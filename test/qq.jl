
@testset "construction" begin
    @test basetype(QQ{Int}) == ZZ{Int}
    @test lcunit(QQ(-1, 3)) == 1
    @test lcunit(QQ(0)) == 1
    @test copy(QQ(12//15)) == QQ(4, 5)
    @test QQ{Int32}(QQ(3, 4)) isa QQ{Int32}
    @test QQ{Int}(QQ(3, 4)) != nothing
    @test QQ{BigInt}(ZZ(11)) == 11
    @test ZZ(12) // ZZ(13) == QQ(12, 13)

    @test QQ(1, 2) + QQ{Int8}(1, 3) == 5//6
    @test QQ(1, 3) - ZZ(1) == -2//3
    @test QQ(1, 2) * 2 == 1
    @test QQ(1, 2) - 1//3 == 1//6

    @test QQ(1, 2) / QQ(1, 3) == 3//2
    @test -QQ(1) == -1
    @test divrem(QQ(1,2), QQ(1, 3)) == (3//2, 0//1)
    @test div(QQ(1,2), QQ(1, 3)) == 3//2
    @test iszero(rem(QQ(1,2), QQ(1, 3)))
    @test isunit(QQ(23, 24))
    @test !isunit(QQ(0))
    @test isone(QQ(11, 11))
    @test zero(QQ{Int}) == 0
    @test one(QQ{Int8}) == 1
    @test hash(QQ(13, 14)) == hash(13//14)

    buf = IOBuffer()
    show(buf, QQ(12, 13))
    @test String(take!(buf)) == "12/13"
    @test show(IOBuffer(), QQ(12, 1)) == nothing

    @test QQ{Int}(3, 6) == 1//2
    @test QQ(3, 6) == 1//2
    @test QQ(2) == QQ(ZZ(2))
    @test QQ(Int8(2)) == QQ{BigInt}(2//1)
    @test QQ{Int8}(2) == QQ(2)
    @test QQ(1//2) == 1//2
end

@testset "arithmetic" begin
    @test QQ(2//3) + QQ(1//2) == QQ(7//6)
end

@testset "gcd calculations" begin
    @test gcd(QQ(1//3), QQ(2//5)) == 1 // 15
    @test gcd(QQ((2*3)//(5*7)), QQ((2*5)//(3*7))) == QQ(2, 3*5*7)
    @test gcdx(QQ((2*3)//(5*7)), QQ((2*5)//(3*7))) == (QQ(2, 3*5*7), -11, 4)
    @test lcm(QQ((2*3)//(5*7)), QQ((2*5)//(3*7))) == QQ(2*3*5, 7)
end

