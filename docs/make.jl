#!/usr/bin/env julia


push!(LOAD_PATH, "../src/")
# import Pkg; Pkg.develop(path="..")
# locally : julia --color=yes --project make.jl

# -- 
using BazerData
using Documenter
using DocumenterVitepress

# -- 
DocMeta.setdocmeta!(BazerData, :DocTestSetup, :(using BazerData); 
    recursive=true)

# -- 
makedocs(
    format = Documenter.HTML(
        size_threshold = 512_000,          # KiB — raise above your largest file
        size_threshold_warn = 256_000,     # optional
        example_size_threshold = 200_000,  # bytes — for large @example blocks
    ),
    # format = MarkdownVitepress(
    #     repo = "https://github.com/eloualiche/BazerData.jl",
    #     devurl = "dev",
    #     devbranch = "build",
    #     deploy_url = "eloualiche.github.io/BazerData.jl",
    #     description = "BazerData.jl",
    # ),
    # repo = Remotes.GitHub("eloualiche", "BazerData.jl"),
    sitename = "BazerData.jl",
    modules  = [BazerData],
    authors = "Erik Loualiche",
    # version = "0.7.1",
    # version = "dev",
    version = "",
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
    ],

)


deploydocs(;
    repo = "github.com/louloulibs/BazerData.jl",
    target = "build", # this is where Vitepress stores its output
    # devbranch = "main",
    branch = "gh-pages",
    push_preview = true,
    # versions = ["dev"]  # This specifies which versions to deploy
)


deploydocs(;
    repo = "github.com/louloulibs/BazerData.jl",
    devbranch = "build",
)
