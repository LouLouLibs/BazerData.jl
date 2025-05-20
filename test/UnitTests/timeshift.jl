@testset "Time Shift" begin


# --------------------------------------------------------------------------------------------------
    df1 = DataFrame(        # missing t=2 for id=1
        id = ["a","a","b","b","c","c","c"],
        t  = [1,3,8,9,1,2,4],
        v1  = [1,1,1,6,6,0,0],
        v2  = [1,2,3,6,6,4,5],
        v3  = [1,5,4,6,6,15,12.25])

    df2 = DataFrame(        # missing t=2 for id=1
        id = ["a","a", "b","b", "c","c","c", "d","d","d","d"],
        t  = [Date(1990, 1, 1), Date(1990, 4, 1), Date(1990, 8, 1), Date(1990, 9, 1),
              Date(1990, 1, 1), Date(1990, 2, 1), Date(1990, 4, 1),
              Date(1999, 11, 10), Date(1999, 12, 21), Date(2000, 2, 5), Date(2000, 4, 1)],
        v1 = [1,1, 1,6, 6,0,0, 1,4,11,13],
        v2 = [1,2,3,6,6,4,5, 1,2,3,4],
        v3 = [1,5,4,6,6,15,12.25, 21,22.5,17.2,1])

    # --- test for df1
    @testset "DF1" begin
        sort!(df1, [:id, :t])
        transform!(groupby(df1, :id), [:t, :v2] => ( (d, x) -> tlag(x, d)) => :v2_lag)
        @test isequal(df1.v2_lag, [missing, missing, missing, 3, missing, 6, missing])
    end

    # --- test  for df2 multiple variables
    @testset "DF2" begin
        sort!(df2, [:id, :t])
        transform!(
            groupby(df2, :id),
            [:t, :v1] => 
                ((t, v1) -> (; v1_lag_day = tlag(v1, t; verbose=true), 
                               v1_lag_mth = tlag(v1, t; n=Month(1), verbose=true) ) ) =>
                [:v1_lag_day, :v1_lag_mth])

        @test all(ismissing.(df2.v1_lag_day))
        @test isequal(df2.v1_lag_mth, 
            [missing, missing, missing, 1, missing, 6, missing, missing, missing, missing, missing ])

    end
# --------------------------------------------------------------------------------------------------


# --------------------------------------------------------------------------------------------------
    @testset "General tests" begin 

    # --- test large datasets
    function generate_test_data(;size=50_000, gap_probability=0.1, seed=123)
        Random.seed!(seed)
        
        # Start date and initialize arrays
        start_date = Date(2020, 1, 1)
        dates = Vector{Date}()
        x_values = Vector{Float64}()
        
        # Generate dates with some gaps and corresponding x values
        current_date = start_date
        for i in 1:size
            # Add current date and value
            push!(dates, current_date)
            push!(x_values, sin(i/100) + 0.1*randn()) # Some noisy sine wave pattern
            
            # Decide whether to introduce a gap (skip 1-5 days)
            if rand() < gap_probability
                gap_size = rand(1:5)
                current_date += Day(gap_size + 1)
            else
                # Normal increment
                current_date += Day(1)
            end
        end
        
        # Create DataFrame
        df = DataFrame(date=dates, x=x_values)
        return df
    end

    tiny_df  = generate_test_data(size=50, gap_probability=0.05);
    small_df = generate_test_data(size=5_000, gap_probability=0.1);
    large_df = generate_test_data(size=1_000_000, gap_probability=0.1);

    @time transform!(small_df, [:x, :date] => ( (x, d) -> tlag(x, d)) => :x_lag)
    @test nrow(subset(small_df, :x_lag => ByRow(!ismissing))) == 4525
    
    @time transform!(large_df, [:x, :date] => ( (x, d) -> tlag(x, d)) => :x_lag_day);
    @time transform!(large_df, [:x, :date] => ( (x, d) -> tlag(x, d, n=Month(1))) => :x_lag_mth);
    @time transform!(large_df, [:x, :date] => ( (x, d) -> tlag(x, d, n=Year(1))) => :x_lag_yr);
    
    transform!(large_df, :date => ByRow(year) => :datey)
    @test_throws r"time vector not sorted"i transform!(large_df, 
        [:x, :datey] => ( (x, d) -> tlag(x, d, n=1)) => :x_lag_datey);
    
    @test nrow(subset(large_df, :x_lag_day => ByRow(!ismissing)))    == 900_182
    @test nrow(subset(large_df, :x_lag_mth => ByRow(!ismissing)))    == 770_178
    @test nrow(subset(large_df, :x_lag_yr => ByRow(!ismissing)))     == 769_502

    @time transform!(tiny_df, [:x, :date] => ( (x, d) -> tlead(x, d)) => :x_lead)
    @time transform!(tiny_df, [:x_lead, :date] => ( (x, d) -> tlag(x, d)) => :x_lead_lag)
    @test dropmissing(tiny_df) |> (df -> df.x == df.x_lead_lag)  # lead lag reverts back up to destroyed information

    @time transform!(tiny_df, [:x, :date] => ( (x, d) -> tlead(x, d, n=Day(2)) ) => :x_lead2)
    @time transform!(tiny_df, [:x_lead2, :date] => ( (x, d) -> tlag(tlag(x, d), d) ) => :x_lead2_lag2)
    @test dropmissing(tiny_df) |> (df -> df.x == df.x_lead2_lag2)  # lead lag reverts back up to destroyed information


    end # of "General tests"
# --------------------------------------------------------------------------------------------------


# --------------------------------------------------------------------------------------------------
    @testset "From Panelshift.jl" begin

    import PanelShift

    # note the api for this package differs slightly ... 
    # PanelShift.tlag(time_variable, x)
    # BazelData.tlag(x, time_variable)

    x_shift = tlag([4, 5, 6], [1, 2, 3])
    @test isequal(PanelShift.tlag([1;2;3], [4;5;6], 1), x_shift)
    @test isequal(x_shift, [missing, 4, 5])

    x_shift = tlead([4, 5, 6], [1, 2, 3])
    @test isequal(PanelShift.tlead([1;2;3], [4;5;6], 1), x_shift)
    @test isequal(x_shift, [5; 6; missing])

    x_shift = tlag([4;5;6], [1;2;3], n=2)
    @test isequal(PanelShift.tlag([1;2;3], [4;5;6], 2), x_shift)     
    @test isequal(x_shift, [missing;missing;4])

    x_shift = tlead([4;5;6], [1;2;3], n=2)
    @test isequal(PanelShift.tlead([1;2;3], [4;5;6], 2), x_shift) 
    @test isequal(x_shift, [6; missing; missing])

    # unit-length vector
    x_shift = tlag([1], [1])
    @test isequal(PanelShift.tlag([1], [1]), x_shift)    #[missing;])
    @test isequal(x_shift, [missing])

    x_shift = tlead([1], [1])
    @test isequal(PanelShift.tlead([1], [1]), x_shift)
    @test isequal(x_shift, [missing])

    # -- 
    x_shift = tlag([1;2;3;4;5], [1;3;5;6;7], n=2)
    @test isequal(PanelShift.tlag([1;3;5;6;7], [1;2;3;4;5], 2), x_shift)
    @test isequal(x_shift, [missing; 1; 2; missing; 3])

    x_shift = tlag(float.([1;2;3;4;5]), [1;3;5;6;7], n=2) 
    @test isequal(PanelShift.tlag(float.([1;3;5;6;7]), [1;2;3;4;5], 2), x_shift)
    @test isequal(x_shift, [missing; 1; 2; missing; 3])

    # non-numeric x and unequal gaps
    x_shift = tlag([:apple; :orange; :banana; :pineapple; :strawberry], [1;2;4;7;11], n=1)
    @test isequal(PanelShift.tlag([1;2;4;7;11], [:apple; :orange; :banana; :pineapple; :strawberry], 1), x_shift)
    @test isequal(x_shift, [missing; :apple; missing; missing; missing])

    x_shift = tlag([:apple; :orange; :banana; :pineapple; :strawberry], [1;2;4;7;11], n=2)
    @test isequal(PanelShift.tlag([1;2;4;7;11], [:apple; :orange; :banana; :pineapple; :strawberry], 2), x_shift)
    @test isequal(x_shift, [missing; missing; :orange; missing; missing])

    x_shift = tlag([:apple; :orange; :banana; :pineapple; :strawberry], [1;2;4;7;11], n=3)
    @test isequal(PanelShift.tlag([1;2;4;7;11], [:apple; :orange; :banana; :pineapple; :strawberry], 3), x_shift)
    @test isequal(x_shift, [missing; missing; :apple; :banana; missing])
        

    x_shift = tlag([:apple; :orange; :banana; :pineapple; :strawberry], [1;2;4;7;11], n=4)
    @test isequal(PanelShift.tlag([1;2;4;7;11], [:apple; :orange; :banana; :pineapple; :strawberry], 4), x_shift)
    @test isequal(x_shift, [missing; missing; missing; missing; :pineapple])

    x_shift = tlead([:apple; :orange; :banana; :pineapple; :strawberry], [1;2;4;7;11], n=4)
    @test isequal(PanelShift.tlead([1;2;4;7;11], [:apple; :orange; :banana; :pineapple; :strawberry], 4), x_shift)
    @test isequal(x_shift, [missing; missing; missing; :strawberry; missing])

    # indexed by dates 
    x_shift = tlag([1,2,3], [Date(2000,1,1), Date(2000, 1,2), Date(2000,1, 4)], n=Day(1))
    @test isequal(PanelShift.tlag([Date(2000,1,1), Date(2000, 1,2), Date(2000,1, 4)], [1,2,3], Day(1)), x_shift)
    @test isequal(x_shift, [missing; 1; missing])
    
    x_shift = tlag([1,2,3], [Date(2000,1,1), Date(2000, 1,2), Date(2000,1, 4)], n=Day(2))
    @test isequal(PanelShift.tlag([Date(2000,1,1), Date(2000, 1,2), Date(2000,1, 4)], [1,2,3], Day(2)), x_shift)
    @test isequal(x_shift, [missing; missing; 2])

    # test shift
    x_shift = tshift([1;2;3], [1;2;3], n=-1)
    @test isequal(PanelShift.tshift([1;2;3], [1;2;3], -1), x_shift)
    @test isequal(x_shift, tlead([1;2;3], [1;2;3], n=1))

    x_shift = tshift([1;2;3], [1;2;3], n=1)
    @test isequal(PanelShift.tshift([1;2;3], [1;2;3], 1), x_shift)
    @test isequal(x_shift, tlag([1;2;3], [1;2;3], n=1))

    # safeguards
    # @test_throws ArgumentError PanelShift.tlag([1;2;2], [1,2,3])  # argcheck error unsorted t
    @test_throws r"time vector not sorted"i tlag([1, 2, 3], [1, 2, 2]) 
    # @test_throws ArgumentError PanelShift.tlag([1;2;], [1,2,3])
    @test_throws r"value and time vector"i tlag([1, 2], [1, 2, 3]) 
    # @test_throws ArgumentError PanelShift.tlag([1;2;3], [1,2,3], 0)
    @test_throws r"shift value"i tlag([1, 2, 3], [1, 2, 3], n=0) 

    end 
# --------------------------------------------------------------------------------------------------



# --------------------------------------------------------------------------------------------------
# benchmarking

# using Chairmarks
# large_df = generate_test_data(size=50_000_000, gap_probability=0.1);

# @b transform!(large_df, [:x, :date] => ( (x, d) -> tlag(x, d)) => :x_lag_day)
# @b transform!(large_df, [:x, :date] => ( (x, d) -> tlag(x, d, n=Month(1))) => :x_lag_mth)
# @b transform!(large_df, [:x, :date] => ( (x, d) -> tlag(x, d, n=Year(1))) => :x_lag_yr)

# @b transform!(large_df, [:x, :date] => ( (x, d) -> PanelShift.tlag(d, x)) => :x_lag_day)
# @b transform!(large_df, [:x, :date] => ( (x, d) -> PanelShift.tlag(d, x, Month(1))) => :x_lag_mth)
# @b transform!(large_df, [:x, :date] => ( (x, d) -> PanelShift.tlag(d, x, Year(1))) => :x_lag_yr)



# @b transform!(large_df, [:x, :date] => ( (x, d) -> tlead(x, d)) => :x_lag_day)
# @b transform!(large_df, [:x, :date] => ( (x, d) -> tlead(x, d, n=Month(1))) => :x_lag_mth)
# @b transform!(large_df, [:x, :date] => ( (x, d) -> tlead(x, d, n=Year(1))) => :x_lag_yr)

# @b transform!(large_df, [:x, :date] => ( (x, d) -> PanelShift.tlead(d, x)) => :x_lag_day)
# @b transform!(large_df, [:x, :date] => ( (x, d) -> PanelShift.tlead(d, x, Month(1))) => :x_lag_mth)
# @b transform!(large_df, [:x, :date] => ( (x, d) -> PanelShift.tlead(d, x, Year(1))) => :x_lag_yr)

# --------------------------------------------------------------------------------------------------    





end




























