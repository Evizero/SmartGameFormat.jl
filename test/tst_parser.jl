const ps = SmartGameFormat.Parser

@testset "public interface" begin
    # nothing should be exported
    @test_throws UndefVarError Parser
    @test_throws UndefVarError SGFCollection # private typealias
    @test ParseError === Base.ParseError
    @test parse === Base.parse
    @test tryparse === Base.tryparse
    @test SGFNode === SmartGameFormat.SGFNode
    @test SGFGameTree === SmartGameFormat.SGFGameTree
end

@testset "SGFNode" begin
end

@testset "SGFGameTree" begin
end
