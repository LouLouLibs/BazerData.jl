# Winsorizing

The function `winsorize` tries to emulate stata winsor function.

There is a [`winsor`](https://juliastats.org/StatsBase.jl/stable/robust/#StatsBase.winsor) function in StatsBase.jl but I think it's a little less full-featured.


```@setup hist
import Pkg; Pkg.add("Plots");
using Plots, Random, BazerData
gr(); theme(:wong2); Plots.default(display_type=:inline, size=(1250,750), thickness_scaling=1)
```


## Basic usage

Start with a simple distribution to visualize the effect of *winsorizing*
```@example hist
Random.seed!(3); x = randn(10_000);
p1 = histogram(x, bins=-4:0.1:4, color="blue", label="distribution", 
    framestyle=:box, size=(1250,750))
savefig(p1, "p1.svg"); nothing # hide
```
![](p1.svg)


### Replace the outliers based on quantile
```@example hist; 
x_win = winsorize(x, probs=(0.05, 0.95));
p2 = histogram(x, bins=-4:0.1:4, color="blue", label="distribution", framestyle=:box); 
histogram!(x_win, bins=-4:0.1:4, color="red", opacity=0.5, label="winsorized")
savefig(p2, "p2.svg"); nothing # hide
```
![](p2.svg)


### One side trim
```@example hist; 
x_win = winsorize(x, probs=(0, 0.8));
p3 = histogram(x, bins=-4:0.1:4, color="blue", label="distribution", framestyle=:box);
histogram!(x_win, bins=-4:0.1:4, color="red", opacity=0.5, label="winsorized");
savefig(p3, "p3.svg"); nothing # hide
```
![](p3.svg)


### Bring your own cutpoints
Another type of winsorizing is to specify your own cutpoints (they do not have to be symmetric):
```@example hist
x_win = winsorize(x, cutpoints=(-1.96, 2.575));
p4 = histogram(x, bins=-4:0.1:4, color="blue", label="distribution", framestyle=:box); 
histogram!(x_win, bins=-4:0.1:4, color="red", opacity=0.5, label="winsorized");
savefig(p4, "p4.svg"); nothing # hide
```
![](p4.svg)


### Rely on the computer to select the right cutpoints
If you do not specify either they will specified automatically
```@example hist
x_win = winsorize(x; verbose=true);
p5 = histogram(x, bins=-4:0.1:4, color="blue", label="distribution", framestyle=:box); 
histogram!(x_win, bins=-4:0.1:4, color="red", opacity=0.5, label="winsorized");
savefig(p5, "p5.svg"); nothing # hide
```
![](p5.svg)


### How not to replace outliers
If you do not want to replace the value by the cutoffs, specify `replace_value=missing`:
```@example hist
x_win = winsorize(x, cutpoints=(-2.575, 1.96), replace_value=missing);
p6 = histogram(x, bins=-4:0.1:4, color="blue", label="distribution", framestyle=:box); 
histogram!(x_win, bins=-4:0.1:4, color="red", opacity=0.5, label="winsorized");
savefig(p6, "p6.svg"); nothing # hide
```
![](p6.svg)


### How to choose your replacement
The `replace_value` command gives you some flexibility to do whatever you want in your outlier data transformation
```@example hist
x_win = winsorize(x, cutpoints=(-2.575, 1.96), replace_value=(-1.96, 1.28));
p7 = histogram(x, bins=-4:0.1:4, color="blue", label="distribution", framestyle=:box); 
histogram!(x_win, bins=-4:0.1:4, color="red", opacity=0.5, label="winsorized");
savefig(p7, "p7.svg"); nothing # hide
```
![](p7.svg)



## Within a DataFrame

I try to mimick the `gtools winsor` [example](https://raw.githubusercontent.com/mcaceresb/stata-gtools/master/docs/examples/gstats_winsor.do)

```@setup dataframe
import Pkg; 
Pkg.add("DataFrames"); Pkg.add("Plots");
Pkg.add("PalmerPenguins"); ENV["DATADEPS_ALWAYS_ACCEPT"] = true
using DataFrames, PalmerPenguins, Plots, BazerData
gr(); theme(:wong2); Plots.default(display_type=:inline, size=(1250,750), thickness_scaling=1)
```


Winsorize one variable
```@example dataframe
df = DataFrame(PalmerPenguins.load())

# gstats winsor wage
transform!(df, :body_mass_g => (x -> winsorize(x, probs=(0.1, 0.9)) ) => :body_mass_g_w) 

p8 = histogram(df.body_mass_g, bins=2700:100:6300, color="blue", label="distribution", framestyle=:box); 
histogram!(df.body_mass_g_w, bins=2700:100:6300, color="red", opacity=0.5, label="winsorized");
savefig(p8, "p8.svg"); nothing # hide
```
![](p8.svg)


Winsorize multiple variables
```@example dataframe
# gstats winsor wage age hours, cuts(0.5 99.5) replace
var_to_winsorize = ["bill_length_mm", "bill_depth_mm", "flipper_length_mm"]
transform!(df, 
    var_to_winsorize .=> (x -> winsorize(x, probs=(0.1, 0.9)) ) .=> var_to_winsorize .* "_w")
show(IOContext(stdout, :limit => true, :displaysize => (20, 100)), df, allcols=true, allrows=false)
nothing; # hide
```

Winsorize on one side only
```@example dataframe
# left-winsorizing only, at 1th percentile; 
# cap noi gstats winsor wage, cuts(1 100); gstats winsor wage, cuts(1 100) s(_w2)
transform!(df, :body_mass_g => (x -> winsorize(x, probs=(0.1, 1)) ) => :body_mass_g_w )
show(IOContext(stdout, :limit => true, :displaysize => (20, 100)), df, allcols=true, allrows=false)
nothing; # hide
```

Winsorize by groups
```@example dataframe
transform!(
    groupby(df, :sex),
    :body_mass_g => (x -> winsorize(x, probs=(0.2, 0.8)) ) => :body_mass_g_w)
p9 = histogram(df[ isequal.(df.sex, "male"), :body_mass_g], bins=3000:100:6300, 
    color="blue", label="distribution", framestyle=:box);
histogram!(df[ isequal.(df.sex, "male"), :body_mass_g_w], bins=3000:100:6300, 
    color="red", opacity=0.5, label="winsorized");
savefig(p9, "p9.svg"); nothing # hide
```
![](p9.svg)





