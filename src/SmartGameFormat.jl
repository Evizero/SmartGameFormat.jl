module SmartGameFormat

using DataStructures

export

    load_sgf,
    parse_sgf

include("types.jl")
include("lexer.jl")
include("parser.jl")

load_sgf(path::String) = open(parse_sgf, path)

parse_sgf(str::String) = parse_sgf(IOBuffer(str))
parse_sgf(io::IO) = Parser.parse(io)

end # module
