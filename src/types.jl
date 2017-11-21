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

Base.@propagate_inbounds Base.setindex!(n::SGFNode, v, id) =
    Base.setindex!(n.properties, boxvector(v), id)

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

function Base.show(io::IO, n::SGFNode)
    if haskey(io, :compact)
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

struct SGFGameTree <: AbstractVector{SGFNode}
    sequence::Vector{SGFNode}
    variations::Vector{SGFGameTree}
end

function Base.size(t::SGFGameTree)
    n = length(t.sequence)
    if length(t.variations) > 0
        n += size(first(t.variations))[1]
    end
    (n,)
end

function Base.getindex(t::SGFGameTree, i::Int)
    @boundscheck 0 < i <= length(t)
    if i <= length(t.sequence)
        t.sequence[i]
    else
        t.variations[1][i - length(t.sequence)]
    end
end

function Base.summary(t::SGFGameTree)
    string(length(t), "-node ", typeof(t), " with ", length(t.variations), " variation(s)")
end

# --------------------------------------------------------------------

const SGFCollection = Vector{SGFGameTree}
