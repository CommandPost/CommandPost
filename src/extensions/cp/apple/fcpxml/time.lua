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

--- cp.apple.fcpxml.time.newFromTimecodeWithFrameDuration(timecode, frameDuration) -> timeObject
--- Constructor
--- Create a time object from timecode and frame duration.
---
--- Parameters:
---  * timecode - A timecode string in "hh:mm:ss:ff" format (i.e. 01:00:00:00).
---  * frameDuration - Frame duration as a time object.
---
--- Returns:
---  * A new `cp.apple.fcpxml.time` object.
function time.newFromTimecodeWithFrameDuration(timecode, frameDuration)
    assert(type(timecode) == "string", "[cp.apple.fcpxml.time.newFromTimecodeWithFrameDuration] Timecode must be a string")
    assert(type(frameDuration) == "table", "[cp.apple.fcpxml.time.newFromTimecodeWithFrameDuration] Frame Duration must be a time object")

    local values = tools.split(timecode, ":")

    local h = tonumber(values[1])
    local m = tonumber(values[2])
    local s = tonumber(values[3])
    local f = tonumber(values[4])

    local fps = time.new(1, 1) / frameDuration
    local totalSeconds = h * 360 + m * 60 + s
    local totalFrames = time.new(totalSeconds, 1) * fps + time.new(f, 1)

    return totalFrames * frameDuration
end

--- cp.apple.fcpxml.time.newFromTimecodeWithFps(timecode, fps) -> timeObject
--- Constructor
--- Create a time object from timecode and frames per second.
---
--- Parameters:
---  * timecode - A timecode string in "hh:mm:ss:ff" format (i.e. 01:00:00:00).
---  * fps - Frames per seconds as a number.
---
--- Returns:
---  * A new `cp.apple.fcpxml.time` object.
function time.newFromTimecodeWithFps(timecode, fps)
    assert(type(timecode) == "string", "[cp.apple.fcpxml.time.newFromTimecodeWithFps] Timecode must be a string")
    assert(type(fps) == "number", "[cp.apple.fcpxml.time.newFromTimecodeWithFps] fps must be a number")

    local values = tools.split(timecode, ":")

    local h = tonumber(values[1])
    local m = tonumber(values[2])
    local s = tonumber(values[3])
    local f = tonumber(values[4])

    fps = time.new(tonumber(fps), 1)
    local totalSeconds = h * 360 + m * 60 + s
    local totalFrames = time.new(totalSeconds, 1) * fps + time.new(f, 1)

    return totalFrames * fps
end

--- cp.apple.fcpxml.time.newFromTimecodeWithFpsAndFrameDuration(timecode, fps, frameDuration) -> timeObject
--- Constructor
--- Create a time object from timecode, frames per second and frame duration.
---
--- Parameters:
---  * A timecode string in "hh:mm:ss:ff" format (i.e. 01:00:00:00).
---  * fps - Frames per seconds as a number.
---  * Frame duration as a time object.
---
--- Returns:
---  * A new `cp.apple.fcpxml.time` object.
function time.newFromTimecodeWithFpsAndFrameDuration(timecode, fps, frameDuration)
    assert(type(timecode) == "string", "[cp.apple.fcpxml.time.newFromTimecodeWithFpsAndFrameDuration] Timecode must be a string")
    assert(type(fps) == "number", "[cp.apple.fcpxml.time.newFromTimecodeWithFpsAndFrameDuration] fps must be a number")
    assert(type(frameDuration) == "table", "[cp.apple.fcpxml.time.newFromTimecodeWithFpsAndFrameDuration] Frame Duration must be a time object")

    local values = tools.split(timecode, ":")

    local h = tonumber(values[1])
    local m = tonumber(values[2])
    local s = tonumber(values[3])
    local f = tonumber(values[4])

    fps = time.new(tonumber(fps), 1)
    local totalSeconds = h * 360 + m * 60 + s
    local totalFrames = time.new(totalSeconds, 1) * fps + time.new(f, 1)

    return totalFrames * frameDuration
end

--- cp.apple.fcpxml.time.new([numerator], [denominator]) -> timeObject
--- Constructor
---
--- Parameters:
---  * An optional numerator as a number (i.e. 3400) or a string value (i.e. "3400/2500s" or "2s"). Defaults to "0s".
---  * A optional denominator as a number (i.e 2500)
---
--- Returns:
---  * A new `cp.apple.fcpxml.time` object.
function time.new(n, d)
    --------------------------------------------------------------------------------
    -- If nothing is supplied, lets assume it's "0s".
    --------------------------------------------------------------------------------
    if type(n) == "nil" and type(d) == "nil" then
        n = 0
        d = 1
    end

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
            local values = tools.split(value, "/")
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
        log.df("n: %s", n)
        log.df("d: %s", d)
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

--- cp.apple.fcpxml.time.min(a, b) -> timeObject
--- Function
--- Gets the smaller of the two time objects.
---
--- Parameters:
---  * a - A time object.
---  * b - A time object.
---
--- Returns:
---  * A time object.
function time.min(a, b)
    assert(type(a) == "table", "[cp.apple.fcpxml.time.min] First attribute must be a time object.")
    assert(type(b) == "table", "[cp.apple.fcpxml.time.min] Second attribute must be a time object.")

    return a <= b and a or b
end

--- cp.apple.fcpxml.time.max(a, b) -> timeObject
--- Function
--- Gets the bigger of the two time objects.
---
--- Parameters:
---  * a - A time object.
---  * b - A time object.
---
--- Returns:
---  * A time object.
function time.max(a, b)
    assert(type(a) == "table", "[cp.apple.fcpxml.time.max] First attribute must be a time object.")
    assert(type(b) == "table", "[cp.apple.fcpxml.time.max] Second attribute must be a time object.")

    return a >= b and a or b
end

--- cp.apple.fcpxml.time.doesIntersect(aStart, aDuration, bStart, bDuration) -> boolean
--- Function
--- Checks to see if two clips intersect.
---
--- Parameters:
---  * aStart - The start time of clip one as a time object.
---  * aDuration - The duration of clip one as a time object.
---  * bStart - The start time of clip two as a time object.
---  * bDuration - The duration of clip two as a time object.
---
--- Returns:
---  * A boolean
function time.doesIntersect(aStart, aDuration, bStart, bDuration)
    assert(type(aStart) == "table", "[cp.apple.fcpxml.time.doesIntersect] First attribute must be a time object.")
    assert(type(aDuration) == "table", "[cp.apple.fcpxml.time.doesIntersect] Second attribute must be a time object.")
    assert(type(bStart) == "table", "[cp.apple.fcpxml.time.doesIntersect] Third attribute must be a time object.")
    assert(type(bDuration) == "table", "[cp.apple.fcpxml.time.doesIntersect] Fourth attribute must be a time object.")

    local aEnd = aStart + aDuration
    local bEnd = bStart + bDuration

    local cStart = time.min(aEnd, time.max(aStart, bStart))
    local cEnd = time.max(aStart, time.min(aEnd, bEnd))

    return cEnd > cStart
end

--- cp.apple.fcpxml.time.ONE -> timeObject
--- Constant
--- A time object with a value of 1/1s.
time.ONE = time.new(1, 1)

--- cp.apple.fcpxml.time.ONE -> timeObject
--- Constant
--- A time object with a value of 0/1s.
time.ZERO = time.new(0, 1)

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
        __call      = function(_, ...) return time.new(...) end
    }
)
return mod