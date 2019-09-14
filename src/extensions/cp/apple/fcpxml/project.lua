--- === cp.apple.fcpxml.project ===
---
--- FCPXML Document Project Object.
---
--- This extension was inspired and uses code based on [Pipeline](https://github.com/reuelk/pipeline).
--- Thank you Reuel Kim for making something truly awesome, and releasing it as Open Source!


local log           = require("hs.logger").new("fcpxmlProject")

local fnutils       = require("hs.fnutils")

local config        = require("cp.config")
local flicks        = require("cp.time.flicks")
local tools         = require("cp.tools")

local xml           = require("hs._asm.xml")


local mod = {}
mod.mt = {}
mod.mt.__index = mod.mt

--- cp.apple.fcpxml.project.new(name, format, duration, timecodeStart, timecodeFormat, audioLayout, audioRate, renderColorSpace[, clips]) -> fcpxmlProject Object
--- Constructor
--- Creates a new project FCPXML object and optionally adds clips to it.
---
--- Parameters:
---  * name - The name of the project as a string.
---  * format - The format of the project.
---  * duration - The duration of the project.
---  * timecodeStart - The start timecode of the project.
---  * timecodeFormat - The timecode format of the project.
---  * audioLayout - The audio layout of the project.
---  * audioRate - The audio sample rate of the project.
---  * renderColorSpace - The render color space of the project.
---  * clips - An optional table of clips you want to add to the project.
---
--- Returns:
---  * A new project object.
function mod.new(name, format, duration, timecodeStart, timecodeFormat, audioLayout, audioRate, renderColorSpace, clips)
    local o = {}
    return setmetatable(o, {__index = mod.mt})
end

return mod