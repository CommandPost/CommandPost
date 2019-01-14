--- === cp.apple.finalcutpro.prefs.PreferencesWindow ===
---
--- Preferences Window Module.

local require = require

-- local log							= require("hs.logger").new("PrefsDlg")

-- local inspect						= require("hs.inspect")

local axutils						= require("cp.ui.axutils")
local just							= require("cp.just")
local prop							= require("cp.prop")
local go                            = require("cp.rx.go")
local Window                        = require("cp.ui.Window")
local Toolbar                       = require("cp.ui.Toolbar")

local PlaybackPanel					= require("cp.apple.finalcutpro.prefs.PlaybackPanel")
local ImportPanel					= require("cp.apple.finalcutpro.prefs.ImportPanel")

local If, WaitUntil                 = go.If, go.WaitUntil

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local PreferencesWindow = {}

function PreferencesWindow.matches(element)
    return element:attributeValue("AXSubrole") == "AXDialog"
        and not element:attributeValue("AXModal")
        and element:attributeValue("AXTitle") ~= ""
        and axutils.childWithRole(element, "AXToolbar") ~= nil
        and axutils.childWithRole(element, "AXGroup") ~= nil
end

-- TODO: Add documentation
function PreferencesWindow._findWindowUI(windows)
    return axutils.childMatching(windows, PreferencesWindow.matches)
end

-- TODO: Add documentation
function PreferencesWindow.new(app)
    local o = prop.extend({_app = app}, PreferencesWindow)

    local UI = app.windowsUI:mutate(function(original, self)
        return axutils.cache(self, "_ui", function()
            local windowsUI = original()
            return windowsUI and PreferencesWindow._findWindowUI(windowsUI)
        end)
    end)

    -- provides access to common AXWindow properties.
    local window = Window(app.app, UI)
    o._window = window


    prop.bind(o) {
--- cp.apple.finalcutpro.prefs.PreferencesWindow.UI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- The `axuielement` instance for the window.
        UI = UI,

--- cp.apple.finalcutpro.prefs.PreferencesWindow.hsWindow <cp.prop: hs.window; read-only>
--- Field
--- The `hs.window` instance for the window, or `nil` if it can't be found.
        hsWindow = window.hsWindow,

--- cp.apple.finalcutpro.prefs.PreferencesWindow.isShowing <cp.prop: boolean; live>
--- Field
--- Is `true` if the window is visible.
        isShowing = window.visible,

--- cp.apple.finalcutpro.prefs.PreferencesWindow.isFullScreen <cp.prop: boolean; live>
--- Field
--- Is `true` if the window is full-screen.
        isFullScreen = window.fullScreen,

--- cp.apple.finalcutpro.prefs.PreferencesWindow.frame <cp.prop: frame; live>
--- Field
--- The current position (x, y, width, height) of the window.
        frame = window.frame,

        -- TODO: Add documentation
        -- Returns the UI for the AXToolbar containing this panel's buttons
        toolbarUI = UI:mutate(function(original, self)
            return axutils.cache(self, "_toolbar", function()
                local ax = original()
                return ax and axutils.childWithRole(ax, "AXToolbar") or nil
            end)
        end),

        -- TODO: Add documentation
        -- Returns the UI for the AXGroup containing this panel's elements
        groupUI = UI:mutate(function(original, self)
            return axutils.cache(self, "_group", function()
                local ui = original()
                local group = ui and axutils.childWithRole(ui, "AXGroup")
                -- The group conains another single group that contains the actual checkboxes, etc.
                return group and #group == 1 and group[1] or nil
            end)
        end),
    }

--- cp.apple.finalcutpro.prefs.PreferencesWindow.toolbar <cp.ui.Toolbar>
--- Field
--- The `Toolbar` for the Preferences Window.
    o.toolbar = Toolbar(o, o.toolbarUI)

    return o
end

-- TODO: Add documentation
function PreferencesWindow:app()
    return self._app
end

--- cp.apple.finalcutpro.prefs.PreferencesWindow:window() -> cp.ui.Window
--- Method
--- Returns the `Window` for the Preferences Window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Window`.
function PreferencesWindow:window()
    return self._window
end

-- TODO: Add documentation
function PreferencesWindow:playbackPanel()
    if not self._playbackPanel then
        self._playbackPanel = PlaybackPanel.new(self)
    end
    return self._playbackPanel
end

-- TODO: Add documentation
function PreferencesWindow:importPanel()
    if not self._importPanel then
        self._importPanel = ImportPanel.new(self)
    end
    return self._importPanel
end

-- TODO: Add documentation
-- Ensures the PreferencesWindow is showing
function PreferencesWindow:show()
    if not self:isShowing() then
        -- open the window
        if self:app():menu():isEnabled({"Final Cut Pro", "Preferences…"}) then
            self:app():menu():selectMenu({"Final Cut Pro", "Preferences…"})
            -- wait for it to open.
            just.doUntil(function() return self:UI() end)
        end
    end
    return self
end

function PreferencesWindow:doShow()
    return If(self.isShowing):Is(false):Then(
        self:app():menu():doSelectMenu({"Final Cut Pro", "Preferences…"})
    ):Then(
        WaitUntil(self.isShowing)
    )
end

-- TODO: Add documentation
function PreferencesWindow:hide()
    local hsWindow = self:hsWindow()
    if hsWindow then
        hsWindow:close()
        -- wait for it to close, up to 5 seconds
        just.doWhile(function() return self:isShowing() end, 5)
    end
    return self
end

function PreferencesWindow:doHide()
    return If(self.isShowing)
    :Then(function()
        self:hsWindow():close()
    end)
    :Then(
        WaitUntil(self.isShowing):Is(false)
    )
end

return PreferencesWindow
