local MOD = 2^32
local MODM = MOD-1
local function memoize(f)
    local mt = {}
    local t = setmetatable({}, mt)
    function mt:__index(k)
        local v = f(k)
        t[k] = v
        return v
    end
    return t
end
local function make_bitop_uncached(t, m)
    local function bitop(a, b)
        local res,p = 0,1
        while a ~= 0 and b ~= 0 do
            local am, bm = a % m, b % m
            res = res + t[am][bm] * p
            a = (a - am) / m
            b = (b - bm) / m
            p = p*m
        end
        res = res + (a + b) * p
        return res
    end
    return bitop
end
local function make_bitop(t)
    local op1 = make_bitop_uncached(t,2^1)
    local op2 = memoize(function(a) return memoize(function(b) return op1(a, b) end) end)
    return make_bitop_uncached(op2, 2 ^ (t.n or 1))
end
local k = {
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
    0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
    0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
    0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
    0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
}
local function str2hexa(s)
    return (string.gsub(s, ".", function(c) return string.format("%02x", string.byte(c)) end))
end
local function num2s(l, n)
    local s = ""
    for i = 1, n do
        local rem = l % 256
        s = string.char(rem) .. s
        l = (l - rem) / 256
    end
    return s
end
local function s232num(s, i)
    local n = 0
    for i = i, i + 3 do n = n*256 + string.byte(s, i) end
    return n
end
local function preproc(msg, len)
    local extra = 64 - ((len + 9) % 64)
    len = num2s(8 * len, 8)
    msg = msg .. "\128" .. string.rep("\0", extra) .. len
    assert(#msg % 64 == 0)
    return msg
end
local function initH256(H)
    H[1] = 0x6a09e667
    H[2] = 0xbb67ae85
    H[3] = 0x3c6ef372
    H[4] = 0xa54ff53a
    H[5] = 0x510e527f
    H[6] = 0x9b05688c
    H[7] = 0x1f83d9ab
    H[8] = 0x5be0cd19
    return H
end
local function digestblock(msg, i, H)
    local w = {}
    for j = 1, 16 do w[j] = s232num(msg, i + (j - 1)*4) end
    for j = 17, 64 do
        local v = w[j - 15]
        local s0 = bit32.bxor(bit32.rrotate(v, 7), bit32.rrotate(v, 18), bit32.rshift(v, 3))
        v = w[j - 2]
        w[j] = w[j - 16] + s0 + w[j - 7] + bit32.bxor(bit32.rrotate(v, 17), bit32.rrotate(v, 19), bit32.rshift(v, 10))
    end
    local a, b, c, d, e, f, g, h = H[1], H[2], H[3], H[4], H[5], H[6], H[7], H[8]
    for i = 1, 64 do
        local s0 = bit32.bxor(bit32.rrotate(a, 2), bit32.rrotate(a, 13), bit32.rrotate(a, 22))
        local maj = bit32.bxor(bit32.band(a, b), bit32.band(a, c), bit32.band(b, c))
        local t2 = s0 + maj
        local s1 = bit32.bxor(bit32.rrotate(e, 6), bit32.rrotate(e, 11), bit32.rrotate(e, 25))
        local ch = bit32.bxor (bit32.band(e, f), bit32.band(bit32.bnot(e), g))
        local t1 = h + s1 + ch + k[i] + w[i]
        h, g, f, e, d, c, b, a = g, f, e, d + t1, c, b, a, t1 + t2
    end
    H[1] = bit32.band(H[1] + a)
    H[2] = bit32.band(H[2] + b)
    H[3] = bit32.band(H[3] + c)
    H[4] = bit32.band(H[4] + d)
    H[5] = bit32.band(H[5] + e)
    H[6] = bit32.band(H[6] + f)
    H[7] = bit32.band(H[7] + g)
    H[8] = bit32.band(H[8] + h)
end
function sha256(msg)
    msg = preproc(msg, #msg)
    local H = initH256({})
    for i = 1, #msg, 64 do digestblock(msg, i, H) end
    return str2hexa(num2s(H[1], 4) .. num2s(H[2], 4) .. num2s(H[3], 4) .. num2s(H[4], 4) ..
        num2s(H[5], 4) .. num2s(H[6], 4) .. num2s(H[7], 4) .. num2s(H[8], 4))
end
