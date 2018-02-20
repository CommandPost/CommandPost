--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.ids ===
---
--- Final Cut Pro IDs.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log               = require("hs.logger").new("fcp_ids")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local application       = require("hs.application")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config            = require("cp.config")
local ids               = require("cp.ids")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------

-- currentVersion() -> string
-- Function
-- Returns the current version number of Final Cut Pro
--
-- Parameters:
--  * None
--
-- Returns:
--  * A string with Final Cut Pro's version number or `nil` if Final Cut Pro could not be detected
local function currentVersion()

    --------------------------------------------------------------------------------
    -- TODO: This should really be calling cp.apple.finalcutpro:getVersion()
    --       instead, but not sure how best to do this...
    --------------------------------------------------------------------------------

    ----------------------------------------------------------------------------------------
    -- Get running copy of Final Cut Pro:
    ----------------------------------------------------------------------------------------
    local app = application.applicationsForBundleID("com.apple.FinalCut")

    ----------------------------------------------------------------------------------------
    -- Final Cut Pro is currently running:
    ----------------------------------------------------------------------------------------
    if app and next(app) ~= nil then
        app = app[1]
        local appPath = app:path()
        if appPath then
            local info = application.infoForBundlePath(appPath)
            if info then
                return info["CFBundleShortVersionString"]
            else
                log.df("VERSION CHECK: Could not determine Final Cut Pro's version.")
            end
        else
            log.df("VERSION CHECK: Could not determine Final Cut Pro's path.")
        end
    end

    ----------------------------------------------------------------------------------------
    -- No version of Final Cut Pro currently running:
    ----------------------------------------------------------------------------------------
    app = application.infoForBundleID("com.apple.FinalCut")
    if app then
        return app["CFBundleShortVersionString"]
    else
        log.df("VERSION CHECK: Could not determine Final Cut Pro's info from Bundle ID.")
    end

    ----------------------------------------------------------------------------------------
    -- Final Cut Pro could not be detected:
    ----------------------------------------------------------------------------------------
    return nil

end

return ids.new(config.scriptPath .. "/cp/apple/finalcutpro/ids/v/", currentVersion)
