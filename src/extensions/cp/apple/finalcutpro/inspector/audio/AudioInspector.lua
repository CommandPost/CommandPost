--- === cp.apple.finalcutpro.inspector.audio.AudioInspector ===
---
--- Audio Inspector Module.
---
--- Header Rows (`compositing`, `transform`, etc.) have the following properties:
---  * enabled   - (cp.ui.CheckBox) Indicates if the section is enabled.
---  * toggle    - (cp.ui.Button) Will toggle the Hide/Show button.
---  * reset     - (cp.ui.Button) Will reset the contents of the section.
---  * expanded  - (cp.prop <boolean>) Get/sets whether the section is expanded.
---
--- Property Rows depend on the type of property:
---
--- Menu Property:
---  * value     - (cp.ui.PopUpButton) The current value of the property.
---
--- Slider Property:
---  * value     - (cp.ui.Slider) The current value of the property.
---
--- XY Property:
---  * x         - (cp.ui.TextField) The current 'X' value.
---  * y         - (cp.ui.TextField) The current 'Y' value.
---
--- CheckBox Property:
---  * value     - (cp.ui.CheckBox) The currently value.
---
--- For example:
--- ```lua
--- local audio = fcp:inspector():audio()
--- -- Menu Property:
--- audio:compositing():blendMode():value("Subtract")
--- -- Slider Property:
--- audio:compositing():opacity():value(50.0)
--- -- XY Property:
--- audio:transform():position():x(-10.0)
--- -- CheckBox property:
--- audio:stabilization():tripodMode():value(true)
--- ```
---
--- You should also be able to show a specific property and it will be revealed:
--- ```lua
--- audio:stabilization():smoothing():show():value(1.5)
--- ```

local require                                       = require

-- local log                                           = require("hs.logger").new("AudioInspector")

local axutils                                       = require("cp.ui.axutils")
local prop                                          = require("cp.prop")

local Button                                        = require("cp.ui.Button")
local Group                                         = require("cp.ui.Group")
local PopUpButton                                   = require("cp.ui.PopUpButton")
local RadioButton                                   = require("cp.ui.RadioButton")
local SplitGroup                                    = require("cp.ui.SplitGroup")

local BasePanel                                     = require("cp.apple.finalcutpro.inspector.BasePanel")
local IP                                            = require("cp.apple.finalcutpro.inspector.InspectorProperty")
local AudioConfiguration                            = require("cp.apple.finalcutpro.inspector.audio.AudioConfiguration")

local childFromLeft, childFromRight                 = axutils.childFromLeft, axutils.childFromRight
local withRole, childWithRole                       = axutils.withRole, axutils.childWithRole
local hasProperties, simple                         = IP.hasProperties, IP.simple
local section, slider, numberField, popUpButton     = IP.section, IP.slider, IP.numberField, IP.popUpButton

local AudioInspector = BasePanel:subclass("cp.apple.finalcutpro.inspector.audio.AudioInspector")

--- cp.apple.finalcutpro.inspector.audio.AudioInspector.matches(element)
--- Function
--- Checks if the provided element could be a AudioInspector.
---
--- Parameters:
---  * element   - The element to check
---
--- Returns:
---  * `true` if it matches, `false` if not.
function AudioInspector.static.matches(element)
    local root = BasePanel.matches(element) and withRole(element, "AXGroup")
    local split = root and #root == 1 and childWithRole(root, "AXSplitGroup")
    return split and #split > 5 or false
end

--- cp.apple.finalcutpro.inspector.audio.AudioInspector(parent) -> cp.apple.finalcutpro.audio.AudioInspector
--- Constructor
--- Creates a new `AudioInspector` object
---
--- Parameters:
---  * `parent`     - The parent
---
--- Returns:
---  * A `AudioInspector` object
function AudioInspector:initialize(parent)
    BasePanel.initialize(self, parent, "Audio")
end

function AudioInspector.lazy.method:content()
    return SplitGroup(self, self.UI:mutate(function(original)
        return axutils.cache(self, "_ui", function()
            local ui = original()
            if ui then
                local splitGroup = ui[1]
                return SplitGroup.matches(splitGroup) and splitGroup or nil
            end
            return nil
        end, SplitGroup.matches)
    end))
end

function AudioInspector.lazy.method:topProperties()
    local topProps = Group(self, function()
        return axutils.childFromTop(self:content():UI(), 1)
    end)

    prop.bind(topProps) {
        contentUI = topProps.UI:mutate(function(original)
            local ui = original()
            if ui and ui[1] then
                return ui[1]
            end
        end)
    }

    hasProperties(topProps, topProps.contentUI) {
        volume              = slider "FFAudioVolumeToolName",
    }

    return topProps
end

function AudioInspector.lazy.method:mainProperties()
    local mainProps = Group(self, function()
        return axutils.childFromTop(self:content():UI(), 2)
    end)

    prop.bind(mainProps) {
        contentUI = mainProps.UI:mutate(function(original)
            local ui = original()
            if ui and ui[1] and ui[1][1] then
                return ui[1][1]
            end
        end)
    }

    hasProperties(mainProps, mainProps.contentUI) {
        audioEnhancements       = section "FFAudioAnalysisLabel_EnhancementsBrick" {

            equalization        = section "FFAudioAnalysisLabel_Equalization" {}
                                  :extend(function(row)
                                        row.mode = PopUpButton(row, function() return childFromLeft(row:children(), 1, PopUpButton.matches) end)
                                        row.enhanced = Button(row, function() return childFromLeft(row:children(), 1, Button.matches) end)
                                  end),

            audioAnalysis       = section "FFAudioAnalysisLabel_AnalysisBrick" {

                loudness        = section "FFAudioAnalysisLabel_Loudness" {
                    amount      = numberField "FFAudioAnalysisLabel_LoudnessAmount",
                    uniformity  = numberField "FFAudioAnalysisLabel_LoudnessUniformity",
                },

                noiseRemoval    = section "FFAudioAnalysisLabel_NoiseRemoval" {
                    amount      = numberField "FFAudioAnalysisLabel_NoiseRemovalAmount",
                },

                humRemoval      = section "FFAudioAnalysisLabel_HumRemoval" {
                    frequency   = simple("FFAudioAnalysisLabel_HumRemovalFrequency", function(row)
                                        row.fiftyHz     = RadioButton(row, function()
                                            return childFromLeft(row:children(), 1, RadioButton.matches)
                                        end)
                                        row.sixtyHz     = RadioButton(row, function()
                                            return childFromRight(row:children(), 1, RadioButton.matches)
                                        end)
                                  end),
                }
            }
                                  :extend(function(row)
                                        row.magic = Button(row, function() return childFromLeft(row:children(), 1, Button.matches) end)
                                  end),
        },

        pan                     = section "FFAudioIntrinsicChannels_Pan" {
            mode                = popUpButton "FFAudioIntrinsicChannels_PanMode",
            amount              = slider "FFAudioIntrinsicChannels_PanAmount",
            surroundPanner      = section "FFAudioIntrinsicChannels_PanSettings" {
                --------------------------------------------------------------------------------
                -- TODO: Add Surround Panner.
                --
                --/Applications/Final Cut Pro.app/Contents/Frameworks/Flexo.framework/Versions/A/Resources/en.lproj/FFAudioSurroundPannerHUD.nib
                --------------------------------------------------------------------------------
            }

        },

        effects                 = section "FFInspectorBrickEffects" {},
    }
    return mainProps
end

--- cp.apple.finalcutpro.inspector.color.VideoInspector.volume <cp.prop: PropertyRow>
--- Field
--- Volume
function AudioInspector.lazy.prop:volume()
    return self:topProperties().volume
end

--- cp.apple.finalcutpro.inspector.color.VideoInspector.audioEnhancements <cp.prop: PropertyRow>
--- Field
--- Audio Enhancements
function AudioInspector.lazy.prop:audioEnhancements()
    return self:mainProperties().audioEnhancements
end

--- cp.apple.finalcutpro.inspector.color.VideoInspector.pan <cp.prop: PropertyRow>
--- Field
--- Pan
function AudioInspector.lazy.prop:pan()
    return self:mainProperties().pan
end

--- cp.apple.finalcutpro.inspector.color.VideoInspector.effects <cp.prop: PropertyRow>
--- Field
--- Effects
function AudioInspector.lazy.prop:effects()
    return self:mainProperties().effects
end

--- cp.apple.finalcutpro.inspector.audio.AudioInspector:audioConfiguration() -> AudioConfiguration
--- Method
--- Returns the `AudioConfiguration` instance.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `CorrectionsBar` instance.
function AudioInspector.lazy.method:audioConfiguration()
    return AudioConfiguration(self)
end

--- cp.apple.finalcutpro.inspector.audio.AudioInspector.PAN_MODES -> table
--- Constant
--- Pan Modes
AudioInspector.PAN_MODES = {
    [1]      = {flexoID = "None", i18n="none"},
    [2]      = {flexoID = "Stereo Left/Right", i18n="stereoLeftRight"},
    [3]      = {}, -- Separator
    [4]      = {}, -- SURROUND Label
    [5]      = {flexoID = "Basic Surround", i18n="basicSurround"},
    [6]      = {flexoID = "Create Space", i18n="createSpace"},
    [7]      = {flexoID = "Dialogue", i18n="dialogue"},
    [8]      = {flexoID = "Music", i18n="music"},
    [9]      = {flexoID = "Ambience", i18n="ambience"},
    [10]     = {flexoID = "Circle", i18n="circle"},
    [11]     = {flexoID = "Rotate", i18n="rotate"},
    [12]     = {flexoID = "Back to Front", i18n="backToFront"},
    [13]     = {flexoID = "Left Surround to Right Front", i18n="leftSurroundToRightFront"},
    [14]     = {flexoID = "Right Surround to Left Front", i18n="rightSurroundToLeftFront"},
}

--- cp.apple.finalcutpro.inspector.audio.AudioInspector.EQ_MODES -> table
--- Constant
--- EQ Modes
AudioInspector.EQ_MODES = {
    [1]     = {flexoID = "Flat", i18n="flat"},
    [2]     = {flexoID = "Voice Enhance", i18n="voiceEnhance"},
    [3]     = {flexoID = "Music Enhance", i18n="musicEnhance"},
    [4]     = {flexoID = "Loudness", i18n="loudness"},
    [5]     = {flexoID = "Hum Reduction", i18n="humReduction"},
    [6]     = {flexoID = "Bass Boost", i18n="bassBoost"},
    [7]     = {flexoID = "Bass Reduce", i18n="bassReduce"},
    [8]     = {flexoID = "Treble Boost", i18n="trebleBoost"},
    [9]     = {flexoID = "Treble Reduce", i18n="trebleReduce"},
    [10]     = {}, -- Separator
    [11]     = {flexoID = "FFAudioAnalysisMatchAudioEqualizationMenuName", i18n="match"},
}

return AudioInspector
