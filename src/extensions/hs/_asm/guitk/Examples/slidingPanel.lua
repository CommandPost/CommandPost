-- See https://github.com/asmagill/hammerspoon-config/blob/master/_Spoons/SlidingPanels.spoon and
--     https://github.com/asmagill/hammerspoon-config/blob/master/utils/_panels/infoPanel.lua
--
-- This file will go away eventually since the links above are so much further along


--
-- Creates panels which slide from the side of the screen when specific key modifiers are held and the mouse pointer is
-- moved to the screen edge.  Each panel can have its own elements for display or user interaction.
--
-- This is expected to become part of a spoon once `hs._asm.guitk` becomes a part of core.
--

--[[ -- simple test suite:
    sp  = require("slidingPanel")
    id  = getmetatable(sp)._internalData -- for debugging
    bs  = sp.new():persistent(true):enabled(true)
    ls  = sp.new():persistent(true):size(.60):modifiers{ "cmd", "alt" }:side("left"):color{ red = 1 }:enabled(true)
    ts  = sp.new():persistent(true):modifiers{ "fn" }:side("top"):color{ green = 1 }:enabled(true)
    ts2 = sp.new():side("top"):size(250):color{ green = 1, blue = 1 }:enabled(true)
    rs  = sp.new():animationDuration(0):size(.25):side("right"):color{ blue = 1 }:enabled(true)
]]--

local module, objectMT = {}, {}
local internalData, activeSides = setmetatable({}, {__mode = "k" }), setmetatable({}, {__mode = "v" })

-- module.DEBUG_TRANSIT = true

local guitk    = require("hs._asm.guitk")
local timer    = require("hs.timer")
local canvas   = require("hs.canvas")
local drawing  = require("hs.drawing")
local screen   = require("hs.screen")
local mouse    = require("hs.mouse")
local inspect  = require("hs.inspect")
local eventtap = require("hs.eventtap")

local ANIMATION_STEPS    = 10    -- how many steps should the panel take to go from full close to full open or vice-versa
local ANIMATION_DURATION =  0.5  -- how long the panel takes to fully open or close
local HOVER_DELAY        =  1    -- how long the mouse pointer must be at the screen edge to trigger the panel
local PADDING            = 10    -- padding between panel background and display area for elements
local FILL_ALPHA         =  0.25 -- alpha for panel background color
local STROKE_ALPHA       =  0.5  -- alpha for panel border color

local USERDATA_TAG = "slidingPanel"
local VALID_SIDES = {
    top    = { horizontal = true  },
    bottom = { horizontal = true  },
    left   = { horizontal = false },
    right  = { horizontal = false },
}

local VALID_MODS = {
    cmd      = true,
    alt      = true,
    shift    = true,
    ctrl     = true,
    capslock = true,
    fn       = true,
}

-- Not a fan of allowing UTF8 chars for modifiers or strings instead of table -- gets confusing and tricky to
-- to make sure it's always valid. But if someone wants to add that later, this is where you'd do it...
--
-- For now I just verify either a list of modifier names (this code's preference) or convert key-value pairs of
-- modifier names (the original hs.hotkey preference) into the list format used in this code.
local coerceModifiers = function(input)
    local results
    if type(input) == "table" then
        results = {}
        for k, v in pairs(input) do
            local key = math.type(k) == "integer" and v or k
            if VALID_MODS[key] and v then -- v could be false if k,v pairs in table
                table.insert(results, key)
            else
                results = nil
                break
            end
        end
    end
    if results then table.sort(results) end
    return results
end

-- a simplified one line inspect used to stringify tables
local finspect = function(...)
    local args = table.pack(...)
    if args.n == 1 and type(args[1]) == "table" then
        args = args[1]
    else
        args.n = nil -- supress the count from table.pack
    end

    -- causes issues with recursive calls to __tostring in inspect
    local mt = getmetatable(args)
    if mt then setmetatable(args, nil) end
    local answer = inspect(args, { newline = " ", indent = "" })
    if mt then setmetatable(args, mt) end
    return answer
end

local timestamp = function(date)
    date = date or timer.secondsSinceEpoch()
    return os.date("%F %T" .. string.format("%-5s", ((tostring(date):match("(%.%d+)$")) or "")), math.floor(date))
end

-- only one active panel for a given side and set of modifiers allowed
local verifyUnique = function(self, side, enabled, mods)
    local isGood = true
    local modsAsString = finspect(mods)
    if enabled then
        for k,v in pairs(internalData) do
            if k ~= self and v.enabled then
                if side == v.side and modsAsString == finspect(v.mods) then
                    isGood = false
                    break
                end
            end
        end
    end
    if not isGood then
        error("enabled panel already at " .. side .. " with modifiers " .. modsAsString, 3)
    end
end

local updatePanelFrame = function(self)
    local obj = internalData[self]

    local scFrame    = screen.mainScreen():fullFrame()
    local side       = obj.side
    local horizontal = VALID_SIDES[side].horizontal
    local size       = obj.size

    -- slightly offset sensor so that corners don't trigger anything (rather than possibly 2) sine they're used by the OS anyways
    obj._sensor:frame{
        x = scFrame.x + ((side == "right")  and (scFrame.w - 1) or (horizontal and 5 or 0)),
        y = scFrame.y + ((side == "bottom") and (scFrame.h - 1) or (horizontal and 0 or 5)),
        h = horizontal and 1 or (scFrame.h - 10),
        w = horizontal and (scFrame.w - 10) or 1,
    }

    local newFrame = {
        h = horizontal and ((size > 1.0) and size or (size * scFrame.h)) or scFrame.h,
        w = horizontal and scFrame.w or ((size > 1.0) and size or (size * scFrame.w)),
    }
    newFrame.x = scFrame.x + (horizontal and 0 or ((side == "right") and scFrame.w or -newFrame.w))
    newFrame.y = scFrame.y + (horizontal and ((side == "bottom") and scFrame.h or -newFrame.h) or 0)
    obj._baseFrame = { x = newFrame.x, y = newFrame.y, h = newFrame.h, w = newFrame.w, }

    if obj._panel:isShowing() then
        local percentage = obj._panelMoveTimer and (obj._count / obj.animationSteps) or 1
        local offset     = ((size > 1.0) and size or (size * (horizontal and scFrame.h or scFrame.w))) * percentage
        newFrame.x = newFrame.x + (horizontal and 0 or ((side == "right") and -offset or offset))
        newFrame.y = newFrame.y + (horizontal and ((side == "bottom") and -offset or offset) or 0)

        local atOurSide = activeSides[side]
        if atOurSide and atOurSide ~= self then objectMT.hide(atOurSide) end
        activeSides[side] = self
    end

    obj._panel:frame(newFrame)
    obj._panel["display"].frameDetails = {
        x = obj.padding,
        y = obj.padding,
        h = newFrame.h - 2 * obj.padding,
        w = newFrame.w - 2 * obj.padding,
    }
end

local startPanelTimer = function(self)
    local obj = internalData[self]
    return timer.doEvery(obj.animationDuration / obj.animationSteps, function()
        local _status = "moveTimer"
        if obj._count == 0 and obj._targetCount == obj.animationSteps then
            _status = _status .. "; show panel"
            obj._panel:show()
        end

        obj._count = obj._count + obj._dir

        local scFrame     = screen.mainScreen():fullFrame()
        local side        = obj.side
        local horizontal  = VALID_SIDES[side].horizontal
        local size        = obj.size

        local baseFrame   = obj._baseFrame
        local percentage  = obj._count / obj.animationSteps
        local offset      = ((size > 1.0) and size or (size * (horizontal and scFrame.h or scFrame.w))) * percentage

        local newTopLeft = {
            x = baseFrame.x + (horizontal and 0 or ((side == "right") and -offset or offset)),
            y = baseFrame.y + (horizontal and ((side == "bottom") and -offset or offset) or 0),
        }
        obj._panel:topLeft(newTopLeft)
        _status = _status .. string.format("; %d @ %s", obj._count, finspect(newTopLeft))
        if obj._count == 0 and obj._targetCount == 0 then
            _status = _status .. "; hidePanel"
            obj._panel:hide()
            if activeSides[side] == self then activeSides[side] = nil end
        end
        if obj._count == obj._targetCount then
            _status = _status .. "; target reached, kill moveTimer"
            obj._panelMoveTimer:stop()
            obj._panelMoveTimer = nil
            obj._persistLock = obj.persistent and obj._count ~= 0 or nil -- coerce false into nil
            obj._targetCount, obj._dir, obj._count = nil, nil, nil
            _status = _status .. "; persistLock = " .. tostring(obj._persistLock)
        end
        if module.DEBUG_TRANSIT then print(timestamp(), _status) end
    end)
end

local sensorCallback = function(self, mgr, msg, loc)
    local obj  = internalData[self]
    local side = obj.side

    local _status = msg

    if msg == "enter" then
        if obj._persistLock then
            _status = _status .. "; break persist lock, change msg to exit"
            obj._persistLock = nil
            msg = "exit"
        else
            if activeSides[side] == self then
                _status = _status .. "; transit, change direction to open"
                obj._targetCount, obj._dir = obj.animationSteps, 1
            elseif not (activeSides[side] or obj._panelMoveTimer) then
                _status = _status .. "; checking mods"
                local cMods, mods = eventtap.checkKeyboardModifiers(), {}
                for k,v in pairs(VALID_MODS) do if cMods[k] then table.insert(mods, k) end end
                if finspect(coerceModifiers(obj.mods)) == finspect(coerceModifiers(mods)) then
                    _status = _status .. "; mods match, make active for side and start delay timer"
                    activeSides[side] = self
                    obj._panelDelayTimer = timer.doAfter(obj.hoverDelay, function()
                        if module.DEBUG_TRANSIT then print(timestamp(), "delayTimer; change direction to open; start move timer") end
                        obj._panelDelayTimer:stop()
                        obj._panelDelayTimer = nil
                        obj._count = 0
                        obj._targetCount, obj._dir = obj.animationSteps, 1
                        obj._panelMoveTimer = startPanelTimer(self)
                    end)
                end
            end
        end
    end
    if msg == "exit" then
        if obj._panelDelayTimer then
            _status = _status .. "; kill delay timer and remove from active for side"
            obj._panelDelayTimer:stop()
            obj._panelDelayTimer = nil
            if activeSides[side] == self then activeSides[side] = nil end
        elseif not obj._persistLock then
            _status = _status .. "; transit, change direction to close"
            obj._targetCount, obj._dir = 0, -1
            if obj._panel:isShowing() and not obj._panelMoveTimer then
                _status = _status .. "; start move timer"
                obj._count = obj.animationSteps
                obj._panelMoveTimer = startPanelTimer(self)
            end
        end
    end
    if module.DEBUG_TRANSIT then print(timestamp(), _status) end
end

-- not sure if we're going to need to do something special when the active screen changes or
-- not, but capture this change as well and we'll see...
local screenWatcher = screen.watcher.newWithActiveScreen(function(active)
    for self, v in pairs(internalData) do updatePanelFrame(self) end
end):start()

-- pass through to display manager since that will be what is wanted if the key doesn't refer to a sliderPanel method
objectMT.__index    = function(self, key)        return objectMT[key] or internalData[self]._display[key] end
objectMT.__call     = function(self, ...)        return internalData[self]._display(key, ...) end
objectMT.__len      = function(self)             return #internalData[self]._display end
objectMT.__newindex = function(self, key, value) internalData[self]._display[key] = value end
objectMT.__pairs    = function(self)
    local fn, _, initial = pairs(internalData[self]._display)
    -- properly we should return *our* self, not the one returned by pairs, but I'm not sure it
    -- really matters, and while initial should always be nil, lets be pedantic just in case
    return fn, self, initial
end

objectMT.__gc = function(self)
    local obj = internalData[self]
    if obj then
        if obj._panelMoveTimer then
            obj._panelMoveTimer:stop()
            obj._panelMoveTimer = nil
        end
        if obj._panelDelayTimer then
            obj._panelDelayTimer:stop()
            obj._panelDelayTimer = nil
        end
        if obj._sensor then
            obj._sensor:delete() -- passes up to the sensor window
            obj._sensor = nil
        end
        if obj._panel then
            local cv = obj._panel("background")
            obj._panel:elementRemoveFromManager(cv)
            -- this step of deleting the canvas we created is necessary because canvas isn't a "true" guitk element
            -- yet and it has it's own requirement of explicit delete for true garbage collection
            cv:delete()
            -- we don't bother with the potential canvas elements in "display" since this code didn't create them --
            -- it only "borrowed" them from stuff the user added; it's up to the user to handle cleanup if they care
            -- about memory that closely; eventually canvas should become a proper element of guitk and the distinction
            -- will no longer matter then.
            obj._display = nil
            obj._panel:delete() -- passes up to the panel window
            obj._panel = nil
        end
    end
    obj = nil
end

objectMT.__tostring = function(self)
    local obj = internalData[self]
    return string.format("%s: %s @ %s with %s",
        USERDATA_TAG,
        (obj.enabled and "enabled" or "disabled"),
        obj.side,
        finspect(obj.mods)
    )
end

objectMT.color = function(self, ...)
    local obj, args = internalData[self], table.pack(...)
    local backPanel = obj._panel("background")["backPanel"]
    if args.n == 0 then
        return setmetatable({
            red   = backPanel.fillColor.red,
            green = backPanel.fillColor.green,
            blue  = backPanel.fillColor.blue,
        }, { __tostring = finspect })
    elseif args.n == 1 and type(args[1]) == "table" then
        local col = drawing.color.asRGB(args[1])
        backPanel.fillColor = {
            red   = col.red,
            green = col.green,
            blue  = col.blue,
            alpha = obj.fillAlpha,
        }
        backPanel.strokeColor = {
            red   = col.red,
            green = col.green,
            blue  = col.blue,
            alpha = obj.strokeAlpha,
        }
-- doesn't matter if it's in transition or visible, so don't bother with update
--         updatePanelFrame(self)
        return self
    end
    error("expected optional color table", 2)
end

objectMT.modifiers = function(self, ...)
    local obj, args = internalData[self], table.pack(...)
    if args.n == 0 then
        return setmetatable(obj.mods, { __tostring = finspect })
    elseif args.n == 1 then
        local mods = coerceModifiers(args[1])
        if mods then
            verifyUnique(self, obj.side, obj.enabled, mods)
            obj.mods = mods
-- doesn't matter if it's in transition or visible, so don't bother with update
--             updatePanelFrame(self)
            return self
        end
    end
    local mods = {}
    for k,v in pairs(VALID_MODS) do table.insert(mods, k) end
    error("expected optional table with zero or more strings equal to " .. table.concat(mods), 2)
end

objectMT.enabled = function(self, ...)
    local obj, args = internalData[self], table.pack(...)
    if args.n == 0 then
        return obj.enabled
    elseif args.n == 1 and type(args[1]) == "boolean" then
        if obj.enabled ~= args[1] then -- is this actually a change?
            verifyUnique(self, obj.side, args[1], obj.mods)
            obj.enabled = args[1]
            if obj.enabled then
                obj._sensor:show()
            else
                if obj._panelMoveTimer then
                    obj._panelMoveTimer:stop()
                    obj._panelMoveTimer = nil
                end
                obj._targetCount, obj._dir, obj._persistLock, obj._count = nil, nil, nil, nil
                if activeSides[obj.side] == self then activeSides[obj.side] = nil end
                obj._panel:hide()
                obj._sensor:hide()
            end
            updatePanelFrame(self)
        end
-- we've already enabled/disabled everything, so don't bother with update
--         updatePanelFrame(self)
        return self
    end
    error("expected optional boolean", 2)
end

objectMT.side = function(self, ...)
    local obj, args = internalData[self], table.pack(...)
    if args.n == 0 then
        return obj.side
    elseif args.n == 1 and VALID_SIDES[args[1]] then
        verifyUnique(self, args[1], obj.enabled, obj.mods)
        obj.side = args[1]
        updatePanelFrame(self)
        return self
    end
    local sides = {}
    for k,v in pairs(VALID_SIDES) do table.insert(sides, k) end
    error("expected optional string equal to one of " .. table.concat(sides, ", "), 2)
end

-- if <= 1.0, treat as percentage; otherwise explicit size
objectMT.size = function(self, ...)
    local obj, args = internalData[self], table.pack(...)
    if args.n == 0 then
        return obj.size
    elseif args.n == 1 and type(args[1]) == "number" and args[1] > 0.0 then
        obj.size = args[1]
        updatePanelFrame(self)
        return self
    end
    error("expected optional number greater than 0.0", 2)
end

objectMT.persistent = function(self, ...)
    local obj, args = internalData[self], table.pack(...)
    if args.n == 0 then
        return obj.persistent
    elseif args.n == 1 and type(args[1]) == "boolean" then
        obj.persistent = args[1]
        obj._persistLock = obj.persistent and obj._panel:isShowing() and not obj._panelMoveTimer or nil -- coerce to nil
        return self
    end
    error("expected optional boolean", 2)
end

objectMT.animationSteps = function(self, ...)
    local obj, args = internalData[self], table.pack(...)
    if args.n == 0 then
        return obj.animationSteps
    elseif args.n == 1 and math.type(args[1]) == "integer" then
        obj.animationSteps = math.max(1, args[1])
        if obj._dir then
            obj._targetCount = (obj._dir > 0) and obj.animationSteps or 0
            if obj._count then
                obj._count = (obj._dir > 0) and 0 or obj.animationSteps
            end
        end
        return self
    end
    error("expected optional integer greater than or equal to 1", 2)
end

objectMT.animationDuration = function(self, ...)
    local obj, args = internalData[self], table.pack(...)
    if args.n == 0 then
        return obj.animationDuration
    elseif args.n == 1 and type(args[1]) == "number" then
        obj.animationDuration = math.max(0.0, args[1])
        if (obj.animationDuration / obj.animationSteps) < 1e-09 then self:animationSteps(1) end
        return self
    end
    error("expected optional number greater than or equal to 0.0", 2)
end

objectMT.hoverDelay = function(self, ...)
    local obj, args = internalData[self], table.pack(...)
    if args.n == 0 then
        return obj.hoverDelay
    elseif args.n == 1 and type(args[1]) == "number" then
        obj.hoverDelay = math.max(0.0, args[1])
        return self
    end
    error("expected optional number greater than or equal to 0.0", 2)
end

objectMT.padding = function(self, ...)
    local obj, args = internalData[self], table.pack(...)
    if args.n == 0 then
        return obj.padding
    elseif args.n == 1 and type(args[1]) == "number" then
        obj.padding = math.max(0.0, args[1])
        updatePanelFrame(self)
        return self
    end
    error("expected optional number greater than or equal to 0.0", 2)
end

objectMT.strokeAlpha = function(self, ...)
    local obj, args = internalData[self], table.pack(...)
    if args.n == 0 then
        return obj.strokeAlpha
    elseif args.n == 1 and type(args[1]) == "number" then
        obj.strokeAlpha = math.min(1.0, math.max(0.0, args[1]))
        self:color(self:color())
        return self
    end
    error("expected optional number between 0.0 and 1.0 inclusive", 2)
end

objectMT.fillAlpha = function(self, ...)
    local obj, args = internalData[self], table.pack(...)
    if args.n == 0 then
        return obj.fillAlpha
    elseif args.n == 1 and type(args[1]) == "number" then
        obj.fillAlpha = math.min(1.0, math.max(0.0, args[1]))
        self:color(self:color())
        return self
    end
    error("expected optional number between 0.0 and 1.0 inclusive", 2)
end

objectMT.show = function(self)
    local obj = internalData[self]
    local atOurSide = activeSides[obj.side]
    if atOurSide and atOurSide ~= self then objectMT.hide(atOurSide) end
    obj._persistLock = true
    obj._targetCount, obj._dir = obj.animationSteps, 1
    if atOurSide ~= self then
        activeSides[obj.side] = self
        obj._count = 0
        if obj._panelDelayTimer then
            obj._panelDelayTimer:stop()
            obj._panelDelayTimer = nil
        end
        if not obj._panelMoveTimer then obj._panelMoveTimer = startPanelTimer(self) end
    end
    return self
end

objectMT.hide = function(self)
    local obj = internalData[self]
    obj._persistLock = nil
    sensorCallback(self, obj._sensor, "exit", {})
    return self
end

-- objectMT.elements

module.new = function()
    local self = setmetatable({}, objectMT)
    internalData[self] = {
        side              = "bottom",
        size              = .5,
        mods              = {},
        enabled           = false,
        persistent        = false,

        animationSteps    = ANIMATION_STEPS,
        animationDuration = ANIMATION_DURATION,
        hoverDelay        = HOVER_DELAY,
        padding           = PADDING,
        fillAlpha         = FILL_ALPHA,
        strokeAlpha       = STROKE_ALPHA,
    }

    local obj = internalData[self]
    obj._panel  = guitk.newCanvas{}:level("status")
                                   :ignoresMouseEvents(false)
                                   :contentManager(guitk.manager.new())
    obj._sensor = guitk.newCanvas{}:level("status")
                                   :collectionBehavior("canJoinAllSpaces")
                                   :contentManager(guitk.manager.new():mouseCallback(function(mgr, msg, loc)
                                       sensorCallback(self, mgr, msg, loc)
                                   end))
    -- by keeping them at different levels, the movement of the panel doesn't cause sensor to lose its position as
    -- the receiver of mouse enter/exit messages during panel deployment. Could also set ignoresMouseEvents true on the
    -- panel, but this defats the ability to allow user to interact with panel when it's persistent
    obj._sensor:level(obj._sensor:level() + 1)

    -- since we access the content managers more often then the windows, save the manager object instead;
    -- it makes for clearer code IMHO. We can always get the window if we need it with :_nextResponder()
    obj._panel, obj._sensor = obj._panel:contentManager(), obj._sensor:contentManager()

    obj._panel[#obj._panel + 1] = {
        _element     = canvas.new{}:assignElement{
                         type             = "rectangle",
                         id               = "backPanel",
                         strokeWidth      = 10,
                         fillColor        = { alpha = obj.fillAlpha },
                         strokeColor      = { alpha = obj.strokeAlpha },
                         roundedRectRadii = { xRadius = 10, yRadius = 10 },
                         clipToPath       = true,
                     },
        id           = "background",
        frameDetails = { x = 0, y = 0, h = "100%", w = "100%" },
    }

    obj._display = guitk.manager.new()
    obj._panel[#obj._panel + 1] = {
        _element     = obj._display,
        id           = "display",
        frameDetails = { h = "100%", w = "100%" }, -- placeholder, gets set in updatePanelFrame()
    }

    updatePanelFrame(self)

    return self
end

return setmetatable(module, {
    __gc = function(self)
        screenWatcher:stop()
        screenWatcher = nil
        setmetatable()
    end,

    -- referencing here persists local data that we don't want going away that isn't otherwise referenced as an
    -- up-value (e.g. internalData doesn't *need* to be here) and because it makes it reasonably easy to get at
    -- for debugging purposes without actually putting it into the module as keys directly
    -- (e.g. getmetatable(module)._internalData)
    _internalData  = internalData,
    _screenWatcher = screenWatcher,
    _activeSides   = activeSides,
})
