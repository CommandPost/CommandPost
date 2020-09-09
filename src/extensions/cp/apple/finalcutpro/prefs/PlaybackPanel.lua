--- === cp.apple.finalcutpro.prefs.PlaybackPanel ===
---
--- Playback Panel Module.

--local log             = require "hs.logger".new "playbackPanel"

--local inspect         = require "hs.inspect"

local require           = require

local axutils           = require "cp.ui.axutils"
local CheckBox          = require "cp.ui.CheckBox"
local PopUpButton       = require "cp.ui.PopUpButton"
local TextField         = require "cp.ui.TextField"

local Panel             = require "cp.apple.finalcutpro.prefs.Panel"

local childFromTop      = axutils.childFromTop

local PlaybackPanel = Panel:subclass("cp.apple.finalcutpro.prefs.PlaybackPanel")

--- cp.apple.finalcutpro.prefs.PlaybackPanel(preferencesDialog) -> PlaybackPanel
--- Constructor
--- Creates a new `PlaybackPanel` instance.
---
--- Parameters:
---  * parent - The parent object.
---
--- Returns:
---  * A new `PlaybackPanel` object.
function PlaybackPanel:initialize(parent)
    Panel.initialize(self, parent, "PEPlaybackPreferenceName")
end

--- cp.apple.finalcutpro.prefs.PlaybackPanel.backgroundRender <cp.ui.CheckBox>
--- Field
--- The `CheckBox` for "Background render".
function PlaybackPanel.lazy.value:backgroundRender()
    return CheckBox(self, function()
        childFromTop(self:UI(), 1, CheckBox.matches)
    end)
end

--- cp.apple.finalcutpro.prefs.PlaybackPanel.backgroundRenderDelay <cp.ui.TextField>
--- Field
--- The `TextField` for "Background render".
function PlaybackPanel.lazy.value:backgroundRenderDelay()
    return TextField(self, function()
        childFromTop(self:UI(), 1, TextField.matches)
    end, tonumber)
end

--- cp.apple.finalcutpro.prefs.PlaybackPanel.renderShareGPU <cp.ui.PopUpButton>
--- Field
--- The `PopUpButton` for "Render/Share GPU".
function PlaybackPanel.lazy.value:renderShareGPU()
    return PopUpButton(self, function()
        childFromTop(self:UI(), 1, PopUpButton.matches)
    end)
end

--- cp.apple.finalcutpro.prefs.PlaybackPanel.createMulticamOptimizedMedia <cp.ui.CheckBox>
--- Field
--- The `CheckBox` for "Create optimized media for multicam clips".
function PlaybackPanel.lazy.value:createMulticamOptimizedMedia()
    return CheckBox(self, function()
        return childFromTop(self:UI(), 2, CheckBox.matches)
    end)
end

--- cp.apple.finalcutpro.prefs.PlaybackPanel.warnOnFrameDrop <cp.ui.CheckBox>
--- Field
--- The `CheckBox` for "If a frame drops, stop playback and warn".
function PlaybackPanel.lazy.value:warnOnFrameDrop()
    return CheckBox(self, function()
        return childFromTop(self:UI(), 3, CheckBox.matches)
    end)
end

--- cp.apple.finalcutpro.prefs.PlaybackPanel.warnAfterPlaybackOnDiskFrameDrop <cp.ui.CheckBox>
--- Field
--- The `CheckBox` for "If frames drop due to disk performance, warn after playback".
function PlaybackPanel.lazy.value:warnAfterPlaybackOnDiskFrameDrop()
    return CheckBox(self, function()
        return childFromTop(self:UI(), 4, CheckBox.matches)
    end)
end

--- cp.apple.finalcutpro.prefs.PlaybackPanel.warnAfterPlaybackOnVRFrameDrop <cp.ui.CheckBox>
--- Field
--- The `CheckBox` for "If frames drop on VR headset, warn after playback".
function PlaybackPanel.lazy.value:warnAfterPlaybackOnVRFrameDrop()
    return CheckBox(self, function()
        return childFromTop(self:UI(), 5, CheckBox.matches)
    end)
end

--- cp.apple.finalcutpro.prefs.PlaybackPanel.preRollDuration <cp.ui.TextField>
--- Field
--- The `TextField` for "Pre-Roll Duration" in seconds.
function PlaybackPanel.lazy.value:preRollDuration()
    return TextField(self, function()
        childFromTop(self:UI(), 2, TextField.matches)
    end, tonumber)
end

--- cp.apple.finalcutpro.prefs.PlaybackPanel.postRollDuration <cp.ui.TextField>
--- Field
--- The `TextField` for "Post-Roll Duration" in seconds.
function PlaybackPanel.lazy.value:preRollDuration()
    return TextField(self, function()
        childFromTop(self:UI(), 3, TextField.matches)
    end, tonumber)
end

--- cp.apple.finalcutpro.prefs.PlaybackPanel.playerBackground <cp.ui.PopUpButton>
--- Field
--- The `PopUpButton` for "Player Background".
function PlaybackPanel.lazy.value:playerBackground()
    return PopUpButton(self, function()
        childFromTop(self:UI(), 2, PopUpButton.matches)
    end)
end

--- cp.apple.finalcutpro.prefs.PlaybackPanel.avOutput <cp.ui.PopUpButton>
--- Field
--- The `PopUpButton` for "A/V Output".
function PlaybackPanel.lazy.value:avOutput()
    return PopUpButton(self, function()
        childFromTop(self:UI(), 3, PopUpButton.matches)
    end)
end

--- cp.apple.finalcutpro.prefs.PlaybackPanel.showHDRAsToneMapped <cp.ui.CheckBox>
--- Field
--- The `CheckBox` for "Show HDR as Tone Mapped".
function PlaybackPanel.lazy.value:showHDRAsToneMapped()
    return CheckBox(self, function()
        return childFromTop(self:UI(), 6, CheckBox.matches)
    end)
end

return PlaybackPanel
