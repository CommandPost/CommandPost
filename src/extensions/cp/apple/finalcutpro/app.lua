--- === cp.apple.finalcutpro.app ===
---
--- The [cp.app](cp.app.md) for Final Cut Pro. Will automatically determine
--- if only the trial version of FCPX is installed and use that instead.

local require               = require

local log                   = require "hs.logger" .new "fcpApp"

local application           = require "hs.application"

local app                   = require "cp.app"
local config                = require "cp.config"

local semver                = require "semver"

local infoForBundleID       = application.infoForBundleID

local fcpID                 = "com.apple.FinalCut"
local trialID               = "com.apple.FinalCutTrial"

--------------------------------------------------------------------------------
-- If the main application isn't installed but the trial is, then use the
-- trial bundle ID instead:
--------------------------------------------------------------------------------
if infoForBundleID(fcpID) == nil and infoForBundleID(trialID) ~= nil then
    fcpID = trialID
end

--------------------------------------------------------------------------------
-- This is a temporary hack job to override the MainMenu.nib in 10.6.2 by
-- using the 10.6.1 one.
--
-- TODO: This can be removed once #2914 is solved.
--------------------------------------------------------------------------------
local mainMenuNibOverridePath
local bundleInfo = infoForBundleID(fcpID)
local version = bundleInfo and bundleInfo.CFBundleShortVersionString
if version then
    if semver(version) >= semver("10.6.2") then
        log.df("[cp.apple.finalcutpro.app] We're using 10.6.1's NIB as a workaround.")
        mainMenuNibOverridePath = config.basePath .. "/extensions/cp/apple/finalcutpro/nib/10.6.1/MainMenu.nib"
    end
end

return app.forBundleID(fcpID, mainMenuNibOverridePath)