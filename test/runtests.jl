using Test
using CommutativeRings

@testset "ZZ" begin include("zz.jl") end
@testset "QQ" begin include("qq.jl") end
@testset "ZZmod" begin include("zzmod.jl") end
@testset "univarpolynom" begin include("univarpolynom.jl") end
@testset "fraction" begin include("fraction.jl") end
@testset "quotient" begin include("quotient.jl") end
@testset "factorization" begin include("factorization.jl") end
@testset "galoisfields" begin include("galoisfields.jl") end
@testset "numbertheory" begin include("numbertheoretical.jl") end

