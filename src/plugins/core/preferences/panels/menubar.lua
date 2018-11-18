--- === plugins.core.preferences.panels.menubar ===
---
--- Menubar Preferences Panel

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local image                                     = require("hs.image")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local commands                                  = require("cp.commands")
local config                                    = require("cp.config")
local i18n                                      = require("cp.i18n")
local tools                                     = require("cp.tools")
local ui                                        = require("cp.web.ui")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local APPEARANCE_HEADING    = 100
local SECTIONS_HEADING      = 200

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.core.preferences.panels.menubar.lastGroup <cp.prop: string>
--- Field
--- Last group used in the Preferences Drop Down.
mod.lastGroup = config.prop("menubarPreferencesLastGroup", nil)

--- plugins.core.preferences.panels.menubar.showSectionHeadingsInMenubar <cp.prop: boolean>
--- Field
--- Show section headings in menubar.
mod.showSectionHeadingsInMenubar = config.prop("showSectionHeadingsInMenubar", true)

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "core.preferences.panels.menubar",
    group           = "core",
    dependencies    = {
        ["core.preferences.manager"]            = "prefsMgr",
        ["core.menu.manager"]                   = "menuMgr",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    local panel = deps.prefsMgr.addPanel({
        priority    = 2020,
        id          = "menubar",
        label       = i18n("menubarPanelLabel"),
        image       = image.imageFromPath(tools.iconFallback("/System/Library/PreferencePanes/DesktopScreenEffectsPref.prefPane/Contents/Resources/DesktopScreenEffectsPref.icns", "/System/Library/PreferencePanes/Appearance.prefPane/Contents/Resources/GeneralPrefsIcons.icns")),
        tooltip     = i18n("menubarPanelTooltip"),
        height      = 380,
    })

    --------------------------------------------------------------------------------
    -- Setup Menubar Preferences Panel:
    --------------------------------------------------------------------------------
    panel
        :addHeading(APPEARANCE_HEADING, i18n("appearance"))
        :addCheckbox(APPEARANCE_HEADING + 1,
            {
                label = i18n("displayThisMenuAsIcon"),
                onchange = function(_, params) deps.menuMgr.displayMenubarAsIcon(params.checked) end,
                checked = deps.menuMgr.displayMenubarAsIcon,
            }
        )
        :addCheckbox(APPEARANCE_HEADING + 2,
            {
                label = i18n("showSectionHeadingsInMenubar"),
                onchange = function(_, params) mod.showSectionHeadingsInMenubar(params.checked) end,
                checked = mod.showSectionHeadingsInMenubar,
            }
        )

        :addHeading(APPEARANCE_HEADING + 3, i18n("shared") .. " " .. i18n("sections"))

    return panel
end

return plugin
