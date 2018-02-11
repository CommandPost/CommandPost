--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                      T I M E L I N E     H E I G H T                       --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.timeline.height ===
---
--- Shortcut for changing Final Cut Pro's Timeline Height

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local timer                             = require("hs.timer")
local eventtap                          = require("hs.eventtap")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local fcp                               = require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.timeline.height.changeTimelineClipHeightAlreadyInProgress -> boolean
--- Variable
--- Change timeline clip height already in progress.
mod.changeTimelineClipHeightAlreadyInProgress = false

--- plugins.finalcutpro.timeline.height.shiftClipHeight(direction) -> boolean
--- Function
--- Shift Clip Height
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if successful otherwise `false`.
local function shiftClipHeight(direction)
    --------------------------------------------------------------------------------
    -- Find the Timeline Appearance Button:
    --------------------------------------------------------------------------------
    local appearance = fcp:timeline():toolbar():appearance()
    if appearance then
        appearance:show()
        if direction == "up" then
            appearance:clipHeight():increment()
        else
            appearance:clipHeight():decrement()
        end
        return true
    else
        return false
    end
end

--- plugins.finalcutpro.timeline.height.changeTimelineClipHeightRelease() -> none
--- Function
--- Change Timeline Clip Height Release.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
local function changeTimelineClipHeightRelease()
    mod.changeTimelineClipHeightAlreadyInProgress = false
    fcp:timeline():toolbar():appearance():hide()
end

--- plugins.finalcutpro.timeline.height.changeTimelineClipHeight(direction) -> none
--- Function
--- Change the Timeline Clip Height
---
--- Parameters:
---  * direction - "up" or "down"
---
--- Returns:
---  * None
function mod.changeTimelineClipHeight(direction)

    --------------------------------------------------------------------------------
    -- Prevent multiple keypresses:
    --------------------------------------------------------------------------------
    if mod.changeTimelineClipHeightAlreadyInProgress then return end
    mod.changeTimelineClipHeightAlreadyInProgress = true

    --------------------------------------------------------------------------------
    -- Change Value of Zoom Slider:
    --------------------------------------------------------------------------------
    local result = shiftClipHeight(direction)

    --------------------------------------------------------------------------------
    -- Keep looping it until the key is released.
    --------------------------------------------------------------------------------
    if result then
        timer.doUntil(function() return not mod.changeTimelineClipHeightAlreadyInProgress end, function()
            shiftClipHeight(direction)
        end, eventtap.keyRepeatInterval())
    end

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.timeline.height",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"]    = "fcpxCmds",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    if deps.fcpxCmds then
        deps.fcpxCmds:add("cpChangeTimelineClipHeightUp")
            :whenActivated(function() mod.changeTimelineClipHeight("up") end)
            :whenReleased(function() changeTimelineClipHeightRelease() end)
            :activatedBy():ctrl():option():cmd("=")

        deps.fcpxCmds:add("cpChangeTimelineClipHeightDown")
            :whenActivated(function() mod.changeTimelineClipHeight("down") end)
            :whenReleased(function() changeTimelineClipHeightRelease() end)
            :activatedBy():ctrl():option():cmd("-")
    end
    return mod
end

return plugin