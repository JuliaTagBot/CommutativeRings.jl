
using Primes

tm(T::Type{<:Integer}) = typemax(T)
tm(::Type{BigInt}) = big"1000000000000000000000000000000000067"

@testset "construction and promotion" begin
    @test basetype(ZZmod{:p,Int}) == ZZ{Int}
    @test depth(ZZmod{13,BigInt}) == 1
    @test lcunit(ZZmod{13}(7)) == 20
    @test ZZmod{13,Int}(ZZ(8)) == ZZmod{13}(8)
    @test ZZmod{13}(1) + ZZmod{13}(Int8(12)) == 0
    @test_throws ErrorException ZZmod{13}(1) - ZZmod{14}(1)
    ZZp = new_class(ZZmod{:p,Int}, 13)
    @test ZZmod{13}(1) + ZZp(12) == 0
    @test typeof(ZZmod{13}(1) + ZZp(1)) == ZZp
    @test typeof(ZZp(1) + ZZmod{13}(1)) == ZZp
    @test Int / 13 == ZZmod{13,Int}
    @test BigInt/13 <: (ZZmod{X,BigInt} where X)
    @test convert(ZZp, ZZmod{13}(Int8(7))) == ZZp(-6) 
    @test_throws DomainError convert(ZZp, ZZmod{23}(Int8(7))) 
end

@testset "ZZmod{$m,$T}" for T in (UInt16, Int64, BigInt), m in (65, tm(T))
    
    while T != BigInt && isprime(m)
        m -= 2
    end
    m = T(m)

    if T != BigInt || m <= typemax(UInt128)
        phi = totient(m)
        p = factor(m).pe[end].first # the greatest prime factor of m
    else
        phi = (m-1)*4
        m = m * T(5)
    end

    n1 = T(19)
    while gcd(n1, m) != 1
        n1 += T(1)
    end
    n2 = tm(T) - T(16)
    while gcd(n2, m) != 1
        n2 += T(1)
    end

    ZZp = new_class(ZZmod{:p,T}, m)
    @test typeof(modulus(ZZp)) == T
    isbitstype(T) && @test typeof(modulus(ZZmod{m,T})) == T
    @test typeof(modulus(ZZmod{3,T})) == T
    z = zero(ZZp)
    @test z == zero(z)
    @test iszero(z)
    @test !isone(z)
    o = one(z)
    @test isunit(o)
    @test isone(o)
    @test !iszero(o)
    z1 = ZZp(n1)
    z2 = ZZp(n2)
    zp = ZZp(p)
    @test isunit(z1)
    @test z1 + z1 == ZZp(T(2n1))
    
    @test z1 - z1 == z
    @test z1 - z2 == ZZp(m + mod(n1, m) - mod(n2, m))
    @test -z2 == ZZp(m - mod(n2, m))
    
    @test z1 * z1 == ZZp(T(n1 * n1))
    @test z1 * n1 == ZZp(T(n1 * n1))
    @test n1 * z1 == ZZp(T(n1 * n1))

    @test z1^2 == ZZp(n1^2)
    
    z3 = 2z1
    z4 = z3 + o
    @test z3 / z1 == ZZp(T(2))
    @test z4 / z1 == z4 * inv(z1)
    @test z1 \ z4 == z4 / z1

    @test z1^phi == o
    @test z2^(phi-1) == inv(z2)

    @test_throws DomainError inv(zp)
    @test_throws DomainError ZZmod{0,T}(0)

    if T != BigInt
        @test zero(ZZmod{m}) == z
        @test one(ZZmod{m}) == o
        @test ZZmod(n1, m) == ZZp(n1)
        @test hash(ZZmod(n1, m)) == hash(ZZp(n1))
    end

    @test ZZp(m-1) + ZZp(2) == ZZp(1)
    @test ZZp(1) - ZZp(2) == ZZp(m-1)
    @test ZZp(1) + ZZp(3) == ZZp(4)
    @test ZZp(3) - ZZp(2) == ZZp(1)

    @test ZZp(4)^-1 == inv(ZZp(4))
    @test ZZp(3)^1 == ZZp(3)
    @test ZZp(3)^0 == o

    @test copy(ZZp(5)) == ZZp(5)
    @test deg(z3) == 0
    @test div(z3, z3) == one(z3)
    @test rem(z3, z3) == zero(z3)
    io = IOBuffer()
    @test show(io, z1) == nothing
end
@testset "constructors and type assertion" begin
    ZZp1 = ZZmod{17,Int8}
    p1 = ZZp1(-1)
    @test ZZp1(p1) === p1
    ZZp2 = ZZmod{17,Int}
    p2 = ZZp2(-1)
    @test ZZp1(p2) !== p2
    @test ZZp1(p2).val == p2.val
    @test_throws InexactError ZZp1(128)
    @test modulus(Int8/17) == 17
    @test modulus(BigInt/31) == 31
    @test (Int8/17)(1) == ZZp1(1)
end

@testset "auxiliary functions" begin
    @test CommutativeRings.invmod2(big"12", big"31") == big"13" # gcdx[2] > 0
    @test CommutativeRings.invmod2(big"15", big"31") == big"29" # gcdx[2] < 0
    @test CommutativeRings._unsigned(Int) == UInt
    @test CommutativeRings._unsigned(BigInt) == BigInt
    @test CommutativeRings._unsigned(big"-1") == big"-1"
end

