--- === cp.apple.finalcutpro.prefs.PreferencesWindow ===
---
--- Preferences Window Module.

local require = require

-- local log							= require "hs.logger" .new("PrefsDlg")

-- local inspect						= require "hs.inspect"

local axutils						= require "cp.ui.axutils"
local just							= require "cp.just"
local prop							= require "cp.prop"
local go                            = require "cp.rx.go"
local Dialog                        = require "cp.ui.Dialog"
local Group                         = require "cp.ui.Group"
local Toolbar                       = require "cp.ui.Toolbar"

local GeneralPanel                  = require "cp.apple.finalcutpro.prefs.GeneralPanel"
local PlaybackPanel					= require "cp.apple.finalcutpro.prefs.PlaybackPanel"
local ImportPanel					= require "cp.apple.finalcutpro.prefs.ImportPanel"

local cache                         = axutils.cache
local childMatching                 = axutils.childMatching

local If, WaitUntil                 = go.If, go.WaitUntil

local PreferencesWindow = Dialog:subclass("cp.apple.finalcutpro.prefs.PreferencesWindow")

function PreferencesWindow.static.matches(element)
    return Dialog.matches(element)
        and not element:attributeValue("AXModal")
        and element:attributeValue("AXTitle") ~= ""
        and childMatching(element, Toolbar.matches) ~= nil
        and childMatching(element, Group.matches) ~= nil
end

-- TODO: Add documentation
function PreferencesWindow:initialize(app)
    local UI = app.windowsUI:mutate(function(original)
        return cache(self, "_ui", function()
            return childMatching(original(), PreferencesWindow.matches)
        end)
    end)

    Dialog.initialize(self, app.app, UI)
end

-- TODO: Add documentation
-- Returns the UI for the AXToolbar containing this panel's buttons
function PreferencesWindow.lazy.prop:toolbarUI()
    return UI:mutate(function(originalelf)
        return cache(self, "_toolbar", function()
            return childMatching(original(), Toolbar.matches)
        end)
    end)
end

-- TODO: Add documentation
-- Returns the UI for the AXGroup containing this panel's elements
function PreferencesWindow.lazy.prop:groupUI()
    return UI:mutate(function(original)
        return cache(self, "_group", function()
            local group = childMatching(original(), Group.matches)
            -- The group conains another single group that contains the actual checkboxes, etc.
            return group and #group == 1 and group[1] or nil
        end)
    end)
end

--- cp.apple.finalcutpro.prefs.PreferencesWindow.toolbar <cp.ui.Toolbar>
--- Field
--- The `Toolbar` for the Preferences Window.
function  PreferencesWindow.lazy.value:toolbar()
    return Toolbar(self, self.toolbarUI)
end

-- TODO: Add documentation
function PreferencesWindow.lazy.value:playbackPanel()
    return PlaybackPanel.new(self)
end

-- TODO: Add documentation
function PreferencesWindow.lazy.value:importPanel()
    return ImportPanel.new(self)
end

-- TODO: Add documentation
function PreferencesWindow.lazy.value:generalPanel()
    return GeneralPanel.new(self)
end

-- TODO: Add documentation
-- Ensures the PreferencesWindow is showing
function PreferencesWindow:show()
    if not self:isShowing() then
        -- open the window
        if self:app().menu:isEnabled({"Final Cut Pro", "Preferences…"}) then
            self:app().menu:selectMenu({"Final Cut Pro", "Preferences…"})
            -- wait for it to open.
            just.doUntil(function() return self:UI() end)
        end
    end
    return self
end

function PreferencesWindow.lazy.method:doShow()
    return If(self.isShowing):Is(false):Then(
        self:app().menu:doSelectMenu({"Final Cut Pro", "Preferences…"})
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

function PreferencesWindow.lazy.method:doHide()
    return If(self.isShowing)
    :Then(function()
        self:hsWindow():close()
    end)
    :Then(
        WaitUntil(self.isShowing):Is(false)
    )
end

return PreferencesWindow
