-- === finalcutpro.viewer.overlays.Dot ===
--
-- Represents a target dot on a `DraggableGuide`.

local require = require

-- local log                   = require "hs.logger" .new "Dot"
-- local inspect               = require "hs.inspect"

local deferred              = require "cp.deferred"
local prop                  = require "cp.prop"

local canvas                = require "hs.canvas"
local eventtap              = require "hs.eventtap"
local timer                 = require "hs.timer"

local class                 = require "middleclass"

local secondsSinceEpoch     = timer.secondsSinceEpoch
local eventTypes            = eventtap.event.types

local Dot = class("finalcutpro.viewer.overlays.Dot")

local DOT_ID = "dot"

-- finalcutpro.viewer.overlays.Dot(frame, target, color, isEnabled, isActive)
-- Constructor
-- Initializes a `Dot` with the provided `frame` and `color` `cp.prop` values.
--
-- Parameters:
--  * frame: The frame for the dot.
--  * target: The actual target, which may be different to the center of the frame.
--  * color: The `cp.drawing.color` to fill the bar with.
--  * isEnabled: If `true`, the bar will be loaded, ready to show.
--  * isActive: If `true`, the bar will be visible.
function Dot:initialize(frame, target, color, isEnabled, isActive)
    prop.bind(self) {
        frame = frame,
        target = target,
        color = color,
        isEnabled = isEnabled,
        isActive = isActive,
    }

    self.isEnabled:watch(function(enabled)
        if not enabled then
            self:_killOverlay()
        end
    end, true)

    self.isActive:watch(function(active)
        self:update()
    end, true)

    self.frame:watch(function(frame)
        local overlay = self:overlay()
        if overlay and frame then
            overlay:frame(frame)
        end
        self:update()
    end, true)

    self.target:watch(function(target)
        self:update()
    end)

    self.color:watch(function(color)
        local overlay = self:overlay()
        if overlay and color then
            local filler = self._overlay[DOT_ID]
            filler.fillColor = color
            filler.strokeColor = color
            self:update()
        end
    end, true)
end


function Dot:overlay()
    if self._overlay then
        return self._overlay
    end

    local frame = self:frame()
    -- local target = self:target()
    local color = self:color()

    if not frame or not color then
        return nil
    end

    -- log.df("isEnabled: creating overlay, targetting  %s", inspect(target))
    self._overlay = canvas.new(frame)
    :level(canvas.windowLevels.status + 10)
    :appendElements(
        {
            id = DOT_ID,
            type = "rectangle",
            strokeColor = self:color(),
            fillColor = self:color(),
        }
    )
    :clickActivating(false)
    :canvasMouseEvents(true, true, false, false)
    :mouseCallback(function(canvas, event, id, x, y)
        self:_onMouseEvent(event)
    end)

    return self._overlay
end

function Dot:update()
    local isActive = self:isActive()
    local overlay = self:overlay()
    if not overlay then
        return
    end

    if isActive then
        -- log.df("update: showing the overlay...")
        overlay:show()
    else
        -- log.df("update: hiding the overlay...")
        overlay:hide()
    end
end

function Dot:_onMouseEvent(event)
    -- log.df("_onMouseEvent: %s", inspect(event))
    if event == "mouseUp" then
        local prevClick = self._previousClick
        local now = secondsSinceEpoch()
        if prevClick and now - prevClick <= eventtap.doubleClickInterval() then
            self._previousClick = nil
            self.target:set(nil)
        else
            self._previousClick = now
        end
    elseif event == "mouseDown" then
        local location
        local updateTarget = deferred.new(0.01):action(function()
            self:target(location)
        end)

        self:_killMouseTracker()

        self._mouseMoveTracker = eventtap.new(
            { eventTypes.leftMouseDragged, eventTypes.leftMouseUp },
            function(e)
                if e:getType() == eventTypes.leftMouseUp and self._mouseMoveTracker then
                    self:_killMouseTracker()
                else
                    location = e:location()
                    updateTarget()
                end
            end,
            false
        ):start()
    end
end

function Dot:_killOverlay()
    if self._overlay then
        self._overlay:delete()
        self._overlay = nil
    end
end

function Dot:_killMouseTracker()
    if self._mouseMoveTracker then
        self._mouseMoveTracker:stop()
        self._mouseMoveTracker = nil
    end
end

function Dot:__gc()
    self:_killOverlay()
    self:_killMouseTracker()
end

return Dot