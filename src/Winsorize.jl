# ------------------------------------------------------------------------------------------
"""
    winsorize(x::AbstractVector;
        probs=nothing, cutpoints=nothing, replace_value=nothing,
        IQR=3, verbose=false)

Winsorize (clip extreme values) in a vector.
Based on Matthieu Gomez's winsorize function in the `statar` R package.

# Arguments
- `x::AbstractVector`: a vector of values

# Keywords
- `probs::Union{Tuple{Real, Real}, Nothing}`: Probability bounds for cutpoints (e.g., `(0.05, 0.95)`)
- `cutpoints::Union{Tuple{Real, Real}, Nothing}`: Explicit cutpoints for outlier thresholds.
    Default is `(median - IQR*(q75-q25), median + IQR*(q75-q25))`
- `replace_value`: Values to replace outliers with. Default: cutpoint values.
    Can be a tuple `(lo, hi)`, `missing`, or `(missing, missing)`
- `IQR::Real=3`: Multiplier from the median for the interquartile range when inferring cutpoints
- `verbose::Bool=false`: Print informational messages

# Returns
- `AbstractVector`: A vector the size of x with substituted values

# Examples
- See tests
"""
function winsorize(x::AbstractVector{T}; 
    probs::Union{Tuple{Real, Real}, Nothing} = nothing,
    cutpoints::Union{Tuple{Union{T, Real}, Union{T, Real}}, Nothing} = nothing,
    replace_value::Union{Tuple{Union{T, Real}, Union{T, Real}}, Tuple{Missing, Missing}, Nothing, Missing} = nothing,
    IQR::Real=3,
    verbose::Bool=false
    ) where T

    if !isnothing(probs)
        lower_percentile = max(minimum(probs), 0)
        upper_percentile = min(maximum(probs), 1)
        (lower_percentile<0 || upper_percentile>1) && @error "bad probability input"
        verbose && any(ismissing, x) && (@info "Some missing data skipped in winsorizing")
        verbose && !isnothing(cutpoints) && (@info "input cutpoints ignored ... using probabilities")

        cut_lo = (lower_percentile==0) ? minimum(skipmissing(x)) : quantile(skipmissing(x), lower_percentile)
        cut_hi = (upper_percentile==1) ? maximum(skipmissing(x)) : quantile(skipmissing(x), upper_percentile)
        cutpoints = (cut_lo, cut_hi)
        
    elseif isnothing(cutpoints)
        verbose && any(ismissing, x) && (@info "Some missing data skipped in winsorizing")
        l = quantile(skipmissing(x), [0.25, 0.50, 0.75])
        cutpoints = (l[2] - IQR * (l[3]-l[1]), l[2] + IQR * (l[3]-l[1]) )
        verbose && @info "Inferred cutpoints are ... $cutpoints (using interquartile range x $IQR from median)"
    end

    if isnothing(replace_value) # default to  cutpoints
        replace_value = (minimum(cutpoints), maximum(cutpoints))
        replace_value = convert.(Union{T, eltype(replace_value)}, replace_value)
    elseif ismissing(replace_value)
        replace_value = (missing, missing)
    end

    if any(ismissing.(replace_value))
        y = Vector{Union{T, Missing}}(x)  # Make a copy of x that can also store missing values
    else
        y = Vector{Union{T, eltype(replace_value)}}(x) # TODO could be faster using views here ...
    end
    
    y[findall(skipmissing(x .< cutpoints[1]))] .= replace_value[1];
    y[findall(skipmissing(x .> cutpoints[2]))] .= replace_value[2];

    return y
end
