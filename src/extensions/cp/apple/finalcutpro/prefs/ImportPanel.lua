--- === cp.apple.finalcutpro.prefs.ImportPanel ===
---
--- Import Panel Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

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
local just								= require("cp.just")
local go                                = require("cp.rx.go")
local axutils							= require("cp.ui.axutils")
local CheckBox							= require("cp.ui.CheckBox")
local RadioButton						= require("cp.ui.RadioButton")

local id								= require("cp.apple.finalcutpro.ids") "ImportPanel"

local Panel                             = require("cp.apple.finalcutpro.prefs.Panel")
local Do, If                            = go.Do, go.If

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local ImportPanel = {}
ImportPanel.mt = setmetatable({}, Panel.mt)
ImportPanel.mt.__index = ImportPanel.mt

-- TODO: Add documentation
function ImportPanel.new(preferencesDialog)
    local o = Panel.new(preferencesDialog, "PEImportPreferenceName", ImportPanel.mt)

    return o
end

-- TODO: Add documentation
function ImportPanel.mt:parent()
    return self._parent
end

-- TODO: Add documentation
function ImportPanel.mt:show()
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

function ImportPanel.mt:hide()
    return self:parent():hide()
end

function ImportPanel.mt:createProxyMedia()
    if not self._createProxyMedia then
        self._createProxyMedia = CheckBox(self, function()
            return axutils.childFromTop(axutils.childrenWithRole(self:contentsUI(), "AXCheckBox"), id "CreateProxyMedia")
        end)
    end
    return self._createProxyMedia
end

function ImportPanel.mt:createOptimizedMedia()
    if not self._createOptimizedMedia then
        self._createOptimizedMedia = CheckBox(self, function()
            return axutils.childFromTop(axutils.childrenWithRole(self:contentsUI(), "AXCheckBox"), id "CreateOptimizedMedia")
        end)
    end
    return self._createOptimizedMedia
end

function ImportPanel.mt:mediaLocationGroupUI()
    return axutils.cache(self, "_mediaLocationGroup", function()
        return axutils.childFromTop(axutils.childrenWithRole(self:contentsUI(), "AXRadioGroup"), id "MediaLocationGroup")
    end)
end

function ImportPanel.mt:copyToMediaFolder()
    if not self._copyToMediaFolder then
        self._copyToMediaFolder = RadioButton(self, function()
            local groupUI = self:mediaLocationGroupUI()
            return groupUI and groupUI[id "CopyToMediaFolder"]
        end)
    end
    return self._copyToMediaFolder
end

function ImportPanel.mt:leaveInPlace()
    if not self._leaveInPlace then
        self._leaveInPlace = RadioButton(self, function()
            local groupUI = self:mediaLocationGroupUI()
            return groupUI and groupUI[id "LeaveInPlace"]
        end)
    end
    return self._leaveInPlace
end

-- TODO: Add documentation
function ImportPanel.mt:toggleMediaLocation()
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

function ImportPanel.mt:doToggleMediaLocation()
    return Do(self:doShow())
    :Then(
        If(self:copyToMediaFolder().checked)
        :Then(function()
            self:leaveInPlace():checked(true)
        end)
        :Otherwise(function()
            self:copyToMediaFolder():checked(true)
        end)
    )
end

return ImportPanel
