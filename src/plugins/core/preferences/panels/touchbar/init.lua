--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--            T O U C H B A R    P R E F E R E N C E S    P A N E L           --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.preferences.panels.touchbar ===
---
--- Touch Bar Preferences Panel

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                                       = require("hs.logger").new("prefsTouchBar")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local canvas                                    = require("hs.canvas")
local dialog                                    = require("hs.dialog")
local image                                     = require("hs.image")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local commands                                  = require("cp.commands")
local config                                    = require("cp.config")
local fcp                                       = require("cp.apple.finalcutpro")
local tools                                     = require("cp.tools")
local html                                      = require("cp.web.html")
local ui                                        = require("cp.web.ui")

--------------------------------------------------------------------------------
-- 3rd Party Extensions:
--------------------------------------------------------------------------------
local _                                         = require("moses")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.core.preferences.panels.touchbar.supportedExtensions -> string
--- Variable
--- Table of supported extensions for Touch Bar Icons.
mod.supportedExtensions = {"jpeg", "jpg", "tiff", "gif", "png", "tif", "bmp"}

--- plugins.core.preferences.panels.touchbar.defaultIconPath -> string
--- Variable
--- Default Path where built-in icons are stored
mod.defaultIconPath = config.assetsPath .. "/icons"

--- plugins.core.preferences.panels.touchbar.enabled <cp.prop: boolean>
--- Field
--- Enable or disable Touch Bar Support.
mod.enabled = config.prop("enableTouchBar", false)

--- plugins.core.preferences.panels.touchbar.lastGroup <cp.prop: string>
--- Field
--- Last group used in the Preferences Drop Down.
mod.lastGroup = config.prop("touchBarPreferencesLastGroup", nil)

--- plugins.core.preferences.panels.touchbar.maxItems -> number
--- Variable
--- The maximum number of Touch Bar items per group.
mod.maxItems = 8

-- resetTouchBar() -> none
-- Function
-- Prompts to reset shortcuts to default.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function resetTouchBar()
    dialog.webviewAlert(mod._manager.getWebview(), function(result)
        if result == i18n("yes") then
            mod._tb.clear()
            mod._manager.refresh()
        end
    end, i18n("touchBarResetConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
end

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
    local groupOptions = {}
    local defaultGroup = nil
    if mod.lastGroup() then defaultGroup = mod.lastGroup() end -- Get last group from preferences.
    for _,id in ipairs(commands.groupIds()) do
        for subGroupID=1, mod._tb.numberOfSubGroups do
            defaultGroup = defaultGroup or id .. subGroupID
            groupOptions[#groupOptions+1] = { value = id .. subGroupID, label = i18n("shortcut_group_" .. id, {default = id}) .. " (Bar " .. tostring(subGroupID) .. ")"}
            groups[#groups + 1] = id .. subGroupID
        end
    end
    table.sort(groupOptions, function(a, b) return a.label < b.label end)

    local touchBarGroupSelect = ui.select({
        id          = "touchBarGroupSelect",
        value       = defaultGroup,
        options     = groupOptions,
        required    = true,
    }) .. ui.javascript([[
        var touchBarGroupSelect = document.getElementById("touchBarGroupSelect")
        touchBarGroupSelect.onchange = function(e) {

            //
            // Change Group Callback:
            //
            try {
                var result = {
                    id: "touchBarPanelCallback",
                    params: {
                        type: "updateGroup",
                        groupID: this.value,
                    },
                }
                webkit.messageHandlers.]] .. mod._manager.getLabel() .. [[.postMessage(result);
            } catch(err) {
                console.log("Error: " + err)
                alert('An error has occurred. Does the controller exist yet?');
            }

            console.log("touchBarGroupSelect changed");
            var groupControls = document.getElementById("touchbarGroupControls");
            var value = touchBarGroupSelect.options[touchBarGroupSelect.selectedIndex].value;
            var children = groupControls.children;
            for (var i = 0; i < children.length; i++) {
              var child = children[i];
              if (child.id == "touchbarGroup_" + value) {
                  child.classList.add("selected");
              } else {
                  child.classList.remove("selected");
              }
            }
        }
    ]])

    local context = {
        _                       = _,
        touchBarGroupSelect     = touchBarGroupSelect,
        groups                  = groups,
        defaultGroup            = defaultGroup,

        groupEditor             = mod.getGroupEditor,

        webviewLabel            = mod._manager.getLabel(),

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
                    for subGroupID=1, mod._tb.numberOfSubGroups do
                        --------------------------------------------------------------------------------
                        -- Create new Activator:
                        --------------------------------------------------------------------------------
                        mod.activator[groupID .. subGroupID] = mod._actionmanager.getActivator("touchbarPreferences" .. groupID .. subGroupID)

                        --------------------------------------------------------------------------------
                        -- Restrict Allowed Handlers for Activator to current group (and global):
                        --------------------------------------------------------------------------------
                        local allowedHandlers = {}
                        for _,v in pairs(handlerIds) do
                            local handlerTable = tools.split(v, "_")
                            if handlerTable[1] == groupID or handlerTable[1] == "global" then
                                table.insert(allowedHandlers, v)
                            end
                        end
                        mod.activator[groupID .. subGroupID]:allowHandlers(table.unpack(allowedHandlers))
                        mod.activator[groupID .. subGroupID]:preloadChoices()
                    end
                end
            end

            --------------------------------------------------------------------------------
            -- Setup Activator Callback:
            --------------------------------------------------------------------------------
            local groupID = params["groupID"]

            mod.activator[groupID]:onActivate(function(handler, action, text)

                --------------------------------------------------------------------------------
                -- Process Stylised Text:
                --------------------------------------------------------------------------------
                if text and type(text) == "userdata" then
                    text = text:convert("text")
                end

                local actionTitle = text
                local handlerID = handler:id()

                mod._tb.updateAction(params["buttonID"], params["groupID"], actionTitle, handlerID, action)
                mod._manager.refresh()
            end)

            --------------------------------------------------------------------------------
            -- Show Activator:
            --------------------------------------------------------------------------------
            mod.activator[groupID]:show()

        elseif params["type"] == "clearAction" then
            mod._tb.updateAction(params["buttonID"], params["groupID"], nil, nil, nil)
            mod._manager.refresh()
        elseif params["type"] == "updateLabel" then
            --------------------------------------------------------------------------------
            -- Update Label:
            --------------------------------------------------------------------------------
            mod._tb.updateLabel(params["buttonID"], params["groupID"], params["label"])
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

                            local a = canvas.new{x = 0, y = 0, w = 512, h = 512 }
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

                            local encodedIcon = newImage:encodeAsURLString()

                            mod._tb.updateIcon(params["buttonID"], params["groupID"], encodedIcon)
                            mod._manager.refresh()
                        else
                            failed = true
                        end
                    else
                        --------------------------------------------------------------------------------
                        -- An image from outside the pre-supplied image path:
                        --------------------------------------------------------------------------------
                        local encodedIcon = icon:encodeAsURLString()
                        if encodedIcon then
                            mod._tb.updateIcon(params["buttonID"], params["groupID"], encodedIcon)
                            mod._manager.refresh()
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
                mod._manager.refresh()
            end
        elseif params["type"] == "updateGroup" then
            --------------------------------------------------------------------------------
            -- Update Group:
            --------------------------------------------------------------------------------
            mod.lastGroup(params["groupID"])
        else
            --------------------------------------------------------------------------------
            -- Unknown Callback:
            --------------------------------------------------------------------------------
            log.df("Unknown Callback in Touch Bar Preferences Panel:")
            log.df("id: %s", hs.inspect(id))
            log.df("params: %s", hs.inspect(params))
        end
    end
end

--- plugins.core.preferences.panels.touchbar.setGroupEditor(groupId, editorFn) -> none
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

--- plugins.core.preferences.panels.touchbar.getGroupEditor(groupId) -> none
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
    if enabled then
        mod._tb.virtual.start()
    else
        mod._tb.virtual.stop()
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
        mod._tb.virtual.show()
    elseif status == mod.virtual.VISIBILITY_FCP then
        if fcp.isFrontmost() then
            mod._tb.virtual.show()
        else
            mod._tb.virtual.hide()
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
        value = mod._tb.virtual.LOCATION_MOUSE,
    }
    options[#options + 1] = {
        label = i18n("draggable"),
        value = mod._tb.virtual.LOCATION_DRAGGABLE,
    }
    return options
end

--- plugins.core.preferences.panels.touchbar.init(deps, env) -> module
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
        image           = image.imageFromPath(tools.iconFallback("/System/Library/PreferencePanes/TouchID.prefPane/Contents/Resources/touchid_icon.icns")),
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
                value       = mod._tb.virtual.location,
                options     = locationOptions(),
                required    = true,
                class       = "touchbarDropdown",
                onchange    = function(_, params) mod._tb.virtual.location(params.value) end,
            }
        )
        :addParagraph(5, html.span {style="display: clear;", class="tbTip"} (
            html.strong (string.upper(i18n("tip")) .. ": ") .. i18n("touchBarDragTip") ) ..
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
        :addParagraph(8, html.span { class="tbTip" } ( html.strong (string.upper(i18n("tip")) .. ": ") .. i18n("touchBarSetupTip") ).. "\n\n")
        :addContent(10, generateContent, false)

    mod._panel:addButton(20,
        {
            width       = 200,
            label       = i18n("touchBarReset"),
            onclick     = resetTouchBar,
            class       = "resetShortcuts",
        }
    )

    --------------------------------------------------------------------------------
    -- Setup Callback Manager:
    --------------------------------------------------------------------------------
    mod._panel:addHandler("onchange", "touchBarPanelCallback", touchBarPanelCallback)

    return mod

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "core.preferences.panels.touchbar",
    group           = "core",
    dependencies    = {
        ["core.preferences.manager"]        = "manager",
        ["core.touchbar.manager"]           = "tb",
        ["core.action.manager"]             = "actionmanager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)
    if deps.tb.supported() then
        return mod.init(deps, env)
    end
end

return plugin