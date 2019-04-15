--- === cp.apple.fcpxml.event ===
---
--- FCPXML Document Event Object.
---
--- This extension was inspired and uses code based on [Pipeline](https://github.com/reuelk/pipeline).
--- Thank you Reuel Kim for making something truly awesome, and releasing it as Open Source!


local log           = require("hs.logger").new("fcpxmlEvent")

local fnutils       = require("hs.fnutils")

local config        = require("cp.config")
local flicks        = require("cp.time.flicks")
local tools         = require("cp.tools")

local xml           = require("hs._asm.xml")


local mod = {}
mod.mt = {}
mod.mt.__index = mod.mt

--- cp.apple.fcpxml.event.new(name[, items]) -> fcpxmlEvent Object
--- Constructor
--- Creates a new event object.
---
--- Parameters:
---  * name - The name of the event.
---  * items - An optional table of items to add to the event.
---
--- Returns:
---  * A new event object.
function mod.new(name, items)
    local o = {}
    return setmetatable(o, {__index = mod.mt})
end

return mod