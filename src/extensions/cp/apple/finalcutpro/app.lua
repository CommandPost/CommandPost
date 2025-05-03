--- === cp.apple.finalcutpro.app ===
---
--- The [cp.app](cp.app.md) for Final Cut Pro. Will automatically determine
--- if only the trial version of Final Cut Pro is installed and use that instead.

local require                   = require

local log						= require "hs.logger".new "fcpApp"

local application               = require "hs.application"
local fs				        = require "hs.fs"

local app                       = require "cp.app"

local semver                    = require "semver"

local applicationsForBundleID   = application.applicationsForBundleID
local infoForBundleID           = application.infoForBundleID
local pathToAbsolute			= fs.pathToAbsolute

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

--------------------------------------------------------------------------------
-- Final Cut Pro 11 Sandbox Workaround:
--
-- When the user is running Final Cut Pro 11 (or later), rather than using
-- the bundle identifier to do preferences lookups, we instead pass in the
-- full file path (without the `.plist`) to ensure that CommandPost is reading
-- the correct sandboxed preferences file.
--------------------------------------------------------------------------------
local preferencesID = fcpID
local info = infoForBundleID(fcpID)
local versionString = info and info.CFBundleShortVersionString
local fcpVersion = versionString and semver(versionString)
if fcpVersion and fcpVersion >= semver("11.0.0") then
	log.df("Running Final Cut Pro v%s in a sandbox...", fcpVersion)
	local userFolder = pathToAbsolute("~")
	local sandboxPath = userFolder and string.format("%s/Library/Containers/%s/Data/Library/Preferences/%s", userFolder, fcpID, fcpID)
	if sandboxPath then
		log.df("Using sandbox path for preferences: %s", sandboxPath)
		preferencesID = sandboxPath
	end
end

return app.forBundleID(fcpID, preferencesID)