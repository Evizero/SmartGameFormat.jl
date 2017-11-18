module SmartGameFormat

using DataStructures
using Crayons

export

    load_sgf,
    parse_sgf,
    print_sgf

include("types.jl")
include("lexer.jl")
include("parser.jl")
include("prettyprint.jl")

load_sgf(path::String) = open(parse_sgf, path)

parse_sgf(str::String) = parse_sgf(IOBuffer(str))
parse_sgf(io::IO) = Parser.parse(io)

end # module
