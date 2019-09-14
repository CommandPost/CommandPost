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

local app           = require("cp.app")
local config        = require("cp.config")
local dialog        = require("cp.dialog")
local fcp           = require("cp.apple.finalcutpro")
local i18n          = require("cp.i18n")
local just          = require("cp.just")
local tools         = require("cp.tools")

local moses         = require("moses")
local panel         = require("panel")

local doAfter       = timer.doAfter
local forBundleID   = app.forBundleID
local processInfo   = hs.processInfo
local sortedIndex   = moses.sortedIndex
local waitUntil     = timer.waitUntil

local mod = {}

-- SNAPPING_RANGE -> number
-- Constant
-- The amount of leeway when it comes to window snapping.
local SNAPPING_RANGE = 30

-- WEBVIEW_LABEL -> string
-- Constant
-- The webview Label.
local WEBVIEW_LABEL = "hud"

-- FCP_BUNDLE_ID -> string
-- Constant
-- Cached Final Cut Pro Bundle ID.
local FCP_BUNDLE_ID = fcp:bundleID()

-- CP_BUNDLE_ID -> string
-- Constant
-- Cached CommandPost Bundle ID.
local CP_BUNDLE_ID = config.bundleID

-- UNKNOWN_WORKSPACE -> string
-- Constant
-- The ID used when we can't detect a workspace name for some reason.
local UNKNOWN_WORKSPACE = "Unknown Workspace"

-- cpApp -> cp.app
-- Variable
-- CommandPost App
local cpApp = forBundleID(processInfo.bundleID)

--- plugins.finalcutpro.hud.manager.enabled <cp.prop: boolean>
--- Field
--- Is the HUD enabled in the settings?
mod.enabled = config.prop("hub.enabled", false)

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
mod.position = config.prop("fcp.hud.position", {})

--- plugins.finalcutpro.hud.manager.position
--- Constant
--- Returns the last frame saved in settings.
mod.workspace = config.prop("fcp.hud.workspace", nil)

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
    return WEBVIEW_LABEL
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
    env.webviewLabel = WEBVIEW_LABEL

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
            --------------------------------------------------------------------------------
            -- Window Snapping:
            --------------------------------------------------------------------------------
            local timelineUI = fcp:timeline():UI()
            local timelineFrame = timelineUI and timelineUI:attributeValue("AXFrame")

            local browserUI = fcp:browser():UI()
            local browserFrame = browserUI and browserUI:attributeValue("AXFrame")

            local inspectorUI = fcp:inspector():UI()
            local inspectorFrame = inspectorUI and inspectorUI:attributeValue("AXFrame")

            local newFrame = frame

            if timelineFrame then
                --------------------------------------------------------------------------------
                -- Snap to top of timeline frame:
                --------------------------------------------------------------------------------
                if frame.y >= (timelineFrame.y - SNAPPING_RANGE) and frame.y <= (timelineFrame.y + SNAPPING_RANGE) then
                    newFrame = {
                        x = newFrame.x,
                        y = timelineFrame.y,
                        w = newFrame.w,
                        h = newFrame.h
                    }
                end

                --------------------------------------------------------------------------------
                -- Snap to bottom of timeline frame:
                --------------------------------------------------------------------------------
                if (frame.y + frame.h) >= (timelineFrame.y - SNAPPING_RANGE) and (frame.y + frame.h) <= (timelineFrame.y + SNAPPING_RANGE) then
                    newFrame = {
                        x = newFrame.x,
                        y = timelineFrame.y - newFrame.h,
                        w = newFrame.w,
                        h = newFrame.h
                    }
                end
            else
                --------------------------------------------------------------------------------
                -- We only need to snap to the browser frame if the timeline frame isn't visible:
                --------------------------------------------------------------------------------
                if browserFrame then
                    --------------------------------------------------------------------------------
                    -- Snap to top of browser frame:
                    --------------------------------------------------------------------------------
                    if frame.y >= (browserFrame.y - SNAPPING_RANGE) and frame.y <= (browserFrame.y + SNAPPING_RANGE) then
                        newFrame = {
                            x = newFrame.x,
                            y = browserFrame.y,
                            w = newFrame.w,
                            h = newFrame.h
                        }
                    end

                    --------------------------------------------------------------------------------
                    -- Snap to bottom of browser frame:
                    --------------------------------------------------------------------------------
                    if (frame.y + frame.h) >= (browserFrame.y - SNAPPING_RANGE) and (frame.y + frame.h) <= (browserFrame.y + SNAPPING_RANGE) then
                        newFrame = {
                            x = newFrame.x,
                            y = browserFrame.y - newFrame.h,
                            w = newFrame.w,
                            h = newFrame.h
                        }
                    end
                end

                --------------------------------------------------------------------------------
                -- We only need to snap to the inspector frame if the timeline frame isn't visible:
                --------------------------------------------------------------------------------
                if inspectorFrame then
                    --------------------------------------------------------------------------------
                    -- Snap to top of inspector frame:
                    --------------------------------------------------------------------------------
                    if frame.y >= (inspectorFrame.y - SNAPPING_RANGE) and frame.y <= (inspectorFrame.y + SNAPPING_RANGE) then
                        newFrame = {
                            x = newFrame.x,
                            y = inspectorFrame.y,
                            w = newFrame.w,
                            h = newFrame.h
                        }
                    end

                    --------------------------------------------------------------------------------
                    -- Snap to bottom of inspector frame:
                    --------------------------------------------------------------------------------
                    if (frame.y + frame.h) >= (inspectorFrame.y - SNAPPING_RANGE) and (frame.y + frame.h) <= (inspectorFrame.y + SNAPPING_RANGE) then
                        newFrame = {
                            x = newFrame.x,
                            y = inspectorFrame.y - newFrame.h,
                            w = newFrame.w,
                            h = newFrame.h
                        }
                    end
                end


            end
            if browserFrame then
                --------------------------------------------------------------------------------
                -- Snap to left of browser frame:
                --------------------------------------------------------------------------------
                if frame.x >= ((browserFrame.x + browserFrame.w) - SNAPPING_RANGE) and frame.x <= ((browserFrame.x + browserFrame.w) + SNAPPING_RANGE) then
                    newFrame = {
                        x = browserFrame.x + browserFrame.w,
                        y = newFrame.y,
                        w = newFrame.w,
                        h = newFrame.h
                    }
                end

                --------------------------------------------------------------------------------
                -- Snap to right of browser frame:
                --------------------------------------------------------------------------------
                if (frame.x + frame.w) >= ((browserFrame.x + browserFrame.w) - SNAPPING_RANGE) and (frame.x + frame.w) <= ((browserFrame.x + browserFrame.w) + SNAPPING_RANGE) then
                    newFrame = {
                        x = (browserFrame.x + browserFrame.w) - newFrame.w,
                        y = newFrame.y,
                        w = newFrame.w,
                        h = newFrame.h
                    }
                end
            end
            if inspectorFrame then
                --------------------------------------------------------------------------------
                -- Snap to left of inspector frame:
                --------------------------------------------------------------------------------
                if frame.x >= (inspectorFrame.x - SNAPPING_RANGE) and frame.x <= (inspectorFrame.x + SNAPPING_RANGE) then
                    newFrame = {
                        x = inspectorFrame.x,
                        y = newFrame.y,
                        w = newFrame.w,
                        h = newFrame.h
                    }
                end

                --------------------------------------------------------------------------------
                -- Snap to right of inspector frame:
                --------------------------------------------------------------------------------
                if (frame.x + frame.w) >= (inspectorFrame.x - SNAPPING_RANGE) and (frame.x + frame.w) <= (inspectorFrame.x + SNAPPING_RANGE) then
                    newFrame = {
                        x = inspectorFrame.x - newFrame.w,
                        y = newFrame.y,
                        w = newFrame.w,
                        h = newFrame.h
                    }
                end

            end
            if not tools.tableMatch(frame, newFrame) then
                mod._webview:frame(newFrame)
            end

            --------------------------------------------------------------------------------
            -- Save Frame Position Data per Workspace:
            --------------------------------------------------------------------------------
            local id = fcp:selectedWorkspace() or UNKNOWN_WORKSPACE
            local position = mod.position()
            position[id] = {
                x = frame.x,
                y = frame.y,
            }
            mod.position(position)
            mod.workspace(id)
        end
    end
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

-- centredPosition() -> table
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

-- navigationCallback(action) -> none
-- Function
-- Navigation Callback for the webview
--
-- Parameters:
--  * action - a string indicating the webview's current status
--
-- Returns:
--  * None
local function navigationCallback(action)
    if action == "didFinishNavigation" then
        --------------------------------------------------------------------------------
        -- Trigger the Loaded Function:
        --------------------------------------------------------------------------------
        for _, thePanel in ipairs(mod._panels) do
            if thePanel.id == mod.currentPanelID() then
                if thePanel.loadedFn and type(thePanel.loadedFn) == "function" then
                    thePanel.loadedFn()
                end
            end
        end
    end
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
    local id = fcp:selectedWorkspace() or mod.workspace() or UNKNOWN_WORKSPACE
    local defaultRect = centredPosition()
    local position = mod.position()
    local p = position and position[id]
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
        mod._controller = webview.usercontent.new(WEBVIEW_LABEL)
            :setCallback(function(message)
                local body = message.body
                local bodyID = body.id
                local params = body.params

                local handler = mod.getHandler(bodyID)
                if handler then
                    return handler(bodyID, params)
                end
            end)
    end

    --------------------------------------------------------------------------------
    -- Setup Tool Bar:
    --------------------------------------------------------------------------------
    if not mod._toolbar then
        mod._toolbar = toolbar.new(WEBVIEW_LABEL)
            :canCustomize(true)
            :autosaves(true)
            :setCallback(function(_, _, cbID)
                waitUntil(function() return not mod._webview:loading() end, function()
                    mod.refresh(cbID)
                end, 0.01)
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
            :navigationCallback(navigationCallback)
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
        mod.showing = true
    end

    return true
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
        mod.showing = false
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
        mod.showing = false
    end
end

--- plugins.finalcutpro.hud.manager.resize()
--- Function
--- Resizes the HUD.
---
--- Parameters:
---  * height - The new height of the HUD as number.
---
--- Returns:
---  * None
function mod.resize(height)
    if mod._webview then
        local size = mod._webview:size()
        size.h = height
        mod._webview:size(size)

        local frame = mod._webview:frame()
        mod._frameUUID = frame.w + frame.h
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
function mod.refresh(id)
    if mod._webview then
        if mod.currentPanelID() ~= id then
            mod.selectPanel(id)

            mod._webview:html(generateHTML())

            local frame = mod._webview:frame()
            mod._frameUUID = frame.w + frame.h
        end
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
    if mod._webview and mod._webview:frame() and script and script ~= "" then
        mod._webview:evaluateJavaScript(script, function(_, theerror)
            if theerror and theerror.code ~= 0 then
                log.ef("Javascript Error: %s\nCaused by script: %s", inspect(theerror), script)
            end
        end)
    end
end

--- plugins.finalcutpro.hud.manager.selectPanel([id]) -> none
--- Function
--- Selects a HUD Panel.
---
--- Parameters:
---  * id - the optional ID of the panel you want to select. If no ID is supplied then
---         the current panel ID will be used.
---
--- Returns:
---  * None
function mod.selectPanel(id)

    if not mod._webview then return end

    local currentPanelID = mod.currentPanelID()
    id = id or currentPanelID

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

            --------------------------------------------------------------------------------
            -- Allow for different toolbar heights:
            --------------------------------------------------------------------------------
            local offset = 0
            local theToolbar = mod._toolbar
            local displayMode = theToolbar and theToolbar:displayMode()   --"default", "label", "icon", or "both".
            local sizeMode = theToolbar and theToolbar:sizeMode()         --"default", "regular", or "small".

            if displayMode == "icon" and sizeMode == "small" then
                offset = -5
            elseif displayMode == "icon" and sizeMode == "regular" then
                offset = 5
            elseif displayMode == "both" and sizeMode == "regular" then
                offset = 17
            elseif displayMode == "both" and sizeMode == "small" then
                offset = 10
            elseif displayMode == "label" and sizeMode == "regular" then
                offset = -20
            elseif displayMode == "label" and sizeMode == "small" then
                offset = -22
            end
            height = height + offset

            mod._webview:size({w = mod.DEFAULT_WIDTH, h = height })
        end

        --------------------------------------------------------------------------------
        -- Trigger Panel Open & Close Callbacks:
        --------------------------------------------------------------------------------
        if thePanel.id == id then
            if thePanel.openFn and type(thePanel.openFn) == "function" then
                thePanel.openFn()
            end
        end
        if id ~= currentPanelID and thePanel.id == currentPanelID then
            if thePanel.closeFn and type(thePanel.closeFn) == "function" then
                thePanel.closeFn()
            end
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
---  ** `openFn`        - A callback function that's triggered when the panel is opened.
---  ** `closeFn`       - A callback function that's triggered when the panel is closed.
---  ** `loadedFn`      - A callback function that's triggered when the panel is loaded.
function mod.addPanel(params)
    local newPanel = panel.new(params, mod)
    local index = sortedIndex(mod._panels, newPanel, comparePriorities)
    table.insert(mod._panels, index, newPanel)
    return newPanel
end

local function showOrHideHUD()
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
end

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
    doAfter(0.000000000001, function()
        showOrHideHUD()
        doAfter(0.5, showOrHideHUD)
    end)
end

--- plugins.finalcutpro.hud.manager.updatePosition() -> none
--- Function
--- Updates the HUD position.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.updatePosition()
    local id = fcp:selectedWorkspace() or mod.workspace()
    if id and mod._webview then
        local f = mod._webview:frame()
        local position = mod.position()
        local p = position and position[id]
        if p and f then
            local newFrame = {
                x = p.x,
                y = p.y,
                w = f.w,
                h = f.h
            }
            if not tools.isOffScreen(newFrame) then
                mod._webview:frame(newFrame)
            end
        end
    end
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

        fcp.selectedWorkspace:watch(mod.updatePosition)

        --------------------------------------------------------------------------------
        -- Update Visibility:
        --------------------------------------------------------------------------------
        mod.updateVisibility()
    else
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

        fcp.selectedWorkspace:unwatch(mod.updatePosition)

        --------------------------------------------------------------------------------
        -- Destroy the HUD:
        --------------------------------------------------------------------------------
        mod.delete()
    end
end

local plugin = {
    id              = "finalcutpro.hud.manager",
    group           = "finalcutpro",
    required        = true,
    dependencies    = {
        ["finalcutpro.commands"] = "fcpxCmds",
        ["finalcutpro.menu.manager"] = "menu",
    }
}

function plugin.init(deps, env)

    --------------------------------------------------------------------------------
    -- Setup Menus:
    --------------------------------------------------------------------------------
   deps.menu.tools
        :addItem(10000, function()
            return { title = i18n("enableHUD"), fn = function() mod.enabled:toggle() end, checked = mod.enabled()}
        end)

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
    -- Set Panel Renderer:
    --------------------------------------------------------------------------------
    mod._panelRenderer = env:compileTemplate("html/panels.html")

    return mod
end

function plugin.postInit()
    mod.update()
end

return plugin
