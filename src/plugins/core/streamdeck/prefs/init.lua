--- === plugins.core.streamdeck.prefs ===
---
--- Stream Deck Preferences Panel

local require = require

local log               = require "hs.logger".new "prefsStreamDeck"

local application       = require "hs.application"
local canvas            = require "hs.canvas"
local dialog            = require "hs.dialog"
local image             = require "hs.image"

local commands          = require "cp.commands"
local config            = require "cp.config"
local tools             = require "cp.tools"
local html              = require "cp.web.html"
local ui                = require "cp.web.ui"
local i18n              = require "cp.i18n"

local moses             = require "moses"

local mod = {}

--- plugins.core.streamdeck.prefs.supportedExtensions -> string
--- Variable
--- Table of supported extensions for Stream Deck Icons.
mod.supportedExtensions = {"jpeg", "jpg", "tiff", "gif", "png", "tif", "bmp"}

--- plugins.core.streamdeck.prefs.defaultIconPath -> string
--- Variable
--- Default Path where built-in icons are stored
mod.defaultIconPath = config.assetsPath .. "/icons/"

--- plugins.core.streamdeck.prefs.enabled <cp.prop: boolean>
--- Field
--- Enable or disable Stream Deck Support.
mod.enabled = config.prop("enableStreamDesk", false)

--- plugins.core.streamdeck.prefs.lastGroup <cp.prop: string>
--- Field
--- Last group used in the Preferences Drop Down.
mod.lastGroup = config.prop("streamDeckPreferencesLastGroup", nil)

--- plugins.core.touchbar.prefs.scrollBarPosition <cp.prop: string>
--- Field
--- Last group used in the Preferences Drop Down.
mod.scrollBarPosition = config.prop("streamDeckPreferencesScrollBarPosition", {})

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
    local numberOfSubGroups = mod._sd.numberOfSubGroups
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
        bankLabel               = mod._sd.getBankLabel(defaultGroup),
        scrollBarPosition       = mod.scrollBarPosition(),
        groupEditor             = mod.getGroupEditor,
        i18n                    = i18n,
        maxItems                = mod._sd.maxItems,
        sd                      = mod._sd,
    }

    return renderPanel(context)
end

-- streamDeckPanelCallback() -> none
-- Function
-- JavaScript Callback for the Preferences Panel
--
-- Parameters:
--  * id - ID as string
--  * params - Table of paramaters
--
-- Returns:
--  * None
local function streamDeckPanelCallback(id, params)
    local injectScript = mod._manager.injectScript
    if params and params["type"] then
        if params["type"] == "badExtension" then
            --------------------------------------------------------------------------------
            -- Bad Icon File Extension:
            --------------------------------------------------------------------------------
            dialog.webviewAlert(mod._manager.getWebview(), function() end, i18n("badStreamDeckIcon"), i18n("pleaseTryAgain"), i18n("ok"))
        elseif params["type"] == "updateIcon" then
            --------------------------------------------------------------------------------
            -- Update Icon:
            --------------------------------------------------------------------------------
            mod._sd.updateIcon(params["buttonID"], params["groupID"], params["icon"])
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
                    mod.activator[groupID] = mod._actionmanager.getActivator("streamDeckPreferences" .. groupID)

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
                    mod.activator[groupID]:allowHandlers(table.unpack(allowedHandlers))
                    mod.activator[groupID]:preloadChoices()

                    --------------------------------------------------------------------------------
                    -- Allow specific toolbar icons in the Console:
                    --------------------------------------------------------------------------------
                    local iconPath = config.basePath .. "/plugins/finalcutpro/console/images/"
                    if groupID == "fcpx" then
                        local toolbarIcons = {
                            fcpx_widgets            = { path = iconPath .. "touchbar.png",      priority = 1},
                            global_streamDeckbanks  = { path = iconPath .. "bank.png",          priority = 2},
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
                    else
                        local toolbarIcons = {
                            global_streamDeckbanks  = { path = iconPath .. "bank.png",          priority = 1},
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
                if not mod._sd.updateAction(params["buttonID"], params["groupID"], actionTitle, handlerID, action) then
                    dialog.webviewAlert(mod._manager.getWebview(), function() end, i18n("touchBarDuplicateWidget"), i18n("touchBarDuplicateWidgetInfo"), i18n("ok"))
                end
                mod._sd.updateLabel(params["buttonID"], params["groupID"], actionTitle)

                injectScript([[setStreamDeckLabel("]] .. params["groupID"] .. [[", "]] .. params["buttonID"] .. [[", "]] .. actionTitle .. [[")]])
                injectScript([[setStreamDeckActionTitle("]] .. params["groupID"] .. [[", "]] .. params["buttonID"] .. [[", "]] .. actionTitle .. [[")]])
            end)

            --------------------------------------------------------------------------------
            -- Show Activator:
            --------------------------------------------------------------------------------
            mod.activator[activatorID]:show()

        elseif params["type"] == "clearAction" then
            mod._sd.updateAction(params["buttonID"], params["groupID"], nil, nil, nil)
            injectScript([[setStreamDeckActionTitle("]] .. params["groupID"] .. [[", "]] .. params["buttonID"] .. [[", "]] .. i18n("none") .. [[")]])
        elseif params["type"] == "updateLabel" then
            --------------------------------------------------------------------------------
            -- Update Label:
            --------------------------------------------------------------------------------
            mod._sd.updateLabel(params["buttonID"], params["groupID"], params["label"])
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
                    local genericPath = mod.defaultIconPath .. "Generic"
                    local touchBarPath = mod.defaultIconPath .. "Stream Deck"
                    if string.sub(path, 1, string.len(genericPath)) == genericPath or string.sub(path, 1, string.len(touchBarPath)) == touchBarPath then
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

                            local encodedIcon = newImage:encodeAsURLString()

                            mod._sd.updateIcon(params["buttonID"], params["groupID"], encodedIcon)
                            injectScript([[setStreamDeckIcon("]] .. params["groupID"] .. [[", "]] .. params["buttonID"] .. [[", "]] .. encodedIcon .. [[")]])
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
                            mod._sd.updateIcon(params["buttonID"], params["groupID"], encodedIcon)
                            injectScript([[setStreamDeckIcon("]] .. params["groupID"] .. [[", "]] .. params["buttonID"] .. [[", "]] .. encodedIcon .. [[")]])
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
                mod._sd.updateIcon(params["buttonID"], params["groupID"], nil)
                injectScript([[clearStreamDeckIcon("]] .. params["groupID"] .. [[", "]] .. params["buttonID"] .. [[") ]])
            end
        elseif params["type"] == "updateGroup" then
            --------------------------------------------------------------------------------
            -- Update Group:
            --------------------------------------------------------------------------------
            mod._sd.forceGroupChange(params["groupID"], mod._sd.enabled())
            mod._sd.update()
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
            mod._sd.updateOrder(direction, params["buttonID"], params["groupID"])
            local shiftButton
            if params["type"] == "upButtonPressed" then
                shiftButton = tostring(tonumber(params["buttonID"]) - 1)
            else
                shiftButton = tostring(tonumber(params["buttonID"]) + 1)
            end
            injectScript([[shiftStreamDeckButtons(']] .. params["groupID"] .. [[', ']] .. params["buttonID"] .. [[', ']] .. shiftButton .. [[')]])
        elseif params["type"] == "scrollBarPosition" then
            local value = params["value"]
            local groupID = params["groupID"]
            if value and groupID then
                local scrollBarPosition = mod.scrollBarPosition()
                scrollBarPosition[groupID] = value
                mod.scrollBarPosition(scrollBarPosition)
            end
        elseif params["type"] == "updateBankLabel" then
            local groupID = params["groupID"]
            local bankLabel = params["bankLabel"]
            mod._sd.setBankLabel(groupID, bankLabel)
        else
            --------------------------------------------------------------------------------
            -- Unknown Callback:
            --------------------------------------------------------------------------------
            log.df("Unknown Callback in Stream Deck Preferences Panel:")
            log.df("id: %s", hs.inspect(id))
            log.df("params: %s", hs.inspect(params))
        end
    end
end

--- plugins.core.streamdeck.prefs.setGroupEditor(groupId, editorFn) -> none
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

--- plugins.core.streamdeck.prefs.getGroupEditor(groupId) -> none
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

-- resetAll() -> none
-- Function
-- Prompts to reset all Stream Deck Preferences to their defaults.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function resetAll()
    dialog.webviewAlert(mod._manager.getWebview(), function(result)
        if result == i18n("yes") then
            mod._sd.clear()
            mod._manager.refresh()
        end
    end, i18n("streamDeckResetConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
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
            local items = mod._sd._items()
            local currentGroup = string.sub(mod.lastGroup(), 1, -2)
            for groupAndSubgroupID in pairs(items) do
                if string.sub(groupAndSubgroupID, 1, -2) == currentGroup then
                    items[groupAndSubgroupID] = nil
                end
            end
            mod._sd._items(items)
            mod._manager.refresh()
        end
    end, i18n("streamDeckResetGroupConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
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
            local items = mod._sd._items()
            local currentGroup = mod.lastGroup()
            items[currentGroup] = nil
            mod._sd._items(items)
            mod._manager.refresh()
        end
    end, i18n("streamDeckResetSubGroupConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
end


--- plugins.core.streamdeck.prefs.init(deps, env) -> module
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
    mod._sd             = deps.sd
    mod._manager        = deps.manager
    mod._webviewLabel   = deps.manager.getLabel()
    mod._actionmanager  = deps.actionmanager
    mod._env            = env

    --------------------------------------------------------------------------------
    -- Setup Preferences Panel:
    --------------------------------------------------------------------------------
    mod._panel          =  deps.manager.addPanel({
        priority        = 2032,
        id              = "streamdeck",
        label           = i18n("streamdeckPanelLabel"),
        image           = image.imageFromPath(tools.iconFallback(env:pathToAbsolute("images/streamdeck.icns"))),
        tooltip         = i18n("streamdeckPanelTooltip"),
        height          = 750,
    })
        :addHeading(6, i18n("streamDeck"))
        :addCheckbox(7,
            {
                label       = i18n("enableStreamDeck"),
                checked     = mod.enabled,
                onchange    = function(_, params)
                    if #application.applicationsForBundleID("com.elgato.StreamDeck") == 0 then
                        mod.enabled(params.checked)
                    else
                        dialog.webviewAlert(mod._manager.getWebview(), function() end, i18n("streamDeckAppRunning"), i18n("streamDeckAppRunningMessage"), i18n("ok"))
                        mod._manager.refresh()
                    end
                end,
            }
        )
        :addParagraph(8, html.span {class="tip"} (html(i18n("streamDeckAppTip"), false) ) .. "\n\n")
        :addContent(10, generateContent, false)

    mod._panel:addButton(20,
        {
            width       = 200,
            label       = i18n("resetEverything"),
            onclick     = resetAll,
            class       = "resetStreamDeck",
        }
    )

    mod._panel:addButton(21,
        {
            width       = 200,
            label       = i18n("resetApplication"),
            onclick     = resetGroup,
            class       = "sdResetGroup",
        }
    )

    mod._panel:addButton(22,
        {
            width       = 200,
            label       = i18n("resetBank"),
            onclick     = resetSubGroup,
            class       = "sdResetGroup",
        }
    )

    --------------------------------------------------------------------------------
    -- Setup Callback Manager:
    --------------------------------------------------------------------------------
    mod._panel:addHandler("onchange", "streamDeckPanelCallback", streamDeckPanelCallback)

    return mod

end

local plugin = {
    id              = "core.streamdeck.prefs",
    group           = "core",
    dependencies    = {
        ["core.preferences.manager"]        = "manager",
        ["core.streamdeck.manager"]         = "sd",
        ["core.action.manager"]             = "actionmanager",
    }
}

function plugin.init(deps, env)
    return mod.init(deps, env)
end

return plugin
