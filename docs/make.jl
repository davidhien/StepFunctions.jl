using StepFunctions
using Documenter

DocMeta.setdocmeta!(StepFunctions, :DocTestSetup, :(using StepFunctions); recursive=true)

makedocs(;
    modules=[StepFunctions],
    authors="davidhien <david.hien@outlook.de> and contributors",
    sitename="StepFunctions.jl",
    format=Documenter.HTML(;
        canonical="https://David Hien.github.io/StepFunctions.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/David Hien/StepFunctions.jl",
    devbranch="main",
)
