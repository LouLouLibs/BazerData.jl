@testset "xtile" begin

    df = dropmissing(DataFrame(PalmerPenguins.load()))

    # -- test on strings!
    a = xtile(df.species, 2);
    b = xtile(df.species, 2; weights=Weights(repeat([1], inner=nrow(df))));
    @test a==b
    @test sum(a)==520

    # -- test for more xtile than categories
    a = xtile(df.species, 4);
    b = xtile(df.species, 5);
    @test a==b

    # -- test on int
    a = xtile(df.flipper_length_mm, 2);
    @test sum(a)==173
    b = xtile(df.flipper_length_mm, 10);
    @test sum(b)==1539
    c = xtile(df.flipper_length_mm, 100);
    @test sum(c)==16923
    d = xtile(df.flipper_length_mm, 10, weights=Weights(repeat([1], inner=nrow(df))));
    @test d==b
    e = xtile(df.flipper_length_mm, 10, weights=Weights(rand(nrow(df))));
    @test sum(e.<=10)==nrow(df)

    # -- test on Float
    a = xtile(df.bill_depth_mm, 2);
    @test sum(a)==173
    b = xtile(df.bill_depth_mm, 10);
    @test sum(b)==1533
    c = xtile(df.bill_depth_mm, 100);
    @test sum(c)==16741
    d = xtile(df.bill_depth_mm, 10, weights=Weights(repeat([1], inner=nrow(df))));
    @test d==b
    e = xtile(df.bill_depth_mm, 10, weights=Weights(rand(nrow(df))));
    @test sum(e.<=10)==nrow(df)

    # -- test on Union{Missing, Float64}
    x_m = Vector{Union{Int64,Missing}}(collect(range(1, 1_000_000)));
    x_m[sample(1:length(x_m), 10_000, replace=false)] .= convert(Missing, missing);
    q_m = xtile(x_m, 10);
    # test that function works ok
    @test sum( ismissing.(q_m) ) == 10_000
    # test that it gives the same result as the skipmissing result on subset of not missing
    @test q_m[ .!ismissing.(q_m) ] == xtile(collect(skipmissing(x_m)), 10)

    # -- test on Union{Missing, AbstractString}
    s_m = ["a", "c", "g", missing, "e", missing, "za"]
    @test isequal(xtile(s_m, 3), [1, 1, 2, missing, 1, missing, 3])
    @test isequal(xtile(s_m, 20), [1, 2, 4, missing, 2, missing, 5])

end


@testset "xtile - edge cases" begin

    # all-missing input
    x_all_missing = Vector{Union{Int64, Missing}}(fill(missing, 10))
    result = xtile(x_all_missing, 4)
    @test all(ismissing, result)
    @test length(result) == 10

    # single-element vector: searchsortedlast puts the value at the last quantile
    result = xtile([42.0], 5)
    @test length(result) == 1
    @test result[1] isa Int

    result = xtile([42], 5)
    @test length(result) == 1

    result = xtile(["hello"], 3)
    @test length(result) == 1

    # single-element with missing wrapper
    x_single_m = Union{Int, Missing}[7]
    result = xtile(x_single_m, 3)
    @test length(result) == 1
    @test !ismissing(result[1])

    # two-element vector: results should be valid bin indices
    result = xtile([1.0, 2.0], 2)
    @test length(result) == 2
    @test result[1] < result[2]  # lower value gets lower bin

    # all identical values: all should get the same bin
    x_same = fill(5.0, 100)
    result = xtile(x_same, 10)
    @test allequal(result)
    @test length(result) == 100

    # n_quantiles == 1: only the max element gets bin 1 (searchsortedlast behavior)
    result = xtile(rand(50), 1)
    @test all(r -> r in (0, 1), result)

    # large n_quantiles: bins are bounded by n_quantiles
    result = xtile(rand(100), 10)
    @test all(r -> 0 <= r <= 10, result)

end
