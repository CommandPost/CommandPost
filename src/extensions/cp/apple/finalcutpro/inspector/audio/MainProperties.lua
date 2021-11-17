--- === cp.apple.finalcutpro.inspector.audio.MainProperties ===
---
--- The MainProperties UI for the [AudioInspector](cp.apple.finalcutpro.inspector.audio.AudioInspector.md).

local require                       = require

-- local log                           = require "hs.logger".new "MainProperties"

local fn                    = require "cp.fn"
local ax                    = require "cp.fn.ax"
local Button                = require "cp.ui.Button"
local Group                 = require "cp.ui.Group"
local PopUpButton           = require "cp.ui.PopUpButton"
local RadioButton           = require "cp.ui.RadioButton"

local axutils               = require "cp.ui.axutils"
local childFromLeft         = axutils.childFromLeft
local childFromRight        = axutils.childFromRight

local IP                    = require "cp.apple.finalcutpro.inspector.InspectorProperty"

local chain                 = fn.chain
local get                   = fn.table.get

local hasProperties, simple                         = IP.hasProperties, IP.simple
local section, slider, numberField, popUpButton     = IP.section, IP.slider, IP.numberField, IP.popUpButton


local MainProperties = Group:subclass("cp.apple.finalcutpro.inspector.audio.MainProperties")

--- cp.apple.finalcutpro.inspector.audio.MainProperties.matches(element) -> boolean
--- Function
--- Checks if the element matches the MainProperties.
---
--- Parameters:
---  * element - The element to check.
---
--- Returns:
---  * `true` if the element matches, `false` otherwise.
MainProperties.static.matches = Group.matches

--- cp.apple.finalcutpro.inspector.audio.MainProperties(parent, uiFinder) -> MainProperties
--- Constructor
--- Creates a new MainProperties.
---
--- Parameters:
---  * parent		- The parent object.
---  * uiFinder	- The `axuielement` object that represents this element.
function MainProperties:initialize(parent, uiFinder)
    Group.initialize(self, parent, uiFinder)

    hasProperties(self, self.contentUI) {
        audioEnhancements       = section "FFAudioAnalysisLabel_EnhancementsBrick" {

            equalization        = section "FFAudioAnalysisLabel_Equalization" {}
                                  :extend(function(row)
                                        local children = function() return row:children() end
                                        row.mode = PopUpButton(row, chain(children, fn.table.firstMatching(PopUpButton.matches)))
                                        row.enhanced = Button(row, chain(children, fn.table.firstMatching(Button.matches)))
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
end

--- cp.apple.finalcutpro.inspector.audio.MainProperties.contentUI <cp.prop: hs.axuielement; read-only; live>
--- Field
--- The `axuielement` object that represents the content of the MainProperties group.
function MainProperties.lazy.prop:contentUI()
    return self.UI:mutate(chain(ax.children, get(1), get(1)))
end

return MainProperties