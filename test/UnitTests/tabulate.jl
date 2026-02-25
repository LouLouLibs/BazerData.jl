@testset "Tabulate" begin

    # on existing dataset
    df = dropmissing(DataFrame(PalmerPenguins.load()))
    cols = :island

    # Test that function do not error on empty
    @test isnothing(tabulate(df[ df.island .== "Brehat", :], :sex))

    col_length = combine(groupby(df, cols), cols .=> length => :_N)
    sort!(col_length, cols)
    col_tab = tabulate(df, :island; out=:df);
    sort!(col_tab, cols)
    @test col_length._N == col_tab.freq

    # test the string output
    tab_buf = IOBuffer(tabulate(df, :island; out=:string))
    tab_string = String(take!(tab_buf))
    @test count(==('\n'), tab_string) == 5 # test number of lines expected
    first_line = split(tab_string, '\n', limit=2)[1]
    @test all(x -> contains(first_line, x), ["island", "Freq", "Percent", "Cum", "Hist."])

    tab_buf = IOBuffer(tabulate(df, :island; out=:string, skip_stat=:freq_hist))
    tab_string = String(take!(tab_buf))
    @test count(==('\n'), tab_string) == 5 # test number of lines expected
    first_line = split(tab_string, '\n', limit=2)[1]
    @test all(x -> contains(first_line, x), ["island", "Freq", "Percent", "Cum"])

    # test the nothing output
    tab_stdout = tabulate(df, :island, out=:stdout)
    @test typeof(tab_stdout) == Nothing
    tab_stdout = stdout_string() do # had to request a convenient package for this one...
        tabulate(df, :island, out=:stdout)
    end
    @test count(==('\n'), tab_stdout) == 5 # test number of lines expected
    first_line = split(tab_stdout, '\n', limit=2)[1]
    @test all(x -> contains(first_line, x), ["island", "Freq", "Percent", "Cum", "Hist."])

    # test the type columns get properly passed
    @test contains(tabulate(df, [:island, :species], group_type = [:type, :value], out=:string),
                   "island_typeof")
    @test contains(tabulate(df, [:island, :species], group_type = [:value, :type], out=:string),
                   "species_typeof")

    # test the twoway ad wide tabulate
    df_twoway = tabulate(df, [:island, :species], format_tbl=:wide, out=:df);
    @test names(df_twoway) == ["-", "Adelie", "Gentoo", "Chinstrap", "Total by island"]
    @test nrow(df_twoway) == 4
    df_twoway = tabulate(df, [:sex, :island, :species], format_tbl=:wide, out=:df);
    @test names(df_twoway) == ["-", "--", "Adelie", "Gentoo", "Chinstrap", "Total by sex, island"]
    @test nrow(df_twoway) == 7

    # on a specific dataset (see issue #1)
    df = DataFrame(x = [1, 2, 5, "NA", missing], y = ["a", "c", "b", "e", "d"])
    df_tab = tabulate(df, :x, reorder_cols=true, out=:df)
    @test isequal(df_tab.x, df.x)

    # test the group type options
    df = DataFrame(x = [1, 2, 2, "NA", missing], y = ["c", "c", "b", "z", "d"])
    @test isequal(
        tabulate(df, [:x, :y], out=:df).y,
        sort(df.y))
    @test nrow(tabulate(df, [:x, :y], group_type = :value, out=:df)) == 5
    @test nrow(tabulate(df, [:x, :y], group_type = :type, out=:df)) == 3
    @test nrow(tabulate(df, [:x, :y], group_type = [:type, :value], out=:df)) == 4
    @test nrow(tabulate(df, [:x, :y], group_type = [:value, :type], out=:df)) == 4

end


@testset "Tabulate - wide format pct" begin
    df = dropmissing(DataFrame(PalmerPenguins.load()))

    # wide format with format_stat=:pct returns a DataFrame
    df_pct = tabulate(df, [:island, :species], format_tbl=:wide, format_stat=:pct, out=:df)
    @test df_pct isa DataFrame
    @test nrow(df_pct) == 3
    # pct columns should not have a totals column (unlike freq)
    @test !any(contains.(names(df_pct), "Total"))

    # wide format pct as string output
    pt = tabulate(df, [:island, :species], format_tbl=:wide, format_stat=:pct, out=:string)
    @test pt isa String
    @test length(pt) > 0

    # wide format pct stdout returns nothing
    result = tabulate(df, [:island, :species], format_tbl=:wide, format_stat=:pct, out=:stdout)
    @test isnothing(result)
end


@testset "Tabulate - wide format string output" begin
    df = dropmissing(DataFrame(PalmerPenguins.load()))

    # wide freq as string
    pt = tabulate(df, [:island, :species], format_tbl=:wide, out=:string)
    @test pt isa String
    @test contains(pt, "Adelie")
    @test contains(pt, "Gentoo")
    @test contains(pt, "Chinstrap")

    # 3-column wide as string
    pt = tabulate(df, [:sex, :island, :species], format_tbl=:wide, out=:string)
    @test pt isa String
    @test contains(pt, "Adelie")
end


@testset "Tabulate - missing values" begin
    # DataFrame with missing values in the tabulated column
    df = DataFrame(x = [1, 2, missing, 1, missing, 3])
    df_tab = tabulate(df, :x, out=:df)
    @test nrow(df_tab) == 4  # 1, 2, 3, missing
    @test sum(df_tab.freq) == 6
    @test :freq in propertynames(df_tab)
    @test :pct in propertynames(df_tab)
    @test :cum in propertynames(df_tab)

    # string output with missing values should not error
    pt = tabulate(df, :x, out=:string)
    @test pt isa String
    @test contains(pt, "missing")

    # two-column with missing
    df = DataFrame(x = ["a", "b", missing, "a"], y = [1, 2, 3, missing])
    df_tab = tabulate(df, [:x, :y], out=:df)
    @test nrow(df_tab) == 4
    @test sum(df_tab.freq) == 4
end


@testset "Tabulate - skip_stat vector" begin
    df = dropmissing(DataFrame(PalmerPenguins.load()))

    # skip multiple stats
    pt = tabulate(df, :island, out=:string, skip_stat=[:freq_hist, :cum])
    first_line = split(pt, '\n', limit=2)[1]
    @test contains(first_line, "Freq")
    @test contains(first_line, "Percent")
    @test !contains(first_line, "Cum")
    @test !contains(first_line, "Hist")

    # skip just freq
    pt = tabulate(df, :island, out=:string, skip_stat=:freq)
    first_line = split(pt, '\n', limit=2)[1]
    @test !contains(first_line, "Freq.")
    @test contains(first_line, "Percent")
end


@testset "Tabulate - single row DataFrame" begin
    df = DataFrame(x = ["only_value"])
    df_tab = tabulate(df, :x, out=:df)
    @test nrow(df_tab) == 1
    @test df_tab.freq[1] == 1
    @test df_tab.cum[1] == 100
end


@testset "Tabulate - reorder_cols=false" begin
    df = DataFrame(x = ["c", "a", "b", "a", "c", "c"])
    df_tab = tabulate(df, :x, reorder_cols=false, out=:df)
    # without reordering, original groupby order is preserved
    @test nrow(df_tab) == 3
    @test sum(df_tab.freq) == 6
end


@testset "Tabulate - invalid format_stat in wide" begin
    df = dropmissing(DataFrame(PalmerPenguins.load()))
    @test_throws Exception tabulate(df, [:island, :species],
        format_tbl=:wide, format_stat=:invalid, out=:df)
end
