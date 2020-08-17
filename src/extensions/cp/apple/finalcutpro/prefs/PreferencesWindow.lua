--- === cp.apple.finalcutpro.prefs.PreferencesWindow ===
---
--- Preferences Window Module.

local require = require

-- local log							= require "hs.logger" .new("PrefsDlg")

-- local inspect						= require "hs.inspect"

local axutils						= require "cp.ui.axutils"
local just							= require "cp.just"
local go                            = require "cp.rx.go"
local Dialog                        = require "cp.ui.Dialog"
local Group                         = require "cp.ui.Group"
local StaticText                    = require "cp.ui.StaticText"
local Toolbar                       = require "cp.ui.Toolbar"

local GeneralPanel                  = require "cp.apple.finalcutpro.prefs.GeneralPanel"
local EditingPanel                  = require "cp.apple.finalcutpro.prefs.EditingPanel"
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

--- cp.apple.finalcutpro.prefs.PreferencesWindow.title <cp.ui.StaticText>
--- Field
--- The `StaticText` for the Preferences Window title.
function PreferencesWindow.lazy.value:title()
    return StaticText(self, self.UI:mutate(function(original)
        return cache(self, "_title", function()
            return childMatching(original(), StaticText.matches)
        end, StaticText.matches)
    end))
end

--- cp.apple.finalcutpro.prefs.PreferencesWindow.toolbar <cp.ui.Toolbar>
--- Field
--- The `Toolbar` for the Preferences Window.
function  PreferencesWindow.lazy.value:toolbar()
    return Toolbar(self, self.UI:mutate(function(original)
        return cache(self, "_toolbar", function()
            return childMatching(original(), Toolbar.matches)
        end)
    end))
end

--- cp.apple.finalcutpro.prefs.PreferencesWindow.generalPanel <GeneralPanel>
--- Field
--- The `GeneralPanel` for the Preferences Window.
function PreferencesWindow.lazy.value:generalPanel()
    return GeneralPanel(self)
end

--- cp.apple.finalcutpro.prefs.PreferencesWindow.editingPanel <EditingPanel>
--- Field
--- The `EditingPanel` for the Preferences Window.
function PreferencesWindow.lazy.value:editingPanel()
    return EditingPanel(self)
end

--- cp.apple.finalcutpro.prefs.PreferencesWindow.playbackPanel <PlaybackPanel>
--- Field
--- The `PlaybackPanel` for the Preferences Window.
function PreferencesWindow.lazy.value:playbackPanel()
    return PlaybackPanel(self)
end

--- cp.apple.finalcutpro.prefs.PreferencesWindow.importPanel <ImportPanel>
--- Field
--- The `ImportPanel` for the Preferences Window.
function PreferencesWindow.lazy.value:importPanel()
    return ImportPanel(self)
end

--- cp.apple.finalcutpro.prefs.PreferencesWindow:show() -> PreferencesWindow
--- Method
--- Attempts to show the Preferences window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The same `PreferencesWindow`, for chaining.
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

--- cp.apple.finalcutpro.prefs.PreferencesWindow:doShow() -> cp.rx.go.Statement
--- Method
--- A `Statement` that attempts to show the Preferences window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement`.
function PreferencesWindow.lazy.method:doShow()
    return If(self.isShowing):Is(false):Then(
        self:app().menu:doSelectMenu({"Final Cut Pro", "Preferences…"})
    ):Then(
        WaitUntil(self.isShowing)
    )
end

--- cp.apple.finalcutpro.prefs.PreferencesWindow:hide() -> PreferencesWindow
--- Method
--- Attempts to hide the Preferences window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The same `PreferencesWindow`, for chaining.
function PreferencesWindow:hide()
    local hsWindow = self:hsWindow()
    if hsWindow then
        hsWindow:close()
        -- wait for it to close, up to 5 seconds
        just.doWhile(function() return self:isShowing() end, 5)
    end
    return self
end

--- cp.apple.finalcutpro.prefs.PreferencesWindow:doHide() -> cp.rx.go.Statement
--- Method
--- A `Statement` that attempts to hide the Preferences window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement`.
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
