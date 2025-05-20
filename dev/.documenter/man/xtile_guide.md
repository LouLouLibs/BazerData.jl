
# Xtile {#Xtile}

The function `xtile` tries to emulate stata [xtile](https://www.stata.com/manuals/dpctile.pdf) function.

There is a [`BinScatter.jl`](https://github.com/matthieugomez/Binscatters.jl) package which already implements these features.

## Basic usage {#Basic-usage}

Start with a simple distribution to visualize the effect of _winsorizing_

```julia
Random.seed!(3); x = randn(10_000);
p1 = histogram(x,
    bins=-4:0.1:4, alpha=0.25, color="grey", label="",
    framestyle=:box, size=(1250,750))
```



![](p1.svg)


The quintiles split the distribution:

```julia
x_tile = hcat(x, xtile(x, 5))
p2 = histogram(x, bins=-4:0.1:4, alpha=0.25, color="grey",
    label="", framestyle=:box);
[ histogram!(x_tile[ x_tile[:, 2] .== i , 1], bins=-4:0.1:4,
             alpha=0.75, label="quantile bin $i")
  for i in 0:4 ];
```



![](p2.svg)


It is possible to include weights

```julia
x_sorted = sort(x)
x_tile_weights = xtile(x_sorted, 5,
                       weights=Weights([ log(i)/i for i in 1:length(x)]) )
p3 = histogram(x, bins=-4:0.1:4, alpha=0.25, color="grey",
    label="", framestyle=:box);
[ histogram!(x_sorted[x_tile_weights.==i], bins=-4:0.1:4,
             alpha=0.75, label="quantile bin $i")
  for i in 0:4 ];
```



![](p3.svg)

