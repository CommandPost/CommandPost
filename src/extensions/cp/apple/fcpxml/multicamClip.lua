--- === cp.apple.fcpxml.multicamClip ===
---
--- FCPXML Document Multicam Clip Object.
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
local log           = require("hs.logger").new("fcpxmlMulticamClip")

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

--- cp.apple.fcpxml.multicamClip.new(name, refID, offset, startTimecode, duration, mcSources) -> fcpxmlMulticamClip Object
--- Constructor
--- Creates a new multicam event clip FCPXML Document object.
---
--- Parameters:
---  * name - The name of the Multicam Clip as a string.
---  * refID - The reference ID of the Multicam Clip.
---  * offset - The offset of the Multicam clip in flicks.
---  * startTimecode - The start timecode in flicks.
---  * duration - The duration of the Multicam clip.
---  * mcSources - A table of multicam sources.
---
--- Returns:
---  * A new Multicam Clip object.
function mod.new(name, refID, offset, startTimecode, duration, mcSources)
    local o = {}
    return setmetatable(o, {__index = mod.mt})
end

return mod