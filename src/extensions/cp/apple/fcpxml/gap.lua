--- === cp.apple.fcpxml.gap ===
---
--- FCPXML Document Gap Object.
---
--- This extension was inspired and uses code based on [Pipeline](https://github.com/reuelk/pipeline).
--- Thank you Reuel Kim for making something truly awesome, and releasing it as Open Source!

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log           = require("hs.logger").new("fcpxmlGap")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local fnutils       = require("hs.fnutils")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
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

--- cp.apple.fcpxml.gap.new(offset, duration, startTimecode) -> fcpxmlGap Object
--- Constructor
--- Creates a new gap to be used in a timeline.
---
--- Parameters:
---  * offset - The offset of the Gap clip in flicks.
---  * duration - The duration of the Gap clip in flicks.
---  * startTimecode - The start timecode of the Gap clip in flicks.
---
--- Returns:
---  * A new Gap Clip object.
function mod.new(offset, duration, startTimecode)
    local o = {}
    return setmetatable(o, {__index = mod.mt})
end

return mod