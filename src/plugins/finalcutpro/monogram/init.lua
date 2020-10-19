--- === plugins.core.monogram.manager ===
---
--- Monogram Actions for Final Cut Pro

local require                   = require

local log                       = require "hs.logger".new "monogram"

local application               = require "hs.application"
local json                      = require "hs.json"
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
        end
    end
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
        registerAction("Color Wheels." .. v.id .. ".Vertical", makeWheelHandler(function() return v.control end, true))
        registerAction("Color Wheels." .. v.id .. ".Horizontal", makeWheelHandler(function() return v.control end, false))
        registerAction("Color Wheels." .. v.id .. ".Reset", makeResetColorWheelHandler(function() return v.control end))
        registerAction("Color Wheels." .. v.id .. ".Reset All", makeResetColorWheelSatAndBrightnessHandler(function() return v.control end))
        registerAction("Color Wheels." .. v.id .. ".Saturation", makeSaturationHandler(function() return v.control end))
        registerAction("Color Wheels." .. v.id .. ".Brightness", makeBrightnessHandler(function() return v.control end))
    end

end

return plugin
