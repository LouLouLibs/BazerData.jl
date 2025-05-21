# ------------------------------------------------------------------------------------------
"""
    panel_fill!(
        df::DataFrame,
        id_var::Symbol, 
        time_var::Symbol, 
        value_var::Union{Symbol, Vector{Symbol}};
        gap::Union{Int, DatePeriod} = 1, 
        method::Symbol = :backwards, 
        uniquecheck::Bool = true,
        flag::Bool = false,
        merge::Bool = false
    )

# Arguments
- `df::AbstractDataFrame`: a panel dataset
- `id_var::Symbol`: the individual index dimension of the panel
- `time_var::Symbol`: the time index dimension of the panel (must be integer or a date)
- `value_var::Union{Symbol, Vector{Symbol}}`: the set of columns we would like to fill
        
# Keywords
- `gap::Union{Int, DatePeriod} = 1` : the interval size for which we want to fill data
- `method::Symbol = :backwards`: the interpolation method to fill the data
    options are: `:backwards` (default), `:forwards`, `:linear`, `:nearest`
    email me for other interpolations (anything from Interpolations.jl is possible)
- `uniquecheck::Bool = true`: check if panel is clean
- `flag::Bool = false`: flag the interpolated values

# Returns
- `AbstractDataFrame`: 

# Examples
- See tests
"""
function panel_fill!(
    df::DataFrame,
    id_var::Symbol, time_var::Symbol, value_var::Union{Symbol, Vector{Symbol}};
    gap::Union{Int, DatePeriod} = 1, 
    method::Symbol = :backwards, 
    uniquecheck::Bool = true,
    flag::Bool = false,
    )
 
    # prepare the data
    sort!(df, [id_var, time_var])
    if isa(value_var, Symbol) 
        value_var = [value_var]
    end
    if uniquecheck # check for unicity 
        any(nonunique(df, [id_var, time_var])) && 
            (@warn "Some non unique observations in dataset")
    end

    time_var_r = join([string(time_var), "rounded"], "_") # clean up if dates
    if typeof(gap) <: DatePeriod
        if !(eltype(df.t) <: Dates.AbstractTime)
            error(
                """
                Type of gap $(typeof(gap)) and type of time variable $(eltype(df.t)) do not match
                """
            )
        else
            df[!, time_var_r] .= floor.(df[!, time_var], gap)
            if !(df[!, time_var_r] == df[!, time_var])
                @warn "Using rounded time variables for consistency with gap: $gap"
            end
        end
    else
        df[!, time_var_r] .= df[!, time_var]
    end

    gdf = groupby(df, [id_var])
    df_fill = DataFrame();

    for id_gdf in eachindex(gdf)
        subdf = gdf[id_gdf]
        sub_fill = DataFrame()

        if method == :backwards
            interpolate_method = BSpline(Constant(Previous))
        elseif method == :forwards
            interpolate_method = BSpline(Constant(Next)) #     # Next-neighbor interpolation
        elseif method == :nearest 
            interpolate_method = BSpline(Constant())  # Nearest-neighbor interpolation
        elseif method == :linear
            interpolate_method = BSpline(Linear())
        else
            error(
                """
                Method $method not available.
                Please choose from :backwards, :forwards, :nearest, :linear (default)
                """
                )
        end
        
        if nrow(subdf)>1 # condition for filling: at least one open
            sort!(subdf, time_var_r)
            rowdf_init = subdf[1, :]
            for rowdf in eachrow(subdf)[2:end]
                
                old_t = rowdf_init[time_var_r] # initialize the iteration
                enum_t = rowdf[time_var_r] 
                
                t_fill = collect(range(old_t, enum_t, step=sign(enum_t-old_t) * gap))[2:end-1]
                group_fill = DataFrame(
                    Dict(Symbol(time_var_r) => t_fill, id_var => id_gdf[1]))
                N_fill = nrow(group_fill)
                scale_xs = range(1, 2, N_fill+2)[2:end-1]  # the scaling matrix

                # this builds the interpolator and home made scales
                interp_dict = Dict(
                    v => interpolate([rowdf_init[v], rowdf[v]], interpolate_method) 
                    for v in value_var)
                var_fill = DataFrame(
                    Dict(v => interp_dict[v].(scale_xs) for v in value_var))

                # process the iteration and move on
                sub_fill = vcat(sub_fill, hcat(group_fill, var_fill))
                rowdf_init = rowdf;
            end
        end
        df_fill = vcat(sub_fill, df_fill)   
    end
    
    # clean up the output
    if flag 
        df_fill[!, :flag] .= method
    end
    if df[!, time_var_r] == df[!, time_var]
        rename!(df_fill, time_var_r => time_var)
        select!(df, Not(time_var_r))
    else # if they are not all the same we are going to fill
        transform!(df_fill, time_var_r => time_var)
    end

    if flag
        df[!, :flag] .= :original
    end

    append!(df, df_fill, cols=:union)
    sort!(df, [id_var, time_var])

    return df

end


""" 
    panel_fill(...)

    Same as panel_fill but without modification in place in place
"""    
function panel_fill(
    df::DataFrame,
    id_var::Symbol, time_var::Symbol, value_var::Union{Symbol, Vector{Symbol}};
    gap::Union{Int, DatePeriod} = 1, 
    method::Symbol = :backwards, 
    uniquecheck::Bool = true,
    flag::Bool = false
    )

    df_res = copy(df)

    panel_fill!(df_res, id_var, time_var, value_var,
        gap = gap, method = method, uniquecheck = uniquecheck, flag = flag)
    
    return df_res


end



