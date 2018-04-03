--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.prefs.PreferencesWindow ===
---
--- Preferences Window Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
-- local log							= require("hs.logger").new("PrefsDlg")
-- local inspect						= require("hs.inspect")

local axutils						= require("cp.ui.axutils")
local just							= require("cp.just")
local prop							= require("cp.prop")

local PlaybackPanel					= require("cp.apple.finalcutpro.prefs.PlaybackPanel")
local ImportPanel					= require("cp.apple.finalcutpro.prefs.ImportPanel")

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

    local UI = prop(function(self)
        return axutils.cache(self, "_ui", function()
            local windowsUI = self:app():windowsUI()
            return windowsUI and PreferencesWindow._findWindowUI(windowsUI)
        end)
    end)

    prop.bind(o) {
        -- TODO: Add documentation
        UI = UI,

        -- TODO: Add documentation
        isShowing = UI:ISNOT(nil),

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
                return group and #group == 1 and group[1]
            end)
        end),
    }

    return o
end

-- TODO: Add documentation
function PreferencesWindow:app()
    return self._app
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
        if self:app():menuBar():isEnabled({"Final Cut Pro", "Preferences…"}) then
            self:app():menuBar():selectMenu({"Final Cut Pro", "Preferences…"})
            -- wait for it to open.
            just.doUntil(function() return self:UI() end)
        end
    end
    return self
end

-- TODO: Add documentation
function PreferencesWindow:hide()
    local ui = self:UI()
    if ui then
        local closeBtn = axutils.childWith(ui, "AXSubrole", "AXCloseButton")
        if closeBtn then
            closeBtn:doPress()
            -- wait for it to close
            just.doWhile(function() return self:isShowing() end, 5)
        end
    end
    return self
end

return PreferencesWindow