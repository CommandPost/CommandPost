--- === plugins.finalcutpro.timeline.playhead ===
---
--- Manages features relating to the Timeline Playhead.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
--local log                       = require("hs.logger").new("scrolling")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local dialog                    = require("cp.dialog")
local fcp                       = require("cp.apple.finalcutpro")
local config                    = require("cp.config")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- PRIORITY -> number
-- Constant
-- The menubar position priority.
local PRIORITY = 1000

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.timeline.playhead.scrollingTimeline <cp.prop: boolean>
--- Variable
--- Enables or disables the scrolling timeline.
mod.scrollingTimeline = config.prop("scrollingTimelineActive", false):watch(function(active)
    if active then
        --------------------------------------------------------------------------------
        -- Ensure that Playhead Lock is off:
        --------------------------------------------------------------------------------
        local message = ""
        if mod.playheadLocked() then
            mod.playheadLocked(false)
            message = i18n("playheadLockDeactivated") .. "\n"
        end
        --------------------------------------------------------------------------------
        -- Display Notification:
        --------------------------------------------------------------------------------
        dialog.displayNotification(message..i18n("scrollingTimelineActivated"))
    elseif not mod.playheadLocked() then
        dialog.displayNotification(i18n("scrollingTimelineDeactivated"))
    end
    mod.update()
end)

--- plugins.finalcutpro.timeline.playhead.playheadLocked <cp.prop: boolean>
--- Variable
--- Playhead Locked?
mod.playheadLocked = config.prop("lockTimelinePlayhead", false):watch(function(active)
    if active then
        --------------------------------------------------------------------------------
        -- Ensure that Scrolling Timeline is off:
        --------------------------------------------------------------------------------
        local message = ""
        if mod.scrollingTimeline() then
            mod.scrollingTimeline(false)
            message = i18n("scrollingTimelineDeactivated") .. "\n"
        end
        --------------------------------------------------------------------------------
        -- Display Notification:
        --------------------------------------------------------------------------------
        dialog.displayNotification(message .. i18n("playheadLockActivated"))
    elseif not mod.scrollingTimeline() then
        dialog.displayNotification(i18n("playheadLockDeactivated"))
    end
    mod.update()
end)

--- plugins.finalcutpro.timeline.playhead.update() -> none
--- Function
--- Ensures the Scrolling Timeline/Playhead Lock are in the correct mode
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.update()
    local timeline = fcp:timeline()
    local scrolling = mod.scrollingTimeline()
    local locked = mod.playheadLocked()
    if scrolling or locked then
        timeline:lockInCentre(locked)
        timeline:lockPlayhead()
    else
        timeline:unlockPlayhead()
    end
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.timeline.playhead",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.menu.timeline"]               = "options",
        ["finalcutpro.commands"]                    = "fcpxCmds",
        ["finalcutpro.preferences.app"]             = "prefs",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Setup Menu:
    --------------------------------------------------------------------------------
    if deps.options then
        local section = deps.options:addSection(PRIORITY)
        section:addItems(1000, function()
            return {
                { title = i18n("enableScrollingTimeline"),      fn = function() mod.scrollingTimeline:toggle() end,     checked = mod.scrollingTimeline() },
                { title = i18n("enableTimelinePlayheadLock"),   fn = function() mod.playheadLocked:toggle() end,        checked = mod.playheadLocked() },
            }
        end)
    end

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    if deps.fcpxCmds then
        deps.fcpxCmds:add("cpScrollingTimeline")
            :groupedBy("timeline")
            :activatedBy():ctrl():option():cmd("w")
            :whenActivated(function() mod.scrollingTimeline:toggle() end)
        deps.fcpxCmds:add("cpLockPlayhead")
            :groupedBy("timeline")
            :whenActivated(function() mod.playheadLocked:toggle() end)
    end

    --------------------------------------------------------------------------------
    -- Update Scrolling Timeline:
    --------------------------------------------------------------------------------
    mod.update()

    return mod
end

return plugin
