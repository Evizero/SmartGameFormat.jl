module Parser

using DataStructures
using ..Lexer

struct ParseError <: Exception
    msg::String
end

# --------------------------------------------------------------------

struct Node
    properties::Dict{Symbol,Any}
end

function Base.show(io::IO, n::Node)
    print(io, "; ")
    for p in n.properties
        showproperty(io, p)
    end
end

function showproperty(io::IO, p::Pair)
    print(io, p.first, join(map(v->string('[',v,']'), p.second)))
end

# Node = ";" { Property }
function tryparse(::Type{Node}, queue::Deque)
    token = front(queue)
    token.name === ';' || return Nullable{Node}()
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
    Nullable(Node(properties))
end

# Property = PropIdent PropValue { PropValue }
function tryparse(::Type{Pair}, queue::Deque)
    token = front(queue)
    token.name === 'I' || return Nullable{Node}()
    shift!(queue)
    # identifier for the property
    identifier = Symbol(token.value)
    # there must be at least one value
    values = Any[] # There must be at least one
    value = tryparsevalue(identifier, queue)
    isnull(value) && throw(ParseError("[ expected"))
    push!(values, get(value))
    # parse optional values
    value = tryparsevalue(identifier, queue)
    while !isnull(value)
        get(value) != nothing && push!(values, get(value))
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
    token.name === '[' || return Nullable{Node}()
    shift!(queue)
    # parse values. There need not be one (as long as [] are there)
    value = nothing # type is going to be Any
    token = front(queue)
    if token.name === 'S'
        if identifier == :KM # komi
            value = Base.parse(Float64, token.value)
        elseif identifier == :C # komi
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
    token.name === ']' || throw(ParseError("] expected"))
    # return the newly created value
    Nullable(value)
end

# --------------------------------------------------------------------

struct GameTree
    sequence::Vector{Node}
    children::Vector{GameTree}
end

function Base.show(io::IO, t::GameTree)
    print(io, "(")
    for p in t.sequence
        print(io, p)
    end
    for c in t.children
        println(io)
        print(io, c)
    end
    print(io, ")")
end

# GameTree = "(" Sequence { GameTree } ")"
# Sequence = Node { Node }
function tryparse(::Type{GameTree}, queue::Deque)
    token = front(queue)
    token.name === '(' || return Nullable{GameTree}()
    shift!(queue)
    # parse sequence of nodes
    sequence = Node[parse(Node, queue)] # There must be at least one
    node = tryparse(Node, queue)
    while !isnull(node)
        push!(sequence, get(node))
        node = tryparse(Node, queue)
    end
    # parse sub game trees
    children = Vector{GameTree}()
    tree = tryparse(GameTree, queue)
    while !isnull(tree)
        push!(children, get(tree))
        tree = tryparse(GameTree, queue)
    end
    # return the newly created gametree
    Nullable(GameTree(sequence, children))
end

# --------------------------------------------------------------------

struct Collection
    children::Vector{GameTree}
end

function Base.show(io::IO, col::Collection)
    print(io, join((string(c) for c in col.children), "\n"))
end

# Collection = GameTree { GameTree }
function tryparse(::Type{Collection}, queue::Deque)
    trees = GameTree[parse(GameTree, queue)]
    tree = tryparse(GameTree, queue)
    while !isnull(tree)
        push!(trees, get(tree))
        tree = tryparse(GameTree, queue)
    end
    Nullable(Collection(trees))
end

# --------------------------------------------------------------------

parse(io::IO) = parse(Lexer.TokenStream(io))

function parse(ts::Lexer.TokenStream)
    queue = Deque{Lexer.Token}()
    while !eof(ts)
        push!(queue, Lexer.next_token(ts))
    end
    parse(Collection, queue)
end

function parse(::Type{T}, queue::Deque) where T
    res = tryparse(T, queue)
    isnull(res) && throw(ParseError("$T expected"))
    get(res)
end

end
