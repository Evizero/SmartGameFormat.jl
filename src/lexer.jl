"""
The `Lexer` sub-module is concerned with transcribing a given
stream of characters into a sequence of domain specific lexical
units called "token".

Basic usage:

1. Wrap a plain `IO` object into a [`Lexer.TokenStream`](@ref).
2. Call [`Lexer.next_token`](@ref) to collect another
   [`Lexer.Token`](@ref).
3. Goto 2. unless end of file is reached.
"""
module Lexer

using Base.UTF8proc.isspace

"""
    LexicalError(msg)

The string or stream passed to [`Lexer.next_token`](@ref) was not
a valid sequence of characters according to the smart game
format.
"""
struct LexicalError <: Exception
    msg::String
end

"""
    Token(name::Char, [value::String])

A SGF specific lexical token. It can be either for the following:

- `Token('\\0')`: Empty token to denote trailing whitespaces.
- `Token(';')`: Separator for nodes.
- `Token('(')` and `Token(')')`: Delimiter for game trees.
- `Token('[')` and `Token(']')`: Delimiter for property values.
- `Token('I', "AB1")`: Identifier for properties. In general these
  are made up of one or more uppercase letters. However, with the
  exception of the first position, digits are also allowed to
  occur. This is done in order to supported older FF versions.
- `Token('S', "abc 23(\\)")`: Any property value between `'['`
  and `']'`. This includes moves, numbers, simple text, and text.
"""
struct Token
    name::Char
    value::String
end

Token(name::Char) = Token(name, "")

Base.hash(t::Token, h::UInt) = hash(t.name, hash(t.value, hash(:Token, h)))
Base.:(==)(a::Token, b::Token) = isequal(a.name, b.name) && isequal(a.value, b.value)

"""
    TokenStream(io::IO)

Stateful decorator around an `io` to create [`Token`](@ref) by
using the function [`next_token`](@ref).
"""
mutable struct TokenStream{I<:IO}
    io::I
    inproperty::Bool
    next::Char
end

TokenStream(io::IO) = TokenStream(io, false, '\0')

Base.eof(ts::TokenStream) = eof(ts.io) && (ts.next == '\0')
for fun in (:read, :position, :seek)
    @eval (Base.$fun)(ts::TokenStream, args...) =
        (Base.$fun)(ts.io, args...)
end

"""
    next_token(ts::TokenStream) -> Token

Reads and returns the next [`Token`](@ref) from the given token
stream `ts`. If no more token are available, then a `EOFError`
will be thrown.

Note that the lexer should support FF[1]-FF[4] versions. In case
any unambiguously illegal character sequence is encountered, the
function will throw a [`LexicalError`](@ref).
"""
function next_token(ts::TokenStream)
    eof(ts) && throw(EOFError())
    c = ts.next == '\0' ? read(ts, Char)::Char : ts.next
    ts.next = '\0'
    if ts.inproperty && c === ']'
        ts.inproperty = false
        Token(']')
    elseif ts.inproperty
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
                elseif isspace(c)
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
            elseif isspace(c)
                # since newlines are already processed at this point,
                # every other whitespace can be replaced with ' '
                push!(buf, ' ')
            else
                push!(buf, c)
            end
        end
        Token('S', String(buf))
    elseif c === '['
        ts.inproperty = true
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
            elseif c in '0':'9' # compatibility with FF[1-3]
                push!(buf, c)
            else
                ts.next = c
                break
            end
        end
        Token('I', String(buf))
    elseif isspace(c)
        eof(ts) ? Token('\0') : next_token(ts)
    else
        throw(LexicalError("Invalid character: \"$c\""))
    end
end

end
