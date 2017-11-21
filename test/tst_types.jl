@testset "public interface" begin
    @test_throws UndefVarError SGFCollection # private typealias
    @test SGFNode === SmartGameFormat.SGFNode
    @test SGFGameTree === SmartGameFormat.SGFGameTree
end

@testset "SGFNode" begin
    @testset "constructor" begin
        n = @inferred SGFNode(:a => 2)
        @test n isa SGFNode
        @test n.properties == Dict(:a => [2])
        @test n.properties isa Dict{Symbol,Vector{Any}}
        @test n == @inferred SGFNode(:a => [2])
        n = @inferred SGFNode()
        @test n isa SGFNode
        @test n.properties == Dict()
        @test n.properties isa Dict{Symbol,Vector{Any}}
        n = @inferred SGFNode(:a => 2, :b => "test")
        @test n == @inferred SGFNode(:a => 2, :b => ["test"])
        @test n == @inferred SGFNode(:a => [2], :b => ["test"])
        @test n isa SGFNode
        @test n.properties == Dict(:a => [2], :b => ["test"])
        @test n.properties isa Dict{Symbol,Vector{Any}}
        n = @inferred SGFNode(Dict(:a => [2], :b => [3]))
        @test n isa SGFNode
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
    @test SGFGameTree <: AbstractVector

    @testset "constructor" begin
        t = @inferred SGFGameTree()
        @test t isa SGFGameTree
        @test t.sequence isa Vector{SGFNode}
        @test t.variations isa Vector{SGFGameTree}
        @test length(t.sequence) == 0
        @test length(t.variations) == 0
        t = @inferred SGFGameTree(SGFNode(:a=>2))
        @test t isa SGFGameTree
        @test t.sequence isa Vector{SGFNode}
        @test t.variations isa Vector{SGFGameTree}
        @test length(t.sequence) == 1
        @test length(t.variations) == 0
        @test t.sequence == [SGFNode(:a=>2)]
        t = @inferred SGFGameTree([SGFNode(:b=>3),SGFNode(:c=>"4")])
        @test t isa SGFGameTree
        @test t.sequence isa Vector{SGFNode}
        @test t.variations isa Vector{SGFGameTree}
        @test length(t.sequence) == 2
        @test length(t.variations) == 0
        @test t.sequence == [SGFNode(:b=>3),SGFNode(:c=>"4")]
        t2 = @inferred SGFGameTree([SGFNode(:a=>2)], [t])
        @test t2 isa SGFGameTree
        @test t2.sequence isa Vector{SGFNode}
        @test t2.variations isa Vector{SGFGameTree}
        @test length(t2.sequence) == 1
        @test length(t2.variations) == 1
        @test t2.sequence == [SGFNode(:a=>2)]
        @test t2.variations == [t]
    end

    @testset "equality" begin
        @test SGFGameTree() == SGFGameTree()
        @test hash(SGFGameTree()) == hash(SGFGameTree())
        @test SGFGameTree(SGFNode(:a=>2)) == SGFGameTree(SGFNode(:a=>2))
        @test hash(SGFGameTree(SGFNode(:a=>2))) == hash(SGFGameTree(SGFNode(:a=>2)))
        @test SGFGameTree(SGFNode(:a=>2)) != SGFGameTree(SGFNode(:a=>3))
        @test hash(SGFGameTree(SGFNode(:a=>2))) != hash(SGFGameTree(SGFNode(:a=>3)))
        @test SGFGameTree([SGFNode(:b=>"a")], [SGFGameTree(SGFNode(:a=>2))]) == SGFGameTree([SGFNode(:b=>"a")], [SGFGameTree(SGFNode(:a=>2))])
        @test hash(SGFGameTree([SGFNode(:b=>"a")], [SGFGameTree(SGFNode(:a=>2))])) == hash(SGFGameTree([SGFNode(:b=>"a")], [SGFGameTree(SGFNode(:a=>2))]))
    end

    @testset "interface" begin
        t = SGFGameTree()
        @test @inferred(length(t)) == 0
        @test @inferred(size(t)) == (0,)
        @test_throws BoundsError t[0]
        @test_throws BoundsError t[1]
        push!(t.sequence, SGFNode(:a=>2))
        @test @inferred(length(t)) == 1
        @test @inferred(size(t)) == (1,)
        @test @inferred(t[1]) == SGFNode(:a=>2)
        @test_throws BoundsError t[2]
        t.variations = [SGFGameTree(SGFNode(:b=>"c")), SGFGameTree(SGFNode(:c=>"d"))]
        @test @inferred(length(t)) == 2
        @test @inferred(size(t)) == (2,)
        @test t.sequence == [SGFNode(:a=>2)]
        @test @inferred(t[1]) == SGFNode(:a=>2)
        @test @inferred(t[2]) == SGFNode(:b=>"c")
        t[1] = SGFNode(:AB=>3)
        @test @inferred(length(t)) == 2
        @test @inferred(t[1]) == SGFNode(:AB=>3)
        @test @inferred(t[2]) == SGFNode(:b=>"c")
        @test t.sequence == [SGFNode(:AB=>3)]
        @test t.variations == [SGFGameTree(SGFNode(:b=>"c")), SGFGameTree(SGFNode(:c=>"d"))]
        t[2] = SGFNode(:BC=>3.4)
        @test @inferred(t[1]) == SGFNode(:AB=>3)
        @test @inferred(t[2]) == SGFNode(:BC=>3.4)
        @test t.sequence == [SGFNode(:AB=>3)]
        @test t.variations == [SGFGameTree(SGFNode(:BC=>3.4)), SGFGameTree(SGFNode(:c=>"d"))]
        @test_throws BoundsError t[3]
        @test_throws BoundsError t[3] = SGFNode()
        # include simple show test right here
        if Int == Int64
            @test_reference "ref/show_gametree.txt" @io2str show(::IO, MIME"text/plain"(), t)
        else
            warn("skipping show tests on 32 bit systems")
        end
    end
end
