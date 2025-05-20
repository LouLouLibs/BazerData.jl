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