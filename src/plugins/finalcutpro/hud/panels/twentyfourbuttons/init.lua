--- === plugins.finalcutpro.hud.panels.twentyfourbuttons ===
---
--- Twenty Four Button Panel for the Final Cut Pro HUD.

local require                   = require

local log                       = require("hs.logger").new("hudButton")

local dialog                    = require("hs.dialog")
local image                     = require("hs.image")
local inspect                   = require("hs.inspect")
local menubar                   = require("hs.menubar")
local mouse                     = require("hs.mouse")

local config                    = require("cp.config")
local fcp                       = require("cp.apple.finalcutpro")
local i18n                      = require("cp.i18n")
local json                      = require("cp.json")
local tools                     = require("cp.tools")

local cleanupButtonText         = tools.cleanupButtonText
local iconFallback              = tools.iconFallback
local imageFromPath             = image.imageFromPath
local stringMaxLength           = tools.stringMaxLength
local webviewAlert              = dialog.webviewAlert

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.hud.panels.twentyfourbuttons.buttons <cp.prop: table>
--- Field
--- Table of HUD button values.
mod.buttons = json.prop(config.userConfigRootPath, "HUD", "Twenty Four Buttons.cpHUD", {})

--- plugins.finalcutpro.hud.panels.twentyfourbuttons.updateInfo() -> none
--- Function
--- Update the Buttons Panel HTML content.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
local function updateInfo()
    local buttons = mod.buttons()
    local script = ""
    for i=1, 24 do
        local button = buttons and buttons[tostring(i)]
        local value = button and (button.customTitle or button.actionTitle)
        if value then
            value = stringMaxLength(cleanupButtonText(value), 10, "…")
            script = script .. [[changeInnerHTMLByID("button]] .. i .. [[", "]] .. value .. [[");]] .. "\n"
        else
            script = script .. [[changeInnerHTMLByID("button]] .. i .. [[", "-");]] .. "\n"
        end
    end
    if script ~= "" then
        mod._manager.injectScript(script)
    end
end

-- saveAction(id, actionTitle, handlerID, action) -> none
-- Function
-- Saves an action to the button JSON file.
--
-- Parameters:
--  * id - The ID of the button as a string.
--  * actionTitle - The action title as string.
--  * handlerID - The handler ID as string.
--  * action - The action table.
--
-- Returns:
--  * None
local function saveAction(id, actionTitle, handlerID, action)
    local buttons = mod.buttons()
    if not buttons[id] then
        buttons[id] = {}
    end

    buttons[id] = {
        actionTitle = actionTitle,
        handlerID = handlerID,
        action = action,
    }
    mod.buttons(buttons)
end

-- assignAction(id) -> none
-- Function
-- Assign an action to a HUD button.
--
-- Parameters:
--  * id - The ID of the button as a string.
--
-- Returns:
--  * None
local function assignAction(id)
    --------------------------------------------------------------------------------
    -- Setup Activator:
    --------------------------------------------------------------------------------
    local activator = mod._actionManager.getActivator("hud")
    activator:preloadChoices()
    activator:onActivate(function(handler, action, text)
        --------------------------------------------------------------------------------
        -- Process Stylised Text:
        --------------------------------------------------------------------------------
        if text and type(text) == "userdata" then
            text = text:convert("text")
        end

        local actionTitle = text
        local handlerID = handler:id()

        saveAction(id, actionTitle, handlerID, action)
        updateInfo()
        fcp:launch()
    end)

    --------------------------------------------------------------------------------
    -- Show Activator:
    --------------------------------------------------------------------------------
    activator:show()
end

-- renameButton(id) -> none
-- Function
-- Prompts to rename a HUD button.
--
-- Parameters:
--  * id - The ID of the button as a string.
--
-- Returns:
--  * None
local function renameButton(id)
    local buttons = mod.buttons()
    local button = buttons and buttons[id]
    local value = button and button.customTitle or button.actionTitle or ""
    mod._manager.injectScript("renamePrompt('" .. id .. "', '" .. i18n("renameButtonQuestion").. "', '" .. value .. "');")
end

-- renameButtonValue(id, value) -> none
-- Function
-- Renames a button value based on a previous prompt.
--
-- Parameters:
--  * id - The ID of the button as a string.
--  * value - The new name of the button as a string.
--
-- Returns:
--  * None
local function renameButtonValue(id, value)
    local buttons = mod.buttons()
    if not buttons[id] then
        buttons[id] = {}
    end
    buttons[id]["customTitle"] = value
    mod.buttons(buttons)
    updateInfo()
end

-- resetButton(id) -> none
-- Function
-- Resets a HUD button.
--
-- Parameters:
--  * id - The ID of the button as a string.
--
-- Returns:
--  * None
local function resetButton(id)
    local buttons = mod.buttons()
    buttons[id] = nil
    mod.buttons(buttons)
    updateInfo()
end

-- leftClickButton(id) -> none
-- Function
-- Triggers an action when a HUD button is pressed.
--
-- Parameters:
--  * id - The ID of the button as a string.
--
-- Returns:
--  * None
local function leftClickButton(id)
    local buttons = mod.buttons()
    local button = buttons and buttons[id]
    local webview = mod._manager._webview
    if button then
        local handler = mod._actionManager.getHandler(button.handlerID)
        if handler then
            if not handler:execute(button.action) then
                log.ef("Failed to execute button: %s", inspect(button))
                if webview then
                    webviewAlert(webview, function() end, "An error has occurred.", "We were unable to execute the action. Please try reassigning the action.", i18n("ok"))
                end
            end
        else
            log.ef("Unable to find handler to execute button: %s", inspect(button))
            if webview then
                webviewAlert(webview, function() end, "An error has occurred.", "We were unable to find the handler to execute the action. Please try reassigning the action.", i18n("ok"))
            end
        end
    else
        if webview then
            webviewAlert(webview, function() end, i18n("noActionAssignedToThisButton"), i18n("rightClickToAssignAction"), i18n("ok"))
        end
    end
end

-- rightClickButton(id) -> none
-- Function
-- Triggers a popup when a HUD button is right-clicked.
--
-- Parameters:
--  * id - The ID of the button as a string.
--
-- Returns:
--  * None
local function rightClickButton(id)

    local buttons = mod.buttons()
    local button = buttons and buttons[id]

    local position = mouse.getAbsolutePosition()
    local popup = menubar.new()

    local menu = {
        { title = i18n("assignAction"), fn = function() assignAction(id) end }
    }

    if button then
        table.insert(menu, { title = i18n("renameButton"), fn = function() renameButton(id) end })
        table.insert(menu, { title = i18n("resetButton"), fn = function() resetButton(id) end })
    end

    popup:setMenu(menu)
    popup:removeFromMenuBar()
    popup:popupMenu(position, true)
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.hud.panels.twentyfourbuttons",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.hud.manager"]     = "manager",
        ["core.action.manager"]         = "actionManager",
    }
}

function plugin.init(deps, env)
    if fcp:isSupported() then

        mod._manager = deps.manager
        mod._actionManager = deps.actionManager

        local panel = deps.manager.addPanel({
            priority    = 5,
            id          = "twentyfourbuttons",
            label       = "24 " .. i18n("buttons"),
            tooltip     = "24 " .. i18n("buttons"),
            image       = imageFromPath(iconFallback(env:pathToAbsolute("/images/twentyfourbuttons.png"))),
            height      = 170,
            loadedFn    = updateInfo,
        })

        --------------------------------------------------------------------------------
        -- Generate HTML for Panel:
        --------------------------------------------------------------------------------
        local renderPanel = env:compileTemplate("html/panel.html")
        panel:addContent(1, function() return renderPanel() end, false)

        --------------------------------------------------------------------------------
        -- Setup Controller Callback:
        --------------------------------------------------------------------------------
        local controllerCallback = function(_, params)
            if params["type"] == "leftClickHUDButton" then
                leftClickButton(params["buttonID"])
            elseif params["type"] == "rightClickHUDButton" then
                rightClickButton(params["buttonID"])
            elseif params["type"] == "renameButton" then
                renameButtonValue(params["buttonID"], params["value"])
            end
        end
        deps.manager.addHandler("hudtwentyfourbuttons", controllerCallback)
    end
end

return plugin
