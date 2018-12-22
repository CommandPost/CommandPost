--- === cp.apple.finalcutpro.app ===
---
--- The `cp.app` for Final Cut Pro.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local application = require("hs.application")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local app = require("cp.app")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local fcpID = "com.apple.FinalCut"
local trialID = "com.apple.FinalCutTrial"

--------------------------------------------------------------------------------
-- If the main application isn't installed but the trial is, then use the
-- trial bundle ID instead:
--------------------------------------------------------------------------------
if application.infoForBundleID(fcpID) == nil and application.infoForBundleID(trialID) ~= nil then
    fcpID = trialID
end

return app.forBundleID(fcpID)