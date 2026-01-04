# ------------------------------------------------------------------------------------------

# StataUtils.jl

# Collection of functions that replicate some stata utilities
# ------------------------------------------------------------------------------------------



# ------------------------------------------------------------------------------------------
# List of exported functions
# tabulate # (tab alias)
# xtile
# ------------------------------------------------------------------------------------------


# ------------------------------------------------------------------------------------------
"""
    tabulate(df::AbstractDataFrame, cols::Union{Symbol, Array{Symbol}};
        reorder_cols=true, out::Symbol=:stdout)

This was forked from TexTables.jl and was inspired by https://github.com/matthieugomez/statar

# Arguments
- `df::AbstractDataFrame`: Input DataFrame to analyze
- `cols::Union{Symbol, Vector{Symbol}}`: Single column name or vector of column names to tabulate
- `group_type::Union{Symbol, Vector{Symbol}}=:value`: Specifies how to group each column:
    - `:value`: Group by the actual values in the column
    - `:type`: Group by the type of values in the column
    - `Vector{Symbol}`: Vector combining `:value` and `:type` for different columns
- `reorder_cols::Bool=true`  Whether to sort the output by sortable columns
- `format_tbl::Symbol=:long` How to present the results long or wide (stata twoway)
- `format_stat::Symbol=:freq`  Which statistics to present for format :freq or :pct
- `skip_stat::Union{Nothing, Symbol, Vector{Symbol}}=nothing`  do not print out all statistics (only for string)
- `out::Symbol=:stdout`  Output format:
    - `:stdout`  Print formatted table to standard output (returns nothing)
    - `:df`  Return the result as a DataFrame
    - `:string` Return the formatted table as a string


# Returns
- `Nothing` if `out=:stdout`
- `DataFrame` if `out=:df`
- `String` if `out=:string`

# Output Format
The resulting table contains the following columns:
- Specified grouping columns (from `cols`)
- `freq`: Frequency count
- `pct`: Percentage of total
- `cum`: Cumulative percentage

# TO DO
allow user to specify order of columns (reorder = false flag)

# Examples
See the README for more examples
```julia
# Simple frequency table for one column
tabulate(df, :country)

## Group by value type
tabulate(df, :age, group_type=:type)

# Multiple columns with mixed grouping
tabulate(df, [:country, :age], group_type=[:value, :type])

# Return as DataFrame instead of printing
result_df = tabulate(df, :country, out=:df)
```

"""
function tabulate(
    df::AbstractDataFrame, cols::Union{Symbol, Vector{Symbol}};
    group_type::Union{Symbol, Vector{Symbol}}=:value,
    reorder_cols::Bool=true,
    format_tbl::Symbol=:long, 
    format_stat::Symbol=:freq,
    skip_stat::Union{Nothing, Symbol, Vector{Symbol}}=nothing,
    out::Symbol=:stdout)

    if typeof(cols) <: Symbol # check if it's an array or just a point
        N_COLS = 1
    else
        N_COLS = size(cols,1)
        # error("Only accepts one variable for now ...")
    end

    if !(format_tbl ∈ [:long, :wide])
        if size(cols, 1) == 1
            @warn "Converting format_tbl to :long"
            format_tbl = :long
        else
            @error "Table format_tbl must be :long or :wide"
        end
    end

    if isempty(df)
        @warn "Input Dataframe is empty ..."
        return nothing
    end

    # Count the number of observations by `columns`: this is the main calculation
    group_type_error_msg = """
        \ngroup_type input must specify either ':value' or ':type' for columns;
        options are :value, :type, or a vector combining the two;
        see help for more information
        """
    if group_type == :value
        df_out = combine(groupby(df, cols), nrow => :freq, proprow =>:pct)
        new_cols = cols
    elseif group_type == :type
        name_type_cols = Symbol.(cols, "_typeof")
        df_out = transform(df, cols .=> ByRow(typeof) .=> name_type_cols) |>
            (d -> combine(groupby(d, name_type_cols), nrow => :freq, proprow =>:pct))
        new_cols = name_type_cols
        # rename!(df_out, name_type_cols .=> cols)
    elseif typeof(group_type) <: Vector{Symbol}
        !all(s -> s in [:value, :type], group_type) && (@error group_type_error_msg)
        (size(group_type, 1) != size(cols, 1)) &&
            (@error "\ngroup_type and cols must be the same size; \nsee help for more information")
        type_cols = cols[group_type .== :type]
        name_type_cols = Symbol.(type_cols, "_typeof")
        group_cols = [cols[group_type .== :value]; name_type_cols]
        df_out = transform(df, type_cols .=> ByRow(typeof) .=> name_type_cols) |>
            (d -> combine(groupby(d, group_cols), nrow => :freq, proprow =>:pct))
        new_cols = group_cols
    else
        @error group_type_error_msg
    end
    # resort columns based on the original order
    new_cols = sort(new_cols isa Symbol ? [new_cols] : new_cols, 
        by= x -> findfirst(==(replace(string(x), r"_typeof$" => "")), string.(cols)) )

    if reorder_cols
        cols_sortable = [ # check whether it makes sense to sort on the variables
            name
            for (name, col) in pairs(eachcol(select(df_out, new_cols)))
            if eltype(col) |> t -> hasmethod(isless, Tuple{t,t})
        ]
        if size(cols_sortable, 1)>0
            cols_sortable
            sort!(df_out, cols_sortable)  # order before we build cumulative
        end
    end
    transform!(df_out, :pct => cumsum => :cum, :freq => ByRow(Int) => :freq)
    # easier to do some of the transformations on the numbers directly than using formatters
    transform!(df_out, 
        :pct => (x -> x .* 100), 
        :cum => (x -> Int.(round.(x .* 100, digits=0))), renamecols=false)




# ----- prepare the table
    if format_tbl == :long

        transform!(df_out, :freq => (x->text_histogram(x, width=24)) => :freq_hist)

        # highlighter with gradient for the freq/pct/cum columns (rest is blue)
        col_highlighters = vcat(
            map(i -> Highlighter((data, row, col) -> col == i, crayon"cyan bold"), 1:N_COLS),
            hl_custom_gradient(cols=(N_COLS+1), colorscheme=:Oranges_9, scale=maximum(df_out.freq)),
            hl_custom_gradient(cols=(N_COLS+2), colorscheme=:Greens_9,  scale=ceil(Int, maximum(df_out.pct))),
            hl_custom_gradient(cols=(N_COLS+3), colorscheme=:Greens_9, scale=100),
        )
        col_highlighters = Tuple(x for x in col_highlighters)

        col_formatters = Tuple(vcat( 
            [ ft_printf("%s", i) for i in 1:N_COLS ],   # Column values
            [ 
                ft_printf("%d", N_COLS+1),   # Frequency (integer)
                ft_printf("%.1f", N_COLS+2),  
                ft_printf("%d", N_COLS+3), # Cumulative
                ft_printf("%s", N_COLS+4)    # Histogram
            ]
        ))

        if out ∈ [:stdout, :df]

            pretty_table(df_out;
                hlines = [1],
                vlines = [N_COLS],
                alignment = vcat(repeat([:l], N_COLS), :c, :c, :c, :c),
                cell_alignment = reduce(push!,
                    map(i -> (i,1)=>:l, 1:N_COLS+3),
                    init=Dict{Tuple{Int64, Int64}, Symbol}()),
                header = [string.(new_cols); "Freq."; "Percent"; "Cum"; "Hist."],
                formatters =  col_formatters,
                highlighters = col_highlighters,
                vcrop_mode = :middle,
                border_crayon = crayon"bold yellow",
                header_crayon = crayon"bold light_green",
                show_header = true,
            )

            if out==:stdout
                return(nothing)
            elseif out==:df
                return(df_out)
            end

        elseif out==:string # this might be costly as I am regenerating the table.
            if isnothing(skip_stat)
                pt = pretty_table(String, df_out;
                    hlines = [1],
                    vlines = [N_COLS],
                    alignment = vcat(repeat([:l], N_COLS), :c, :c, :c, :c),
                    cell_alignment = reduce(push!,
                        map(i -> (i,1)=>:l, 1:N_COLS+3),
                        init=Dict{Tuple{Int64, Int64}, Symbol}()),
                    header = [string.(new_cols); "Freq."; "Percent"; "Cum"; "Hist."],
                    formatters =  col_formatters,
                    highlighters = col_highlighters,
                    crop = :none, # no crop for string output
                    border_crayon = crayon"bold yellow",
                    header_crayon = crayon"bold light_green",
                    show_header = true,
                )
            else 
                col_stat = setdiff([:freq, :pct, :cum, :freq_hist], 
                                   isa(skip_stat, Vector) ? skip_stat : [skip_stat])
                N_COL_STAT = size(col_stat,1)
                header_table = vcat(string.(new_cols), 
                    [Dict(:freq=>"Freq.", :pct=>"Percent", :cum=>"Cum", :freq_hist=>"Hist.")[k]
                     for k in col_stat]
                    )
                df_sub_out = select(df_out, cols, col_stat)
                pt = pretty_table(String, df_sub_out;
                    hlines = [1],
                    vlines = [N_COLS],
                    alignment = vcat(repeat([:l], N_COLS), repeat([:c], N_COL_STAT)),
                    cell_alignment = reduce(push!,
                        map(i -> (i,1)=>:l, 1:N_COLS+N_COL_STAT-1),
                        init=Dict{Tuple{Int64, Int64}, Symbol}()),
                    header = header_table,
                    formatters =  col_formatters,
                    highlighters = col_highlighters,
                    crop = :none, # no crop for string output
                    border_crayon = crayon"bold yellow",
                    header_crayon = crayon"bold light_green",
                    show_header = true,
                )
            end                

            return(pt)
        end

    elseif format_tbl == :wide 

        df_out = unstack(df_out, 
            new_cols[1:(N_COLS-1)], new_cols[N_COLS], format_stat, 
            allowmissing=true)
        # new_cols[1:(N_COLS-1)] might be more than one category
        # new_cols[N_COLS] only one group!

        N_GROUP_COLS = N_COLS - 1 # the first set of category (on the left!)
        N_VAR_COLS   = size(df_out, 2) - N_GROUP_COLS


        if format_stat == :freq

            # frequency we also show totals            
            total_row_des = "Total by $(string(new_cols[N_COLS]))"
            total_col_des = join(vcat("Total by ", join(string.(new_cols[1:(N_COLS-1)]), ", ")))

            sum_cols = sum.(skipmissing.(eachcol(df_out[:, range(1+N_GROUP_COLS; length=N_VAR_COLS)])))
            row_vector = vcat([total_row_des], repeat(["-"], max(0, N_GROUP_COLS-1)), sum_cols)                        
            df_out = vcat(df_out, 
                DataFrame(permutedims(row_vector)[:, end+1-size(df_out,2):end], names(df_out))
                )
            sum_rows = sum.(skipmissing.(eachrow(df_out[:, range(1+N_GROUP_COLS; length=N_VAR_COLS)])))
            col_vector = rename(DataFrame(total = sum_rows), "total" => total_col_des)
            df_out = hcat(df_out, col_vector)
            rename!(df_out, [i => "-"^i for i in 1:N_GROUP_COLS])

            #TODO: add a line on top
            #   blank for the group_cols 
            #   name of the wide col 
            #   total by for the sum col

            col_highlighters = vcat(
                map(i -> Highlighter((data, row, col) -> col == i, crayon"cyan bold"), 1:N_GROUP_COLS),
                [ hl_custom_gradient(cols=i, colorscheme=:Greens_9,
                        scale = ceil(Int, maximum(skipmissing(df_out[1:end-1, i]))))
                  for i in  range(1+N_GROUP_COLS; length=N_VAR_COLS) ],
                Highlighter((data, row, col) -> col == size(df_out, 2), crayon"green")
            )
           
            formatters = vcat( 
                [ ft_printf("%s", i) for i in 1:N_GROUP_COLS ],
                [ ft_printf("%d", j) for j in range(1+N_GROUP_COLS; length=N_VAR_COLS) ],
                [ ft_printf("%d", 1+N_GROUP_COLS+N_VAR_COLS) ]
                )

            hlines = [1, size(df_out, 1)]
            vlines = [N_GROUP_COLS, N_GROUP_COLS+N_VAR_COLS]
            alignment = vcat(repeat([:l], N_GROUP_COLS), repeat([:c], N_VAR_COLS), [:l])


        elseif format_stat == :pct

            col_highlighters = vcat(
                map(i -> Highlighter((data, row, col) -> col == i, crayon"cyan bold"), 1:N_GROUP_COLS),
                [ hl_custom_gradient(cols=i, colorscheme=:Greens_9,
                        scale = ceil(Int, maximum(skipmissing(df_out[:, i]))) )
                  for i in  range(1+N_GROUP_COLS; length=N_VAR_COLS) ],
            )

            formatters = vcat( 
                [ ft_printf("%s", i) for i in 1:N_GROUP_COLS ],
                [ ft_printf("%.1f", j) for j in range(1+N_GROUP_COLS; length=N_VAR_COLS) ]
                )

            hlines = [1]
            vlines = [0, N_GROUP_COLS, N_GROUP_COLS+N_VAR_COLS]
            alignment = vcat(repeat([:l], N_GROUP_COLS), repeat([:c], N_VAR_COLS))


        end

        col_highlighters = Tuple(x for x in col_highlighters)

        if out ∈ [:stdout, :df]

            pretty_table(df_out;
                hlines = hlines,
                vlines = vlines,
                alignment = alignment,
                cell_alignment = reduce(push!,
                    map(i -> (i,1)=>:l, 1:N_GROUP_COLS),
                    init=Dict{Tuple{Int64, Int64}, Symbol}()),
                formatters = Tuple(formatters),
                highlighters = col_highlighters,
                vcrop_mode = :middle,
                border_crayon = crayon"bold yellow",
                header_crayon = crayon"bold light_green",
                show_header = true,
                show_subheader=false,
            )

            if out==:stdout
                return(nothing)
            elseif out==:df
                return(df_out)
            end
        elseif out==:string            
            pt = pretty_table(String, df_out;
                hlines = hlines,
                vlines = vlines,
                alignment = alignment,
                cell_alignment = reduce(push!,
                    map(i -> (i,1)=>:l, 1:N_GROUP_COLS),
                    init=Dict{Tuple{Int64, Int64}, Symbol}()),
                formatters = Tuple(formatters),
                highlighters = col_highlighters,
                crop = :none, # no crop for string output
                border_crayon = crayon"bold yellow",
                header_crayon = crayon"bold light_green",
                show_header = true,
                show_subheader = false,
            )

            return(pt)
        end
    end


end
# --------------------------------------------------------------------------------------------------


# --------------------------------------------------------------------------------------------------
function hl_custom_gradient(;
    cols::Int=0,
    colorscheme::Symbol=:Oranges_9,
    scale::Int=1)

    Highlighter(
    (data, i, j) -> j == cols,
    (h, data, i, j) -> begin
        if ismissing(data[i, j])
            return Crayon(foreground=(128, 128, 128))  # Use a default color for missing values
        end
        color = get(colorschemes[colorscheme], data[i, j], (0, scale))
        return Crayon(foreground=(round(Int, color.r * 255),
                                  round(Int, color.g * 255),
                                  round(Int, color.b * 255)))
    end
)

end
# --------------------------------------------------------------------------------------------------


# --------------------------------------------------------------------------------------------------
# From https://github.com/mbauman/Sparklines.jl/blob/master/src/Sparklines.jl
# Sparklines.jl
# const ticks = ['▁','▂','▃','▄','▅','▆','▇','█']
# function spark(x)
#     min, max = extrema(x)
#     f = div((max - min) * 2^8, length(ticks)-1)
#     f < 1 && (f = one(typeof(f)))
#     idxs = convert(Vector{Int}, map(v -> div(v, f), (x .- min) * 2^8))
#     return string.(ticks[idxs.+1])
# end

# Unicode characters: 
# █ (Full block, U+2588)
# ⣿ (Full Braille block, U+28FF)
# ▓ (Dark shade, U+2593)
# ▒ (Medium shade, U+2592)
# ░ (Light shade, U+2591)
# ◼ (Small black square, U+25FC)

function text_histogram(frequencies; width=12)
    blocks = [" ", "▏", "▎", "▍", "▌", "▋", "▊", "▉", "█"]
    max_freq = maximum(frequencies)
    max_freq == 0 && return fill(" " ^ width, length(frequencies))
    scale = (width * 8 - 1) / max_freq  # Subtract 1 to ensure we don't exceed width
    
    function bar(f)
        units = round(Int, f * scale)
        full_blocks = div(units, 8)
        remainder = units % 8
        rpad(repeat("█", full_blocks) * blocks[remainder + 1], width)
    end
    bar.(frequencies)
end
# --------------------------------------------------------------------------------------------------



# --------------------------------------------------------------------------------------------------

"""
    xtile(data::Vector{T}, n_quantiles::Integer, 
                 weights::Union{Vector{Float64}, Nothing}=nothing)::Vector{Int} where T <: Real

Create quantile groups using Julia's built-in weighted quantile functionality.

# Arguments
- `data`: Values to group
- `n_quantiles`: Number of groups
- `weights`: Optional weights of weight type (StatasBase)

# Examples
```julia
sales = rand(10_000);
a = xtile(sales, 10);
b = xtile(sales, 10, weights=Weights(repeat([1], length(sales))) );
@assert a == b
```
"""
function xtile(
    data::AbstractVector{T}, 
    n_quantiles::Integer;
    weights::Union{Weights{<:Real}, Nothing} = nothing
)::Vector{Int} where T <: Real
    
        N = length(data)
        n_quantiles > N && (@warn "More quantiles than data")

        probs = range(0, 1, length=n_quantiles + 1)[2:end]
        if weights === nothing
            weights = UnitWeights{T}(N)
        end
        cuts = quantile(collect(data), weights, probs)

    return searchsortedlast.(Ref(cuts), data)
end

# String version
function xtile(
    data::AbstractVector{T}, 
    n_quantiles::Integer;
    weights::Union{Weights{<:Real}, Nothing} = nothing
)::Vector{Int} where T <: AbstractString
    
    if weights === nothing
        weights = UnitWeights{Int}(length(data))
    end
    # Assign weights to each category
    category_weights = [sum(weights[data .== category]) for category in unique(data)]
    # Sort categories based on the weighted cumulative sum
    sorted_categories = sortperm(category_weights, rev=true)
    step = max(1, round(Int, length(sorted_categories) / n_quantiles))
    cuts = unique(data)[sorted_categories][1:step:end]
   
    return searchsortedlast.(Ref(cuts), data)

end

# Dealing with missing and Numbers
function xtile(
    data::AbstractVector{T}, 
    n_quantiles::Integer;
    weights::Union{Weights{<:Real}, Nothing} = nothing
)::Vector{Union{Int, Missing}} where {T <: Union{Missing, AbstractString, Number}}

    # Determine the non-missing type
    non_missing_type = Base.nonmissingtype(T)

    # Identify valid (non-missing) data
    data_notmissing_idx = findall(!ismissing, data)

    if isempty(data_notmissing_idx)  # If all values are missing, return all missing
        return fill(missing, length(data))
    end

    # Use @view to avoid unnecessary allocations but convert explicitly to non-missing type
    valid_data = convert(Vector{non_missing_type}, @view data[data_notmissing_idx])
    valid_weights = weights === nothing ? nothing : Weights(@view weights[data_notmissing_idx])

    # Compute quantile groups on valid data
    valid_result = xtile(valid_data, n_quantiles; weights=valid_weights)

    # Allocate result array with correct type
    result = Vector{Union{Int, Missing}}(missing, length(data))
    result[data_notmissing_idx] .= valid_result  # Assign computed quantile groups

    return result
end
# --------------------------------------------------------------------------------------------------





