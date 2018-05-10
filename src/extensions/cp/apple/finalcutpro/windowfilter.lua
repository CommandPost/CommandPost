--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.windowfilter ===
---
--- Window Filter for Final Cut Pro.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local windowfilter              = require("hs.window.filter")
local fcpApp                    = require("cp.apple.finalcutpro.app")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

-- Disable Window Filter Errors (the wfilter errors are too annoying):
windowfilter.setLogLevel("nothing")

--- cp.apple.finalcutpro.windowfilter.LOG_NAME -> string
--- Constant
--- The name of the `hs.logger` instance.
mod.LOG_NAME = "fcpWinFilter"

--- cp.apple.finalcutpro.windowfilter.windowfilter -> hs.window.filter object
--- Function
--- Creates a new `hs.window.filter` instance.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A new `windowfilter` instance
mod.windowfilter = windowfilter.new(function(window)
    return window and window:application():bundleID() == fcpApp:bundleID()
end, mod.LOG_NAME)

return mod.windowfilter