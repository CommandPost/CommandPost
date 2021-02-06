--- === plugins.core.monogram.manager ===
---
--- Monogram Actions for Final Cut Pro

local require                   = require

local log                       = require "hs.logger".new "monogram"

local application               = require "hs.application"
local json                      = require "hs.json"
local plist                     = require "hs.plist"
local timer                     = require "hs.timer"
local udp                       = require "hs.socket.udp"

local config                    = require "cp.config"
local deferred                  = require "cp.deferred"
local fcp                       = require "cp.apple.finalcutpro"
local i18n                      = require "cp.i18n"
local tools                     = require "cp.tools"

local doAfter                   = timer.doAfter
local doesDirectoryExist        = tools.doesDirectoryExist
local doesFileExist             = tools.doesFileExist
local ensureDirectoryExists     = tools.ensureDirectoryExists

local mod = {}

-- makeWheelHandler(puckFinderFn) -> function
-- Function
-- Creates a 'handler' for wheel controls, applying them to the puck returned by the `puckFinderFn`
--
-- Parameters:
--  * puckFinderFn - a function that will return the `ColorPuck` to apply the percentage value to.
--
-- Returns:
--  * a function that will receive the Monogram control metadata table and process it.
local function makeWheelHandler(wheelFinderFn, vertical)
    local wheelRight = 0
    local wheelUp = 0

    local wheel = wheelFinderFn()

    local updateUI = deferred.new(0.01):action(function()
        if wheel:isShowing() then
            local current = wheel:colorOrientation()

            current.right = current.right + wheelRight
            current.up = current.up + wheelUp

            wheel:colorOrientation(current)

            wheelRight = 0
            wheelUp = 0
        else
            wheel:show()
        end
    end)

    return function(data)
        if data.operation == "+" then
            local increment = data.params and data.params[1]

            if vertical then
                wheelUp = wheelUp + increment
            else
                wheelRight = wheelRight + increment
            end

            updateUI()
        elseif data.operation == "=" then
            local value = data.params and data.params[1]
            local current = wheel:colorOrientation()
            if vertical then
                current.up = value
            else
                current.right = value
            end
            wheel:colorOrientation(current)
        end
    end
end

-- makeResetColorWheelHandler(puckFinderFn) -> function
-- Function
-- Creates a 'handler' for resetting a Color Wheel.
--
-- Parameters:
--  * puckFinderFn - a function that will return the `ColorPuck` to reset.
--
-- Returns:
--  * a func
local function makeResetColorWheelHandler(wheelFinderFn)
    return function()
        local wheel = wheelFinderFn()
        wheel:show()
        wheel:colorOrientation({right=0, up=0})
    end
end

-- makeResetColorWheelSatAndBrightnessHandler(puckFinderFn) -> function
-- Function
-- Creates a 'handler' for resetting a Color Wheel, Saturation & Brightness.
--
-- Parameters:
--  * puckFinderFn - a function that will return the `ColorPuck` to reset.
--
-- Returns:
--  * a function that will receive the Monogram control metadata table and process it.
local function makeResetColorWheelSatAndBrightnessHandler(wheelFinderFn)
    return function()
        local wheel = wheelFinderFn()
        wheel:show()
        wheel:colorOrientation({right=0, up=0})
        wheel:brightnessValue(0)
        wheel:saturationValue(1)
    end
end

-- makeShortcutHandler(finderFn) -> function
-- Function
-- Creates a 'handler' for triggering a Final Cut Pro Command Editor shortcut.
--
-- Parameters:
--  * finderFn - a function that will return the shortcut identifier.
--
-- Returns:
--  * a function that will receive the Monogram control metadata table and process it.
local function makeShortcutHandler(finderFn)
    return function()
        local shortcut = finderFn()
        fcp:doShortcut(shortcut):Now()
    end
end

-- makeSaturationHandler(puckFinderFn) -> function
-- Function
-- Creates a 'handler' for wheel controls, applying them to the puck returned by the `puckFinderFn`
--
-- Parameters:
--  * puckFinderFn - a function that will return the `ColorPuck` to apply the percentage value to.
--
-- Returns:
--  * a function that will receive the Monogram control metadata table and process it.
local function makeSaturationHandler(wheelFinderFn)
    local saturationShift = 0
    local wheel = wheelFinderFn()

    local updateUI = deferred.new(0.01):action(function()
        if wheel:isShowing() then
            local current = wheel:saturationValue()
            wheel:saturationValue(current + saturationShift)
            saturationShift = 0
        else
            wheel:show()
        end
    end)

    return function(data)
        if data.operation == "+" then
            local increment = data.params and data.params[1]
            saturationShift = saturationShift + increment
            updateUI()
        elseif data.operation == "=" then
            local value = data.params and data.params[1]
            wheel:saturationValue(value)
        end
    end
end

-- makeBrightnessHandler(puckFinderFn) -> function
-- Function
-- Creates a 'handler' for wheel controls, applying them to the puck returned by the `puckFinderFn`
--
-- Parameters:
--  * puckFinderFn - a function that will return the `ColorPuck` to apply the percentage value to.
--
-- Returns:
--  * a function that will receive the Monogram control metadata table and process it.
local function makeBrightnessHandler(wheelFinderFn)
    local brightnessShift = 0
    local wheel = wheelFinderFn()

    local updateUI = deferred.new(0.01):action(function()
        if wheel:isShowing() then
            local current = wheel:brightnessValue()
            wheel:brightnessValue(current + brightnessShift)
            brightnessShift = 0
        else
            wheel:show()
        end
    end)

    return function(data)
        if data.operation == "+" then
            local increment = data.params and data.params[1]
            brightnessShift = brightnessShift + increment
            updateUI()
        elseif data.operation == "=" then
            local value = data.params and data.params[1]
            wheel:brightnessValue(value)
        end
    end
end

-- makeColourBoardHandler(puckFinderFn) -> function
-- Function
-- Creates a 'handler' for color board controls, applying them to the puck returned by the `puckFinderFn`
--
-- Parameters:
--  * boardFinderFn - a function that will return the color board puck to apply the value to.
--  * angle - a boolean which specifies whether or not it's an angle value.
--
-- Returns:
--  * a function that will receive the Monogram control metadata table and process it.
local function makeColourBoardHandler(boardFinderFn, angle)
    local colorBoardShift = 0
    local board = boardFinderFn()

    local updateUI = deferred.new(0.01):action(function()
        if board:isShowing() then
            if angle then
                local current = board:angle()
                board:angle(current + colorBoardShift)
                colorBoardShift = 0
            else
                local current = board:percent()
                board:percent(current + colorBoardShift)
                colorBoardShift = 0
            end
        else
            board:show()
        end
    end)

    return function(data)
        if data.operation == "+" then
            local increment = data.params and data.params[1]
            colorBoardShift = colorBoardShift + increment
            updateUI()
        elseif data.operation == "=" then
            local value = data.params and data.params[1]
            if angle then
                board:angle(value)
            else
                board:percent(value)
            end
        end
    end
end

-- makeSliderHandler(finderFn) -> function
-- Function
-- Creates a 'handler' for slider controls, applying them to the slider returned by the `finderFn`
--
-- Parameters:
--  * finderFn - a function that will return the slider to apply the value to.
--
-- Returns:
--  * a function that will receive the Monogram control metadata table and process it.
local function makeSliderHandler(finderFn)
    local shift = 0
    local slider = finderFn()

    local updateUI = deferred.new(0.01):action(function()
        if slider:isShowing() then
            local current = slider:value()
            slider:value(current + shift)
            shift = 0
        else
            slider:show()
        end
    end)

    return function(data)
        if data.operation == "+" then
            local increment = data.params and data.params[1]
            shift = shift + increment
            updateUI()
        elseif data.operation == "=" then
            local value = data.params and data.params[1]
            slider:value(value)
        end
    end
end

-- plugins.core.monogram.manager._buildCommandSet() -> none
-- Function
-- A private function which outputs the command set code into the Debug Console.
-- This should only really ever be used by CommandPost Developers.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function mod._buildCommandSet()
    local commandNamesPath = "/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/NSProCommandNames.strings"
    local commandNames = plist.read(commandNamesPath)

    local commandDescriptionsPath = "/Applications/Final Cut Pro.app/Contents/Resources/en.lproj/NSProCommandDescriptions.strings"
    local commandDescriptions = plist.read(commandDescriptionsPath)

    local commandGroupsPath = "/Applications/Final Cut Pro.app/Contents/Resources/NSProCommandGroups.plist"
    local commandGroups = plist.read(commandGroupsPath)

    local codeForCommandPost = ""
    local xmlForInputs = ""

    for id, commandName in pairs(commandNames) do
        local description = commandDescriptions[id]
        if description then
            local group = "General"
            for currentGroup, v in pairs(commandGroups) do
                for _, commandID in pairs(v.commands) do
                    if commandID == id then
                        group = currentGroup
                        break
                    end
                end
            end
            codeForCommandPost = codeForCommandPost .. [[registerAction("Command Set Shortcuts.]] .. group .. [[.]] .. commandName .. [[", makeShortcutHandler(function() return "]] .. id .. [[" end))]] .. "\n"
            xmlForInputs = xmlForInputs .. [[
                {
                    "name": "Command Set Shortcuts.]] .. group .. [[.]] .. commandName .. [[",
                    "info": "]] .. description.. [["
                },
            ]]
        end
    end

    log.df("codeForCommandPost:\n%s", codeForCommandPost)
    log.df("xmlForInputs:\n%s", xmlForInputs)
end

local plugin = {
    id          = "finalcutpro.monogram",
    group       = "finalcutpro",
    required    = true,
    dependencies    = {
        ["core.monogram.manager"] = "manager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Connect to Monogram Manager:
    --------------------------------------------------------------------------------
    local manager = deps.manager
    local registerAction = manager.registerAction

    --------------------------------------------------------------------------------
    -- Register the plugin:
    --------------------------------------------------------------------------------
    local basePath = config.basePath
    local sourcePath = basePath .. "/plugins/core/monogram/plugins/"
    manager.registerPlugin("Final Cut Pro via CP", sourcePath)

    --------------------------------------------------------------------------------
    -- Colour Wheel Controls:
    --------------------------------------------------------------------------------
    local colourWheels = {
        { control = fcp.inspector.color.colorWheels.master,       id = "Master" },
        { control = fcp.inspector.color.colorWheels.shadows,      id = "Shadows" },
        { control = fcp.inspector.color.colorWheels.midtones,     id = "Midtones" },
        { control = fcp.inspector.color.colorWheels.highlights,   id = "Highlights" },
    }
    for _, v in pairs(colourWheels) do
        registerAction("Color Wheels." .. v.id .. "." .. v.id .. " Vertical", makeWheelHandler(function() return v.control end, true))
        registerAction("Color Wheels." .. v.id .. "." .. v.id .. " Horizontal", makeWheelHandler(function() return v.control end, false))

        registerAction("Color Wheels." .. v.id .. "." .. v.id .. " Saturation", makeSaturationHandler(function() return v.control end))
        registerAction("Color Wheels." .. v.id .. "." .. v.id .. " Brightness", makeBrightnessHandler(function() return v.control end))

        registerAction("Color Wheels." .. v.id .. "." .. v.id .. " Reset", makeResetColorWheelHandler(function() return v.control end))
        registerAction("Color Wheels." .. v.id .. "." .. v.id .. " Reset All", makeResetColorWheelSatAndBrightnessHandler(function() return v.control end))
    end

    --------------------------------------------------------------------------------
    -- Color Board Controls:
    --------------------------------------------------------------------------------
    local colourBoards = {
        { control = fcp.inspector.color.colorBoard.color.master,            id = "Color.Color Master (Angle)",            angle = true },
        { control = fcp.inspector.color.colorBoard.color.shadows,           id = "Color.Color Shadows (Angle)",           angle = true },
        { control = fcp.inspector.color.colorBoard.color.midtones,          id = "Color.Color Midtones (Angle)",          angle = true },
        { control = fcp.inspector.color.colorBoard.color.highlights,        id = "Color.Color Highlights (Angle)",        angle = true },

        { control = fcp.inspector.color.colorBoard.color.master,            id = "Color.Color Master (Percentage)" },
        { control = fcp.inspector.color.colorBoard.color.shadows,           id = "Color.Color Shadows (Percentage)" },
        { control = fcp.inspector.color.colorBoard.color.midtones,          id = "Color.Color Midtones (Percentage)" },
        { control = fcp.inspector.color.colorBoard.color.highlights,        id = "Color.Color Highlights (Percentage)" },

        { control = fcp.inspector.color.colorBoard.saturation.master,       id = "Saturation.Saturation Master" },
        { control = fcp.inspector.color.colorBoard.saturation.shadows,      id = "Saturation.Saturation Shadows" },
        { control = fcp.inspector.color.colorBoard.saturation.midtones,     id = "Saturation.Saturation Midtones" },
        { control = fcp.inspector.color.colorBoard.saturation.highlights,   id = "Saturation.Saturation Highlights" },

        { control = fcp.inspector.color.colorBoard.exposure.master,         id = "Exposure.Exposure Master" },
        { control = fcp.inspector.color.colorBoard.exposure.shadows,        id = "Exposure.Exposure Shadows" },
        { control = fcp.inspector.color.colorBoard.exposure.midtones,       id = "Exposure.Exposure Midtones" },
        { control = fcp.inspector.color.colorBoard.exposure.highlights,     id = "Exposure.Exposure Highlights" },
    }
    for _, v in pairs(colourBoards) do
        registerAction("Color Board." .. v.id, makeColourBoardHandler(function() return v.control end, v.angle))
    end

    --------------------------------------------------------------------------------
    -- Video Controls:
    --------------------------------------------------------------------------------
    registerAction("Video Inspector.Compositing.Opacity", makeSliderHandler(function() return fcp.inspector.video.compositing():opacity() end))

    registerAction("Video Inspector.Transform.Position X", makeSliderHandler(function() return fcp.inspector.video.transform():position().x end))
    registerAction("Video Inspector.Transform.Position Y", makeSliderHandler(function() return fcp.inspector.video.transform():position().y end))

    registerAction("Video Inspector.Transform.Rotation", makeSliderHandler(function() return fcp.inspector.video.transform():rotation() end))

    registerAction("Video Inspector.Transform.Scale (All)", makeSliderHandler(function() return fcp.inspector.video.transform():scaleAll() end))

    registerAction("Video Inspector.Transform.Scale X", makeSliderHandler(function() return fcp.inspector.video.transform():scaleX() end))
    registerAction("Video Inspector.Transform.Scale Y", makeSliderHandler(function() return fcp.inspector.video.transform():scaleY() end))

    registerAction("Video Inspector.Transform.Anchor X", makeSliderHandler(function() return fcp.inspector.video.transform():anchor().x end))
    registerAction("Video Inspector.Transform.Anchor Y", makeSliderHandler(function() return fcp.inspector.video.transform():anchor().y end))

    --------------------------------------------------------------------------------
    -- Command Set Shortcuts:
    --------------------------------------------------------------------------------
    registerAction("Command Set Shortcuts.Playback/Navigation.Next Marker", makeShortcutHandler(function() return "NextMarker" end))
    registerAction("Command Set Shortcuts.General.Send iTMS Package to Compressor", makeShortcutHandler(function() return "SendITMSPackageToCompressor" end))
    registerAction("Command Set Shortcuts.General.Start/Stop Voiceover Recording", makeShortcutHandler(function() return "ToggleVoiceOverRecording" end))
    registerAction("Command Set Shortcuts.Marking.Apply Keyword Tag 7", makeShortcutHandler(function() return "AddKeywordGroup7" end))
    registerAction("Command Set Shortcuts.Editing.Deselect All", makeShortcutHandler(function() return "DeselectAll" end))
    registerAction("Command Set Shortcuts.Windows.Show/Hide Timeline Index", makeShortcutHandler(function() return "ToggleDataList" end))
    registerAction("Command Set Shortcuts.Effects.Apply Color Correction from Two Clips Back", makeShortcutHandler(function() return "SetCorrectionFromEdit-Back-2" end))
    registerAction("Command Set Shortcuts.View.Increase Clip Height", makeShortcutHandler(function() return "IncreaseThumbnailSize" end))
    registerAction("Command Set Shortcuts.Effects.Save Frame", makeShortcutHandler(function() return "AddCompareFrame" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Next Clip", makeShortcutHandler(function() return "NextClip" end))
    registerAction("Command Set Shortcuts.Editing.Select Left and Right Video Edit Edges", makeShortcutHandler(function() return "SelectLeftRightEdgeVideo" end))
    registerAction("Command Set Shortcuts.Editing.Overwrite", makeShortcutHandler(function() return "OverwriteWithSelectedMedia" end))
    registerAction("Command Set Shortcuts.Editing.Select Previous Audio Angle", makeShortcutHandler(function() return "SelectPreviousAudioAngle" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Increase Field of View", makeShortcutHandler(function() return "IncreaseFOV" end))
    registerAction("Command Set Shortcuts.Editing.Overwrite to Primary Storyline", makeShortcutHandler(function() return "CollapseToSpine" end))
    registerAction("Command Set Shortcuts.Tools.Distort Tool", makeShortcutHandler(function() return "SelectDistortTool" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Play Forward", makeShortcutHandler(function() return "JogForward" end))
    registerAction("Command Set Shortcuts.Marking.Reject", makeShortcutHandler(function() return "Reject" end))
    registerAction("Command Set Shortcuts.Editing.Connect Video only to Primary Storyline - Backtimed", makeShortcutHandler(function() return "AnchorWithSelectedMediaVideoBacktimed" end))
    registerAction("Command Set Shortcuts.Effects.Toggle Effects on/off", makeShortcutHandler(function() return "ToggleSelectedEffectsOff" end))
    registerAction("Command Set Shortcuts.Editing.Switch to Viewer Angle 15", makeShortcutHandler(function() return "SwitchAngle15" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Play Rate 2", makeShortcutHandler(function() return "PlayRate2X" end))
    registerAction("Command Set Shortcuts.Editing.Audition: Duplicate as Audition", makeShortcutHandler(function() return "NewVariantFromCurrentInSelection" end))
    registerAction("Command Set Shortcuts.General.Show/Hide Custom Overlay", makeShortcutHandler(function() return "SetDisplayCustomOverlay" end))
    registerAction("Command Set Shortcuts.Marking.Add Chapter Marker", makeShortcutHandler(function() return "AddChapterMarker" end))
    registerAction("Command Set Shortcuts.Effects.Toggle Color Mask Type", makeShortcutHandler(function() return "ToggleColorMaskModel" end))
    registerAction("Command Set Shortcuts.Marking.Delete Marker", makeShortcutHandler(function() return "DeleteMarker" end))
    registerAction("Command Set Shortcuts.Editing.Switch to Viewer Angle 7", makeShortcutHandler(function() return "SwitchAngle07" end))
    registerAction("Command Set Shortcuts.Editing.Select Right Audio Edge", makeShortcutHandler(function() return "SelectRightEdgeAudio" end))
    registerAction("Command Set Shortcuts.Editing.Cut", makeShortcutHandler(function() return "Cut" end))
    registerAction("Command Set Shortcuts.Editing.Solo", makeShortcutHandler(function() return "Solo" end))
    registerAction("Command Set Shortcuts.General.Import Media", makeShortcutHandler(function() return "Import" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Output to VR Headset", makeShortcutHandler(function() return "ToggleHMD" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Play Rate 1", makeShortcutHandler(function() return "PlayRate1X" end))
    registerAction("Command Set Shortcuts.Editing.Copy", makeShortcutHandler(function() return "Copy" end))
    registerAction("Command Set Shortcuts.Editing.Extend Edit", makeShortcutHandler(function() return "ExtendEdit" end))
    registerAction("Command Set Shortcuts.Editing.Audition: Add to Audition", makeShortcutHandler(function() return "AddToAudition" end))
    registerAction("Command Set Shortcuts.Marking.Apply Keyword Tag 3", makeShortcutHandler(function() return "AddKeywordGroup3" end))
    registerAction("Command Set Shortcuts.Windows.Project Timecode", makeShortcutHandler(function() return "GoToProjectTimecodeView" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Go to Next Edit", makeShortcutHandler(function() return "NextEdit" end))
    registerAction("Command Set Shortcuts.Effects.Retime: Speed Ramp from Zero", makeShortcutHandler(function() return "RetimeSpeedRampFromZero" end))
    registerAction("Command Set Shortcuts.General.Blade Speed", makeShortcutHandler(function() return "RetimeBladeSpeed" end))
    registerAction("Command Set Shortcuts.Marking.Delete Markers In Selection", makeShortcutHandler(function() return "DeleteMarkersInSelection" end))
    registerAction("Command Set Shortcuts.Windows.Revert to Original Layout", makeShortcutHandler(function() return "ResetWindowLayout" end))
    registerAction("Command Set Shortcuts.View.Clip Appearance: Filmstrips Only", makeShortcutHandler(function() return "ClipAppearanceVideoOnly" end))
    registerAction("Command Set Shortcuts.Effects.Color Correction: Reset Current Effect Pane", makeShortcutHandler(function() return "ColorBoard-ResetPucksOnCurrentBoard" end))
    registerAction("Command Set Shortcuts.Editing.Nudge Up Many", makeShortcutHandler(function() return "NudgeUpMany" end))
    registerAction("Command Set Shortcuts.Editing.Source Media: Audio & Video", makeShortcutHandler(function() return "AVEditModeBoth" end))
    registerAction("Command Set Shortcuts.Editing.Cut and Switch to Viewer Angle 9", makeShortcutHandler(function() return "CutSwitchAngle09" end))
    registerAction("Command Set Shortcuts.Editing.Cut and Switch to Viewer Angle 4", makeShortcutHandler(function() return "CutSwitchAngle04" end))
    registerAction("Command Set Shortcuts.General.Toggle Audio Fade In", makeShortcutHandler(function() return "ToggleFadeInAudio" end))
    registerAction("Command Set Shortcuts.View.Clip Appearance: Waveforms and Filmstrips", makeShortcutHandler(function() return "ClipAppearance5050" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Exit Full Screen", makeShortcutHandler(function() return "ExitFullScreen" end))
    registerAction("Command Set Shortcuts.Editing.Select Below", makeShortcutHandler(function() return "SelectLowerItem" end))
    registerAction("Command Set Shortcuts.Editing.Finalize Audition", makeShortcutHandler(function() return "FinalizePick" end))
    registerAction("Command Set Shortcuts.Editing.Nudge Down Many", makeShortcutHandler(function() return "NudgeDownMany" end))
    registerAction("Command Set Shortcuts.General.Sort By Name", makeShortcutHandler(function() return "SortByName" end))
    registerAction("Command Set Shortcuts.Windows.Show Vectorscope", makeShortcutHandler(function() return "ToggleVectorscope" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Play Selection", makeShortcutHandler(function() return "PlaySelected" end))
    registerAction("Command Set Shortcuts.General.Paste Keyframes", makeShortcutHandler(function() return "PasteKeyframes" end))
    registerAction("Command Set Shortcuts.General.Export Captions…", makeShortcutHandler(function() return "ExportCaptions" end))
    registerAction("Command Set Shortcuts.Effects.Apply Color Correction from Previous Clip", makeShortcutHandler(function() return "SetCorrectionFromEdit-Back-1" end))
    registerAction("Command Set Shortcuts.Editing.Insert Audio only", makeShortcutHandler(function() return "InsertMediaAudio" end))
    registerAction("Command Set Shortcuts.General.Copy Keyframes", makeShortcutHandler(function() return "CopyKeyframes" end))
    registerAction("Command Set Shortcuts.Editing.Nudge Right Many", makeShortcutHandler(function() return "NudgeRightMany" end))
    registerAction("Command Set Shortcuts.Editing.Align Audio to Video", makeShortcutHandler(function() return "AlignAudioToVideo" end))
    registerAction("Command Set Shortcuts.Editing.Insert Gap", makeShortcutHandler(function() return "InsertGap" end))
    registerAction("Command Set Shortcuts.View.Toggle Inspector Height", makeShortcutHandler(function() return "ToggleFullheightInspector" end))
    registerAction("Command Set Shortcuts.Editing.New Multicam Clip…", makeShortcutHandler(function() return "CreateMultiAngleClip" end))
    registerAction("Command Set Shortcuts.Editing.Sync Angle to Monitoring Angle", makeShortcutHandler(function() return "AudioFineSyncMultiAngleAngle" end))
    registerAction("Command Set Shortcuts.Effects.Color Correction: Nudge Control Down", makeShortcutHandler(function() return "ColorBoard-NudgePuckDown" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Negative Timecode Entry", makeShortcutHandler(function() return "ShowTimecodeEntryMinusDelta" end))
    registerAction("Command Set Shortcuts.Windows.View Tags in Timeline Index", makeShortcutHandler(function() return "SwitchToTagsTabInTimelineIndex" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Left Eye Only", makeShortcutHandler(function() return "360LeftEyeOnly" end))
    registerAction("Command Set Shortcuts.Editing.New Compound Clip…", makeShortcutHandler(function() return "CreateCompoundClip" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Play Rate 4", makeShortcutHandler(function() return "PlayRate4X" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Difference", makeShortcutHandler(function() return "360Difference" end))
    registerAction("Command Set Shortcuts.Editing.Overwrite Video only - Backtimed", makeShortcutHandler(function() return "OverwriteWithSelectedMediaVideoBacktimed" end))
    registerAction("Command Set Shortcuts.Effects.Color Board: Switch to the Color Pane", makeShortcutHandler(function() return "ColorBoard-SwitchToColorTab" end))
    registerAction("Command Set Shortcuts.View.Clip Appearance: Waveforms Only", makeShortcutHandler(function() return "ClipAppearanceAudioOnly" end))
    registerAction("Command Set Shortcuts.Effects.Retime Video Quality: Optical Flow", makeShortcutHandler(function() return "RetimeVideoQualityOpticalFlow" end))
    registerAction("Command Set Shortcuts.General.Nudge Marker Right", makeShortcutHandler(function() return "NudgeMarkerRight" end))
    registerAction("Command Set Shortcuts.View.Clip Appearance: Decrease Waveform Size", makeShortcutHandler(function() return "ClipAppearanceAudioSmaller" end))
    registerAction("Command Set Shortcuts.Marking.New Keyword Collection", makeShortcutHandler(function() return "NewKeyword" end))
    registerAction("Command Set Shortcuts.Editing.Append to Storyline", makeShortcutHandler(function() return "AppendWithSelectedMedia" end))
    registerAction("Command Set Shortcuts.General.Save Audio Effect Preset", makeShortcutHandler(function() return "SaveAudioEffectPreset" end))
    registerAction("Command Set Shortcuts.Editing.Next Pick", makeShortcutHandler(function() return "SelectNextVariant" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Go to Next Bank", makeShortcutHandler(function() return "SelectNextAngleBank" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Previous Clip", makeShortcutHandler(function() return "PreviousClip" end))
    registerAction("Command Set Shortcuts.Editing.Delete Selection Only", makeShortcutHandler(function() return "DeleteSelectionOnly" end))
    registerAction("Command Set Shortcuts.Editing.Select Next Audio Angle", makeShortcutHandler(function() return "SelectNextAudioAngle" end))
    registerAction("Command Set Shortcuts.Editing.Replace From End", makeShortcutHandler(function() return "ReplaceWithSelectedMediaFromEnd" end))
    registerAction("Command Set Shortcuts.Organization.Reveal Project in Browser", makeShortcutHandler(function() return "RevealProjectInEventsBrowser" end))
    registerAction("Command Set Shortcuts.General.Show/Hide Video Scopes in the Event Viewer", makeShortcutHandler(function() return "ToggleVideoScopesEventViewer" end))
    registerAction("Command Set Shortcuts.Effects.Add Color Mask", makeShortcutHandler(function() return "AddColorMask" end))
    registerAction("Command Set Shortcuts.Editing.Source Media: Video Only", makeShortcutHandler(function() return "AVEditModeVideo" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Copy Timecode", makeShortcutHandler(function() return "CopyTimecode" end))
    registerAction("Command Set Shortcuts.Editing.Replace", makeShortcutHandler(function() return "ReplaceWithSelectedMediaWhole" end))
    registerAction("Command Set Shortcuts.Marking.Clear Range Start", makeShortcutHandler(function() return "ClearSelectionStart" end))
    registerAction("Command Set Shortcuts.Marking.Range Selection Tool", makeShortcutHandler(function() return "SelectToolRangeSelection" end))
    registerAction("Command Set Shortcuts.Effects.Add Default Transition", makeShortcutHandler(function() return "AddTransition" end))
    registerAction("Command Set Shortcuts.Editing.Paste as Connected", makeShortcutHandler(function() return "PasteAsConnected" end))
    registerAction("Command Set Shortcuts.General.New Project", makeShortcutHandler(function() return "NewProject" end))
    registerAction("Command Set Shortcuts.General.Sort By Date", makeShortcutHandler(function() return "SortByDate" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Roll Counterclockwise", makeShortcutHandler(function() return "RollCounterclockwise" end))
    registerAction("Command Set Shortcuts.Editing.Expand/Collapse Audio Components", makeShortcutHandler(function() return "ToggleAudioComponents" end))
    registerAction("Command Set Shortcuts.Windows.View Captions in Timeline Index", makeShortcutHandler(function() return "SwitchToCaptionsTabInTimelineIndex" end))
    registerAction("Command Set Shortcuts.Share.Export Using Default Share Destination…", makeShortcutHandler(function() return "ShareDefaultDestination" end))
    registerAction("Command Set Shortcuts.Effects.Color Correction: Nudge Control Right", makeShortcutHandler(function() return "ColorBoard-NudgePuckRight" end))
    registerAction("Command Set Shortcuts.Organization.New Event…", makeShortcutHandler(function() return "NewEvent" end))
    registerAction("Command Set Shortcuts.Editing.Delete", makeShortcutHandler(function() return "Delete" end))
    registerAction("Command Set Shortcuts.Effects.Remove Effects", makeShortcutHandler(function() return "RemoveEffects" end))
    registerAction("Command Set Shortcuts.Editing.Connect Audio only to Primary Storyline", makeShortcutHandler(function() return "AnchorWithSelectedMediaAudio" end))
    registerAction("Command Set Shortcuts.Effects.Retime: Fast 4x", makeShortcutHandler(function() return "RetimeFast4x" end))
    registerAction("Command Set Shortcuts.General.Render Selection", makeShortcutHandler(function() return "RenderSelection" end))
    registerAction("Command Set Shortcuts.General.Delete Keyframes", makeShortcutHandler(function() return "DeleteKeyframes" end))
    registerAction("Command Set Shortcuts.Editing.Switch to Viewer Angle 9", makeShortcutHandler(function() return "SwitchAngle09" end))
    registerAction("Command Set Shortcuts.View.Zoom to Samples", makeShortcutHandler(function() return "ZoomToSubframes" end))
    registerAction("Command Set Shortcuts.View.View All Color Channels", makeShortcutHandler(function() return "ShowColorChannelsAll" end))
    registerAction("Command Set Shortcuts.Windows.Organize", makeShortcutHandler(function() return "OrganizeLayout" end))
    registerAction("Command Set Shortcuts.Editing.Switch to Viewer Angle 13", makeShortcutHandler(function() return "SwitchAngle13" end))
    registerAction("Command Set Shortcuts.Effects.Connect Default Title", makeShortcutHandler(function() return "AddBasicTitle" end))
    registerAction("Command Set Shortcuts.Editing.Switch to Viewer Angle 12", makeShortcutHandler(function() return "SwitchAngle12" end))
    registerAction("Command Set Shortcuts.Marking.Apply Keyword Tag 1", makeShortcutHandler(function() return "AddKeywordGroup1" end))
    registerAction("Command Set Shortcuts.Effects.Retime: Reverse Clip", makeShortcutHandler(function() return "RetimeReverseClip" end))
    registerAction("Command Set Shortcuts.Editing.Switch to Viewer Angle 4", makeShortcutHandler(function() return "SwitchAngle04" end))
    registerAction("Command Set Shortcuts.Marking.Show/Hide Marked Ranges", makeShortcutHandler(function() return "ShowMarkedRanges" end))
    registerAction("Command Set Shortcuts.General.Hide Rejected", makeShortcutHandler(function() return "HideRejected" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Copy Playhead Timecode", makeShortcutHandler(function() return "CopyPlayheadTimecode" end))
    registerAction("Command Set Shortcuts.Windows.Show/Hide Video Scopes", makeShortcutHandler(function() return "ToggleVideoScopes" end))
    registerAction("Command Set Shortcuts.Editing.Extend Selection Down", makeShortcutHandler(function() return "ExtendDown" end))
    registerAction("Command Set Shortcuts.Application.Minimize", makeShortcutHandler(function() return "Minimize" end))
    registerAction("Command Set Shortcuts.Effects.Retime: Reset", makeShortcutHandler(function() return "RetimeReset" end))
    registerAction("Command Set Shortcuts.Tools.Select Tool", makeShortcutHandler(function() return "SelectToolArrowOrRangeSelection" end))
    registerAction("Command Set Shortcuts.View.Zoom Out", makeShortcutHandler(function() return "ZoomOut" end))
    registerAction("Command Set Shortcuts.Effects.Enable/Disable Balance Color", makeShortcutHandler(function() return "ToggleColorBalance" end))
    registerAction("Command Set Shortcuts.General.Connect with Selected Media Video Backtimed", makeShortcutHandler(function() return "ConnectWithSelectedMediaVideoBacktimed" end))
    registerAction("Command Set Shortcuts.General.Hide Keyword Editor", makeShortcutHandler(function() return "HideKeywordEditor" end))
    registerAction("Command Set Shortcuts.View.View Red Color Channel", makeShortcutHandler(function() return "ShowColorChannelsRed" end))
    registerAction("Command Set Shortcuts.Effects.Color Board: Switch to the Saturation Pane", makeShortcutHandler(function() return "ColorBoard-SwitchToSaturationTab" end))
    registerAction("Command Set Shortcuts.Marking.Apply Keyword Tag 6", makeShortcutHandler(function() return "AddKeywordGroup6" end))
    registerAction("Command Set Shortcuts.Tools.Blade Tool", makeShortcutHandler(function() return "SelectToolBlade" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Cut/Switch Multicam Audio and Video", makeShortcutHandler(function() return "MultiAngleEditStyleAudioVideo" end))
    registerAction("Command Set Shortcuts.Windows.Show/Hide Timeline", makeShortcutHandler(function() return "ToggleTimeline" end))
    registerAction("Command Set Shortcuts.Windows.Show/Hide Events on Second Display", makeShortcutHandler(function() return "ToggleFullScreenEvents" end))
    registerAction("Command Set Shortcuts.Effects.Color Correction: Select Previous Effect", makeShortcutHandler(function() return "ColorBoard-PreviousColorEffect" end))
    registerAction("Command Set Shortcuts.Editing.Resolve Overlaps", makeShortcutHandler(function() return "ResolveCaptionOverlaps" end))
    registerAction("Command Set Shortcuts.Effects.Toggle View Mask On/Off", makeShortcutHandler(function() return "ToggleEffectViewMask" end))
    registerAction("Command Set Shortcuts.General.Edit Next Marker", makeShortcutHandler(function() return "EditNextMarker" end))
    registerAction("Command Set Shortcuts.View.Show One Frame per Filmstrip", makeShortcutHandler(function() return "ShowOneFramePerFilmstrip" end))
    registerAction("Command Set Shortcuts.Windows.Show/Hide Event Viewer", makeShortcutHandler(function() return "ToggleEventViewer" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Decrease Field of View", makeShortcutHandler(function() return "DecreaseFOV" end))
    registerAction("Command Set Shortcuts.Editing.Cut and Switch to Viewer Angle 7", makeShortcutHandler(function() return "CutSwitchAngle07" end))
    registerAction("Command Set Shortcuts.Editing.Paste Insert at Playhead", makeShortcutHandler(function() return "Paste" end))
    registerAction("Command Set Shortcuts.Editing.Open Audition", makeShortcutHandler(function() return "ToggleStackHUD" end))
    registerAction("Command Set Shortcuts.Effects.Toggle Color Correction Effects on/off", makeShortcutHandler(function() return "ColorBoard-ToggleAllCorrection" end))
    registerAction("Command Set Shortcuts.Editing.Switch to Viewer Angle 2", makeShortcutHandler(function() return "SwitchAngle02" end))
    registerAction("Command Set Shortcuts.Editing.Select Left Audio Edge", makeShortcutHandler(function() return "SelectLeftEdgeAudio" end))
    registerAction("Command Set Shortcuts.Windows.Show/Hide Keyword Editor", makeShortcutHandler(function() return "ToggleKeywordEditor" end))
    registerAction("Command Set Shortcuts.Marking.Apply Keyword Tag 4", makeShortcutHandler(function() return "AddKeywordGroup4" end))
    registerAction("Command Set Shortcuts.Effects.Retime Video Quality: Frame Blending", makeShortcutHandler(function() return "RetimeVideoQualityFrameBlending" end))
    registerAction("Command Set Shortcuts.View.Toggle Filmstrip/List View", makeShortcutHandler(function() return "ToggleEventsAsFilmstripAndList" end))
    registerAction("Command Set Shortcuts.Windows.Go To Titles and Generators", makeShortcutHandler(function() return "ToggleEventContentBrowser" end))
    registerAction("Command Set Shortcuts.View.View Blue Color Channel", makeShortcutHandler(function() return "ShowColorChannelsBlue" end))
    registerAction("Command Set Shortcuts.Marking.Edit Caption", makeShortcutHandler(function() return "EditCaption" end))
    registerAction("Command Set Shortcuts.Editing.Blade", makeShortcutHandler(function() return "BladeAtPlayhead" end))
    registerAction("Command Set Shortcuts.General.Connect with Selected Media Audio Backtimed", makeShortcutHandler(function() return "ConnectWithSelectedMediaAudioBacktimed" end))
    registerAction("Command Set Shortcuts.Editing.Create Storyline", makeShortcutHandler(function() return "CreateConnectedStoryline" end))
    registerAction("Command Set Shortcuts.General.Sort Ascending", makeShortcutHandler(function() return "SortAscending" end))
    registerAction("Command Set Shortcuts.Effects.Retime: Rewind 2x", makeShortcutHandler(function() return "RetimeRewind2x" end))
    registerAction("Command Set Shortcuts.General.Add Custom Name…", makeShortcutHandler(function() return "AddNewNamePreset" end))
    registerAction("Command Set Shortcuts.General.Favorites", makeShortcutHandler(function() return "ShowFavorites" end))
    registerAction("Command Set Shortcuts.General.Connect with Selected Media Video", makeShortcutHandler(function() return "ConnectWithSelectedMediaVideo" end))
    registerAction("Command Set Shortcuts.General.Connect with Selected Media Audio", makeShortcutHandler(function() return "ConnectWithSelectedMediaAudio" end))
    registerAction("Command Set Shortcuts.Editing.Connect Video only to Primary Storyline", makeShortcutHandler(function() return "AnchorWithSelectedMediaVideo" end))
    registerAction("Command Set Shortcuts.Effects.Retime: Slow 50%", makeShortcutHandler(function() return "RetimeSlow50" end))
    registerAction("Command Set Shortcuts.Editing.Cut and Switch to Viewer Angle 6", makeShortcutHandler(function() return "CutSwitchAngle06" end))
    registerAction("Command Set Shortcuts.General.Play From Beginning", makeShortcutHandler(function() return "PlayFromStart" end))
    registerAction("Command Set Shortcuts.Windows.Show/Hide Effects Browser", makeShortcutHandler(function() return "ToggleMediaEffectsBrowser" end))
    registerAction("Command Set Shortcuts.Marking.Extract Captions", makeShortcutHandler(function() return "ExtractCaptionsFromClip" end))
    registerAction("Command Set Shortcuts.Marking.Set Range Start", makeShortcutHandler(function() return "SetSelectionStart" end))
    registerAction("Command Set Shortcuts.Marking.Apply Keyword Tag 2", makeShortcutHandler(function() return "AddKeywordGroup2" end))
    registerAction("Command Set Shortcuts.View.Zoom to Fit", makeShortcutHandler(function() return "ZoomToFit" end))
    registerAction("Command Set Shortcuts.General.Import iMovie iOS Projects", makeShortcutHandler(function() return "ImportiOSProjects" end))
    registerAction("Command Set Shortcuts.General.All Clips", makeShortcutHandler(function() return "AllClips" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Pan Left", makeShortcutHandler(function() return "PanLeft" end))
    registerAction("Command Set Shortcuts.Marking.Roles: Apply Dialogue Role", makeShortcutHandler(function() return "SetRoleDialogue" end))
    registerAction("Command Set Shortcuts.General.Reimport from Camera/Archive…", makeShortcutHandler(function() return "ReImportFilesFromCamera" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Go to Next Frame", makeShortcutHandler(function() return "JumpToNextFrame" end))
    registerAction("Command Set Shortcuts.Marking.Add Marker and Modify", makeShortcutHandler(function() return "AddAndEditMarker" end))
    registerAction("Command Set Shortcuts.Marking.Add Marker", makeShortcutHandler(function() return "AddMarker" end))
    registerAction("Command Set Shortcuts.Editing.Select Left and Right Edit Edges", makeShortcutHandler(function() return "SelectLeftRightEdge" end))
    registerAction("Command Set Shortcuts.Marking.Apply Keyword Tag 9", makeShortcutHandler(function() return "AddKeywordGroup9" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Pan Right", makeShortcutHandler(function() return "PanRight" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Go to Next Field", makeShortcutHandler(function() return "JumpToNextField" end))
    registerAction("Command Set Shortcuts.Editing.Add to Soloed Clips", makeShortcutHandler(function() return "AddToSoloed" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Reset Field of View", makeShortcutHandler(function() return "ResetFieldOfView" end))
    registerAction("Command Set Shortcuts.General.Previous Keyframe", makeShortcutHandler(function() return "PreviousKeyframe" end))
    registerAction("Command Set Shortcuts.Editing.Trim to Selection", makeShortcutHandler(function() return "TrimSelection" end))
    registerAction("Command Set Shortcuts.General.Detach Audio", makeShortcutHandler(function() return "DetachAudio" end))
    registerAction("Command Set Shortcuts.View.Zoom In", makeShortcutHandler(function() return "ZoomIn" end))
    registerAction("Command Set Shortcuts.Editing.Cut and Switch to Viewer Angle 15", makeShortcutHandler(function() return "CutSwitchAngle15" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Reset Angle", makeShortcutHandler(function() return "ResetPointOfView" end))
    registerAction("Command Set Shortcuts.View.Show More Filmstrip Frames", makeShortcutHandler(function() return "ShowMoreFilmstripFrames" end))
    registerAction("Command Set Shortcuts.Organization.Edit Smart Collection", makeShortcutHandler(function() return "EditSmartCollection" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Go Forward 10 Frames", makeShortcutHandler(function() return "JumpForward10Frames" end))
    registerAction("Command Set Shortcuts.Editing.Show/Hide Precision Editor", makeShortcutHandler(function() return "TogglePrecisionEditor" end))
    registerAction("Command Set Shortcuts.Editing.Overwrite - Backtimed", makeShortcutHandler(function() return "OverwriteWithSelectedMediaBacktimed" end))
    registerAction("Command Set Shortcuts.Editing.Previous Pick", makeShortcutHandler(function() return "SelectPreviousVariant" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Play Rate -1", makeShortcutHandler(function() return "PlayRateMinus1X" end))
    registerAction("Command Set Shortcuts.General.Clear Selected Ranges", makeShortcutHandler(function() return "ClearSelection" end))
    registerAction("Command Set Shortcuts.Effects.Retime: Speed Ramp to Zero", makeShortcutHandler(function() return "RetimeSpeedRampToZero" end))
    registerAction("Command Set Shortcuts.Editing.Select Above", makeShortcutHandler(function() return "SelectUpperItem" end))
    registerAction("Command Set Shortcuts.Editing.Audition: Replace and Add to Audition", makeShortcutHandler(function() return "ReplaceAndAddToAudition" end))
    registerAction("Command Set Shortcuts.Editing.Snapping", makeShortcutHandler(function() return "ToggleSnapping" end))
    registerAction("Command Set Shortcuts.Effects.Color Correction: Reset All Controls", makeShortcutHandler(function() return "ColorBoard-ResetAllPucks" end))
    registerAction("Command Set Shortcuts.Application.Hide Other Applications", makeShortcutHandler(function() return "HideOtherApplications" end))
    registerAction("Command Set Shortcuts.General.Show/Hide All Image Content", makeShortcutHandler(function() return "ToggleTransformOverscan" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Positive Timecode Entry", makeShortcutHandler(function() return "ShowTimecodeEntryPlusDelta" end))
    registerAction("Command Set Shortcuts.General.Snapshot Project", makeShortcutHandler(function() return "SnapshotProject" end))
    registerAction("Command Set Shortcuts.General.Rejected", makeShortcutHandler(function() return "ShowRejected" end))
    registerAction("Command Set Shortcuts.Editing.Switch to Viewer Angle 6", makeShortcutHandler(function() return "SwitchAngle06" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Play From Beginning of Clip", makeShortcutHandler(function() return "PlayFromBeginningOfClip" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Go to Previous Bank", makeShortcutHandler(function() return "SelectPreviousAngleBank" end))
    registerAction("Command Set Shortcuts.Editing.Insert Default Generator", makeShortcutHandler(function() return "InsertPlaceholder" end))
    registerAction("Command Set Shortcuts.Tools.Zoom Tool", makeShortcutHandler(function() return "SelectToolZoom" end))
    registerAction("Command Set Shortcuts.Editing.Nudge Audio Subframe Right Many", makeShortcutHandler(function() return "NudgeRightAudioMany" end))
    registerAction("Command Set Shortcuts.Editing.Overwrite Video only", makeShortcutHandler(function() return "OverwriteWithSelectedMediaVideo" end))
    registerAction("Command Set Shortcuts.Marking.New Smart Collection", makeShortcutHandler(function() return "NewSmartCollection" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Up", makeShortcutHandler(function() return "Up" end))
    registerAction("Command Set Shortcuts.Application.Undo Changes", makeShortcutHandler(function() return "UndoChanges" end))
    registerAction("Command Set Shortcuts.Marking.Roles: Apply Effects Role", makeShortcutHandler(function() return "SetRoleEffects" end))
    registerAction("Command Set Shortcuts.General.Save Color Effect Preset", makeShortcutHandler(function() return "SaveColorEffectPreset" end))
    registerAction("Command Set Shortcuts.General.Show Both Fields", makeShortcutHandler(function() return "ShowBothFields" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Go Back 10 Frames", makeShortcutHandler(function() return "JumpBackward10Frames" end))
    registerAction("Command Set Shortcuts.Editing.Extend Selection to Previous Clip", makeShortcutHandler(function() return "ExtendPreviousItem" end))
    registerAction("Command Set Shortcuts.Editing.Nudge Audio Subframe Left", makeShortcutHandler(function() return "NudgeLeftAudio" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Anaglyph Color", makeShortcutHandler(function() return "360AnaglyphColor" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Play Rate 8", makeShortcutHandler(function() return "PlayRate8X" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Play Around", makeShortcutHandler(function() return "PlayAroundCurrentFrame" end))
    registerAction("Command Set Shortcuts.Editing.Open Clip", makeShortcutHandler(function() return "OpenInTimeline" end))
    registerAction("Command Set Shortcuts.General.Show/Hide Angles in the Event Viewer", makeShortcutHandler(function() return "ShowMultiangleEventViewer" end))
    registerAction("Command Set Shortcuts.Editing.Cut and Switch to Viewer Angle 16", makeShortcutHandler(function() return "CutSwitchAngle16" end))
    registerAction("Command Set Shortcuts.Effects.Add Shape Mask", makeShortcutHandler(function() return "AddShapeMask" end))
    registerAction("Command Set Shortcuts.Editing.Reset Volume (0db)", makeShortcutHandler(function() return "VolumeZero" end))
    registerAction("Command Set Shortcuts.Effects.Show/Hide Comparison Viewer", makeShortcutHandler(function() return "ToggleCompareViewer" end))
    registerAction("Command Set Shortcuts.Effects.Add Color Board Effect", makeShortcutHandler(function() return "AddColorBoardEffect" end))
    registerAction("Command Set Shortcuts.Editing.Join Clips or Captions", makeShortcutHandler(function() return "JoinSelection" end))
    registerAction("Command Set Shortcuts.Application.Hide Application", makeShortcutHandler(function() return "HideApplication" end))
    registerAction("Command Set Shortcuts.Editing.Cut and Switch to Viewer Angle 10", makeShortcutHandler(function() return "CutSwitchAngle10" end))
    registerAction("Command Set Shortcuts.Effects.Switch Focus between Comparison Viewer and Main Viewer", makeShortcutHandler(function() return "ToggleCompareViewerFocus" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Play Rate -16", makeShortcutHandler(function() return "PlayRateMinus16X" end))
    registerAction("Command Set Shortcuts.Application.Preferences", makeShortcutHandler(function() return "ShowPreferences" end))
    registerAction("Command Set Shortcuts.Windows.Go to Color Inspector", makeShortcutHandler(function() return "GoToColorBoard" end))
    registerAction("Command Set Shortcuts.Windows.Show/Hide 360° Viewer", makeShortcutHandler(function() return "Toggle360Viewer" end))
    registerAction("Command Set Shortcuts.General.Sync To Monitoring Angle…", makeShortcutHandler(function() return "ToggleSyncTo" end))
    registerAction("Command Set Shortcuts.General.Library Properties", makeShortcutHandler(function() return "LibraryProperties" end))
    registerAction("Command Set Shortcuts.General.Reveal Proxy Media in Finder", makeShortcutHandler(function() return "RevealProxyInFinder" end))
    registerAction("Command Set Shortcuts.Editing.Nudge Left Many", makeShortcutHandler(function() return "NudgeLeftMany" end))
    registerAction("Command Set Shortcuts.Marking.Add Caption", makeShortcutHandler(function() return "AddAndEditCaption" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Timeline History Forward", makeShortcutHandler(function() return "SelectNextTimelineItem" end))
    registerAction("Command Set Shortcuts.General.Add Keyframe to Selected Effect in Animation Editor", makeShortcutHandler(function() return "AddKeyframe" end))
    registerAction("Command Set Shortcuts.General.Close Other Timelines", makeShortcutHandler(function() return "CloseOthers" end))
    registerAction("Command Set Shortcuts.Effects.Color Correction: Go to the Next Pane", makeShortcutHandler(function() return "ColorBoard-SwitchToNextTab" end))
    registerAction("Command Set Shortcuts.Editing.Audition: Duplicate from Original", makeShortcutHandler(function() return "DuplicateFromOriginal" end))
    registerAction("Command Set Shortcuts.Marking.Roles: Apply Music Role", makeShortcutHandler(function() return "SetRoleMusic" end))
    registerAction("Command Set Shortcuts.Effects.Color Correction: Select Next Control", makeShortcutHandler(function() return "ColorBoard-SelectNextPuck" end))
    registerAction("Command Set Shortcuts.Editing.Extend Selection Up", makeShortcutHandler(function() return "ExtendUp" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Audition: Preview", makeShortcutHandler(function() return "AuditionSelected" end))
    registerAction("Command Set Shortcuts.General.Transcode Media…", makeShortcutHandler(function() return "TranscodeMedia" end))
    registerAction("Command Set Shortcuts.General.Relink Proxy Files…", makeShortcutHandler(function() return "RelinkProxyFiles" end))
    registerAction("Command Set Shortcuts.Windows.Show/Hide Sidebar", makeShortcutHandler(function() return "ToggleEventsLibrary" end))
    registerAction("Command Set Shortcuts.Editing.Replace From Start", makeShortcutHandler(function() return "ReplaceWithSelectedMediaFromStart" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Play Rate 16", makeShortcutHandler(function() return "PlayRate16X" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Roll Clockwise", makeShortcutHandler(function() return "RollClockwise" end))
    registerAction("Command Set Shortcuts.Editing.Insert", makeShortcutHandler(function() return "InsertMedia" end))
    registerAction("Command Set Shortcuts.General.Export Final Cut Pro X XML", makeShortcutHandler(function() return "ExportXML" end))
    registerAction("Command Set Shortcuts.General.Auto Enhance Audio", makeShortcutHandler(function() return "EnhanceAudio" end))
    registerAction("Command Set Shortcuts.Windows.Show/Hide Browser", makeShortcutHandler(function() return "ToggleOrganizer" end))
    registerAction("Command Set Shortcuts.Tools.Hand Tool", makeShortcutHandler(function() return "SelectToolHand" end))
    registerAction("Command Set Shortcuts.Editing.Overwrite Audio only", makeShortcutHandler(function() return "OverwriteWithSelectedMediaAudio" end))
    registerAction("Command Set Shortcuts.Editing.Sync Selection to Monitoring Angle", makeShortcutHandler(function() return "AudioSyncMultiAngleItems" end))
    registerAction("Command Set Shortcuts.Editing.Cut and Switch to Viewer Angle 8", makeShortcutHandler(function() return "CutSwitchAngle08" end))
    registerAction("Command Set Shortcuts.Windows.Show/Hide Viewer on Second Display", makeShortcutHandler(function() return "ToggleFullScreenViewer" end))
    registerAction("Command Set Shortcuts.Organization.Analyze and Fix…", makeShortcutHandler(function() return "AnalyzeAndFix" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Go to Beginning", makeShortcutHandler(function() return "JumpToStart" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Play Rate -32", makeShortcutHandler(function() return "PlayRateMinus32X" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Tilt Up", makeShortcutHandler(function() return "TiltUp" end))
    registerAction("Command Set Shortcuts.Marking.Select Clip Range", makeShortcutHandler(function() return "SelectClip" end))
    registerAction("Command Set Shortcuts.Editing.Append Audio only to Storyline", makeShortcutHandler(function() return "AppendWithSelectedMediaAudio" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Go to Previous Field", makeShortcutHandler(function() return "JumpToPreviousField" end))
    registerAction("Command Set Shortcuts.Effects.Retime: Rewind 4x", makeShortcutHandler(function() return "RetimeRewind4x" end))
    registerAction("Command Set Shortcuts.Effects.Color Correction: Select Next Effect", makeShortcutHandler(function() return "ColorBoard-NextColorEffect" end))
    registerAction("Command Set Shortcuts.General.Show/Hide 360° Viewer in the Event Viewer", makeShortcutHandler(function() return "Toggle360EventViewer" end))
    registerAction("Command Set Shortcuts.Marking.Apply Keyword Tag 8", makeShortcutHandler(function() return "AddKeywordGroup8" end))
    registerAction("Command Set Shortcuts.General.Consolidate Library/Project/Event/Clip Media", makeShortcutHandler(function() return "ConsolidateFiles" end))
    registerAction("Command Set Shortcuts.Editing.Nudge Down", makeShortcutHandler(function() return "NudgeDown" end))
    registerAction("Command Set Shortcuts.General.Go to End", makeShortcutHandler(function() return "JumpToEnd" end))
    registerAction("Command Set Shortcuts.Editing.Select Next Angle", makeShortcutHandler(function() return "SelectNextAngle" end))
    registerAction("Command Set Shortcuts.Windows.Show/Hide Audio Meters", makeShortcutHandler(function() return "ToggleAudioMeter" end))
    registerAction("Command Set Shortcuts.Effects.Color Correction: Reset Selected Control", makeShortcutHandler(function() return "ColorBoard-ResetSelectedPuck" end))
    registerAction("Command Set Shortcuts.Effects.Add Color Curves Effect", makeShortcutHandler(function() return "AddColorCurvesEffect" end))
    registerAction("Command Set Shortcuts.Effects.Retime: Fast 8x", makeShortcutHandler(function() return "RetimeFast8x" end))
    registerAction("Command Set Shortcuts.General.Next Keyframe", makeShortcutHandler(function() return "NextKeyframe" end))
    registerAction("Command Set Shortcuts.Editing.Reference New Parent Clip", makeShortcutHandler(function() return "MakeIndependent" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Paste Timecode", makeShortcutHandler(function() return "PasteTimecode" end))
    registerAction("Command Set Shortcuts.Effects.Add Default Audio Effect", makeShortcutHandler(function() return "AddDefaultAudioEffect" end))
    registerAction("Command Set Shortcuts.Editing.Cut and Switch to Viewer Angle 13", makeShortcutHandler(function() return "CutSwitchAngle13" end))
    registerAction("Command Set Shortcuts.General.Find and Replace Title Text", makeShortcutHandler(function() return "FindAndReplaceTitleText" end))
    registerAction("Command Set Shortcuts.Windows.Previous Inspector Tab", makeShortcutHandler(function() return "SelectPreviousTab" end))
    registerAction("Command Set Shortcuts.General.Show/Hide Audio Lanes", makeShortcutHandler(function() return "AllAudioLanes" end))
    registerAction("Command Set Shortcuts.Editing.Cut and Switch to Viewer Angle 1", makeShortcutHandler(function() return "CutSwitchAngle01" end))
    registerAction("Command Set Shortcuts.General.Pick the next object in the Audition", makeShortcutHandler(function() return "SelectNextPick" end))
    registerAction("Command Set Shortcuts.Effects.Smart Conform", makeShortcutHandler(function() return "AutoReframe" end))
    registerAction("Command Set Shortcuts.General.Show Unused Media Only", makeShortcutHandler(function() return "FilterUnusedMedia" end))
    registerAction("Command Set Shortcuts.General.Sort Descending", makeShortcutHandler(function() return "SortDescending" end))
    registerAction("Command Set Shortcuts.Effects.Solo Animation", makeShortcutHandler(function() return "CollapseAnimations" end))
    registerAction("Command Set Shortcuts.Editing.Select Next Video Angle", makeShortcutHandler(function() return "SelectNextVideoAngle" end))
    registerAction("Command Set Shortcuts.General.Save Video Effect Preset", makeShortcutHandler(function() return "SaveVideoEffectPreset" end))
    registerAction("Command Set Shortcuts.General.Paste as Connected", makeShortcutHandler(function() return "PasteConnected" end))
    registerAction("Command Set Shortcuts.General.Close Project", makeShortcutHandler(function() return "CloseProject" end))
    registerAction("Command Set Shortcuts.General.Better Playback Quality", makeShortcutHandler(function() return "PlaybackBetterQuality" end))
    registerAction("Command Set Shortcuts.General.Remove Analysis Keywords", makeShortcutHandler(function() return "RemoveAllAnalysisKeywordsFromSelection" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Play Rate 32", makeShortcutHandler(function() return "PlayRate32X" end))
    registerAction("Command Set Shortcuts.Editing.Override Connections", makeShortcutHandler(function() return "ToggleOverrideConnections" end))
    registerAction("Command Set Shortcuts.Editing.Append Video only to Storyline", makeShortcutHandler(function() return "AppendWithSelectedMediaVideo" end))
    registerAction("Command Set Shortcuts.General.Color Correction: Switch Between Inside/Outside Masks", makeShortcutHandler(function() return "ColorBoard-ToggleInsideColorMask" end))
    registerAction("Command Set Shortcuts.Effects.Add Default Video Effect", makeShortcutHandler(function() return "AddDefaultVideoEffect" end))
    registerAction("Command Set Shortcuts.Editing.Blade All", makeShortcutHandler(function() return "BladeAll" end))
    registerAction("Command Set Shortcuts.Editing.Overwrite Audio only - Backtimed", makeShortcutHandler(function() return "OverwriteWithSelectedMediaAudioBacktimed" end))
    registerAction("Command Set Shortcuts.General.Apply Audio Fades", makeShortcutHandler(function() return "ApplyAudioFades" end))
    registerAction("Command Set Shortcuts.Windows.Show/Hide Inspector", makeShortcutHandler(function() return "ToggleInspector" end))
    registerAction("Command Set Shortcuts.General.Crossfade", makeShortcutHandler(function() return "ApplyAudioCrossFadesToAlignedClips" end))
    registerAction("Command Set Shortcuts.Editing.Select Right Edge", makeShortcutHandler(function() return "SelectRightEdge" end))
    registerAction("Command Set Shortcuts.General.Close Library", makeShortcutHandler(function() return "CloseLibrary" end))
    registerAction("Command Set Shortcuts.General.Better Playback Performance", makeShortcutHandler(function() return "PlaybackBetterPerformance" end))
    registerAction("Command Set Shortcuts.Editing.Select Left Video Edge", makeShortcutHandler(function() return "SelectLeftEdgeVideo" end))
    registerAction("Command Set Shortcuts.General.Go to Comparison Viewer", makeShortcutHandler(function() return "GoToCompareViewer" end))
    registerAction("Command Set Shortcuts.Effects.Apply Color Correction from Three Clips Back", makeShortcutHandler(function() return "SetCorrectionFromEdit-Back-3" end))
    registerAction("Command Set Shortcuts.Effects.Match Color…", makeShortcutHandler(function() return "ToggleMatchColor" end))
    registerAction("Command Set Shortcuts.Tools.Trim Tool", makeShortcutHandler(function() return "SelectToolTrim" end))
    registerAction("Command Set Shortcuts.General.Go to Event Viewer", makeShortcutHandler(function() return "GoToEventViewer" end))
    registerAction("Command Set Shortcuts.Organization.New Folder", makeShortcutHandler(function() return "NewFolder" end))
    registerAction("Command Set Shortcuts.Windows.Background Tasks", makeShortcutHandler(function() return "GoToBackgroundTasks" end))
    registerAction("Command Set Shortcuts.Editing.Select Previous Angle", makeShortcutHandler(function() return "SelectPreviousAngle" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Mirror VR Headset", makeShortcutHandler(function() return "ToggleMirrorHMD" end))
    registerAction("Command Set Shortcuts.General.Remove Audio Fades", makeShortcutHandler(function() return "RemoveAudioFades" end))
    registerAction("Command Set Shortcuts.General.Open Library", makeShortcutHandler(function() return "OpenLibrary" end))
    registerAction("Command Set Shortcuts.Effects.Color Correction: Nudge Control Left", makeShortcutHandler(function() return "ColorBoard-NudgePuckLeft" end))
    registerAction("Command Set Shortcuts.General.Edit Previous Marker", makeShortcutHandler(function() return "EditPreviousMarker" end))
    registerAction("Command Set Shortcuts.Application.Redo Changes", makeShortcutHandler(function() return "RedoChanges" end))
    registerAction("Command Set Shortcuts.Editing.Nudge Audio Subframe Right", makeShortcutHandler(function() return "NudgeRightAudio" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Anaglyph Monochrome", makeShortcutHandler(function() return "360AnaglyphMono" end))
    registerAction("Command Set Shortcuts.General.Toggle Audio Fade Out", makeShortcutHandler(function() return "ToggleFadeOutAudio" end))
    registerAction("Command Set Shortcuts.Editing.Raise Volume 1 dB", makeShortcutHandler(function() return "VolumeUp" end))
    registerAction("Command Set Shortcuts.Windows.Go To Photos and Audio", makeShortcutHandler(function() return "ToggleEventMediaBrowser" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Go to Previous Edit", makeShortcutHandler(function() return "PreviousEdit" end))
    registerAction("Command Set Shortcuts.General.Custom Speed…", makeShortcutHandler(function() return "RetimeCustomSpeed" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Cut/Switch Multicam Audio Only", makeShortcutHandler(function() return "MultiAngleEditStyleAudio" end))
    registerAction("Command Set Shortcuts.Effects.Retime: Slow 10%", makeShortcutHandler(function() return "RetimeSlow10" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Anaglyph Outline", makeShortcutHandler(function() return "360AnaglyphOutline" end))
    registerAction("Command Set Shortcuts.Editing.Split Captions", makeShortcutHandler(function() return "SplitCaptions" end))
    registerAction("Command Set Shortcuts.General.Render All", makeShortcutHandler(function() return "RenderAll" end))
    registerAction("Command Set Shortcuts.Windows.Show/Hide Angles", makeShortcutHandler(function() return "ShowMultiangleViewer" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Loop Playback", makeShortcutHandler(function() return "LoopPlayback" end))
    registerAction("Command Set Shortcuts.Editing.Trim To Playhead", makeShortcutHandler(function() return "TrimToPlayhead" end))
    registerAction("Command Set Shortcuts.Editing.Trim Start", makeShortcutHandler(function() return "TrimStart" end))
    registerAction("Command Set Shortcuts.View.View Clip Names", makeShortcutHandler(function() return "ToggleShowTimelineItemTitles" end))
    registerAction("Command Set Shortcuts.Organization.Merge Events", makeShortcutHandler(function() return "MergeEvents" end))
    registerAction("Command Set Shortcuts.Effects.Paste Effects", makeShortcutHandler(function() return "PasteAllAttributes" end))
    registerAction("Command Set Shortcuts.Tools.Crop Tool", makeShortcutHandler(function() return "SelectCropTool" end))
    registerAction("Command Set Shortcuts.General.No Ratings or Keywords", makeShortcutHandler(function() return "NoRatingsOrKeywords" end))
    registerAction("Command Set Shortcuts.View.Show Fewer Filmstrip Frames", makeShortcutHandler(function() return "ShowFewerFilmstripFrames" end))
    registerAction("Command Set Shortcuts.Editing.Cut and Switch to Viewer Angle 3", makeShortcutHandler(function() return "CutSwitchAngle03" end))
    registerAction("Command Set Shortcuts.Windows.Source Timecode", makeShortcutHandler(function() return "GoToTimecodeView" end))
    registerAction("Command Set Shortcuts.Marking.Roles: Apply Titles Role", makeShortcutHandler(function() return "SetRoleTitles" end))
    registerAction("Command Set Shortcuts.Marking.Set Additional Range Start", makeShortcutHandler(function() return "AddNewSelectionStart" end))
    registerAction("Command Set Shortcuts.Editing.Switch to Viewer Angle 14", makeShortcutHandler(function() return "SwitchAngle14" end))
    registerAction("Command Set Shortcuts.Effects.Retime: Create Normal Speed Segment", makeShortcutHandler(function() return "RetimeCreateSegment" end))
    registerAction("Command Set Shortcuts.Marking.Apply Keyword Tag 5", makeShortcutHandler(function() return "AddKeywordGroup5" end))
    registerAction("Command Set Shortcuts.General.Cut Keyframes", makeShortcutHandler(function() return "CutKeyframes" end))
    registerAction("Command Set Shortcuts.Effects.Paste Attributes…", makeShortcutHandler(function() return "PasteSomeAttributes" end))
    registerAction("Command Set Shortcuts.Windows.Record Voiceover", makeShortcutHandler(function() return "GoToVoiceoverRecordView" end))
    registerAction("Command Set Shortcuts.View.Clip Appearance: Clip Labels Only", makeShortcutHandler(function() return "ClipAppearanceTitleOnly" end))
    registerAction("Command Set Shortcuts.General.Connect with Selected Media Backtimed", makeShortcutHandler(function() return "ConnectWithSelectedMediaBacktimed" end))
    registerAction("Command Set Shortcuts.Editing.Select Left Edge", makeShortcutHandler(function() return "SelectLeftEdge" end))
    registerAction("Command Set Shortcuts.General.Import Captions…", makeShortcutHandler(function() return "ImportCaptions" end))
    registerAction("Command Set Shortcuts.Application.Quit", makeShortcutHandler(function() return "Quit" end))
    registerAction("Command Set Shortcuts.Editing.Cut and Switch to Viewer Angle 11", makeShortcutHandler(function() return "CutSwitchAngle11" end))
    registerAction("Command Set Shortcuts.Marking.Favorite", makeShortcutHandler(function() return "Favorite" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Stop", makeShortcutHandler(function() return "Stop" end))
    registerAction("Command Set Shortcuts.Marking.Clear Range End", makeShortcutHandler(function() return "ClearSelectionEnd" end))
    registerAction("Command Set Shortcuts.Organization.Reveal In Browser", makeShortcutHandler(function() return "RevealInEventsBrowser" end))
    registerAction("Command Set Shortcuts.Editing.Create Audition", makeShortcutHandler(function() return "CollapseSelectionIntoVariant" end))
    registerAction("Command Set Shortcuts.Tools.Position Tool", makeShortcutHandler(function() return "SelectToolPlacement" end))
    registerAction("Command Set Shortcuts.View.View Alpha Color Channel", makeShortcutHandler(function() return "ShowColorChannelsAlpha" end))
    registerAction("Command Set Shortcuts.Effects.Retime: Slow 25%", makeShortcutHandler(function() return "RetimeSlow25" end))
    registerAction("Command Set Shortcuts.Editing.Cut and Switch to Viewer Angle 14", makeShortcutHandler(function() return "CutSwitchAngle14" end))
    registerAction("Command Set Shortcuts.General.Delete Generated Library/Event/Project/Clip Files", makeShortcutHandler(function() return "PurgeRenderFiles" end))
    registerAction("Command Set Shortcuts.General.Replace At Playhead", makeShortcutHandler(function() return "ReplaceWithSelectedMediaAtPlayhead" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Go to Next Subframe", makeShortcutHandler(function() return "JumpToNextSubframe" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Cut/Switch Multicam Video Only", makeShortcutHandler(function() return "MultiAngleEditStyleVideo" end))
    registerAction("Command Set Shortcuts.General.Adjust Volume Absolute…", makeShortcutHandler(function() return "AdjustVolumeAbsolute" end))
    registerAction("Command Set Shortcuts.Marking.Set Range End", makeShortcutHandler(function() return "SetSelectionEnd" end))
    registerAction("Command Set Shortcuts.Editing.Switch to Viewer Angle 11", makeShortcutHandler(function() return "SwitchAngle11" end))
    registerAction("Command Set Shortcuts.Editing.Move Playhead Position", makeShortcutHandler(function() return "ShowTimecodeEntryPlayhead" end))
    registerAction("Command Set Shortcuts.Windows.Go to Viewer", makeShortcutHandler(function() return "GoToViewer" end))
    registerAction("Command Set Shortcuts.Editing.Select All", makeShortcutHandler(function() return "SelectAll" end))
    registerAction("Command Set Shortcuts.View.Decrease Clip Height", makeShortcutHandler(function() return "DecreaseThumbnailSize" end))
    registerAction("Command Set Shortcuts.Effects.Remove Attributes…", makeShortcutHandler(function() return "RemoveAttributes" end))
    registerAction("Command Set Shortcuts.Effects.Copy Effects", makeShortcutHandler(function() return "CopyAttributes" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Previous Marker", makeShortcutHandler(function() return "PreviousMarker" end))
    registerAction("Command Set Shortcuts.General.Update Projects and Events…", makeShortcutHandler(function() return "UpdateProjectsAndEvents" end))
    registerAction("Command Set Shortcuts.General.Pick the previous object in the Audition", makeShortcutHandler(function() return "SelectPreviousPick" end))
    registerAction("Command Set Shortcuts.General.Toggle A/V Output on/off", makeShortcutHandler(function() return "ToggleVideoOut" end))
    registerAction("Command Set Shortcuts.Windows.Default", makeShortcutHandler(function() return "DefaultLayout" end))
    registerAction("Command Set Shortcuts.Windows.Dual Displays", makeShortcutHandler(function() return "DualDisplaysLayout" end))
    registerAction("Command Set Shortcuts.Windows.Go to Timeline", makeShortcutHandler(function() return "GoToTimeline" end))
    registerAction("Command Set Shortcuts.Editing.Switch to Viewer Angle 1", makeShortcutHandler(function() return "SwitchAngle01" end))
    registerAction("Command Set Shortcuts.Windows.Show Title/Action Safe Zones", makeShortcutHandler(function() return "SetDisplayBroadcastSafe" end))
    registerAction("Command Set Shortcuts.Editing.Change Duration", makeShortcutHandler(function() return "ShowTimecodeEntryDuration" end))
    registerAction("Command Set Shortcuts.Windows.Show/Hide Timeline on Second Display", makeShortcutHandler(function() return "ToggleFullScreenTimeline" end))
    registerAction("Command Set Shortcuts.Editing.Nudge Up", makeShortcutHandler(function() return "NudgeUp" end))
    registerAction("Command Set Shortcuts.General.Move to Trash", makeShortcutHandler(function() return "MoveToTrash" end))
    registerAction("Command Set Shortcuts.Effects.Retime Video Quality: Normal", makeShortcutHandler(function() return "RetimeVideoQualityNormal" end))
    registerAction("Command Set Shortcuts.Effects.Retime: Rewind", makeShortcutHandler(function() return "RetimeRewind1x" end))
    registerAction("Command Set Shortcuts.General.Reveal in Finder", makeShortcutHandler(function() return "RevealInFinder" end))
    registerAction("Command Set Shortcuts.General.Clip Skimming", makeShortcutHandler(function() return "ToggleItemSkimming" end))
    registerAction("Command Set Shortcuts.Effects.Automatic Speed", makeShortcutHandler(function() return "RetimeConformSpeed" end))
    registerAction("Command Set Shortcuts.Editing.Switch to Viewer Angle 3", makeShortcutHandler(function() return "SwitchAngle03" end))
    registerAction("Command Set Shortcuts.Windows.Color & Effects", makeShortcutHandler(function() return "ColorEffectsLayout" end))
    registerAction("Command Set Shortcuts.General.Edit Custom Names…", makeShortcutHandler(function() return "EditNamePreset" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Play Reverse", makeShortcutHandler(function() return "PlayReverse" end))
    registerAction("Command Set Shortcuts.Marking.Add ToDo Marker", makeShortcutHandler(function() return "AddToDoMarker" end))
    registerAction("Command Set Shortcuts.General.New Library…", makeShortcutHandler(function() return "NewLibrary" end))
    registerAction("Command Set Shortcuts.Editing.Cut and Switch to Viewer Angle 2", makeShortcutHandler(function() return "CutSwitchAngle02" end))
    registerAction("Command Set Shortcuts.Marking.Unrate", makeShortcutHandler(function() return "Unfavorite" end))
    registerAction("Command Set Shortcuts.Editing.Cut and Switch to Viewer Angle 12", makeShortcutHandler(function() return "CutSwitchAngle12" end))
    registerAction("Command Set Shortcuts.Editing.Lower Volume 1 dB", makeShortcutHandler(function() return "VolumeDown" end))
    registerAction("Command Set Shortcuts.Effects.Retime: Instant Replay", makeShortcutHandler(function() return "RetimeInstantReplay" end))
    registerAction("Command Set Shortcuts.Editing.Select Left and Right Audio Edit Edges", makeShortcutHandler(function() return "SelectLeftRightEdgeAudio" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Play Reverse", makeShortcutHandler(function() return "JogBackward" end))
    registerAction("Command Set Shortcuts.General.Relink Files…", makeShortcutHandler(function() return "RelinkFiles" end))
    registerAction("Command Set Shortcuts.General.Connect with Selected Media", makeShortcutHandler(function() return "ConnectWithSelectedMedia" end))
    registerAction("Command Set Shortcuts.Editing.Break Apart Clip Items", makeShortcutHandler(function() return "BreakApartClipItems" end))
    registerAction("Command Set Shortcuts.Editing.Select Previous Video Angle", makeShortcutHandler(function() return "SelectPreviousVideoAngle" end))
    registerAction("Command Set Shortcuts.General.Adjust Content Created Date and Time…", makeShortcutHandler(function() return "ModifyContentCreationDate" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Play Rate -2", makeShortcutHandler(function() return "PlayRateMinus2X" end))
    registerAction("Command Set Shortcuts.Editing.Duplicate", makeShortcutHandler(function() return "Duplicate" end))
    registerAction("Command Set Shortcuts.Editing.Cut and Switch to Viewer Angle 5", makeShortcutHandler(function() return "CutSwitchAngle05" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Play Full Screen", makeShortcutHandler(function() return "PlayFullscreen" end))
    registerAction("Command Set Shortcuts.Editing.Trim End", makeShortcutHandler(function() return "TrimEnd" end))
    registerAction("Command Set Shortcuts.Editing.Nudge Left", makeShortcutHandler(function() return "NudgeLeft" end))
    registerAction("Command Set Shortcuts.Marking.Go to Keyword Editor", makeShortcutHandler(function() return "OrderFrontKeywordEditor" end))
    registerAction("Command Set Shortcuts.Effects.Add Color Hue/Saturation Effect", makeShortcutHandler(function() return "AddHueSaturationEffect" end))
    registerAction("Command Set Shortcuts.Effects.Show/Hide Frame Browser", makeShortcutHandler(function() return "ToggleCompareFrameHUD" end))
    registerAction("Command Set Shortcuts.Effects.Color Correction: Go to the Previous Pane", makeShortcutHandler(function() return "ColorBoard-SwitchToPreviousTab" end))
    registerAction("Command Set Shortcuts.Editing.Switch to Viewer Angle 5", makeShortcutHandler(function() return "SwitchAngle05" end))
    registerAction("Command Set Shortcuts.Windows.Go to Library Browser", makeShortcutHandler(function() return "ToggleEventLibraryBrowser" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Set Monitoring Angle", makeShortcutHandler(function() return "MultiAngleVideoSetUsingSkimmedObject" end))
    registerAction("Command Set Shortcuts.Editing.Extend Selection to Next Clip", makeShortcutHandler(function() return "ExtendNextItem" end))
    registerAction("Command Set Shortcuts.View.Show/Hide Skimmer Info", makeShortcutHandler(function() return "ShowSkimmerInfo" end))
    registerAction("Command Set Shortcuts.General.Import Final Cut Pro X XML", makeShortcutHandler(function() return "ImportXML" end))
    registerAction("Command Set Shortcuts.Tools.Transform Tool", makeShortcutHandler(function() return "SelectTransformTool" end))
    registerAction("Command Set Shortcuts.General.Duplicate Project As…", makeShortcutHandler(function() return "DuplicateProjectAs" end))
    registerAction("Command Set Shortcuts.Effects.Retime: Hold", makeShortcutHandler(function() return "RetimeHold" end))
    registerAction("Command Set Shortcuts.Marking.Set Additional Range End", makeShortcutHandler(function() return "AddNewSelectionEnd" end))
    registerAction("Command Set Shortcuts.Effects.Color Correction: Nudge Control Up", makeShortcutHandler(function() return "ColorBoard-NudgePuckUp" end))
    registerAction("Command Set Shortcuts.Windows.Show/Hide Transitions Browser", makeShortcutHandler(function() return "ToggleMediaTransitionsBrowser" end))
    registerAction("Command Set Shortcuts.General.Adjust Volume Relative…", makeShortcutHandler(function() return "AdjustVolumeRelative" end))
    registerAction("Command Set Shortcuts.Windows.View Roles in Timeline Index", makeShortcutHandler(function() return "SwitchToRolesTabInTimelineIndex" end))
    registerAction("Command Set Shortcuts.General.Show Both Fields in the Event Viewer", makeShortcutHandler(function() return "ShowBothFieldsEventViewer" end))
    registerAction("Command Set Shortcuts.Editing.Expand Audio/Video", makeShortcutHandler(function() return "ShowAVSplit" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Go to Previous Frame", makeShortcutHandler(function() return "JumpToPreviousFrame" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Audio Skimming", makeShortcutHandler(function() return "ToggleAudioScrubbing" end))
    registerAction("Command Set Shortcuts.Editing.Replace with Gap", makeShortcutHandler(function() return "ReplaceWithGap" end))
    registerAction("Command Set Shortcuts.Windows.View Clips in Timeline Index", makeShortcutHandler(function() return "SwitchToClipsTabInTimelineIndex" end))
    registerAction("Command Set Shortcuts.Editing.Switch to Viewer Angle 8", makeShortcutHandler(function() return "SwitchAngle08" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Superimpose", makeShortcutHandler(function() return "360Superimpose" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Play to End", makeShortcutHandler(function() return "PlayToOut" end))
    registerAction("Command Set Shortcuts.Editing.Source Media: Audio Only", makeShortcutHandler(function() return "AVEditModeAudio" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Right Eye Only", makeShortcutHandler(function() return "360RightEyeOnly" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Down", makeShortcutHandler(function() return "Down" end))
    registerAction("Command Set Shortcuts.Editing.Select Next Clip", makeShortcutHandler(function() return "SelectNextItem" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Go to Previous Subframe", makeShortcutHandler(function() return "JumpToPreviousSubframe" end))
    registerAction("Command Set Shortcuts.Organization.Synchronize Clips…", makeShortcutHandler(function() return "SynchronizeClips" end))
    registerAction("Command Set Shortcuts.Editing.Switch to Viewer Angle 10", makeShortcutHandler(function() return "SwitchAngle10" end))
    registerAction("Command Set Shortcuts.Effects.Color Board: Switch to the Exposure Pane", makeShortcutHandler(function() return "ColorBoard-SwitchToExposureTab" end))
    registerAction("Command Set Shortcuts.General.Find", makeShortcutHandler(function() return "Find" end))
    registerAction("Command Set Shortcuts.Editing.Select Clip", makeShortcutHandler(function() return "SelectClipAtPlayhead" end))
    registerAction("Command Set Shortcuts.Editing.Select Previous Clip", makeShortcutHandler(function() return "SelectPreviousItem" end))
    registerAction("Command Set Shortcuts.Editing.Connect to Primary Storyline - Backtimed", makeShortcutHandler(function() return "AnchorWithSelectedMediaBacktimed" end))
    registerAction("Command Set Shortcuts.View.Clip Appearance: Large Waveforms", makeShortcutHandler(function() return "ClipAppearanceAudioMostly" end))
    registerAction("Command Set Shortcuts.Editing.Connect to Primary Storyline", makeShortcutHandler(function() return "AnchorWithSelectedMedia" end))
    registerAction("Command Set Shortcuts.Editing.Insert Video only", makeShortcutHandler(function() return "InsertMediaVideo" end))
    registerAction("Command Set Shortcuts.Organization.Continuous Playback", makeShortcutHandler(function() return "ToggleOrganizerPlaythrough" end))
    registerAction("Command Set Shortcuts.Effects.Connect Default Lower Third", makeShortcutHandler(function() return "AddBasicLowerThird" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Play Rate -8", makeShortcutHandler(function() return "PlayRateMinus8X" end))
    registerAction("Command Set Shortcuts.Effects.Retime Editor", makeShortcutHandler(function() return "ShowRetimeEditor" end))
    registerAction("Command Set Shortcuts.Editing.Insert/Connect Freeze Frame", makeShortcutHandler(function() return "FreezeFrame" end))
    registerAction("Command Set Shortcuts.Editing.Set Volume to Silence (-∞)", makeShortcutHandler(function() return "VolumeMinusInfinity" end))
    registerAction("Command Set Shortcuts.General.Close Window", makeShortcutHandler(function() return "CloseWindow" end))
    registerAction("Command Set Shortcuts.General.Skimming", makeShortcutHandler(function() return "ToggleSkimming" end))
    registerAction("Command Set Shortcuts.Effects.Color Correction: Select Previous Control", makeShortcutHandler(function() return "ColorBoard-SelectPreviousPuck" end))
    registerAction("Command Set Shortcuts.General.Modify Marker", makeShortcutHandler(function() return "EditMarker" end))
    registerAction("Command Set Shortcuts.General.Project Properties", makeShortcutHandler(function() return "ProjectInfo" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Go to Range End", makeShortcutHandler(function() return "GotoOut" end))
    registerAction("Command Set Shortcuts.General.Nudge Marker Left", makeShortcutHandler(function() return "NudgeMarkerLeft" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Play Rate -4", makeShortcutHandler(function() return "PlayRateMinus4X" end))
    registerAction("Command Set Shortcuts.Marking.Roles: Apply Video Role", makeShortcutHandler(function() return "SetRoleVideo" end))
    registerAction("Command Set Shortcuts.Windows.Show Video Waveform", makeShortcutHandler(function() return "ToggleWaveform" end))
    registerAction("Command Set Shortcuts.Editing.Nudge Audio Subframe Left Many", makeShortcutHandler(function() return "NudgeLeftAudioMany" end))
    registerAction("Command Set Shortcuts.Windows.Next Inspector Tab", makeShortcutHandler(function() return "SelectNextTab" end))
    registerAction("Command Set Shortcuts.Editing.Enable/Disable Clip", makeShortcutHandler(function() return "EnableOrDisableEdit" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Play/Pause", makeShortcutHandler(function() return "PlayPause" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Play from Playhead", makeShortcutHandler(function() return "PlayFromAlternatePlayhead" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Monitor Audio", makeShortcutHandler(function() return "MultiAngleAddAudioUsingSkimmedObject" end))
    registerAction("Command Set Shortcuts.Windows.Go to Inspector", makeShortcutHandler(function() return "GoToInspector" end))
    registerAction("Command Set Shortcuts.Editing.Nudge Right", makeShortcutHandler(function() return "NudgeRight" end))
    registerAction("Command Set Shortcuts.Editing.Connect Audio only to Primary Storyline - Backtimed", makeShortcutHandler(function() return "AnchorWithSelectedMediaAudioBacktimed" end))
    registerAction("Command Set Shortcuts.View.Clip Appearance: Increase Waveform Size", makeShortcutHandler(function() return "ClipAppearanceAudioBigger" end))
    registerAction("Command Set Shortcuts.View.View Green Color Channel", makeShortcutHandler(function() return "ShowColorChannelsGreen" end))
    registerAction("Command Set Shortcuts.View.Show/Hide Video Animation", makeShortcutHandler(function() return "ShowCurveEditor" end))
    registerAction("Command Set Shortcuts.Share.Send to Compressor", makeShortcutHandler(function() return "SendToCompressor" end))
    registerAction("Command Set Shortcuts.Effects.Retime: Fast 2x", makeShortcutHandler(function() return "RetimeFast2x" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Timeline History Back", makeShortcutHandler(function() return "SelectPreviousTimelineItem" end))
    registerAction("Command Set Shortcuts.Windows.Show Histogram", makeShortcutHandler(function() return "ToggleHistogram" end))
    registerAction("Command Set Shortcuts.Editing.Select Right Video Edge", makeShortcutHandler(function() return "SelectRightEdgeVideo" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Go to Range Start", makeShortcutHandler(function() return "GotoIn" end))
    registerAction("Command Set Shortcuts.Application.Keyboard Customization", makeShortcutHandler(function() return "KeyboardCustomization" end))
    registerAction("Command Set Shortcuts.Editing.Switch to Viewer Angle 16", makeShortcutHandler(function() return "SwitchAngle16" end))
    registerAction("Command Set Shortcuts.Playback/Navigation.Tilt Down", makeShortcutHandler(function() return "TiltDown" end))
    registerAction("Command Set Shortcuts.Marking.Remove All Keywords From Selection", makeShortcutHandler(function() return "RemoveAllKeywordsFromSelection" end))
    registerAction("Command Set Shortcuts.View.Clip Appearance: Large Filmstrips", makeShortcutHandler(function() return "ClipAppearanceVideoMostly" end))
    registerAction("Command Set Shortcuts.View.Show/Hide Audio Animation", makeShortcutHandler(function() return "ShowAudioCurveEditor" end))
    registerAction("Command Set Shortcuts.Marking.Edit Roles…", makeShortcutHandler(function() return "EditRoles" end))
    registerAction("Command Set Shortcuts.Editing.Toggle Storyline Mode", makeShortcutHandler(function() return "ToggleAnchoredSpinesMode" end))
    registerAction("Command Set Shortcuts.Effects.Match Audio…", makeShortcutHandler(function() return "MatchAudio" end))
    registerAction("Command Set Shortcuts.Editing.Lift from Storyline", makeShortcutHandler(function() return "LiftFromSpine" end))
    registerAction("Command Set Shortcuts.General.Send IMF Package to Compressor", makeShortcutHandler(function() return "SendIMFPackageToCompressor" end))
    registerAction("Command Set Shortcuts.Effects.Add Color Wheels Effect", makeShortcutHandler(function() return "AddColorWheelsEffect" end))

    return mod
end

return plugin
