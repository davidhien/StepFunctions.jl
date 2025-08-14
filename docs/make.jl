using StepFunctions
using Documenter

DocMeta.setdocmeta!(StepFunctions, :DocTestSetup, :(using StepFunctions); recursive=true)

makedocs(;
    modules=[StepFunctions],
    authors="davidhien <david.hien@outlook.de> and contributors",
    sitename="StepFunctions.jl",
    format=Documenter.HTML(;
<<<<<<< HEAD
        canonical="https://David Hien.github.io/StepFunctions.jl",
=======
        canonical="https://davidhien.github.io/StepFunctions.jl",
>>>>>>> dev
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
<<<<<<< HEAD
    repo="github.com/David Hien/StepFunctions.jl",
=======
    repo="github.com/davidhien/StepFunctions.jl",
>>>>>>> dev
    devbranch="main",
)
