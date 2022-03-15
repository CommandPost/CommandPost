--- === plugins.finalcutpro.timeline.mousezoom ===
---
--- Allows you to zoom in or out of a Final Cut Pro timeline using the mechanical scroll wheel on your mouse or the Touch Pad on the Magic Mouse when holding down the OPTION modifier key.
---
--- Special Thanks: Iain Anderson (@funwithstuff) for all his incredible testing!

local require = require

--local log               = require("hs.logger").new("mousezoom")

local eventtap          = require "hs.eventtap"
local mouse             = require "hs.mouse"
local pathwatcher       = require "hs.pathwatcher"

local config            = require "cp.config"
local fcp               = require "cp.apple.finalcutpro"
local tools             = require "cp.tools"
local i18n              = require "cp.i18n"

local semver            = require "semver"

local touchdevice

local mod = {}

--- plugins.finalcutpro.timeline.mousezoom.numberOfTouchDevices -> boolean
--- Variable
--- Returns `true` if a Magic Mouse has been detected otherwise `false`.
mod.foundMagicMouse = false

--- plugins.finalcutpro.timeline.mousezoom.numberOfTouchDevices -> table
--- Variable
--- Table of Touch Devices.
mod.touchDevices = {}

--- plugins.finalcutpro.timeline.mousezoom.numberOfTouchDevices -> table
--- Variable
--- Table of Magic Mouse ID's
mod.magicMouseIDs = {}

--- plugins.finalcutpro.timeline.mousezoom.numberOfTouchDevices -> number
--- Variable
--- Number of Touch Devices Detected.
mod.numberOfTouchDevices = 0

--- plugins.finalcutpro.timeline.mousezoom.offset -> number
--- Variable
--- Offset Value used in difference calculations.
mod.offset = 25

--- plugins.finalcutpro.timeline.mousezoom.threshold -> number
--- Variable
--- Threshold Value used in difference calculations.
mod.threshold = 0.005

--- plugins.finalcutpro.timeline.mousezoom.update() -> none
--- Function
--- Checks to see whether or not we should enable the timeline zoom watchers.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.update()
    if mod.enabled() then
        mod.start()
    else
        mod.stop()
    end
end

--- plugins.finalcutpro.timeline.mousezoom.enabled <cp.prop: boolean>
--- Variable
--- Toggles the Enable Proxy Menu Icon
mod.enabled = config.prop("enablemousezoom", false):watch(mod.update)

--- plugins.finalcutpro.timeline.mousezoom.customModifier <cp.prop: string>
--- Variable
--- Custom Modifier as string.
mod.customModifier = config.prop("mouseZoomCustomModifier", "alt")

--- plugins.finalcutpro.timeline.mousezoom.customModifier <cp.prop: boolean>
--- Variable
--- Should Mouse Zoom be inverted?
mod.invert = config.prop("mouseZoom.invert", false)

--- plugins.finalcutpro.timeline.mousezoom.sensitivity <cp.prop: string>
--- Variable
--- Sensitivity Level
mod.sensitivity = config.prop("mouseZoom.sensitivity", "default")

local zoomInFn = {
    ["default"] = function()
        local zoomAmount = fcp.timeline.toolbar.appearance:show().zoomAmount
        zoomAmount:increment()
    end,
    ["fast"] = function()
        local zoomAmount = fcp.timeline.toolbar.appearance:show().zoomAmount
        zoomAmount:shiftValue(-1)
    end,
    ["medium"] = function()
        local zoomAmount = fcp.timeline.toolbar.appearance:show().zoomAmount
        zoomAmount:shiftValue(-0.5)
    end,
    ["slow"] = function()
        local zoomAmount = fcp.timeline.toolbar.appearance:show().zoomAmount
        zoomAmount:shiftValue(-0.1)
    end,
    ["relative"] = function()
        local zoomAmount = fcp.timeline.toolbar.appearance:show().zoomAmount
        local shiftAmount = -0.5
        if zoomAmount:value() >= 7 then
            shiftAmount = -0.1
        end
        zoomAmount:shiftValue(shiftAmount)
    end,
}

local zoomOutFn = {
    ["default"] = function()
        local zoomAmount = fcp.timeline.toolbar.appearance:show().zoomAmount
        zoomAmount:decrement()
    end,
    ["fast"] = function()
        local zoomAmount = fcp.timeline.toolbar.appearance:show().zoomAmount
        zoomAmount:shiftValue(1)
    end,
    ["medium"] = function()
        local zoomAmount = fcp.timeline.toolbar.appearance:show().zoomAmount
        zoomAmount:shiftValue(0.5)
    end,
    ["slow"] = function()
        local zoomAmount = fcp.timeline.toolbar.appearance:show().zoomAmount
        zoomAmount:shiftValue(0.1)
    end,
    ["relative"] = function()
        local zoomAmount = fcp.timeline.toolbar.appearance:show().zoomAmount
        local shiftAmount = 0.5
        if zoomAmount:value() >= 7 then
            shiftAmount = 0.1
        end
        zoomAmount:shiftValue(shiftAmount)
    end,
}

-- zoomIn() -> none
-- Function
-- Zooms in to the FCPX Timeline.
local function zoomIn()
    local sensitivity = mod.sensitivity()
    zoomInFn[sensitivity]()
end

-- zoomOut() -> none
-- Function
-- Zooms out of the the FCPX Timeline.
local function zoomOut()
    local sensitivity = mod.sensitivity()
    zoomOutFn[sensitivity]()
end

--- plugins.finalcutpro.timeline.mousezoom.stop() -> none
--- Function
--- Disables the ability to zoom a timeline using your mouse scroll wheel and the OPTION modifier key.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.stop()

    --------------------------------------------------------------------------------
    -- Clear any existing existing Touch Devices:
    --------------------------------------------------------------------------------
    if mod.touchDevices then
        for _, id in ipairs(mod.magicMouseIDs) do
            if mod.touchDevices[id] then
                mod.touchDevices[id]:stop()
                mod.touchDevices[id] = nil
            end
        end
        mod.touchDevices = nil
    end

    --------------------------------------------------------------------------------
    -- Destroy Mouse Watcher:
    --------------------------------------------------------------------------------
    if mod.distributedObserver then
        mod.distributedObserver:stop()
        mod.distributedObserver = nil
    end

    --------------------------------------------------------------------------------
    -- Destroy Preferences Watcher:
    --------------------------------------------------------------------------------
    if mod.preferencesWatcher then
        mod.preferencesWatcher:stop()
        mod.preferencesWatcher = nil
    end

    --------------------------------------------------------------------------------
    -- Destory Mouse Scroll Wheel Watcher:
    --------------------------------------------------------------------------------
    if mod.mousetap then
        mod.mousetap:stop()
        mod.mousetap = nil
    end

    --------------------------------------------------------------------------------
    -- Destroy Keyboard Watcher:
    --------------------------------------------------------------------------------
    if mod.keytap then
        mod.keytap:stop()
        mod.keytap = nil
    end

    --------------------------------------------------------------------------------
    -- Destroy the extension:
    --------------------------------------------------------------------------------
    touchdevice = nil

end

--- plugins.finalcutpro.timeline.mousezoom.findMagicMouses() -> none
--- Function
--- Find Magic Mouse Devices and adds them to a table.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.findMagicMouses()

    --------------------------------------------------------------------------------
    -- Clear any existing existing Touch Devices:
    --------------------------------------------------------------------------------
    mod.stop()
    mod.foundMagicMouse = false

    --------------------------------------------------------------------------------
    -- Only start this extension if required:
    --------------------------------------------------------------------------------
    touchdevice = require("hs._asm.undocumented.touchdevice")

    --------------------------------------------------------------------------------
    -- Search for Magic Mouses:
    --------------------------------------------------------------------------------
    if touchdevice.available() then
        mod.magicMouseIDs = {}
        local devices = touchdevice.devices()
        mod.numberOfTouchDevices = #devices
        if devices then
            for _, id in ipairs(devices) do
                local selectedDevice = touchdevice.forDeviceID(id)
                if selectedDevice then

                    --------------------------------------------------------------------------------
                    -- First Generation:
                    --
                    -- The original Magic Mouse annoyingly returns the customisable mouse name as
                    -- the `productName`, so we need to detect it differently:
                    --------------------------------------------------------------------------------
                    if selectedDevice:details().builtin == false and
                    selectedDevice:details().driverType == 4 and
                    selectedDevice:details().familyID == 112 and
                    selectedDevice:details().sensorDimensions.h == 9056 and
                    selectedDevice:details().sensorDimensions.w == 5152 and
                    selectedDevice:details().sensorSurfaceDimensions.h == 9056 and
                    selectedDevice:details().sensorSurfaceDimensions.w == 5152 and
                    selectedDevice:details().supportsForce == false then
                        --log.df("Found a first generation Magic Mouse with ID: %s", id)
                        mod.magicMouseIDs[#mod.magicMouseIDs + 1] = id
                        mod.foundMagicMouse = true
                    else
                        --------------------------------------------------------------------------------
                        -- Second Generation:
                        --------------------------------------------------------------------------------
                        local selectedProductName = selectedDevice:details().productName
                        if selectedProductName == "Magic Mouse 2" then
                            --log.df("Found a second generation Magic Mouse with ID: %s", id)
                            mod.magicMouseIDs[#mod.magicMouseIDs + 1] = id
                            mod.foundMagicMouse = true
                        end
                    end
                end
            end
        end
    end
end

-- touchCallback(self, touches, time, frame) -> none
-- Function
-- Touch Callback.
--
-- Parameters:
--  * `self` - the touch device object for which the callback is being invoked for
--  * `touch` - a table containing an array of touch tables as described in `hs._asm.undocumented.touchdevice.touchData` for each of the current touches detected by the touch device.
--  * `timestamp` - a number specifying the timestamp for the frame.
--  * `frame` - an integer specifying the frame ID
--
-- Returns:
--  * None
local function touchCallback(_, touches)

    --------------------------------------------------------------------------------
    -- Only do stuff if FCPX is active:
    --------------------------------------------------------------------------------
    if not fcp:isFrontmost() or not fcp.timeline:isShowing() then return end

    --------------------------------------------------------------------------------
    -- Only allow when ONLY the custom modifier key is held down:
    --
    -- TODO: There's got to be a better way to do this. Until then...
    --------------------------------------------------------------------------------
    local mods = eventtap.checkKeyboardModifiers()
    mod.modifierPressed = false
    local customModifier = mod.customModifier()
    if customModifier == "cmd" then
        if mods['cmd'] and not mods['alt'] and not mods['shift'] and not mods['ctrl'] and not mods['capslock'] and not mods['fn'] then
            mod.modifierPressed = true
        end
    elseif customModifier == "alt" then
        if mods['alt'] and not mods['cmd'] and not mods['shift'] and not mods['ctrl'] and not mods['capslock'] and not mods['fn'] then
            mod.modifierPressed = true
        end
    elseif customModifier == "shift" then
        if mods['shift'] and not mods['cmd'] and not mods['alt'] and not mods['ctrl'] and not mods['capslock'] and not mods['fn'] then
            mod.modifierPressed = true
        end
    elseif customModifier == "ctrl" then
        if mods['ctrl'] and not mods['cmd'] and not mods['alt'] and not mods['shift'] and not mods['capslock'] and not mods['fn'] then
            mod.modifierPressed = true
        end
    elseif customModifier == "capslock" then
        if mods['capslock'] and not mods['cmd'] and not mods['alt'] and not mods['shift'] and not mods['ctrl'] and not mods['fn'] then
            mod.modifierPressed = true
        end
    elseif customModifier == "fn" then
        if mods['fn'] and not mods['cmd'] and not mods['alt'] and not mods['shift'] and not mods['ctrl'] and not mods['capslock'] then
            mod.modifierPressed = true
        end
    end
    if not mod.modifierPressed then
        return
    end

    --------------------------------------------------------------------------------
    -- Exit Callback if Mouse has been clicked:
    --------------------------------------------------------------------------------
    local mouseButtons = eventtap.checkMouseButtons()
    if next(mouseButtons) then
        mod.lastPosition = nil
        if fcp.timeline.toolbar.appearance:isShowing() then
            fcp.timeline.toolbar.appearance:hide()
        end
        return
    end

    --------------------------------------------------------------------------------
    -- Only single touch allowed:
    --------------------------------------------------------------------------------
    local numberOfTouches = #touches
    if numberOfTouches ~= 1 then
        --------------------------------------------------------------------------------
        -- Abort:
        --------------------------------------------------------------------------------
        return
    end

    --------------------------------------------------------------------------------
    -- Get Stage & Current Position:
    --------------------------------------------------------------------------------
    local stage = touches[1].stage
    local currentPosition = touches[1].normalizedVector.position.y

    --------------------------------------------------------------------------------
    -- User has broken contact with the Touch Device:
    --------------------------------------------------------------------------------
    if stage == "breakTouch" then
        fcp.timeline.toolbar.appearance:hide()
        return
    end

    --------------------------------------------------------------------------------
    -- User has made contact with the Touch Device:
    --------------------------------------------------------------------------------
    if stage == "makeTouch" then
        fcp.timeline.toolbar.appearance:show()
        mod.lastPosition = currentPosition
    end

    --------------------------------------------------------------------------------
    -- User is touching the Touch Device:
    --------------------------------------------------------------------------------
    if stage == "touching" then

        --------------------------------------------------------------------------------
        -- Define the appearance popup:
        --------------------------------------------------------------------------------
        local appearance = fcp.timeline.toolbar.appearance

        --------------------------------------------------------------------------------
        -- If we can't get the appearance popup, then we give up:
        --------------------------------------------------------------------------------
        if not appearance then return end

        --------------------------------------------------------------------------------
        -- Get current value of the zoom slider:
        --------------------------------------------------------------------------------
        local currentValue = appearance.zoomAmount:getValue()

        --------------------------------------------------------------------------------
        -- If we can't get the zoom value, then we give up:
        --------------------------------------------------------------------------------
        if not currentValue then return end

        --------------------------------------------------------------------------------
        -- Work out the difference between the last position and the current position:
        --------------------------------------------------------------------------------
        local difference = currentPosition
        if mod.lastPosition then
            difference = currentPosition - mod.lastPosition
        end

        --------------------------------------------------------------------------------
        -- Only allow differences of a certain threshold:
        --------------------------------------------------------------------------------
        if math.abs(difference) < mod.threshold then
            mod.lastPosition = currentPosition
            return
        end

        --------------------------------------------------------------------------------
        -- Adjust the zoom slider:
        --------------------------------------------------------------------------------
        if mod.scrollDirection == "normal" then
            appearance.zoomAmount:setValue(currentValue + (difference * mod.offset))
        else
            appearance.zoomAmount:setValue(currentValue - (difference * mod.offset))
        end

        --------------------------------------------------------------------------------
        -- Save the last position for next time:
        --------------------------------------------------------------------------------
        mod.lastPosition = currentPosition

    end

end

--- plugins.finalcutpro.timeline.mousezoom.start() -> none
--- Function
--- Enables the ability to zoon a timeline using your mouse scroll wheel and the OPTION modifier key.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.start()

    --------------------------------------------------------------------------------
    -- Monitor Touch Devices:
    --------------------------------------------------------------------------------
    mod.findMagicMouses()
    if not mod.touchDevices then mod.touchDevices = {} end
    if mod.numberOfTouchDevices >= 1 then
        for _, id in ipairs(mod.magicMouseIDs) do
            mod.touchDevices[id] = touchdevice.forDeviceID(id):frameCallback(touchCallback):start()
        end
    end

    --------------------------------------------------------------------------------
    -- Setup Mouse Watcher:
    --------------------------------------------------------------------------------
    local distributednotifications = require("hs.distributednotifications")
    mod.distributedObserver = distributednotifications.new(function()
        mod.stop()
        mod.update()
    end, "com.apple.MultitouchSupport.HID.DeviceAdded"):start()

    --------------------------------------------------------------------------------
    -- Setup Preferences Watcher:
    --------------------------------------------------------------------------------
    mod.preferencesWatcher = pathwatcher.new("~/Library/Preferences/", function(files)
        local doReload = false
        for _,file in pairs(files) do
            if file:sub(-24) == ".GlobalPreferences.plist" then
                doReload = true
            end
        end
        if doReload then
            --------------------------------------------------------------------------------
            -- Cache Scroll Direction:
            --------------------------------------------------------------------------------
            --log.df("Global Preferences Updated. Refreshing scroll direction cache.")
            mod.scrollDirection = mouse.scrollDirection()

            --------------------------------------------------------------------------------
            -- Invert if necessary:
            --------------------------------------------------------------------------------
            if mod.invert() then
                if mod.scrollDirection == "normal" then
                    mod.scrollDirection = "natural"
                else
                    mod.scrollDirection = "normal"
                end
            end
        end
    end):start()

    --------------------------------------------------------------------------------
    -- Setup Mouse Scroll Wheel Watcher:
    --------------------------------------------------------------------------------
    mod.mousetap = eventtap.new({eventtap.event.types.scrollWheel}, function(event)

        --------------------------------------------------------------------------------
        -- Block Horizontal Scrolling:
        --------------------------------------------------------------------------------
        if event:getProperty(eventtap.event.properties.scrollWheelEventPointDeltaAxis2) ~= 0 then
            if mod.modifierPressed then
                --------------------------------------------------------------------------------
                -- Exit callback if OPTION is being held down:
                --------------------------------------------------------------------------------
                return true
            end
        end

        --------------------------------------------------------------------------------
        -- Setup Mouse & Keyword Checkers:
        --
        -- TODO: There's got to be a better way to do this. Until then...
        --------------------------------------------------------------------------------
        local mods = eventtap.checkKeyboardModifiers()
        mod.modifierPressed = false
        local customModifier = mod.customModifier()
        if customModifier == "cmd" then
            if mods['cmd'] and not mods['alt'] and not mods['shift'] and not mods['ctrl'] and not mods['capslock'] and not mods['fn'] then
                mod.modifierPressed = true
            end
        elseif customModifier == "alt" then
            if mods['alt'] and not mods['cmd'] and not mods['shift'] and not mods['ctrl'] and not mods['capslock'] and not mods['fn'] then
                mod.modifierPressed = true
            end
        elseif customModifier == "shift" then
            if mods['shift'] and not mods['cmd'] and not mods['alt'] and not mods['ctrl'] and not mods['capslock'] and not mods['fn'] then
                mod.modifierPressed = true
            end
        elseif customModifier == "ctrl" then
            if mods['ctrl'] and not mods['cmd'] and not mods['alt'] and not mods['shift'] and not mods['capslock'] and not mods['fn'] then
                mod.modifierPressed = true
            end
        elseif customModifier == "capslock" then
            if mods['capslock'] and not mods['cmd'] and not mods['alt'] and not mods['shift'] and not mods['ctrl'] and not mods['fn'] then
                mod.modifierPressed = true
            end
        elseif customModifier == "fn" then
            if mods['fn'] and not mods['cmd'] and not mods['alt'] and not mods['shift'] and not mods['ctrl'] and not mods['capslock'] then
                mod.modifierPressed = true
            end
        end
        if not mod.modifierPressed then
            return
        end

        local mouseButtons = eventtap.checkMouseButtons()
        if not next(mouseButtons) and fcp.isFrontmost() and fcp.timeline:isShowing() then
            mod.modifierPressed = true
            if mod.foundMagicMouse then
                --------------------------------------------------------------------------------
                -- This prevents the Magic Mouse from scrolling horizontally or vertically:
                --------------------------------------------------------------------------------
                return true
            else
                --------------------------------------------------------------------------------
                -- Code to handle MECHANICAL MOUSES (i.e. not Magic Mouse):
                --------------------------------------------------------------------------------
                local direction = event:getProperty(eventtap.event.properties.scrollWheelEventDeltaAxis1)
                if fcp.timeline:isShowing() then
                    if mod.scrollDirection == "normal" then
                        if direction >= 1 then
                            zoomIn()
                        else
                            zoomOut()
                        end
                    else
                        if direction >= 1 then
                            zoomOut()
                        else
                            zoomIn()
                        end
                    end
                    return true
                end
            end
        end
    end):start()

    --------------------------------------------------------------------------------
    -- Detect when modifier key is released:
    --------------------------------------------------------------------------------
    mod.keytap = eventtap.new({eventtap.event.types.flagsChanged}, function(event)
        if mod.modifierPressed and tools.tableCount(event:getFlags()) == 0 then

            --------------------------------------------------------------------------------
            -- Reset everything:
            --------------------------------------------------------------------------------
            mod.modifierPressed = false
            mod.lastPosition = nil

            --------------------------------------------------------------------------------
            -- Hide the Appearance Popup:
            --------------------------------------------------------------------------------
            local appearance = fcp.timeline.toolbar.appearance
            if appearance and appearance:isShowing() then
                appearance:hide()
            end

        end
    end):start()

end

local plugin = {
    id = "finalcutpro.timeline.mousezoom",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.preferences.manager"] = "prefs",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Cache Scroll Direction:
    --------------------------------------------------------------------------------
    mod.scrollDirection = mouse.scrollDirection()

    --------------------------------------------------------------------------------
    -- Invert if necessary:
    --------------------------------------------------------------------------------
    if mod.invert() then
        if mod.scrollDirection == "normal" then
            mod.scrollDirection = "natural"
        else
            mod.scrollDirection = "normal"
        end
    end

    --------------------------------------------------------------------------------
    -- Update:
    --------------------------------------------------------------------------------
    mod.update()

    --------------------------------------------------------------------------------
    -- Setup Menubar Preferences Panel:
    --------------------------------------------------------------------------------
    local panel = deps.prefs.panel
    if panel then
        panel
            :addCheckbox(1.3,
            {
                label = i18n("allowZoomingWithModifierKey"),
                onchange = function(_, params) mod.enabled(params.checked) end,
                checked = mod.enabled,
            })
            :addContent(1.4, [[
                <style>
                    #mouseZoomModifierKey {
                         margin-left: 5px;
                         width: 100px;
                    }

                    #mouseZoomSensitivity {
                        margin-left: 18px;
                        width: 100px;
                    }

                    .mouseZoomInvertCheckbox {
                        padding-top: 3px;
                    }

                    .column {
                      float: left;
                      width: 50%;
                      vertical-align: middle;
                      height: 27px;
                    }

                    /* Clear floats after the columns */
                    .row:after {
                      content: "";
                      display: table;
                      clear: both;
                    }
                </style>
                <div style="padding-left: 19px">
                    <div class="row">
                      <div class="column">
            ]], false)
            :addSelect(1.5,
            {
                label       = i18n("modifierKey"),
                value       = mod.customModifier,
                options     = {
                    {
                        label = "command ⌘",
                        value = "cmd",
                    },
                    {
                        label = "option ⌥",
                        value = "alt",
                    },
                    {
                        label = "shift ⇧",
                        value = "shift",
                    },
                    {
                        label = "control ⌃",
                        value = "ctrl",
                    },
                    {
                        label = "caps lock",
                        value = "capslock",
                    },
                    {
                        label = "fn",
                        value = "fn",
                    },
                },
                required    = true,
                onchange    = function(_, params) mod.customModifier(params.value) end,
                id          = "mouseZoomModifierKey",
            })
            :addContent(1.6, [[
                        </div>
                        <div class="column">
            ]], false)
            :addCheckbox(1.7,
            {
                label = i18n("invert"),
                onchange = function(_, params)
                    mod.invert(params.checked)

                    --------------------------------------------------------------------------------
                    -- Cache Scroll Direction:
                    --------------------------------------------------------------------------------
                    mod.scrollDirection = mouse.scrollDirection()

                    --------------------------------------------------------------------------------
                    -- Invert if necessary:
                    --------------------------------------------------------------------------------
                    if mod.invert() then
                        if mod.scrollDirection == "normal" then
                            mod.scrollDirection = "natural"
                        else
                            mod.scrollDirection = "normal"
                        end
                    end
                end,
                checked = mod.invert,
                class = "uiItem mouseZoomInvertCheckbox"
            })
            :addContent(1.8, [[
                    </div>
                </div>
            </div>]], false)
            :addContent(1.9, [[
                <div style="padding-left: 19px">
            ]], false)
            :addSelect(2,
            {
                label       = i18n("sensitivity"),
                value       = mod.sensitivity,
                options     = {
                    {
                        label = i18n("default"),
                        value = "default",
                    },
                    {
                        label = i18n("fast"),
                        value = "fast",
                    },
                    {
                        label = i18n("medium"),
                        value = "medium",
                    },
                    {
                        label = i18n("slow"),
                        value = "slow",
                    },
                    {
                        label = i18n("relative"),
                        value = "relative",
                    },
                },
                required    = true,
                onchange    = function(_, params) mod.sensitivity(params.value) end,
                id          = "mouseZoomSensitivity",
            })
            :addContent(2.1, [[</div>]], false)
    end

    return mod
end

return plugin
