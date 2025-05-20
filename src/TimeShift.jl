# --------------------------------------------------------------------------------------------------
# most of this code was copied from @FuZhiyu PanelShift.jl package
# --------------------------------------------------------------------------------------------------


# --------------------------------------------------------------------------------------------------
"""
    tlag(x, t_vec; n = nothing, checksorted = true, verbose = false)

Create a lagged version of array `x` based on time vector `t_vec`, where each element is shifted
backward in time by a specified amount `n`.

# Arguments
- `x`: Array of values to be lagged
- `t_vec`: Vector of time points corresponding to each element in `x` 

# Keyword Arguments
- `n`: Time gap for lagging. If `nothing` (default), uses the minimal unit difference between time points.
- `checksorted`: If `true` (default), verifies that `t_vec` is sorted in ascending order
- `verbose`: If `true`, prints informational messages about the process

# Returns
- An array of the same length as `x` where each element is the value of `x` from `n` time units ago,
  or `missing` if no corresponding past value exists

# Notes
- Time vectors must be strictly sorted (ascending order)
- The time gap `n` must be positive
- Uses linear scan to match time points
- For `Date` types, no type checking is performed on `n`
- Elements at the beginning will be `missing` if they don't have values from `n` time units ago
- See PanelShift.jl for original implementation

# Errors
- If `t_vec` is not sorted and `checksorted=true`
- If `n` is not positive
- If `x` and `t_vec` have different lengths
- If `n` has a type that doesn't match the difference type of `t_vec`

# Examples
```julia
x = [1, 2, 3, 4, 5]
t = [Date(2023,1,1), Date(2023,1,2), Date(2023,1,3), Date(2023,1,4), Date(2023,1,5)]
tlag(x, t, n = Day(1))  # Returns: [missing, 1, 2, 3, 4]
"""
function tlag(x, t_vec; 
    n = nothing, 
    checksorted = true,
    verbose = false,
    )

    if isnothing(n) # this is the default
        n = oneunit(t_vec[1] - t_vec[1])
        verbose && ( (t_vec[1] isa Date) ? (@info "Default date gap inferred ... $n") : 
            (@info "Default gap inferred ... $n") )
    elseif eltype(t_vec) == Date 
        verbose && @info "No checks on increment argument n for type Date ... "
    else
        !(n isa typeof(t_vec[1]-t_vec[1])) && 
            error("Time gap type does not match time variable: typeof(n)=$(typeof(n)) != eltype(vec)=$(eltype(t_vec))")

    end

    checksorted && !issorted(t_vec; lt = (<=) ) && error("time vector not sorted (order is strict)!")
    !(n > zero(n)) && error("shift value has to be positive!")
    
    N = length(t_vec)
    (length(x) != N) && error("value and time vector have different lengths!")

    x_shift = Array{Union{Missing, eltype(x)}}(missing, N);

    # _binary_search_lag!(x_shift, x, t_vec, n, N)
    _linear_scan!(x_shift, x, t_vec, n, N)

    return x_shift

end

function _linear_scan!(x_shift, x, t_vec, n, N)
    j = 0
    @inbounds for i in 1:N
        # Calculate the target time we're looking for
        lagt = t_vec[i] - n
        # Scan forward from where we left off to find the largest index
        # where t_vec[j] <= lagt (since t_vec is sorted)
        while j < N && t_vec[j + 1] <= lagt
            j += 1
        end

        # If we found a valid index and it's an exact match
        if j > 0 && t_vec[j] == lagt
            x_shift[i] = x[j]
        # else
        #     x_shift[i] = missing
        end
    end
    return x_shift
end
# --------------------------------------------------------------------------------------------------



# --------------------------------------------------------------------------------------------------
"""
    tlead(x, t_vec; n = nothing, checksorted = true, verbose = false)

Create a leading version of array `x` based on time vector `t_vec`, where each element is shifted
forward in time by a specified amount `n`.

# Arguments
- `x`: Array of values to be led
- `t_vec`: Vector of time points corresponding to each element in `x`

# Keyword Arguments
- `n`: Time gap for leading. If `nothing` (default), uses the minimal unit difference between time points.
- `checksorted`: If `true` (default), verifies that `t_vec` is sorted in ascending order
- `verbose`: If `true`, prints informational messages about the process

# Returns
- An array of the same length as `x` where each element is the value of `x` from `n` time units in the future,
  or `missing` if no corresponding future value exists

# Notes
- Time vectors must be strictly sorted (ascending order)
- The time gap `n` must be positive
- Uses linear scan to match time points
- For `Date` types, no type checking is performed on `n`
- Elements at the end will be `missing` if they don't have values from `n` time units in the future
- See PanelShift.jl for original implementation

# Errors
- If `t_vec` is not sorted and `checksorted=true`
- If `n` is not positive
- If `x` and `t_vec` have different lengths
- If `n` has a type that doesn't match the difference type of `t_vec`

# Examples
```julia
x = [1, 2, 3, 4, 5]
t = [Date(2023,1,1), Date(2023,1,2), Date(2023,1,3), Date(2023,1,4), Date(2023,1,5)]
tlead(x, t, n = Day(1))  # Returns: [2, 3, 4, 5, missing]
"""
function tlead(x, t_vec; 
    n = nothing, 
    checksorted = true,
    verbose = false,
    )

    if isnothing(n) # this is the default
        n = oneunit(t_vec[1] - t_vec[1])
        verbose && ( (t_vec[1] isa Date) ? (@info "Default date gap inferred ... $n") : 
            (@info "Default gap inferred ... $n") )
    elseif eltype(t_vec) == Date 
        verbose && @info "No checks on increment argument n for date type ... "
    else
        !(n isa typeof(t_vec[1]-t_vec[1])) && 
            error("Time gap type does not match time variable: typeof(n)=$(typeof(n)) != eltype(vec)=$(eltype(t_vec))")
    end

    checksorted && !issorted(t_vec; lt = (<=) ) && error("time vector not sorted (order is strict)!")
    !(n > zero(n)) && error("shift value has to be positive!")
    
    N = length(t_vec)
    (length(x) != N) && error("value and time vector have different lengths!")

    x_shift = Array{Union{Missing, eltype(x)}}(missing, N);
    _linear_scan_lead!(x_shift, x, t_vec, n, N)
    return x_shift

end

function _linear_scan_lead!(x_shift, x, t_vec, n, N)
    j = 0
    
    @inbounds for i in 1:N
        leadt = t_vec[i] + n    
        # Early termination if already past the end of the array
        if leadt > t_vec[N]
            # All remaining targets will be beyond the array bounds
            break
        end
     
        # Fast forward scan (can add loop unrolling here if needed)
        while j < N && t_vec[j + 1] < leadt
            j += 1
        end
        # Check for exact match at the next position
        if j + 1 <= N && t_vec[j + 1] == leadt
            x_shift[i] = x[j + 1]
        end
    end
    return x_shift

end
# --------------------------------------------------------------------------------------------------


# --------------------------------------------------------------------------------------------------
"""
    tshift(x, t_vec; n = nothing, kwargs...)

Create a shifted version of array `x` based on time vector `t_vec`, where each element is shifted
by a specified amount `n`. Acts as a unified interface to `tlag` and `tlead`.

# Arguments
- `x`: Array of values to be shifted
- `t_vec`: Vector of time points corresponding to each element in `x`

# Keyword Arguments
- `n`: Time gap for shifting. If positive, performs a lag operation (backward in time); 
       if negative, performs a lead operation (forward in time).
       If `nothing` (default), defaults to a lag operation with minimal unit difference.
- `kwargs...`: Additional keyword arguments passed to either `tlag` or `tlead`

# Returns
- An array of the same length as `x` where each element is the value of `x` shifted by `n` time units,
  or `missing` if no corresponding value exists at that time point

# Notes
- Positive `n` values call `tlag` (backward shift in time)
- Negative `n` values call `tlead` (forward shift in time)
- If `n` is not specified, issues a warning and defaults to a lag operation

# Examples
```julia
x = [1, 2, 3, 4, 5]
t = [Date(2023,1,1), Date(2023,1,2), Date(2023,1,3), Date(2023,1,4), Date(2023,1,5)]
tshift(x, t, n = Day(1))   # Lag: [missing, 1, 2, 3, 4]
tshift(x, t, n = -Day(1))  # Lead: [2, 3, 4, 5, missing]

See also: tlag, tlead
"""
function tshift(x, t_vec; n=nothing, kwargs...)
    
    if isnothing(n)
        @warn "shift not specified ... defaulting to lag"
        n = oneunit(t_vec[1] - t_vec[1])
    end

    if n > zero(n)
        return tlag(x, t_vec, n=n; kwargs...)
    else
        return tlead(x, t_vec, n=-n; kwargs...)
    end
end
# --------------------------------------------------------------------------------------------------












