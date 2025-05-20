@testset "panel_fill" begin

# include("./src/PanelData.jl")

    df1 = DataFrame(        # missing t=2 for id=1
        id = [1,1,2,2,2],
        t  = [1,4,1,2,4],
        a  = [1,1,1,0,0])

    df2 = DataFrame(        # missing t=2 for id=1
        id = ["a","a","b","b","c","c","c"],
        t  = [1,4,8,9,1,2,4],
        v1  = [1,1,1,6,6,0,0],
        v2  = [1,2,3,6,6,4,5],
        v3  = [1,5,4,6,6,15,12.25])

    df3 = DataFrame(        # missing t=2 for id=1
        id = ["a","a", "b","b", "c","c","c", "d","d","d","d"],
        t  = [Date(1990, 1, 1), Date(1990, 4, 1), Date(1990, 8, 1), Date(1990, 9, 1),
              Date(1990, 1, 1), Date(1990, 2, 1), Date(1990, 4, 1),
              Date(1999, 11, 10), Date(1999, 12, 21), Date(2000, 2, 5), Date(2000, 4, 1)],
        v1 = [1,1, 1,6, 6,0,0, 1,4,11,13],
        v2 = [1,2,3,6,6,4,5, 1,2,3,4],
        v3 = [1,5,4,6,6,15,12.25, 21,22.5,17.2,1])

    # --- test for df1
    @testset "DF1" begin
        df1_test = panel_fill(df1, :id, :t, :a,
            gap=1, method=:backwards, uniquecheck=true, flag=true)
        @test isequal(select(df1_test, :a),
                        DataFrame(a = [0.0, 1.0, 1.0]))
        # TODO clean up this t est
        df1_test = panel_fill(df1, :id, :t, :a,
            gap=1, method=:backwards, uniquecheck=true, flag=true, merge=true)
        @test isequal(nrow(df1_test), 8)
    end

    # --- test  for df2 multiple variables
    @testset "DF2" begin
        df2_test = panel_fill(df2, :id, :t, [:v1, :v2, :v3],
            gap=1, method=:backwards, uniquecheck=true, flag=true)
        @test isequal(select(df2_test, r"v"),
                    DataFrame(v1 = [0.0, 1.0, 1.0], v2 = [4.0, 1.0, 1.], v3 = [15.0, 1.0, 1.0]))

        df2_test = panel_fill(df2, :id, :t, :v1,
            gap=1, method=:backwards, uniquecheck=true, flag=true, merge=true)
        @test isequal((nrow(df2_test), nrow(filter(:v2 => !ismissing, df2_test))),
                    (10, 7))
    end


    # --- test for df3 multiple variables and dates
    @testset "DF3" begin
        # test with dates backwards
        df3_test = panel_fill(df3, :id, :t, [:v1, :v2, :v3],
            gap=Month(1), method=:backwards, uniquecheck=true, flag=true)
        @test isequal(select(df3_test, :v1, :v2, :v3),
                    DataFrame(v1 = [4.0, 11.0, 0.0, 1.0, 1.0], v2 = [2.0, 3.0, 4.0, 1.0, 1.0],
                                v3 = [22.5, 17.2, 15.0, 1.0, 1.0]))

        # test in place with dates forwards and only fill some variables and not others
        df3_test = copy(df3)
        panel_fill!(df3_test, :id, :t, [:v2],
            gap=Month(1), method=:forwards, uniquecheck=true, flag=true)
        @test isequal(
            select(subset(df3_test, :flag => ByRow(==(:forwards)), skipmissing=true), :v1, :v2),
            DataFrame(v1 = repeat([missing], inner=5), v2 = [2.0, 2.0, 5.0, 3.0, 4.0]))

        # linear interpolation
        df3_test = panel_fill(df3, :id, :t, [:v1, :v2, :v3],
            gap=Month(1), method=:linear, uniquecheck=true, flag=true, merge=false)
        @test isapprox(select(df3_test, r"v"),
                    DataFrame(v1 = [7.5 , 12.0, 0.0, 1.0, 1.0], v2 = [2.5, 3.5, 4.5, 1.333, 1.666],
                                v3 = [19.85, 9.1, 13.625, 2.3333, 3.666]),
                    atol = 0.01)

        # nearest
        df3_test = panel_fill(df3, :id, :t, :v1,
            gap=Month(1), method=:nearest, uniquecheck=true, flag=true, merge=false)
        @test isequal(select(df3_test, :v1), DataFrame(v1 = [11.0, 13.0, 0.0, 1.0, 1.0]))

        # TODO clean up these tests

        # -- different time periods
        # this fails
        # panel_fill(df3, :id, :t, [:v1, :v2, :v3],
            # gap=Month(2), method=:backwards, uniquecheck=true, flag=true, merge=true)
        df3_test = panel_fill(df3, :id, :t, [:v1, :v2, :v3],
            gap=Day(10), method=:forwards, uniquecheck=true, flag=true, merge=true)
        @test isequal(nrow(df3_test) , 39)

    end


end
