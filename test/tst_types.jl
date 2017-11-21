@testset "public interface" begin
    @test_throws UndefVarError SGFCollection # private typealias
    @test SGFNode === SmartGameFormat.SGFNode
    @test SGFGameTree === SmartGameFormat.SGFGameTree
end

@testset "SGFNode" begin
    @testset "constructor" begin
        n = @inferred SGFNode(:a => 2)
        @test typeof(n) <: SGFNode
        @test n.properties == Dict(:a => [2])
        @test n.properties isa Dict{Symbol,Vector{Any}}
        @test n == @inferred SGFNode(:a => [2])
        n = @inferred SGFNode()
        @test typeof(n) <: SGFNode
        @test n.properties == Dict()
        @test n.properties isa Dict{Symbol,Vector{Any}}
        n = @inferred SGFNode(:a => 2, :b => "test")
        @test n == @inferred SGFNode(:a => 2, :b => ["test"])
        @test n == @inferred SGFNode(:a => [2], :b => ["test"])
        @test typeof(n) <: SGFNode
        @test n.properties == Dict(:a => [2], :b => ["test"])
        @test n.properties isa Dict{Symbol,Vector{Any}}
        n = @inferred SGFNode(Dict(:a => [2], :b => [3]))
        @test typeof(n) <: SGFNode
        @test n.properties == Dict(:a => [2], :b => [3])
        @test n.properties isa Dict{Symbol,Vector{Any}}
    end

    @testset "equality" begin
        @test SGFNode(:a => 3) == SGFNode(:a => 3)
        @test hash(SGFNode(:a => 3)) == hash(SGFNode(:a => 3))
        @test SGFNode(:a => "3") == SGFNode(:a => "3")
        @test hash(SGFNode(:a => "3")) == hash(SGFNode(:a => "3"))
        @test SGFNode(:a => 3) != SGFNode(:a => "3")
        @test hash(SGFNode(:a => 3)) != hash(SGFNode(:a => "3"))
        @test SGFNode(:a => [3], :b => ["c"]) == SGFNode(:a => [3], :b => ["c"])
        @test hash(SGFNode(:a => [3], :b => ["c"])) == hash(SGFNode(:a => [3], :b => ["c"]))
    end

    @testset "interface" begin
        n = SGFNode()
        @test @inferred(keytype(n)) == Symbol
        @test @inferred(valtype(n)) == Vector{Any}
        @test @inferred(length(n)) == 0
        @test @inferred(get(n, :a, Any[3])) == Any[3]
        @test @inferred(getkey(n, :a, :b)) == :b
        @test @inferred(haskey(n, :a)) == false
        n[:a] = 2
        @test @inferred(length(n)) == 1
        @test @inferred(get(n, :a, Any[3])) == Any[2]
        @test @inferred(getkey(n, :a, :b)) == :a
        @test @inferred(haskey(n, :a)) == true
        @test @inferred(n[:a]) == Any[2]
        n[:a] = 4
        @test @inferred(length(n)) == 1
        @test @inferred(get(n, :a, Any[3])) == Any[4]
        @test @inferred(getkey(n, :a, :b)) == :a
        @test @inferred(haskey(n, :a)) == true
        @test @inferred(n[:a]) == Any[4]
        n[:a] = [5]
        @test @inferred(length(n)) == 1
        @test @inferred(get(n, :a, Any[3])) == Any[5]
        @test @inferred(getkey(n, :a, :b)) == :a
        @test @inferred(haskey(n, :a)) == true
        @test @inferred(n[:a]) == Any[5]
        push!(n, :b=>2)
        @test @inferred(length(n)) == 2
        @test @inferred(haskey(n, :a)) == true
        @test @inferred(haskey(n, :b)) == true
        @test @inferred(n[:b]) == Any[2]
        @test collect(keys(n)) == [:a, :b] || collect(keys(n)) == [:b, :a]
        @test collect(values(n)) == [[5], [2]] || collect(keys(n)) == [[2], [5]]
        push!(n, :b=>3)
        @test @inferred(length(n)) == 2
        @test @inferred(haskey(n, :a)) == true
        @test @inferred(haskey(n, :b)) == true
        @test @inferred(n[:b]) == Any[2, 3]
        push!(n, :b=>[4])
        @test @inferred(length(n)) == 2
        @test @inferred(haskey(n, :a)) == true
        @test @inferred(haskey(n, :b)) == true
        @test @inferred(n[:b]) == Any[4]
    end

    @testset "show" begin
        if Int == Int64
            @test_reference "ref/show_node0.txt" @io2str show(::IO, MIME"text/plain"(), SGFNode())
            @test_reference "ref/show_node1.txt" @io2str show(::IO, MIME"text/plain"(), SGFNode(:a => [2]))
            @test_reference "ref/show_node2.txt" @io2str show(::IO, MIME"text/plain"(), SGFNode(:a => [2], :b => [1.2, 3.2], :c => ["test"]))
            @test_reference "ref/show_node_cpct0.txt" @io2str show(IOContext(::IO, :compact=>true), MIME"text/plain"(), SGFNode())
            @test_reference "ref/show_node_cpct1.txt" @io2str show(IOContext(::IO, :compact=>true), MIME"text/plain"(), SGFNode(:a => [2]))
            @test_reference "ref/show_node_cpct2.txt" @io2str show(IOContext(::IO, :compact=>true), MIME"text/plain"(), SGFNode(:a => [2], :b => [1.2, 3.2], :c => ["test"]))
            @test_reference "ref/show_node_cpct3.txt" @io2str show(IOContext(::IO, :compact=>true), MIME"text/plain"(), SGFNode((Symbol("a$a") => [a] for a in 1:10)...))
        else
            warn("skipping show tests on 32 bit systems")
        end
    end
end

@testset "SGFGameTree" begin
end
