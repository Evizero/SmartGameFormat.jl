module Parser

using DataStructures
using ..Lexer
using ..SGFNode, ..SGFGameTree, ..SGFCollection

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

# SGFNode = ";" { Property }
function tryparse(::Type{SGFNode}, queue::Deque)
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

# Property = PropIdent PropValue { PropValue }
function tryparse(::Type{Pair}, queue::Deque)
    token = front(queue)
    token.name === 'I' || return Nullable{SGFNode}()
    shift!(queue)
    # identifier for the property
    identifier = Symbol(token.value)
    # there must be at least one value
    values = Any[] # There must be at least one
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
    token = front(queue)
    token.name === '[' || return Nullable{SGFNode}()
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
    Nullable(value)
end

# --------------------------------------------------------------------

# SGFGameTree = "(" Sequence { SGFGameTree } ")"
# Sequence = SGFNode { SGFNode }
function tryparse(::Type{SGFGameTree}, queue::Deque)
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
    # return the newly created gametree
    Nullable(SGFGameTree(sequence, variations))
end

# --------------------------------------------------------------------

# SGFCollection = SGFGameTree { SGFGameTree }
function tryparse(::Type{SGFCollection}, queue::Deque)
    col = SGFGameTree[parse(SGFGameTree, queue)]
    tree = tryparse(SGFGameTree, queue)
    while !isnull(tree)
        push!(col, get(tree))
        tree = tryparse(SGFGameTree, queue)
    end
    Nullable(col)
end

# --------------------------------------------------------------------

parse(io::IO) = parse(Lexer.TokenStream(io))

function parse(ts::Lexer.TokenStream)
    queue = Deque{Lexer.Token}()
    while !eof(ts)
        tkn = Lexer.next_token(ts)
        if tkn != Lexer.Token('\0')
            push!(queue, tkn)
        end
    end
    col = parse(SGFCollection, queue)
    # TODO: check property types (root node, etc)
    col
end

function parse(::Type{T}, queue::Deque) where T
    res = tryparse(T, queue)
    isnull(res) && throw(ParseError("$(T.name.name) expected"))
    get(res)
end

end
