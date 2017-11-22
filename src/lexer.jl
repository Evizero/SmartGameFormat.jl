"""
The `Lexer` sub-module is concerned with transcribing a given
stream of characters into a sequence of domain specific lexical
units called "token".

Basic methodology:

1. Wrap a plain `IO` object into a [`Lexer.CharStream`](@ref).
2. Call [`Lexer.next_token`](@ref) to collect another
   [`Lexer.Token`](@ref) from the character stream.
3. Goto 2. unless end of file is reached.

For convenience the above process is simplified by providing the
type [`Lexer.TokenStream`](@ref), which supports `eof`, `read`
and [`Lexer.peek`](@ref).
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
    CharStream(io::IO)

Stateful decorator around `io` to keep track of some context
information, as well as allow the use of [`peek`](@ref) (i.e.
looking at the next character without consuming it).
"""
mutable struct CharStream{I<:IO}
    io::I
    inproperty::Bool
    next::Char
end

CharStream(io::IO) = CharStream(io, false, '\0')

Base.eof(cs::CharStream) = eof(cs.io) && (cs.next == '\0')

"""
    peek(cs::CharStream, ::Type{Char}) -> Char

Return the next `Char` in `cs` without consuming it, which means
that the next time `peek` or `read` is called, the same `Char`
will be returned.
"""
function peek(cs::CharStream, ::Type{Char})
    if cs.next == '\0'
        cs.next = read(cs.io, Char)::Char
    end
    cs.next
end

function Base.read(cs::CharStream, ::Type{Char})
    if cs.next == '\0'
        read(cs.io, Char)::Char
    else
        c = cs.next
        cs.next = '\0'
        c
    end
end

"""
    next_token(cs::CharStream) -> Token

Reads and returns the next [`Token`](@ref) from the given
character stream `cs`. If no more token are available, then a
`EOFError` will be thrown.

Note that the lexer should support FF[1]-FF[4] versions. In case
any unambiguously illegal character sequence is encountered, the
function will throw a [`LexicalError`](@ref).
"""
function next_token(cs::CharStream)
    eof(cs) && throw(EOFError())
    c = read(cs, Char)
    if cs.inproperty && c === ']'
        cs.inproperty = false
        Token(']')
    elseif cs.inproperty
        buf = UInt8[c]
        while true
            c = peek(cs, Char)
            if c === ']'
                break
            elseif c === '\\'
                read(cs, Char) # consume \\
                c = read(cs, Char)
                # newlines are removed after '\\'
                if c === '\r'
                    # consume additional \n if it exists
                    peek(cs, Char) == '\n' && read(cs, Char)
                elseif c === '\n'
                    # consume additional \r if it exists
                    peek(cs, Char) == '\r' && read(cs, Char)
                elseif isspace(c)
                    # all other whitespaces are converted to " "
                    push!(buf, ' ')
                else
                    # everything else is stored verbatim
                    # this includes ']', ')', and ':'
                    push!(buf, c)
                end
            elseif c === '\r'
                read(cs, Char) # consume \r
                # we represent newlines always as a single \n
                push!(buf, '\n')
                # consume additional \n if it exists
                peek(cs, Char) == '\n' && read(cs, Char)
            elseif c === '\n'
                read(cs, Char) # consume \n
                push!(buf, '\n')
                # consume additional \r if it exists
                peek(cs, Char) == '\r' && read(cs, Char)
            elseif isspace(c)
                read(cs, Char) # consume " "
                # since newlines are already processed at this point,
                # every other whitespace can be replaced with ' '
                push!(buf, ' ')
            else
                read(cs, Char) # consume character
                push!(buf, c)
            end
        end
        Token('S', String(buf))
    elseif c === '['
        cs.inproperty = true
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
            c = read(cs, Char)
            if c in 'A':'Z'
                push!(buf, c)
            elseif c in '0':'9' # compatibility with FF[1-3]
                push!(buf, c)
            else
                cs.next = c
                break
            end
        end
        Token('I', String(buf))
    elseif isspace(c)
        eof(cs) ? Token('\0') : next_token(cs)
    else
        throw(LexicalError("Invalid character: \"$c\""))
    end
end

"""
    TokenStream(cs::CharStream)

Stateful decorator around `cs` to keep track of some context
information, as well as allow the use of [`peek`](@ref) (i.e.
looking at the next [`Token`](@ref) without consuming it).

It uses the function [`next_token`](@ref) to create a new
[`Token`](@ref) from the current position of `cs` onwards.
"""
mutable struct TokenStream{I<:IO}
    stream::CharStream{I}
    next::Token
end

TokenStream(cs::CharStream) = TokenStream(cs, Token('\0'))
TokenStream(io::IO) = TokenStream(CharStream(io))

Base.eof(ts::TokenStream) = eof(ts.stream) && (ts.next == Token('\0'))

"""
    peek(ts::TokenStream, ::Type{Token}) -> Token

Return the next [`Token`](@ref) in `ts` without consuming it,
which means that the next time `peek` or `read` is called, the
same [`Token`](@ref) will be returned.
"""
function peek(ts::TokenStream, ::Type{Token})
    if ts.next == Token('\0')
        ts.next = next_token(ts.stream)
    end
    ts.next
end

function Base.read(ts::TokenStream, ::Type{Token})
    if ts.next == Token('\0')
        next_token(ts.stream)
    else
        t = ts.next
        ts.next = Token('\0')
        t
    end
end

end
