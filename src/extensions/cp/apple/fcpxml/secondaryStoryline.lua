--- === cp.apple.fcpxml.secondaryStoryline ===
---
--- FCPXML Document Secondary Storyline Object.
---
--- This extension was inspired and uses code based on [Pipeline](https://github.com/reuelk/pipeline).
--- Thank you Reuel Kim for making something truly awesome, and releasing it as Open Source!


local log           = require("hs.logger").new("fcpxmlSecondaryStoryline")

local fnutils       = require("hs.fnutils")

local config        = require("cp.config")
local flicks        = require("cp.time.flicks")
local tools         = require("cp.tools")

local xml           = require("hs._asm.xml")


local mod = {}
mod.mt = {}
mod.mt.__index = mod.mt

--- cp.apple.fcpxml.secondaryStoryline.new(lane, offset, formatRef, clips) -> fcpxmlSecondaryStoryline Object
--- Constructor
--- Creates a new secondary storyline FCPXML Document object.
---
--- Parameters:
---  * lane - The lane you want the secondary storyline to appear.
---  * offset - The offset of the secondary storyline in flicks.
---  * formatRef - The format of the secondary storyline.
---  * clips - A table of clips.
---
--- Returns:
---  * A new Secondary Storyline object.
function mod.new(lane, offset, formatRef, clips)
    local o = {}
    return setmetatable(o, {__index = mod.mt})
end

return mod