--- === plugins.finalcutpro.menu.timeline ===
---
--- The TIMELINE menu section.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config					= require("cp.config")
local fcp						  = require("cp.apple.finalcutpro")
local i18n            = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- PRIORITY -> number
-- Constant
-- The menubar position priority.
local PRIORITY = 2000

-- PREFERENCES_PRIORITY -> number
-- Constant
-- Preferences Priority
local PREFERENCES_PRIORITY = 3

-- SETTING -> number
-- Constant
-- Setting Name
local SETTING = "menubarTimelineEnabled"

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
    id				= "finalcutpro.menu.timeline",
    group			= "finalcutpro",
    dependencies	= {
        ["core.menu.manager"] 				= "manager",
        ["core.preferences.panels.menubar"]	= "prefs",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(dependencies)

    --------------------------------------------------------------------------------
    -- Create the Timeline section:
    --------------------------------------------------------------------------------
    local shortcuts = dependencies.manager.addSection(PRIORITY)

    --------------------------------------------------------------------------------
    -- Disable the section if the Timeline option is disabled:
    --------------------------------------------------------------------------------
    shortcuts:setDisabledFn(function() return not fcp:isInstalled() or not sectionEnabled() end)

    --------------------------------------------------------------------------------
    -- Add the separator and title for the section:
    --------------------------------------------------------------------------------
    shortcuts:addSeparator(0)
        :addItem(1, function()
            return { title = string.upper(i18n("timeline")) .. ":", disabled = true }
        end)

    --------------------------------------------------------------------------------
    -- Add to General Preferences Panel:
    --------------------------------------------------------------------------------
    local prefs = dependencies.prefs
    prefs:addCheckbox(prefs.SECTIONS_HEADING + PREFERENCES_PRIORITY,
        {
            label = i18n("show") .. " " .. i18n("timeline"),
            onchange = function(_, params) sectionEnabled(params.checked) end,
            checked = sectionEnabled,
        }
    )

    return shortcuts
end

return plugin
