const ps = SmartGameFormat.Parser

@testset "public interface" begin
    # nothing should be exported
    @test_throws UndefVarError Parser
    @test ParseError === Base.ParseError
    @test parse === Base.parse
    @test tryparse === Base.tryparse
end

# unsupported FF
@testset "FF and other root properties" begin
    @test parse_sgf("(; FF[4])") == [SGFGameTree(SGFNode(:FF=>4))]
    @test parse_sgf("(; CA[UTF-8])") == [SGFGameTree(SGFNode(:CA=>"UTF-8"))]
    @test parse_sgf("(; FF[4])(; CA[UTF-8])") == [SGFGameTree(SGFNode(:FF=>4)), SGFGameTree(SGFNode(:CA=>"UTF-8"))]
    # warning for older versions
    @test @test_warn("FF",parse_sgf("(; FF[3])")) == [SGFGameTree(SGFNode(:FF=>3))]
    # warning for unsupported charsets
    @test @test_warn("unsupported",parse_sgf("(; CA[ABC])")) == [SGFGameTree(SGFNode(:CA=>"ABC"))]
    # illegal version numbers
    @test_throws ps.ParseError parse_sgf("(; FF[5])")
    @test_throws ps.ParseError parse_sgf("(; FF[0])")
    # root property in non root node
    @test_throws ps.ParseError parse_sgf("(; ; FF[4])")
    @test_throws ps.ParseError parse_sgf("(; ; CA[UTF-8])")
end

# illegal value types (not numbers)
@test_throws ps.ParseError parse_sgf("(; FF[A])")
@test_throws ps.ParseError parse_sgf("(; KM[A])")
