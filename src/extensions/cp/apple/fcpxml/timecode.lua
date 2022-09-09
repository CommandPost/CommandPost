--- === cp.apple.fcpxml.timecode ===
---
--- Functions for working with timecode in Final Cut Pro XML. Note that
--- a timecode does not have any concept of a frame rate, so it is
--- simple a structure of hours, minutes, seconds and frames.
---
--- To calculate the exact number of frames for a timecode, call the
--- `timecode:totalFramesWithFPS(fps)` method, where `fps` is a `number`.
---
--- To calculate the exact number of seconds for a timecode, call the
--- `timecode:timeWithFrameDuration(frameDuration)` method,
--- where `frameDuration` is the frame duration as a `time` value.
---
--- Note, this currently does not support "Drop Frame" timecodes.

local require       = require

--local log           = require "hs.logger".new "timecode"
local time          = require "cp.apple.fcpxml.time"

local timecode = {}
timecode.mt = {}
timecode.mt.__index = timecode.mt

--- cp.apple.fcpxml.timecode.new(hours, minutes, seconds, frames)
--- Constructor
--- Creates a new timecode object.
---
--- Parameters:
---  * hours - The number of hours.
---  * minutes - The number of minutes.
---  * seconds - The number of seconds.
---  * frames - The number of frames.
---
--- Returns:
---  * The new timecode object.
function timecode.new(hours, minutes, seconds, frames)
    local o = {
        hours = hours,
        minutes = minutes,
        seconds = seconds,
        frames = frames,
    }
    return setmetatable(o, timecode.mt)
end

--- cp.apple.fcpxml.timecode.fromHH_MM_SS_FF(timecodeString) -> timecode
--- Constructor
--- Parses a timecode string in the format `HH:MM:SS:FF` and returns a new timecode object.
---
--- Parameters:
---  * timecodeString - The timecode string.
---
--- Returns:
---  * The new timecode object.
function timecode.fromHH_MM_SS_FF(timecodeString)
    local hours, minutes, seconds, frames = timecodeString:match("(%d+):(%d+):(%d+):(%d+)")
    return timecode.new(tonumber(hours), tonumber(minutes), tonumber(seconds), tonumber(frames))
end

--- cp.apple.fcpxml.timecode.fromFFSSMMHH(timecodeString) -> timecode
--- Constructor
--- Parses a timecode string in the format `FFSSMMHH` and returns a new timecode object.
---
--- Parameters:
---  * timecodeString - The timecode string.
---
--- Returns:
---  * The new timecode object.
function timecode.fromFFSSMMHH(timecodeString)
    local frames, seconds, minutes, hours = timecodeString:match("(%d%d)(%d%d)(%d%d)(%d%d)")
    return timecode.new(tonumber(hours), tonumber(minutes), tonumber(seconds), tonumber(frames))
end

--- cp.apple.fcpxml.timecode:timeWithFrameDuration(frameDuration) -> time
--- Method
--- Calculates the `time` for the timecode, given the frame duration `time` value.
---
--- Parameters:
---  * frameDuration - The frame duration as a `time` value.
---
--- Returns:
---  * The `time` value.
function timecode.mt:timeWithFrameDuration(frameDuration)
    local totalSeconds = self.seconds + (self.minutes * 60) + (self.hours * 3600)
    return time.new(totalSeconds) + (time.new(self.frames) * frameDuration)
end

--- cp.apple.fcpxml.timecode:totalFramesWithFPS(fps) -> number
--- Method
--- Calculates the total number of frames for the timecode, given the specified frame rate.
---
--- Parameters:
---  * fps - The frame rate as a `number`.
---
--- Returns:
---  * The total number of frames as a `number`.
function timecode.mt:totalFramesWithFPS(fps)
    return self.frames + (self.seconds * fps) + (self.minutes * 60 * fps) + (self.hours * 60 * 60 * fps)
end

--- cp.apple.fcpxml.timecode:__tostring() -> string
--- Method
--- Returns the timecode as a string in the format `HH:MM:SS:FF`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The timecode string.
function timecode.mt:__tostring()
    return string.format("%02d:%02d:%02d:%02d", self.hours, self.minutes, self.seconds, self.frames)
end

setmetatable(timecode, {
    __call = function(_, ...) return timecode.new(...) end
})

return timecode