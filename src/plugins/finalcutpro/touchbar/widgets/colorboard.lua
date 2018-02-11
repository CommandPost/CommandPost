--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                    T O U C H    B A R    W I D G E T                       --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.touchbar.widgets.colorboard ===
---
--- A collection of Final Cut Pro Color Board Widgets for the Touch Bar.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local canvas            = require("hs.canvas")
local eventtap          = require("hs.eventtap")
local styledtext        = require("hs.styledtext")
local timer             = require("hs.timer")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local fcp               = require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
-- 3rd Party Extensions:
--------------------------------------------------------------------------------
local touchbar          = require("hs._asm.undocumented.touchbar")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.touchbar.widgets.colorboard.updateInterval -> number
--- Variable
--- How often the Touch Bar widgets should be refreshed in seconds
mod.updateInterval = 2

-- plugins.finalcutpro.touchbar.widgets.colorboard._doubleTap -> table
-- Variable
-- Table containing whether or not a double tap has occurred.
mod._doubleTap = {}

-- plugins.finalcutpro.touchbar.widgets.colorboard._updateCallbacks -> table
-- Variable
-- A table containing all of the update callback functions for each widget
mod._updateCallbacks = {}

-- calculateColor(pct, angle) -> brightness, solidColor, fillColor, negative
-- Function
-- Returns the color
--
-- Parameters:
--  * pct - percentage value as number
--  * aspect - "color", "saturation" or "exposure"
--
-- Returns:
--  * brightness - value as number
--  * solidColor - color in `hs.drawing.color` format
--  * fillColor - color in `hs.drawing.color` format
--  * negative - boolean
local function calculateColor(pct, angle)
    local brightness = nil
    local solidColor = nil
    local fillColor = nil

    if angle then
        solidColor = {hue = angle/360, saturation = 1, brightness = 1, alpha = 1}
        fillColor = {hue = angle/360, saturation = 1, brightness = 1, alpha = math.abs(pct/100)}
    else
        if pct then
            brightness = pct >= 0 and 1 or 0
            fillColor = {hue = 0, saturation = 0, brightness = brightness, alpha = math.abs(pct/100)}
        end
    end

    local negative = false
    if pct and angle and pct < 0 then
        negative = true
    end

    return brightness, solidColor, fillColor, negative
end

-- getWidgetText(id, aspect) -> string
-- Function
-- Returns the widget text
--
-- Parameters:
--  * id - puck ID
--  * aspect - "color", "saturation" or "exposure"
--
-- Returns:
--  * Text in `hs.styledtext` format
local function getWidgetText(id, aspect)
    local colorBoard = fcp:colorBoard()
    local widgetText
    local puckID = tonumber(string.sub(id, -1))

    local aspectTitle = {
        ["color"] = "Color",
        ["saturation"] = "Sat",
        ["exposure"] = "Exp",
    }

    local puckTitle = {
        [1] = "Global",
        [2] = "Low",
        [3] = "Mid",
        [4] = "High",
    }

    local spanStyle = [[<span style="font-family: -apple-system; font-size: 12px; color: #FFFFFF;">]]
    if aspect == "*" then
        local selectedPanel = colorBoard:selectedAspect()
        if selectedPanel then
            if aspectTitle[selectedPanel] and puckTitle[puckID] then
                widgetText = styledtext.getStyledTextFromData(spanStyle .. "<strong>" .. aspectTitle[selectedPanel] .. ": </strong>" .. puckTitle[puckID] .. "</span>")
            end
        else
            widgetText = styledtext.getStyledTextFromData(spanStyle .. "<strong>" .. puckTitle[puckID] .. ":</strong> </span>")
        end
    else
        widgetText = styledtext.getStyledTextFromData(spanStyle .. "<strong>" .. aspectTitle[aspect] .. ":</strong> </span>") .. puckTitle[puckID]
    end

    return widgetText
end

-- updateCanvas(widgetCanvas, id, aspect, property) -> none
-- Function
-- Updates a Canvas
--
-- Parameters:
--  * widgetCanvas - a `hs.canvas` object
--  * id - ID of the puck as string
--  * aspect - "color", "saturation" or "exposure"
--  * property - "global", "shadows", "midtones", "highlights"
--
-- Returns:
--  * None
local function updateCanvas(widgetCanvas, id, aspect, property)

    local colorBoard = fcp:colorBoard()

    if not colorBoard:isActive() then
        widgetCanvas.negative.action = "skip"
        widgetCanvas.arc.action = "skip"
        widgetCanvas.info.action = "skip"
        widgetCanvas.circle.action = "skip"
    else
        if colorBoard:selectedPanel() == aspect or aspect == "*" then
            local pct = colorBoard:getPercentage(aspect, property)
            local angle = colorBoard:getAngle(aspect, property)

            local _, solidColor, fillColor, negative = calculateColor(pct, angle)

            widgetCanvas.circle.action = "strokeAndFill"
            if solidColor then
                widgetCanvas.circle.strokeColor = solidColor
                widgetCanvas.arc.strokeColor = solidColor
                widgetCanvas.arc.fillColor = solidColor
            end
            widgetCanvas.circle.fillColor = fillColor

            if negative then
                widgetCanvas.negative.action = "strokeAndFill"
            else
                widgetCanvas.negative.action = "skip"
            end

            if colorBoard:selectedAspect() == "color" and aspect == "*" then
                widgetCanvas.arc.action = "strokeAndFill"
            else
                widgetCanvas.arc.action = "skip"
            end

            widgetCanvas.info.action = "strokeAndFill"
            if pct then
                widgetCanvas.info.text = pct .. "%"
            else
                widgetCanvas.info.text = ""
            end

            widgetCanvas.text.text = getWidgetText(id, aspect)
        end
    end

end

-- update() -> none
-- Function
-- Triggers all the available update callbacks
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function update()
    if fcp:isRunning() and fcp:isFrontmost() and fcp:colorBoard():isShowing() then
        for _, v in pairs(mod._updateCallbacks) do
            v()
        end
    end

end

--- plugins.finalcutpro.touchbar.widgets.colorboard.start() -> nil
--- Function
--- Stops the Timer.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.start(delay)
    if delay and type(delay) == "number" then
        timer.doAfter(delay, function()
            mod._timer:start()
        end)
    else
        mod._timer:start()
    end
end

--- plugins.finalcutpro.touchbar.widgets.colorboard.stop() -> nil
--- Function
--- Stops the Timer.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.stop()
    mod._timer:stop()
end

-- puckWidget(id, aspect, property) -> `hs._asm.undocumented.touchbar.item` object
-- Function
-- Creates a Puck Widget
--
-- Parameters:
--  * id - ID of the widget as string
--  * aspect - "color", "saturation" or "exposure"
--  * property - "global", "shadows", "midtones", "highlights"
--
-- Returns:
--  * A `hs._asm.undocumented.touchbar.item` object
local function puckWidget(id, aspect, property)

    --------------------------------------------------------------------------------
    -- Setup Timer:
    --------------------------------------------------------------------------------
    if not mod._timer then
        mod._timer = timer.new(mod.updateInterval, update)
    end

    --------------------------------------------------------------------------------
    -- Only enable the timer when Final Cut Pro is active:
    --------------------------------------------------------------------------------
    if not mod._fcpWatcher then
        mod._fcpWatcher = fcp:watch({
            active      = mod.start,
            inactive    = mod.stop,
            show        = mod.start,
            hide        = mod.stop,
        })
    end

    local colorBoard = fcp:colorBoard()

    local pct = colorBoard:getPercentage(aspect, property)
    local angle = colorBoard:getAngle(aspect, property)

    local brightness, _, fillColor, negative = calculateColor(pct, angle)

    local value = colorBoard:getPercentage(aspect, property)
    if value == nil then value = 0 end

    local color = {hue=0, saturation=0, brightness=brightness, alpha=1}

    local widgetCanvas = canvas.new{x = 0, y = 0, h = 30, w = 150}

    --------------------------------------------------------------------------------
    -- Background:
    --------------------------------------------------------------------------------
    widgetCanvas[#widgetCanvas + 1] = {
        id               = "background",
        type             = "rectangle",
        action           = "strokeAndFill",
        strokeColor      = { white = 1 },
        fillColor        = { hex = "#292929", alpha = 1 },
        roundedRectRadii = { xRadius = 5, yRadius = 5 },
    }

    --------------------------------------------------------------------------------
    -- Text:
    --------------------------------------------------------------------------------
    widgetCanvas[#widgetCanvas + 1] = {
        id = "text",
        frame = { h = 30, w = 150, x = 10, y = 6 },
        text = getWidgetText(id, aspect),
        textAlignment = "left",
        textColor = { white = 1.0 },
        textSize = 12,
        type = "text",
    }

    --------------------------------------------------------------------------------
    -- Circle:
    --------------------------------------------------------------------------------
    widgetCanvas[#widgetCanvas + 1] = {
        id                  = "circle",
        type                = "circle",
        radius              = "7%",
        center              =  { x = "90%", y = "50%" },
        action              = "strokeAndFill",
        strokeColor         = color,
        fillColor           = fillColor,
    }

    --------------------------------------------------------------------------------
    -- Arc:
    --------------------------------------------------------------------------------
    local arcAction = "skip"
    if colorBoard:selectedAspect() == "color" and aspect == "*" then
        arcAction = "strokeAndFill"
    end
    widgetCanvas[#widgetCanvas + 1] = {
        id                  = "arc",
        type                = "arc",
        radius              = "7%",
        center              =  { x = "90%", y = "50%" },
        startAngle          = 135,
        endAngle            = 315,
        action              = arcAction,
        strokeColor         = color,
        fillColor           = color,
    }

    --------------------------------------------------------------------------------
    -- Negative Symbol (Used for Color Panel):
    --------------------------------------------------------------------------------
    local negativeType = "skip"
    if negative then negativeType = "strokeAndFill" end
    widgetCanvas[#widgetCanvas + 1] = {
        id              = "negative",
        type            = "rectangle",
        action          = negativeType,
        strokeColor     = {white=1, alpha=0.75},
        strokeWidth     = 1,
        fillColor       = {white=0, alpha=1.0 },
        frame           = { h = 5, w = 10, x = 130, y = 12 },
    }

    --------------------------------------------------------------------------------
    -- Text:
    --------------------------------------------------------------------------------
    local textValue = value .. "%" or ""
    widgetCanvas[#widgetCanvas + 1] = {
        id = "info",
        frame = { h = 30, w = 120, x = 0, y = 6 },
        text = textValue,
        textAlignment = "right",
        textColor = { white = 1.0 },
        textSize = 12,
        type = "text",
    }

    --------------------------------------------------------------------------------
    -- Touch Events:
    --------------------------------------------------------------------------------
    widgetCanvas:canvasMouseEvents(true, true, false, true)
        :mouseCallback(function(o,m,_,x)

            --------------------------------------------------------------------------------
            -- Stop the timer:
            --------------------------------------------------------------------------------
            mod.stop()

            --------------------------------------------------------------------------------
            -- Detect Double Taps:
            --------------------------------------------------------------------------------
            local skipMaths = false
            if m == "mouseDown" then
                if mod._doubleTap[id] == true then
                    --------------------------------------------------------------------------------
                    -- Reset Puck:
                    --------------------------------------------------------------------------------
                    mod._doubleTap[id] = false
                    colorBoard:applyPercentage(aspect, property, 0)

                    local defaultValues = {
                        ["global"] = 110,
                        ["shadows"] = 180,
                        ["midtones"] = 215,
                        ["highlights"] = 250,
                    }

                    colorBoard:applyAngle(aspect, property, defaultValues[property])
                    skipMaths = true
                else
                    mod._doubleTap[id] = true
                end
                timer.doAfter(eventtap.doubleClickInterval(), function()
                    mod._doubleTap[id] = false
                end)
            end

            --------------------------------------------------------------------------------
            -- Show the Color Board if it's hidden:
            --------------------------------------------------------------------------------
            if not colorBoard:isShowing() then
                colorBoard:show()
            end

            --------------------------------------------------------------------------------
            -- Abort if Color Board is not active:
            --------------------------------------------------------------------------------
            if not colorBoard:isActive() then
                return
            end

            --------------------------------------------------------------------------------
            -- Check for keyboard modifiers:
            --------------------------------------------------------------------------------
            local mods = eventtap.checkKeyboardModifiers()
            local shiftPressed = false
            if mods['shift'] and not mods['cmd'] and not mods['alt'] and not mods['ctrl'] and not mods['capslock'] and not mods['fn'] then
                shiftPressed = true
            end
            local controlPressed = false
            if mods['ctrl'] and not mods['cmd'] and not mods['alt'] and not mods['shift'] and not mods['capslock'] and not mods['fn'] then
                controlPressed = true
            end

            --------------------------------------------------------------------------------
            -- Do the maths:
            --------------------------------------------------------------------------------
            if shiftPressed then
                x = x * 2.4
            else
                if controlPressed then
                    x = (x-75) * 1.333
                else
                    x = (x-75) * 0.75
                end
            end

            --------------------------------------------------------------------------------
            -- Update UI:
            --------------------------------------------------------------------------------
            updateCanvas(o, id, aspect, property)

            --------------------------------------------------------------------------------
            -- Perform Action:
            --------------------------------------------------------------------------------
            if not skipMaths then
                if m == "mouseDown" or m == "mouseMove" then
                    if shiftPressed then
                        colorBoard:applyAngle(aspect, property, x)
                    else
                        colorBoard:applyPercentage(aspect, property, x)
                    end
                --elseif m == "mouseUp" then
                end
            end

            --------------------------------------------------------------------------------
            -- Start the timer:
            --------------------------------------------------------------------------------
            mod.start(2)

    end)

    --------------------------------------------------------------------------------
    -- Update the Canvas:
    --------------------------------------------------------------------------------
    updateCanvas(widgetCanvas, id, aspect, property)

    --------------------------------------------------------------------------------
    -- Create new Touch Bar Item from Canvas:
    --------------------------------------------------------------------------------
    local item = touchbar.item.newCanvas(widgetCanvas, id):canvasClickColor{ alpha = 0.0 }

    --------------------------------------------------------------------------------
    -- Add update callback to timer:
    --------------------------------------------------------------------------------
    mod._updateCallbacks[#mod._updateCallbacks + 1] = function()
        if item:isVisible() then
            updateCanvas(widgetCanvas, id, aspect, property)
        end
    end

    return item

end

-- groupPuck(id) -> `hs._asm.undocumented.touchbar.item` object
-- Function
-- Creates the Group Puck
--
-- Parameters:
--  * id - ID of the group as string
--
-- Returns:
--  * A `hs._asm.undocumented.touchbar.item` object
local function groupPuck(id)

    --------------------------------------------------------------------------------
    -- Setup Toggle Button:
    --------------------------------------------------------------------------------
    local widgetCanvas = canvas.new{x = 0, y = 0, h = 30, w = 50}
    widgetCanvas[#widgetCanvas + 1] = {
        id               = "background",
        type             = "rectangle",
        action           = "strokeAndFill",
        strokeColor      = { white = 1 },
        fillColor        = { hex = "#292929", alpha = 1 },
        roundedRectRadii = { xRadius = 5, yRadius = 5 },
    }
    widgetCanvas[#widgetCanvas + 1] = {
        id = "text",
        frame = { h = 30, w = 50, x = 0, y = 6 },
        text = "Toggle",
        textAlignment = "center",
        textColor = { white = 1.0 },
        textSize = 12,
        type = "text",
    }
    widgetCanvas:canvasMouseEvents(true, true, false, true)
        :mouseCallback(function(_,m)
            if m == "mouseDown" or m == "mouseMove" then
                mod.stop()
                fcp:colorBoard():nextAspect()
                mod.start(0.01)
            end
        end)

    --------------------------------------------------------------------------------
    -- Setup Group:
    --------------------------------------------------------------------------------
    local group = touchbar.item.newGroup(id):groupItems({
        touchbar.item.newCanvas(widgetCanvas):canvasClickColor{ alpha = 0.0 },
        puckWidget("colorBoardGroup1", "*", "global"),
        puckWidget("colorBoardGroup2", "*", "shadows"),
        puckWidget("colorBoardGroup3", "*", "midtones"),
        puckWidget("colorBoardGroup4", "*", "highlights"),
    })
    return group

end

--- plugins.finalcutpro.touchbar.widgets.colorboard.init() -> nil
--- Function
--- Initialise the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init(deps)

    --------------------------------------------------------------------------------
    -- TODO: This should be streamlined and cleaned up with loops. We should also
    --       be used i18n.
    --------------------------------------------------------------------------------

    --------------------------------------------------------------------------------
    -- Color Board Group:
    --------------------------------------------------------------------------------
    local params
    params = {
        group = "fcpx",
        text = "Color Board (Grouped)",
        subText = "Color Board Panel Toggle Button & 4 x Puck Controls.",
        item = function() groupPuck("colorBoardGroup") end,
    }
    deps.manager.widgets:new("colorBoardGroup", params)

    --------------------------------------------------------------------------------
    -- Active Puck Controls:
    --------------------------------------------------------------------------------
    params = {
        group = "fcpx",
        text = "Color Board Puck 1",
        subText = "Allows you to control puck one of the Color Board.",
        item = function() puckWidget("colorBoardPuck1", "*", "global") end,
    }
    deps.manager.widgets:new("colorBoardPuck1", params)

    params = {
        group = "fcpx",
        text = "Color Board Puck 2",
        subText = "Allows you to control puck two of the Color Board.",
        item = function() puckWidget("colorBoardPuck2", "*", "shadows") end,
    }
    deps.manager.widgets:new("colorBoardPuck2", params)

    params = {
        group = "fcpx",
        text = "Color Board Puck 3",
        subText = "Allows you to control puck three of the Color Board.",
        item = function() puckWidget("colorBoardPuck3", "*", "midtones") end,
    }
    deps.manager.widgets:new("colorBoardPuck3", params)

    params = {
        group = "fcpx",
        text = "Color Board Puck 4",
        subText = "Allows you to control puck four of the Color Board.",
        item = function() puckWidget("colorBoardPuck4", "*", "highlights") end,
    }
    deps.manager.widgets:new("colorBoardPuck4", params)

    --------------------------------------------------------------------------------
    -- Color Panel:
    --------------------------------------------------------------------------------
    params = {
        group = "fcpx",
        text = "Color Board Color Puck 1",
        subText = "Allows you to the Color Panel of the Color Board.",
        item = function() puckWidget("colorBoardColorPuck1", "color", "global") end,
    }
    deps.manager.widgets:new("colorBoardColorPuck1", params)

    params = {
        group = "fcpx",
        text = "Color Board Color Puck 2",
        subText = "Allows you to the Color Panel of the Color Board.",
        item = function() puckWidget("colorBoardColorPuck2", "color", "shadows") end,
    }
    deps.manager.widgets:new("colorBoardColorPuck2", params)

    params = {
        group = "fcpx",
        text = "Color Board Color Puck 3",
        subText = "Allows you to the Color Panel of the Color Board.",
        item = function() puckWidget("colorBoardColorPuck3", "color", "midtones") end,
    }
    deps.manager.widgets:new("colorBoardColorPuck3", params)

    params = {
        group = "fcpx",
        text = "Color Board Color Puck 4",
        subText = "Allows you to the Color Panel of the Color Board.",
        item = function() puckWidget("colorBoardColorPuck4", "color", "highlights") end,
    }
    deps.manager.widgets:new("colorBoardColorPuck4", params)

    --------------------------------------------------------------------------------
    -- Saturation Panel:
    --------------------------------------------------------------------------------
    params = {
        group = "fcpx",
        text = "Color Board Saturation Puck 1",
        subText = "Allows you to the Saturation Panel of the Color Board.",
        item = function() puckWidget("colorBoardSaturationPuck1", "saturation", "global") end,
    }
    deps.manager.widgets:new("colorBoardSaturationPuck1", params)

    params = {
        group = "fcpx",
        text = "Color Board Saturation Puck 2",
        subText = "Allows you to the Saturation Panel of the Color Board.",
        item = function() puckWidget("colorBoardSaturationPuck2", "saturation", "shadows") end,
    }
    deps.manager.widgets:new("colorBoardSaturationPuck2", params)

    params = {
        group = "fcpx",
        text = "Color Board Saturation Puck 3",
        subText = "Allows you to the Saturation Panel of the Color Board.",
        item = function() puckWidget("colorBoardSaturationPuck3", "saturation", "midtones") end,
    }
    deps.manager.widgets:new("colorBoardSaturationPuck3", params)

    params = {
        group = "fcpx",
        text = "Color Board Saturation Puck 4",
        subText = "Allows you to the Saturation Panel of the Color Board.",
        item = function() puckWidget("colorBoardSaturationPuck4", "saturation", "highlights") end,
    }
    deps.manager.widgets:new("colorBoardSaturationPuck4", params)

    --------------------------------------------------------------------------------
    -- Exposure Panel:
    --------------------------------------------------------------------------------
    params = {
        group = "fcpx",
        text = "Color Board Exposure Puck 1",
        subText = "Allows you to the Exposure Panel of the Color Board.",
        item = function() puckWidget("colorBoardExposurePuck1", "exposure", "global") end,
    }
    deps.manager.widgets:new("colorBoardExposurePuck1", params)

    params = {
        group = "fcpx",
        text = "Color Board Exposure Puck 2",
        subText = "Allows you to the Exposure Panel of the Color Board.",
        item = function() puckWidget("colorBoardExposurePuck2", "exposure", "shadows") end,
    }
    deps.manager.widgets:new("colorBoardExposurePuck2", params)

    params = {
        group = "fcpx",
        text = "Color Board Exposure Puck 3",
        subText = "Allows you to the Exposure Panel of the Color Board.",
        item = function() puckWidget("colorBoardExposurePuck3", "exposure", "midtones") end,
    }
    deps.manager.widgets:new("colorBoardExposurePuck3", params)

    params = {
        group = "fcpx",
        text = "Color Board Exposure Puck 4",
        subText = "Allows you to the Exposure Panel of the Color Board.",
        item = function() puckWidget("colorBoardExposurePuck4", "exposure", "highlights") end,
    }
    deps.manager.widgets:new("colorBoardExposurePuck4", params)

    return mod

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.touchbar.widgets.colorboard",
    group           = "finalcutpro",
    dependencies    = {
        ["core.touchbar.manager"] = "manager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load this plugin if the Touch Bar is supported:
    --------------------------------------------------------------------------------
    if touchbar.supported() then
        return mod.init(deps)
    end
end

return plugin
