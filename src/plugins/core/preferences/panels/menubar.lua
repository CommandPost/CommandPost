--- === plugins.core.preferences.panels.menubar ===
---
--- Menubar Preferences Panel

local require                   = require

--local log                       = require "hs.logger".new "menubar"

local image                     = require "hs.image"
local dialog                    = require "hs.dialog"

local config                    = require "cp.config"
local i18n                      = require "cp.i18n"
local tools                     = require "cp.tools"

local chooseFileOrFolder        = dialog.chooseFileOrFolder
local doesDirectoryExist        = tools.doesDirectoryExist
local imageFromPath             = image.imageFromPath
local removeFilenameFromPath    = tools.removeFilenameFromPath
local webviewAlert              = dialog.webviewAlert

local mod = {}

-- SUPPORTED_EXTENSIONS -> table
-- Constant
-- A table of supported image file extensions.
local SUPPORTED_EXTENSIONS = {"jpeg", "jpg", "tiff", "gif", "png", "tif", "bmp"}

local defaultIconPath = os.getenv("HOME") .. "/Desktop/"

--- plugins.core.preferences.panels.menubar.lastIconPath <cp.prop: string>
--- Field
--- Last Icon path.
mod.lastIconPath = config.prop("menubar.lastIconPath", defaultIconPath)

--- plugins.core.preferences.panels.menubar.lastGroup <cp.prop: string>
--- Field
--- Last group used in the Preferences Drop Down.
mod.lastGroup = config.prop("menubarPreferencesLastGroup", nil)

--- plugins.core.preferences.panels.menubar.showSectionHeadingsInMenubar <cp.prop: boolean>
--- Field
--- Show section headings in menubar.
mod.showSectionHeadingsInMenubar = config.prop("showSectionHeadingsInMenubar", true)

--- plugins.core.preferences.panels.menubar.menubarLabel <cp.prop: string>
--- Field
--- The menubar label.
mod.menubarLabel = config.prop("menubar.label", "CP")

local iconPath = config.basePath .. "/plugins/core/menu/manager/icons/"
local defaultIcon = {
    id = "icon1",
    encoded = imageFromPath(iconPath .. "icon1.png"):encodeAsURLString(),
}

--- plugins.core.preferences.panels.menubar.menubarLabel <cp.prop: table>
--- Field
--- The menubar icon.
mod.menubarIcon = config.prop("menubar.icon", defaultIcon)

--- plugins.core.preferences.panels.menubar.displayMenubarAsIcon <cp.prop: boolean>
--- Field
--- If `true`, the menubar item will be the app icon. If not, it will be the app name.
mod.displayMenubarAsIcon = config.prop("displayMenubarAsIcon", true)

local plugin = {
    id              = "core.preferences.panels.menubar",
    group           = "core",
    dependencies    = {
        ["core.preferences.manager"] = "prefsMgr",
    }
}

function plugin.init(deps)

    local manager = deps.prefsMgr

    local panel = manager.addPanel({
        priority    = 2020,
        id          = "menubar",
        label       = i18n("menubarPanelLabel"),
        image       = imageFromPath(config.basePath .. "/plugins/core/preferences/panels/images/DesktopScreenEffectsPref.icns"),
        tooltip     = i18n("menubarPanelTooltip"),
        height      = 350,
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

                .menubarIcon select {
                    margin-left: 28px;
                }

                .menubarColumn {
                    flex: 50%;
                }

                .menubarLabel input[type=text] {
                    -webkit-appearance: none;
                    -webkit-box-shadow: none;
                    -webkit-rtl-ordering: logical;
                    -webkit-user-select: text;
                    color: #959595;
                    background-color:#161616;
                    border-style: solid;
                    border-color: #0a0a0a;
                    border-width: 2px;
                    border-radius: 6px;
                    width: 200px;
                    text-align: center;
                    font-size: 13px;
                    height: 20px;
                    margin-left: 20px;
                }

                .menubarLabel input[type=text]:focus {
                    border-color: #1a3868;
                }

            </style>
            <div class="menubarRow">
                <div class="menubarColumn">
        ]], false)
        :addHeading(100, i18n("appearance"))
        :addCheckbox(100.1,
            {
                label = i18n("displayThisMenuAsIcon"),
                onchange = function(_, params) mod.displayMenubarAsIcon(params.checked) end,
                checked = mod.displayMenubarAsIcon,
            }
        )


        :addCheckbox(100.2,
            {
                label = i18n("showSectionHeadingsInMenubar"),
                onchange = function(_, params) mod.showSectionHeadingsInMenubar(params.checked) end,
                checked = mod.showSectionHeadingsInMenubar,
            }
        )
         :addContent(100.3, [[
                <br />
        ]], false)
        :addTextbox(100.4,
            {
                label       =       i18n("menubarLabel") .. ":",
                class       =       "menubarLabel",
                value       =       function()
                                        return mod.menubarLabel()
                                    end,
                onchange    =       function(_, params)
                                        mod.menubarLabel(params.value)
                                    end,
            }
        )
        :addSelect(100.5,
            {
                label       =   i18n("menubarIcon"),
                width       =   205,
                class       =   "menubarIcon",
                value       =   function()
                                    return mod.menubarIcon().id
                                end,
                options     =   function()
                                    local options = {
                                        { value = "icon1", label = i18n("option") .. " 1", selected = function() return mod.menubarIcon().id == "icon1" end  },
                                        { value = "icon2", label = i18n("option") .. " 2", selected = function() return mod.menubarIcon().id == "icon2" end },
                                        { value = "icon3", label = i18n("option") .. " 3", selected = function() return mod.menubarIcon().id == "icon3" end },
                                        { value = "icon4", label = i18n("option") .. " 4", selected = function() return mod.menubarIcon().id == "icon4" end },
                                        { value = "icon5", label = i18n("option") .. " 5", selected = function() return mod.menubarIcon().id == "icon5" end },
                                        { label = "──────────", disabled = true },
                                        { value = "custom", label = i18n("customIcon"), disabled = true, selected = function() return mod.menubarIcon().id == "custom" end },
                                        { label = "──────────", disabled = true },
                                        { value = "selectACustomIcon", label = i18n("selectACustomIcon") .. "..." },
                                    }
                                    return options
                                end,
                required    =   true,
                onchange    =   function(_, params)
                                    if params.value == "selectACustomIcon" then
                                        --------------------------------------------------------------------------------
                                        -- Make sure the last icon path actually exists:
                                        --------------------------------------------------------------------------------
                                        if not doesDirectoryExist(mod.lastIconPath()) then
                                            mod.lastIconPath(defaultIconPath)
                                        end

                                        --------------------------------------------------------------------------------
                                        -- Show choose dialog:
                                        --------------------------------------------------------------------------------
                                        local result = chooseFileOrFolder(i18n("pleaseSelectAnIcon"), mod.lastIconPath(), true, false, false, SUPPORTED_EXTENSIONS, true)
                                        if result and result["1"] then

                                            local path = result["1"]

                                            --------------------------------------------------------------------------------
                                            -- Save path for next time:
                                            --------------------------------------------------------------------------------
                                            mod.lastIconPath(removeFilenameFromPath(path))

                                            local icon = imageFromPath(path)
                                            if icon then
                                                local data = {
                                                    id = "custom",
                                                    encoded = icon:encodeAsURLString()
                                                }
                                                mod.menubarIcon(data)
                                                manager.refresh()
                                                return
                                            end

                                            --------------------------------------------------------------------------------
                                            -- Failed to read image:
                                            --------------------------------------------------------------------------------
                                            webviewAlert(manager.getWebview(), function()
                                                manager.refresh()
                                            end, i18n("fileCouldNotBeRead"), i18n("pleaseTryAgain"), i18n("ok"))
                                        else
                                            --------------------------------------------------------------------------------
                                            -- Cancel was pressed:
                                            --------------------------------------------------------------------------------
                                            manager.refresh()
                                        end
                                    else
                                        local result = {
                                            id = params.value,
                                            encoded = imageFromPath(iconPath .. params.value .. ".png"):encodeAsURLString()
                                        }
                                        mod.menubarIcon(result)
                                    end
                                end,
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

    mod.panel = panel

    return mod
end

return plugin
