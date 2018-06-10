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
---
--- * 24 * 1000/1001 (~23.976) fps frame: 29429400 flicks
--- * 30 * 1000/1001 (~29.97) fps frame: 23543520 flicks
--- * 60 * 1000/1001 (~59.94) fps frame: 11771760 flicks
--- * 120 * 1000/1001 (~119.88) fps frame: 5885880 flicks

local log					= require("hs.logger").new("flicks")

local format                = string.format

local flicks = {}

flicks.mt = {}
flicks.mt.__index = flicks.mt

--- cp.time.flicks.perSecond
--- Constant
--- The number of flicks in 1 second.
flicks.perSecond = 705600000

--- cp.time.flicks.perMinutes
--- Constant
--- The number of flicks in 1 minute.
flicks.perMinute = 60 * flicks.perSecond

--- cp.time.flicks.perHour
--- Constant
--- The number of flicks in 1 hour.
flicks.perHour = 60 * flicks.perMinute

--- cp.time.flicks.perFrame24
--- Constant
--- The number of flicks in 1 frame at 24 fps.
flicks.perFrame24 = 29400000

--- cp.time.flicks.perFrame25
--- Constant
--- The number of flicks in 1 frame at 25 fps.
flicks.perFrame25 = 28224000

--- cp.time.flicks.perFrame30
--- Constant
--- The number of flicks in 1 frame at 30 fps.
flicks.perFrame30 = 23520000

--- cp.time.flicks.perFrame48
--- Constant
--- The number of flicks in 1 frame at 48 fps.
flicks.perFrame48 = 14700000

--- cp.time.flicks.perFrame50
--- Constant
--- The number of flicks in 1 frame at 50 fps.
flicks.perFrame50 = 14112000

--- cp.time.flicks.perFrame60
--- Constant
--- The number of flicks in 1 frame at 60 fps.
flicks.perFrame60 = 11760000

--- cp.time.flicks.perFrame90
--- Constant
--- The number of flicks in 1 frame at 90 fps.
flicks.perFrame90 = 7840000

--- cp.time.flicks.perFrame100
--- Constant
--- The number of flicks in 1 frame at 100 fps.
flicks.perFrame100 = 7056000

--- cp.time.flicks.perFrame120
--- Constant
--- The number of flicks in 1 frame at 120 fps.
flicks.perFrame120 = 5880000

--- cp.time.flicks.perFrame44100
--- Constant
--- The number of flicks in 1 frame at 44100 fps, a.k.a. 44.1 Hz.
flicks.perFrame44100 = 16000

--- cp.time.flicks.perFrame48000
--- Constant
--- The number of flicks in 1 frame at 44100 fps, a.k.a. 48 Hz.
flicks.perFrame48000 = 14700

--- cp.time.flicks.perFrame24NTSC
--- Constant
--- An approximate for flicks in 1 frame at 24 fps in NTSC, a.k.a. 23.976 fps.
flicks.perFrame24NTSC = 29429400

--- cp.time.flicks.perFrame30NTSC
--- Constant
--- An approximate for flicks in 1 frame at 30 fps in NTSC, a.k.a. 29.97 fps.
flicks.perFrame30NTSC = 23543520

--- cp.time.flicks.perFrame60NTSC
--- Constant
--- An approximate for flicks in 1 frame at 60 fps in NTSC, a.k.a. 59.94 fps.
flicks.perFrame60NTSC = 11771760

--- cp.time.flicks.perFrame120NTSC
--- Constant
--- An approximate for flicks in 1 frame at 120 fps in NTSC, a.k.a. ~119.88 fps.
flicks.perFrame120NTSC = 5885880

flicks.perFrame = {
    [23.976] = flicks.perFrame24NTSC,
    [23.98] = flicks.perFrame24NTSC,
    [29.97] = flicks.perFrame30NTSC,
    [59.94] = flicks.perFrame60NTSC,
    [119.88] = flicks.perFrame120NTSC,
}

local function DIV(a,b)
    return (a - a % b) / b
end

local function _findFlicksPerFrame(framerate)
    if framerate % 1 ~= 0 then
        return flicks.perFrame[framerate], math.ceil(framerate)
    else
        return flicks.perSecond / framerate, framerate
    end
end

--- cp.time.flicks.parse(timecodeString, framerate) -> flicks
--- Constructor
--- Attempts to parse the timecode string value with the specified framerate.
--- The timecode can match the folowing patterns:
---
--- * `"HH:MM:SS:FF"`
--- * `"HH:MM:SS;FF"`
--- * `"HHMMSSFF"`
---
--- The characters above match to `H`ours, `M`inutes `S`econds and `F`rames, respectively. For example,
--- a timecode of 1 hour, 23 minutes, 45 seconds and 12 frames could be expressed as:
---
--- * `"01:23:45:12"`
--- * `"01:23:45;12"`
--- * `"01234512"`
---
--- Times with a value of zero from left to right may be omitted. After the first non-zero value, all
--- other numbers including framesmust always be expressed, even if they are zero.
--- So, if your timecode is 1 minute 30 seconds, you could use:
---
--- * `"1:30:00"`
--- * `"1:30;00"`
--- * `"13000"`
---
--- You can also put numbers up to `99` in each block. So, another way of expressing 1 minute 30 seconds is:
---
--- * `"90:00"`
--- * `"90;00"`
--- * `"9000"`
---
--- Parameters:
---  * timecodeString   - The timecode as a string.
---  * framerate        - The number of frames per second.
---
--- Returns:
---  * a new `flicks` instance for the timecode.
function flicks.parse(timecodeString, framerate)
    local tokens = timecodeString:gsub("[;:]", "")
    local block, multiplier = _findFlicksPerFrame(framerate)
    if not block then
        error("Unsupported framerate: %s", framerate)
    end
    local value = 0

    repeat
        local remainder, chunk = tokens:match("^(.*)(%d%d)$")
        if chunk then
            value = value + tonumber(chunk) * block
            block = block * multiplier
            multiplier = 60
            tokens = remainder
        end
    until remainder == nil or string.len(remainder) < 2

    if tokens:match("^%d$") then -- it's an odd-numbered remainder.
        value = value + tonumber(tokens) * block
    elseif tokens ~= "" then
        error("Unexpected timecode value: %s", tokens)
    end

    return flicks(value)
end

--- cp.time.flicks.new(value) -> flicks
--- Constructor
--- Creates a new `flicks` instance. By default, the unit is in flicks`, but can be set as a
--- different unit using the `flicks.perXXX` constants. For example:
---
--- ```lua
--- local oneFlick = flicks.new(1)
--- local oneSecond = flicks.new(1 * flicks.perSecond)
--- ```
---
--- Parameters:
---  * value - the base value to set to
---
--- Returns:
---  * the new `flicks` instance
function flicks.new(value)
    local o = {
        value = value // 1,
    }
    return setmetatable(o, flicks.mt)
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
function flicks.is(thing)
    return type(thing) == "table" and getmetatable(thing) == flicks.mt
end

setmetatable(flicks, {
	__call = function(_, ...)
		return flicks.new(...)
	end
})

--- cp.time.flicks:toFrames(framerate) --> number
--- Method
--- Converts the flicks into a number for the specific framerate.

--- cp.time.flicks:toSeconds() -> number
--- Method
--- Converts the flicks into a decimal value of the number of seconds it represents.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the number of seconds
function flicks.mt:toSeconds()
    return self.value / flicks.perSecond
end

--- cp.time.flicks:toTimecode(framerate[, delimeter]) -> string
--- Method
--- Converts the flicks into a string of the format "HH[:]MM[:]SS[:;]FF", with hours, minutes and frames listed respectively.
--- By default, there will be no delimiter. If you provide ":" then all delimiters will be colons. If you provide
--- ";" then the final delimiter will be a semic-colon, all others will be colons.
---
--- Parameters:
---  * framerate    - the framerate to use when calculating frames per second.
---  * delimeter    - either `nil` (default), ":", or ";".
---
--- Returns:
---  * String of the timecode.
function flicks.mt:toTimecode(framerate, delimeter)
    local result
    local flicksPerFrame, fps = _findFlicksPerFrame(framerate)
    if not flicksPerFrame then
        error("Unsupported framerate: %s", framerate)
    end

    if delimeter ~= nil and delimeter ~= ":" and delimeter ~= ";" then
        error("Unsupported delimiter: %s", delimeter)
    else
        delimeter = delimeter or ""
    end

    local frames = self.value / flicksPerFrame
    -- log.df("toTimecode: frames = %s; framerate = %s", frames, framerate)
    -- log.df("toTimecode: mod = %s", frames % framerate // 1)
    result = format("%02d", frames % fps // 1)
    local seconds = frames // fps
    result = format("%02d", seconds % 60) .. delimeter .. result
    if delimeter == ";" then
        delimeter = ":"
    end
    local minutes = seconds // 60
    result = format("%02d", minutes % 60) .. delimeter .. result
    local hours = minutes // 60
    result = format("%02d", hours % 60) .. delimeter .. result

    return result
end

function flicks.mt.__tostring(self)
    return tostring(self.value) .. " flicks"
end

function flicks.mt.__eq(left, right)
	return left.value == right.value
end

function flicks.mt.__unm(self)
    return flicks.new(self.value * -1)
end

local function check(value, label)
    if not flicks.is(value) then
        label = label or "value"
        error(string.format("Expected %s to be a `flicks` instance: %s", label, type(value)))
    end
    return value
end

local function toFlicksValue(value)
    return flicks.is(value) and value.value or tonumber(value) * flicks.perSecond
end

function flicks.mt.__add(left, right)
    left = check(left, "left")
    right = check(right, "right")

    return flicks.new(left.value + right.value)
end

function flicks.mt.__sub(left, right)
    local leftFlicks = toFlicksValue(left)
    local rightFlicks = toFlicksValue(right)

    return flicks.new(leftFlicks - rightFlicks)
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
function flicks.mt.__mul(left, right)
    if flicks.is(left) and flicks.is(right) then
        error("Either the left or right operand must not be a `flicks` instance.")
    end
    local flicksValue = flicks.is(left) and left.value * tonumber(right) or tonumber(left) * right.value
    return flicks.new(flicksValue)
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
function flicks.mt.__div(left, right)
    if flicks.is(left) and flicks.is(right) then
        error("Either the left or right operand must not be a `flicks` instance.")
    end
    local flicksValue = flicks.is(left) and left.value / tonumber(right) or tonumber(left) / right.value
    return flicks.new(flicksValue)
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
function flicks.mt.__idiv(left, right)
    if flicks.is(left) and flicks.is(right) then
        error("Either the left or right operand must not be a `flicks` instance.")
    end
    local flicksValue = flicks.is(left) and (left.value // tonumber(right)) or (tonumber(left) // right.value)
    return flicks.new(flicksValue)
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
function flicks.mt.__mod(left, right)
    if flicks.is(left) and flicks.is(right) then
        error("Either the left or right operand must not be a `flicks` instance.")
    end
    local flicksValue = flicks.is(left) and left.value % tonumber(right) or tonumber(left) % right.value
    return flicks.new(flicksValue)
end

function flicks.mt.__eq(left, right)
    return left.value == right.value
end

function flicks.mt.__lt(left, right)
    return left.value < right.value
end

function flicks.mt.__le(left, right)
    return left.value <= right.value
end

return flicks