# BazerData

[![CI](https://github.com/louloulibs/BazerData.jl/actions/workflows/CI.yml/badge.svg)](https://github.com/louloulibs/BazerData.jl/actions/workflows/CI.yml)
[![Lifecycle:Experimental](https://img.shields.io/badge/Lifecycle-Experimental-339999)](https://github.com/louloulibs/BazerData.jl/actions/workflows/CI.yml)
[![codecov](https://codecov.io/gh/LouLouLibs/BazerData.jl/graph/badge.svg?token=AQR1GHLLHG)](https://codecov.io/gh/LouLouLibs/BazerData.jl)

`BazerData.jl` is a placeholder package for some functions that I use in julia frequently.

So far the package provides a five functions

  1. tabulate some data ([`tabulate`](#tabulate-data))
  2. create category based on quantile ([`xtile`](#xtile))
  3. winsorize some data ([`winsorize`](#winsorize-data))
  4. fill unbalanced panel data ([`panel_fill`](#filling-an-unbalanced-panel))
  5. lead and lag functions ([`tlead|tlag`](#leads-and-lags))

Note that as the package grow in different directions, dependencies might become overwhelming.
The readme serves as documentation; there might be more examples inside of the test folder.

## Installation

`BazerData.jl` is now a registered package. You can install from the main julia registry via the julia package manager
```julia
> import Pkg; Pkg.add("BazerData.jl")
# or in package mode in the REPL
pkg> add BazerData 
# or from the main github branch
> import Pkg; Pkg.add("https://github.com/louloulibs/BazerData.jl#main")
```



## Usage

### Tabulate data

The `tabulate` function tries to emulate the tabulate function from stata (see oneway [here](https://www.stata.com/manuals/rtabulateoneway.pdf) or twoway [here](https://www.stata.com/manuals13/rtabulatetwoway.pdf)).
This relies on the `DataFrames.jl` package and is useful to get a quick overview of the data.

```julia
using DataFrames
using BazerData
using PalmerPenguins

df = DataFrame(PalmerPenguins.load())

tabulate(df, :island)
tabulate(df, [:island, :species])

# If you are looking for groups by type (detect missing e.g.)
df = DataFrame(x = [1, 2, 2, "NA", missing], y = ["c", "c", "b", "z", "d"])
tabulate(df, [:x, :y], group_type = :type) # only types for all group variables
tabulate(df, [:x, :y], group_type = [:value, :type]) # mix value and types
```
I have not implemented all the features of the stata tabulate function, but I am open to [suggestions](#3).


### xtile

See the [doc](https://louloulibs.github.io/BazerData.jl/dev/man/xtile_guide) or the [tests](test/UnitTests/xtile.jl) for examples.
```julia
sales = rand(10_000);
a = xtile(sales, 10);
b = xtile(sales, 10, weights=Weights(repeat([1], length(sales))) );
# works on strings
cities = [randstr() for _ in 10]
xtile(cities, 10)
```


### Winsorize data

This is fairly standard and I offer options to specify probabilities or cutpoints; moreover you can replace the values that are winsorized with a missing, the cutpoints, or some specific values.
There is a [`winsor`](https://juliastats.org/StatsBase.jl/stable/robust/#StatsBase.winsor) function in StatsBase.jl but I think it's a little less full-featured.

See the doc for [examples](https://louloulibs.github.io/BazerData.jl/dev/man/winsorize_guide)
```julia
df = DataFrame(PalmerPenguins.load())
winsorize(df.flipper_length_mm, probs=(0.05, 0.95)) # skipmissing by default
transform(df, :flipper_length_mm =>
    (x->winsorize(x, probs=(0.05, 0.95), replace_value=missing)), renamecols=false)
```


### Filling an unbalanced panel

Sometimes it is unpractical to work with unbalanced panel data.
There are many ways to fill values between dates (what interpolation to use) and I try to implement a few of them.
I use the function sparingly, so it has not been tested extensively.

See the following example (or the test suite) for more information.
```julia
df_panel = DataFrame(        # missing t=2 for id=1
    id = ["a","a", "b","b", "c","c","c", "d","d","d","d"],
    t  = [Date(1990, 1, 1), Date(1990, 4, 1), Date(1990, 8, 1), Date(1990, 9, 1),
          Date(1990, 1, 1), Date(1990, 2, 1), Date(1990, 4, 1),
          Date(1999, 11, 10), Date(1999, 12, 21), Date(2000, 2, 5), Date(2000, 4, 1)],
    v1 = [1,1, 1,6, 6,0,0, 1,4,11,13],
    v2 = [1,2,3,6,6,4,5, 1,2,3,4],
    v3 = [1,5,4,6,6,15,12.25, 21,22.5,17.2,1])

panel_fill(df_panel, :id, :t, [:v1, :v2, :v3],
    gap=Month(1), method=:backwards, uniquecheck=true, flag=true, merge=true)
panel_fill(df_panel, :id, :t, [:v1, :v2, :v3],
    gap=Month(1), method=:forwards, uniquecheck=true, flag=true, merge=true)
panel_fill(df_panel, :id, :t, [:v1, :v2, :v3],
    gap=Month(1), method=:linear, uniquecheck=true, flag=true, merge=true)
```

### Leads and lags
This is largely "borrowed" (copied) from @FuZhiyu [`PanelShift.jl`](https://github.com/FuZhiyu/PanelShift.jl) package.
See the tests for more examples.

```julia
x, t = [1, 2, 3], [1, 2, 4]
tlag(x, t) 
tlag(x, t, n=2) 

using Dates;
t = [Date(2020,1,1); Date(2020,1,2); Date(2020,1,4)];
tlag(x, t)
tlag(x, t, n=Day(2)) # specify two-day lags
```


## Other stuff


See my other package 
  - [BazerUtils.jl](https://github.com/louloulibs/BazerUtils.jl) which groups together data wrangling functions.
  - [FinanceRoutines.jl](https://github.com/louloulibs/FinanceRoutines.jl) which is more focused and centered on working with financial data.
  - [TigerFetch.jl](https://github.com/louloulibs/TigerFetch.jl) which simplifies downloading shape files from the Census.
