module SmartGameFormat

export

    SGFStream,
    next_token

mutable struct SGFStream{I<:IO}
    io::I
    incomment::Bool
end
SGFStream(io::IO) = SGFStream(io, false)

for fun in (:eof, :read, :position, :seek)
    @eval (Base.$fun)(sgf::SGFStream, args...) = (Base.$fun)(sgf.io, args...)
end

function next_token(sgf::SGFStream)
    eof(sgf) && throw(EOFError())
    c = read(sgf, Char)::Char
    if sgf.incomment && c === ']'
        sgf.incomment = false
        "]"
    elseif sgf.incomment
        v = UInt8[c]
        while !eof(sgf)
            pos = position(sgf)
            c = read(sgf, Char)::Char
            if c in ']'
                seek(sgf, pos)
                break
            elseif c in '\\'
                c = read(sgf, Char)::Char
                if c === '\r'
                    c = read(sgf, Char)::Char
                end
                if c === '\n'
                    c = read(sgf, Char)::Char
                end
                if c === ']'
                    push!(v, c)
                end
            else
                push!(v, c)
            end
        end
        String(v)
    elseif c === '['
        sgf.incomment = true
        "["
    elseif c === '('
        "("
    elseif c === ')'
        ")"
    elseif c === ';'
        ";"
    elseif c in 'A':'Z'
        v = UInt8[c]
        while !eof(sgf)
            pos = position(sgf)
            c = read(sgf, Char)::Char
            if c in 'A':'Z'
                push!(v, c)
            else
                seek(sgf, pos)
                break
            end
        end
        String(v)
    else
        error("invalid character")
    end
end

# package code goes here

end # module
