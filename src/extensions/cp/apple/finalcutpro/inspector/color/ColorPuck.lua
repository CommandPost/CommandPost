--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.inspector.color.ColorPuck ===
---
--- Color Puck Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log                                    = require("hs.logger").new("colorPuck")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local drawing                               = require("hs.drawing")
local geometry                              = require("hs.geometry")
local mouse                                 = require("hs.mouse")
local timer                                 = require("hs.timer")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils                               = require("cp.ui.axutils")
local prop                                  = require("cp.prop")
local PropertyRow                           = require("cp.ui.PropertyRow")
local TextField                             = require("cp.ui.TextField")
local tools                                 = require("cp.tools")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Puck = {}

--- cp.apple.finalcutpro.inspector.color.ColorPuck.RANGE -> table
--- Constant
--- Table of puck ranges.
Puck.RANGE = {master=1, shadows=2, midtones=3, highlights=4}

--- cp.apple.finalcutpro.inspector.color.ColorPuck.NATURAL_LENGTH -> number
--- Constant
--- Natural Length as number.
Puck.NATURAL_LENGTH = 20

--- cp.apple.finalcutpro.inspector.color.ColorPuck.ELASTICITY -> number
--- Constant
--- Elasticity as number.
Puck.ELASTICITY = Puck.NATURAL_LENGTH/10

-- cp.apple.finalcutpro.inspector.color.ColorPuck._active -> boolean
-- Constant
-- Is the ColorPuck active?
Puck._active = nil

--- cp.apple.finalcutpro.inspector.color.ColorPuck.DEFAULT_ANGLES -> table
--- Constant
--- The table of default angles for the various pucks (1-4).
Puck.DEFAULT_ANGLES = { 110, 180, 215, 250 }

-- tension(diff) -> number
-- Function
-- Calculates the tension given the x/y difference value, based on the Puck elasticity and natural length.
--
-- Parameters:
-- * diff   - The amount of stretch in a given dimension.
--
-- Returns:
-- * The tension factor.
local function tension(diff)
    local factor = diff < 0 and -1 or 1
    local t = Puck.ELASTICITY * (diff*factor-Puck.NATURAL_LENGTH) / Puck.NATURAL_LENGTH
    return t < 0 and 0 or t * factor
end

--- cp.apple.finalcutpro.inspector.color.ColorPuck.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function Puck.matches(element)
    return element and element:attributeValue("AXRole") == "AXButton"
end

--- cp.apple.finalcutpro.inspector.color.ColorPuck.new(parent, puckNumber, labelKeys, hasAngle) -> ColorPuck
--- Constructor
--- Creates a new `ColorPuck` object
---
--- Parameters:
---  * `parent`     - The parent
---  * `puckNumber` - The puck number
---  * `labelKeys`  - Label Keys
---  * `hasAngle`   - If `true`, the puck has an `angle` parameter.
---
--- Returns:
---  * A ColorInspector object
function Puck.new(parent, puckNumber, labelKeys, hasAngle) -- luacheck: ignore

    assert(
        puckNumber >= Puck.RANGE.master and puckNumber <= Puck.RANGE.highlights,
        string.format("Please supply a puck number between %s and %s.", Puck.RANGE.master, Puck.RANGE.highlights)
    )

    local o = prop.extend({
        _parent     = parent,
        _puckNumber = puckNumber,
        _labelKeys  = labelKeys,
        _hasAngle   = hasAngle,
        xShift = 0,
        yShift = 0
    }, Puck)

    --- cp.apple.finalcutpro.inspector.color.ColorPuck.row <cp.prop: PropertyRow>
    --- Field
    --- Finds the 'row' for the property type.
    o.row = PropertyRow.new(o, o._labelKeys, "contentUI")

    --- cp.apple.finalcutpro.inspector.color.ColorPuck.label <cp.prop: string; read-only>
    --- Field
    --- The human-readable label for the puck, in FCPX's current language.
    o.label = o.row.label:wrap(o)

    --- cp.apple.finalcutpro.inspector.color.ColorPuck.percent <cp.prop: TextField>
    --- Field
    --- The 'percent' text field.
    o.percent = TextField.new(o, function()
        local fields = axutils.childrenWithRole(o.row:children(), "AXTextField")
        return fields and fields[#fields] or nil
    end, tonumber)

    --- cp.apple.finalcutpro.inspector.color.ColorPuck.angle <cp.prop: TextField>
    --- Field
    --- The 'angle' text field (only present for the 'color' aspect).
    o.angle = TextField.new(o, function()
        if o._hasAngle then
            local fields = axutils.childrenWithRole(o.row:children(), "AXTextField")
            return fields and #fields > 1 and fields[1] or nil
        else
            return nil
        end
    end, tonumber)

    return o
end

--- cp.apple.finalcutpro.inspector.color.ColorPuck:index() -> number
--- Method
--- Returns the puck number (1 through 4).
---
--- Parameters:
--- * None
---
--- Returns:
--- * The puck number.
function Puck:index()
    return self._puckNumber
end

--- cp.apple.finalcutpro.inspector.color.ColorPuck:hasAngle() -> boolean
--- Method
--- Indicates if the puck has an `angle` parameter. The `angle` `cp.prop` will always
--- exist regardless, but if this is `false`, it will never return a result.
---
--- Parameters:
--- * None
---
--- Returns:
--- * `true` if the puck has an `angle`.
function Puck:hasAngle()
    return self._hasAngle
end

--- cp.apple.finalcutpro.inspector.color.ColorPuck:parent() -> object
--- Method
--- Returns the Parent object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object.
function Puck:parent()
    return self._parent
end

--- cp.apple.finalcutpro.inspector.color.ColorPuck:app() -> App
--- Method
--- Returns the App instance representing Final Cut Pro.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function Puck:app()
    return self:parent():app()
end

--- cp.apple.finalcutpro.inspector.color.ColorPuck:UI() -> axuielementObject
--- Method
--- Returns the Color Puck Accessibility Object
---
--- Parameters:
---  * None
---
--- Returns:
---  * An `axuielementObject` or `nil`
function Puck:UI()
    return axutils.cache(self, "_ui", function()
        local buttons = axutils.childrenWithRole(self:parent():UI(), "AXButton")
        return buttons and #buttons == 5 and buttons[self._puckNumber+1] or nil
    end, Puck.matches)
end

--- cp.apple.finalcutpro.inspector.color.ColorPuck:contentUI() -> axuielementObject
--- Method
--- Returns the Content Accessibility Object
---
--- Parameters:
---  * None
---
--- Returns:
---  * An `axuielementObject` or `nil`
function Puck:contentUI()
    return self:parent():UI()
end

--- cp.apple.finalcutpro.inspector.color.ColorPuck:isShowing() -> boolean
--- Method
--- Gets whether or not the Color Puck is showing.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if showing or `false` if not.
function Puck:isShowing()
    return self:UI() ~= nil
end

--- cp.apple.finalcutpro.inspector.color.ColorPuck:show() -> cp.apple.finalcutpro.inspector.color.ColorPuck
--- Method
--- Shows the Color Puck
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.apple.finalcutpro.inspector.color.ColorPuck` object for method chaining.
function Puck:show()
    self:parent():show()
    return self
end

--- cp.apple.finalcutpro.inspector.color.ColorPuck:select() -> cp.apple.finalcutpro.inspector.color.ColorPuck
--- Method
--- Selects this puck.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `ColorPuck` instance.
function Puck:select()
    self:show()
    local ui = self:UI()
    if ui then
        local f = ui:frame()
        -- local centre = geometry(f.x + f.w/2, f.y + f.h/2)
        local centre = geometry(f).center
        tools.ninjaMouseClick(centre)
    end
    return self
end

--- cp.apple.finalcutpro.inspector.color.ColorPuck:shiftPercent(amount) -> cp.apple.finalcutpro.inspector.color.ColorPuck
--- Method
--- Shifts the percent value by the provide amount.
---
--- Parameters:
---  * `amount` - The amount to shift the percent value.
---
--- Returns:
---  * The updated value.
function Puck:shiftPercent(amount)
    local value = self:percent()
    if value ~= nil then
        value = self:percent(value + amount)
    end
    return value
end

--- cp.apple.finalcutpro.inspector.color.ColorPuck:shiftAngle(amount) -> cp.apple.finalcutpro.inspector.color.ColorPuck
--- Method
--- Shifts the angle value by the provide amount.
---
--- Parameters:
--- * amount - The amount to shift the angle value.
---
--- Returns:
--- * The `ColorPuck` instance.
function Puck:shiftAngle(amount)
    local value = self:angle()
    if value ~= nil then
        value = self:angle(value + amount)
    end
    return value
end

--- cp.apple.finalcutpro.inspector.color.ColorPuck:reset() -> cp.apple.finalcutpro.inspector.color.ColorPuck
--- Method
--- Resets the puck to its default settings.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `ColorPuck` instance.
function Puck:reset()
    self:percent(0)
    self:angle(Puck.DEFAULT_ANGLES[self:index()])
    return self
end

--- cp.apple.finalcutpro.inspector.color.ColorPuck.skimming <cp.prop: boolean>
--- Field
--- The Skimming Preferences value.
Puck.skimming = prop(function(self)
    return not self:app():getPreference("FFDisableSkimming", false)
end):bind(Puck)

--- cp.apple.finalcutpro.inspector.color.ColorPuck:start() -> cp.apple.finalcutpro.inspector.color.ColorPuck
--- Method
--- Starts a Color Puck.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `ColorPuck` instance.
function Puck:start()
    --------------------------------------------------------------------------------
    -- Stop any running pucks when starting a new one:
    --------------------------------------------------------------------------------
    if Puck._active then
        Puck._active:stop()
    end

    --------------------------------------------------------------------------------
    -- Disable skimming while the Puck is running:
    --------------------------------------------------------------------------------
    self.menuBar = self:parent():app():menuBar()
    if self.skimming() then
        self.menuBar:checkMenu({"View", "Skimming"})
    end

    Puck._active = self

    --------------------------------------------------------------------------------
    -- Select the puck to ensure properties are available:
    --------------------------------------------------------------------------------
    self:select()

    --------------------------------------------------------------------------------
    -- Record the origin and draw a marker:
    --------------------------------------------------------------------------------
    self.origin = mouse.getAbsolutePosition()
    self:drawMarker()

    --------------------------------------------------------------------------------
    -- Start the timer:
    --------------------------------------------------------------------------------
    self.running = true
    Puck.loop(self)
    return self
end

--- cp.apple.finalcutpro.inspector.color.ColorPuck:getBrightness() -> number
--- Method
--- Gets the brightness value.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The brightness value as number.
function Puck:getBrightness()
    if self.property == "global" then
        return 0.25
    elseif self.property == "shadows" then
        return 0
    elseif self.property == "midtones" then
        return 0.33
    elseif self.property == "highlights" then
        return 0.66
    else
        return 1
    end
end

--- cp.apple.finalcutpro.inspector.color.ColorPuck:getArc() -> number
--- Method
--- Gets the arc value.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The arc value as number.
function Puck:getArc()
    if self.angleUI then
        return 135, 315
    elseif self.property == "global" then
        return 0, 0
    else
        return 90, 270
    end
end

--- cp.apple.finalcutpro.inspector.color.ColorPuck:drawMarker() -> none
--- Method
--- Draws a marker.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function Puck:drawMarker()
    local d = Puck.NATURAL_LENGTH*2
    local oFrame = geometry.rect(self.origin.x-d/2, self.origin.y-d/2, d, d)

    local brightness = self:getBrightness()
    local color = {hue=0, saturation=0, brightness=brightness, alpha=1}

    self.circle = drawing.circle(oFrame)
        :setStrokeColor(color)
        :setFill(true)
        :setStrokeWidth(1)

    local aStart, aEnd = self:getArc()
    self.arc = drawing.arc(self.origin, d/2, aStart, aEnd)
        :setStrokeColor(color)
        :setFillColor(color)
        :setFill(true)

    local rFrame = geometry.rect(self.origin.x-d/4, self.origin.y-d/8, d/2, d/4)
    self.negative = drawing.rectangle(rFrame)
        :setStrokeColor({white=1, alpha=0.75})
        :setStrokeWidth(1)
        :setFillColor({white=0, alpha=1.0 })
        :setFill(true)
end

--- cp.apple.finalcutpro.inspector.color.ColorPuck:colorMarker(pct, angle) -> none
--- Method
--- Draws a Color Marker.
---
--- Parameters:
---  * pct - Percentage
---- * angle - Angle
---
--- Returns:
---  * None
function Puck:colorMarker(pct, angle)
    local solidColor = nil
    local fillColor

    if angle then
        solidColor = {hue = angle/360, saturation = 1, brightness = 1, alpha = 1}
        fillColor = {hue = angle/360, saturation = 1, brightness = 1, alpha = math.abs(pct/100)}
    else
        local brightness = pct >= 0 and 1 or 0
        fillColor = {hue = 0, saturation = 0, brightness = brightness, alpha = math.abs(pct/100)}
    end

    if solidColor then
        self.circle:setStrokeColor(solidColor)
        self.arc:setStrokeColor(solidColor)
            :setFillColor(solidColor)
    end

    self.circle:setFillColor(fillColor):show()

    self.arc:show()

    if angle and pct < 0 then
        self.negative:show()
    else
        self.negative:hide()
    end
end

--- cp.apple.finalcutpro.inspector.color.ColorPuck:stop() -> none
--- Method
--- Stops a Color Puck.
---
--- Parameters:
--- * None
---
--- Returns:
--- * None
function Puck:stop()
    self.running = false
end

--- cp.apple.finalcutpro.inspector.color.ColorPuck:cleanup() -> none
--- Method
--- Cleans up the Color Puck drawings.
---
--- Parameters:
--- * None
---
--- Returns:
--- * None
function Puck:cleanup()
    self.running = false
    if self.circle then
        self.circle:delete()
        self.circle = nil
    end
    if self.arc then
        self.arc:delete()
        self.arc = nil
    end
    if self.negative then
        self.negative:delete()
        self.negative = nil
    end
    self.origin = nil
    if self.skimming() and self.menuBar then
        self.menuBar:checkMenu({"View", "Skimming"})
    end
    self.menuBar = nil
    Puck._active = nil
end

--- cp.apple.finalcutpro.inspector.color.ColorPuck:accumulate() -> none
--- Method
--- Accumulate's the Shift Values.
---
--- Parameters:
--- * `xShift` - `x` value as number
--- * `yShift` - `y` value as number
---
--- Returns:
--- * `x` - Accumulated `x` value as number
--- * `y` - Accumulated `y` value as number
function Puck:accumulate(xShift, yShift)
    if xShift < 1 and xShift > -1 then
        self.xShift = self.xShift + xShift
        if self.xShift > 1 or self.xShift < -1 then
            xShift = self.xShift
            self.xShift = 0
        else
            xShift = 0
        end
    end
    if yShift < 1 and yShift > -1 then
        self.yShift = self.yShift + yShift
        if self.yShift > 1 or self.yShift < -1 then
            yShift = self.yShift
            self.yShift = 0
        else
            yShift = 0
        end
    end
    return xShift, yShift
end

--- cp.apple.finalcutpro.inspector.color.ColorPuck:loop() -> none
--- Method
--- Loops the Color Puck function.
---
--- Parameters:
--- * None
---
--- Returns:
--- * None
function Puck:loop()
    if not self.running then
        self:cleanup()
        return
    end

    local pct = self.percent
    local angle = self.angle

    local current = mouse.getAbsolutePosition()
    local xDiff = current.x - self.origin.x
    local yDiff = self.origin.y - current.y

    local xShift = tension(xDiff)
    local yShift = tension(yDiff)

    xShift, yShift = self:accumulate(xShift, yShift)

    local pctValue = (pct:value() or 0) + yShift
    local angleValue = ((angle:value() or 0) + xShift + 360) % 360
    self:colorMarker(pctValue, angleValue)

    if yShift then pct:value(pctValue) end
    if xShift then angle:value(angleValue) end

    timer.doAfter(0.01, function() self:loop() end)
end

-- cp.apple.finalcutpro.inspector.color.ColorPuck:__tostring() -> string
-- Method
-- Gets the Puck ID.
--
-- Parameters:
-- * None
--
-- Returns:
-- * The Puck ID as string.
function Puck:__tostring()
    return string.format("%s - %s", self:parent(), self:label() or "[Unknown]")
end

return Puck