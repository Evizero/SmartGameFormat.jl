struct Node
    properties::Dict{Symbol,Any}
end

for fun in (:haskey, :getindex, :getkey, :get, :keys, :values,
            :keytype, :valtype)
    @eval Base.@propagate_inbounds (Base.$fun)(n::Node, args...) =
        (Base.$fun)(n.properties, args...)
end

function Base.show(io::IO, n::Node)
    if haskey(io, :compact)
        for (i,p) in enumerate(n.properties)
            join(map(v->string('[',v,']'), p.second))
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
        print(io, typeof(n), " using a ")
        show(io, MIME"text/plain"(), n.properties)
    end
end

# --------------------------------------------------------------------

struct GameTree <: AbstractVector{Node}
    sequence::Vector{Node}
    variations::Vector{GameTree}
end

function Base.size(t::GameTree)
    n = length(t.sequence)
    if length(t.variations) > 0
        n += size(first(t.variations))[1]
    end
    (n,)
end

function Base.getindex(t::GameTree, i::Int)
    @boundscheck 0 < i <= length(t)
    if i <= length(t.sequence)
        t.sequence[i]
    else
        t.variations[1][i - length(t.sequence)]
    end
end

function Base.summary(t::GameTree)
    string(length(t), "-node ", typeof(t), " with ", length(t.variations), " variation(s)")
end

# --------------------------------------------------------------------

const Collection = Vector{GameTree}
