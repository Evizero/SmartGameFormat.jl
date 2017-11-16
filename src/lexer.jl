module Lexer

struct LexicalError <: Exception end

struct Token
    name::Char
    value::String
end
Token(name::Char) = Token(name, "")

mutable struct TokenStream{I<:IO}
    io::I
    incomment::Bool
    next::Char
end
TokenStream(io::IO) = TokenStream(io, false, '\0')

for fun in (:eof, :read, :position, :seek)
    @eval (Base.$fun)(ts::TokenStream, args...) =
        (Base.$fun)(ts.io, args...)
end

iswhitespace(c::Char) = c ∈ (' ', '\t', '\r', '\n')

function next_token(ts::TokenStream)
    eof(ts) && (ts.next == '\0') && throw(EOFError())
    c = ts.next == '\0' ? read(ts, Char)::Char : ts.next
    ts.next = '\0'
    if ts.incomment && c === ']'
        ts.incomment = false
        Token(']')
    elseif ts.incomment
        buf = UInt8[c]
        while true
            eof(ts) && throw(LexicalError()) # not legal
            pos = position(ts)
            c = read(ts, Char)::Char
            if c === ']'
                ts.next = c
                break
            elseif c === '\\'
                c = read(ts, Char)::Char
                if c === '\r'
                    c = read(ts, Char)::Char
                end
                if c === '\n'
                    c = read(ts, Char)::Char
                end
                if c === ']' || c === ')' || c === ':'
                    push!(buf, c)
                end
            else
                push!(buf, c)
            end
        end
        Token('S', String(buf))
    elseif c === '['
        ts.incomment = true
        Token('[')
    elseif c === '('
        Token('(')
    elseif c === ')'
        Token(')')
    elseif c === ';'
        Token(';')
    elseif c in 'A':'Z'
        buf = UInt8[c]
        while !eof(ts)
            pos = position(ts)
            c = read(ts, Char)::Char
            if c in 'A':'Z'
                push!(buf, c)
            else
                ts.next = c
                break
            end
        end
        String(buf)
        Token('I', String(buf))
    elseif iswhitespace(c)
        next_token(ts)
    else
        throw(LexicalError())
        error("invalid character")
    end
end

end
