# Xtile

The function `xtile` tries to emulate stata [xtile](https://www.stata.com/manuals/dpctile.pdf) function.

There is a [`BinScatter.jl`](https://github.com/matthieugomez/Binscatters.jl) package which already implements these features.


```@setup hist
import Pkg; Pkg.add("Plots");
using Plots, Random, StatsBase, BazerData
gr(); theme(:wong2); Plots.default(display_type=:inline, size=(1250,750), thickness_scaling=1)
```


## Basic usage

Start with a simple distribution to visualize the effect of *winsorizing*
```@example hist
Random.seed!(3); x = randn(10_000);
p1 = histogram(x, 
    bins=-4:0.1:4, alpha=0.25, color="grey", label="",
    framestyle=:box, size=(1250,750))
savefig(p1, "p1.svg"); nothing # hide
```
![](p1.svg)


The quintiles split the distribution:
```@example hist; 
x_tile = hcat(x, xtile(x, 5))
p2 = histogram(x, bins=-4:0.1:4, alpha=0.25, color="grey", 
    label="", framestyle=:box); 
[ histogram!(x_tile[ x_tile[:, 2] .== i , 1], bins=-4:0.1:4, 
             alpha=0.75, label="quantile bin $i") 
  for i in 0:4 ];
savefig(p2, "p2.svg"); nothing # hide
```
![](p2.svg)


It is possible to include weights
```@example hist;
x_sorted = sort(x)
x_tile_weights = xtile(x_sorted, 5, 
                       weights=Weights([ log(i)/i for i in 1:length(x)]) ) 
p3 = histogram(x, bins=-4:0.1:4, alpha=0.25, color="grey", 
    label="", framestyle=:box); 
[ histogram!(x_sorted[x_tile_weights.==i], bins=-4:0.1:4, 
             alpha=0.75, label="quantile bin $i") 
  for i in 0:4 ];
savefig(p3, "p3.svg"); nothing # hide
```
![](p3.svg)






