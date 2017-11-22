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

# --------------------------------------------------------------------

"""
    tryparse(::Type{SGFNode}, seq::Deque{Token}) -> Nullable{SGFNode}

Try to parse the next `N` token in `seq` into a
[`SGFNode`](@ref), which means that the immediate next element in
`seq` is expected to be `Token(';')` followed by zero or more
properties. Each property must have a unique identifier, or a
[`ParseError`](@ref) will be thrown.
"""
function tryparse(::Type{SGFNode}, queue::Deque)
    isempty(queue) && return Nullable{SGFNode}()
    token = front(queue)
    token.name === ';' || return Nullable{SGFNode}()
    shift!(queue)
    # parse optional properties
    properties = Dict{Symbol,Vector{Any}}()
    pair = tryparse(Pair, queue)
    while !isnull(pair)
        p = get(pair)
        haskey(properties, p.first) && throw(ParseError("property $(p.first) not unique"))
        push!(properties, p)
        pair = tryparse(Pair, queue)
    end
    # return the newly created node
    Nullable(SGFNode(properties))
end

"""
    tryparse(::Type{Pair}, seq::Deque{Token}) -> Nullable{Pair{Symbol,Vector{Any}}}

Try to parse the next `N` token in `seq` into a `Pair` denoting a
single property of a [`SGFNode`](@ref). Note that individual
properties are parsed as `Pair`, because each [`SGFNode`](@ref)
stores all its properties as a single `Dict`.

For a property to occur in `seq`, the immediate next element in
`seq` must be a `Token('I', "<ID>")`, where `<ID>` is some
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
function tryparse(::Type{Pair}, queue::Deque)
    isempty(queue) && return Nullable{Pair{Symbol,Vector{Any}}}()
    token = front(queue)
    token.name === 'I' || return Nullable{Pair{Symbol,Vector{Any}}}()
    shift!(queue)
    # identifier for the property
    identifier = Symbol(token.value)
    # there must be at least one value
    values = Any[]
    value = tryparsevalue(identifier, queue)
    isnull(value) && throw(ParseError("missing \"[\" after identifier"))
    push!(values, get(value))
    # parse optional values
    value = tryparsevalue(identifier, queue)
    while !isnull(value)
        if get(value) != nothing
            push!(values, get(value))
        end
        value = tryparsevalue(identifier, queue)
    end
    # return the newly created pair
    Nullable(identifier => values)
end

# PropValue  = "[" CValueType "]"
# CValueType = (ValueType | Compose)
# ValueType  = (None | Number | Real | Double | Color | SimpleText |
#               Text | Point  | Move | Stone)
function tryparsevalue(identifier::Symbol, queue::Deque)
    isempty(queue) && return Nullable{Any}()
    token = front(queue)
    token.name === '[' || return Nullable{Any}()
    shift!(queue)
    # parse values. There need not be one (as long as [] are there)
    value = nothing # type is going to be Any
    token = front(queue)
    if token.name === 'S'
        if identifier === :B || identifier === :W # Move (black/ white)
            # we keep string because value is game specific
            value = token.value
        elseif identifier ∈ (:KM, :BL, :WL, :V, :TM) # Real (e.g. komi)
            value = Base.parse(Float64, token.value)
        elseif identifier ∈ (:C, :GC) # String (Comment or Gamecomment)
            value = replace(token.value, "]", "\\]")
            value = replace(value, ")", "\\)")
            value = replace(value, ":", "\\:")
        else # default to use string
            value = token.value
        end
        shift!(queue)
    end
    # property value must end with a ]
    token = shift!(queue)
    token.name === ']' || throw(ParseError("missing \"]\" after property value"))
    # return the newly created value
    Nullable{Any}(value)
end

# --------------------------------------------------------------------

"""
    tryparse(::Type{SGFGameTree}, seq::Deque{Token}) -> Nullable{SGFGameTree}

Try to parse the next `N` token in `seq` into a
[`SGFGameTree`](@ref).

A game tree must start with a `Token('(')`, followed by one or
more [`SGFNode`](@ref), followed by zero or more
sub-[`SGFGameTree`](@ref), and finally end with a `Token(')')`.
"""
function tryparse(::Type{SGFGameTree}, queue::Deque)
    isempty(queue) && return Nullable{SGFGameTree}()
    token = front(queue)
    token.name === '(' || return Nullable{SGFGameTree}()
    shift!(queue)
    # parse sequence of nodes
    sequence = SGFNode[parse(SGFNode, queue)] # There must be at least one
    node = tryparse(SGFNode, queue)
    while !isnull(node)
        push!(sequence, get(node))
        node = tryparse(SGFNode, queue)
    end
    # parse sub game trees
    variations = Vector{SGFGameTree}()
    tree = tryparse(SGFGameTree, queue)
    while !isnull(tree)
        push!(variations, get(tree))
        tree = tryparse(SGFGameTree, queue)
    end
    # gametree must end with a )
    token = shift!(queue)
    token.name === ')' || throw(ParseError("missing \")\" at the end of a game tree"))
    # return the newly created gametree
    Nullable(SGFGameTree(sequence, variations))
end

# --------------------------------------------------------------------

"""
    tryparse(::Type{Vector{SGFGameTree}}, seq::Deque{Token}) -> Nullable{Vector{SGFGameTree}}

Try to parse the next `N` token in `seq` as a `Vector` of
[`SGFGameTree`](@ref). Such a vector is called a "collection".
For a collection to occur there must be at least one parse-able
[`SGFGameTree`](@ref) in `seq`.
"""
function tryparse(::Type{Vector{SGFGameTree}}, queue::Deque)
    col = SGFGameTree[parse(SGFGameTree, queue)]
    tree = tryparse(SGFGameTree, queue)
    while !isnull(tree)
        push!(col, get(tree))
        tree = tryparse(SGFGameTree, queue)
    end
    Nullable(col)
end

# --------------------------------------------------------------------

"""
    parse(ts::Lexer.TokenStream) -> Vector{SGFGameTree}

Read all the lexial token from the stream `ts` into a `Deque`,
and attempt to parse it as an SGF collection by calling
[`tryparse`](@ref). If successful, the SGF collection is returned
as a vector of [`SGFGameTree`](@ref). Note that the stream `ts`
is first converted into a `Deque{Token}` in order to support
peeking at the next [`Lexer.Token`](@ref) without removing it.

Depending on the content an exception may be thrown to signal
that it is not a legal SGF specification.

- `Base.EOFError`: Premature end-of-file encountered during
  tokenisation.

- [`Lexer.LexicalError`](@ref): illegal characters used outside
  property values. For example lower case letters for identifier.

- [`Parser.ParseError`](@ref): content is not a valid SGF
  specification (while considering the given the FF version).
"""
function parse(ts::Lexer.TokenStream)
    queue = Deque{Lexer.Token}()
    while !eof(ts)
        tkn = Lexer.next_token(ts)
        if tkn != Lexer.Token('\0')
            push!(queue, tkn)
        end
    end
    col = parse(Vector{SGFGameTree}, queue)
    # TODO: check property types (root node, etc)
    col
end

function parse(::Type{T}, queue::Deque) where T
    res = tryparse(T, queue)
    isnull(res) && throw(ParseError("unable to parse to $(T.name.name)"))
    get(res)
end

end
