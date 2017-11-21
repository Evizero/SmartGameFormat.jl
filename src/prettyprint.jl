function print_crayon(io::IO, crayon, color)
    if color
        print(io, crayon)
    end
    nothing
end

"""
    print_sgf([io], sgf; [color = true])

Writes the given parsed `sfg` to `io` (defaults to `STDOUT`).
If the keyword parameter `color = true` then an ANSI based syntax
highlighting will be used.
"""
function print_sgf(A; color = true)
    print_sgf(STDOUT, A; color = color)
end

function print_sgf(io::IO, n::SGFNode; color = true)
    print_crayon(io, Crayon(foreground = 243, bold = true), color)
    print(io, ";")
    print_crayon(io, Crayon(reset = true), color)
    for p in n.properties
        print_sgf(io, p; color = color)
    end
end

function print_sgf(io::IO, p::Pair; color = true)
    print_crayon(io, Crayon(foreground = 67), color)
    print(io, " ", p.first)
    print_crayon(io, Crayon(reset = true), color)
    for v in p.second
        print(io, "[")
        print_crayon(io, Crayon(foreground = 143), color)
        print(io, v)
        print_crayon(io, Crayon(reset = true), color)
        print(io, "]")
    end
end

function print_sgf(io::IO, t::SGFGameTree; color = true)
    print_crayon(io, Crayon(foreground = 173), color)
    print(io, "(")
    print_crayon(io, Crayon(reset = true), color)
    for n in t.sequence
        print_sgf(io, n; color = color)
    end
    for c in t.variations
        println(io)
        print_sgf(io, c; color = color)
    end
    print_crayon(io, Crayon(foreground = 173), color)
    print(io, ")")
    print_crayon(io, Crayon(reset = true), color)
end

function print_sgf(io::IO, col::AbstractVector{SGFGameTree}; color = true)
    for (i,t) in enumerate(col)
        print_sgf(io, t; color = color)
        i < length(col) && println(io)
    end
end
