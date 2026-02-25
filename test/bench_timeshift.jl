#!/usr/bin/env julia
# Benchmark: tlag/tlead performance comparison
#
# Compares three approaches:
#   1. Old linear scan (Date arithmetic interleaved with comparisons)
#   2. New: pre-compute Int64 targets, scan in pure Int64
#   3. Dict-based O(1) lookup
#
# Run with: julia --project test/bench_timeshift.jl

using BazerData
using Dates
using Random
using Statistics

# --- Old linear scan (Date objects in hot loop) ---
function tlag_oldscan(x, t_vec, n)
    N = length(t_vec)
    x_shift = Array{Union{Missing, eltype(x)}}(missing, N)
    j = 0
    @inbounds for i in 1:N
        lagt = t_vec[i] - n
        while j < N && t_vec[j + 1] <= lagt
            j += 1
        end
        if j > 0 && t_vec[j] == lagt
            x_shift[i] = x[j]
        end
    end
    return x_shift
end

function tlead_oldscan(x, t_vec, n)
    N = length(t_vec)
    x_shift = Array{Union{Missing, eltype(x)}}(missing, N)
    j = 0
    @inbounds for i in 1:N
        leadt = t_vec[i] + n
        if leadt > t_vec[N]; break; end
        while j < N && t_vec[j + 1] < leadt
            j += 1
        end
        if j + 1 <= N && t_vec[j + 1] == leadt
            x_shift[i] = x[j + 1]
        end
    end
    return x_shift
end

# --- Dict-based lookup ---
function tlag_dict(x, t_vec, n)
    N = length(t_vec)
    x_shift = Array{Union{Missing, eltype(x)}}(missing, N)
    lookup = Dict{eltype(t_vec), Int}()
    sizehint!(lookup, N)
    @inbounds for i in 1:N; lookup[t_vec[i]] = i; end
    @inbounds for i in 1:N
        idx = get(lookup, t_vec[i] - n, 0)
        if idx > 0; x_shift[i] = x[idx]; end
    end
    return x_shift
end


# --- Benchmark harness ---
function bench(f; warmup=3, trials=15)
    for _ in 1:warmup; f(); end
    GC.gc()
    times = Float64[]
    for _ in 1:trials
        t0 = time_ns()
        f()
        push!(times, (time_ns() - t0) / 1e6)  # ms
    end
    return (median=median(times), min=minimum(times))
end

function report(label, old, new; dict=nothing)
    speedup = old.median / new.median
    color = speedup >= 1.0 ? "\033[32m" : "\033[31m"
    reset = "\033[0m"
    line = "  $(rpad(label, 28))  old=$(rpad(round(old.median, digits=2), 8))ms  " *
           "new=$(rpad(round(new.median, digits=2), 8))ms  " *
           "$(color)$(round(speedup, digits=2))x$(reset)"
    if dict !== nothing
        ds = old.median / dict.median
        dc = ds >= 1.0 ? "\033[32m" : "\033[31m"
        line *= "  dict=$(rpad(round(dict.median, digits=2), 8))ms $(dc)$(round(ds, digits=2))x$(reset)"
    end
    println(line)
end


# --- Generate test data ---
function make_daily_dates(n; gap_prob=0.1, seed=42)
    Random.seed!(seed)
    dates = Vector{Date}(undef, n)
    d = Date(2000, 1, 1)
    for i in 1:n
        dates[i] = d
        d += Day(rand() < gap_prob ? rand(2:5) : 1)
    end
    return dates
end

function make_integers(n; gap_prob=0.1, seed=42)
    Random.seed!(seed)
    ts = Vector{Int}(undef, n)
    t = 1
    for i in 1:n
        ts[i] = t
        t += rand() < gap_prob ? rand(2:5) : 1
    end
    return ts
end


# --- Run benchmarks ---
println("\n" * "="^80)
println("  TimeShift Benchmark")
println("  old = linear scan on Date objects")
println("  new = pre-compute Int64 targets, scan in Int64")
println("  dict = Dict{T,Int} lookup")
println("="^80)

for N in [100_000, 1_000_000]
    println("\n--- N = $(N ÷ 1000)K elements ---")

    dates = make_daily_dates(N)
    ints  = make_integers(N)
    x_f   = rand(N)
    x_i   = rand(1:1000, N)

    println("\n  tlag:")
    for (lbl, t, x, n) in [
        ("Int,   n=1",        ints,  x_i, 1),
        ("Int,   n=365",      ints,  x_i, 365),
        ("Date,  n=Day(1)",   dates, x_f, Day(1)),
        ("Date,  n=Month(1)", dates, x_f, Month(1)),
        ("Date,  n=Year(1)",  dates, x_f, Year(1)),
    ]
        old  = bench(() -> tlag_oldscan(x, t, n))
        new  = bench(() -> tlag(x, t; n=n, checksorted=false))
        dict = bench(() -> tlag_dict(x, t, n))
        report(lbl, old, new; dict=dict)
    end

    println("\n  tlead:")
    for (lbl, t, x, n) in [
        ("Int,   n=1",        ints,  x_i, 1),
        ("Date,  n=Day(1)",   dates, x_f, Day(1)),
        ("Date,  n=Month(1)", dates, x_f, Month(1)),
        ("Date,  n=Year(1)",  dates, x_f, Year(1)),
    ]
        old = bench(() -> tlead_oldscan(x, t, n))
        new = bench(() -> tlead(x, t; n=n, checksorted=false))
        report(lbl, old, new)
    end
end

println("\n" * "="^80)
