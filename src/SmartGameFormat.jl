module SmartGameFormat

using DataStructures
using Crayons

export

    SGFNode,
    SGFGameTree,

    load_sgf,
    save_sgf,
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
[`SGFGameTree`](@ref) (i.e. a `Vector{SGFGameTree}`).

```jldoctest
julia> using SmartGameFormat

julia> path = joinpath(Pkg.dir("SmartGameFormat"), "examples", "sample.sgf");

julia> col = load_sgf(path)
1-element Array{SmartGameFormat.SGFGameTree,1}:
 SmartGameFormat.SGFNode[FF[4] GM[1] SZ[19], B[aa], W[bb], B[cc]]

julia> col[1]
4-node SmartGameFormat.SGFGameTree with 2 variation(s):
 FF[4] GM[1] SZ[19]
 B[aa]
 W[bb]
 B[cc]
```
"""
load_sgf(path::String) = open(parse_sgf, path)

"""
    save_sgf(path::String, sgf)

Write the given `sgf` object (e.g. [`SGFNode`](@ref), or
[`SGFGameTree`](@ref)) into the given file at `path`. Note that
it is a current limitation that the character encoding is
hardcoded to UTF8 (no matter what any property specifies).

```jldoctest
julia> using SmartGameFormat

julia> save_sgf("/tmp/example.sgf", SGFGameTree(SGFNode(:KM => 6.5)))

julia> readstring("/tmp/example.sgf") # take a look at file content
"(; KM[6.5])"
```
"""
function save_sgf(path::String, sgf)
    open(path, "w") do io
        print_sgf(io, sgf, color = false)
    end
end

"""
    parse_sgf(io::IO) -> Vector{SGFGameTree}
    parse_sgf(str::String) -> Vector{SGFGameTree}

Read the content from `io` (or `str`), and attempt to parse it as
an SGF collection. If successful, the collection is returned as a
vector of [`SGFGameTree`](@ref). In most cases this collection
will just have a single tree.

```jldoctest
julia> using SmartGameFormat

julia> col = parse_sgf("(; FF[4] KM[6.5]; B[aa])")
1-element Array{SmartGameFormat.SGFGameTree,1}:
 SmartGameFormat.SGFNode[KM[6.5] FF[4], B[aa]]

julia> tree = col[1]
2-node SmartGameFormat.SGFGameTree with 0 variation(s):
 KM[6.5] FF[4]
 B[aa]

julia> node = tree[1]
SmartGameFormat.SGFNode with 2 properties:
  :KM => Any[6.5]
  :FF => Any[4]
```

Depending on the content an exception may be thrown to signal
that it is not a legal SGF specification.

- `Base.EOFError`: Premature end-of-file encountered during
  tokenisation.

- [`Lexer.LexicalError`](@ref): illegal characters used outside
  property values. For example lower case letters for identifier.

- [`Parser.ParseError`](@ref): content is not a valid SGF
  specification (while considering the given the FF version).

Internally, the function simply calls [`Parser.parse`](@ref).
Take a look at the corresponding documentation for more details.
"""
parse_sgf(str::String) = parse_sgf(IOBuffer(str))
parse_sgf(io::IO) = Parser.parse(Lexer.TokenStream(io))


end # module
