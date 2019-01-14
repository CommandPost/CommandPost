--- === cp.apple.fcpxml.multicamResource ===
---
--- FCPXML Document Multicam Resource Object.
---
--- This extension was inspired and uses code based on [Pipeline](https://github.com/reuelk/pipeline).
--- Thank you Reuel Kim for making something truly awesome, and releasing it as Open Source!


local log           = require("hs.logger").new("fcpxmlMulticamResource")

local fnutils       = require("hs.fnutils")

local config        = require("cp.config")
local flicks        = require("cp.time.flicks")
local tools         = require("cp.tools")

--------------------------------------------------------------------------------
-- 3rd Party Extensions:
--------------------------------------------------------------------------------
local xml           = require("hs._asm.xml")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}
mod.mt = {}
mod.mt.__index = mod.mt

--- cp.apple.fcpxml.multicamResource.new(name, id, formatRef, startTimecode, timecodeFormat, renderColorSpace, angles) -> fcpxmlMulticamResource Object
--- Constructor
--- Creates a new FCPXML multicam reference FCPXML Document object.
---
--- Parameters:
---  * name - The name of the Multicam Resource as a string.
---  * id - The ID of the Multicam Resource as a string.
---  * formatRef - The format of the Multicam Resource.
---  * startTimecode - The start timecode in flicks.
---  * timecodeFormat - The timecode format (see: `cp.apple.fcpxml.TIMECODE_FORMAT`).
---  * renderColorSpace - The render color space (see: `cp.apple.fcpxml.COLOR_SPACE`).
---  * angles - A table of angle objects.
---
--- Returns:
---  * A new Multicam Resource object.
function mod.new(name, id, formatRef, startTimecode, timecodeFormat, renderColorSpace, angles)
    local o = {}
    return setmetatable(o, {__index = mod.mt})
end

return mod