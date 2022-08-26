--- === cp.apple.fcpxml.time ===
---
--- Allows you to convert time string values found in a FCPXML document into Lua objects,
--- that do all the operations using rational numbers.
---
--- Final Cut Pro expresses time values as a rational number of seconds with a 64-bit
--- numerator and a 32-bit denominator. Frame rates for NTSC-compatible media, for example,
--- use a frame duration of 1001/30000s (29.97 fps) or 1001/60000s (59.94 fps). If a time
--- value is equal to a whole number of seconds, Final Cut Pro may reduce the fraction
--- into whole seconds (for example, 5s).

local log                   = require "hs.logger".new "fcpxml"

local tools                 = require "cp.tools"

local mod = {}
local time = {}
local mt

--- cp.apple.fcpxml.time.new(numerator, [denominator]) -> timeObject
--- Constructor
---
--- Parameters:
---  * A numerator as a number (i.e. 3400) or a string value (i.e. "3400/2500s" or "2s")
---  * A optional denominator as a number (i.e 2500)
---
--- Returns:
---  * A new `cp.apple.fcpxml.time` object.
function time.new(n, d)
    if type(n) == "string" and type(d) == "nil" then
        --------------------------------------------------------------------------------
        -- Remove the "s" at the end:
        --------------------------------------------------------------------------------
        local value = n
        if value:sub(-1) == "s" then
            value = value:sub(1, -2)
        end

        --------------------------------------------------------------------------------
        -- If there's a slash then do the maths:
        --------------------------------------------------------------------------------
        if string.find(value, "/") then
            local values = value:split("/")
            n = values and values[1] and tonumber(values[1])
            d = values and values[2] and tonumber(values[2])
        else
            --------------------------------------------------------------------------------
            -- Set the denominator to 1, if it's a whole number:
            --------------------------------------------------------------------------------
            n = tonumber(value)
            d = 1
        end
    end

    if type(n) ~= "number" then
        log.ef("[cp.apple.fcpxml.time] The numerator must be a number.")
        log.df("n: %s", n)
        log.df("n type: %s", type(n))
        return
    end

    if not d then d = 1 end

    if type(d) ~= "number" then
        log.ef("[cp.apple.fcpxml.time.new] The denominator must be a number.")
        return
    end

    if d == 0 then
        log.ef("[cp.apple.fcpxml.time.new] The denominator cannot be zero.")
        return
    end

    if n ~= math.floor(n) or d ~= math.floor(d) then
        log.ef("[cp.apple.fcpxml.time.new] The numerator and denominator must be whole numbers.")
        return
    end

    if d < 0 then
        n, d = -n, -d
    end

    --------------------------------------------------------------------------------
    -- Calculate the greatest common divisor:
    --------------------------------------------------------------------------------
    local gcd = time.gcd(n, d)
    local self = {n=n/gcd, d=d/gcd}
    setmetatable(self, mt)
    return self
end

--- cp.apple.fcpxml.time.gcd(numerator, denominator) -> number
--- Function
--- Gets the greatest common divisor.
---
--- Parameters:
---  * numerator - A numerator as a number
---  * denominator - A denominator as a number
---
--- Returns:
---  * A number containing the greatest common divisor.
function time.gcd(m, n)
    assert(type(m) == "number", "[cp.apple.fcpxml.time.gcd] Numerator must be a number")
    assert(type(n) == "number", "[cp.apple.fcpxml.time.gcd] Denominator must be a number")

    if m < 0 then
        m = -m
    end

    if n < 0 then
        n = -n
    end

    while m ~= 0 do
        m, n = n % m, m
    end

    return n
end

--- cp.apple.fcpxml.time.add(a, b) -> timeObject
--- Function
--- Adds one time object to another.
---
--- Parameters:
---  * a - A time object.
---  * b - A time object.
---
--- Returns:
---  * A new time object
function time.add(a, b)
    assert(type(a) == "table", "[cp.apple.fcpxml.time.add] First attribute must be a time object.")
    assert(type(b) == "table", "[cp.apple.fcpxml.time.add] Second attribute must be a time object.")

    return time.new(
        a.n * b.d + b.n * a.d,
        a.d * b.d
    )
end

--- cp.apple.fcpxml.time.unm(a) -> timeObject
--- Function
--- Negates a time object.
---
--- Parameters:
---  * a - A time object.
---
--- Returns:
---  * A new time object
function time.unm(a, b)
    if b then a = b end

    assert(type(a) == "table", "[cp.apple.fcpxml.time.unm] First attribute must be a time object.")

    return time.new(-a.n, a.d)
end

--- cp.apple.fcpxml.time.sub(a, b) -> timeObject
--- Function
--- Subtract one time object from another.
---
--- Parameters:
---  * a - A time object.
---  * b - A time object.
---
--- Returns:
---  * A new time object
function time.sub(a, b)
    assert(type(a) == "table", "[cp.apple.fcpxml.time.sub] First attribute must be a time object.")
    assert(type(b) == "table", "[cp.apple.fcpxml.time.sub] Second attribute must be a time object.")

    return time.new(
        a.n * b.d - b.n * a.d,
        a.d * b.d
    )
end

--- cp.apple.fcpxml.time.mul(a, b) -> timeObject
--- Function
--- Multiplies one time object with another.
---
--- Parameters:
---  * a - A time object.
---  * b - A time object.
---
--- Returns:
---  * A new time object
function time.mul(a, b)
    assert(type(a) == "table", "[cp.apple.fcpxml.time.mul] First attribute must be a time object.")
    assert(type(b) == "table", "[cp.apple.fcpxml.time.mul] Second attribute must be a time object.")

    return time.new(
        a.n * b.n,
        a.d * b.d
    )
end

--- cp.apple.fcpxml.time.mul(object, value) -> timeObject
--- Function
--- To the power of a time value.
---
--- Parameters:
---  * object - A time object.
---  * value - The power value
---
--- Returns:
---  * A new time object
function time.pow(a, n)
    assert(type(a) == "table", "[cp.apple.fcpxml.time.pow] First attribute must be a time object.")
    assert(type(n) == "number", "[cp.apple.fcpxml.time.pow] Second attribute must be a number.")

    return time.new(
        a.n^n,
        a.d^n
    )
end

--- cp.apple.fcpxml.time.div(a, b) -> timeObject
--- Function
--- Divides one time object with another.
---
--- Parameters:
---  * a - A time object.
---  * b - A time object.
---
--- Returns:
---  * A new time object
function time.div(a, b)
    assert(type(a) == "table", "[cp.apple.fcpxml.time.div] First attribute must be a time object.")
    assert(type(b) == "table", "[cp.apple.fcpxml.time.div] Second attribute must be a time object.")

    assert(b.n ~= 0, "[cp.apple.fcpxml.time.div] Second attribute numerator cannot be zero..")

    return time.new(
        a.n * b.d,
        a.d * b.n
    )
end

--- cp.apple.fcpxml.time.tostring(a) -> timeObject
--- Function
--- Gets the string value of a time object.
---
--- Parameters:
---  * a - A time object.
---
--- Returns:
---  * A string
function time.tostring(a)
    assert(type(a) == "table", "[cp.apple.fcpxml.time.tostring] First attribute must be a time object.")

    if a.d == 1 then
        return string.format("%d", a.n) .. "s"
    else
        return string.format("%d/%d", a.n, a.d) .. "s"
    end
end

--- cp.apple.fcpxml.time.tonumber(a) -> timeObject
--- Function
--- Gets the number value of a time object.
---
--- Parameters:
---  * a - A time object.
---
--- Returns:
---  * A number
function time.tonumber(a)
    assert(type(a) == "table", "[cp.apple.fcpxml.time.tonumber] First attribute must be a time object.")
    return a.n/a.d
end

--- cp.apple.fcpxml.time.eq(a, b) -> boolean
--- Function
--- Compares two time objects to ensure they're equal.
---
--- Parameters:
---  * a - A time object.
---  * b - A time object.
---
--- Returns:
---  * A boolean
function time.eq(a, b)
    assert(type(a) == "table", "[cp.apple.fcpxml.time.eq] First attribute must be a time object.")
    assert(type(b) == "table", "[cp.apple.fcpxml.time.eq] Second attribute must be a time object.")

    return a.n == b.n and a.d == b.d
end

--- cp.apple.fcpxml.time.lt(a, b) -> boolean
--- Function
--- Is time object A less than time object B?
---
--- Parameters:
---  * a - A time object.
---  * b - A time object.
---
--- Returns:
---  * A boolean
function time.lt(a, b)
    assert(type(a) == "table", "[cp.apple.fcpxml.time.lt] First attribute must be a time object.")
    assert(type(b) == "table", "[cp.apple.fcpxml.time.lt] Second attribute must be a time object.")

    local r = time.sub(a, b)
    return r.n < 0
end

--- cp.apple.fcpxml.time.lt(a, b) -> boolean
--- Function
--- Is time object A less than or equal to time object B?
---
--- Parameters:
---  * a - A time object.
---  * b - A time object.
---
--- Returns:
---  * A boolean
function time.le(a, b)
    assert(type(a) == "table", "[cp.apple.fcpxml.time.le] First attribute must be a time object.")
    assert(type(b) == "table", "[cp.apple.fcpxml.time.le] Second attribute must be a time object.")

    local r = time.sub(a, b)
    return r.n <= 0
end

mt = {
   __add        = time.add,
   __call       = time.tonumber,
   __div        = time.div,
   __eq         = time.eq,
   __index      = time,
   __le         = time.le,
   __lt         = time.lt,
   __mul        = time.mul,
   __pow        = time.pow,
   __sub        = time.sub,
   __tonumber   = time.tonumber,
   __tostring   = time.tostring,
   __unm        = time.unm,
}

setmetatable(mod,
    {
        __index     = time,
        __newindex  = time,
        __call      = function(self, ...) return time.new(...) end
    }
)
return mod