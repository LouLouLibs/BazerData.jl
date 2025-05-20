#!/usr/bin/env julia


push!(LOAD_PATH, "../src/")
import Pkg; Pkg.develop(path="..")
# locally : julia --color=yes --project make.jl

# -- 
using BazerData
using Documenter
using DocumenterVitepress

# -- 
makedocs(
    # format = Documenter.HTML(),
    format = MarkdownVitepress(
        repo = "https://github.com/eloualiche/BazerData.jl",
    ),
    repo = Remotes.GitHub("eloualiche", "BazerData.jl"),
    sitename = "BazerData.jl",
    modules  = [BazerData],
    authors = "Erik Loualiche",
    pages=[
        "Home" => "index.md",
        "Manual" => [
            "man/xtile_guide.md",
            "man/winsorize_guide.md"
        ],
        "Demos" => [
            "demo/stata_utils.md",
        ],
        "Library" => [
            "lib/public.md",
            "lib/internals.md"
        ]
    ]
)


deploydocs(;
    repo = "github.com/eloualiche/BazerData.jl",
    target = "build", # this is where Vitepress stores its output
    devbranch = "main",
    branch = "gh-pages",
    push_preview = true,
)


# deploydocs(;
#     repo = "github.com/eloualiche/BazerData.jl",
#     devbranch = "build",
# )

# deploydocs(;
#     repo = "github.com/eloualiche/BazerData.jl",
#     target = "build",
#     branch = "gh-pages",
# )

