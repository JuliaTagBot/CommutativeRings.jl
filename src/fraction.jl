
# class constructors
Frac(::Type{R}) where R<:Ring = Frac{R}
Frac(::Type{R}) where R<:Integer = QQ{R}

# construction
basetype(::Type{<:Frac{T}}) where T = T
depth(::Type{<:Frac{T}}) where T = depth(T) + 1
copy(a::Frac) = typeof(a)(a.num,a.den, NOCHECK)

numerator(a::FractionField) = a.num
denominator(a::FractionField) = a.den

issimpler(a::T, b::T) where T<:Frac = issimpler(a.num, b.num)
Frac{T}(a::Frac{T}) where T = a
Frac{T}(a::Frac{S}) where {T,S} = Frac{T}(T(a.num), T(a.den), NOCHECK)

Frac{T}(a::Integer) where T = convert(Frac{T}, a)
Frac{T}(a::Ring) where T = convert(Frac{T}, a)
Frac(a::T) where T<:Ring  = convert(Frac{T}, a)
Frac(a::T) where T<:Integer = convert(Frac{ZZ{T}}, a)
Frac{T}(a::Integer,b::Integer) where T = Frac(T(a), T(b))
Frac{T}(a::Rational) where T = convert(Frac{T}, a)
function Frac(a::T, b::T) where T<:Polynomial
    cab = content(a) // content(b)
    a = primpart(a)
    b = primpart(b)
    g = pgcd(a, b)
    a /= g
    b /= g
    a *= numerator(cab)
    b *= denominator(cab)
    g = pgcd(a, b)
    a /= g
    b /= g
    s = lcunit(b)
    b /= s
    a /= s
    Frac{T}(a, b, NOCHECK)
end
function Frac(a::T, b::T) where T<:ZZ
    g = pgcd(a, b)
    a /= g
    b /= g
    s = lcunit(b)
    b /= s
    a /= s
    Frac{T}(a, b, NOCHECK)
end
//(a::T, b::T) where T<:Ring = Frac(a, b)
Frac{T}(a, b) where T = Frac(T(a), T(b))

_promote_rule(::Type{Frac{T}}, ::Type{Frac{S}}) where {S,T} = Frac{promote_type(S,T)}
_promote_rule(::Type{Frac{T}}, ::Type{S}) where {S<:Ring,T} = Frac{promote_type(S,T)}
promote_rule(::Type{Frac{T}}, ::Type{S}) where {S<:Integer,T} = Frac{promote_type(S,T)}
promote_rule(::Type{Frac{T}}, ::Type{Rational{S}}) where {S,T} = Frac{promote_type(S,T)}

convert(F::Type{Frac{T}}, a::Frac{T}) where T = a
convert(F::Type{Frac{T}}, a::Frac{S}) where {S,T} = F(T(a.num), T(a.den), NOCHECK)
convert(F::Type{Frac{T}}, a::Ring) where T = F(T(a), one(T), NOCHECK)
convert(F::Type{Frac{T}}, a::Integer) where T = F(T(a), one(T), NOCHECK)
convert(F::Type{Frac{T}}, a::Rational) where T = F(T(a.num), T(a.den), NOCHECK)

lcunit(a::Frac) = inv(lcunit(a.den))

# induced homomorphism
function (h::Hom{F,R,S})(p::Frac{<:R}) where {F,R,S}
    Frac(F(a.num), F(a.den))
end

Base.isless(p::T, q::T) where T<:Frac = isless(p.num * q.den, q.num * p.den)

# operations for Frac

function +(x::T, y::T) where T<:Frac
    a, b, c, d = x.num, x.den, y.num, y.den
    h = pgcd(b, d)
    b /= h
    d /= h
    n = a * d + b * c
    g = pgcd(n, h)
    T(n / g, h / g * b * d, NOCHECK)
end

function *(x::T, y::T) where T<:Frac
    a, b, c, d = x.num, x.den, y.num, y.den
    g = pgcd(a, d)
    a /= g
    d /= g
    g = pgcd(b, c)
    b /= g
    c /= g
    T(a * c, b * d, NOCHECK)
end
function inv(x::T) where T<:Frac
    T(x.den, x.num, NOCHECK)
end

==(a::T, b::T) where T<:Frac = iszero(a - b)
/(a::T, b::T) where T<:Frac = a * inv(b)
-(a::T, b::T) where T<:Frac = +(a, -b)
-(a::Frac{T}) where T = Frac{T}(-a.num, a.den, NOCHECK)
divrem(a::T, b::T) where T<:Frac = (a / b, zero(T))
div(a::T, b::T) where T<:Frac = a / b
rem(a::T, b::T) where T<:Frac = zero(T)

isunit(a::Frac) = !iszero(a.num)
isone(a::Frac) = a.num == a.den
iszero(a::Frac) = iszero(a.num)
zero(::Type{Frac{T}}) where T = Frac(zero(T), one(T))
one(::Type{Frac{T}}) where T = Frac(one(T), one(T))
hash(a::Frac, h::UInt) = hash(a.den, hash(a.num, h))

evaluate(p::Frac, a) = Frac(evaluate(p.num, a), evaluate(p.den, a))
(p::Frac)(a, b...) = evaluate(p, a, b...)

function show(io::IO, a::Frac)
    if isone(a.den)
        show(io, a.num)
    else
        print(io, '(', a.num, ")/(", a.den, ')')
    end
end
    
