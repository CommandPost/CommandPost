--- === cp.apple.finalcutpro.app ===
---
--- The [cp.app](cp.app.md) for Final Cut Pro. Will automatically determine
--- if only the trial version of FCPX is installed and use that instead.

local require                   = require

local application               = require "hs.application"

local app                       = require "cp.app"

local applicationsForBundleID   = application.applicationsForBundleID
local infoForBundleID           = application.infoForBundleID

local fcpID                     = "com.apple.FinalCut"
local trialID                   = "com.apple.FinalCutTrial"

local trialApplications = applicationsForBundleID(trialID) or {}

if #trialApplications == 1 then
    --------------------------------------------------------------------------------
    -- If the trial version is currently running, then use the Trial bundle
    -- identifier instead of the full version:
    --------------------------------------------------------------------------------
    fcpID = trialID
elseif infoForBundleID(fcpID) == nil and infoForBundleID(trialID) ~= nil then
    --------------------------------------------------------------------------------
    -- If the main application isn't installed but the trial is, then use the
    -- trial bundle ID instead:
    --------------------------------------------------------------------------------
    fcpID = trialID
end


return app.forBundleID(fcpID)