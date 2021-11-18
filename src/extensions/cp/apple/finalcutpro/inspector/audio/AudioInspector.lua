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
--- local audio = fcp.inspector.audio
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

local fn                                            = require "cp.fn"
local ax                                            = require "cp.fn.ax"

local axutils                                       = require "cp.ui.axutils"

local Group                                         = require "cp.ui.Group"
local ScrollArea                                    = require "cp.ui.ScrollArea"
local SplitGroup                                    = require "cp.ui.SplitGroup"
local Splitter                                      = require "cp.ui.Splitter"
local TextArea                                      = require "cp.ui.TextArea"

local BasePanel                                     = require "cp.apple.finalcutpro.inspector.BasePanel"
local AudioConfiguration                            = require "cp.apple.finalcutpro.inspector.audio.AudioConfiguration"
local TopProperties                                 = require "cp.apple.finalcutpro.inspector.audio.TopProperties"
local MainProperties                                = require "cp.apple.finalcutpro.inspector.audio.MainProperties"

local childMatching                                 = axutils.childMatching

local chain                                         = fn.chain
local get                                           = fn.table.get
local filter                                        = fn.value.filter

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
    local root = BasePanel.matches(element) and Group.matches(element) and element
    local split = root and #root == 1 and childMatching(root, SplitGroup.matches)
    return split and #split > 5 or false
end

AudioInspector.static.matches2 = ax.matchesIf(
    chain //
    -- it a BasePanel that is also a Group...
    filter(BasePanel.matches, Group.matches) >>
    -- with exactly one child...
    ax.children >> filter(fn.table.hasExactly(1)) >>
    -- which is a SplitGroup...
    get(1) >> filter(SplitGroup.matches) >>
    -- who has more than 5 children.
    ax.children >> fn.table.hasAtLeast(5)
)

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

function AudioInspector.lazy.value:content()
    local ui = self.UI:mutate(ax.childMatching(SplitGroup.matches))
    return SplitGroup(self, ui, {
        TopProperties,
        MainProperties,
        Group,
        Splitter,
        TextArea,
        ScrollArea
    })
end

function AudioInspector.lazy.value:topProperties()
    return self.content.children[1]
end

function AudioInspector.lazy.value:mainProperties()
    return self.content.children[2]
end

--- cp.apple.finalcutpro.inspector.color.VideoInspector.volume <cp.prop: PropertyRow>
--- Field
--- Volume
function AudioInspector.lazy.prop:volume()
    return self.topProperties.volume
end

--- cp.apple.finalcutpro.inspector.color.VideoInspector.audioEnhancements <cp.prop: PropertyRow>
--- Field
--- Audio Enhancements
function AudioInspector.lazy.prop:audioEnhancements()
    return self.mainProperties.audioEnhancements
end

--- cp.apple.finalcutpro.inspector.color.VideoInspector.pan <cp.prop: PropertyRow>
--- Field
--- Pan
function AudioInspector.lazy.prop:pan()
    return self.mainProperties.pan
end

--- cp.apple.finalcutpro.inspector.color.VideoInspector.effects <cp.prop: PropertyRow>
--- Field
--- Effects
function AudioInspector.lazy.prop:effects()
    return self.mainProperties.effects
end

--- cp.apple.finalcutpro.inspector.audio.AudioInspector.audioConfiguration <AudioConfiguration>
--- Field
--- The `AudioConfiguration` instance.
function AudioInspector.lazy.value:audioConfiguration()
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
