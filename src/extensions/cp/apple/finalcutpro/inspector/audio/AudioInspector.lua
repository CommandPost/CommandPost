--- === cp.apple.finalcutpro.inspector.audio.AudioInspector ===
---
--- Audio Inspector Module.
---
--- Header Rows (`compositing`, `transform`, etc.) have the following properties:
--- * enabled   - (cp.ui.CheckBox) Indicates if the section is enabled.
--- * toggle    - (cp.ui.Button) Will toggle the Hide/Show button.
--- * reset     - (cp.ui.Button) Will reset the contents of the section.
--- * expanded  - (cp.prop <boolean>) Get/sets whether the section is expanded.
---
--- Property Rows depend on the type of property:
---
--- Menu Property:
--- * value     - (cp.ui.PopUpButton) The current value of the property.
---
--- Slider Property:
--- * value     - (cp.ui.Slider) The current value of the property.
---
--- XY Property:
--- * x         - (cp.ui.TextField) The current 'X' value.
--- * y         - (cp.ui.TextField) The current 'Y' value.
---
--- CheckBox Property:
--- * value     - (cp.ui.CheckBox) The currently value.
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

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log								= require("hs.logger").new("audioInspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local prop								= require("cp.prop")
local axutils							= require("cp.ui.axutils")
local Element                           = require("cp.ui.Element")
local Group                             = require("cp.ui.Group")
local RadioButton                       = require("cp.ui.RadioButton")
local SplitGroup                        = require("cp.ui.SplitGroup")

local If                                = require("cp.rx.go.If")

local IP                                = require("cp.apple.finalcutpro.inspector.InspectorProperty")

local childFromLeft, childFromRight     = axutils.childFromLeft, axutils.childFromRight
local hasProperties, simple             = IP.hasProperties, IP.simple
local section, slider, numberField, popUpButton      = IP.section, IP.slider, IP.numberField, IP.popUpButton

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local AudioInspector = Element:subclass("AudioInspector")

--- cp.apple.finalcutpro.inspector.audio.AudioInspector.matches(element)
--- Function
--- Checks if the provided element could be a AudioInspector.
---
--- Parameters:
--- * element   - The element to check
---
--- Returns:
--- * `true` if it matches, `false` if not.
function AudioInspector.static.matches(element)
    if Element.matches(element) then
        if element:attributeValue("AXRole") == "AXGroup" and #element == 1 then
            local group = element[1]
            return group and group:attributeValue("AXRole") == "AXSplitGroup" and #group > 5
        end
    end
    return false
end

--- cp.apple.finalcutpro.inspector.audio.AudioInspector(parent) -> cp.apple.finalcutpro.audio.AudioInspector
--- Constructor
--- Creates a new `AudioInspector` object
---
--- Parameters:
---  * `parent`		- The parent
---
--- Returns:
---  * A `AudioInspector` object
function AudioInspector:initialize(parent)

    local UI = parent.panelUI:mutate(function(original)
        return axutils.cache(self, "_ui",
            function()
                local ui = original()
                return AudioInspector.matches(ui) and ui or nil
            end,
            AudioInspector.matches
        )
    end)

    Element.initialize(self, parent, UI)
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
        end)
    end))
end

function AudioInspector.lazy.method:topProperties()
    local topProps = Group(self, function()
        return axutils.childFromTop(self:content():UI(), 1)
    end)

    prop.bind(topProps) {
        contentUI = self.UI:mutate(function(original)
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
    local mainProps = SplitGroup(self, function()
        return axutils.childFromTop(self:content():UI(), 2)
    end)

    prop.bind(mainProps) {
        contentUI = self.UI:mutate(function(original)
            local ui = original()
            if ui and ui[1] and ui[1][1] then
                return ui[1][1]
            end
        end)
    }

    hasProperties(mainProps, mainProps.contentUI) {
        audioEnhancements   = section "FFAudioAnalysisLabel_EnhancementsBrick" {
            equalization    = popUpButton "FFAudioAnalysisLabel_Equalization",
            audioAnalysis   = section "FFAudioAnalysisLabel_AnalysisBrick" {
                loudness        = section "FFAudioAnalysisLabel_Loudness" {
                    amount      = numberField "FFAudioAnalysisLabel_LoudnessAmount",
                    uniformity   = numberField "FFAudioAnalysisLabel_LoudnessUniformity",
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
            },
        },

        effects             = section "FFInspectorBrickEffects" {},
    }

    return mainProps
end

function AudioInspector.lazy.prop:volume()
    return self:topProperties().volume
end

function AudioInspector.lazy.prop:audioEnhancements()
    return self:mainProperties().audioEnhancements
end

function AudioInspector.lazy.prop:effects()
    return self:mainProperties().effects
end

--------------------------------------------------------------------------------
--
-- VIDEO INSPECTOR:
--
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.audio.AudioInspector:show() -> AudioInspector
--- Method
--- Shows the Audio Inspector
---
--- Parameters:
---  * None
---
--- Returns:
---  * AudioInspector
function AudioInspector:show()
    if not self:isShowing() then
        self:parent():selectTab("Audio")
    end
    return self
end

--- cp.apple.finalcutpro.inspector.audio.AudioInspector:show() -> AudioInspector
--- Method
--- A [Statement](cp.rx.go.Statement.md) that shows the Audio Inspector.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement`, resolving to `true` if successful and sending an error if not.
function AudioInspector.lazy.method:doShow()
    return If(self.isShowing):Is(false):Then(
        self:parent():doSelectTab("Audio")
    ):Otherwise(true)
    :Label("AudioInspector:doShow")
end

return AudioInspector
