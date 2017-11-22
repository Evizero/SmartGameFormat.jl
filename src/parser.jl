"""
The `Parser` sub-module is concerned with converting a sequence
of [`Lexer.Token`](@ref) into a collection (i.e. a vector) of
[`SGFGameTree`](@ref).

To that end it provides the following functionality:

- [`Parser.parse`](@ref)
- [`Parser.tryparse`](@ref)
- [`Parser.ParseError`](@ref)
"""
module Parser

using DataStructures
using ..Lexer
using ..SGFNode, ..SGFGameTree

"""
    ParseError(msg)

The expression passed to `Parser.parse` could not be interpreted
as a valid SGF specification (in accordance with the specified FF
version).
"""
struct ParseError <: Exception
    msg::String
end

"""
    ParseContext()

Context information used during parsing. It stores temporary data
such as the encountered game type and file format version.
"""
mutable struct ParseContext
    isrootnode::Bool
    version::Int
    gametype::Int
end

ParseContext() = ParseContext(true, 0, 0)

# --------------------------------------------------------------------

"""
    parse(ts::Lexer.TokenStream) -> Vector{SGFGameTree}

Read all the lexical [`Lexer.Token`](@ref) from the
[`Lexer.TokenStream`](@ref) `ts`, and attempt to parse the
sequence of token as an SGF collection. To accomplish this it
uses the function [`tryparse`](@ref). If successful, the SGF
collection is returned as a `Vector` of [`SGFGameTree`](@ref).

Depending on the content, any of the following exceptions may be
thrown to signal that it is not a legal SGF specification.

- `Base.EOFError`: Premature end-of-file encountered during
  tokenisation.

- [`Lexer.LexicalError`](@ref): Illegal characters used outside
  property values. For example lower case letters for identifier.

- [`Parser.ParseError`](@ref): Content is not a valid SGF
  specification (while considering the given the FF version).
"""
function parse(ts::Lexer.TokenStream)
    parse(Vector{SGFGameTree}, ts, ParseContext())
end

"""
    parse(::Type{T}, ts::Lexer.TokenStream, ctx::ParseContext) -> T

Same as the corresponding [`tryparse`](@ref) method, but instead
of returning a `Nullable` it throws a [`ParseError`](@ref) if it
is unable to parse the next `N` token in `ts` to type `T`.
"""
function parse(::Type{T}, ts::Lexer.TokenStream, ctx::ParseContext) where T
    res = tryparse(T, ts, ctx)
    isnull(res) && throw(ParseError("unable to parse to $(T.name.name)"))
    get(res)
end

# --------------------------------------------------------------------

"""
    tryparse(::Type{Vector{SGFGameTree}}, ts::Lexer.TokenStream, ctx::ParseContext) -> Nullable{Vector{SGFGameTree}}

Try to parse the next `N` token in `ts` as a `Vector` of
[`SGFGameTree`](@ref). Such a vector is called a "collection".
For a collection to occur there must be at least one parse-able
[`SGFGameTree`](@ref) in `ts`.
"""
function tryparse(::Type{Vector{SGFGameTree}}, ts::Lexer.TokenStream, ctx::ParseContext)
    ctx.isrootnode = true
    col = SGFGameTree[parse(SGFGameTree, ts, ctx)]
    ctx.isrootnode = true
    tree = tryparse(SGFGameTree, ts, ctx)
    while !isnull(tree)
        push!(col, get(tree))
        ctx.isrootnode = true
        tree = tryparse(SGFGameTree, ts, ctx)
    end
    Nullable(col)
end

# --------------------------------------------------------------------

"""
    tryparse(::Type{SGFGameTree}, ts::Lexer.TokenStream, ctx::ParseContext) -> Nullable{SGFGameTree}

Try to parse the next `N` token in `ts` into a
[`SGFGameTree`](@ref).

A game tree must start with a `Token('(')`, followed by one or
more [`SGFNode`](@ref), followed by zero or more
sub-[`SGFGameTree`](@ref), and finally end with a `Token(')')`.
"""
function tryparse(::Type{SGFGameTree}, ts::Lexer.TokenStream, ctx::ParseContext)
    eof(ts) && return Nullable{SGFGameTree}()
    token = Lexer.peek(ts, Lexer.Token)
    token.name === '(' || return Nullable{SGFGameTree}()
    read(ts, Lexer.Token)
    # parse sequence of nodes. There must be at least one
    sequence = SGFNode[parse(SGFNode, ts, ctx)]
    ctx.isrootnode = false
    node = tryparse(SGFNode, ts, ctx)
    while !isnull(node)
        push!(sequence, get(node))
        node = tryparse(SGFNode, ts, ctx)
    end
    # parse sub game trees
    variations = Vector{SGFGameTree}()
    tree = tryparse(SGFGameTree, ts, ctx)
    while !isnull(tree)
        push!(variations, get(tree))
        tree = tryparse(SGFGameTree, ts, ctx)
    end
    # gametree must end with a )
    token = read(ts, Lexer.Token)
    token.name === ')' || throw(ParseError("missing \")\" at the end of a game tree"))
    # return the newly created gametree
    Nullable(SGFGameTree(sequence, variations))
end

# --------------------------------------------------------------------

"""
    tryparse(::Type{SGFNode}, ts::Lexer.TokenStream, ctx::ParseContext) -> Nullable{SGFNode}

Try to parse the next `N` token in `ts` into a
[`SGFNode`](@ref), which means that the immediate next element in
`ts` is expected to be `Token(';')` followed by zero or more
properties. Each property must have a unique identifier, or a
[`ParseError`](@ref) will be thrown.
"""
function tryparse(::Type{SGFNode}, ts::Lexer.TokenStream, ctx::ParseContext)
    token = Lexer.peek(ts, Lexer.Token)
    token.name === ';' || return Nullable{SGFNode}()
    read(ts, Lexer.Token)
    # parse optional properties
    properties = Dict{Symbol,Vector{Any}}()
    pair = tryparse(Pair, ts, ctx)
    while !isnull(pair)
        p = get(pair)
        haskey(properties, p.first) && throw(ParseError("property $(p.first) not unique"))
        push!(properties, p)
        pair = tryparse(Pair, ts, ctx)
    end
    # return the newly created node
    Nullable(SGFNode(properties))
end

"""
    tryparse(::Type{Pair}, ts::Lexer.TokenStream, ctx::ParseContext) -> Nullable{Pair{Symbol,Vector{Any}}}

Try to parse the next `N` token in `ts` into a `Pair` denoting a
single property of a [`SGFNode`](@ref). Note that individual
properties are parsed as `Pair`, because each [`SGFNode`](@ref)
stores all its properties as a single `Dict`.

For a property to occur in `ts`, the immediate next element in
`ts` must be a `Token('I', "<ID>")`, where `<ID>` is some
sequence of uppercase letters denoting the identifier of the
token. After the identifier there can be one or more property
*values*. There must be at least one property value.

Each property value must be delimited by a `Token('[')` at the
beginning and a `Token(']')` at the end. The value itself is
contained within those two delimiter token as a single
`Token('S', "<val>")` where `<val>` denotes the value. Note that
this "S" token is optional and its absence means that the
property value is the empty value.
"""
function tryparse(::Type{Pair}, ts::Lexer.TokenStream, ctx::ParseContext)
    token = Lexer.peek(ts, Lexer.Token)
    token.name === 'I' || return Nullable{Pair{Symbol,Vector{Any}}}()
    read(ts, Lexer.Token)
    # identifier for the property
    id = Symbol(token.value)
    if id ∈ (:AP, :CA, :FF, :GM, :ST, :SZ)
        ctx.isrootnode || throw(ParseError("found root property $id in non-root node"))
    end
    # there must be at least one value
    values = Any[]
    value = tryparsevalue(id, ts, ctx)
    isnull(value) && throw(ParseError("missing \"[\" after identifier"))
    push!(values, get(value))
    # parse optional values
    value = tryparsevalue(id, ts, ctx)
    while !isnull(value)
        if get(value) != nothing
            push!(values, get(value))
        end
        value = tryparsevalue(id, ts, ctx)
    end
    # return the newly created pair
    Nullable(id => values)
end

# PropValue  = "[" CValueType "]"
# CValueType = (ValueType | Compose)
# ValueType  = (None | Number | Real | Double | Color | SimpleText |
#               Text | Point  | Move | Stone)
function tryparsevalue(id::Symbol, ts::Lexer.TokenStream, ctx::ParseContext)
    token = Lexer.peek(ts, Lexer.Token)
    token.name === '[' || return Nullable{Any}()
    read(ts, Lexer.Token)
    # parse values. There need not be one (as long as [] are there)
    value = nothing # type is going to be Any
    token = Lexer.peek(ts, Lexer.Token)
    if token.name === 'S'
        if id === :B || id === :W # Move (black/ white)
            # we keep string because value is game specific
            # TODO: special move type for GO ?
            value = token.value
        elseif id ∈ (:C, :GC)
            # Text (Comment or Gamecomment)
            value = token.value
        elseif id ∈ [:CA,  :N, :AN, :BR, :BT, :CP, :DT, :EV, :GN,
                     :ON, :OT, :PB, :PC, :PW, :RE, :RO, :RU, :SO,
                     :US, :WR, :WT]
            # SimpleText (no newlines)
            value = replace(token.value, r"(\r?\n)|(\n?\r)", "")
            if id == :CA && uppercase(value) != "UTF-8"
                warn("unsupported charset specified in CA: \"$value\"")
            end
        elseif id ∈ [:HA, :MN, :OB, :OW, :PM, :FF, :GM, :ST]
            # Number (e.g. handicap, fileformat)
            nval = Base.tryparse(Int, token.value)
            isnull(nval) && throw(ParseError("illegal value for property $id: \"$(token.value)\" (unable to parse as Int)"))
            value = get(nval)
            if id == :FF
                1 <= value <= 4 || throw(ParseError("unknown file format FF[$value]"))
                value < 4 && warn("specified version \"FF[$value]\" may not be fully supported")
                ctx.version = value
            elseif id == :GM
                # value == 1 --> Go
                ctx.gametype = value
            end
        elseif id ∈ (:KM, :BL, :WL, :V, :TM)
            # Real (e.g. komi)
            nval = Base.tryparse(Float64, token.value)
            isnull(nval) && throw(ParseError("illegal value for property $id: \"$(token.value)\" (unable to parse as Float64)"))
            value = get(nval)
        else # default to use string
            value = token.value
        end
        read(ts, Lexer.Token)
    end
    # property value must end with a ]
    token = read(ts, Lexer.Token)
    token.name === ']' || throw(ParseError("missing \"]\" after property value"))
    # return the newly created value
    Nullable{Any}(value)
end

end
