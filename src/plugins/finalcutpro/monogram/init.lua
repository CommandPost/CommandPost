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

end

return plugin
