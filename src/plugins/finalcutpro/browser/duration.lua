--- === plugins.finalcutpro.browser.duration ===
---
--- Shortcut for changing Final Cut Pro's Browser Height

local require       = require

local timer         = require "hs.timer"
local eventtap      = require "hs.eventtap"

local fcp           = require "cp.apple.finalcutpro"

local doUntil       = timer.doUntil

local mod = {}

--- plugins.finalcutpro.browser.duration.changeBrowserDurationAlreadyInProgress -> boolean
--- Variable
--- Change timeline clip height already in progress.
mod.changeBrowserDurationAlreadyInProgress = false

-- shiftClipHeight(direction) -> boolean
-- Function
-- Shift Clip Height
--
-- Parameters:
--  * None
--
-- Returns:
--  * `true` if successful otherwise `false`.
local function shiftClipHeight(direction)
    --------------------------------------------------------------------------------
    -- Find the Timeline Appearance Button:
    --------------------------------------------------------------------------------
    local appearance = fcp.libraries.appearanceAndFiltering
    if appearance then
        appearance:show()
        if direction == "up" then
            appearance:duration():increment()
        else
            appearance:duration():decrement()
        end
        return true
    else
        return false
    end
end

-- changeBrowserDurationRelease() -> none
-- Function
-- Change Browser Clip Height Release.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function changeBrowserDurationRelease()
    mod.changeBrowserDurationAlreadyInProgress = false
    fcp.libraries.appearanceAndFiltering:hide()
end

--- plugins.finalcutpro.browser.duration.changeBrowserDuration(direction) -> none
--- Function
--- Change the Browser Clip Height
---
--- Parameters:
---  * direction - "up" or "down"
---
--- Returns:
---  * None
function mod.changeBrowserDuration(direction)
    --------------------------------------------------------------------------------
    -- Prevent multiple keypresses:
    --------------------------------------------------------------------------------
    if mod.changeBrowserDurationAlreadyInProgress then return end
    mod.changeBrowserDurationAlreadyInProgress = true

    --------------------------------------------------------------------------------
    -- Change Value of Zoom Slider:
    --------------------------------------------------------------------------------
    local result = shiftClipHeight(direction)

    --------------------------------------------------------------------------------
    -- Keep looping it until the key is released.
    --------------------------------------------------------------------------------
    if result then
        doUntil(function() return not mod.changeBrowserDurationAlreadyInProgress end, function()
            shiftClipHeight(direction)
        end, eventtap.keyRepeatInterval())
    end

end

local plugin = {
    id = "finalcutpro.browser.duration",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"]    = "fcpxCmds",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    local fcpxCmds = deps.fcpxCmds
    fcpxCmds
        :add("changeBrowserDurationUp")
        :whenActivated(function() mod.changeBrowserDuration("up") end)
        :whenReleased(function() changeBrowserDurationRelease() end)

    fcpxCmds
        :add("changeBrowserDurationDown")
        :whenActivated(function() mod.changeBrowserDuration("down") end)
        :whenReleased(function() changeBrowserDurationRelease() end)

    return mod
end

return plugin
