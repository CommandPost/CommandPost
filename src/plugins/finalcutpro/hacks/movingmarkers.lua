--- === plugins.finalcutpro.hacks.movingmarkers ===
---
--- Moving Markers Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local fs                        = require("hs.fs")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local dialog                    = require("cp.dialog")
local fcp                       = require("cp.apple.finalcutpro")
local html                      = require("cp.web.html")
local i18n                      = require("cp.i18n")
local plist                     = require("cp.plist")
local prop                      = require("cp.prop")
local tools                     = require("cp.tools")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- DEFAULT_VALUE
-- Constant
-- Whether or not the plugin is enabled by default.
local DEFAULT_VALUE = false

-- PLIST_BUDDY
-- Constant
-- Path to Plist Buddy
local PLIST_BUDDY = "/usr/libexec/PlistBuddy"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

-- getValue(source, property, ...) -> none
-- Function
-- x
--
-- Parameters:
--  * source - The source of the value
--  * property - The value you want to check for
--  * ... - Any subsequent values you want to check for
--
-- Returns:
--  * The source of the last property if not `nil`
local function getValue(source, property, ...)
    if source == nil or property == nil then
        return source
    else
        local value = source[property]
        return value ~= nil and getValue(value, ...) or nil
    end
end

-- saveMovingMarkers(enabled) -> boolean
-- Function
-- Save moving markers
--
-- Parameters:
--  * enabled - Whether or not moving markers are enabled.
--
-- Returns:
--  * `true` if successful otherwise `false`
local function saveMovingMarkers(enabled)
    local cmd = string.format([[%s -c \"Set :TLKMarkerHandler:Configuration:'Allow Moving Markers' %s\" '%s']], PLIST_BUDDY, enabled, fcp:getPath() .. fcp.EVENT_DESCRIPTION_PATH)
    local result = tools.executeWithAdministratorPrivileges(cmd)
    if type(result) == "string" then
        dialog.displayErrorMessage(result)
        return false
    end
    return true
end

--- plugins.finalcutpro.hacks.movingmarkers.enabled <cp.prop: boolean>
--- Variable
--- Gets whether or not moving markers are enabled.
mod.enabled = prop.new(
    function()
        if fcp:isInstalled() then
            local eventDescriptionsPath = fcp:getPath() .. fcp.EVENT_DESCRIPTION_PATH
            local modified = fs.attributes(eventDescriptionsPath, "modification")
            if modified ~= mod._modified then
                local eventDescriptions = plist.binaryFileToTable(eventDescriptionsPath)
                local allow = getValue(eventDescriptions, "TLKMarkerHandler", "Configuration", "Allow Moving Markers") or DEFAULT_VALUE

                mod._enabled = allow
                mod._modified = modified
            end

            return mod._enabled
        end
        return false
    end,
    function(allowMovingMarkers)
        if not fcp:isInstalled() then
            return
        end

        --------------------------------------------------------------------------------
        -- If Final Cut Pro is running...
        --------------------------------------------------------------------------------
        local running = fcp:isRunning()
        if running and not dialog.displayYesNoQuestion(i18n("togglingMovingMarkersRestart"), i18n("doYouWantToContinue")) then
            return
        end

        --------------------------------------------------------------------------------
        -- Update plist:
        --------------------------------------------------------------------------------
        saveMovingMarkers(allowMovingMarkers)

        --------------------------------------------------------------------------------
        -- Restart Final Cut Pro:
        --------------------------------------------------------------------------------
        if running and not fcp:restart() then
            --------------------------------------------------------------------------------
            -- Failed to restart Final Cut Pro:
            --------------------------------------------------------------------------------
            dialog.displayErrorMessage(i18n("failedToRestart"))
        end
    end
)

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.hacks.movingmarkers",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]                            = "fcpxCmds",
        ["finalcutpro.preferences.app"]                     = "prefs",
        ["core.preferences.manager"]                        = "preferencesManager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Cache status on load:
    --------------------------------------------------------------------------------
    mod.enabled:update()

    --------------------------------------------------------------------------------
    -- Setup Preferences Panel:
    --------------------------------------------------------------------------------
    if deps.prefs.panel then
        deps.prefs.panel
            :addCheckbox(2202,
                {
                    label = i18n("enableMovingMarkers"),
                    onchange = function(_, params)
                        mod.enabled(params.checked)
                        deps.preferencesManager.refresh()
                    end,
                    checked = mod.enabled,
                }
            )
            :addParagraph(2202.1, html.br())
    end

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    deps.fcpxCmds
        :add("cpToggleMovingMarkers")
        :groupedBy("hacks")
        :activatedBy():ctrl():option():cmd("y")
        :whenActivated(function() mod.enabled:toggle() end)

    return mod

end

return plugin
