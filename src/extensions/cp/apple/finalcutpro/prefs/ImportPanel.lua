--- === cp.apple.finalcutpro.prefs.ImportPanel ===
---
--- Import Panel Module.

local require = require

-- local log								= require "hs.logger".new("importPanel")

-- local inspect							= require "hs.inspect"
local go                                = require "cp.rx.go"

local axutils							= require "cp.ui.axutils"
local CheckBox							= require "cp.ui.CheckBox"
local PopUpButton                       = require "cp.ui.PopUpButton"
local RadioButton                       = require "cp.ui.RadioButton"

local Panel                             = require "cp.apple.finalcutpro.prefs.Panel"

local cache                             = axutils.cache
local childFromTop                      = axutils.childFromTop

local Do, If                            = go.Do, go.If

local ImportPanel = Panel:subclass("cp.apple.finalcutpro.prefs.ImportPanel")

--- cp.apple.finalcutpro.prefs.ImportPanel(preferencesDialog) -> ImportPanel
--- Constructor
--- Creates a new `ImportPanel` instance.
---
--- Parameters:
---  * parent - The parent object.
---
--- Returns:
---  * A new `ImportPanel` object.
function ImportPanel:initialize(preferencesDialog)
    Panel.initialize(self, preferencesDialog, "PEImportPreferenceName")
end

--- cp.apple.finalcutpro.prefs.ImportPanel.copyToLibraryStorageLocation <cp.ui.RadioButton>
--- Field
--- The "Copy to library storage location" `RadioButton`.
function ImportPanel.lazy.value:copyToLibraryStorageLocation()
    return RadioButton(self, self.UI:mutate(function(original)
        return cache(self, "_copyToLibraryStorageLocation", function()
            return childFromTop(original(), 1, RadioButton.matches)
        end, RadioButton.matches)
    end))
end

--- cp.apple.finalcutpro.prefs.ImportPanel.leaveFilesInPlace <cp.ui.RadioButton>
--- Field
--- The "Leave files in place" `RadioButton`.
function ImportPanel.lazy.value:leaveFilesInPlace()
    return RadioButton(self, self.UI:mutate(function(original)
        return cache(self, "_leaveFilesInPlace", function()
            return childFromTop(original(), 2, RadioButton.matches)
        end, RadioButton.matches)
    end))
end

--- cp.apple.finalcutpro.prefs.ImportPanel:toggleMediaLocation() -> boolean
--- Method
--- Toggles between the "Copy to library storage location" and "Leave files in place" options.
function ImportPanel:toggleMediaLocation()
    if self:show():isShowing() then
        if self:copyToLibraryStorageLocation():checked() then
            self:leaveFilesInPlace():checked(true)
        else
            self:copyToLibraryStorageLocation():checked(true)
        end
        return true
    end
    return false
end

--- cp.apple.finalcutpro.prefs.ImportPanel:toggleMediaLocation() -> cp.rx.go.Statement
--- Method
--- A `Statement` that toggles between the "Copy to library storage location" and "Leave files in place" options.
function ImportPanel.lazy.method:doToggleMediaLocation()
    return Do(self:doShow())
    :Then(
        If(self:copyToLibraryStorageLocation().checked)
        :Then(function()
            self:leaveFilesInPlace():checked(true)
        end)
        :Otherwise(function()
            self:copyToLibraryStorageLocation():checked(true)
        end)
    )
end

--- cp.apple.finalcutpro.prefs.ImportPanel.keywordsFromFinderTags <cp.ui.CheckBox>
--- Field
--- The "Keywords from Finder tags" `CheckBox`.
function ImportPanel.lazy.value:keywordsFromFinderTags()
    return CheckBox(self, function()
        return childFromTop(self:UI(), 1, CheckBox.matches)
    end)
end

--- cp.apple.finalcutpro.prefs.ImportPanel.keywordsFromFolders <cp.ui.CheckBox>
--- Field
--- The "Keywords from folders" `CheckBox`.
function ImportPanel.lazy.value:keywordsFromFolders()
    return CheckBox(self, function()
        return childFromTop(self:UI(), 2, CheckBox.matches)
    end)
end

--- cp.apple.finalcutpro.prefs.ImportPanel.assignAudioRole <cp.ui.PopUpButton>
--- Field
--- The "Assign Role" `PopUpButton`.
function ImportPanel.lazy.value:assignAudioRole()
    return PopUpButton(self, function()
        return childFromTop(self:UI(), 1, PopUpButton.matches)
    end)
end

--- cp.apple.finalcutpro.prefs.ImportPanel.iXMLRoles <cp.ui.CheckBox>
--- Field
--- The "Assign iXML track names if available" `CheckBox`.
function ImportPanel.lazy.value:iXMLRoles()
    return CheckBox(self, function()
        return childFromTop(self:UI(), 3, CheckBox.matches)
    end)
end

--- cp.apple.finalcutpro.prefs.ImportPanel.createOptimizedMedia <cp.ui.CheckBox>
--- Field
--- The "Create optimized media" `CheckBox`.
function ImportPanel.lazy.value:createOptimizedMedia()
    return CheckBox(self, function()
        return childFromTop(self:UI(), 4, CheckBox.matches)
    end)
end

--- cp.apple.finalcutpro.prefs.ImportPanel.createProxyMedia <cp.ui.CheckBox>
--- Field
--- The "Create proxy media" `CheckBox`.
function ImportPanel.lazy.value:createProxyMedia()
    return CheckBox(self, function()
        return childFromTop(self:UI(), 5, CheckBox.matches)
    end)
end

--- cp.apple.finalcutpro.prefs.ImportPanel.analyzeBalanceColor <cp.ui.CheckBox>
--- Field
--- The "Analyze video for balance color" `CheckBox`.
function ImportPanel.lazy.value:analyzeBalanceColor()
    return CheckBox(self, function()
        return childFromTop(self:UI(), 6, CheckBox.matches)
    end)
end

--- cp.apple.finalcutpro.prefs.ImportPanel.findPeople <cp.ui.CheckBox>
--- Field
--- The "Find people" `CheckBox`.
function ImportPanel.lazy.value:findPeople()
    return CheckBox(self, function()
        return childFromTop(self:UI(), 7, CheckBox.matches)
    end)
end

--- cp.apple.finalcutpro.prefs.ImportPanel.findPeopleConsolidatedResults <cp.ui.CheckBox>
--- Field
--- The "Consolidate find people results" `CheckBox`.
function ImportPanel.lazy.value:findPeopleConsolidatedResults()
    return CheckBox(self, function()
        return childFromTop(self:UI(), 8, CheckBox.matches)
    end)
end

--- cp.apple.finalcutpro.prefs.ImportPanel.findPeopleSmartCollections <cp.ui.CheckBox>
--- Field
--- The "Create Smart Collections after analysis" `CheckBox`.
function ImportPanel.lazy.value:findPeopleSmartCollections()
    return CheckBox(self, function()
        return childFromTop(self:UI(), 9, CheckBox.matches)
    end)
end

--- cp.apple.finalcutpro.prefs.ImportPanel.analyzeAudioProblems <cp.ui.CheckBox>
--- Field
--- The "Analyze and fix audio problems" `CheckBox`.
function ImportPanel.lazy.value:analyzeAudioProblems()
    return CheckBox(self, function()
        return childFromTop(self:UI(), 10, CheckBox.matches)
    end)
end

--- cp.apple.finalcutpro.prefs.ImportPanel.separateMonoGroupStereoAudio <cp.ui.CheckBox>
--- Field
--- The "Separate mono and group stereo audio" `CheckBox`.
function ImportPanel.lazy.value:separateMonoGroupStereoAudio()
    return CheckBox(self, function()
        return childFromTop(self:UI(), 11, CheckBox.matches)
    end)
end

--- cp.apple.finalcutpro.prefs.ImportPanel.removeSilentChannels <cp.ui.CheckBox>
--- Field
--- The "Remove silent channels" `CheckBox`.
function ImportPanel.lazy.value:removeSilentChannels()
    return CheckBox(self, function()
        return childFromTop(self:UI(), 12, CheckBox.matches)
    end)
end

return ImportPanel
