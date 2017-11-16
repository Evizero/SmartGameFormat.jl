struct Property
    identifier::Symbol
    values::Vector{Any}
end

struct Node
    properties::Vector{Property}
    children::Vector{Node}
end

struct GameTree
    sequence::Vector{Node}
    children::Vector{GameTree}
end

struct Collection
    children::Vector{GameTree}
end

