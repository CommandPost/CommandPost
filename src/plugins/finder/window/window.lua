--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                           C O M M A N D P O S T                            --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finder.window ===
---
--- Handy tools for Windows Management in macOS.
---
--- Inspired by [WinWin](http://www.hammerspoon.org/Spoons/WinWin.html) for [Hammerspoon](http://www.hammerspoon.org/).

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local grid                  = require("hs.grid")
local hints                 = require("hs.hints")
local mouse                 = require("hs.mouse")
local window                = require("hs.window")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finder.window.grid() -> nil
--- Function
--- Shows a modal keyboard driven interface for interactive window resizing.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.grid()
    grid.show()
end

--- plugins.finder.window.hints() -> nil
--- Function
--- Displays a keyboard hint for switching focus to each window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.hints()
    hints.windowHints()
end

--- plugins.finder.window.centerCursor() -> nil
--- Function
--- Center the cursor on the focused window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.centerCursor()
    local focusedWindow                 = window.focusedWindow()
    local focusedWindowFrame            = focusedWindow:frame()
    local focusedWindowScreen           = focusedWindow:screen()
    local focusedWindowScreenFullFrame  = focusedWindowScreen:fullFrame()
    if focusedWindow then
        --------------------------------------------------------------------------------
        -- Center the cursor one the focused window:
        --------------------------------------------------------------------------------
        mouse.setAbsolutePosition({x=focusedWindowFrame.x+focusedWindowFrame.w/2, y=focusedWindowFrame.y+focusedWindowFrame.h/2})
    else
        --------------------------------------------------------------------------------
        -- Center the cursor on the screen:
        --------------------------------------------------------------------------------
        mouse.setAbsolutePosition({x=focusedWindowScreenFullFrame.x+focusedWindowScreenFullFrame.w/2, y=focusedWindowScreenFullFrame.y+focusedWindowScreenFullFrame.h/2})
    end
end

-- Windows manipulation history. Only the last operation is stored.
mod.history = {}

--- plugins.finder.window.gridparts
--- Variable
--- An integer specifying how many gridparts the screen should be divided into. Defaults to 30.
mod.gridParts = 30

--- plugins.finder.window.stepMove(direction)
--- Function
--- Move the focused window in the `direction` by one step. The step scale equals to the width/height of one gridpart.
---
--- Parameters:
---  * direction - A string specifying the direction, valid strings are: `left`, `right`, `up`, `down`.
---
--- Returns:
---  * None
function mod.stepMove(direction)
    local cwin = window.focusedWindow()
    if cwin then
        local cscreen = cwin:screen()
        local cres = cscreen:fullFrame()
        local stepw = cres.w/mod.gridParts
        local steph = cres.h/mod.gridParts
        local wtopleft = cwin:topLeft()
        if direction == "left" then
            cwin:setTopLeft({x=wtopleft.x-stepw, y=wtopleft.y})
        elseif direction == "right" then
            cwin:setTopLeft({x=wtopleft.x+stepw, y=wtopleft.y})
        elseif direction == "up" then
            cwin:setTopLeft({x=wtopleft.x, y=wtopleft.y-steph})
        elseif direction == "down" then
            cwin:setTopLeft({x=wtopleft.x, y=wtopleft.y+steph})
        end
    end
end

--- plugins.finder.window.undo()
--- Function
--- Undo the last window manipulation. Only those "moveAndResize" manipulations can be undone.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.undo()
    local cwin = window.focusedWindow()
    local cwinid = cwin:id()
    for _,val in ipairs(mod.history) do
        --------------------------------------------------------------------------------
        -- Has this window been stored previously?
        --------------------------------------------------------------------------------
        if val[1] == cwinid then
            cwin:setFrame(val[2])
        end
    end
end

--- plugins.finder.window.stepResize(direction)
--- Function
--- Resize the focused window in the `direction` by on step.
---
--- Parameters:
---  * direction - A string specifying the direction, valid strings are: `left`, `right`, `up`, `down`.
---
--- Returns:
---  * None
function mod.stepResize(direction)
    local cwin = window.focusedWindow()
    if cwin then
        local cscreen = cwin:screen()
        local cres = cscreen:fullFrame()
        local stepw = cres.w/mod.gridParts
        local steph = cres.h/mod.gridParts
        local wsize = cwin:size()
        if direction == "left" then
            cwin:setSize({w=wsize.w-stepw, h=wsize.h})
        elseif direction == "right" then
            cwin:setSize({w=wsize.w+stepw, h=wsize.h})
        elseif direction == "up" then
            cwin:setSize({w=wsize.w, h=wsize.h-steph})
        elseif direction == "down" then
            cwin:setSize({w=wsize.w, h=wsize.h+steph})
        end
    end
end

-- windowStash(theWindow)
-- Function
-- Saves the window in history.
--
-- Parameters:
--  * theWindow - The window to save.
--
-- Returns:
--  * None
local function windowStash(theWindow)
    local windowID = theWindow:id()
    local windowFrame = theWindow:frame()
    if #mod.history > 50 then
        --------------------------------------------------------------------------------
        -- Make sure the history doesn't reach the maximum (50 items).
        --------------------------------------------------------------------------------
        table.remove(mod.history) -- Remove the last item
    end
    local result = {windowID, windowFrame}
    --------------------------------------------------------------------------------
    -- Insert new item of window history:
    --------------------------------------------------------------------------------
    table.insert(mod.history, result)
end

--- plugins.finder.window.moveAndResize(option)
--- Function
--- Move and resize the focused window.
---
--- Parameters:
---  * option - A string specifying the option, valid strings are: `halfleft`, `halfright`, `halfup`, `halfdown`, `cornerNW`, `cornerSW`, `cornerNE`, `cornerSE`, `center`, `fullscreen`, `expand`, `shrink`.
---
--- Returns:
---  * None
function mod.moveAndResize(option)
    local focusedWindow = window.focusedWindow()
    if focusedWindow then
        local cscreen = focusedWindow:screen()
        local cres = cscreen:fullFrame()
        local stepw = cres.w/mod.gridParts
        local steph = cres.h/mod.gridParts
        local wf = focusedWindow:frame()
        if option == "halfleft" then
            windowStash(focusedWindow)
            focusedWindow:setFrame({x=cres.x, y=cres.y, w=cres.w/2, h=cres.h})
        elseif option == "halfright" then
            windowStash(focusedWindow)
            focusedWindow:setFrame({x=cres.x+cres.w/2, y=cres.y, w=cres.w/2, h=cres.h})
        elseif option == "halfup" then
            windowStash(focusedWindow)
            focusedWindow:setFrame({x=cres.x, y=cres.y, w=cres.w, h=cres.h/2})
        elseif option == "halfdown" then
            windowStash(focusedWindow)
            focusedWindow:setFrame({x=cres.x, y=cres.y+cres.h/2, w=cres.w, h=cres.h/2})
        elseif option == "cornerNW" then
            windowStash(focusedWindow)
            focusedWindow:setFrame({x=cres.x, y=cres.y, w=cres.w/2, h=cres.h/2})
        elseif option == "cornerNE" then
            windowStash(focusedWindow)
            focusedWindow:setFrame({x=cres.x+cres.w/2, y=cres.y, w=cres.w/2, h=cres.h/2})
        elseif option == "cornerSW" then
            windowStash(focusedWindow)
            focusedWindow:setFrame({x=cres.x, y=cres.y+cres.h/2, w=cres.w/2, h=cres.h/2})
        elseif option == "cornerSE" then
            windowStash(focusedWindow)
            focusedWindow:setFrame({x=cres.x+cres.w/2, y=cres.y+cres.h/2, w=cres.w/2, h=cres.h/2})
        elseif option == "fullscreen" then
            windowStash(focusedWindow)
            focusedWindow:setFrame({x=cres.x, y=cres.y, w=cres.w, h=cres.h})
        elseif option == "center" then
            windowStash(focusedWindow)
            focusedWindow:centerOnScreen()
        elseif option == "expand" then
            focusedWindow:setFrame({x=wf.x-stepw, y=wf.y-steph, w=wf.w+(stepw*2), h=wf.h+(steph*2)})
        elseif option == "shrink" then
            focusedWindow:setFrame({x=wf.x+stepw, y=wf.y+steph, w=wf.w-(stepw*2), h=wf.h-(steph*2)})
        end
    end
end

--- plugins.finder.window.moveToScreen(direction)
--- Function
--- Move the focused window between all of the screens in the `direction`.
---
--- Parameters:
---  * direction - A string specifying the direction, valid strings are: `left`, `right`, `up`, `down`, `next`.
---
--- Returns:
---  * None
function mod.moveCurrentWindowToScreen(value)
    local focusedWindow = window.focusedWindow()
    if focusedWindow then
        if value == "up" then
            focusedWindow:moveOneScreenNorth()
        elseif value == "down" then
            focusedWindow:moveOneScreenSouth()
        elseif value == "left" then
            focusedWindow:moveOneScreenWest()
        elseif value == "right" then
            focusedWindow:moveOneScreenEast()
        elseif value == "next" then
            local currentScreen = focusedWindow:screen()
            focusedWindow:moveToScreen(currentScreen:next())
        end
    end
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finder.window",
    group           = "finder",
    dependencies    = {
        ["core.commands.global"]                    = "global",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Commands:
    --------------------------------------------------------------------------------
    local global = deps.global
    if global then
        --------------------------------------------------------------------------------
        -- Grid:
        --------------------------------------------------------------------------------
        global:add("cpShowGrid")
            :whenActivated(mod.grid)

        --------------------------------------------------------------------------------
        -- Center Cursor:
        --------------------------------------------------------------------------------
        global:add("cpCenterCursor")
            :whenActivated(mod.centerCursor)

        --------------------------------------------------------------------------------
        -- Hints:
        --------------------------------------------------------------------------------
        global:add("cpWindowHints")
            :whenActivated(mod.hints)

        --------------------------------------------------------------------------------
        -- Move Window to Screen:
        --------------------------------------------------------------------------------
        global:add("cpMoveWindowLeft")
            :whenActivated(function() mod.moveCurrentWindowToScreen("left") end)

        global:add("cpMoveWindowRight")
            :whenActivated(function() mod.moveCurrentWindowToScreen("right") end)

        global:add("cpMoveWindowUp")
            :whenActivated(function() mod.moveCurrentWindowToScreen("up") end)

        global:add("cpMoveWindowDown")
            :whenActivated(function() mod.moveCurrentWindowToScreen("down") end)

        global:add("cpMoveWindowNext")
            :whenActivated(function() mod.moveCurrentWindowToScreen("next") end)

        --------------------------------------------------------------------------------
        -- Move & Resize:
        --------------------------------------------------------------------------------
        global:add("cpMoveAndResizeHalfLeft")
            :whenActivated(function() mod.moveAndResize("halfleft") end)

        global:add("cpMoveAndResizeHalfRight")
            :whenActivated(function() mod.moveAndResize("halfright") end)

        global:add("cpMoveAndResizeHalfUp")
            :whenActivated(function() mod.moveAndResize("halfup") end)

        global:add("cpMoveAndResizeHalfDown")
            :whenActivated(function() mod.moveAndResize("halfdown") end)

        global:add("cpMoveAndResizeCornerNorthWest")
            :whenActivated(function() mod.moveAndResize("cornerNW") end)

        global:add("cpMoveAndResizeCornerNorthEast")
            :whenActivated(function() mod.moveAndResize("cornerNE") end)

        global:add("cpMoveAndResizeCornerSouthWest")
            :whenActivated(function() mod.moveAndResize("cornerSW") end)

        global:add("cpMoveAndResizeCornerSouthEast")
            :whenActivated(function() mod.moveAndResize("cornerSE") end)

        global:add("cpMoveAndResizeFullscreen")
            :whenActivated(function() mod.moveAndResize("fullscreen") end)

        global:add("cpMoveAndResizeCenter")
            :whenActivated(function() mod.moveAndResize("center") end)

        global:add("cpMoveAndResizeExpand")
            :whenActivated(function() mod.moveAndResize("expand") end)

        global:add("cpMoveAndResizeShrink")
            :whenActivated(function() mod.moveAndResize("shrink") end)

        global:add("cpMoveAndResizeUndo")
            :whenActivated(mod.undo)

        --------------------------------------------------------------------------------
        -- Step Resize:
        --------------------------------------------------------------------------------
        global:add("cpStepResizeLeft")
            :whenActivated(function() mod.stepResize("left") end)

        global:add("cpStepResizeRight")
            :whenActivated(function() mod.stepResize("right") end)

        global:add("cpStepResizeUp")
            :whenActivated(function() mod.stepResize("up") end)

        global:add("cpStepResizeDown")
            :whenActivated(function() mod.stepResize("down") end)

        --------------------------------------------------------------------------------
        -- Step Move:
        --------------------------------------------------------------------------------
        global:add("cpStepMoveLeft")
            :whenActivated(function() mod.stepMove("left") end)

        global:add("cpStepMoveRight")
            :whenActivated(function() mod.stepMove("right") end)

        global:add("cpStepMoveUp")
            :whenActivated(function() mod.stepMove("up") end)

        global:add("cpStepMoveDown")
            :whenActivated(function() mod.stepMove("down") end)
    end
    return mod
end

return plugin