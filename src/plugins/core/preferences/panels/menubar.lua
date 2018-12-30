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
local config                                    = require("cp.config")
local i18n                                      = require("cp.i18n")
local tools                                     = require("cp.tools")

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

--- plugins.core.preferences.panels.menubar.displayMenubarAsIcon <cp.prop: boolean>
--- Field
--- If `true`, the menubar item will be the app icon. If not, it will be the app name.
mod.displayMenubarAsIcon = config.prop("displayMenubarAsIcon", true)

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
        height      = 250,
    })

    --------------------------------------------------------------------------------
    -- Setup Menubar Preferences Panel:
    --------------------------------------------------------------------------------
    panel
        :addContent(0.1, [[
            <style>
                .menubarRow {
                    display: flex;
                }

                .menubarColumn {
                    flex: 50%;
                }
            </style>
            <div class="menubarRow">
                <div class="menubarColumn">
        ]], false)
        :addHeading(APPEARANCE_HEADING, i18n("appearance"))
        :addCheckbox(APPEARANCE_HEADING + 1,
            {
                label = i18n("displayThisMenuAsIcon"),
                onchange = function(_, params) mod.displayMenubarAsIcon(params.checked) end,
                checked = mod.displayMenubarAsIcon,
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
        :addContent(399, [[
                </div>
                <div class="menubarColumn">
        ]], false)
        :addContent(9000, [[
                </div>
            </div>
        ]], false)


    return panel
end

return plugin
