-- === plugins.finalcutpro.viewer.overlays.DraggableGuide ===
--
-- A draggable guide, visible over the main Viewer.

local require = require

local log               = require "hs.logger" .new "DraggableGuide"
local inspect           = require "hs.inspect"

local Bar               = require "Bar"
local Dot               = require "Dot"

local config            = require "cp.config"
local fcp               = require "cp.apple.finalcutpro"

local color             = require "hs.drawing.color"
local geometry          = require "hs.geometry"

local class             = require "middleclass"
local lazy              = require "cp.lazy"

local format            = string.format
local min, max          = math.min, math.max

local DraggableGuide = class("finalcutpro.viewer.overlays.DraggableGuide"):include(lazy)

-- DEFAULT_COLOR -> string
-- Constant
-- Default Colour Setting.
local DEFAULT_COLOR = color.asRGB({ hex = "#FFFFFF" })

local BAR_THICKNESS = 2
local DOT_RADIUS = 6

local CONFIG_PREFIX = "finalcutpro.viewer.overlays.DraggableGuide"

local function logInspect(label, value)
    -- log.df("%s: %s", label, inspect(value))
    return value
end

local function named(id, name)
    return format("%s.%s.%s", CONFIG_PREFIX, id, name)
end

-- creates a `cp.prop` which wraps the passed `cp.prop` containing an `{x,y,w,h}` table to and from a ` hs.geometry.rect`.
local function asRect(frameProp)
    return frameProp:mutate(
        function(original)
            local value = original()
            return value and geometry.rect(value) or nil
        end,
        function(value, original)
            if value and value.table then
                -- it's a geometry rect.
                original:set(value.table)
            else
                original:set(value)
            end
        end
    )
end

-- creates a `cp.prop` which wraps the passed `cp.prop` containing an `{x,y,w,h}` table to and from a ` hs.geometry.rect`.
local function asPoint(pointProp)
    return pointProp:mutate(
        function(original)
            local value = original()
            return value and geometry.point(value) or nil
        end,
        function(value, original)
            if value and value.table then
                original:set(value.table)
            else
                original:set(value)
            end
        end
    )
end

-- determines if FCP is available to have the guides overlaid on.
local fcpAvailable = fcp.isFrontmost
    :AND(fcp.isModalDialogOpen:NOT())
    :AND(fcp.fullScreenWindow.isShowing:NOT())
    :AND(fcp.preferencesWindow.isShowing:NOT())

--- plugins.finalcutpro.viewer.DraggableGuide.active <cp.prop: boolean; live>
--- Variable
--- If set to `true`, any enabled `DraggableGuide`s will be visible when FCPX is available.
DraggableGuide.static.active = config.prop(named("global", "active"))

-- plugins.finalcutpro.viewer.DraggableGuide(viewer, id) -> DraggableGuide
-- Constructor
-- Constructs a new `DraggableGuide` on the nominated `Viewer` with the specified id.
--
-- Parameter:
--  * viewer    - The `cp.apple.finalcutpro.viewer.Viewer` the guide is attached to.
--  * id        - The id of the guide (eg `1`.)
--
-- Returns:
--  * The new `DraggableGuide`.
function DraggableGuide:initialize(viewer, id)
    self.viewer = viewer
    self.id = id

    self.verticalBar = Bar(self._verticalBarFrame, self.colorWithAlpha, self.isEnabled, self.isActive)
    self.horizontalBar = Bar(self._horizontalBarFrame, self.colorWithAlpha, self.isEnabled, self.isActive)
    self.dot = Dot(self._dotFrame, self.target, self.colorWithAlpha, self.isEnabled, self.isActive)

    self.isActive:update()
end

-- plugins.finalcutpro.viewer.overlays.DraggableGuide.frame <cp.prop: hs.geometry.rect; live?>
-- Field
-- The outer frame of the guide.
function DraggableGuide.lazy.prop:frame()
    return asRect(self.viewer.videoImage.frame)
end

-- plugins.finalcutpro.viewer.overlays.DraggableGuide.isActive <cp.prop: boolean; live>
-- Field
-- Indicates if the guide should be shown on-screen.
function DraggableGuide.lazy.prop:isActive()
    return self.isEnabled:AND(fcpAvailable):AND(self.viewer.isShowing)
end

-- plugins.finalcutpro.viewer.overlays.DraggableGuide.isEnabled <cp.prop: boolean; live>
-- Field
-- If `true`, the guide is enabled. It may not be visible however, since that depends on whether the Viewer is visible and not obscured.
function DraggableGuide.lazy.prop:isEnabled()
    return config.prop(named(self.id, "enabled"), false)
end

-- plugins.finalcutpro.viewer.overlays.DraggableGuide.position <cp.prop: hs.geometry.point; live>
-- Field
-- A `table` containing an `x` and `y` value representing the position of the guide as a percentage of the `Viewer` frame width and height.
--
-- For example: `guide:position({ x = 0.5, y = 0.5 })` puts the guide in the center of the Viewer.
function DraggableGuide.lazy.prop:position()
    return asPoint(config.prop(named(self.id, "position"), { x = 0.5, y = 0.5 }))
end

-- clamp(value, minValue, maxValue) -> number
-- Function
-- Returns the value, clamped betwen the provide min and max values.
--
-- Parameters:
--  * value - The original value.
--  * minValue - The minimum allowed value.
--  * maxValue - The maximum allowed value.
--
-- Returns:
--  * The clamped value.
local function clamp(value, minValue, maxValue)
    return max(min(value, maxValue), minValue)
end

-- plugins.finalcutpro.viewer.overlays.DraggableGuide.target <cp.prop: hs.geometry.point; live>
-- Field
-- The current position of the center of the guide in absolute x/y coordinates.
function DraggableGuide.lazy.prop:target()
    return self.position:mutate(
        function(original)
            local position = original()
            local frame = self:frame()

            return logInspect("target", position and frame and position:fromUnitRect(self:frame()))
        end,
        function(value, original)
            if not value then
                original:set(nil)
                return
            end

            local frame = self:frame()
            if not frame then
                original:set(nil)
                return
            end

            local position = {
                x = clamp((value.x - frame.x)/frame.w, 0, 1),
                y = clamp((value.y - frame.y)/frame.h, 0, 1)
            }
            original:set(position)
        end
    )
    :monitor(self.frame)
end

-- plugins.finalcutpro.viewer.overlays.DraggableGuide.color <cp.prop: string; live>
-- Field
-- The color of the guide as a hex string (eg. "#FFFFFF").
function DraggableGuide.lazy.prop:color()
    return config.prop(named(self.id, "color"), DEFAULT_COLOR):mutate(
        function(original)
            local value = original()
            if type(value) == "string" then
                value = { hex = value }
            end
            return value and color.asRGB(value)
        end,
        function(value, original)
            if type(value) == "string" then
                value = { hex = value }
            end
            if type(value) == "table" then
                value = color.asRGB(value)
                original({ red = value.red, green = value.green, blue = value.blue }) -- ignoring alpha
            else
                original(nil)
            end
        end
    )
end

-- plugins.finalcutpro.viewer.overlays.DraggableGuide.alpha <cp.prop: number: live>
-- Field
-- The transparancy value of the guide, a percentage from `0.0` to `1.0`.
function DraggableGuide.lazy.prop:alpha()
    return config.prop(named(self.id, "alpha"), 1.0)
end

function DraggableGuide.lazy.prop:colorWithAlpha()
    return self.color:mutate(function(original)
        local color = original()
        color.alpha = self:alpha()
        return color
    end)
    :monitor(self.alpha)
end

-- plugins.finalcutpro.viewer.overlay.DraggableGuide:reset()
-- Method
-- Resets the position and color properties of the guide.
function DraggableGuide:reset()
    self.position:set(nil)
    self.alpha:set(nil)
    self.color:set(nil)
    self.customColor:set(nil)
end

function DraggableGuide:update()

end

-- plugins.finalcutpro.viewer.overlay.DraggableGuide._verticalBarFrame <cp.prop: hs.geometry.rect; live>
-- Field
-- The frame for the vertical bar.
function DraggableGuide.lazy.prop:_verticalBarFrame()
    return self.target:mutate(function(original)
        local target = original()
        local frame = self:frame()
        if not target or not frame then
            return nil
        end

        return logInspect("_verticalBarFrame",
            geometry.rect { x = target.x - BAR_THICKNESS/2, y = frame.y, w = BAR_THICKNESS, h = frame.h }
            :intersect(frame)
        )
    end)
    :monitor(self.frame)
end

-- plugins.finalcutpro.viewer.overlay.DraggableGuide._horizontalBarFrame <cp.prop: hs.geometry.rect; live>
-- Field
-- The frame for the horizontal bar.
function DraggableGuide.lazy.prop:_horizontalBarFrame()
    return self.target:mutate(function(original)
        local target = original()
        local frame = self:frame()
        if not target or not frame then
            return nil
        end

        return logInspect("_horizontalBarFrame",
            geometry.rect { x = frame.x, y = target.y - BAR_THICKNESS/2, w = frame.w, h = BAR_THICKNESS }
            :intersect(frame)
        )
    end)
    :monitor(self.frame)
end

-- plugins.finalcutpro.viewer.overlay.DraggableGuide._dotFrame <cp.prop: hs.geometry.rect; live>
-- Field
-- The frame for the dot.
function DraggableGuide.lazy.prop:_dotFrame()
    return self.target:mutate(function(original)
        local target = original()
        local frame = self:frame()
        if not target or not frame then
            log.df("_dotFrame: no target or viewer frame available")
            return nil
        end

        local dotFrame = geometry.rect {
            x = target.x - DOT_RADIUS,
            y = target.y - DOT_RADIUS,
            w = DOT_RADIUS*2,
            h = DOT_RADIUS*2
        }

        return logInspect("_dotFrame",
            dotFrame:intersect(frame)
        )
    end)
    :monitor(self.frame)
end

return DraggableGuide