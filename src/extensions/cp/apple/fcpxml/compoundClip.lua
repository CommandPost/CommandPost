--- === cp.apple.fcpxml.compoundClip ===
---
--- FCPXML Document Compound Clip Object.
---
--- This extension was inspired and uses code based on [Pipeline](https://github.com/reuelk/pipeline).
--- Thank you Reuel Kim for making something truly awesome, and releasing it as Open Source!


local log           = require("hs.logger").new("fcpxmlCompoundClip")

local fnutils       = require("hs.fnutils")

local config        = require("cp.config")
local flicks        = require("cp.time.flicks")
local tools         = require("cp.tools")

local xml           = require("hs._asm.xml")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}
mod.mt = {}
mod.mt.__index = mod.mt

--- cp.apple.fcpxml.compoundClip.new(name, ref, offset, duration, startTimecode, useAudioSubroles) -> fcpxmlCompoundClip Object
--- Constructor
--- Creates a new ref-clip FCPXML Document object.
---
--- Parameters:
---  * name - The name of the Compound Clip as string.
---  * ref - The reference ID of the compound clip as string.
---  * offset - The offset of the compound clip in flicks.
---  * duration - The duration of the compound clip in flicks.
---  * startTimecode - The start timecode in flicks.
---  * useAudioSubroles - A boolean.
---
--- Returns:
---  * A new Compound Clip object.
function mod.new(name, ref, offset, duration, startTimecode, useAudioSubroles)
    local o = {}
    return setmetatable(o, {__index = mod.mt})
end

return mod