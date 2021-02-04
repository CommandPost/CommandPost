--- === plugins.core.touchbar.prefs ===
---
--- Touch Bar Preferences Panel

local require           = require

local log               = require "hs.logger".new "prefsTouchBar"
local inspect           = require "hs.inspect"

local canvas            = require "hs.canvas"
local dialog            = require "hs.dialog"
local image             = require "hs.image"

local commands          = require "cp.commands"
local config            = require "cp.config"
local fcp               = require "cp.apple.finalcutpro"
local tools             = require "cp.tools"
local html              = require "cp.web.html"
local i18n              = require "cp.i18n"

local moses             = require "moses"

local imageFromPath     = image.imageFromPath

local mod = {}

--- plugins.core.touchbar.prefs.supportedExtensions -> string
--- Variable
--- Table of supported extensions for Touch Bar Icons.
mod.supportedExtensions = {"jpeg", "jpg", "tiff", "gif", "png", "tif", "bmp"}

--- plugins.core.touchbar.prefs.defaultIconPath -> string
--- Variable
--- Default Path where built-in icons are stored
mod.defaultIconPath = config.assetsPath .. "/icons"

--- plugins.core.touchbar.prefs.enabled <cp.prop: boolean>
--- Field
--- Enable or disable Touch Bar Support.
mod.enabled = config.prop("enableTouchBar", false)

--- plugins.core.touchbar.prefs.lastGroup <cp.prop: string>
--- Field
--- Last group used in the Preferences Drop Down.
mod.lastGroup = config.prop("touchBarPreferencesLastGroup", nil)

--- plugins.core.touchbar.prefs.scrollBarPosition <cp.prop: string>
--- Field
--- Last group used in the Preferences Drop Down.
mod.scrollBarPosition = config.prop("touchBarPreferencesScrollBarPosition", {})

--- plugins.core.touchbar.prefs.maxItems -> number
--- Variable
--- The maximum number of Touch Bar items per group.
mod.maxItems = 8

-- renderPanel(context) -> none
-- Function
-- Generates the Preference Panel HTML Content.
--
-- Parameters:
--  * context - Table of data that you want to share with the renderer
--
-- Returns:
--  * HTML content as string
local function renderPanel(context)
    if not mod._renderPanel then
        local errorMessage
        mod._renderPanel, errorMessage = mod._env:compileTemplate("html/panel.html")
        if errorMessage then
            log.ef(errorMessage)
            return nil
        end
    end
    return mod._renderPanel(context)
end

-- generateContent() -> string
-- Function
-- Generates the Preference Panel HTML Content.
--
-- Parameters:
--  * None
--
-- Returns:
--  * HTML content as string
local function generateContent()
    --------------------------------------------------------------------------------
    -- The Group Select:
    --------------------------------------------------------------------------------
    local groups = {}
    local groupLabels = {}
    local defaultGroup
    local numberOfSubGroups = mod._tb.numberOfSubGroups
    if mod.lastGroup() then defaultGroup = mod.lastGroup() end -- Get last group from preferences.
    for _,id in ipairs(commands.groupIds()) do
        table.insert(groupLabels, {
            value = id,
            label = i18n("shortcut_group_" .. id, {default = id}),
        })
        for subGroupID=1, numberOfSubGroups do
            defaultGroup = defaultGroup or id .. subGroupID
            groups[#groups + 1] = id .. subGroupID
        end
    end
    table.sort(groupLabels, function(a, b) return a.label < b.label end)

    local context = {
        _                       = moses,
        numberOfSubGroups       = numberOfSubGroups,
        groupLabels             = groupLabels,
        groups                  = groups,
        defaultGroup            = defaultGroup,
        scrollBarPosition       = mod.scrollBarPosition(),
        groupEditor             = mod.getGroupEditor,
        i18n                    = i18n,
        maxItems                = mod._tb.maxItems,
        tb                      = mod._tb,
    }

    return renderPanel(context)
end

-- touchBarPanelCallback() -> none
-- Function
-- JavaScript Callback for the Preferences Panel
--
-- Parameters:
--  * id - ID as string
--  * params - Table of paramaters
--
-- Returns:
--  * None
local function touchBarPanelCallback(id, params)
    local injectScript = mod._manager.injectScript
    if params and params["type"] then
        if params["type"] == "badExtension" then
            --------------------------------------------------------------------------------
            -- Bad Icon File Extension:
            --------------------------------------------------------------------------------
            dialog.webviewAlert(mod._manager.getWebview(), function() end, i18n("badTouchBarIcon"), i18n("pleaseTryAgain"), i18n("ok"))
        elseif params["type"] == "updateIcon" then
            --------------------------------------------------------------------------------
            -- Update Icon:
            --------------------------------------------------------------------------------
            mod._tb.updateIcon(params["buttonID"], params["groupID"], params["icon"])
        elseif params["type"] == "updateAction" then

            --------------------------------------------------------------------------------
            -- Setup Activators:
            --------------------------------------------------------------------------------
            if not mod.activator then
                mod.activator = {}
                local handlerIds = mod._actionmanager.handlerIds()
                for _,groupID in ipairs(commands.groupIds()) do

                    --------------------------------------------------------------------------------
                    -- Create new Activator:
                    --------------------------------------------------------------------------------
                    mod.activator[groupID] = mod._actionmanager.getActivator("touchbarPreferences" .. groupID)

                    --------------------------------------------------------------------------------
                    -- Restrict Allowed Handlers for Activator to current group (and global):
                    --------------------------------------------------------------------------------
                    local allowedHandlers = {}
                    for _,v in pairs(handlerIds) do
                        local handlerTable = tools.split(v, "_")
                        if handlerTable[1] == groupID or handlerTable[1] == "global" and v ~= "global_menuactions" then
                            table.insert(allowedHandlers, v)
                        end
                    end
                    mod.activator[groupID]:allowHandlers(table.unpack(allowedHandlers))

                    --------------------------------------------------------------------------------
                    -- Allow specific toolbar icons in the Console:
                    --------------------------------------------------------------------------------
                    if groupID == "fcpx" then
                        local iconPath = config.basePath .. "/plugins/finalcutpro/console/images/"
                        local toolbarIcons = {
                            fcpx_widgets            = { path = iconPath .. "touchbar.png",      priority = 1},
                            global_touchbarbanks    = { path = iconPath .. "bank.png",          priority = 2},
                            fcpx_videoEffect        = { path = iconPath .. "videoEffect.png",   priority = 3},
                            fcpx_audioEffect        = { path = iconPath .. "audioEffect.png",   priority = 4},
                            fcpx_generator          = { path = iconPath .. "generator.png",     priority = 5},
                            fcpx_title              = { path = iconPath .. "title.png",         priority = 6},
                            fcpx_transition         = { path = iconPath .. "transition.png",    priority = 7},
                            fcpx_fonts              = { path = iconPath .. "font.png",          priority = 8},
                            fcpx_shortcuts          = { path = iconPath .. "shortcut.png",      priority = 9},
                            fcpx_menu               = { path = iconPath .. "menu.png",          priority = 10},
                        }
                        mod.activator[groupID]:toolbarIcons(toolbarIcons)
                    end
                end
            end

            --------------------------------------------------------------------------------
            -- Setup Activator Callback:
            --------------------------------------------------------------------------------
            local groupID = params["groupID"]
            local activatorID = groupID:sub(1, -2)

            mod.activator[activatorID]:onActivate(function(handler, action, text)
                --------------------------------------------------------------------------------
                -- Process Stylised Text:
                --------------------------------------------------------------------------------
                if text and type(text) == "userdata" then
                    text = text:convert("text")
                end

                local actionTitle = text
                local handlerID = handler:id()

                --------------------------------------------------------------------------------
                -- Check for duplicates:
                --------------------------------------------------------------------------------
                if not mod._tb.updateAction(params["buttonID"], params["groupID"], actionTitle, handlerID, action) then
                    dialog.webviewAlert(mod._manager.getWebview(), function() end, i18n("touchBarDuplicateWidget"), i18n("touchBarDuplicateWidgetInfo"), i18n("ok"))
                end
                mod._tb.updateLabel(params["buttonID"], params["groupID"], actionTitle)

                injectScript([[setTouchBarLabel("]] .. params["groupID"] .. [[", "]] .. params["buttonID"] .. [[", "]] .. actionTitle .. [[")]])
                injectScript([[setTouchBarActionTitle("]] .. params["groupID"] .. [[", "]] .. params["buttonID"] .. [[", "]] .. actionTitle .. [[")]])
            end)

            --------------------------------------------------------------------------------
            -- Show Activator:
            --------------------------------------------------------------------------------
            mod.activator[activatorID]:show()

        elseif params["type"] == "clearAction" then
            mod._tb.updateAction(params["buttonID"], params["groupID"], nil, nil, nil)
            injectScript([[setTouchBarActionTitle("]] .. params["groupID"] .. [[", "]] .. params["buttonID"] .. [[", "]] .. i18n("none") .. [[")]])
        elseif params["type"] == "updateLabel" then
            --------------------------------------------------------------------------------
            -- Update Label:
            --------------------------------------------------------------------------------
            mod._tb.updateLabel(params["buttonID"], params["groupID"], params["label"])
        elseif params["type"] == "updateBankLabel" then
            --------------------------------------------------------------------------------
            -- Update Bank Label:
            --------------------------------------------------------------------------------
            mod._tb.updateBankLabel(params["groupID"], params["label"])
        elseif params["type"] == "iconClicked" then
            --------------------------------------------------------------------------------
            -- Icon Clicked:
            --------------------------------------------------------------------------------
            local result = dialog.chooseFileOrFolder(i18n("pleaseSelectAnIcon"), mod.defaultIconPath, true, false, false, mod.supportedExtensions, true)
            local failed = false
            if result and result["1"] then
                local path = result["1"]
                local icon = image.imageFromPath(path)
                if icon then
                    if string.sub(path, 1, string.len(mod.defaultIconPath)) == mod.defaultIconPath then
                        --------------------------------------------------------------------------------
                        -- One of our pre-supplied images:
                        --------------------------------------------------------------------------------
                        local originalImage = image.imageFromPath(path):template(false)
                        if originalImage then

                            local a = canvas.new{x = 0, y = 0, w = 50, h = 50 }
                            a[1] = {
                              type="image",
                              image = originalImage,
                              frame = { x = "10%", y = "10%", h = "80%", w = "80%" },
                            }
                            a[2] = {
                              type = "rectangle",
                              action = "fill",
                              fillColor = { white = 1 },
                              compositeRule = "sourceAtop",
                            }
                            local newImage = a:imageFromCanvas()

                            a:delete()
                            a = nil -- luacheck: ignore

                            local encodedIcon = newImage:encodeAsURLString()

                            mod._tb.updateIcon(params["buttonID"], params["groupID"], encodedIcon)
                            injectScript([[setTouchBarIcon("]] .. params["groupID"] .. [[", "]] .. params["buttonID"] .. [[", "]] .. encodedIcon .. [[")]])
                        else
                            failed = true
                        end
                    else
                        --------------------------------------------------------------------------------
                        -- An image from outside the pre-supplied image path:
                        --------------------------------------------------------------------------------
                        local a = canvas.new{x = 0, y = 0, w = 50, h = 50 }
                        a[1] = {
                          type="image",
                          image = icon,
                          frame = { x = "10%", y = "10%", h = "80%", w = "80%" },
                        }
                        local newImage = a:imageFromCanvas()

                        local encodedIcon = newImage:encodeAsURLString()
                        if encodedIcon then
                            mod._tb.updateIcon(params["buttonID"], params["groupID"], encodedIcon)
                            injectScript([[setTouchBarIcon("]] .. params["groupID"] .. [[", "]] .. params["buttonID"] .. [[", "]] .. encodedIcon .. [[")]])
                        else
                            failed = true
                        end
                    end
                else
                    failed = true
                end
                if failed then
                    dialog.webviewAlert(mod._manager.getWebview(), function() end, i18n("fileCouldNotBeRead"), i18n("pleaseTryAgain"), i18n("ok"))
                end
            else
                --------------------------------------------------------------------------------
                -- Clear Icon:
                --------------------------------------------------------------------------------
                mod._tb.updateIcon(params["buttonID"], params["groupID"], nil)
                injectScript([[clearTouchBarIcon("]] .. params["groupID"] .. [[", "]] .. params["buttonID"] .. [[") ]])
            end
        elseif params["type"] == "updateGroup" then
            --------------------------------------------------------------------------------
            -- Update Group:
            --------------------------------------------------------------------------------
            mod._tb.forceGroupChange(params["groupID"], mod._tb.enabled())
            mod._tb.update()
            mod.lastGroup(params["groupID"])
            mod._manager.refresh()
        elseif params["type"] == "upButtonPressed" or params["type"] == "downButtonPressed" then
            --------------------------------------------------------------------------------
            -- Up & Down Buttons:
            --------------------------------------------------------------------------------
            local direction
            if params["type"] == "upButtonPressed" then
                direction = "up"
            else
                direction = "down"
            end
            mod._tb.updateOrder(direction, params["buttonID"], params["groupID"])
            local shiftButton
            if params["type"] == "upButtonPressed" then
                shiftButton = tostring(tonumber(params["buttonID"]) - 1)
            else
                shiftButton = tostring(tonumber(params["buttonID"]) + 1)
            end
            injectScript([[shiftTouchBarButtons(']] .. params["groupID"] .. [[', ']] .. params["buttonID"] .. [[', ']] .. shiftButton .. [[')]])
        elseif params["type"] == "scrollBarPosition" then
            local value = params["value"]
            local groupID = params["groupID"]
            if value and groupID then
                local scrollBarPosition = mod.scrollBarPosition()
                scrollBarPosition[groupID] = value
                mod.scrollBarPosition(scrollBarPosition)
            end
        else
            --------------------------------------------------------------------------------
            -- Unknown Callback:
            --------------------------------------------------------------------------------
            log.df("Unknown Callback in Touch Bar Preferences Panel:")
            log.df("id: %s", inspect(id))
            log.df("params: %s", inspect(params))
        end
    end
end

--- plugins.core.touchbar.prefs.setGroupEditor(groupId, editorFn) -> none
--- Function
--- Sets the Group Editor
---
--- Parameters:
---  * groupId - Group ID
---  * editorFn - Editor Function
---
--- Returns:
---  * None
function mod.setGroupEditor(groupId, editorFn)
    if not mod._groupEditors then
        mod._groupEditors = {}
    end
    mod._groupEditors[groupId] = editorFn
end

--- plugins.core.touchbar.prefs.getGroupEditor(groupId) -> none
--- Function
--- Gets the Group Editor
---
--- Parameters:
---  * groupId - Group ID
---
--- Returns:
---  * Group Editor
function mod.getGroupEditor(groupId)
    return mod._groupEditors and mod._groupEditors[groupId]
end

--------------------------------------------------------------------------------
--
-- VIRTUAL TOUCH BAR:
--
--------------------------------------------------------------------------------

mod.virtual = {}

--- plugins.finalcutpro.touchbar.virtual.enabled <cp.prop: boolean>
--- Field
--- Is `true` if the plugin is enabled.
mod.virtual.enabled = config.prop("displayVirtualTouchBar", false):watch(function(enabled)
    --------------------------------------------------------------------------------
    -- Check for compatibility:
    --------------------------------------------------------------------------------
    if enabled and not mod._tb.supported() then
        dialog.displayMessage(i18n("touchBarError"))
        mod.enabled(false)
    end
    if mod._virtual then
        if enabled then
            mod._virtual.start()
        else
            mod._virtual.stop()
        end
    end
end)

--- plugins.finalcutpro.touchbar.virtual.VISIBILITY_ALWAYS -> string
--- Constant
--- Virtual Touch Bar is Always Visible
mod.virtual.VISIBILITY_ALWAYS       = "Always"

--- plugins.finalcutpro.touchbar.virtual.VISIBILITY_FCP -> string
--- Constant
--- Virtual Touch Bar is only visible when Final Cut Pro is active.
mod.virtual.VISIBILITY_FCP          = "Final Cut Pro"

--- plugins.finalcutpro.touchbar.virtual.VISIBILITY_DEFAULT -> string
--- Constant
--- The default visibility.
mod.virtual.VISIBILITY_DEFAULT      = mod.virtual.VISIBILITY_FCP

--- plugins.finalcutpro.touchbar.virtual.LOCATION_TIMELINE -> string
--- Constant
--- Virtual Touch Bar is displayed in the top centre of the Final Cut Pro timeline
mod.virtual.LOCATION_TIMELINE       = "TimelineTopCentre"

-- TODO: This Final Cut Pro stuff shouldn't really be in a Core plugin.

--- plugins.finalcutpro.touchbar.virtual.visibility <cp.prop: string>
--- Field
--- When should the Virtual Touch Bar be visible?
mod.virtual.visibility = config.prop("virtualTouchBarVisibility", mod.virtual.VISIBILITY_DEFAULT):watch(function(status)
    if status == mod.virtual.VISIBILITY_ALWAYS then
        mod._virtual.show()
    elseif status == mod.virtual.VISIBILITY_FCP then
        if fcp.isFrontmost() then
            mod._virtual.show()
        else
            mod._virtual.hide()
        end
    end
end)

-- visibilityOptions() -> none
-- Function
-- Generates a list of visibilities for the Preferences dropdown
--
-- Parameters:
--  * None
--
-- Returns:
--  * A table of visibilities
local function visibilityOptions()
    local visibilityOptionsTable = {}
    visibilityOptionsTable[#visibilityOptionsTable + 1] = {
        label = i18n("always"),
        value = mod.virtual.VISIBILITY_ALWAYS,
    }
    visibilityOptionsTable[#visibilityOptionsTable + 1] = {
        label = i18n("finalCutPro"),
        value = mod.virtual.VISIBILITY_FCP,
    }
    return visibilityOptionsTable
end

-- locationOptions() -> none
-- Function
-- Generates a list of location options for the Preferences dropdown
--
-- Parameters:
--  * None
--
-- Returns:
--  * A table of locations
local function locationOptions()
    local options = {}
    options[#options + 1] = {
        label = i18n("topCentreOfTimeline"),
        value = mod.virtual.LOCATION_TIMELINE,
    }
    options[#options + 1] = {
        label = i18n("mouseLocation"),
        value = mod._virtual.LOCATION_MOUSE,
    }
    options[#options + 1] = {
        label = i18n("draggable"),
        value = mod._virtual.LOCATION_DRAGGABLE,
    }
    return options
end

-- resetAll() -> none
-- Function
-- Prompts to reset all Touch Bar Preferences to their defaults.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function resetAll()
    dialog.webviewAlert(mod._manager.getWebview(), function(result)
        if result == i18n("yes") then
            mod._tb.clear()
            mod._manager.refresh()
        end
    end, i18n("touchBarResetConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
end

-- resetGroup() -> none
-- Function
-- Prompts to reset shortcuts to default for the selected group (including all sub-groups).
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function resetGroup()
    dialog.webviewAlert(mod._manager.getWebview(), function(result)
        if result == i18n("yes") then
            local items = mod._tb._items()
            local currentGroup = string.sub(mod.lastGroup(), 1, -2)
            for groupAndSubgroupID in pairs(items) do
                if string.sub(groupAndSubgroupID, 1, -2) == currentGroup then
                    items[groupAndSubgroupID] = nil
                end
            end
            mod._tb._items(items)
            mod._manager.refresh()
        end
    end, i18n("touchBarResetGroupConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
end

-- resetSubGroup() -> none
-- Function
-- Prompts to reset shortcuts to default for the selected group (including all sub-groups).
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function resetSubGroup()
    dialog.webviewAlert(mod._manager.getWebview(), function(result)
        if result == i18n("yes") then
            local items = mod._tb._items()
            local currentGroup = mod.lastGroup()
            items[currentGroup] = nil
            mod._tb._items(items)
            mod._manager.refresh()
        end
    end, i18n("touchBarResetSubGroupConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
end

--- plugins.core.touchbar.prefs.init(deps, env) -> module
--- Function
--- Initialise the Module.
---
--- Parameters:
---  * deps - Dependancies Table
---  * env - Environment Table
---
--- Returns:
---  * The Module
function mod.init(deps, env)

    --------------------------------------------------------------------------------
    -- Inter-plugin Connectivity:
    --------------------------------------------------------------------------------
    mod._tb             = deps.tb
    mod._manager        = deps.manager
    mod._virtual        = deps.virtual
    mod._webviewLabel   = deps.manager.getLabel()
    mod._actionmanager  = deps.actionmanager
    mod._env            = env

    --------------------------------------------------------------------------------
    -- Setup Preferences Panel:
    --------------------------------------------------------------------------------
    mod._panel          =  deps.manager.addPanel({
        priority        = 2031,
        id              = "touchbar",
        label           = i18n("touchbarPanelLabel"),
        image           = imageFromPath(env:pathToAbsolute("/images/touchbar.icns")),
        tooltip         = i18n("touchbarPanelTooltip"),
        height          = 750,
    })
        --------------------------------------------------------------------------------
        -- Virtual Touch Bar
        --------------------------------------------------------------------------------
        :addHeading(1, i18n("virtualTouchBar"))
        :addCheckbox(2,
            {
                label       = i18n("enableVirtualTouchBar"),
                checked     = mod.virtual.enabled,
                onchange    = function(_, params) mod.virtual.enabled(params.checked) end,
            }
        )
        :addParagraph(2.1, html.br())
        :addSelect(3,
            {
                label       = i18n("visibility"),
                value       = mod.virtual.visibility,
                options     = visibilityOptions(),
                required    = true,
                class       = "touchbarDropdown",
                onchange    = function(_, params) mod.virtual.visibility(params.value) end,
            }
        )
        :addSelect(4,
            {
                label       = i18n("location"),
                value       = mod._virtual.location,
                options     = locationOptions(),
                required    = true,
                class       = "touchbarDropdown",
                onchange    = function(_, params) mod._virtual.location(params.value) end,
            }
        )
        :addParagraph(5, html.span {style="display: clear; margin-left: 243px;", class="tbTip"} (
            i18n("touchBarDragTip") ) ..
            "\n\n"
        )

        --------------------------------------------------------------------------------
        -- Customise Touch Bar:
        --------------------------------------------------------------------------------
        :addParagraph(5.1, html.div {style="clear: both;"} (""))
        :addHeading(6, i18n("customTouchBar"))
        :addCheckbox(7,
            {
                label       = i18n("enableCustomisedTouchBar"),
                checked     = mod.enabled,
                onchange    = function(_, params) mod.enabled(params.checked) end,
            }
        )
        :addParagraph(8, html.span { class="tbTip" } ( i18n("touchBarSetupTip"), false ).. "\n\n")
        :addContent(10, generateContent, false)

    mod._panel:addButton(20,
        {
            width       = 200,
            label       = i18n("resetEverything"),
            onclick     = resetAll,
            class       = "resetTouchBar",
        }
    )

    mod._panel:addButton(21,
        {
            width       = 200,
            label       = i18n("resetApplication"),
            onclick     = resetGroup,
            class       = "tbResetGroup",
        }
    )

    mod._panel:addButton(22,
        {
            width       = 200,
            label       = i18n("resetBank"),
            onclick     = resetSubGroup,
            class       = "tbResetGroup",
        }
    )

    --------------------------------------------------------------------------------
    -- Setup Callback Manager:
    --------------------------------------------------------------------------------
    mod._panel:addHandler("onchange", "touchBarPanelCallback", touchBarPanelCallback)

    return mod

end

local plugin = {
    id              = "core.touchbar.prefs",
    group           = "core",
    dependencies    = {
        ["core.controlsurfaces.manager"]    = "manager",
        ["core.touchbar.manager"]           = "tb",
        ["core.touchbar.virtual"]           = "virtual",
        ["core.action.manager"]             = "actionmanager",
    }
}

function plugin.init(deps, env)
    if deps.tb.supported() then
        return mod.init(deps, env)
    end
end

return plugin
