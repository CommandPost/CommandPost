--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                     P R E F E R E N C E S   M A N A G E R                  --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.preferences.manager ===
---
--- Manager for the CommandPost Preferences Window.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                                       = require("hs.logger").new("prefsMgr")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local inspect                                   = require("hs.inspect")
local screen                                    = require("hs.screen")
local toolbar                                   = require("hs.webview.toolbar")
local webview                                   = require("hs.webview")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config                                    = require("cp.config")
local dialog                                    = require("cp.dialog")
local just                                      = require("cp.just")
local tools                                     = require("cp.tools")

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

--- plugins.core.preferences.manager.WEBVIEW_LABEL -> string
--- Constant
--- The WebView Label
mod.WEBVIEW_LABEL = "preferences"

--- plugins.core.preferences.manager.DEFAULT_WINDOW_STYLE
--- Constant
--- Default Webview Window Style of Preferences Window
mod.DEFAULT_WINDOW_STYLE  = {"titled", "closable", "nonactivating"}

--- plugins.core.preferences.manager.DEFAULT_HEIGHT
--- Constant
--- Default Height of Preferences Window
mod.DEFAULT_HEIGHT = 338

--- plugins.core.preferences.manager.DEFAULT_WIDTH
--- Constant
--- Default Width of Preferences Window
mod.DEFAULT_WIDTH = 750

--- plugins.core.preferences.manager.DEFAULT_TITLE
--- Constant
--- Default Title of Preferences Window
mod.DEFAULT_TITLE = i18n("preferences")

--- plugins.core.preferences.manager._panels
--- Variable
--- Table containing panels.
mod._panels = {}

--- plugins.core.preferences.manager._handlers
--- Variable
--- Table containing handlers.
mod._handlers = {}

--- plugins.core.preferences.manager.position
--- Constant
--- Returns the last frame saved in settings.
mod.position = config.prop("preferencesPosition", nil)

--- plugins.core.preferences.manager.lastTab
--- Constant
--- Returns the last tab saved in settings.
mod.lastTab = config.prop("preferencesLastTab", nil)

--- plugins.core.preferences.manager.getWebview() -> hs.webview
--- Function
--- Returns the Webview of the Preferences Window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `hs.webview`
function mod.getWebview()
    return mod.webview
end

--- plugins.core.preferences.manager.getLabel() -> string
--- Function
--- Returns the Webview label.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Webview label as a string.
function mod.getLabel()
    return mod.WEBVIEW_LABEL
end

--- plugins.core.preferences.manager.addHandler(id, handlerFn) -> string
--- Function
--- Adds a Handler
---
--- Parameters:
---  * id - The ID
---  * handlerFn - the handler function
---
--- Returns:
---  * Nothing
function mod.addHandler(id, handlerFn)
    mod._handlers[id] = handlerFn
end

--- plugins.core.preferences.manager.getHandler(id) -> string
--- Function
--- Returns the handler for a given ID.
---
--- Parameters:
---  * id - The ID
---
--- Returns:
---  * Table
function mod.getHandler(id)
    return mod._handlers[id]
end

--- plugins.core.preferences.manager.setPanelRenderer(renderer) -> none
--- Function
--- Sets a Panel Renderer
---
--- Parameters:
---  * renderer - The renderer
---
--- Returns:
---  * None
function mod.setPanelRenderer(renderer)
    mod._panelRenderer = renderer
end

-- isPanelIDValid() -> boolean
-- Function
-- Is Panel ID Valid?
--
-- Parameters:
--  * None
--
-- Returns:
--  * Boolean
local function isPanelIDValid(whichID)
    for _, v in ipairs(mod._panels) do
        if v.id == whichID then
            return true
        end
    end
    return false
end

-- currentPanelID() -> string
-- Function
-- Returns the panel ID with the highest priority.
--
-- Parameters:
-- * None
--
-- Returns:
-- * The panel ID as a string
local function currentPanelID()
    local id = mod.lastTab()
    if id and isPanelIDValid(id) then
        return id
    else
        return #mod._panels > 0 and mod._panels[1].id or nil
    end
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
    env.panels = mod._panels
    env.currentPanelID = currentPanelID()

    local result, err = mod._panelRenderer(env)
    if err then
        log.ef("Error rendering Preferences Panel Template: %s", err)
        return err
    else
        return result
    end
end

-- windowCallback(action, webview, frame) -> none
-- Function
-- Window Callback.
--
-- Parameters:
-- * action - accepts `closing`, `focusChange` or `frameChange`
-- * webview - the `hs.webview`
-- * frame - the frame of the `hs.webview`
--
-- Returns:
-- * Nothing
local function windowCallback(action, webview, frame)
    if action == "closing" then
        if not hs.shuttingDown then
            mod.webview = nil

            --------------------------------------------------------------------------------
            -- Trigger Closing Callbacks:
            --------------------------------------------------------------------------------
            for _, v in ipairs(mod._panels) do
                if v.closeFn and type(v.closeFn) == "function" then
                    v.closeFn()
                end
            end

        end
    elseif action == "frameChange" then
        if frame then
            mod.position(frame)
        end
    end
end

--- plugins.core.preferences.manager.init() -> nothing
--- Function
--- Initialises the preferences panel.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Nothing
function mod.init(env)
    mod.setPanelRenderer(env:compileTemplate("html/panels.html"))

    return mod
end

--- plugins.core.preferences.manager.maxPanelHeight() -> number
--- Function
--- Returns the maximum size defined by a panel.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The maximum panel height.
function mod.maxPanelHeight()
    local max = mod.DEFAULT_HEIGHT
    for _,thePanel in ipairs(mod._panels) do
        local height
        if type(thePanel.height) == "function" then
            height = thePanel.height()
        else
            height = thePanel.height
        end
        if type(height) == "number" then
            if height > max then max = height end
        else
            log.ef("panel.height in plugins.core.preferences.manager.maxPanelHeight is invalid: %s (%s)", inspect(height), height and type(height))
        end
    end
    return max
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
    return {x = sf.x + (sf.w/2) - (mod.DEFAULT_WIDTH/2), y = sf.y + (sf.h/2) - (mod.maxPanelHeight()/2), w = mod.DEFAULT_WIDTH, h = mod.DEFAULT_HEIGHT}
end

--- plugins.core.preferences.manager.new() -> none
--- Function
--- Creates a new Preferences Window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.new()

    --------------------------------------------------------------------------------
    -- Use last Position or Centre on Screen:
    --------------------------------------------------------------------------------
    local defaultRect = mod.position()
    if tools.isOffScreen(defaultRect) then
        defaultRect = centredPosition()
    end

    --------------------------------------------------------------------------------
    -- Setup Web View Controller:
    --------------------------------------------------------------------------------
    mod.controller = webview.usercontent.new(mod.WEBVIEW_LABEL)
        :setCallback(function(message)
            local body = message.body
            local id = body.id
            local params = body.params

            local handler = mod.getHandler(id)
            if handler then
                return handler(id, params)
            end
        end)


    --------------------------------------------------------------------------------
    -- Setup Tool Bar:
    --------------------------------------------------------------------------------
    if not mod.toolbar then
        mod.toolbar = toolbar.new(mod.WEBVIEW_LABEL)
            :canCustomize(true)
            :autosaves(true)
            :setCallback(function(_, _, id)
                mod.selectPanel(id)
            end)

        local theToolbar = mod.toolbar
        for _,thePanel in ipairs(mod._panels) do
            local item = thePanel:getToolbarItem()
            theToolbar:addItems(item)
            if not theToolbar:selectedItem() then
                theToolbar:selectedItem(item.id)
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Setup Web View:
    --------------------------------------------------------------------------------
    local prefs = {}
    prefs.developerExtrasEnabled = config.developerMode()
    mod.webview = webview.new(defaultRect, prefs, mod.controller)
        :windowStyle(mod.DEFAULT_WINDOW_STYLE)
        :shadow(true)
        :allowNewWindows(false)
        :allowTextEntry(true)
        :windowTitle(mod.DEFAULT_TITLE)
        :attachedToolbar(mod.toolbar)
        :deleteOnClose(true)
        :windowCallback(windowCallback)
        :darkMode(true)

    return mod
end

--- plugins.core.preferences.manager.show() -> boolean
--- Function
--- Shows the Preferences Window
---
--- Parameters:
---  * None
---
--- Returns:
---  * True if successful or nil if an error occurred
function mod.show()

    if mod.webview == nil then
        mod.new()
    end

    if next(mod._panels) == nil then
        dialog.displayMessage("There are no Preferences Panels to display.")
        return nil
    else
        mod.selectPanel(currentPanelID())
        mod.webview:html(generateHTML())
        mod.webview:show()
        mod.focus()
    end

    return true
end

--- plugins.core.preferences.manager.focus() -> boolean
--- Function
--- Puts focus on the Preferences Window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if successful or otherwise `false`.
function mod.focus()
    just.doUntil(function()
        if mod.webview and mod.webview:hswindow() and mod.webview:hswindow():raise():focus() then
            return true
        else
            return false
        end
    end)
end

--- plugins.core.preferences.manager.hide() -> none
--- Function
--- Hides the Preferences Window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.hide()
    if mod.webview then
        mod.webview:delete()
        mod.webview = nil
    end
end

--- plugins.core.preferences.manager.refresh() -> none
--- Function
--- Refreshes the Preferences Window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.refresh()
    if mod.webview then
        mod.selectPanel(currentPanelID())
        mod.webview:html(generateHTML())
    end
end

--- plugins.core.preferences.manager.injectScript(script) -> none
--- Function
--- Injects JavaScript into the Preferences Webview.
---
--- Parameters:
---  * script - The JavaScript code you want to inject in the form of a string.
---
--- Returns:
---  * None
function mod.injectScript(script)
    if mod.webview then
        mod.webview:evaluateJavaScript(script)
    end
end

--- plugins.core.preferences.manager.selectPanel(id) -> none
--- Function
--- Selects a Preferences Panel.
---
--- Parameters:
---  * id - the ID of the panel you want to select.
---
--- Returns:
---  * None
function mod.selectPanel(id)

    if not mod.webview then
        return
    end

    local js = ""

    for _, thePanel in ipairs(mod._panels) do
        --------------------------------------------------------------------------------
        -- Resize Panel:
        --------------------------------------------------------------------------------
        if thePanel.id == id and thePanel.height then
            local height
            if type(thePanel.height) == "function" then
                height = thePanel.height()
            else
                height = thePanel.height
            end
            mod.webview:size({w = mod.DEFAULT_WIDTH, h = height })
        end

        local style = thePanel.id == id and "block" or "none"
        js = js .. [[
            document.getElementById(']] .. thePanel.id .. [[').style.display = ']] .. style .. [[';
        ]]
    end

    mod.webview:evaluateJavaScript(js)
    mod.toolbar:selectedItem(id)

    --------------------------------------------------------------------------------
    -- Save Last Tab in Settings:
    --------------------------------------------------------------------------------
    mod.lastTab(id)

end

-- comparePriorities(a, b) -> none
-- Function
-- Compares priorities
--
-- Parameters:
--  * a - Priority A
--  * b - Priority B
--
-- Returns:
--  * The priority of the highest values between A and B.
local function comparePriorities(a, b)
    return a.priority < b.priority
end

--- plugins.core.preferences.manager.addPanel(params) -> plugins.core.preferences.manager.panel
--- Function
--- Adds a new panel with the specified `params` to the preferences manager.
---
--- Parameters:
---  * `params` - The parameters table. Details below.
---
--- Returns:
---  * The new `panel` instance.
---
--- Notes:
---  * The `params` can have the following properties. The `priority` and `id` and properties are **required**.
---  ** `priority`      - An integer value specifying the priority of the panel compared to others.
---  ** `id`            - A string containing the unique ID of the panel.
---  ** `label`         - The human-readable label for the panel icon.
---  ** `image`         - The `hs.image` for the panel icon.
---  ** `tooltip`       - The human-readable details for the toolbar icon when the mouse is hovering over it.
---  ** `closeFn`       - A callback function that's triggered when the Preferences window is closed.
function mod.addPanel(params)

    local newPanel = panel.new(params, mod)

    local index = _.sortedIndex(mod._panels, newPanel, comparePriorities)
    table.insert(mod._panels, index, newPanel)

    if mod.toolbar then
        local toolbar = mod.toolbar
        local item = panel:getToolbarItem()

        toolbar:addItems(item)
        toolbar:insertItem(item.id, index)
        if not toolbar:selectedItem() then
            toolbar:selectedItem(item.id)
        end
    end

    return newPanel
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "core.preferences.manager",
    group           = "core",
    required        = true,
    dependencies    = {
        ["core.commands.global"] = "global",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)

    --------------------------------------------------------------------------------
    -- Commands:
    --------------------------------------------------------------------------------
    local global = deps.global
    global:add("cpPreferences")
        :whenActivated(mod.show)
        :groupedBy("commandPost")

    return mod.init(env)
end

return plugin