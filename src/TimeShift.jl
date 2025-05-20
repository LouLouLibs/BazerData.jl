# --------------------------------------------------------------------------------------------------
# most of this code was copied from @FuZhiyu PanelShift.jl package
# --------------------------------------------------------------------------------------------------


# --------------------------------------------------------------------------------------------------
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
# most of this code was inspired by @FuZhiyu PanelShift.jl package
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












