--- === plugins.core.watchfolders.manager ===
---
--- Manager for the CommandPost Watch Folders Panel.

local require = require

local log           = require "hs.logger".new "watchMan"

local inspect       = require "hs.inspect"
local screen        = require "hs.screen"
local timer         = require "hs.timer"
local toolbar       = require "hs.webview.toolbar"
local webview       = require "hs.webview"

local config        = require "cp.config"
local dialog        = require "cp.dialog"
local just          = require "cp.just"
local tools         = require "cp.tools"
local i18n          = require "cp.i18n"

local panel         = require "panel"
local _             = require "moses"

local doAfter       = timer.doAfter
local waitUntil     = timer.waitUntil

local mod = {}

--- plugins.core.watchfolders.manager.WEBVIEW_LABEL -> string
--- Constant
--- WebView Label
mod.WEBVIEW_LABEL = "watchfolders"

--- plugins.core.watchfolders.manager.DEFAULT_WINDOW_STYLE -> table
--- Constant
--- Table of Default Window Style
mod.DEFAULT_WINDOW_STYLE = {"titled", "closable", "nonactivating"}

--- plugins.core.watchfolders.manager.DEFAULT_WIDTH -> number
--- Constant
--- Default Width of the Watch Folder Window
mod.DEFAULT_WIDTH = 1000

--- plugins.core.watchfolders.manager.DEFAULT_HEIGHT -> number
--- Constant
--- Default Height of the Watch Folder Window
mod.DEFAULT_HEIGHT = 338

--- plugins.core.watchfolders.manager.DEFAULT_TITLE -> number
--- Constant
--- Default Title of the Watch Folder Window
mod.DEFAULT_TITLE = i18n("watchFolders")

-- plugins.core.watchfolders.manager._panels -> table
-- Variable
-- Table of Panels
mod._panels = {}

-- plugins.core.watchfolders.manager._panels -> table
-- Variable
-- Table of Handlers
mod._handlers = {}

--- plugins.core.watchfolders.manager.position <cp.prop: table>
--- Constant
--- Returns the last frame saved in settings.
mod.position = config.prop("watchFolders.position", nil)

--- plugins.core.watchfolders.manager.position <cp.prop: table>
--- Constant
--- Returns the last frame saved in settings.
mod.lastTab = config.prop("watchFolders.lastTab", nil)

--- plugins.core.watchfolders.manager.getLabel() -> string
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

--- plugins.core.watchfolders.manager.addHandler(id, handlerFn) -> string
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

--- plugins.core.watchfolders.manager.getHandler(id) -> string
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

--- plugins.core.watchfolders.manager.setPanelRenderer(renderer) -> none
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

-- highestPriorityID() -> boolean
-- Function
-- Returns the highest priority ID.
--
-- Parameters:
--  * None
--
-- Returns:
--  * Boolean
local function highestPriorityID()
    if mod.lastTab() and isPanelIDValid(mod.lastTab()) then
        return mod.lastTab()
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
    env.highestPriorityID = highestPriorityID()

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
local function windowCallback(action, wv, frame)
    if action == "closing" then
        if not hs.shuttingDown then
            mod._webview = nil
        end
    elseif action == "focusChange" then
        if frame and mod._toolbar then
            local id = mod._toolbar:selectedItem()
            for _, v in ipairs(mod._panels) do
                if v.id == id then
                    --------------------------------------------------------------------------------
                    -- Wait until the Webview has loaded before triggering individual panels
                    -- functions:
                    --------------------------------------------------------------------------------
                    if just.doUntil(function() return not wv:loading() end) then
                        v.loadFn()
                    else
                        log.ef("Failed to trigger Watch Folder Load Function via manager.windowCallback.")
                    end
                end
            end
        end
    elseif action == "frameChange" then
        if frame then
            mod.position({
                x = frame.x,
                y = frame.y,
            })
        end
    end
end

--- plugins.core.watchfolders.manager.maxPanelHeight() -> number
--- Function
--- Gets the maximum panel height as a number
---
--- Parameters:
--- * None
---
--- Returns:
--- * A number
function mod.maxPanelHeight()
    local max = mod.DEFAULT_HEIGHT
    for _,v in ipairs(mod._panels) do
        max = v.height ~= nil and v.height < max and max or v.height
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

--- plugins.core.watchfolders.manager.init() -> nothing
--- Function
--- Initialises the preferences panel.
---
--- Parameters:
--- * None
---
--- Returns:
--- * Nothing
function mod.new()

    --------------------------------------------------------------------------------
    -- Use last Position or Centre on Screen:
    --------------------------------------------------------------------------------
    local defaultRect = centredPosition()
    local p = mod.position()
    if p then
        local savedPosition = {x = p.x, y = p.y, w = mod.DEFAULT_WIDTH, h = mod.DEFAULT_HEIGHT}
        if not tools.isOffScreen(defaultRect) then
            defaultRect = savedPosition
        end
    end

    --------------------------------------------------------------------------------
    -- Setup Web View Controller:
    --------------------------------------------------------------------------------
    if not mod._controller then
        mod._controller = webview.usercontent.new(mod.WEBVIEW_LABEL)
            :setCallback(function(message)
                --log.df("webview callback called: %s", inspect(message))
                local body = message.body
                local id = body.id
                local params = body.params
                local handler = mod.getHandler(id)
                if handler then
                    return handler(id, params)
                end
            end)
    end

    --------------------------------------------------------------------------------
    -- Setup Tool Bar:
    --------------------------------------------------------------------------------
    if not mod._toolbar then
        mod._toolbar = toolbar.new(mod.WEBVIEW_LABEL)
            :canCustomize(true)
            :autosaves(true)
            :setCallback(function(_, _, id)
                mod.selectPanel(id)
            end)

        local theToolbar = mod._toolbar
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
    if not mod._webview then
        local prefs = {}
        if config.developerMode() then prefs = {developerExtrasEnabled = true} end
        mod._webview = webview.new(defaultRect, prefs, mod._controller)
            :windowStyle(mod.DEFAULT_WINDOW_STYLE)
            :shadow(true)
            :allowNewWindows(false)
            :allowTextEntry(true)
            :windowTitle(mod.DEFAULT_TITLE)
            :attachedToolbar(mod._toolbar)
            :deleteOnClose(true)
            :windowCallback(windowCallback)
            :darkMode(true)
    end

end

--- plugins.core.watchfolders.manager.show() -> boolean
--- Function
--- Shows the Watch Folders Window
---
--- Parameters:
---  * None
---
--- Returns:
---  * True if successful or nil if an error occurred
function mod.show()
    if not mod._webview or not mod._toolbar then
        mod.new()
    end
    if next(mod._panels) == nil then
        dialog.displayMessage("There are no Preferences Panels to display.")
        return nil
    else
        mod._webview:html(generateHTML())
        mod._webview:show()
        doAfter(0.1, function()
            --log.df("Attempting to bring Preferences Panel to focus.")
            mod._webview:hswindow():raise():focus()
        end)
    end

    --------------------------------------------------------------------------------
    -- Select Panel:
    --------------------------------------------------------------------------------
    mod.selectPanel(highestPriorityID())

    return true
end

--- plugins.core.watchfolders.manager.hide() -> boolean
--- Function
--- Hides the Watch Folders Window
---
--- Parameters:
---  * None
---
--- Returns:
---  * True if successful or nil if an error occurred
function mod.hide()
    if mod._webview then
        mod._webview:delete()
        mod._webview = nil
    end
end

--- plugins.core.watchfolders.manager.injectScript(script) -> none
--- Function
--- Injects JavaScript into the Watch Folders Webview.
---
--- Parameters:
---  * script - The JavaScript code you want to inject in the form of a string.
---
--- Returns:
---  * None
function mod.injectScript(script)
    if mod._webview and mod._webview:frame() then
        --------------------------------------------------------------------------------
        -- Wait until the Webview has loaded before executing JavaScript:
        --------------------------------------------------------------------------------
        waitUntil(function() return not mod._webview:loading() end, function()
            mod._webview:evaluateJavaScript(script,
                function(_, theerror)
                    if theerror and theerror.code ~= 0 then
                        log.df("Javascript Error: %s\nCaused by script: %s", inspect(theerror), script)
                    end
                end)
        end, 0.01)
    end
end

--- plugins.core.watchfolders.manager.selectPanel(id) -> none
--- Function
--- Selects a Preferences Panel.
---
--- Parameters:
---  * id - the ID of the panel you want to select.
---
--- Returns:
---  * None
function mod.selectPanel(id)

    if not mod._webview or not mod._toolbar then
        return
    end

    local js = ""

    local loadFn = nil
    for _, v in ipairs(mod._panels) do

        --------------------------------------------------------------------------------
        -- Load Function for Panel:
        --------------------------------------------------------------------------------
        if v.id == id and v.loadFn then
            loadFn = v.loadFn
        end

        --------------------------------------------------------------------------------
        -- Resize Panel:
        --------------------------------------------------------------------------------
        if v.id == id and v.height and type(v.height) == "number" and mod._webview:hswindow() and mod._webview:hswindow():isVisible() then
            mod._webview:size({w = mod.DEFAULT_WIDTH, h = v.height })
        end

        local style = v.id == id and "block" or "none"
        js = js .. [[
            if (document.getElementById(']] .. v.id .. [[') !== null) {
                document.getElementById(']] .. v.id .. [[').style.display = ']] .. style .. [[';
            }
        ]]
    end

    mod.injectScript(js)

    mod._toolbar:selectedItem(id)

    if loadFn then
        --log.df("Executing Load Function via manager.selectPanel.")
        loadFn()
    end

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

--- plugins.core.watchfolders.manager.addPanel(params) -> plugins.core.watchfolders.manager.panel
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
function mod.addPanel(params)

    --log.df("Adding Preferences Panel with ID: %s", id)
    local newPanel = panel.new(params, mod)

    local index = _.sortedIndex(mod._panels, newPanel, comparePriorities)
    table.insert(mod._panels, index, newPanel)

    return newPanel
end

--- plugins.core.watchfolders.manager.init() -> none
--- Function
--- Initialises the Watch Folder Manager.
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

local plugin = {
    id              = "core.watchfolders.manager",
    group           = "core",
    required        = true,
    dependencies    = {
        ["core.commands.global"] = "global",
    }
}

function plugin.init(deps, env)

    --------------------------------------------------------------------------------
    -- Commands:
    --------------------------------------------------------------------------------
    local global = deps.global
    global:add("cpSetupWatchFolders")
        :whenActivated(mod.show)
        :groupedBy("commandPost")


    return mod.init(env)
end

return plugin
