const ps = SmartGameFormat.Parser

@testset "public interface" begin
    # nothing should be exported
    @test_throws UndefVarError Parser
    @test ParseError === Base.ParseError
    @test parse === Base.parse
    @test tryparse === Base.tryparse
end
