using Documenter, SmartGameFormat

makedocs(
    modules = [SmartGameFormat],
    clean = false,
    format = :html,
    sitename = "SmartGameFormat.jl",
    authors = "Christof Stocker",
    linkcheck = !("skiplinks" in ARGS),
    pages = Any[
        "Home" => "index.md",
        "Internals" => Any[
            "lexer.md",
            "parser.md",
        ]
    ],
    html_prettyurls = !("local" in ARGS),
)

deploydocs(
    repo = "github.com/Evizero/SmartGameFormat.jl.git",
    target = "build",
    julia = "0.6",
    deps = nothing,
    make = nothing,
)
