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
