--- === cp.apple.finalcutpro.prefs.EditingPanel ===
---
--- Editing Panel Module.

local require = require

-- local log								= require "hs.logger".new("importPanel")

-- local inspect							= require "hs.inspect"

local axutils							= require "cp.ui.axutils"
local CheckBox							= require "cp.ui.CheckBox"
local TextField                         = require "cp.ui.TextField"

local Panel                             = require "cp.apple.finalcutpro.prefs.Panel"

local childFromTop                      = axutils.childFromTop

local EditingPanel = Panel:subclass("cp.apple.finalcutpro.prefs.EditingPanel")

--- cp.apple.finalcutpro.prefs.EditingPanel(preferencesDialog) -> EditingPanel
--- Constructor
--- Creates a new `EditingPanel` instance.
---
--- Parameters:
---  * parent - The parent object.
---
--- Returns:
---  * A new `EditingPanel` object.
function EditingPanel:initialize(preferencesDialog)
    Panel.initialize(self, preferencesDialog, "PEEditingPreferenceName")
end

--- cp.apple.finalcutpro.prefs.EditingPanel.showDetailedTrimmingFeedback <cp.ui.CheckBox>
--- Field
--- The "Show detailed trimming feedback" `CheckBox`.
function EditingPanel.lazy.value:showDetailedTrimmingFeedback()
    return CheckBox(self, function()
        return childFromTop(self:UI(), 1, CheckBox.matches)
    end)
end

--- cp.apple.finalcutpro.prefs.EditingPanel.positionPlayheadAfterEditOperation <cp.ui.CheckBox>
--- Field
--- The "Position playhead after edit operation" `CheckBox`.
function EditingPanel.lazy.value:positionPlayheadAfterEditOperation()
    return CheckBox(self, function()
        return childFromTop(self:UI(), 2, CheckBox.matches)
    end)
end

--- cp.apple.finalcutpro.prefs.EditingPanel.showReferenceWaveforms <cp.ui.CheckBox>
--- Field
--- The "Show reference waveforms" `CheckBox`.
function EditingPanel.lazy.value:showReferenceWaveforms()
    return CheckBox(self, function()
        return childFromTop(self:UI(), 3, CheckBox.matches)
    end)
end

--- cp.apple.finalcutpro.prefs.EditingPanel.audioFadeDuration <cp.ui.TextField: number>
--- Field
--- The "Audio Fade Duration" `TextField` with a `number` value.
function EditingPanel.lazy.value:audioFadeDuration()
    return TextField(self, function()
        return childFromTop(self:UI(), 1, TextField.matches)
    end, tonumber)
end

--- cp.apple.finalcutpro.prefs.EditingPanel.stillImageDuration <cp.ui.TextField: number>
--- Field
--- The "Still image Duration" `TextField` with a `number` value.
function EditingPanel.lazy.value:stillImageDuration()
    return TextField(self, function()
        return childFromTop(self:UI(), 2, TextField.matches)
    end, tonumber)
end

--- cp.apple.finalcutpro.prefs.EditingPanel.transitionDuration <cp.ui.TextField: number>
--- Field
--- The "Transition Duration" `TextField` with a `number` value.
function EditingPanel.lazy.value:transitionDuration()
    return TextField(self, function()
        return childFromTop(self:UI(), 3, TextField.matches)
    end, tonumber)
end

return EditingPanel
