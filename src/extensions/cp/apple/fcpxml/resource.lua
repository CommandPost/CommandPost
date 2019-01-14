--- === cp.apple.fcpxml.resource ===
---
--- FCPXML Document Resource Object.
---
--- This extension was inspired and uses code based on [Pipeline](https://github.com/reuelk/pipeline).
--- Thank you Reuel Kim for making something truly awesome, and releasing it as Open Source!


local log           = require("hs.logger").new("fcpxmlResource")

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

--------------------------------------------------------------------------------
-- FCPXML DOCUMENT CONSTRUCTORS:
--------------------------------------------------------------------------------

--- cp.apple.fcpxml.resource.new() -> fcpxmlResource Object
--- Constructor
--- Creates a new resource object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A new FCPXML Document Resource object.
function mod.new()
    local o = {}
    return setmetatable(o, {__index = mod.mt})
end

return mod