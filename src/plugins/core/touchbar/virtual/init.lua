--- === plugins.core.touchbar.virtual ===
---
--- Virtual Touch Bar Manager

local require = require

local log                                       = require "hs.logger" .new "tbVirtual"

local eventtap                                  = require "hs.eventtap"

local config                                    = require "cp.config"
local dialog                                    = require "cp.dialog"
local i18n                                      = require "cp.i18n"
local prop                                      = require "cp.prop"
local tools                                     = require "cp.tools"

local semver                                    = require "semver"

local location                                  = require "location"
local execute                                   = hs.execute

local mod = {}

--- plugins.core.touchbar.virtual.LOCATION_DRAGGABLE -> string
--- Constant
--- Location is Draggable.
mod.LOCATION_DRAGGABLE = "Draggable"

--- plugins.core.touchbar.virtual.LOCATION_MOUSE -> string
--- Constant
--- Location is Mouse.
mod.LOCATION_MOUSE = "Mouse"

--- plugins.core.touchbar.virtual.LOCATION_DEFAULT_VALUE -> string
--- Constant
--- Default location value.
mod.LOCATION_DEFAULT_VALUE = mod.LOCATION_DRAGGABLE

--- plugins.core.touchbar.virtual.lastLocation <cp.prop: point table>
--- Field
--- The last known Virtual Touch Bar Location
mod.lastLocation = config.prop("lastVirtualTouchBarLocation")

--- plugins.finalcutpro.touchbar.virtual.location <cp.prop: string>
--- Field
--- The Virtual Touch Bar Location Setting
mod.location = config.prop("displayVirtualTouchBarLocation", mod.LOCATION_DEFAULT_VALUE):watch(function() mod.update() end)

--- plugins.core.touchbar.virtual.updateLocationCallback -> table
--- Variable
--- Update Location Callback
mod.updateLocationCallback = location

--- plugins.core.touchbar.virtual.macOSVersionSupported <cp.prop: boolean>
--- Field
--- Does the macOS version support the Touch Bar?
mod.macOSVersionSupported = prop(function()
    local osVersion = semver(tools.macOSVersion())
    return osVersion >= semver("10.12.1")
end)

--- plugins.core.touchbar.virtual.supported <cp.prop: boolean; read-only>
--- Field
--- Is `true` if the Touch Bar is supported on this version of macOS.
mod.supported = mod.macOSVersionSupported:AND(prop(function()
    local touchbar = mod.touchbar()
    return touchbar and touchbar.supported()
end))

--- plugins.core.touchbar.virtual.touchbar() -> none
--- Function
--- Returns the `hs._asm.undocumented.touchbar` object if it exists.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `hs._asm.undocumented.touchbar`
function mod.touchbar()
    if not mod._touchbar then
        if mod.macOSVersionSupported() then
            mod._touchbar = require "hs._asm.undocumented.touchbar"
        else
            mod._touchbar = {
                supported = function() return false end,
            }
        end
    end
    return mod._touchbar
end

--- plugins.core.touchbar.virtual.enabled <cp.prop: boolean>
--- Field
--- Is `true` if the plugin is enabled.
mod.enabled = config.prop("displayVirtualTouchBar", false):watch(function(enabled)
    --------------------------------------------------------------------------------
    -- Check for compatibility:
    --------------------------------------------------------------------------------
    if enabled and not mod.supported() then
        dialog.displayMessage(i18n("touchBarError"))
        mod.enabled(false)
    end
    if not enabled then
        mod.stop()
    end
end)

--- plugins.core.touchbar.virtual.isActive <cp.prop: boolean; read-only>
--- Field
--- Is `true` if the plugin is enabled and the TouchBar is supported on this OS.
mod.isActive = mod.enabled:AND(mod.supported):watch(function(active)
    if active then
        mod.show()
    else
        mod.hide()
    end
end)

--- plugins.core.touchbar.virtual.start() -> none
--- Function
--- Initialises the Virtual Touch Bar
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.start()
    if mod.supported() and not mod._touchBar then
        local touchbar = mod.touchbar()
        if not touchbar then
            log.ef("The Touch Bar is not supported on this system.")
            return
        end

        --------------------------------------------------------------------------------
        -- Set up Touch Bar:
        --------------------------------------------------------------------------------
        mod._touchBar = touchbar.virtual.new()

        if mod._touchBar == nil then
            log.ef("There was an error initialising the Touch Bar.")
            return
        end

        --------------------------------------------------------------------------------
        -- Touch Bar Watcher:
        --------------------------------------------------------------------------------
        mod._touchBar:setCallback(mod.callback)

        --------------------------------------------------------------------------------
        -- Get last Touch Bar Location from Settings:
        --------------------------------------------------------------------------------
        local lastTouchBarLocation = mod.lastLocation()
        if lastTouchBarLocation ~= nil then mod._touchBar:topLeft(lastTouchBarLocation) end

        --------------------------------------------------------------------------------
        -- Draggable Touch Bar:
        --------------------------------------------------------------------------------
        local events = eventtap.event.types
        mod.keyboardWatcher = eventtap.new({events.flagsChanged, events.keyDown, events.leftMouseDown}, function(ev)
            if mod.mouseInsideTouchbar and mod.location() == mod.LOCATION_DRAGGABLE then
                if ev:getType() == events.flagsChanged and ev:getRawEventData().CGEventData.flags == 524576 then
                    mod._touchBar:backgroundColor{ red = 1 }
                                    :movable(true)
                                    :acceptsMouseEvents(false)
                elseif ev:getType() ~= events.leftMouseDown then
                    mod._touchBar:backgroundColor{ white = 0 }
                                  :movable(false)
                                  :acceptsMouseEvents(true)
                    mod.lastLocation(mod._touchBar:topLeft())
                end
            end
            return false
        end):start()

        mod.update()

    end
end

--- plugins.core.touchbar.virtual.stop() -> none
--- Function
--- Stops the Virtual Touch Bar
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.stop()
    if mod._touchBar then
        mod._touchBar:hide()
        mod._touchBar = nil
        collectgarbage() -- See: https://github.com/asmagill/hammerspoon_asm/issues/10#issuecomment-303290853
    end
    if mod.keyboardWatcher then
        mod.keyboardWatcher:stop()
        mod.keyboardWatcher = nil
    end
end

--- plugins.finalcutpro.touchbar.virtual.updateLocation() -> none
--- Function
--- Updates the Location of the Virtual Touch Bar
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.updateLocation()

    --------------------------------------------------------------------------------
    -- Check that the Touch Bar exists:
    --------------------------------------------------------------------------------
    if not mod._touchBar then return end

    --------------------------------------------------=-----------------------------
    -- Put it back to last known position:
    --------------------------------------------------------------------------------
    local lastLocation = mod.lastLocation()
    if lastLocation and mod._touchBar then
        mod._touchBar:topLeft(lastLocation)
    end

    --------------------------------------------------------------------------------
    -- Trigger Callbacks:
    --------------------------------------------------------------------------------
    local updateLocationCallbacks = location:getAll()
    if updateLocationCallbacks and type(updateLocationCallbacks) == "table" then
        for _, v in pairs(updateLocationCallbacks) do
            local fn = v:callbackFn()
            if fn and type(fn) == "function" then
                fn()
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Save last Touch Bar Location to Settings:
    --------------------------------------------------------------------------------
    mod.lastLocation(mod._touchBar:topLeft())
end

--- plugins.core.touchbar.virtual.show() -> none
--- Function
--- Show the Virtual Touch Bar
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.show()
    --------------------------------------------------------------------------------
    -- Check if we need to show the Touch Bar:
    --------------------------------------------------------------------------------
    if mod.supported() and mod.enabled() then
        mod.start()
        mod.updateLocation()
        mod._touchBar:show()
    end
end

--- plugins.core.touchbar.virtual.hide() -> none
--- Function
--- Hide the Virtual Touch Bar
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.hide()
    if mod.supported() and mod.enabled() and mod._touchBar then
        mod._touchBar:hide()
    end
end

--- plugins.core.touchbar.virtual.callback() -> none
--- Function
--- Callback Function for the Virtual Touch Bar
---
--- Parameters:
---  * obj - the touchbarObject the callback is for
---  * message - the message to the callback, either "didEnter" or "didExit"
---
--- Returns:
---  * None
function mod.callback(_, message)
    if message == "didEnter" then
        mod.mouseInsideTouchbar = true
    elseif message == "didExit" then
        mod.mouseInsideTouchbar = false

        --------------------------------------------------------------------------------
        -- Just in case we got here before the eventtap returned the Touch Bar to normal:
        --------------------------------------------------------------------------------
        mod._touchBar:movable(false)
        mod._touchBar:acceptsMouseEvents(true)
        mod.lastLocation(mod._touchBar:topLeft())
    end
end

--- plugins.core.touchbar.virtual.update() -> none
--- Function
--- Updates the visibility and location of the Virtual Touch Bar
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.update()
    -- Check if it's active.
    mod.isActive:update()
end

--- plugins.core.touchbar.virtual.init() -> self
--- Function
--- Initialise the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Self
function mod.init()
    mod.update()
    return mod
end


local plugin = {
    id          = "core.touchbar.virtual",
    group       = "core",
}

function plugin.init()
    return mod.init()
end

return plugin
