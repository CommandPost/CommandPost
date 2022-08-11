--- === plugins.core.preferences.general ===
---
--- General Preferences Panel.

local require = require

local hs        = _G.hs

local config    = require "cp.config"
local i18n      = require "cp.i18n"
local prop      = require "cp.prop"
local tools     = require "cp.tools"

local spairs    = tools.spairs

local mod = {}

--- plugins.core.preferences.general.autoLaunch <cp.prop: boolean>
--- Field
--- Controls if CommandPost will automatically launch when the user logs in.
mod.autoLaunch = prop.new(
    function() return hs.autoLaunch() end,
    function(value) hs.autoLaunch(value) end
)

--- plugins.core.preferences.general.autoLaunch <cp.prop: boolean>
--- Field
--- Controls if CommandPost will automatically upload crash data to the developer.
mod.uploadCrashData = prop.new(
    function() return hs.uploadCrashData() end,
    function(value) hs.uploadCrashData(value) end
)

--- plugins.core.preferences.general.dockIcon <cp.prop: boolean>
--- Field
--- Controls whether or not CommandPost should show a dock icon.
mod.dockIcon = config.prop("dockIcon", true):watch(function(value)
    hs.dockIcon(value)
end)

--- plugins.core.preferences.general.dragAndDropFileAction <cp.prop: string>
--- Field
--- Which Drag & Drop File Action is enabled?
mod.dragAndDropFileAction = config.prop("dockIcon.dragAndDropFileAction", "")

--- plugins.core.preferences.general.dragAndDropTextAction <cp.prop: string>
--- Field
--- Which Drag & Drop Text Action is enabled?
mod.dragAndDropTextAction = config.prop("dockIcon.dragAndDropTextAction", "")

--- plugins.core.preferences.general.openDebugConsoleOnDockClick <cp.prop: boolean>
--- Variable
--- Open Error Log on Dock Icon Click.
mod.openDebugConsoleOnDockClick = config.prop("openDebugConsoleOnDockClick", true)

--- plugins.core.preferences.general.dragAndDropTextActions -> table
--- Variable
--- A table of registered Drag & Drop Text Actions.
mod.dragAndDropTextActions = {}

--- plugins.core.preferences.general.registerDragAndDropTextAction(id, label, fn) -> none
--- Function
--- Registers a new Drag & Drop Text Action.
---
--- Parameters:
---  * id - A unique identifier as a string
---  * label - The label that should be display in the user interface
---  * fn - A callback function
---
--- Returns:
---  * None
function mod.registerDragAndDropTextAction(id, label, fn)
    mod.dragAndDropTextActions[id] = {
        label = label,
        fn = fn
    }
end

--- plugins.core.preferences.general.dragAndDropFileActions -> table
--- Variable
--- A table of registered Drag & Drop File Actions.
mod.dragAndDropFileActions = {}

--- plugins.core.preferences.general.registerDragAndDropFileAction(id, label, fn) -> none
--- Function
--- Registers a new Drag & Drop File Action.
---
--- Parameters:
---  * id - A unique identifier as a string
---  * label - The label that should be display in the user interface
---  * fn - A callback function
---
--- Returns:
---  * None
function mod.registerDragAndDropFileAction(id, label, fn)
    mod.dragAndDropFileActions[id] = {
        label = label,
        fn = fn
    }
end

local plugin = {
    id              = "core.preferences.general",
    group           = "core",
    dependencies    = {
        ["core.preferences.panels.general"] = "general",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Disable Dock Icon by Default:
    --------------------------------------------------------------------------------
    hs.openConsoleOnDockClick(false)

    --------------------------------------------------------------------------------
    -- Create Dock Icon Click Callback:
    --------------------------------------------------------------------------------
    config.dockIconClickCallback:new("cp", function()
        if mod.openDebugConsoleOnDockClick() then hs.openConsole() end
    end)

    --------------------------------------------------------------------------------
    -- Cache Values:
    --------------------------------------------------------------------------------
    mod._autoLaunch         = hs.autoLaunch()
    mod._uploadCrashData    = hs.uploadCrashData()

    --------------------------------------------------------------------------------
    -- Setup General Preferences Panel:
    --------------------------------------------------------------------------------
    deps.general
        :addContent(0.1, [[
            <style>
                .generalPrefsRow {
                    display: flex;
                }

                .generalPrefsColumn {
                    flex: 50%;
                }
            </style>
            <div class="generalPrefsRow">
                <div class="generalPrefsColumn">
        ]], false)

        --------------------------------------------------------------------------------
        -- General Section:
        --------------------------------------------------------------------------------
        :addHeading(1, i18n("general"))
        :addCheckbox(3,
            {
                label       = i18n("launchAtStartup"),
                checked     = mod.autoLaunch,
                onchange    = function(_, params) mod.autoLaunch(params.checked) end,
            }
        )

        --------------------------------------------------------------------------------
        -- Privacy Section:
        --------------------------------------------------------------------------------
        :addHeading(10, i18n("privacy"))
        :addCheckbox(11,
            {
                label        = i18n("sendCrashData"),
                checked  = mod.uploadCrashData,
                onchange = function(_, params) mod.uploadCrashData(params.checked) end,
            }
        )
        :addButton(12,
            {
                label   = i18n("openPrivacyPolicy"),
                width       = 200,
                onclick = function() hs.execute("open '" .. config.privacyPolicyURL .. "'") end,
            }
        )

        :addContent(30, [[
                </div>
                <div class="generalPrefsColumn">
        ]], false)

        --------------------------------------------------------------------------------
        -- Dock Icon Section:
        --------------------------------------------------------------------------------
        :addHeading(31, i18n("dockIcon"))
        :addCheckbox(32,
            {
                label       = i18n("enableDockIcon"),
                checked     = mod.dockIcon,
                onchange    = function() mod.dockIcon:toggle() end,
            }
        )
        :addCheckbox(33,
            {
                label = i18n("openDebugConsoleOnDockClick"),
                checked = mod.openDebugConsoleOnDockClick,
                onchange = function() mod.openDebugConsoleOnDockClick:toggle() end
            }
        )

        :addContent(33.1, [[
            <br />
            <p class="uiItem">]] .. i18n("dragAndDropTextAction") .. [[:</p>
        ]], false)
        :addSelect(33.2,
            {
                width       =   300,
                value       =   mod.dragAndDropTextAction,
                options     =   function()
                                    local options = {}

                                    table.insert(options, {
                                        value = "",
                                        label = i18n("doNothing")
                                    })

                                    for id, v in spairs(mod.dragAndDropTextActions, function(t,a,b) return t[b].label < t[a].label end) do
                                        table.insert(options, {
                                            value = id,
                                            label = v.label
                                        })
                                    end

                                    return options
                                end,
                required    =   true,
                onchange    =   function(_, params)
                                    mod.dragAndDropTextAction(params.value)
                                end,
            }
        )
        :addContent(33.3, [[
            <br />
            <p class="uiItem">]] .. i18n("dragAndDropFileAction") .. [[:</p>
        ]], false)
        :addSelect(33.4,
            {
                width       =   300,
                value       =   mod.dragAndDropFileAction,
                options     =   function()
                                    local options = {}

                                    table.insert(options, {
                                        value = "",
                                        label = i18n("doNothing")
                                    })

                                    for id, v in spairs(mod.dragAndDropFileActions, function(t,a,b) return t[b].label < t[a].label end) do
                                        table.insert(options, {
                                            value = id,
                                            label = v.label
                                        })
                                    end

                                    return options
                                end,
                required    =   true,
                onchange    =   function(_, params)
                                    mod.dragAndDropFileAction(params.value)
                                end,
            }
        )

        :addContent(100, [[
                </div>
            </div>
        ]], false)


    --------------------------------------------------------------------------------
    -- Text Dropped on to Dock Icon Callback:
    --------------------------------------------------------------------------------
    config.textDroppedToDockIconCallback:new("dragAndDropTextAction", function(value)
        local dragAndDropTextAction = mod.dragAndDropTextAction()
        if dragAndDropTextAction ~= "" then
            local action = mod.dragAndDropTextActions[dragAndDropTextAction]
            if action and action.fn then
                action.fn(value)
            end
        end
    end)

    --------------------------------------------------------------------------------
    -- File Dropped on to Dock Icon Callback:
    --------------------------------------------------------------------------------
    config.fileDroppedToDockIconCallback:new("dragAndDropFileAction", function(value)
        local dragAndDropFileAction = mod.dragAndDropFileAction()
        if dragAndDropFileAction ~= "" then
            local action = mod.dragAndDropFileActions[dragAndDropFileAction]
            if action and action.fn then
                action.fn(value)
            end
        end
    end)

    return mod

end

function plugin.postInit()
    mod.dockIcon:update()
end

return plugin
