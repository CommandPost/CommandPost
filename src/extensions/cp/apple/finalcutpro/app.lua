--- === cp.apple.finalcutpro.app ===
---
--- The [cp.app](cp.app.md) for Final Cut Pro. Will automatically determine
--- if only the trial version of FCPX is installed and use that instead.

local require = require

local application = require("hs.application")

local app = require("cp.app")

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