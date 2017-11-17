@testset "public interface" begin
    @test_throws UndefVarError Lexer
    @test_throws UndefVarError Token
    @test_throws UndefVarError TokenStream
    @test_throws UndefVarError next_token
end
