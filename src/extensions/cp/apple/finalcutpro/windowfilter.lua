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
local logname										= "fcpWinFilter"

local log											= require("hs.logger").new(logname)

local windowfilter									= require("hs.window.filter")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--log.df("Setting up Final Cut Pro Window Filter...")

windowfilter.setLogLevel("error") -- The wfilter errors are too annoying.

mod.windowfilter = windowfilter.new(function(window)
	return window and window:application():bundleID() == "com.apple.FinalCut" -- TODO: This should be taken from cp.apple.finalcutpro.BUNDLE_ID somehow?
end, logname)

return mod.windowfilter