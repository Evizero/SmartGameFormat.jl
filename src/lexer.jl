module Lexer

"""
    LexicalError(msg)

The string or stream passed to `Lexer.next_token` was not a valid
sequence of characters according to the smart game format.
"""
struct LexicalError <: Exception
    msg::String
end

"""
    Token(name::Char, [value::String])

A SGF specific lexical token. It can be either for the following:

- `Token(';')`: Separator for nodes.
- `Token('(')` and `Token(')')`: Delimiter for game trees.
- `Token('[')` and `Token(']')`: Delimiter for property values.
- `Token('I', "AB1")`: Identifier for properties. In general this
  are one or more uppercase letters. However, with the exception
  of the first position, digits are also allowed to supported
  older FF versions.
- `Token('S', "abc 23(\\)")`: Any property value between `'['`
  and `']'`. This includes moves, numbers, and text.
"""
struct Token
    name::Char
    value::String
end

Token(name::Char) = Token(name, "")

"""
    TokenStream(io::IO)

Stateful decorator around an `io` to create [`Token`](@ref) from
using [`next_token`](@ref).
"""
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

"""
    next_token(ts::TokenStream) -> Token

Reads and returns the next `Token` from the given stream `ts`.
"""
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
            c = read(ts, Char)::Char
            @label check_c_again
            if c === ']'
                ts.next = c
                break
            elseif c === '\\'
                c = read(ts, Char)::Char
                consumed = false
                # newlines are removed after '\\'
                if c === '\r'
                    # consume additional \n if it exists
                    c = read(ts, Char)::Char
                    if c != '\n'
                        @goto check_c_again
                    end
                elseif c === '\n'
                    # consume additional \r if it exists
                    c = read(ts, Char)::Char
                    if c != '\r'
                        @goto check_c_again
                    end
                elseif iswhitespace(c)
                    push!(buf, ' ')
                else
                    # everything else is stored verbatim
                    # this includes ']', ')', and ':'
                    push!(buf, c)
                end
            elseif c === '\r'
                # we represent newlines always as a single \n
                push!(buf, '\n')
                # consume additional \n if it exists
                c = read(ts, Char)::Char
                if c != '\n'
                    @goto check_c_again
                end
            elseif c === '\n'
                push!(buf, '\n')
                # consume additional \r if it exists
                c = read(ts, Char)::Char
                if c != '\r'
                    @goto check_c_again
                end
            elseif iswhitespace(c)
                # since newlines are already processed at this point,
                # every other whitespace can be replaced with ' '
                push!(buf, ' ')
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
        while true
            c = read(ts, Char)::Char
            if c in 'A':'Z'
                push!(buf, c)
            elseif c in '0':'9' # compatibility with FF[3]
                push!(buf, c)
            else
                ts.next = c
                break
            end
        end
        Token('I', String(buf))
    elseif iswhitespace(c)
        next_token(ts)
    else
        throw(LexicalError("Invalid character: \"$c\""))
    end
end

end
