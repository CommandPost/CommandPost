--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                        C L I P B O A R D    M E N U                        --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.menu.clipboard ===
---
--- The CLIPBOARD menu section.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config                    = require("cp.config")
local fcp                       = require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- PRIORITY -> number
-- Constant
-- The menubar position priority.
local PRIORITY = 2500

-- PREFERENCES_PRIORITY -> number
-- Constant
-- Preferences Priority
local PREFERENCES_PRIORITY = 5

-- SETTING -> number
-- Constant
-- Setting Name
local SETTING = "menubarClipboardEnabled"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------

-- sectionEnabled <cp.prop: boolean>
-- Variable
-- Section Enabled
local sectionEnabled = config.prop(SETTING, true)

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.menu.clipboard",
    group           = "finalcutpro",
    dependencies    = {
        ["core.menu.manager"]               = "manager",
        ["core.preferences.panels.menubar"] = "prefs",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(dependencies)

    --------------------------------------------------------------------------------
    -- Create the Clipboard section:
    --------------------------------------------------------------------------------
    local shortcuts = dependencies.manager.addSection(PRIORITY)

    --------------------------------------------------------------------------------
    -- Disable the section if the Clipboard option is disabled:
    --------------------------------------------------------------------------------
    shortcuts:setDisabledFn(function() return not fcp:isInstalled() or not sectionEnabled() end)

    --------------------------------------------------------------------------------
    -- Add the separator and title for the section:
    --------------------------------------------------------------------------------
    shortcuts:addSeparator(0)
        :addItem(1, function()
            return { title = string.upper(i18n("clipboard")) .. ":", disabled = true }
        end)

    --------------------------------------------------------------------------------
    -- Add to General Preferences Panel:
    --------------------------------------------------------------------------------
    local prefs = dependencies.prefs
    prefs:addCheckbox(prefs.SECTIONS_HEADING + PREFERENCES_PRIORITY,
        {
            label = i18n("show") .. " " .. i18n("clipboard"),
            onchange = function(_, params) sectionEnabled(params.checked) end,
            checked = sectionEnabled,
        }
    )

    return shortcuts
end

return plugin
