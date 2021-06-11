-- === finalcutpro.viewer.overlays.Bar ===
--
-- Represents a bar on a `DraggableGuide`.

local require = require

local canvas                = require "hs.canvas"

local prop                  = require "cp.prop"

local class                 = require "middleclass"

local Bar = class("finalcutpro.viewer.overlays.Bar")

local FILLER_ID = "filler"

-- finalcutpro.viewer.overlays.Bar(frame, color, isEnabled, isActive)
-- Constructor
-- Initializes a `Bar` with the provided `frame` and `color` `cp.prop` values.
--
-- Parameters:
--  * frame: The frame for the bar.
--  * color: The `cp.drawing.color` to fill the bar with.
--  * isEnabled: If `true`, the bar will be loaded, ready to show.
--  * isActive: If `true`, the bar will be visible.
function Bar:initialize(frame, color, isEnabled, isActive)
    prop.bind(self) {
        frame = frame,
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
        if overlay then
            overlay:frame(frame)
        end
        self:update()
    end, true)

    self.color:watch(function(color)
        local overlay = self:overlay()
        if self._overlay then
            local filler = self._overlay[FILLER_ID]
            filler.fillColor = color
            filler.strokeColor = color
        end
        self:update()
    end, true)
end

function Bar:overlay()
    if self._overlay then
        return self._overlay
    end

    local frame = self:frame()
    local color = self:color()

    if not frame or not color then
        return nil
    end

    self._overlay = canvas.new(frame)
    :level(canvas.windowLevels.status + 5)
    :appendElements({
        id = FILLER_ID,
        type = "rectangle",
        strokeColor = color,
        fillColor = color,
    })

    return self._overlay
end

function Bar:update()
    local overlay = self:overlay()
    if not overlay then
        return
    end

    if self:isActive() then
        overlay:show()
    else
        overlay:hide()
    end
end

function Bar:_killOverlay()
    if self._overlay then
        self._overlay:delete()
        self._overlay = nil
    end
end

function Bar:__gc()
    self:_killOverlay()
end

return Bar