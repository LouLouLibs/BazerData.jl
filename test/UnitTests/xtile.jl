@testset "xtile" begin

    df = dropmissing(DataFrame(PalmerPenguins.load()))

    # -- test on strings (lexicographic ordering)
    a = xtile(df.species, 2)
    b = xtile(df.species, 2; weights=Weights(repeat([1], inner=nrow(df))))
    @test a == b                                     # uniform weights == no weights
    @test all(0 .<= a .<= 2)                        # bins in valid range
    # same species must get same bin
    for sp in unique(df.species)
        @test allequal(a[df.species .== sp])
    end
    # lexicographic order: Adelie < Chinstrap < Gentoo
    @test a[findfirst(df.species .== "Adelie")] <= a[findfirst(df.species .== "Chinstrap")]
    @test a[findfirst(df.species .== "Chinstrap")] <= a[findfirst(df.species .== "Gentoo")]

    # -- string xtile with non-alphabetical categories
    s_nonalpha = ["z", "z", "z", "a", "a", "m"]
    result = xtile(s_nonalpha, 2)
    @test allequal(result[1:3])         # all "z" in same bin
    @test allequal(result[4:5])         # all "a" in same bin
    @test all(0 .<= result .<= 2)      # bins are valid
    # lexicographic: "a" < "m" < "z"
    @test result[4] <= result[6]        # "a" <= "m"
    @test result[6] <= result[1]        # "m" <= "z"

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
    result_m = xtile(s_m, 3)
    @test count(ismissing, result_m) == 2           # missing preserved
    @test all(0 .<= skipmissing(result_m) .<= 3)   # bins in valid range
    # lexicographic: a < c < e < g < za
    non_miss_idx = findall(!ismissing, s_m)
    non_miss_vals = s_m[non_miss_idx]
    non_miss_bins = result_m[non_miss_idx]
    for (i, j) in zip(non_miss_idx[1:end-1], non_miss_idx[2:end])
        if s_m[i] < s_m[j]
            @test result_m[i] <= result_m[j]        # ordering preserved
        end
    end

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

    # n_quantiles validation
    @test_throws Exception xtile([1.0, 2.0, 3.0], 0)
    @test_throws Exception xtile([1.0, 2.0, 3.0], -1)

end
