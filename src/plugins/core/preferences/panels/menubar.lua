--- === plugins.core.preferences.panels.menubar ===
---
--- Menubar Preferences Panel

local require           = require

local image             = require "hs.image"

local config            = require "cp.config"
local i18n              = require "cp.i18n"

local imageFromPath     = image.imageFromPath

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

local plugin = {
    id              = "core.preferences.panels.menubar",
    group           = "core",
    dependencies    = {
        ["core.preferences.manager"]            = "prefsMgr",
    }
}

function plugin.init(deps)

    local panel = deps.prefsMgr.addPanel({
        priority    = 2020,
        id          = "menubar",
        label       = i18n("menubarPanelLabel"),
        image       = imageFromPath(config.basePath .. "/plugins/core/preferences/panels/images/DesktopScreenEffectsPref.icns"),
        tooltip     = i18n("menubarPanelTooltip"),
        height      = 280,
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
        :addHeading(100, i18n("appearance"))
        :addCheckbox(101,
            {
                label = i18n("displayThisMenuAsIcon"),
                onchange = function(_, params) mod.displayMenubarAsIcon(params.checked) end,
                checked = mod.displayMenubarAsIcon,
            }
        )
        :addCheckbox(102,
            {
                label = i18n("showSectionHeadingsInMenubar"),
                onchange = function(_, params) mod.showSectionHeadingsInMenubar(params.checked) end,
                checked = mod.showSectionHeadingsInMenubar,
            }
        )
        :addHeading(103, i18n("shared") .. " " .. i18n("sections"))
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
