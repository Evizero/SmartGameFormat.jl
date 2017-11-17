module SmartGameFormat

using DataStructures

export

    load_sgf,
    parse_sgf

include("types.jl")
include("lexer.jl")
include("parser.jl")

function load_sgf(path::String)
    open(path) do io
        parse_sgf(io)
    end
end

parse_sgf(str::String) = parse_sgf(IOBuffer(str))
parse_sgf(io::IO) = Parser.parse(io)

end # module
