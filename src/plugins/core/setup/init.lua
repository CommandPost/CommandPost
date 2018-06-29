--- === plugins.core.setup ===
---
--- Manager for the CommandPost Setup Screen.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                                       = require("hs.logger").new("setup")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local screen                                    = require("hs.screen")
local webview                                   = require("hs.webview")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config                                    = require("cp.config")
local prop                                      = require("cp.prop")
local tools                                     = require("cp.tools")
local i18n                                      = require("cp.i18n")

--------------------------------------------------------------------------------
-- 3rd Party Extensions:
--------------------------------------------------------------------------------
local _                                         = require("moses")

--------------------------------------------------------------------------------
-- Module Extensions:
--------------------------------------------------------------------------------
local panel                                     = require("panel")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

-- plugins.core.setup.panel -> panel
-- Class
-- The `panel` class
mod.panel = panel

--- plugins.core.setup.DEFAULT_WIDTH -> number
--- Constant
--- The default panel width.
mod.DEFAULT_WIDTH = 900

--- plugins.core.setup.DEFAULT_HEIGHT -> number
--- Constant
--- The default panel height.
mod.DEFAULT_HEIGHT = 470

--- plugins.core.setup.DEFAULT_TITLE -> string
--- Constant
--- The default panel title.
mod.DEFAULT_TITLE = i18n("setupTitle")

-- plugins.core.setup._processedPanels -> number
-- Variable
-- Number of processed panels.
mod._processedPanels = 0

-- plugins.core.setup._currentPanel -> string
-- Variable
-- The ID of the current panel
mod._currentPanel = nil

-- plugins.core.setup._panelQueue -> table
-- Variable
-- The ID of the current panel
mod._panelQueue = {}

--- plugins.core.setup.FIRST_PRIORITY -> number
--- Constant
--- The first panel priority.
mod.FIRST_PRIORITY = 0

--- plugins.core.setup.LAST_PRIORITY -> number
--- Constant
--- The last panel priority.
mod.LAST_PRIORITY = 1000

--- plugins.core.setup.position <cp.prop: table>
--- Variable
--- The last known position of the Setup Window as a frame.
mod.position = config.prop("setupPosition", nil)

--- plugins.core.setup.onboardingRequired <cp.prop: boolean>
--- Variable
--- Set to `true` if on-boarding is required otherwise `false`. Defaults to `true`.
mod.onboardingRequired = config.prop("setupOnboardingRequired", true)

--- plugins.core.setup.visible <cp.prop: boolean; read-only>
--- Constant
--- A property indicating if the welcome window is visible on screen.
mod.visible = prop.new(function() return mod.webview and mod.webview:hswindow() and mod.webview:hswindow():isVisible() or false end)

--- plugins.core.setup.enabled <cp.prop: boolean>
--- Constant
--- Set to `true` if the manager is enabled. Defaults to `false`.
--- Panels can be added while disabled. Once enabled, the window will appear and display the panels.
mod.enabled = prop.FALSE():watch(function()
    --------------------------------------------------------------------------------
    -- Show the welcome window, if any panels are registered:
    --------------------------------------------------------------------------------
    mod.show()
end)

--- plugins.core.setup.setPanelRenderer(renderer) -> none
--- Function
--- Sets a Panel Renderer
---
--- Parameters:
---  * renderer - The renderer
---
--- Returns:
---  * None
function mod.setPanelRenderer(renderer)
    mod.renderPanel = renderer
end

--- plugins.core.setup.getLabel() -> string
--- Function
--- Returns the Webview label.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Webview label as a string.
function mod.getLabel()
    return panel.WEBVIEW_LABEL
end

-- generateHTML() -> string
-- Function
-- Generates the HTML for the Webview.
--
-- Parameters:
-- * None
--
-- Returns:
-- * The HTML as a string.
local function generateHTML()
    local env = {}

    env.debugMode = config.developerMode()

    env.panel = mod.currentPanel()
    env.panelCount = mod.panelCount()
    env.panelNumber = mod.panelNumber()

    local result, err = mod.renderPanel(env)
    if err then
        log.ef("Error while rendering Setup Panel: %s", err)
        return err
    else
        return result
    end
end

--- plugins.core.setup.panelCount() -> number
--- Function
--- The number of panels currently being processed in this session.
--- This includes panels already processed, the current panel, and remaining panels.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The number of panels.
function mod.panelCount()
    return mod._processedPanels + #mod._panelQueue
end

--- plugins.core.setup.panelNumber() -> number
--- Function
--- The number of the panel currently being viewed.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the current panel number, or `0` if no panels are registered.
function mod.panelNumber()
    return mod._processedPanels
end

--- plugins.core.setup.panelQueue() -> table of panels
--- Function
--- The table of panels remaining to be processed. Panels are removed from the queue
--- one at a time and idisplayed in the window via the `nextPanel()` function.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The table of panels remaining to be processed.
function mod.panelQueue()
    return mod._panelQueue
end

--- plugins.core.setup.currentPanel() -> string
--- Function
--- The Current Panel
---
--- Parameters:
---  * None
---
--- Returns:
---  * The current panel as a string
function mod.currentPanel()
    return mod._currentPanel
end

--- plugins.core.setup.init(env) -> module
--- Function
--- Initialises the module.
---
--- Parameters:
---  * env - The plugin environment table
---
--- Returns:
---  * The Module
function mod.init(env)
    mod.setPanelRenderer(env:compileTemplate("html/template.html"))
    mod.visible:update()

    return mod
end

-- windowCallback(action, webview, frame) -> none
-- Function
-- Setup Panels Window Callback
--
-- Parameters:
--  * action - The action as a string
--  * webview - The `hs.webview` object
--  * frame - position and size of the window
--
-- Returns:
--  * Table
local function windowCallback(action, _, frame)
    if action == "closing" then
        if not hs.shuttingDown then
            mod.webview = nil
            --------------------------------------------------------------------------------
            -- Close button on window clicked:
            --------------------------------------------------------------------------------
            if not mod._userClosing then
                config.application():kill()
            end
        end
    elseif action == "frameChange" then
        if frame then
            mod.position(frame)
        end
    end
end

-- centredPosition() -> none
-- Function
-- Gets the Centred Position.
--
-- Parameters:
--  * None
--
-- Returns:
--  * Table
local function centredPosition()
    local sf = screen.mainScreen():frame()
    return {x = sf.x + (sf.w/2) - (mod.DEFAULT_WIDTH/2), y = sf.y + (sf.h/2) - (mod.DEFAULT_HEIGHT/2), w = mod.DEFAULT_WIDTH, h = mod.DEFAULT_HEIGHT}
end

--- plugins.core.setup.new() -> none
--- Function
--- Creates the Setup Panels.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.new()
    if mod.nextPanel() then

        --------------------------------------------------------------------------------
        -- Use last Position or Centre on Screen:
        --------------------------------------------------------------------------------
        local defaultRect = mod.position()
        if defaultRect then
            defaultRect.w = mod.DEFAULT_WIDTH
            defaultRect.h = mod.DEFAULT_HEIGHT
        end
        if tools.isOffScreen(defaultRect) then
            defaultRect = centredPosition()
        end

        --------------------------------------------------------------------------------
        -- Setup Web View Controller:
        --------------------------------------------------------------------------------
        mod.controller = webview.usercontent.new(mod.getLabel())
            :setCallback(function(message)
                local body = message.body
                local id = body.id
                local params = body.params
                local thePanel = mod.currentPanel()
                local handler = thePanel and thePanel:getHandler(id)
                if handler then
                    return handler(id, params)
                end
            end)

        --------------------------------------------------------------------------------
        -- Setup Web View:
        --------------------------------------------------------------------------------
        local options = {
            developerExtrasEnabled = config.developerMode(),
        }

        mod.webview = webview.new(defaultRect, options, mod.controller)
            :windowStyle({"titled", "closable", "nonactivating", "miniaturizable"})
            :shadow(true)
            :allowNewWindows(false)
            :allowTextEntry(true)
            :windowTitle(mod.DEFAULT_TITLE)
            :html(generateHTML())
            :darkMode(true)
            :windowCallback(windowCallback)

        --------------------------------------------------------------------------------
        -- Show Setup Screen:
        --------------------------------------------------------------------------------
        mod.webview:show()
        mod.visible:update()
        --mod.focus()
    end
end

--- plugins.core.setup.show() -> none
--- Function
--- Shows the Setup Panels.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.show()
    if mod.visible() or not mod.enabled() then
        return
    else
        mod.new()
    end
end

--- plugins.core.setup.update() -> none
--- Function
--- Updates the Setup Panels.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.update()
    mod.visible:update()
    if mod.webview then
        mod.webview:html(generateHTML())
    end
end

--- plugins.core.setup.delete() -> none
--- Function
--- Deletes the Setup Panels.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.delete()
    if mod.webview then
        mod._userClosing = true
        mod.webview:delete()
        mod.webview = nil
        mod._panelQueue = {}
        mod._currentPanel = nil
        mod._processedPanels = 0
    end
    mod.visible:update()
end

--- plugins.core.setup.injectScript(script) -> none
--- Function
--- Injects JavaScript into the Setup Panels.
---
--- Parameters:
---  * script - The JavaScript you want to inject as a string.
---
--- Returns:
---  * None
function mod.injectScript(script)
    if mod.webview then
        mod.webview:evaluateJavaScript(script)
    end
end

--- plugins.core.setup.focus() -> none
--- Function
--- Focuses on the Setup Panels window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.focus()
    if mod.webview then
        mod.webview:bringToFront()
    end
    --[[
    mod.visible:update()
    if mod.webview then
        timer.doAfter(0.1, function()
            mod.webview:hswindow():focus()
        end)
        mod.webview:bringToFront()
        return true
    end
    return false
    --]]
end

--- plugins.core.setup.nextPanel() -> boolean
--- Function
--- Moves to the next panel. If the window is visible, the panel will be updated.
--- If no panels are left in the queue, the window will be closed.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if there was another panel to move to, or `false` if no panels remain.
function mod.nextPanel()
    if #mod._panelQueue > 0 then
        mod._currentPanel = mod._panelQueue[1]
        table.remove(mod._panelQueue, 1)
        mod._processedPanels = mod._processedPanels+1
        mod.update()
        --mod.focus()
        return true
    else
        mod.delete()
        return false
    end
end

--- plugins.core.setup.addPanel(newPanel) -> panel
--- Function
--- Adds the new panel to the manager. Panels are created via the
--- `plugins.core.setup.panel.new(...)` function.
---
--- If the Setup Manager is `enabled`, the window will be displayed
--- immediately when a panel is added.
---
--- Parameters:
---  * `newPanel`   - The panel to add.
---
--- Returns:
---  * The manager.
function mod.addPanel(newPanel)
    mod._panelQueue[#mod._panelQueue + 1] = newPanel
    --------------------------------------------------------------------------------
    -- Sort by priority:
    --------------------------------------------------------------------------------
    table.sort(mod._panelQueue, function(a, b) return a.priority < b.priority end)
    return mod
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "core.setup",
    group           = "core",
    required        = true,
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(_, env)
    return mod.init(env)
end

--------------------------------------------------------------------------------
-- POST INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.postInit()
    mod.onboardingRequired:watch(function(required)
        if required then

            --------------------------------------------------------------------------------
            -- The Intro Panel:
            --------------------------------------------------------------------------------
            mod.addPanel(
                panel.new("intro", mod.FIRST_PRIORITY)
                    :addIcon(config.iconPath)
                    :addHeading(config.appName)
                    :addSubHeading(i18n("introTagLine"))
                    :addParagraph(i18n("introText"), false)
                    :addButton({
                        value   = i18n("continue"),
                        onclick = function() mod.nextPanel() end,
                    })
                    :addButton({
                        value   = i18n("quit"),
                        onclick = function() config.application():kill() end,
                    })
            )

            --------------------------------------------------------------------------------
            -- The Outro Panel:
            --------------------------------------------------------------------------------
            mod.addPanel(
                panel.new("outro", mod.LAST_PRIORITY)
                    :addIcon(config.iconPath)
                    :addSubHeading(i18n("outroTitle"))
                    :addParagraph(i18n("outroText"), false)
                    :addButton({
                        value   = i18n("close"),
                        onclick = function()
                            mod.onboardingRequired(false)
                            mod.nextPanel()
                        end,
                    })
            )
            mod.show()
        end
    end, true)

    return mod.enabled(true)
end

return plugin
