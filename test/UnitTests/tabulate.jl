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


# -- TODO: Add tests for results that include missing 