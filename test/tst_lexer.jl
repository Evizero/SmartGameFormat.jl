const lx = SmartGameFormat.Lexer

function read_all_token(str)
    io = lx.TokenStream(IOBuffer(str))
    tkn = lx.Token[]
    while !eof(io)
        push!(tkn, lx.next_token(io))
    end
    tkn
end

# --------------------------------------------------------------------

@testset "public interface" begin
    # nothing should be exported
    @test_throws UndefVarError Lexer
    @test_throws UndefVarError Token
    @test_throws UndefVarError TokenStream
    @test_throws UndefVarError next_token
end

@testset "lexical error" begin
    # all kind of characters that should not be encountered
    # except inside property delimiter "[...]"
    for str in [string.(0:9)...,
                string.('a':'z')...,
                split("'!\"§\$%&/?]\\,<>.:-_#+*","")...]
        io = lx.TokenStream(IOBuffer(str))
        @test_throws lx.LexicalError lx.next_token(io)
    end
    # some illegal examples strings
    for str in ("Ab[a]", "ABc[a]", "ab[cd]", "1A[bc]", "AB[]]")
        @testset "$str" begin
            @test_throws lx.LexicalError read_all_token(str)
        end
    end
end

@testset "Token equality" begin
    # make sure comparing Token works properly
    @test lx.Token('S', "test") == lx.Token('S', "test")
    @test lx.Token('S', "test") != lx.Token('S', "test1")
    @test lx.Token('S', "test") != lx.Token('S', "tesT")
    @test lx.Token('S', "test") != lx.Token('T', "test")
    @test hash(lx.Token('S', "test")) == hash(lx.Token('S', "test"))
    @test hash(lx.Token('S', "test")) != hash(lx.Token('S', "test1"))
    @test hash(lx.Token('S', "test")) != hash(lx.Token('S', "tesT"))
    @test hash(lx.Token('S', "test")) != hash(lx.Token('T', "test"))
end

@testset "premature EOF" begin
    # basically when reading an identifier or a property value
    for str in ("AB", "AB[oo", "AB[oo ", "AB[oo\n")
        @testset "$str" begin
            @test_throws EOFError read_all_token(str)
        end
    end
    # however, trailing white spaces will cause different behaviour.
    # this isn't ideal, but the parser should catch it either way
    for str in ("AB\t", "AB ", "AB\n")
        @testset "$str" begin
            @test read_all_token(str) == [lx.Token('I',"AB"), lx.Token('\0')]
        end
    end
end

@testset "normal examples" begin
    for (str, ref) in (
            # minimal legal file
            ("(;)", [lx.Token('('), lx.Token(';'), lx.Token(')')]),
            # will be a parse error, but lexically its fine
            ("()", [lx.Token('('), lx.Token(')')]),
            ("())", [lx.Token('('), lx.Token(')'), lx.Token(')')]),
            ("(()", [lx.Token('('), lx.Token('('), lx.Token(')')]),
            ("(A B)", [lx.Token('('), lx.Token('I',"A"), lx.Token('I',"B"), lx.Token(')')]),
            # typical property
            ("AB[oo]", [lx.Token('I',"AB"), lx.Token('['), lx.Token('S',"oo"), lx.Token(']')]),
            # check that white spaces are tolerated but skipped
            (" AB  \n[oo]",   [lx.Token('I',"AB"), lx.Token('['), lx.Token('S',"oo"), lx.Token(']')]),
            (" AB  \r[oo]",   [lx.Token('I',"AB"), lx.Token('['), lx.Token('S',"oo"), lx.Token(']')]),
            (" AB  \r\n[oo]", [lx.Token('I',"AB"), lx.Token('['), lx.Token('S',"oo"), lx.Token(']')]),
            (" AB  \n\r[oo]", [lx.Token('I',"AB"), lx.Token('['), lx.Token('S',"oo"), lx.Token(']')]),
            # in case of trailing white spaces we need an empty
            # token to avoid throwing EOFError. note that the
            # parser skips the empty token "Token('\0')" entirely.
            (" AB  \r\n[oo]\r\n", [lx.Token('I',"AB"), lx.Token('['), lx.Token('S',"oo"), lx.Token(']'), lx.Token('\0')]),
            # digits in identifiers are allowed for compatibility
            ("A1B[oo]", [lx.Token('I',"A1B"), lx.Token('['), lx.Token('S',"oo"), lx.Token(']')]),
            # a longer more complex example
            (" (; AB[ab] CD[cd])", [lx.Token('('), lx.Token(';'), lx.Token('I',"AB"), lx.Token('['), lx.Token('S',"ab"), lx.Token(']'), lx.Token('I',"CD"), lx.Token('['), lx.Token('S',"cd"), lx.Token(']'), lx.Token(')')]),
           )
        @testset "$str" begin
            @test read_all_token(str) == ref
        end
    end
end

@testset "property values examples" begin
    for (str, ref) in (
            # no property value will lack string token
            ("AB[]", [lx.Token('I',"AB"), lx.Token('['), lx.Token(']')]),
            # lexer does not attempt to interpret property values
            # the following just shows that composite values don't
            # cause any problems
            ("AB[aa:cc]", [lx.Token('I',"AB"), lx.Token('['), lx.Token('S',"aa:cc"), lx.Token(']')]),

            ## ESCAPING
            ("AB[ab(\\)[\\]\\;\\\\cd]", [lx.Token('I',"AB"), lx.Token('['), lx.Token('S',"ab()[];\\cd"), lx.Token(']')]),

            ## SPACES
            # spaces are preserved
            ("AB[ab  cd]", [lx.Token('I',"AB"), lx.Token('['), lx.Token('S',"ab  cd"), lx.Token(']')]),
            # spaces are preserved even when escaped
            ("AB[ab \\ cd]", [lx.Token('I',"AB"), lx.Token('['), lx.Token('S',"ab  cd"), lx.Token(']')]),

            ## TABS
            # tabs are converted to spaces
            ("AB[ab\tcd]", [lx.Token('I',"AB"), lx.Token('['), lx.Token('S',"ab cd"), lx.Token(']')]),
            # tabs are converted to spaces, even when escaped
            ("AB[ab\\\tcd]", [lx.Token('I',"AB"), lx.Token('['), lx.Token('S',"ab cd"), lx.Token(']')]),

            ## NEWLINES
            # new lines are preserved except when escaped by "\"
            ("AB[ab\nc\\\nd]", [lx.Token('I',"AB"), lx.Token('['), lx.Token('S',"ab\ncd"), lx.Token(']')]),
            # supported newlines are CR, LF, CRLF, LFCR
            ("AB[ab\rc\\\rd]", [lx.Token('I',"AB"), lx.Token('['), lx.Token('S',"ab\ncd"), lx.Token(']')]),
            ("AB[ab\n\rc\\\n\rd]", [lx.Token('I',"AB"), lx.Token('['), lx.Token('S',"ab\ncd"), lx.Token(']')]),
            ("AB[ab\r\nc\\\r\nd]", [lx.Token('I',"AB"), lx.Token('['), lx.Token('S',"ab\ncd"), lx.Token(']')]),
           )
        @testset "$str" begin
            @test read_all_token(str) == ref
        end
    end
end
