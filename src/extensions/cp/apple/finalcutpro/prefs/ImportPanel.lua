--- === cp.apple.finalcutpro.prefs.ImportPanel ===
---
--- Import Panel Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log								= require("hs.logger").new("importPanel")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
-- local inspect							= require("hs.inspect")
--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils							= require("cp.ui.axutils")
local CheckBox							= require("cp.ui.CheckBox")
local just								= require("cp.just")
local prop								= require("cp.prop")
local RadioButton						= require("cp.ui.RadioButton")

local id								= require("cp.apple.finalcutpro.ids") "ImportPanel"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local ImportPanel = {}

-- TODO: Add documentation
function ImportPanel.new(preferencesDialog)
    local o = prop.extend({_parent = preferencesDialog}, ImportPanel)

    -- TODO: Add documentation
    local UI = prop(function(self)
        return axutils.cache(self, "_ui", function()
            return axutils.childFromLeft(self:parent():toolbarUI(), id "ID")
        end)
    end)

    -- TODO: Add documentation
    local isShowing = prop.new(function(self)
        local toolbar = self:parent():toolbarUI()
        if toolbar then
            local selected = toolbar:selectedChildren()
            return #selected == 1 and selected[1] == self:UI()
        end
        return false
    end)

    prop.bind(o) {
        UI = UI, isShowing = isShowing,

        contentsUI = prop.OR(isShowing:AND(preferencesDialog.groupUI), prop.NIL),
    }

    return o
end

-- TODO: Add documentation
function ImportPanel:parent()
    return self._parent
end

-- TODO: Add documentation
function ImportPanel:show()
    local parent = self:parent()
    -- show the parent.
    if parent:show():isShowing() then
        -- get the toolbar UI
        local panel = just.doUntil(function() return self:UI() end)
        if panel then
            panel:doPress()
            just.doUntil(function() return self:isShowing() end)
        end
    end
    return self
end

function ImportPanel:hide()
    return self:parent():hide()
end

function ImportPanel:createProxyMedia()
    if not self._createProxyMedia then
        self._createProxyMedia = CheckBox.new(self, function()
            return axutils.childFromTop(axutils.childrenWithRole(self:contentsUI(), "AXCheckBox"), id "CreateProxyMedia")
        end)
    end
    return self._createProxyMedia
end

function ImportPanel:createOptimizedMedia()
    if not self._createOptimizedMedia then
        self._createOptimizedMedia = CheckBox.new(self, function()
            return axutils.childFromTop(axutils.childrenWithRole(self:contentsUI(), "AXCheckBox"), id "CreateOptimizedMedia")
        end)
    end
    return self._createOptimizedMedia
end

function ImportPanel:mediaLocationGroupUI()
    return axutils.cache(self, "_mediaLocationGroup", function()
        return axutils.childFromTop(axutils.childrenWithRole(self:contentsUI(), "AXRadioGroup"), id "MediaLocationGroup")
    end)
end

function ImportPanel:copyToMediaFolder()
    if not self._copyToMediaFolder then
        self._copyToMediaFolder = RadioButton.new(self, function()
            local groupUI = self:mediaLocationGroupUI()
            return groupUI and groupUI[id "CopyToMediaFolder"]
        end)
    end
    return self._copyToMediaFolder
end

function ImportPanel:leaveInPlace()
    if not self._leaveInPlace then
        self._leaveInPlace = RadioButton.new(self, function()
            local groupUI = self:mediaLocationGroupUI()
            return groupUI and groupUI[id "LeaveInPlace"]
        end)
    end
    return self._leaveInPlace
end

-- TODO: Add documentation
function ImportPanel:toggleMediaLocation()
    if self:show():isShowing() then
        if self:copyToMediaFolder():checked() then
            self:leaveInPlace():checked(true)
        else
            self:copyToMediaFolder():checked(true)
        end
        return true
    end
    return false
end

return ImportPanel