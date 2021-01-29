--- === cp.apple.finalcutpro.viewer.ControlBar ===
---
--- Represents the bottom "control" bar on a [Viewer](cp.apple.finalcutpro.viewer.Viewer.md)
--- which contains the play/pause button, timecode, audio meters, etc.

local log               = require "hs.logger" .new "ViewerCB"

local canvas            = require "hs.canvas"
local eventtap          = require "hs.eventtap"
local geometry          = require "hs.geometry"
local pasteboard        = require "hs.pasteboard"
local timer             = require "hs.timer"

local just              = require "cp.just"
local prop              = require "cp.prop"
local tools             = require "cp.tools"
local axutils           = require "cp.ui.axutils"
local Button            = require "cp.ui.Button"
local Group             = require "cp.ui.Group"
local Image             = require "cp.ui.Image"
local StaticText        = require "cp.ui.StaticText"

local rightToLeft       = axutils.compareRightToLeft
local cache             = axutils.cache
local childFromBottom   = axutils.childFromBottom
local childFromRight    = axutils.childFromRight

local doAfter           = timer.doAfter
local doUntil           = just.doUntil
local find              = string.find
local ninjaMouseClick   = tools.ninjaMouseClick

local ControlBar = Group:subclass("cp.apple.finalcutpro.viewer.ControlBar")

--- cp.apple.finalcutpro.viewer.ControlBar.matches(element) -> boolean
--- Function
--- Checks if the element is a `ControlBar` instance.
---
--- Parameters:
--- * element       - The `axuielement` to check.
---
--- Returns:
--- * `true` if it matches the pattern for a `Viewer` `ControlBar`.
function ControlBar.static.matches(element)
    if Group.matches(element) and #element >= 4 then
        -- Note: sorting right-to-left
        local children = axutils.children(element, rightToLeft)
        return
            (
                -- Normal Control Bar:
                #children >= 5
                and Button.matches(children[1])
                and Button.matches(children[2])
                and StaticText.matches(children[3])
                and Button.matches(children[4])
                and Button.matches(children[5])
            )
            or
            (
                -- Timecode Entry Mode:
                #children >= 4
                and Button.matches(children[1])
                and Button.matches(children[2])
                and StaticText.matches(children[3])
                and Image.matches(children[4])
            )
    end
    return false
end

--- cp.apple.finalcutpro.viewer.ControlBar(viewer)
--- Constructor
--- Creates a new `ControlBar` instance.
---
--- Parameters:
---  * viewer       - The [Viewer](cp.apple.finalcutpro.viewer.Viewer.md) instance.
---
--- Returns:
---  * The new `ControlBar`.
function ControlBar:initialize(viewer)
    local uiFinder = viewer.UI:mutate(function(original)
        return cache(self, "_ui", function()
            return childFromBottom(original(), 1, ControlBar.matches)
        end, ControlBar.matches)
    end)

    Group.initialize(self, viewer, uiFinder)
end

--- cp.apple.finalcutpro.viewer.playFullScreen <cp.ui.Button>
--- Field
--- Play Full Screen Button.
function ControlBar.lazy.value:playFullScreen()
    return Button(self, self.UI:mutate(function(original)
        return childFromRight(original(), 1, Button.matches)
    end))
end

--- cp.apple.finalcutpro.viewer.audioMeters <cp.ui.Button>
--- Field
--- Audio Meters button.
function ControlBar.lazy.value:audioMeters()
    return Button(self, self.UI:mutate(function(original)
        return childFromRight(original(), 2, Button.matches)
    end))
end

--- cp.apple.finalcutpro.viewer.timecodeField <cp.ui.StaticText>
--- Field
--- Timecode Field
function ControlBar.lazy.value:timecodeField()
    return StaticText(self, self.UI:mutate(function(original)
        return childFromRight(original(), 1, StaticText.matches)
    end))
end

--- cp.apple.finalcutpro.viewer.ControlBar.timecode <cp.prop: string; live>
--- Field
--- The current timecode value, with the format "hh:mm:ss:ff". Setting also supports "hh:mm:ss;ff".
--- The property can be watched to get notifications of changes.
--- The prop will use the "Paste Timecode" shortcut to set the timecode value if a shortcut
--- key is associated, otherwise it will attempt to use GUI Scripting methods.
function ControlBar.lazy.prop:timecode()
    local tcField = self.timecodeField
    return tcField.value:mutate(
        function(original)
            return original()
        end,
        function(timecodeValue, original)
            --------------------------------------------------------------------------------
            -- Make sure there's a timecode value:
            --------------------------------------------------------------------------------
            if not timecodeValue then
                log.ef("cp.apple.finalcutpro.viewer.Viewer.timecode: Timecode value is invalid: %s.", timecodeValue)
                return
            end

            --------------------------------------------------------------------------------
            -- Check to see if we can use the "Paste Timecode" shortcut:
            --------------------------------------------------------------------------------
            local shortcuts = self:app():getCommandShortcuts("PasteTimecode")
            if shortcuts and #shortcuts > 0 then
                --------------------------------------------------------------------------------
                -- Use "Paste Timecode" method:
                --------------------------------------------------------------------------------
                if timecodeValue then
                    --------------------------------------------------------------------------------
                    -- Get current Pasteboard Contents:
                    --------------------------------------------------------------------------------
                    local originalPasteboard = pasteboard.getContents()

                    --------------------------------------------------------------------------------
                    -- Set Pasteboard Contents to timecode value we want to go to:
                    --------------------------------------------------------------------------------
                    pasteboard.setContents(timecodeValue)

                    --------------------------------------------------------------------------------
                    -- Wait until the timecode is on the pasteboard:
                    --------------------------------------------------------------------------------
                    local pasteboardReady = doUntil(function()
                        return pasteboard.getContents() == timecodeValue
                    end, 5)

                    if not pasteboardReady then
                        log.ef("cp.apple.finalcutpro.viewer.Viewer.timecode: Failed to add timecode to pasteboard.")
                        return
                    else
                        local app = self:app():application()
                        shortcuts[1]:trigger(app)
                    end

                    --------------------------------------------------------------------------------
                    -- Restore Original Pasteboard Contents:
                    --------------------------------------------------------------------------------
                    if originalPasteboard then
                        doAfter(0.1, function()
                            pasteboard.setContents(originalPasteboard)
                        end)
                    end
                end
            else
                --------------------------------------------------------------------------------
                -- Use GUI Scripting Method:
                --------------------------------------------------------------------------------
                log.wf("You are currently changing timecode using the GUI Scripting Method. You'll get better results if you set a shortcut key for 'Paste Timecode' within Final Cut Pro.")

                --------------------------------------------------------------------------------
                -- Make sure the timecode field is visible:
                --------------------------------------------------------------------------------
                if not tcField:isShowing() then
                    log.ef("cp.apple.finalcutpro.viewer.Viewer.timecode: Timecode text not showing.")
                    return
                end

                --------------------------------------------------------------------------------
                -- Get the timecode field UI position:
                --------------------------------------------------------------------------------
                local frame = tcField:frame()
                if not frame then
                    log.ef("cp.apple.finalcutpro.viewer.Viewer.timecode: Failed to find timecode frame.")
                    return
                end

                --------------------------------------------------------------------------------
                -- Make sure Final Cut Pro is frontmost:
                --------------------------------------------------------------------------------
                self:app():launch()
                local result = doUntil(function()
                    return self:app():isFrontmost()
                end)
                if not result then
                    log.ef("cp.apple.finalcutpro.viewer.Viewer.timecode: Failed to make Final Cut Pro frontmost.")
                    return
                end

                --------------------------------------------------------------------------------
                -- Double click the timecode value in the Viewer:
                --------------------------------------------------------------------------------
                local center = geometry(frame).center
                ninjaMouseClick(center)

                --------------------------------------------------------------------------------
                -- Wait until the click has been registered (give it 5 seconds):
                --------------------------------------------------------------------------------
                local toolbar = self:UI()
                local ready = doUntil(function()
                    return toolbar and #toolbar < 5 and find(original(), "00:00:00[:;]00") ~= nil
                end, 5)
                if not ready then
                    log.ef("cp.apple.finalcutpro.viewer.Viewer.timecode: The toolbar was never ready.")
                    return
                end

                --------------------------------------------------------------------------------
                -- Type the timecode value:
                --------------------------------------------------------------------------------
                local cleanedTimecodeValue = timecodeValue:gsub(";", ""):gsub(":", "")
                for character in cleanedTimecodeValue:gmatch(".") do
                    self:app():keyStroke({}, character)
                end
                self:app():keyStroke({}, 'return')
            end
        end
    )
end

--- cp.apple.finalcutpro.viewer.changePosition <cp.ui.Button>
--- Field
--- Change Position Button.
function ControlBar.lazy.value:changePosition()
    return Button(self, self.UI:mutate(function(original)
        return childFromRight(original(), 3, Button.matches)
    end))
end

--- cp.apple.finalcutpro.viewer.playButton <cp.ui.Button>
--- Field
--- Play Button.
function ControlBar.lazy.value:playButton()
    return Button(self, self.UI:mutate(function(original)
        return childFromRight(original(), 4, Button.matches)
    end))
end

--- cp.apple.finalcutpro.main.ControlBar.isPlaying <cp.prop: boolean>
--- Field
--- The 'playing' status of the viewer. If true, it is playing, if not it is paused.
--- This can be set via `viewer:isPlaying(true|false)`, or toggled via `viewer.isPlaying:toggle()`.
function ControlBar.lazy.prop:isPlaying()
    return prop(
        function()
            local element = self.playButton:UI()
            if element then
                local window = element:attributeValue("AXWindow")
                if window then
                    local hsWindow = window:asHSWindow()
                    local windowSnap = hsWindow and hsWindow:snapshot()

                    if not windowSnap then
                        log.ef("[cp.apple.finalcutpro.main.ControlBar.isPlaying] Snapshot could not be captured, so aborting.")
                        return
                    end

                    local windowFrame = window and window:attributeValue("AXFrame")
                    local shotSize = windowSnap and windowSnap:size()

                    local ratio = shotSize and windowFrame and shotSize.h/windowFrame.h
                    local elementFrame = element and element:attributeValue("AXFrame")

                    if not elementFrame then return end

                    local imageFrame = {
                        x = (windowFrame.x-elementFrame.x)*ratio,
                        y = (windowFrame.y-elementFrame.y)*ratio,
                        w = shotSize.w,
                        h = shotSize.h,
                    }

                    local c = canvas.new({w=elementFrame.w*ratio, h=elementFrame.h*ratio})
                    c[1] = {
                        type = "image",
                        image = windowSnap,
                        imageScaling = "none",
                        imageAlignment = "topLeft",
                        frame = imageFrame,
                    }

                    local elementSnap = c:imageFromCanvas()
                    c:delete()
                    c = nil -- luacheck: ignore

                    if elementSnap then
                        elementSnap:size({h=60,w=60})
                        local spot = elementSnap:colorAt({x=31,y=31})
                        return spot and spot.blue < 0.5
                    end
                end
            end
            return false
        end,
        function(newValue, owner, thisProp)
            local currentValue = thisProp:value()
            if newValue ~= currentValue then
                owner:playButton():press()
            end
        end
    )
end

--- cp.apple.finalcutpro.viewer.playButton <cp.ui.Image>
--- Field
--- Play Image.
function ControlBar.lazy.value:playImage()
    return Image(self, self.UI:mutate(function(original)
        return childFromRight(original(), 1, Image.matches)
    end))
end

return ControlBar