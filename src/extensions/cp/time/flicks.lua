--- === cp.time.flicks ===
---
--- Provides support for measuring time in `flicks`, a base unit of time useful for
--- working with media, such as video or audio files.
---
--- From the [Flicks GitHub project]():
---
---
--- A flick (frame-tick) is a very small unit of time. It is 1/705600000 of a second, exactly.
---
--- `1 flick = 1/705600000 second`
---
--- This unit of time is the smallest time unit which is LARGER than a nanosecond, and can in integer quantities exactly
--- represent a single frame duration for 24 Hz, 25 Hz, 30 Hz, 48 Hz, 50 Hz, 60 Hz, 90 Hz, 100 Hz, 120 Hz, and
--- also 1/1000 divisions of each, as well as a single sample duration for 8 kHz, 16 kHz, 22.05 kHz, 24 kHz, 32 kHz,
--- 44.1 kHz, 48 kHz, 88.2 kHz, 96 kHz, and 192kHz, as well as the NTSC frame durations for 24 * (1000/1001) Hz,
--- 30 * (1000/1001) Hz, 60 * (1000/1001) Hz, and 120 * (1000/1001) Hz.
---
--- That above was one hell of a run-on sentence, but it's strictly and completely correct in its description of
--- the unit.
---
--- This makes flicks suitable for use via std::chrono::duration and std::ratio for doing timing work against the
--- system high resolution clock, which is in nanoseconds, but doesn't get slightly out of sync when doing
--- common frame rates.
---
--- We also support some common audio sample rates as well. This list is not exhaustive, but covers the majority
--- of digital audio formats. They are 8kHz, 16kHz, 22.05kHz, 24kHz, 32kHz, 44.1kHz, 48kHz, 88.2kHz, 96kHz, and 192kHz.
---
--- Though it is not part of the design criteria, 144 Hz, which some newer monitors refresh at, does work
--- correctly with flicks.
---
--- NTSC IS NOT EXPLICITLY SUPPORTED IN ALL OF ITS SUBTLE NUANCES, BUT: The NTSC variations (~23.976, ~29.97, etc)
--- are approximately defined as 24 * 1000/1001 and 30 * 1000/1001, etc. These can be represented exactly in flicks,
--- but 1/1000 divisions are not available.
---
--- Many folks online have pointed out that NTSC technically has a variable frame rate, and that this is handled
--- correctly in other media playback libraries such as QuickTime. The goal of flicks is to provide a simple,
--- convenient std::chrono::duration to work with when writing code that works with simulation and time in media,
--- but not explicitly to handle complex variable-rate playback scenarios. So we'll stick with the 1000/1001
--- approximations, and leave it at that!
---
--- # Details
---
--- * 24 fps frame: 29400000 flicks
--- * 25 fps frame: 28224000 flicks
--- * 30 fps frame: 23520000 flicks
--- * 48 fps frame: 14700000 flicks
--- * 50 fps frame: 14112000 flicks
--- * 60 fps frame: 11760000 flicks
--- * 90 fps frame: 7840000 flicks
--- * 100 fps frame: 7056000 flicks
--- * 120 fps frame: 5880000 flicks
--- * 8000 fps frame: 88200 flicks
--- * 16000 fps frame: 44100 flicks
--- * 22050 fps frame: 32000 flicks
--- * 24000 fps frame: 29400 flicks
--- * 32000 fps frame: 22050 flicks
--- * 44100 fps frame: 16000 flicks
--- * 48000 fps frame: 14700 flicks
--- * 88200 fps frame: 8000 flicks
--- * 96000 fps frame: 7350 flicks
--- * 192000 fps frame: 3675 flicks
---
--- # NTSC:
--- *
--- * 24 * 1000/1001 (~23.976) fps frame: 29429400 flicks
--- * 30 * 1000/1001 (~29.97) fps frame: 23543520 flicks
--- * 60 * 1000/1001 (~59.94) fps frame: 11771760 flicks
--- * 120 * 1000/1001 (~119.88) fps frame: 5885880 flicks

-- local log					= require("hs.logger").new("flicks")

local mod = {}

mod.mt = {}
mod.mt.__index = mod.mt

--- cp.time.flicks.perSecond
--- Constant
--- The number of flicks in 1 second.
mod.perSecond = 705600000

--- cp.time.flicks.perFrame24
--- Constant
--- The number of flicks in 1 frame at 24 fps.
mod.perFrame24 = 29400000

--- cp.time.flicks.new(value[, units]) -> flicks
--- Constructor
--- Creates a new `flicks` instance. By default, the unit is in flicks`, but can be set as a
--- different unit using the `flicks.perXXX` constants. For example:
---
--- ```lua
--- local oneFlick = flicks.new(1)
--- local oneSecond = flicks.new(1, flicks.perSecond)
--- ```
---
--- Parameters:
---  * value - the base value to set to
---  * units - the units the value is in. Defaults to flicks.
---
--- Returns:
---  * the new `flicks` instance
function mod.new(value, units)
    units = units or 1
    local o = {
        value = value * units // 1,
    }
    return setmetatable(o, mod.mt)
end

--- cp.time.flicks.is(thing) -> boolean
--- Function
--- Checks if the `thing` is a `flicks` instance.
---
--- Parameters:
---  * thing - the thing to check
---
--- Returns:
---  * `true` if the thingis a flicks instance, otherwise `false`.
function mod.is(thing)
    return type(thing) == "table" and getmetatable(thing) == mod.mt
end

setmetatable(mod, {
	__call = function(_, ...)
		return mod.new(...)
	end
})

--- cp.time.flicks:toSeconds() -> number
--- Method
--- Converts the flicks into a decimal value of the number of seconds it represents.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the number of seconds
function mod.mt:toSeconds()
    return self.value / mod.perSecond
end

function mod.mt.__tostring(self)
    return tostring(self.value) .. " flicks"
end

function mod.mt.__eq(left, right)
	return left.value == right.value
end

function mod.mt.__unm(self)
    return mod.new(self.value * -1)
end

local function check(value, label)
    if not mod.is(value) then
        label = label or "value"
        error(string.format("Expected %s to be a `flicks` instance: %s", label, type(value)))
    end
    return value
end

local function toFlicksValue(value)
    return mod.is(value) and value.value or tonumber(value) * mod.perSecond
end

function mod.mt.__add(left, right)
    left = check(left, "left")
    right = check(right, "right")

    return mod.new(left.value + right.value)
end

function mod.mt.__sub(left, right)
    local leftFlicks = toFlicksValue(left)
    local rightFlicks = toFlicksValue(right)

    return mod.new(leftFlicks - rightFlicks)
end

-- cp.time.flicks.__mul(left, right) -> flicks
-- Function
-- Multiplies the left by the right value. Only one may be a `flicks` value - the other must
-- be able to be converted to a number via `tonumber(...)`.
--
-- Parameters:
--  * left  - The left operand
--  * right - The right operand
--
-- Returns:
--  * a new `flicks` with the specified values multiplied, or an error if not compatible.
function mod.mt.__mul(left, right)
    if mod.is(left) and mod.is(right) then
        error("Either the left or right operand must not be a `flicks` instance.")
    end
    local flicksValue = mod.is(left) and left.value * tonumber(right) or tonumber(left) * right.value
    return mod.new(flicksValue)
end

-- cp.time.flicks.__div(left, right) -> flicks
-- Function
-- Divides the left by the right value. Only one may be a `flicks` value - the other must
-- be able to be converted to a number via `tonumber(...)`.
--
-- Parameters:
--  * left  - The left operand
--  * right - The right operand
--
-- Returns:
--  * a new `flicks` with the specified values divided, or an error if not compatible.
function mod.mt.__div(left, right)
    if mod.is(left) and mod.is(right) then
        error("Either the left or right operand must not be a `flicks` instance.")
    end
    local flicksValue = mod.is(left) and left.value / tonumber(right) or tonumber(left) / right.value
    return mod.new(flicksValue)
end

-- cp.time.flicks.__idiv(left, right) -> flicks
-- Function
-- Performs a floor divsion (`//`) the left by the right value. Only one may be a `flicks` value - the other must
-- be able to be converted to a number via `tonumber(...)`.
--
-- Parameters:
--  * left  - The left operand
--  * right - The right operand
--
-- Returns:
--  * a new `flicks` with the specified values divided, or an error if not compatible.
function mod.mt.__idiv(left, right)
    if mod.is(left) and mod.is(right) then
        error("Either the left or right operand must not be a `flicks` instance.")
    end
    local flicksValue = mod.is(left) and (left.value // tonumber(right)) or (tonumber(left) // right.value)
    return mod.new(flicksValue)
end

-- cp.time.flicks.__idiv(left, right) -> flicks
-- Function
-- Performs a modulo (`%`) the left by the right value. Only one may be a `flicks` value - the other must
-- be able to be converted to a number via `tonumber(...)`.
--
-- Parameters:
--  * left  - The left operand
--  * right - The right operand
--
-- Returns:
--  * a new `flicks` with the specified values divided, or an error if not compatible.
function mod.mt.__mod(left, right)
    if mod.is(left) and mod.is(right) then
        error("Either the left or right operand must not be a `flicks` instance.")
    end
    local flicksValue = mod.is(left) and left.value % tonumber(right) or tonumber(left) % right.value
    return mod.new(flicksValue)
end

return mod