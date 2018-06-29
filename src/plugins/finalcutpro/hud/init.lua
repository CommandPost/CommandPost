--- === plugins.finalcutpro.hud ===
---
--- Final Cut Pro HUD.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local logName                                   = "hud"
local log                                       = require("hs.logger").new(logName)

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local drawing                                   = require("hs.drawing")
local geometry                                  = require("hs.geometry")
local screen                                    = require("hs.screen")
local timer                                     = require("hs.timer")
local webview                                   = require("hs.webview")
local window                                    = require("hs.window")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local commands                                  = require("cp.commands")
local config                                    = require("cp.config")
local dialog                                    = require("cp.dialog")
local fcp                                       = require("cp.apple.finalcutpro")
local tools                                     = require("cp.tools")
local i18n                                      = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- PRIORITY
-- Constant
-- The menubar position priority.
local PRIORITY = 10000

-- PREFERENCES_KEY
-- Constant
-- The Preferences key used by the HUD.
local PREFERENCES_KEY = "enableHUD"

-- PREFERENCES_KEY_POSITION
-- Constant
-- Preferences Key Position
local PREFERENCES_KEY_POSITION = "hudPosition"

-- GROUP
-- Constant
-- The Group used by the HUD
local GROUP = "fcpx"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local hud = {}

-- plugins.finalcutpro.hud.TITLE
-- Constant
-- The default HUD Title
hud.TITLE = ""

-- plugins.finalcutpro.hud.WIDTH
-- Constant
-- The default HUD Width
hud.WIDTH = 350

-- plugins.finalcutpro.hud.HEIGHT_INSPECTOR
-- Constant
-- The default HUD Height of the Inspector
hud.HEIGHT_INSPECTOR = 90

-- plugins.finalcutpro.hud.HEIGHT_DROP_TARGETS
-- Constant
-- The default HUD Height of the Drop Targets
hud.HEIGHT_DROP_TARGETS = 85

-- plugins.finalcutpro.hud.HEIGHT_BUTTONS
-- Constant
-- The default HUD Height of the Buttons
hud.HEIGHT_BUTTONS = 85

-- plugins.finalcutpro.hud.GREEN_COLOR
-- Constant
-- The Green Color used by Final Cut Pro.
hud.GREEN_COLOR = "#3f9253"

-- plugins.finalcutpro.hud.RED_COLOR
-- Constant
-- The Red Color used by Final Cut Pro.
hud.RED_COLOR = "#d1393e"

-- plugins.finalcutpro.hud.NUMBER_OF_BUTTONS
-- Constant
-- Number of buttons in the HUD
hud.NUMBER_OF_BUTTONS = 4

-- plugins.finalcutpro.hud.MAXIMUM_TEXT_LENGTH
-- Constant
-- Maximum Text Length
hud.MAXIMUM_TEXT_LENGTH = 25

--- plugins.finalcutpro.hud.position <cp.prop: table>
--- Constant
--- Returns the last HUD frame saved in settings.
hud.position = config.prop(PREFERENCES_KEY_POSITION, {})

-- getHUDHeight() -> number
-- Function
-- Calculates the HUD Height.
--
-- Parameters:
--  * None
--
-- Returns:
--  * The HUD height as a number
local function getHUDHeight()

    local hudShowInspector      = hud.inspectorShown()
    local hudShowDropTargets    = hud.isDropTargetsAvailable()
    local hudShowButtons        = hud.buttonsShown()

    local hudHeight = 0
    if hudShowInspector then hudHeight = hudHeight + hud.HEIGHT_INSPECTOR end
    if hudShowDropTargets then hudHeight = hudHeight + hud.HEIGHT_DROP_TARGETS end
    if hudShowButtons then hudHeight = hudHeight + hud.HEIGHT_BUTTONS end

    if hudShowInspector and hudShowDropTargets and (not hudShowButtons) then hudHeight = hudHeight - 15 end
    if hudShowInspector and (not hudShowDropTargets) and hudShowButtons then hudHeight = hudHeight - 20 end
    if hudShowInspector and hudShowDropTargets and hudShowButtons then  hudHeight = hudHeight - 20 end

    return hudHeight

end

-- getHUDRect() -> table
-- Function
-- Gets the HUD rect.
--
-- Parameters:
--  * None
--
-- Returns:
--  * The HUD frame
local function getHUDRect()

    local hudHeight = getHUDHeight()

    --------------------------------------------------------------------------------
    -- Get last HUD position from settings otherwise default to centre screen:
    --------------------------------------------------------------------------------
    local screenFrame = screen.mainScreen():frame()
    local defaultHUDRect = {x = (screenFrame['w']/2) - (hud.WIDTH/2), y = (screenFrame['h']/2) - (hudHeight/2), w = hud.WIDTH, h = hudHeight}
    local hudPosition = hud.position()
    if next(hudPosition) ~= nil then
        defaultHUDRect = {x = hudPosition["x"], y = hudPosition["y"], w = hud.WIDTH, h = hudHeight}
    end

    return defaultHUDRect

end

-- windowCallback() -> none
-- Function
-- x
--
-- Parameters:
--  * `action`  - an action as string
--  * `webview` - the webview that is being closed
--  * `frame`   - a rect-table containing the new co-ordinates and size of the webview window
--
-- Returns:
--  * None
local function windowCallback(action, _, frame)
    if action == "closing" then
        if not hs.shuttingDown then
            hud.enabled(false)
            hud.webview = nil
        end
    elseif action == "frameChange" then
        if frame then
            hud.position(frame)
        end
    end
end

--- plugins.finalcutpro.hud.new()
--- Function
--- Creates a new HUD
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function hud.new()

    --------------------------------------------------------------------------------
    -- Setup Web View Controller:
    --------------------------------------------------------------------------------
    if not hud.webviewController then
        hud.webviewController = webview.usercontent.new("hud")
            :setCallback(hud.javaScriptCallback)
    end

    --------------------------------------------------------------------------------
    -- Setup Web View:
    --------------------------------------------------------------------------------
    if not hud.webview then
        local options = {}
        if config.developerMode() then options.developerExtrasEnabled = true end
        hud.webview = webview.new(getHUDRect(), options, hud.webviewController)
            :windowStyle({"titled", "nonactivating", "closable"})
            :shadow(true)
            :closeOnEscape(true)
            :html(hud.generateHTML())
            :allowGestures(false)
            :allowNewWindows(false)
            :windowTitle(hud.TITLE)
            :level(drawing.windowLevels.floating)
            :windowCallback(windowCallback)
            :deleteOnClose(true)
            :darkMode(true)
    end

end

-- displayDiv(value) -> string
-- Function
-- Returns the display value.
--
-- Parameters:
--  * value - a boolean value
--
-- Returns:
--  * `block` if the value is true, otherwise `none`.
local function displayDiv(value)
    if value then
        return "block"
    else
        return "none"
    end
end

-- getEnv() -> table
-- Function
-- Sets up the HTML Template Environment.
--
-- Parameters:
--  * None
--
-- Returns:
--  * The HTML Template Environment.
local function getEnv()
    --------------------------------------------------------------------------------
    -- Set up the template environment
    --------------------------------------------------------------------------------
    local env       = {}

    env.i18n        = i18n
    env.hud         = hud
    env.displayDiv  = displayDiv

    env.debugMode   = config.developerMode()

    local viewer = fcp:viewer()

    if viewer:usingProxies() then
        env.media   = {
            text    = i18n("proxy"),
            class   = "bad",
        }
        env.quality = {
            text    = i18n("proxy"),
            class   = "bad",
        }
    else
        env.media   = {
            text    = i18n("originalOptimised"),
            class   = "good",
        }
        if viewer:betterQuality() then
            env.quality = {
                text    = i18n("betterQuality"),
                class   = "good",
            }
        else
            env.quality = {
                text    = i18n("betterPerformance"),
                class   = "bad",
            }
        end
    end

    local backgroundRender  = fcp.preferences.FFAutoStartBGRender or true

    if backgroundRender then
        local autoRenderDelay   = tonumber(fcp.preferences.FFAutoRenderDelay or "0.3")
        env.backgroundRender    = {
            text    = string.format("%s (%s %s)", i18n("enabled"), tostring(autoRenderDelay), i18n("secs", {count=autoRenderDelay})),
            class   = "good",
        }
    else
        env.backgroundRender    = {
            text    = i18n("disabled"),
            class   = "bad",
        }
    end

    env.hudInspector        = displayDiv( hud.inspectorShown() )
    env.hr1                 = displayDiv( hud.inspectorShown() and (hud.isDropTargetsAvailable() or hud.buttonsShown()) )
    env.hudDropTargets      = displayDiv( hud.isDropTargetsAvailable() )
    env.hr2                 = displayDiv( (hud.isDropTargetsAvailable() and hud.buttonsShown()) )
    env.hudButtons          = displayDiv( hud.buttonsShown() )

    return env
end

--- plugins.finalcutpro.hud.refresh() -> none
--- Function
--- Refresh the HUD's content.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function hud.refresh()

    --------------------------------------------------------------------------------
    -- Update HUD Content:
    --------------------------------------------------------------------------------
    if hud.webview then
        local env = getEnv()
        local javascriptToInject = [[
            document.getElementById('media').innerHTML = "]] .. env.media.text .. [[";
            document.getElementById('media').className = "]] .. env.media.class .. [[";

            document.getElementById('quality').innerHTML = "]] .. env.quality.text .. [[";
            document.getElementById('quality').className = "]] .. env.quality.class .. [[";

            document.getElementById('backgroundRender').innerHTML = "]] .. env.backgroundRender.text .. [[";
            document.getElementById('backgroundRender').className = "]] .. env.backgroundRender.class .. [[";

            document.getElementById('button1').innerHTML = "]] .. hud.getButtonText(1) .. [[";
            document.getElementById('button2').innerHTML = "]] .. hud.getButtonText(2) .. [[";
            document.getElementById('button3').innerHTML = "]] .. hud.getButtonText(3) .. [[";
            document.getElementById('button4').innerHTML = "]] .. hud.getButtonText(4) .. [[";

            document.getElementById('button1').setAttribute('href', ']] .. hud.getButtonURL(1) .. [[');
            document.getElementById('button2').setAttribute('href', ']] .. hud.getButtonURL(2) .. [[');
            document.getElementById('button3').setAttribute('href', ']] .. hud.getButtonURL(3) .. [[');
            document.getElementById('button4').setAttribute('href', ']] .. hud.getButtonURL(4) .. [[');

            document.getElementById('hudInspector').style.display = ']] .. env.hudInspector .. [[';
            document.getElementById('hr1').style.display = ']] .. env.hr1 .. [[';
            document.getElementById('hudDropTargets').style.display = ']] .. env.hudDropTargets .. [[';
            document.getElementById('hr2').style.display = ']] .. env.hr2 .. [[';
            document.getElementById('hudButtons').style.display = ']] .. env.hudButtons .. [[';
        ]]
        hud.webview:evaluateJavaScript(javascriptToInject)
    end

    --------------------------------------------------------------------------------
    -- Resize the HUD:
    --------------------------------------------------------------------------------
    if hud.visible() then
        hud.webview:hswindow():setSize(geometry.size(hud.WIDTH, getHUDHeight()))
    end

end

--- plugins.finalcutpro.hud.delete()
--- Function
--- Deletes the existing HUD if it exists
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function hud.delete()
    if hud.webview then
        hud.webview:delete()
        hud.webview = nil
    end
end

--- plugins.finalcutpro.hud.enabled <cp.prop: boolean>
--- Field
--- Is the HUD enabled in the settings?
hud.enabled = config.prop(PREFERENCES_KEY, false)

--- plugins.finalcutpro.hud.inspectorShown <cp.prop: boolean>
--- Field
--- Should the Inspector in the HUD be shown?
hud.inspectorShown = config.prop("hudShowInspector", true):watch(hud.refresh)

--- plugins.finalcutpro.hud.dropTargetsShown <cp.prop: boolean>
--- Field
--- Should Drop Targets in the HUD be enabled?
hud.dropTargetsShown = config.prop("hudShowDropTargets", true):watch(hud.refresh)

--- plugins.finalcutpro.hud.buttonsShown <cp.prop: boolean>
--- Field
--- Should Buttons in the HUD be shown?
hud.buttonsShown = config.prop("hudShowButtons", true):watch(hud.refresh)

--- plugins.finalcutpro.hud.getButton() -> table
--- Function
--- Gets the button values from settings.
---
--- Parameters:
---  * index - Index of the Button
---  * defaultValue - Default Value of the Button
---
--- Returns:
---  * Button value
function hud.getButton(index, defaultValue)
    local currentLocale = fcp:currentLocale()
    return config.get(string.format("%s.hudButton.%d", currentLocale.code, index), defaultValue)
end

--- plugins.finalcutpro.hud.getButtonCommand() -> string
--- Function
--- Gets the button command.
---
--- Parameters:
---  * index - Index of the Button
---
--- Returns:
---  * Button Command
function hud.getButtonCommand(index)
    local button = hud.getButton(index)
    if button and button.action then
        if button.action.type == "command" then
            local group = commands.group(button.action.group)
            if group then
                return group:get(button.action.id)
            end
        end
    end
    return nil
end

--- plugins.finalcutpro.hud.getButtonText() -> string
--- Function
--- Gets the button text.
---
--- Parameters:
---  * index - Index of the Button
---
--- Returns:
---  * Button Label or Unassigned Value
function hud.getButtonText(index)
    local button = hud.getButton(index)
    if button and button.text then
        return tools.stringMaxLength(tools.cleanupButtonText(button.text), hud.MAXIMUM_TEXT_LENGTH, "...")
    else
        return i18n("unassigned")
    end
end

--- plugins.finalcutpro.hud.getButtonURL() -> string
--- Function
--- Gets the button URL.
---
--- Parameters:
---  * index - Index of the Button
---
--- Returns:
---  * Button URL
function hud.getButtonURL(index)
    local button = hud.getButton(index)
    if button then
        return hud.actionmanager.getURL(button.handlerId, button.action)
    else
        return "#"
    end
end

--- plugins.finalcutpro.hud.setButton() -> string
--- Function
--- Sets the button.
---
--- Parameters:
---  * index - Index of the Button
---  * value - Value you want to set the button to.
---
--- Returns:
---  * None
function hud.setButton(index, value)
    local currentLocale = fcp:currentLocale()
    config.set(string.format("%s.hudButton.%d", currentLocale.code, index), value)
end

--- plugins.finalcutpro.hud.updateVisibility() -> none
--- Function
--- Update the visibility of the HUD.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function hud.updateVisibility()
    if hud.enabled() then

        --------------------------------------------------------------------------------
        -- Only show if Final Cut Pro is running...
        --------------------------------------------------------------------------------
        if not fcp:isRunning() then
            --log.df("Final Cut Pro is not running.")
            hud.hide()
            return
        end

        --------------------------------------------------------------------------------
        -- Only show if Final Cut Pro or HUD is Frontmost.
        --------------------------------------------------------------------------------
        if not fcp:isFrontmost() then
            local focusedWindow = window.focusedWindow()
            if focusedWindow and focusedWindow:application() and focusedWindow:application():pid() == config.processID then
                --log.df("CommandPost is frontmost")
                hud.show()
                return
            else
                --log.df("Final Cut Pro is not frontmost.")
                hud.hide()
                return
            end
        end

        --------------------------------------------------------------------------------
        -- Don't show the HUD when in fullscreen mode or Command Editor is visible:
        --------------------------------------------------------------------------------
        if fcp:fullScreenWindow():isShowing() or fcp:commandEditor():isShowing() then
            --log.df("Final Cut Pro Command Editor or Full Screen Playback is visible.")
            hud.hide()
            return
        end

        --------------------------------------------------------------------------------
        -- Show the HUD:
        --------------------------------------------------------------------------------
        --log.df("Let's show the HUD")
        hud.show()

    else
        --------------------------------------------------------------------------------
        -- Hide the HUD:
        --------------------------------------------------------------------------------
        hud.hide()
    end

    --------------------------------------------------------------------------------
    -- Just to be safe...
    --------------------------------------------------------------------------------
    timer.doAfter(0.5, hud.updateVisibility)
end

--- plugins.finalcutpro.hud.show() -> none
--- Function
--- Show the HUD.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function hud.show()
    if not hud.webview then
        hud.new()
    end

    --------------------------------------------------------------------------------
    -- CommandPost Window Watcher:
    --------------------------------------------------------------------------------
    if not hud._cpWatcher then
        hud._cpWatcher = window.filter.new(function(w)
                return w and w:application():bundleID() == hs.processInfo.bundleID
        end, logName)
            :subscribe(window.filter.windowUnfocused, function()
                --log.df("CommandPost Lost Focus!")
                hud.updateVisibility()
            end)
    end

    hud.webview:show()
    hud.refresh()
end

--- plugins.finalcutpro.hud.hide() -> none
--- Function
--- Hide the HUD.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function hud.hide()
    if hud.webview then
        hud.webview:hide()
    end
    if hud._cpWatcher then
        --log.df("CommandPost Watcher Destroyed")
        hud._cpWatcher = nil
    end
end

--- plugins.finalcutpro.hud.visible() -> none
--- Function
--- Is the HUD visible?
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` or `false`
function hud.visible()
    if hud.webview and hud.webview:hswindow() then return true end
    return false
end

--- plugins.finalcutpro.hud.assignButton() -> none
--- Function
--- Assigns a HUD button.
---
--- Parameters:
---  * button - which button you want to assign.
---
--- Returns:
---  * None
function hud.assignButton(button)

    --------------------------------------------------------------------------------
    -- Was Final Cut Pro Open?
    --------------------------------------------------------------------------------
    local wasFinalCutProOpen = fcp:isFrontmost()
    local whichButton = button
    local activator

    local chooserAction = function(handler, action, text)
        --------------------------------------------------------------------------------
        -- Perform Specific Function:
        --------------------------------------------------------------------------------
        if action ~= nil then
            local value = { handlerId = handler:id(), action = action, text = text }
            hud.setButton(whichButton, value)
        end

        --------------------------------------------------------------------------------
        -- Put focus back in Final Cut Pro:
        --------------------------------------------------------------------------------
        if wasFinalCutProOpen then
            fcp:launch()
        end

        --------------------------------------------------------------------------------
        -- Refresh HUD:
        --------------------------------------------------------------------------------
        if hud.enabled() then
            hud.refresh()
        end
    end

    activator = hud.actionmanager.getActivator("finalcutpro.hud.buttons")
    :onActivate(chooserAction)

    --------------------------------------------------------------------------------
    -- Restrict Allowed Handlers for Activator to current group:
    --------------------------------------------------------------------------------
    local allowedHandlers = {}
    local handlerIds = hud.actionmanager.handlerIds()
    for _,id in pairs(handlerIds) do
        local handlerTable = tools.split(id, "_")
        if handlerTable[1] == GROUP then
            table.insert(allowedHandlers, id)
        end
    end
    activator:allowHandlers(table.unpack(allowedHandlers))

    activator:show()
end

--- plugins.finalcutpro.hud.choices() -> none
--- Function
--- Choices for the Assign HUD Button chooser.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Table
function hud.choices()
    if hud.actionmanager then
        return hud.actionmanager.choices()
    else
        return {}
    end
end

--- plugins.finalcutpro.hud.generateHTML() -> none
--- Function
--- Generate the HTML for the HUD.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function hud.generateHTML()
    local result, err = hud.renderTemplate(getEnv())
    if err then
        log.ef("Error while rendering HUD template: %s", err)
        return err
    else
        return result
    end

end

--- plugins.finalcutpro.hud.javaScriptCallback() -> none
--- Function
--- Javascript Callback
---
--- Parameters:
---  * message - the message for the callback
---
--- Returns:
---  * None
function hud.javaScriptCallback(message)
    if message["body"] ~= nil then
        if string.find(message["body"], "<!DOCTYPE fcpxml>") ~= nil then
            hud.xmlSharing.shareXML(message["body"])
        else
            dialog.displayMessage(i18n("hudDropZoneError"))
        end
    end
end

--- plugins.finalcutpro.hud.update() -> none
--- Function
--- Enables or Disables the HUD.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function hud.update()
    if hud.enabled() then
        --------------------------------------------------------------------------------
        -- Setup Watchers:
        --------------------------------------------------------------------------------
        fcp.app.frontmost:watch(hud.updateVisibility)
        fcp.app.showing:watch(hud.updateVisibility)

        fcp:fullScreenWindow().isShowing:watch(hud.updateVisibility)
        fcp:commandEditor().isShowing:watch(hud.updateVisibility)

        -- refresh when the preferences change.
        fcp.app.preferences:watch(hud.refresh)

        --------------------------------------------------------------------------------
        -- Create new HUD:
        --------------------------------------------------------------------------------
        hud.new()
        hud.updateVisibility()
    else
        --------------------------------------------------------------------------------
        -- Destroy Watchers:
        --------------------------------------------------------------------------------
        fcp.app.frontmost:unwatch(hud.updateVisibility)
        fcp.app.showing:unwatch(hud.updateVisibility)

        fcp:fullScreenWindow().isShowing:unwatch(hud.updateVisibility)
        fcp:commandEditor().isShowing:unwatch(hud.updateVisibility)

        --------------------------------------------------------------------------------
        -- Delete the HUD:
        --------------------------------------------------------------------------------
        hud.delete()
    end
end

--- plugins.finalcutpro.hud.init() -> none
--- Function
--- Initialise HUD Module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function hud.init(xmlSharing, actionmanager, env)
    hud.xmlSharing      = xmlSharing
    hud.actionmanager   = actionmanager
    hud.renderTemplate  = env:compileTemplate("html/hud.html")

    --------------------------------------------------------------------------------
    -- Set up checking for XML Sharing:
    --------------------------------------------------------------------------------
    xmlSharing.enabled:watch(hud.refresh)
    hud.isDropTargetsAvailable = hud.dropTargetsShown:AND(xmlSharing.enabled)

    hud.enabled:watch(hud.update)
    return hud
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.hud",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.sharing.xml"]         = "xmlSharing",
        ["finalcutpro.menu.tools"]          = "menu",
        ["finalcutpro.commands"]            = "fcpxCmds",
        ["core.action.manager"]     = "actionmanager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)

    --------------------------------------------------------------------------------
    -- Initialise Module:
    --------------------------------------------------------------------------------
    hud.init(deps.xmlSharing, deps.actionmanager, env)

    --------------------------------------------------------------------------------
    -- Setup Menus:
    --------------------------------------------------------------------------------
   deps.menu
        :addMenu(PRIORITY, function() return i18n("hud") end)
        :addItem(1000, function()
            return { title = i18n("enableHUD"), fn = function() hud.enabled:toggle() end,       checked = hud.enabled()}
        end)
        :addSeparator(2000)
        :addMenu(3000, function() return i18n("hudOptions") end)
        :addItems(1000, function()
            return {
                { title = i18n("showInspector"),    fn = function() hud.inspectorShown:toggle() end,        checked = hud.inspectorShown()},
                { title = i18n("showDropTargets"),  fn = function() hud.dropTargetsShown:toggle() end,  checked = hud.isDropTargetsAvailable(), disabled = not hud.xmlSharing.enabled()},
                { title = i18n("showButtons"),      fn = function() hud.buttonsShown:toggle() end,      checked = hud.buttonsShown()},
            }
        end)
        :addMenu(4000, function() return i18n("assignHUDButtons") end)
        :addItems(1000, function()
            local items = {}
            for i = 1, hud.NUMBER_OF_BUTTONS do
                local title = hud.getButtonText(i)
                title = tools.stringMaxLength(tools.cleanupButtonText(title), hud.MAXIMUM_TEXT_LENGTH, "...")
                items[#items + 1] = { title = i18n("hudButtonItem", {count = i, title = title}),    fn = function() hud.assignButton(i) end }
            end
            return items
        end)

    --------------------------------------------------------------------------------
    -- Setup Command:
    --------------------------------------------------------------------------------
    deps.fcpxCmds
        :add("cpHUD")
        :activatedBy():ctrl():option():cmd("a")
        :whenActivated(function() hud.enabled:toggle() end)

    return hud
end

--------------------------------------------------------------------------------
-- POST INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.postInit()
    hud.update()
end

return plugin
