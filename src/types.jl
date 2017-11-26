boxvector(a::Vector) = a
boxvector(a) = [a]

"""
    SGFNode(properties::Pair{Symbol,Any}...)

Create an SGF node with the given properties. The parameter
`properties` is optional, which means that its possible to create
empty nodes.

Additional properties can be added at any time using the function
`setindex!` or `push!`. Note how the property values are stored
in a `Vector{Any}`. This is on purpose in order to support
multi-value properties.

```jldoctest sfgnode
julia> using SmartGameFormat

julia> node = SGFNode()
SmartGameFormat.SGFNode with 0 properties

julia> node[:KM] = 6.5; # set komi property

julia> node
SmartGameFormat.SGFNode with 1 property:
  :KM => Any[6.5]
```

While `setindex!` will always overwrite existing values, the
function `push!` will instead try to append the given value to an
existing property.

```jldoctest sfgnode
julia> push!(node, :AB => "aa")
SmartGameFormat.SGFNode with 2 properties:
  :AB => Any["aa"]
  :KM => Any[6.5]

julia> push!(node, :AB => "bb")
SmartGameFormat.SGFNode with 2 properties:
  :AB => Any["aa", "bb"]
  :KM => Any[6.5]
```
"""
struct SGFNode
    properties::Dict{Symbol,Vector{Any}}
end

SGFNode() = SGFNode(Dict{Symbol,Vector{Any}}())
SGFNode(pairs::Pair{Symbol,<:Vector}...) = SGFNode(Dict{Symbol,Vector{Any}}(pairs...))
SGFNode(pair::Pair{Symbol,<:Vector}) = SGFNode(Dict{Symbol,Vector{Any}}(pair))

# convenience constructors
SGFNode(pairs::Pair{Symbol}...) = SGFNode(map(p->p.first=>boxvector(p.second), pairs)...)
SGFNode(pair::Pair{Symbol}) = SGFNode(pair.first => boxvector(pair.second))

Base.hash(n::SGFNode, h::UInt) = hash(n.properties, hash(:SGFNode, h))
Base.:(==)(a::SGFNode, b::SGFNode) = isequal(a.properties, b.properties)

@inline Base.push!(n::SGFNode, pair::Pair{Symbol,<:Vector}) =
    push!(n.properties, pair)

function Base.push!(n::SGFNode, pair::Pair{Symbol})
    if haskey(n, pair.first)
        push!(n[pair.first], pair.second)
    else
        n[pair.first] = pair.second
    end
    n
end

for fun in (:haskey, :getindex, :getkey, :get, :keys, :values,
            :length, :keytype, :valtype)
    @eval Base.@propagate_inbounds (Base.$fun)(n::SGFNode, args...) =
        (Base.$fun)(n.properties, args...)
end

Base.@propagate_inbounds Base.setindex!(n::SGFNode, v, id) =
    Base.setindex!(n.properties, boxvector(v), id)

function Base.show(io::IO, n::SGFNode)
    if haskey(io, :compact)
        if length(n.properties) == 0
            print(io, "<no properties>")
        else
            for (i,p) in enumerate(n.properties)
                val = if length(p.second) == 1
                    s = first(p.second)
                    if length(s) > 2
                        "[…]"
                    else
                        string('[', s, ']')
                    end
                else
                    string("[…|…]")
                end
                print(io, p.first, val)
                if i > 7
                    print(io, " … (", length(n.properties) - i, " more)")
                    break
                end
                i < length(n.properties) && print(io, " ")
            end
        end
    else
        print(io, typeof(n))
        # a little hack to reuse the Dict show method
        tio = IOBuffer()
        show(tio, MIME"text/plain"(), n.properties)
        str = readstring(seek(tio,0))
        str = replace(str, "Dict{Symbol,Array{Any,1}}", "")
        str = replace(str, "entry", "property")
        str = replace(str, "entries", "properties")
        print(io, str)
    end
end

# --------------------------------------------------------------------

"""
    SGFGameTree([sequence::Vector{SGFNode}], [variations::Vector{SGFGameTree}])

Create a game tree with the given `sequence` and `variations`. Both
parameters are optional, which means that its possible to create
empty game trees.

To edit a `SGFGameTree` simply manipulate the two member
variables directly. Note that `SGFGameTree` is a subtype of
`AbstractVector{SGFNode}`, where `getindex` and `setindex!`
correspond to the appropriate node in the main game path. This
means that if there are any variations, then the first variation
must denote the continuation of the main game path.

```jldoctest
julia> using SmartGameFormat

julia> t = SGFGameTree()
0-node SmartGameFormat.SGFGameTree with 0 variation(s)

julia> push!(t.sequence, SGFNode(:KM => 6.5)); t
1-node SmartGameFormat.SGFGameTree with 0 variation(s):
 KM[6.5]

julia> t.variations = [SGFGameTree(SGFNode(:C=>"first")), SGFGameTree(SGFNode(:C=>"second"))]; t
2-node SmartGameFormat.SGFGameTree with 2 variation(s):
 KM[6.5]
 C[…]

julia> t[1]
SmartGameFormat.SGFNode with 1 property:
  :KM => Any[6.5]

julia> t[2]
SmartGameFormat.SGFNode with 1 property:
  :C => Any["first"]
```
"""
mutable struct SGFGameTree <: AbstractVector{SGFNode}
    sequence::Vector{SGFNode}
    variations::Vector{SGFGameTree}
end

SGFGameTree(sequence::Vector{SGFNode} = SGFNode[]) =
    SGFGameTree(sequence, SGFGameTree[])
SGFGameTree(node::SGFNode) =
    SGFGameTree([node])

Base.hash(t::SGFGameTree, h::UInt) = hash(t.sequence, hash(t.variations, hash(:SGFGameTree, h)))
Base.:(==)(a::SGFGameTree, b::SGFGameTree) = isequal(a.sequence, b.sequence) && isequal(a.variations, b.variations)

function Base.size(t::SGFGameTree)
    n = length(t.sequence)
    if length(t.variations) > 0
        n += size(first(t.variations))[1]
    end
    (n,)
end

function Base.getindex(t::SGFGameTree, i::Int)
    @boundscheck checkbounds(t, i)
    if i <= length(t.sequence)
        @inbounds n = t.sequence[i]
        n
    else
        @inbounds n = t.variations[1][i - length(t.sequence)]
        n
    end
end

function Base.setindex!(t::SGFGameTree, n::SGFNode, i::Int)
    @boundscheck checkbounds(t, i)
    if i <= length(t.sequence)
        @inbounds t.sequence[i] = n
    else
        @inbounds t.variations[1][i - length(t.sequence)] = n
    end
    nothing
end

function Base.summary(t::SGFGameTree)
    string(length(t), "-node ", typeof(t), " with ", length(t.variations), " variation(s)")
end
