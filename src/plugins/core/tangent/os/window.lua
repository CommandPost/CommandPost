--- === plugins.core.tangent.os.window ===
---
--- Window Management Tools for Tangent.

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "core.tangent.os.window",
    group = "core",
    dependencies = {
        ["core.tangent.os"] = "osGroup",
        ["finder.window"] = "win",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    local win = deps.win
    local group = deps.osGroup:group(i18n("windowManagement"))
    local id = 0x0AC00001

    --------------------------------------------------------------------------------
    -- Grid:
    --------------------------------------------------------------------------------
    group:action(id, i18n("cpShowGrid" .. "_title"))
        :onPress(win.grid)
    id = id + 1

    --------------------------------------------------------------------------------
    -- Center Cursor:
    --------------------------------------------------------------------------------
    group:action(id, i18n("cpCenterCursor" .. "_title"))
        :onPress(win.centerCursor)
    id = id + 1

    --------------------------------------------------------------------------------
    -- Hints:
    --------------------------------------------------------------------------------
    group:action(id, i18n("cpWindowHints" .. "_title"))
        :onPress(win.hints)
    id = id + 1

    --------------------------------------------------------------------------------
    -- Move Window to Screen:
    --------------------------------------------------------------------------------
    group:action(id, i18n("cpMoveWindowLeft" .. "_title"))
        :onPress(function() win.moveCurrentWindowToScreen("left") end)
    id = id + 1

    group:action(id, i18n("cpMoveWindowRight" .. "_title"))
        :onPress(function() win.moveCurrentWindowToScreen("right") end)
    id = id + 1

    group:action(id, i18n("cpMoveWindowUp" .. "_title"))
        :onPress(function() win.moveCurrentWindowToScreen("up") end)
    id = id + 1

    group:action(id, i18n("cpMoveWindowDown" .. "_title"))
        :onPress(function() win.moveCurrentWindowToScreen("down") end)
    id = id + 1

    group:action(id, i18n("cpMoveWindowNext" .. "_title"))
        :onPress(function() win.moveCurrentWindowToScreen("next") end)
    id = id + 1

    --------------------------------------------------------------------------------
    -- Move & Resize:
    --------------------------------------------------------------------------------
    group:action(id, i18n("cpMoveAndResizeHalfLeft" .. "_title"))
        :onPress(function() win.moveAndResize("halfleft") end)
    id = id + 1

    group:action(id, i18n("cpMoveAndResizeHalfRight" .. "_title"))
        :onPress(function() win.moveAndResize("halfright") end)
    id = id + 1

    group:action(id, i18n("cpMoveAndResizeHalfUp" .. "_title"))
        :onPress(function() win.moveAndResize("halfup") end)
    id = id + 1

    group:action(id, i18n("cpMoveAndResizeHalfDown" .. "_title"))
        :onPress(function() win.moveAndResize("halfdown") end)
    id = id + 1

    group:action(id, i18n("cpMoveAndResizeCornerNorthWest" .. "_title"))
        :onPress(function() win.moveAndResize("cornerNW") end)
    id = id + 1

    group:action(id, i18n("cpMoveAndResizeCornerNorthEast" .. "_title"))
        :onPress(function() win.moveAndResize("cornerNE") end)
    id = id + 1

    group:action(id, i18n("cpMoveAndResizeCornerSouthWest" .. "_title"))
        :onPress(function() win.moveAndResize("cornerSW") end)
    id = id + 1

    group:action(id, i18n("cpMoveAndResizeCornerSouthEast" .. "_title"))
        :onPress(function() win.moveAndResize("cornerSE") end)
    id = id + 1

    group:action(id, i18n("cpMoveAndResizeFullscreen" .. "_title"))
        :onPress(function() win.moveAndResize("fullscreen") end)
    id = id + 1

    group:action(id, i18n("cpMoveAndResizeCenter" .. "_title"))
        :onPress(function() win.moveAndResize("center") end)
    id = id + 1

    group:action(id, i18n("cpMoveAndResizeExpand" .. "_title"))
        :onPress(function() win.moveAndResize("expand") end)
    id = id + 1

    group:action(id, i18n("cpMoveAndResizeShrink" .. "_title"))
        :onPress(function() win.moveAndResize("shrink") end)
    id = id + 1

    group:action(id, i18n("cpMoveAndResizeUndo" .. "_title"))
        :onPress(win.undo)
    id = id + 1

    --------------------------------------------------------------------------------
    -- Step Resize:
    --------------------------------------------------------------------------------
    group:action(id, i18n("cpStepResizeLeft" .. "_title"))
        :onPress(function() win.stepResize("left") end)
    id = id + 1

    group:action(id, i18n("cpStepResizeRight" .. "_title"))
        :onPress(function() win.stepResize("right") end)
    id = id + 1

    group:action(id, i18n("cpStepResizeUp" .. "_title"))
        :onPress(function() win.stepResize("up") end)
    id = id + 1

    group:action(id, i18n("cpStepResizeDown" .. "_title"))
        :onPress(function() win.stepResize("down") end)
    id = id + 1

    --------------------------------------------------------------------------------
    -- Step Move:
    --------------------------------------------------------------------------------
    group:action(id, i18n("cpStepMoveLeft" .. "_title"))
        :onPress(function() win.stepMove("left") end)
    id = id + 1

    group:action(id, i18n("cpStepMoveRight" .. "_title"))
        :onPress(function() win.stepMove("right") end)
    id = id + 1

    group:action(id, i18n("cpStepMoveUp" .. "_title"))
        :onPress(function() win.stepMove("up") end)
    id = id + 1

    group:action(id, i18n("cpStepMoveDown" .. "_title"))
        :onPress(function() win.stepMove("down") end)

    return group
end

return plugin