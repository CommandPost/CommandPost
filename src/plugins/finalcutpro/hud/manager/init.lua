--- === plugins.finalcutpro.hud.manager ===
---
--- Manager for the Final Cut Pro HUD.

local require = require

local hs            = hs

local log           = require("hs.logger").new("hudMan")

local application   = require("hs.application")
local drawing       = require("hs.drawing")
local inspect       = require("hs.inspect")
local screen        = require("hs.screen")
local timer         = require("hs.timer")
local toolbar       = require("hs.webview.toolbar")
local webview       = require("hs.webview")
local window        = require("hs.window")

local app           = require("cp.app")
local config        = require("cp.config")
local dialog        = require("cp.dialog")
local fcp           = require("cp.apple.finalcutpro")
local i18n          = require("cp.i18n")
local just          = require("cp.just")
local tools         = require("cp.tools")

local moses         = require("moses")
local panel         = require("panel")

local forBundleID   = app.forBundleID
local processInfo   = hs.processInfo
local sortedIndex   = moses.sortedIndex
local tableMatch    = tools.tableMatch

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

-- cpApp -> cp.app
-- Variable
-- CommandPost App
local cpApp = forBundleID(processInfo.bundleID)

--- plugins.finalcutpro.hud.manager.enabled <cp.prop: boolean>
--- Field
--- Is the HUD enabled in the settings?
mod.enabled = config.prop("hub.enabled", false)

--- plugins.finalcutpro.hud.manager.WEBVIEW_LABEL -> string
--- Constant
--- The WebView Label
mod.WEBVIEW_LABEL = "hud"

--- plugins.finalcutpro.hud.manager.DEFAULT_HEIGHT -> number
--- Constant
--- Default Height of HUD
mod.DEFAULT_HEIGHT = 300

--- plugins.finalcutpro.hud.manager.DEFAULT_WIDTH -> number
--- Constant
--- Default Width of HUD
mod.DEFAULT_WIDTH = 600

--- plugins.finalcutpro.hud.manager._panels -> table
--- Variable
--- Table containing panels.
mod._panels = {}

--- plugins.finalcutpro.hud.manager._handlers -> table
--- Variable
--- Table containing handlers.
mod._handlers = {}

--- plugins.finalcutpro.hud.manager.position
--- Constant
--- Returns the last frame saved in settings.
mod.position = config.prop("fcp.hud.position", nil)

--- plugins.finalcutpro.hud.manager.lastTab
--- Constant
--- Returns the last tab saved in settings.
mod.lastTab = config.prop("fcp.hud.lastTab", nil)

--- plugins.finalcutpro.hud.manager.getWebview() -> hs.webview
--- Function
--- Returns the Webview of the HUD.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `hs.webview`
function mod.getWebview()
    return mod._webview
end

--- plugins.finalcutpro.hud.manager.getLabel() -> string
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

--- plugins.finalcutpro.hud.manager.addHandler(id, handlerFn) -> string
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

--- plugins.finalcutpro.hud.manager.getHandler(id) -> string
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

--- plugins.finalcutpro.hud.manager.setPanelRenderer(renderer) -> none
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

--- plugins.finalcutpro.hud.manager.currentPanelID() -> string
--- Function
--- Returns the panel ID with the highest priority.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The panel ID as a string
function mod.currentPanelID()
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
    env.currentPanelID = mod.currentPanelID()
    env.webviewLabel = mod.WEBVIEW_LABEL

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
-- * None
local function windowCallback(action, _, frame)
    if action == "closing" then
        if not hs.shuttingDown then
            mod.enabled(false)
            mod.webview = nil
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

--- plugins.finalcutpro.hud.manager.init() -> nothing
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

--- plugins.finalcutpro.hud.manager.maxPanelHeight() -> number
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
            log.ef("panel.height in plugins.finalcutpro.hud.manager.maxPanelHeight is invalid: %s (%s)", inspect(height), height and type(height))
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

--- plugins.finalcutpro.hud.manager.new() -> none
--- Function
--- Creates a new HUD.
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
                mod.refresh()
            end)

        local theToolbar = mod._toolbar
        for _,thePanel in ipairs(mod._panels) do
            local item = thePanel:getToolbarItem()
            theToolbar:addItems(item)
            if not theToolbar:selectedItem() then
                theToolbar:selectedItem(item.id)
            end
        end

        mod._toolbar
            :displayMode("icon")
            :sizeMode("small")
    end

    --------------------------------------------------------------------------------
    -- Setup Web View:
    --------------------------------------------------------------------------------
    if not mod._webview then
        local prefs = {}
        prefs.developerExtrasEnabled = config.developerMode()
        mod._webview = webview.new(defaultRect, prefs, mod._controller)
            :windowStyle({"titled", "nonactivating", "closable", "HUD", "utility"})
            :shadow(true)
            :closeOnEscape(true)
            :allowNewWindows(false)
            :allowTextEntry(true)
            :windowTitle("CommandPost HUD")
            :attachedToolbar(mod._toolbar)
            :deleteOnClose(true)
            :windowCallback(windowCallback)
            :level(drawing.windowLevels.floating)
            :darkMode(true)
    end

    return mod
end

--- plugins.finalcutpro.hud.manager.show() -> boolean
--- Function
--- Shows the HUD
---
--- Parameters:
---  * None
---
--- Returns:
---  * True if successful or nil if an error occurred
function mod.show()
    if not next(mod._panels) then
        dialog.displayMessage("There are no HUD Panels to display.")
        return nil
    end

    if mod._webview == nil then
        mod.new()
        mod.refresh()
    end

    if mod._webview then
        mod._webview:show()
    end

    return true
end

--- plugins.finalcutpro.hud.manager.focus() -> boolean
--- Function
--- Puts focus on the HUD.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if successful or otherwise `false`.
function mod.focus()
    just.doUntil(function()
        if mod._webview and mod._webview:hswindow() and mod._webview:hswindow():raise():focus() then
            return true
        else
            return false
        end
    end)
end

--- plugins.finalcutpro.hud.manager.hide() -> none
--- Function
--- Hides the HUD.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.hide()
    if mod._webview ~= nil then
        mod._webview:hide()
    end
end

--- plugins.finalcutpro.hud.manager.delete()
--- Function
--- Deletes the existing HUD if it exists
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.delete()
    if mod._webview ~= nil then
        mod._webview:delete()
        mod._webview = nil
    end
end

--- plugins.finalcutpro.hud.manager.refresh() -> none
--- Function
--- Refreshes the HUD.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.refresh()
    if mod._webview then
        mod.selectPanel(mod.currentPanelID())
        mod._webview:html(generateHTML())

        local frame = mod._webview:frame()
        mod._frameUUID = frame.w + frame.h
    end
end

--- plugins.finalcutpro.hud.manager.injectScript(script) -> none
--- Function
--- Injects JavaScript into the HUD Webview.
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
        timer.waitUntil(function() return not mod._webview:loading() end, function()
            mod._webview:evaluateJavaScript(script,
                function(_, theerror)
                    if theerror and theerror.code ~= 0 then
                        log.df("Javascript Error: %s\nCaused by script: %s", inspect(theerror), script)
                    end
                end)
        end, 0.01)
    end
end

--- plugins.finalcutpro.hud.manager.selectPanel(id) -> none
--- Function
--- Selects a HUD Panel.
---
--- Parameters:
---  * id - the ID of the panel you want to select.
---
--- Returns:
---  * None
function mod.selectPanel(id)

    if not mod._webview then
        return
    end

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
            mod._webview:size({w = mod.DEFAULT_WIDTH, h = height })
        end

    end

    mod._toolbar:selectedItem(id)

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

--- plugins.finalcutpro.hud.manager.addPanel(params) -> plugins.finalcutpro.hud.manager.panel
--- Function
--- Adds a new panel with the specified `params` to the HUD manager.
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
---  ** `closeFn`       - A callback function that's triggered when the HUD is closed.
function mod.addPanel(params)

    local newPanel = panel.new(params, mod)

    local index = sortedIndex(mod._panels, newPanel, comparePriorities)
    table.insert(mod._panels, index, newPanel)

    return newPanel
end

-- FCP_BUNDLE_ID -> string
-- Constant
-- Cached Final Cut Pro Bundle ID
local FCP_BUNDLE_ID = fcp:bundleID()

-- CP_BUNDLE_ID -> string
-- Constant
-- Cached CommandPost Bundle ID
local CP_BUNDLE_ID = config.bundleID

-- plugins.finalcutpro.hud.manager._updating -> boolean
-- Variable
-- Is the HUD already in the process of updating it's visibility?
mod._updating = false

--- plugins.finalcutpro.hud.manager.updateVisibility() -> none
--- Function
--- Update the visibility of the HUD.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.updateVisibility()
    timer.doAfter(0.000000000001, function()
        --------------------------------------------------------------------------------
        -- Ignore if the HUD is disabled:
        --------------------------------------------------------------------------------
        if not mod.enabled() then return end

        --------------------------------------------------------------------------------
        -- If CommandPost or Final Cut Pro is frontmost:
        --------------------------------------------------------------------------------
        local frontmostApplication = application.frontmostApplication()
        if frontmostApplication then
            local bundleID = frontmostApplication:bundleID()
            if bundleID and (bundleID == CP_BUNDLE_ID or bundleID == FCP_BUNDLE_ID) then
                if bundleID == CP_BUNDLE_ID then
                    if mod._frameUUID then
                        local focusedWindow = frontmostApplication:focusedWindow()
                        local focusedWindowFrame = focusedWindow and focusedWindow:frame()
                        if focusedWindowFrame then
                            if mod._frameUUID == focusedWindowFrame.w + focusedWindowFrame.h then
                                --------------------------------------------------------------------------------
                                -- The HUD is frontmost:
                                --------------------------------------------------------------------------------
                                log.df("the hud is frontmost")
                                mod.show()
                                return
                            end
                        end
                    end
                elseif bundleID == FCP_BUNDLE_ID then
                    if not fcp:fullScreenWindow():isShowing() and
                    not fcp:commandEditor():isShowing() and
                    not fcp:preferencesWindow():isShowing() then
                        --------------------------------------------------------------------------------
                        -- Final Cut Pro's main interface is frontmost:
                        --------------------------------------------------------------------------------
                        mod.show()
                        return
                    end
                end
            end
        end

        --------------------------------------------------------------------------------
        -- Otherwise hide the HUD:
        --------------------------------------------------------------------------------
        mod.hide()
    end)
end

--- plugins.finalcutpro.hud.manager.update() -> none
--- Function
--- Enables or Disables the HUD.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.update()
    if mod.enabled() then
        log.df("HUD is enabled")
        --------------------------------------------------------------------------------
        -- Setup Watchers:
        --------------------------------------------------------------------------------
        fcp.app.frontmost:watch(mod.updateVisibility)
        fcp.app.showing:watch(mod.updateVisibility)

        fcp:fullScreenWindow().isShowing:watch(mod.updateVisibility)
        fcp:commandEditor().isShowing:watch(mod.updateVisibility)
        fcp:preferencesWindow().isShowing:watch(mod.updateVisibility)

        cpApp.frontmost:watch(mod.updateVisibility)
        cpApp.showing:watch(mod.updateVisibility)

        --------------------------------------------------------------------------------
        -- Update Visibility:
        --------------------------------------------------------------------------------
        mod.updateVisibility()
    else
        log.df("HUD is disabled")
        --------------------------------------------------------------------------------
        -- Destroy Watchers:
        --------------------------------------------------------------------------------
        fcp.app.frontmost:unwatch(mod.updateVisibility)
        fcp.app.showing:unwatch(mod.updateVisibility)

        fcp:fullScreenWindow().isShowing:unwatch(mod.updateVisibility)
        fcp:commandEditor().isShowing:unwatch(mod.updateVisibility)
        fcp:preferencesWindow().isShowing:unwatch(mod.updateVisibility)

        cpApp.frontmost:unwatch(mod.updateVisibility)
        cpApp.showing:unwatch(mod.updateVisibility)

        --------------------------------------------------------------------------------
        -- Destroy the HUD:
        --------------------------------------------------------------------------------
        mod.delete()
    end
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.hud.manager",
    group           = "finalcutpro",
    required        = true,
    dependencies    = {
        ["finalcutpro.commands"] = "fcpxCmds",
    }
}

function plugin.init(deps, env)
    --------------------------------------------------------------------------------
    -- Setup Watcher:
    --------------------------------------------------------------------------------
    mod.enabled:watch(mod.update)

    --------------------------------------------------------------------------------
    -- Setup Command:
    --------------------------------------------------------------------------------
    deps.fcpxCmds
        :add("cpHUD")
        :activatedBy():ctrl():option():cmd("a")
        :whenActivated(function() mod.enabled:toggle() end)

    --------------------------------------------------------------------------------
    -- Initalise Module:
    --------------------------------------------------------------------------------
    return mod.init(env)
end

function plugin.postInit()
    mod.update()
end

return plugin