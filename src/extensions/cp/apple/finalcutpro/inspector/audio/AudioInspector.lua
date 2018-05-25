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

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log								= require("hs.logger").new("audioInspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local prop								= require("cp.prop")
local axutils							= require("cp.ui.axutils")
local Group                             = require("cp.ui.Group")
local RadioButton                       = require("cp.ui.RadioButton")
local SplitGroup                        = require("cp.ui.SplitGroup")

local IP                                = require("cp.apple.finalcutpro.inspector.InspectorProperty")

local childFromLeft, childFromRight     = axutils.childFromLeft, axutils.childFromRight
local hasProperties, simple             = IP.hasProperties, IP.simple
local section, slider, numberField, popUpButton      = IP.section, IP.slider, IP.numberField, IP.popUpButton

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local AudioInspector = {}

--- cp.apple.finalcutpro.inspector.audio.AudioInspector.matches(element)
--- Function
--- Checks if the provided element could be a AudioInspector.
---
--- Parameters:
--- * element   - The element to check
---
--- Returns:
--- * `true` if it matches, `false` if not.
function AudioInspector.matches(element)
    if element then
        if element:attributeValue("AXRole") == "AXGroup" and #element == 1 then
            local group = element[1]
            return group and group:attributeValue("AXRole") == "AXSplitGroup" and #group > 5
        end
    end
    return false
end

--- cp.apple.finalcutpro.inspector.audio.AudioInspector.new(parent) -> cp.apple.finalcutpro.audio.AudioInspector
--- Constructor
--- Creates a new `AudioInspector` object
---
--- Parameters:
---  * `parent`		- The parent
---
--- Returns:
---  * A `AudioInspector` object
function AudioInspector.new(parent)
    local o
    o = prop.extend({
        _parent = parent,
        _child = {},
        _rows = {},
    }, AudioInspector)

--- cp.apple.finalcutpro.inspector.color.AudioInspector.UI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- Returns the `hs._asm.axuielement` object for the Audio Inspector.
    local UI = parent.panelUI:mutate(function(original)
        return axutils.cache(o, "_ui",
            function()
                local ui = original()
                return AudioInspector.matches(ui) and ui or nil
            end,
            AudioInspector.matches
        )
    end)

--- cp.apple.finalcutpro.inspector.color.AudioInspector.isShowing <cp.prop: boolean; read-only>
--- Field
--- Checks if the AudioInspector is currently showing.
    local isShowing = UI:mutate(function(original)
        return original() ~= nil
    end)

    prop.bind(o) {
        UI = UI, isShowing = isShowing,
    }

    function o:content()
        local content = self._content
        if not content then
            content = SplitGroup.new(o, UI:mutate(function(original, this)
                return axutils.cache(this, "_ui", function()
                    local ui = original()
                    if ui then
                        local splitGroup = ui[1]
                        return SplitGroup.matches(splitGroup) and splitGroup or nil
                    end
                    return nil
                end)
            end))
            self._content = content
        end
        return content
    end

    function o:topProperties()
        local topProps = self._topProperties
        if not topProps then
            topProps = Group.new(self, function()
                return axutils.childFromTop(self:content():UI(), 1)
            end)

            prop.bind(topProps) {
                contentUI = topProps.UI:mutate(function(original)
                    local ui = original()
                    if ui and ui[1] then
                        return ui[1]
                    end
                end),
            }

            hasProperties(topProps, topProps.contentUI) {
                volume              = slider "FFAudioVolumeToolName",
            }

            self._topProperties = topProps
        end
        return topProps
    end

    function o:mainProperties()
        local mainProps = self._mainProperties
        if not mainProps then
            mainProps = SplitGroup.new(self, function()
                return axutils.childFromTop(self:content():UI(), 2)
            end)

            prop.bind(mainProps) {
                contentUI = mainProps.UI:mutate(function(original)
                    local ui = original()
                    if ui and ui[1] and ui[1][1] then
                        return ui[1][1]
                    end
                end),
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
                                row.fiftyHz     = RadioButton.new(row, function()
                                    return childFromLeft(row:children(), 1, RadioButton.matches)
                                end)
                                row.sixtyHz     = RadioButton.new(row, function()
                                    return childFromRight(row:children(), 1, RadioButton.matches)
                                end)
                            end),
                        }
                    },
                },

                effects             = section "FFInspectorBrickEffects" {},
            }

            self._mainProperties = mainProps
        end
        return mainProps
    end

    prop.bind(o) {
        volume = o:topProperties().volume,
        audioEnhancements = o:mainProperties().audioEnhancements,
        effects = o:mainProperties().effects,
    }

    return o
end

--- cp.apple.finalcutpro.inspector.audio.AudioInspector:parent() -> table
--- Method
--- Returns the AudioInspector's parent table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function AudioInspector:parent()
    return self._parent
end

--- cp.apple.finalcutpro.inspector.audio.AudioInspector:app() -> table
--- Method
--- Returns the `cp.apple.finalcutpro` app table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application object as a table
function AudioInspector:app()
    return self:parent():app()
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

return AudioInspector