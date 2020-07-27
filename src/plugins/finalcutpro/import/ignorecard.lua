--- === plugins.finalcutpro.import.ignorecard ===
---
--- Ignore Final Cut Pro's Media Import Window.

local require       = require

local log		    = require "hs.logger".new "ignorecard"

local application   = require "hs.application"
local fs            = require "hs.fs"
local timer         = require "hs.timer"

local config        = require "cp.config"
local fcp           = require "cp.apple.finalcutpro"
local i18n          = require "cp.i18n"

local doEvery       = timer.doEvery
local volume        = fs.volume

local mod = {}

-- volumeWatcher -> hs.fs.volume watcher object
-- Variable
-- Volume Watcher
local volumeWatcher

-- mediaImportTimer -> hs.timer
-- Variable
-- Media Import Timer
local mediaImportTimer

-- mediaImportCount -> number
-- Variable
-- Media Import Counter
local mediaImportCount

-- fcpHidden -> boolean
-- Variable
-- Is Final Cut Pro Hidden?
local fcpHidden

--- plugins.finalcutpro.import.ignorecard.start() -> none
--- Function
--- Starts the Media Import Window Watcher
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.start()
    if not volumeWatcher then
        volumeWatcher = volume.new(function(event)
            if event == volume.didMount and fcp:isRunning() and not fcp:mediaImport():isShowing() then
                --------------------------------------------------------------------------------
                -- Setup a timer to check for the Media Import window:
                --------------------------------------------------------------------------------
                fcpHidden = not fcp:isShowing()
                mod._currentApplication = application.frontmostApplication()
                mediaImportTimer = doEvery(0.01, function()
                    local mediaImport = fcp:mediaImport()
                    if mediaImport:isShowing() then
                        --------------------------------------------------------------------------------
                        -- Hide the Media Import Window:
                        --------------------------------------------------------------------------------
                        mediaImport:hide()
                        if fcpHidden then fcp:hide() end
                        mod._currentApplication:activate()
                        fcpHidden = nil
                        mediaImportCount = nil
                        mod._currentApplication = nil
                        mediaImportTimer:stop()
                    end
                    if type(mediaImportCount) ~= "number" then
                        mediaImportCount = 0
                    end
                    mediaImportCount = mediaImportCount + 1
                    if mediaImportCount == 500 then
                        --------------------------------------------------------------------------------
                        -- Gave up watching for the Media Import window, so cleaning up:
                        --------------------------------------------------------------------------------
                        fcpHidden = nil
                        mediaImportCount = nil
                        mod._currentApplication = nil
                        mediaImportTimer:stop()
                    end
                end)
            end
        end):start()
    end
end

--- plugins.finalcutpro.import.ignorecard.stop() -> none
--- Function
--- Stops the Media Import Window Watcher
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.stop()
    if volumeWatcher then
        volumeWatcher:stop()
        volumeWatcher = nil
        mediaImportTimer = nil
        mediaImportCount = nil
        fcpHidden = nil
    end
end

--- plugins.finalcutpro.import.ignorecard.update() -> none
--- Function
--- Starts to stops the Ignore Card device watcher.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.update()
    if mod.enabled() then
        mod.start()
    else
        mod.stop()
    end
end

--- plugins.finalcutpro.import.ignorecard.enabled <cp.prop: boolean>
--- Variable
--- Toggles the Ignore Card Plugin
mod.enabled = config.prop("enableMediaImportWatcher", false):watch(mod.update)

local plugin = {
    id              = "finalcutpro.import.ignorecard",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.preferences.manager"] = "prefs",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Setup Menubar Preferences Panel:
    --------------------------------------------------------------------------------
    local panel = deps.prefs.panel
    if panel then
        panel
            :addCheckbox(1.1,
            {
                label = i18n("ignoreInsertedCameraCards"),
                onchange = function(_, params) mod.enabled(params.checked) end,
                checked = mod.enabled,
            })
    end

    --------------------------------------------------------------------------------
    -- Update the watcher status based on the settings:
    --------------------------------------------------------------------------------
    mod.update()

    return mod
end

return plugin
