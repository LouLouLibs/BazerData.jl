
# Public Interface {#Public-Interface}

## `BazerData` Module {#BazerData-Module}
<details class='jldocstring custom-block' open>
<summary><a id='BazerData.panel_fill!-Tuple{DataFrames.DataFrame, Symbol, Symbol, Union{Symbol, Vector{Symbol}}}' href='#BazerData.panel_fill!-Tuple{DataFrames.DataFrame, Symbol, Symbol, Union{Symbol, Vector{Symbol}}}'><span class="jlbinding">BazerData.panel_fill!</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
panel_fill!(...)

Same as panel_fill but with modification in place
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/eloualiche/BazerData.jl/blob/5faeb3e704b567c33dd3eef7c43492095f8b855a/src/PanelData.jl#L151-L156" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='BazerData.panel_fill-Tuple{DataFrames.DataFrame, Symbol, Symbol, Union{Symbol, Vector{Symbol}}}' href='#BazerData.panel_fill-Tuple{DataFrames.DataFrame, Symbol, Symbol, Union{Symbol, Vector{Symbol}}}'><span class="jlbinding">BazerData.panel_fill</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
panel_fill(
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
```


**Arguments**
- `df::AbstractDataFrame`: a panel dataset
  
- `id_var::Symbol`: the individual index dimension of the panel
  
- `time_var::Symbol`: the time index dimension of the panel (must be integer or a date)
  
- `value_var::Union{Symbol, Vector{Symbol}}`: the set of columns we would like to fill
  

**Keywords**
- `gap::Union{Int, DatePeriod} = 1` : the interval size for which we want to fill data
  
- `method::Symbol = :backwards`: the interpolation method to fill the data   options are: `:backwards` (default), `:forwards`, `:linear`, `:nearest`   email me for other interpolations (anything from Interpolations.jl is possible)
  
- `uniquecheck::Bool = true`: check if panel is clean
  
- `flag::Bool = false`: flag the interpolated values
  
- `merge::Bool = false`: merge the new values with the input dataset
  

**Returns**
- `AbstractDataFrame`: 
  

**Examples**
- See tests
  


<Badge type="info" class="source-link" text="source"><a href="https://github.com/eloualiche/BazerData.jl/blob/5faeb3e704b567c33dd3eef7c43492095f8b855a/src/PanelData.jl#L2-L35" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='BazerData.tabulate-Tuple{DataFrames.AbstractDataFrame, Union{Symbol, Vector{Symbol}}}' href='#BazerData.tabulate-Tuple{DataFrames.AbstractDataFrame, Union{Symbol, Vector{Symbol}}}'><span class="jlbinding">BazerData.tabulate</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
tabulate(df::AbstractDataFrame, cols::Union{Symbol, Array{Symbol}};
    reorder_cols=true, out::Symbol=:stdout)
```


This was forked from TexTables.jl and was inspired by https://github.com/matthieugomez/statar

**Arguments**
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
    
  

**Returns**
- `Nothing` if `out=:stdout`
  
- `DataFrame` if `out=:df`
  
- `String` if `out=:string`
  

**Output Format**

The resulting table contains the following columns:
- Specified grouping columns (from `cols`)
  
- `freq`: Frequency count
  
- `pct`: Percentage of total
  
- `cum`: Cumulative percentage
  

**TO DO**

allow user to specify order of columns (reorder = false flag)

**Examples**

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



<Badge type="info" class="source-link" text="source"><a href="https://github.com/eloualiche/BazerData.jl/blob/5faeb3e704b567c33dd3eef7c43492095f8b855a/src/StataUtils.jl#L18-L72" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='BazerData.winsorize-Union{Tuple{AbstractVector{T}}, Tuple{T}} where T' href='#BazerData.winsorize-Union{Tuple{AbstractVector{T}}, Tuple{T}} where T'><span class="jlbinding">BazerData.winsorize</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
winsorize(
    x::AbstractVector; 
    probs::Union{Tuple{Real, Real}, Nothing} = nothing,
    cutpoints::Union{Tuple{Real, Real}, Nothing} = nothing,
    replace::Symbol = :missing
    verbose::Bool=false
)
```


**Arguments**
- `x::AbstractVector`: a vector of values
  

**Keywords**
- `probs::Union{Tuple{Real, Real}, Nothing}`: A vector of probabilities that can be used instead of cutpoints
  
- `cutpoints::Union{Tuple{Real, Real}, Nothing}`: Cutpoints under and above which are defined outliers. Default is (median - five times interquartile range, median + five times interquartile range). Compared to bottom and top percentile, this takes into account the whole distribution of the vector
  
- `replace_value::Tuple`:  Values by which outliers are replaced. Default to cutpoints. A frequent alternative is missing. 
  
- `IQR::Real`: when inferring cutpoints what is the multiplier from the median for the interquartile range. (median ± IQR * (q75-q25))
  
- `verbose::Bool`: printing level
  

**Returns**
- `AbstractVector`: A vector the size of x with substituted values 
  

**Examples**
- See tests
  

This code is based on Matthieu Gomez winsorize function in the `statar` R package 


<Badge type="info" class="source-link" text="source"><a href="https://github.com/eloualiche/BazerData.jl/blob/5faeb3e704b567c33dd3eef7c43492095f8b855a/src/Winsorize.jl#L2-L28" target="_blank" rel="noreferrer">source</a></Badge>

</details>

<details class='jldocstring custom-block' open>
<summary><a id='BazerData.xtile-Union{Tuple{T}, Tuple{AbstractVector{T}, Integer}} where T<:Real' href='#BazerData.xtile-Union{Tuple{T}, Tuple{AbstractVector{T}, Integer}} where T<:Real'><span class="jlbinding">BazerData.xtile</span></a> <Badge type="info" class="jlObjectType jlMethod" text="Method" /></summary>



```julia
xtile(data::Vector{T}, n_quantiles::Integer, 
             weights::Union{Vector{Float64}, Nothing}=nothing)::Vector{Int} where T <: Real
```


Create quantile groups using Julia&#39;s built-in weighted quantile functionality.

**Arguments**
- `data`: Values to group
  
- `n_quantiles`: Number of groups
  
- `weights`: Optional weights of weight type (StatasBase)
  

**Examples**

```julia
sales = rand(10_000);
a = xtile(sales, 10);
b = xtile(sales, 10, weights=Weights(repeat([1], length(sales))) );
@assert a == b
```



<Badge type="info" class="source-link" text="source"><a href="https://github.com/eloualiche/BazerData.jl/blob/5faeb3e704b567c33dd3eef7c43492095f8b855a/src/StataUtils.jl#L436-L454" target="_blank" rel="noreferrer">source</a></Badge>

</details>

