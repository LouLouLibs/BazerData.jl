@testset "winsorize" begin

    Random.seed!(3);
    x1 = rand(100);
    x2 = Vector{Union{Float64, Missing}}(rand(Float64, 100)); x2[rand(collect(1:100), 5)] .= missing;

# --- tests on non-missing vectors
    x1_win = winsorize(x1, probs=(0.05, 0.95), verbose=true);
    @test findall(x1 .!= x1_win) == [4, 15, 26, 32, 40, 44, 52, 59, 64, 97]

    x1_win = winsorize(x1; verbose=true);
    @test findall(x1 .!= x1_win) == []

    x1_win = winsorize(x1; cutpoints=(0.01, 0.99), verbose=true)
    @test findall(x1 .!= x1_win) == [4, 26, 52]

    x1_win = winsorize(x1; cutpoints=(0, 0.9), verbose=true)
    @test isequal(minimum(x1), minimum(x1_win))

# --- tests with some missing
    x2_win = winsorize(x2, probs=(0.02, 0.98), verbose=true);
    @test size(x2) == size(x2_win)
    @test findall(skipmissing(x2 .!= x2_win)) == [5, 41, 83, 91]

    x2_win = winsorize(x2; verbose=true)
    @test size(x2) == size(x2_win)
    @test findall(skipmissing(x2 .!= x2_win)) == []

    x2_win = winsorize(x2; cutpoints=(0.05, 0.95), verbose=true)
    @test size(x2) == size(x2_win)
    @test findall(skipmissing(x2 .!= x2_win)) == [5, 17, 41, 42, 65, 83, 91]

# --- tests to do: with replace
    x2_win = winsorize(x2; cutpoints=(0.05, 0.95), replace_value=(missing, missing), verbose=true)
    @test size(x2) == size(x2_win)
    @test findall(ismissing.(x2) .!= ismissing.(x2_win)) == [5, 17, 41, 42, 65, 83, 91]

    x2_win = winsorize(x2; cutpoints=(0.05, 0.95), replace_value=missing, verbose=true)
    @test size(x2) == size(x2_win)
    @test findall(ismissing.(x2) .!= ismissing.(x2_win)) == [5, 17, 41, 42, 65, 83, 91]

    x2_win = winsorize(x2; cutpoints=(0.05, 0.95), replace_value=(-1.0, 1.0), verbose=true)
    @test size(x2) == size(x2_win)
    @test findall(v -> v ∈ (-1.0, 1.0), skipmissing(x2_win)) == [5, 17, 41, 42, 65, 83, 91]

    # we check that this works if the type of replace is slightly different ...
    # maybe we want to change this ...
    x2_win = winsorize(x2; cutpoints=(0.05, 0.95), replace_value=(-1, 1), verbose=true)
    @test size(x2) == size(x2_win)
    @test findall(v -> v ∈ (-1.0, 1.0), skipmissing(x2_win)) == [5, 17, 41, 42, 65, 83, 91]

end


@testset "winsorize - custom IQR" begin
    Random.seed!(42)
    x = randn(1000)  # standard normal: outliers likely beyond ~3σ

    # default IQR=3 should keep most data
    w_default = winsorize(x)
    n_changed_default = count(x .!= w_default)

    # IQR=1 should clip more aggressively
    w_tight = winsorize(x, IQR=1)
    n_changed_tight = count(x .!= w_tight)
    @test n_changed_tight > n_changed_default

    # IQR=100 should clip almost nothing
    w_loose = winsorize(x, IQR=100)
    @test count(x .!= w_loose) == 0
end


@testset "winsorize - edge cases" begin
    # all identical values: nothing to winsorize
    x_same = fill(5.0, 50)
    w = winsorize(x_same, probs=(0.05, 0.95))
    @test w == x_same

    # single-element vector
    x_one = [3.14]
    w = winsorize(x_one, probs=(0.1, 0.9))
    @test w == x_one

    # integer vector
    x_int = collect(1:100)
    w = winsorize(x_int, probs=(0.05, 0.95))
    @test length(w) == 100
    @test minimum(w) >= minimum(x_int)
    @test maximum(w) <= maximum(x_int)
    @test count(w .!= x_int) > 0  # some values should be clipped

    # one-sided winsorize: only clip top
    Random.seed!(1)
    x = rand(100)
    w = winsorize(x, cutpoints=(minimum(x), 0.5))
    @test minimum(w) == minimum(x)  # bottom unchanged
    @test maximum(w) <= 0.5

    # one-sided: only clip bottom
    w = winsorize(x, cutpoints=(0.5, maximum(x)))
    @test minimum(w) >= 0.5
    @test maximum(w) == maximum(x)  # top unchanged
end


@testset "winsorize - all missing" begin
    x_all_missing = Vector{Union{Float64, Missing}}(fill(missing, 10))
    # probs path uses skipmissing which will be empty - quantile on empty should error
    @test_throws Exception winsorize(x_all_missing, probs=(0.05, 0.95))
end


@testset "winsorize - error paths" begin
    # empty vector
    @test_throws Exception winsorize(Float64[])

    # invalid probability bounds
    @test_throws Exception winsorize([1.0, 2.0, 3.0], probs=(-0.1, 0.9))
    @test_throws Exception winsorize([1.0, 2.0, 3.0], probs=(0.1, 1.1))
end
