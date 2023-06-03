--- === cp.apple.finalcutpro.main.MulticamClipSheet ===
---
--- Represents the `New Multicam Clip` [Sheet](cp.ui.Sheet.md) in Final Cut Pro.
---
--- Extends: [cp.ui.Sheet](cp.ui.Sheet.md)
--- Delegates To: [children](#children)

local require               = require

-- local log                   = require("hs.logger").new("MulticamClipSheet")

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

local has                   = require "cp.ui.has"

local go                    = require "cp.rx.go"

local If                    = go.If
local WaitUntil             = go.WaitUntil

local chain                 = fn.chain
local get                   = fn.table.get
local filter                = fn.value.filter

local alias, list, oneOf    = has.alias, has.list, has.oneOf
local optional              = has.optional

local MulticamClipSheet = Sheet:subclass("cp.apple.finalcutpro.main.MulticamClipSheet")
                                :delegateTo("children", "method")

local MULTICAM_CLIP_NAME_KEY = "FFAnchoredSequenceSettingsModule_multiAngleLabel"

local function isMulticamClipName(value)
    return value == strings:find(MULTICAM_CLIP_NAME_KEY)
end

--- cp.apple.finalcutpro.main.MulticamClipSheet.matches(element) -> boolean
--- Function
--- Checks if the element is a `MulticamClipSheet`.
---
--- Parameters:
---  * element - An `axuielement` to check.
---
--- Returns:
---  * `true` if it matches, otherwise `false`.
MulticamClipSheet.static.matches = ax.matchesIf(
    Sheet.matches,
    chain // ax.childrenTopDown >> get(1)
        >> filter(StaticText.matches)
        >> get "AXValue" >> isMulticamClipName
)

--- cp.apple.finalcutpro.main.MulticamClipSheet.children <cp.ui.has.UIHandler>
--- Constant
--- UI Handler for the children of the `MulticamClipSheet`.
MulticamClipSheet.static.children = list {
    StaticText, alias "multicamClipName" { TextField },
    StaticText, alias "inEvent" { PopUpButton },
    StaticText, alias "startingTimecode" { TextField },
    alias "useAudioForSynchronization" { CheckBox },
    alias "method" {
        oneOf {
            alias "automatic" {
                StaticText, StaticText, -- "Video and Audio", "Set based on common clip properties"
                alias "settings" { StaticText },
                alias "useCustomSettings" { Button },
            },
            alias "custom" {
                StaticText, alias "angleAssembly" { PopUpButton },
                StaticText, alias "angleClipOrdering" { PopUpButton },
                StaticText, alias "synchronization" { PopUpButton },
                StaticText, alias "videoFormat" { PopUpButton },
                StaticText, -- "Format" label
                alias "videoResolution" {
                    oneOf { -- can either be a pop-up or width/height
                        alias "preset" { PopUpButton },
                        alias "custom" {
                            alias "width" { TextField },
                            StaticText, -- "X"
                            alias "height" { TextField },
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

function MulticamClipSheet:initialize(parent)
    local ui = parent.UI:mutate(ax.childMatching(MulticamClipSheet.matches))

    Sheet.initialize(self, parent, ui, MulticamClipSheet.children)
end

--- cp.apple.finalcutpro.main.MulticamClipSheet.multicamClipName <cp.ui.TextField>
--- Field
--- The `TextField` for the Multicam Clip Name.

--- cp.apple.finalcutpro.main.CompoundClipSheet.clipName <cp.ui.TextField>
--- Field
--- The `TextField` for the Clip Name.
function MulticamClipSheet.lazy.value:clipName()
    return self.multicamClipName
end

--- cp.apple.finalcutpro.main.MulticamClipSheet.inEvent <cp.ui.PopUpButton>
--- Field
--- The `PopUpButton` for the "In Event" setting.

--- cp.apple.finalcutpro.main.MulticamClipSheet.startingTimecode <cp.ui.TextField>
--- Field
--- The `TextField` for the Starting Timecode.

--- cp.apple.finalcutpro.main.MulticamClipSheet.useAudioForSynchronization <cp.ui.CheckBox>
--- Field
--- The `CheckBox` for the "Use Audio for Synchronization" setting.

--- cp.apple.finalcutpro.main.MulticamClipSheet.disableAudioComponentsOnAVClips <cp.ui.CheckBox>
--- Field
--- The `CheckBox` for the "Disable Audio Components on AV Clips" setting.

--------------------------------------------------------------------------------
-- Automatic Settings
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.main.MulticamClipSheet.useCustomSettings <cp.ui.Button>
--- Field
--- The `Button` for the "Use Custom Settings" button.
function MulticamClipSheet.lazy.value:useCustomSettings()
    return self.method.automatic.useCustomSettings
end

--------------------------------------------------------------------------------
-- Custom Settings
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.main.MulticamClipSheet.angleAssembly <cp.ui.PopUpButton>
--- Field
--- The `PopUpButton` for the "Angle Assembly" setting.
function MulticamClipSheet.lazy.value:angleAssembly()
    return self.method.custom.angleAssembly
end

--- cp.apple.finalcutpro.main.MulticamClipSheet.angleClipOrdering <cp.ui.PopUpButton>
--- Field
--- The `PopUpButton` for the "Angle Clip Ordering" setting.
function MulticamClipSheet.lazy.value:angleClipOrdering()
    return self.method.custom.angleClipOrdering
end

--- cp.apple.finalcutpro.main.MulticamClipSheet.synchronization <cp.ui.PopUpButton>
--- Field
--- The `PopUpButton` for the "Synchronization" setting.
function MulticamClipSheet.lazy.value:synchronization()
    return self.method.custom.synchronization
end

--- cp.apple.finalcutpro.main.MulticamClipSheet.videoFormat <cp.ui.PopUpButton>
--- Field
--- The `PopUpButton` for the "Video Format" setting.
function MulticamClipSheet.lazy.value:videoFormat()
    return self.method.custom.videoFormat
end

--- cp.apple.finalcutpro.main.MulticamClipSheet.videoResolutionPreset <cp.ui.PopUpButton>
--- Field
--- The `PopUpButton` for the "Video Resolution" setting.
function MulticamClipSheet.lazy.value:videoResolutionPreset()
    return self.method.custom.videoResolution.preset
end

--- cp.apple.finalcutpro.main.MulticamClipSheet.videoResolutionCustomWidth <cp.ui.TextField>
--- Field
--- The `TextField` for the "Video Resolution Width" setting width.
function MulticamClipSheet.lazy.value:videoResolutionCustomWidth()
    return self.method.custom.videoResolution.custom.width
end

--- cp.apple.finalcutpro.main.MulticamClipSheet.videoResolutionCustomHeight <cp.ui.TextField>
--- Field
--- The `TextField` for the "Video Resolution" setting.
function MulticamClipSheet.lazy.value:videoResolutionCustomHeight()
    return self.method.custom.videoResolution.custom.height
end

--- cp.apple.finalcutpro.main.MulticamClipSheet.videoRate <cp.ui.PopUpButton>
--- Field
--- The `PopUpButton` for the "Video Rate" setting.
function MulticamClipSheet.lazy.value:videoRate()
    return self.method.custom.videoRate
end

--- cp.apple.finalcutpro.main.MulticamClipSheet.renderingCodec <cp.ui.PopUpButton>
--- Field
--- The `PopUpButton` for the "Rendering Codec" setting.
function MulticamClipSheet.lazy.value:renderingCodec()
    return self.method.custom.renderingCodec
end

--- cp.apple.finalcutpro.main.MulticamClipSheet.renderingColorSpace <cp.ui.PopUpButton>
--- Field
--- The `PopUpButton` for the "Rendering Color Space" setting.
function MulticamClipSheet.lazy.value:renderingColorSpace()
    return self.method.custom.renderingColorSpace
end

--- cp.apple.finalcutpro.main.MulticamClipSheet.audioChannels <cp.ui.PopUpButton>
--- Field
--- The `PopUpButton` for the "Audio Channels" setting.
function MulticamClipSheet.lazy.value:audioChannels()
    return self.method.custom.audioChannels
end

--- cp.apple.finalcutpro.main.MulticamClipSheet.audioSampleRate <cp.ui.PopUpButton>
--- Field
--- The `PopUpButton` for the "Audio Sample Rate" setting.
function MulticamClipSheet.lazy.value:audioSampleRate()
    return self.method.custom.audioSampleRate
end

--- cp.apple.finalcutpro.main.MulticamClipSheet.useAutomaticSettings <cp.ui.Button>
--- Field
--- The `Button` for the "Use Automatic Settings" button.
function MulticamClipSheet.lazy.value:useAutomaticSettings()
    return self.method.custom.useAutomaticSettings
end

--------------------------------------------------------------------------------
-- Standard buttons
--------------------------------------------------------------------------------

-- NOTE: Skipping the "Cancel" button because [Sheet](cp.ui.Sheet.md) already defines one.

--- cp.apple.finalcutpro.main.MulticamClipSheet.ok <cp.ui.Button>
--- Field
--- The `Button` for the "Ok" button.

--------------------------------------------------------------------------------
-- Functionality
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.main.MulticamClipSheet.isAutomatic <cp.prop: boolean, live>
--- Field
--- A `boolean` property indicating whether the sheet is in automatic or custom mode.
function MulticamClipSheet.lazy.prop:isAutomatic()
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

--------------------------------------------------------------------------------
-- Other Functions
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.main.MulticamClipSheet:doShow() <cp.rx.go.Statement>
--- Method
--- A [Statement](cp.rx.go.Statement.md) that attempt to show the sheet.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement` object.
function MulticamClipSheet.lazy.method:doShow()
    local app = self:app()
    return If(app:doLaunch())
    :Then(app.browser)
    :Then(
        app.menu:doSelectMenu({"File", "New", "Multicam Clip…"})
    )
    :Then(
        WaitUntil(self.isShowing):TimeoutAfter(2000)
    )
    :Otherwise(false)
    :Label("MulticamClipSheet:doShow")
end

--- cp.apple.finalcutpro.main.MulticamClipSheet:doHide() <cp.rx.go.Statement>
--- Method
--- A [Statement](cp.rx.go.Statement.md) that attempt to hide the sheet, if it is visible.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement` object.
function MulticamClipSheet.lazy.method:doHide()
    return If(self.isShowing):Is(true):Then(
        self.cancel:doPress()
    )
    :Label("MulticamClipSheet:doHide")
end

return MulticamClipSheet