using Base.Test
using ReferenceTests

# check for ambiguities
refambs = detect_ambiguities(Base, Core)
using SmartGameFormat
ambs = detect_ambiguities(Base, Core)
@test length(setdiff(ambs, refambs)) == 0

tests = [
    "tst_lexer.jl",
    "tst_types.jl",
    "tst_parser.jl",
]

for t in tests
    @testset "$t" begin
        include(t)
    end
end
