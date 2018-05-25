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
local prop              = require("cp.prop")

--------------------------------------------------------------------------------
-- 3rd Party Extensions:
--------------------------------------------------------------------------------
local touchbar          = require("hs._asm.undocumented.touchbar")

--------------------------------------------------------------------------------
-- Local Lua Functions:
--------------------------------------------------------------------------------
local insert            = table.insert
local format            = string.format
local abs               = math.abs

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
        fillColor = {hue = angle/360, saturation = 1, brightness = 1, alpha = abs(pct/100)}
    elseif pct then
        brightness = pct >= 0 and 1 or 0
        fillColor = {hue = 0, saturation = 0, brightness = brightness, alpha = abs(pct/100)}
    end

    local negative = false
    if pct and angle and pct < 0 then
        negative = true
    end

    return brightness, solidColor, fillColor, negative
end

-- getWidgetText(puck) -> string
-- Function
-- Returns the widget text.
--
-- Parameters:
--  * puck - The `ColorPuck` being described.
--
-- Returns:
--  * Text in `hs.styledtext` format
local function getWidgetText(puck)
    local puckID = puck:index()

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

    return styledtext.getStyledTextFromData(format(
        [[<span style="font-family: -apple-system; font-size: 12px; color: #FFFFFF;">]] ..
            [[<strong>%s</strong> %s]] ..
        [[</span>]],
        aspectTitle[puck:parent():id()],
        puckTitle[puckID]
    ))
end

-- updateCanvas(widgetCanvas, puck) -> none
-- Function
-- Updates a Canvas
--
-- Parameters:
--  * widgetCanvas - a `hs.canvas` object
--  * puck - The puck to manipulate.
--
-- Returns:
--  * None
local function updateCanvas(widgetCanvas, puck)

    if not puck:isShowing() then
        widgetCanvas.negative.action = "skip"
        widgetCanvas.arc.action = "skip"
        widgetCanvas.info.action = "skip"
        widgetCanvas.circle.action = "skip"
    else
        local pct = puck:percent()
        local angle = puck:angle()

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

        if puck:angle() ~= nil then
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

        widgetCanvas.text.text = getWidgetText(puck)
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
    --------------------------------------------------------------------------------
    -- Setup Timer:
    --------------------------------------------------------------------------------
    if not mod._timer then
        mod._timer = timer.new(mod.updateInterval, update)
    end

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
    if mod._timer then
        mod._timer:stop()
    end
end

-- puckWidget(id, puck) -> `hs._asm.undocumented.touchbar.item` object -> TouchBar Item
-- Function
-- Creates a Puck Widget.
--
-- Parameters:
--  * id - ID of the widget as string
--  * puck - a function that returns the `ColorPuck` to create the widget for.
--
-- Returns:
--  * A `hs._asm.undocumented.touchbar.item` object
local function puckWidget(id, puck)

    --------------------------------------------------------------------------------
    -- Record that we have created at least one widget.
    --------------------------------------------------------------------------------
    mod.hasWidgets(true)

    local pct = puck():percent()
    local angle = puck():angle()

    local brightness, _, fillColor, negative = calculateColor(pct, angle)

    local value = pct or 0

    local color = {hue=0, saturation=0, brightness=brightness, alpha=1}

    local widgetCanvas = canvas.new{x = 0, y = 0, h = 30, w = 150}

    --------------------------------------------------------------------------------
    -- Background:
    --------------------------------------------------------------------------------
    insert(widgetCanvas, {
        id               = "background",
        type             = "rectangle",
        action           = "strokeAndFill",
        strokeColor      = { white = 1 },
        fillColor        = { hex = "#292929", alpha = 1 },
        roundedRectRadii = { xRadius = 5, yRadius = 5 },
    })

    --------------------------------------------------------------------------------
    -- Text:
    --------------------------------------------------------------------------------
    insert(widgetCanvas, {
        id = "text",
        frame = { h = 30, w = 150, x = 10, y = 6 },
        text = getWidgetText(puck()),
        textAlignment = "left",
        textColor = { white = 1.0 },
        textSize = 12,
        type = "text",
    })

    --------------------------------------------------------------------------------
    -- Circle:
    --------------------------------------------------------------------------------
    insert(widgetCanvas, {
        id                  = "circle",
        type                = "circle",
        radius              = "7%",
        center              =  { x = "90%", y = "50%" },
        action              = "strokeAndFill",
        strokeColor         = color,
        fillColor           = fillColor,
    })

    --------------------------------------------------------------------------------
    -- Arc:
    --------------------------------------------------------------------------------
    local arcAction = puck():angle() ~= nil and "strokeAndFill" or "skip"
    insert(widgetCanvas, {
        id                  = "arc",
        type                = "arc",
        radius              = "7%",
        center              =  { x = "90%", y = "50%" },
        startAngle          = 135,
        endAngle            = 315,
        action              = arcAction,
        strokeColor         = color,
        fillColor           = color,
    })

    --------------------------------------------------------------------------------
    -- Negative Symbol (Used for Color Panel):
    --------------------------------------------------------------------------------
    local negativeType = negative and "strokeAndFill" or "skip"
    insert(widgetCanvas, {
        id              = "negative",
        type            = "rectangle",
        action          = negativeType,
        strokeColor     = {white=1, alpha=0.75},
        strokeWidth     = 1,
        fillColor       = {white=0, alpha=1.0 },
        frame           = { h = 5, w = 10, x = 130, y = 12 },
    })

    --------------------------------------------------------------------------------
    -- Text:
    --------------------------------------------------------------------------------
    local textValue = value and value .. "%" or ""
    insert(widgetCanvas, {
        id = "info",
        frame = { h = 30, w = 120, x = 0, y = 6 },
        text = textValue,
        textAlignment = "right",
        textColor = { white = 1.0 },
        textSize = 12,
        type = "text",
    })

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
                    puck():reset()
                    skipMaths = true
                else
                    mod._doubleTap[id] = true
                end
                timer.doAfter(eventtap.doubleClickInterval(), function()
                    mod._doubleTap[id] = false
                end)
            end

            --------------------------------------------------------------------------------
            -- Show the Puck if it's hidden:
            --------------------------------------------------------------------------------
            puck():show()

            --------------------------------------------------------------------------------
            -- Abort if Puck is still not showing.
            --------------------------------------------------------------------------------
            if not puck():isShowing() then
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
            updateCanvas(o, puck())

            --------------------------------------------------------------------------------
            -- Perform Action:
            --------------------------------------------------------------------------------
            if not skipMaths then
                if m == "mouseDown" or m == "mouseMove" then
                    if shiftPressed then
                        puck():angle(x)
                    else
                        puck():percent(x)
                    end
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
    updateCanvas(widgetCanvas, puck())

    --------------------------------------------------------------------------------
    -- Create new Touch Bar Item from Canvas:
    --------------------------------------------------------------------------------
    local item = touchbar.item.newCanvas(widgetCanvas, id):canvasClickColor{ alpha = 0.0 }

    --------------------------------------------------------------------------------
    -- Add update callback to timer:
    --------------------------------------------------------------------------------
    mod._updateCallbacks[#mod._updateCallbacks + 1] = function()
        if item:isVisible() then
            updateCanvas(widgetCanvas, puck())
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
    local colorBoard = fcp:colorBoard()

    --------------------------------------------------------------------------------
    -- Setup Toggle Button:
    --------------------------------------------------------------------------------
    local widgetCanvas = canvas.new{x = 0, y = 0, h = 30, w = 50}
    insert(widgetCanvas, {
        id               = "background",
        type             = "rectangle",
        action           = "strokeAndFill",
        strokeColor      = { white = 1 },
        fillColor        = { hex = "#292929", alpha = 1 },
        roundedRectRadii = { xRadius = 5, yRadius = 5 },
    })
    insert(widgetCanvas, {
        id = "text",
        frame = { h = 30, w = 50, x = 0, y = 6 },
        text = "Toggle",
        textAlignment = "center",
        textColor = { white = 1.0 },
        textSize = 12,
        type = "text",
    })
    widgetCanvas:canvasMouseEvents(true, true, false, true)
        :mouseCallback(function(_,m)
            if m == "mouseDown" or m == "mouseMove" then
                mod.stop()
                colorBoard:nextAspect()
                mod.start(0.01)
            end
        end)

    --------------------------------------------------------------------------------
    -- Setup Group:
    --------------------------------------------------------------------------------
    local group = touchbar.item.newGroup(id):groupItems({
        touchbar.item.newCanvas(widgetCanvas):canvasClickColor{ alpha = 0.0 },
        puckWidget("colorBoardGroup1", function() return colorBoard:current():master() end),
        puckWidget("colorBoardGroup2", function() return colorBoard:current():shadows() end),
        puckWidget("colorBoardGroup3", function() return colorBoard:current():midtones() end),
        puckWidget("colorBoardGroup4", function() return colorBoard:current():highlights() end),
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
        item = function() return groupPuck("colorBoardGroup") end,
    }
    deps.manager.widgets:new("colorBoardGroup", params)

    local colorBoard = fcp:colorBoard()

    --------------------------------------------------------------------------------
    -- Active Puck Controls:
    --------------------------------------------------------------------------------
    params = {
        group = "fcpx",
        text = "Color Board Puck 1",
        subText = "Allows you to control puck one of the Color Board.",
        item = function() return puckWidget("colorBoardPuck1", function() return colorBoard:current():master() end) end,
    }
    deps.manager.widgets:new("colorBoardPuck1", params)

    params = {
        group = "fcpx",
        text = "Color Board Puck 2",
        subText = "Allows you to control puck two of the Color Board.",
        item = function() return puckWidget("colorBoardPuck2", function() return colorBoard:current():shadows() end) end,
    }
    deps.manager.widgets:new("colorBoardPuck2", params)

    params = {
        group = "fcpx",
        text = "Color Board Puck 3",
        subText = "Allows you to control puck three of the Color Board.",
        item = function() return puckWidget("colorBoardPuck3", function() return colorBoard:current():midtones() end) end,
    }
    deps.manager.widgets:new("colorBoardPuck3", params)

    params = {
        group = "fcpx",
        text = "Color Board Puck 4",
        subText = "Allows you to control puck four of the Color Board.",
        item = function() return puckWidget("colorBoardPuck4", function() return colorBoard:current():highlights() end) end,
    }
    deps.manager.widgets:new("colorBoardPuck4", params)

    --------------------------------------------------------------------------------
    -- Color Panel:
    --------------------------------------------------------------------------------
    params = {
        group = "fcpx",
        text = "Color Board Color Puck 1",
        subText = "Allows you to the Color Panel of the Color Board.",
        item = function() return puckWidget("colorBoardColorPuck1", function() return colorBoard:color():master() end) end,
    }
    deps.manager.widgets:new("colorBoardColorPuck1", params)

    params = {
        group = "fcpx",
        text = "Color Board Color Puck 2",
        subText = "Allows you to the Color Panel of the Color Board.",
        item = function() return puckWidget("colorBoardColorPuck2", function() return colorBoard:color():shadows() end) end,
    }
    deps.manager.widgets:new("colorBoardColorPuck2", params)

    params = {
        group = "fcpx",
        text = "Color Board Color Puck 3",
        subText = "Allows you to the Color Panel of the Color Board.",
        item = function() return puckWidget("colorBoardColorPuck3", function() return colorBoard:color():midtones() end) end,
    }
    deps.manager.widgets:new("colorBoardColorPuck3", params)

    params = {
        group = "fcpx",
        text = "Color Board Color Puck 4",
        subText = "Allows you to the Color Panel of the Color Board.",
        item = function() return puckWidget("colorBoardColorPuck4", function() return colorBoard:color():highlights() end) end,
    }
    deps.manager.widgets:new("colorBoardColorPuck4", params)

    --------------------------------------------------------------------------------
    -- Saturation Panel:
    --------------------------------------------------------------------------------
    params = {
        group = "fcpx",
        text = "Color Board Saturation Puck 1",
        subText = "Allows you to the Saturation Panel of the Color Board.",
        item = function() return puckWidget("colorBoardSaturationPuck1", function() return colorBoard:saturation():master() end) end,
    }
    deps.manager.widgets:new("colorBoardSaturationPuck1", params)

    params = {
        group = "fcpx",
        text = "Color Board Saturation Puck 2",
        subText = "Allows you to the Saturation Panel of the Color Board.",
        item = function() return puckWidget("colorBoardSaturationPuck2", function() return colorBoard:saturation():shadows() end) end,
    }
    deps.manager.widgets:new("colorBoardSaturationPuck2", params)

    params = {
        group = "fcpx",
        text = "Color Board Saturation Puck 3",
        subText = "Allows you to the Saturation Panel of the Color Board.",
        item = function() return puckWidget("colorBoardSaturationPuck3", function() return colorBoard:saturation():midtones() end) end,
    }
    deps.manager.widgets:new("colorBoardSaturationPuck3", params)

    params = {
        group = "fcpx",
        text = "Color Board Saturation Puck 4",
        subText = "Allows you to the Saturation Panel of the Color Board.",
        item = function() return puckWidget("colorBoardSaturationPuck4", function() return colorBoard:saturation():highlights() end) end,
    }
    deps.manager.widgets:new("colorBoardSaturationPuck4", params)

    --------------------------------------------------------------------------------
    -- Exposure Panel:
    --------------------------------------------------------------------------------
    params = {
        group = "fcpx",
        text = "Color Board Exposure Puck 1",
        subText = "Allows you to the Exposure Panel of the Color Board.",
        item = function() return puckWidget("colorBoardExposurePuck1", function() return colorBoard:exposure():global() end) end,
    }
    deps.manager.widgets:new("colorBoardExposurePuck1", params)

    params = {
        group = "fcpx",
        text = "Color Board Exposure Puck 2",
        subText = "Allows you to the Exposure Panel of the Color Board.",
        item = function() return puckWidget("colorBoardExposurePuck2", function() return colorBoard:exposure():shadows() end) end,
    }
    deps.manager.widgets:new("colorBoardExposurePuck2", params)

    params = {
        group = "fcpx",
        text = "Color Board Exposure Puck 3",
        subText = "Allows you to the Exposure Panel of the Color Board.",
        item = function() return puckWidget("colorBoardExposurePuck3", function() return colorBoard:exposure():midtones() end) end,
    }
    deps.manager.widgets:new("colorBoardExposurePuck3", params)

    params = {
        group = "fcpx",
        text = "Color Board Exposure Puck 4",
        subText = "Allows you to the Exposure Panel of the Color Board.",
        item = function() return puckWidget("colorBoardExposurePuck4", function() return colorBoard:exposure():highlights() end) end,
    }
    deps.manager.widgets:new("colorBoardExposurePuck4", params)

    return mod

end

--- plugins.finalcutpro.touchbar.widgets.colorboard.hasWidgets <cp.prop: boolean>
--- Variable
--- Indicates if any widgests have been created.
mod.hasWidgets = prop.FALSE()

--- plugins.finalcutpro.touchbar.widgets.colorboard.active <cp.prop: boolean>
--- Variable
--- Indicates if the widget is active.
mod.active = mod.hasWidgets:AND(fcp.app.frontmost:OR(fcp.app.showing)):watch(function(active)
    if active then
        mod.start()
    else
        mod.stop()
    end
end)

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
