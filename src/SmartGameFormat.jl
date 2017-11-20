module SmartGameFormat

using DataStructures
using Crayons

export

    SGFNode,
    SGFGameTree,

    load_sgf,
    parse_sgf,
    print_sgf

include("types.jl")
include("lexer.jl")
include("parser.jl")
include("prettyprint.jl")

"""
    load_sgf(path::String) -> Vector{SGFGameTree}

Read the content from the file at `path`, and call
[`parse_sgf`](@ref) to convert it to a collection of
[`SGFGameTree`](@ref).
"""
load_sgf(path::String) = open(parse_sgf, path)

"""
    load_sgf(io::IO) -> Vector{SGFGameTree}
    load_sgf(str::String) -> Vector{SGFGameTree}

Read the content from `io` (or `str`), and attempt to parse it as
an SGF collection. If successful, the collection is returned as a
vector of [`SGFGameTree`](@ref). In most cases this collection
will just have a single tree.

Depending on the content an exception may be thrown to signal
that it is not a legal SGF specification.

- `Base.EOFError`: Premature end-of-file encountered during
  tokenisation.

- [`Lexer.LexicalError`](@ref): illegal characters used outside
  property values. For example lower case letters for identifier.

- [`Parser.ParseError`](@ref): content is not a valid SGF
  specification (while considering the given the FF version).
"""
parse_sgf(str::String) = parse_sgf(IOBuffer(str))
parse_sgf(io::IO) = Parser.parse(io)

end # module
