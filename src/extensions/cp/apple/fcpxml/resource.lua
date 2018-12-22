--- === cp.apple.fcpxml.resource ===
---
--- FCPXML Document Resource Object.
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
local log           = require("hs.logger").new("fcpxmlResource")

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