#!/usr/bin/env julia

push!(LOAD_PATH, "../src/")

using BazerData
using Documenter

DocMeta.setdocmeta!(BazerData, :DocTestSetup, :(using BazerData);
    recursive=true)

makedocs(
    format = Documenter.HTML(
        size_threshold = 512_000,
        size_threshold_warn = 256_000,
        example_size_threshold = 200_000,
    ),
    sitename = "BazerData.jl",
    modules  = [BazerData],
    authors = "Erik Loualiche",
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
    target = "build",
    branch = "gh-pages",
    push_preview = true,
)
