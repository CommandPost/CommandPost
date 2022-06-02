--- === cp.apple.finalcutpro.main.SynchronizeClipsSheet ===
---
--- Represents the `Synchronize Clips` [Sheet](cp.ui.Sheet.md) in Final Cut Pro.
---
--- Extends: [cp.ui.Sheet](cp.ui.Sheet.md)
--- Delegates To: [children](#children)

local require               = require

-- local log                   = require("hs.logger").new("SynchronizeClipsSheet")

local strings               = require "cp.apple.finalcutpro.strings"
local fn                    = require "cp.fn"
local ax                    = require "cp.fn.ax"
local prop                  = require "cp.prop"
local Button                = require "cp.ui.Button"
local CheckBox              = require "cp.ui.CheckBox"
local Sheet                 = require "cp.ui.Sheet"
local StaticText            = require "cp.ui.StaticText"
local TextField             = require "cp.ui.TextField"
local PopUpButton           = require "cp.ui.PopUpButton"

local delegator             = require "cp.delegator"

local has                   = require "cp.ui.has"

local chain                 = fn.chain
local get                   = fn.table.get
local filter                = fn.value.filter

local alias, list, oneOf    = has.alias, has.list, has.oneOf
local optional              = has.optional

local SynchronizeClipsSheet = Sheet:subclass("cp.apple.finalcutpro.main.SynchronizeClipsSheet")
                                :delegateTo("children", "method")

local SYNCHRONIZED_CLIP_NAME_KEY = "FFAnchoredSequenceSettingsModule_synchronizedClipLabel"

local function isSynchronizedClipName(value)
    return value == strings:find(SYNCHRONIZED_CLIP_NAME_KEY)
end

--- cp.apple.finalcutpro.main.SynchronizeClipsSheet.matches(element) -> boolean
--- Function
--- Checks if the element is a `SynchronizeClipsSheet`.
---
--- Parameters:
---  * element - An `axuielement` to check.
---
--- Returns:
---  * `true` if it matches, otherwise `false`.
SynchronizeClipsSheet.static.matches = ax.matchesIf(
    Sheet.matches,
    chain // ax.childrenTopDown >> get(1)
        >> filter(StaticText.matches)
        >> get "AXValue" >> isSynchronizedClipName
)

--- cp.apple.finalcutpro.main.SynchronizeClipsSheet.children <cp.ui.has.UIHandler>
--- Constant
--- UI Handler for the children of the `SynchronizeClipsSheet`.
SynchronizeClipsSheet.static.children = list {
    StaticText, alias "synchronizedClipName" { TextField },
    StaticText, alias "inEvent" { PopUpButton },
    StaticText, alias "startingTimecode" { TextField },
    alias "useAudioForSynchronization" { CheckBox },
    alias "disableAudioComponentsOnAVClips" { CheckBox },
    alias "method" {
        oneOf {
            alias "automatic" {
                StaticText, StaticText, -- "Video and Audio", "Set based on common clip properties"
                alias "settings" { StaticText },
                alias "useCustomSettings" { Button },
            },
            alias "custom" {
                StaticText, alias "synchronization" { PopUpButton },
                StaticText, alias "videoFormat" { PopUpButton },
                StaticText, -- "Format" label
                alias "videoResolution" {
                    oneOf { -- can either be a pop-up or width/height
                        alias "preset" { PopUpButton },
                        alias "custom" {
                            alias "height" { TextField },
                            alias "width" { TextField },
                        },
                    }
                },
                alias "videoRate" { PopUpButton },
                StaticText, StaticText, -- "Resolution", "Rate" labels
                alias "videoProjection" {
                    optional {
                        alias "type" { PopUpButton },
                        StaticText, -- "Projection Type" label
                    }
                },
                StaticText, alias "renderingCodec" { PopUpButton },
                StaticText, -- "Codec" label
                alias "renderingColorSpace" { PopUpButton },
                StaticText, -- "Color Space" label
                StaticText, -- "Audio"
                alias "audioChannels" { PopUpButton },
                alias "audioSampleRate" { PopUpButton },
                StaticText, StaticText, -- "Audio Channels", "Sample Rate" labels
                alias "useAutomaticSettings" { Button },
            },
        }
    },
    alias "cancel" { Button },
    alias "ok" { Button },
    has.ended
}

function SynchronizeClipsSheet:initialize(parent)
    local ui = parent.UI:mutate(ax.childMatching(SynchronizeClipsSheet.matches))

    Sheet.initialize(self, parent, ui, SynchronizeClipsSheet.children)
end

--- cp.apple.finalcutpro.main.SynchronizeClipsSheet.synchronizedClipName <cp.ui.TextField>
--- Field
--- The `TextField` for the Synchronized Clip Name.

--- cp.apple.finalcutpro.main.SynchronizeClipsSheet.inEvent <cp.ui.PopUpButton>
--- Field
--- The `PopUpButton` for the "In Event" setting.

--- cp.apple.finalcutpro.main.SynchronizeClipsSheet.startingTimecode <cp.ui.TextField>
--- Field
--- The `TextField` for the Starting Timecode.

--- cp.apple.finalcutpro.main.SynchronizeClipsSheet.useAudioForSynchronization <cp.ui.CheckBox>
--- Field
--- The `CheckBox` for the "Use Audio for Synchronization" setting.

--- cp.apple.finalcutpro.main.SynchronizeClipsSheet.disableAudioComponentsOnAVClips <cp.ui.CheckBox>
--- Field
--- The `CheckBox` for the "Disable Audio Components on AV Clips" setting.

--------------------------------------------------------------------------------
-- Automatic Settings
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.main.SynchronizeClipsSheet.useCustomSettings <cp.ui.Button>
--- Field
--- The `Button` for the "Use Custom Settings" button.
function SynchronizeClipsSheet.lazy.value:useCustomSettings()
    return self.method.automatic.useCustomSettings
end

--------------------------------------------------------------------------------
-- Custom Settings
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.main.SynchronizeClipsSheet.synchronization <cp.ui.PopUpButton>
--- Field
--- The `PopUpButton` for the "Synchronization" setting.
function SynchronizeClipsSheet.lazy.value:synchronization()
    return self.method.custom.synchronization
end

--- cp.apple.finalcutpro.main.SynchronizeClipsSheet.videoFormat <cp.ui.PopUpButton>
--- Field
--- The `PopUpButton` for the "Video Format" setting.
function SynchronizeClipsSheet.lazy.value:videoFormat()
    return self.method.custom.videoFormat
end

--- cp.apple.finalcutpro.main.SynchronizeClipsSheet.videoResolutionPreset <cp.ui.PopUpButton>
--- Field
--- The `PopUpButton` for the "Video Resolution" setting.
function SynchronizeClipsSheet.lazy.value:videoResolutionPreset()
    return self.method.custom.videoResolution.preset
end

--- cp.apple.finalcutpro.main.SynchronizeClipsSheet.videoResolutionCustomWidth <cp.ui.TextField>
--- Field
--- The `TextField` for the "Video Resolution Width" setting width.
function SynchronizeClipsSheet.lazy.value:videoResolutionCustomWidth()
    return self.method.custom.videoResolution.custom.width
end

--- cp.apple.finalcutpro.main.SynchronizeClipsSheet.videoResolutionCustomHeight <cp.ui.TextField>
--- Field
--- The `TextField` for the "Video Resolution" setting.
function SynchronizeClipsSheet.lazy.value:videoResolutionCustomHeight()
    return self.method.custom.videoResolution.custom.height
end

--- cp.apple.finalcutpro.main.SynchronizeClipsSheet.videoRate <cp.ui.PopUpButton>
--- Field
--- The `PopUpButton` for the "Video Rate" setting.
function SynchronizeClipsSheet.lazy.value:videoRate()
    return self.method.custom.videoRate
end

--- cp.apple.finalcutpro.main.SynchronizeClipsSheet.renderingCodec <cp.ui.PopUpButton>
--- Field
--- The `PopUpButton` for the "Rendering Codec" setting.
function SynchronizeClipsSheet.lazy.value:renderingCodec()
    return self.method.custom.renderingCodec
end

--- cp.apple.finalcutpro.main.SynchronizeClipsSheet.renderingColorSpace <cp.ui.PopUpButton>
--- Field
--- The `PopUpButton` for the "Rendering Color Space" setting.
function SynchronizeClipsSheet.lazy.value:renderingColorSpace()
    return self.method.custom.renderingColorSpace
end

--- cp.apple.finalcutpro.main.SynchronizeClipsSheet.audioChannels <cp.ui.PopUpButton>
--- Field
--- The `PopUpButton` for the "Audio Channels" setting.
function SynchronizeClipsSheet.lazy.value:audioChannels()
    return self.method.custom.audioChannels
end

--- cp.apple.finalcutpro.main.SynchronizeClipsSheet.audioSampleRate <cp.ui.PopUpButton>
--- Field
--- The `PopUpButton` for the "Audio Sample Rate" setting.
function SynchronizeClipsSheet.lazy.value:audioSampleRate()
    return self.method.custom.audioSampleRate
end

--- cp.apple.finalcutpro.main.SynchronizeClipsSheet.useAutomaticSettings <cp.ui.Button>
--- Field
--- The `Button` for the "Use Automatic Settings" button.
function SynchronizeClipsSheet.lazy.value:useAutomaticSettings()
    return self.method.custom.useAutomaticSettings
end

--------------------------------------------------------------------------------
-- Standard buttons
--------------------------------------------------------------------------------

-- NOTE: Skipping the "Cancel" button because [Sheet](cp.ui.Sheet.md) already defines one.

--- cp.apple.finalcutpro.main.SynchronizeClipsSheet.ok <cp.ui.Button>
--- Field
--- The `Button` for the "Ok" button.

--------------------------------------------------------------------------------
-- Functionality
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.main.SynchronizeClipsSheet.isAutomatic <cp.prop: boolean, live>
--- Field
--- A `boolean` property indicating whether the sheet is in automatic or custom mode.
function SynchronizeClipsSheet.lazy.prop:isAutomatic()
    return prop(
        function()
            return self.useCustomSettings:isShowing()
        end,
        function(value)
            if value == true and self.useAutomaticSettings:isShowing() then
                self.useAutomaticSettings:doPress():Now()
            elseif value == false and self.useCustomSettings:isShowing() then
                self.useCustomSettings:doPress():Now()
            end
        end
    )
    :monitor(self.UI)
end

return SynchronizeClipsSheet