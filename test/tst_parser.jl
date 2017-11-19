const ps = SmartGameFormat.Parser

@testset "public interface" begin
    # nothing should be exported
    @test_throws UndefVarError Parser
    @test_throws UndefVarError Collection
    @test_throws UndefVarError GameTree
    @test_throws UndefVarError Node
    @test parse === Base.parse
end
