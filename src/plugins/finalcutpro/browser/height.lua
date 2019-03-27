--- === plugins.finalcutpro.browser.height ===
---
--- Shortcut for changing Final Cut Pro's Browser Height

local require = require

local timer                             = require("hs.timer")
local eventtap                          = require("hs.eventtap")

local fcp                               = require("cp.apple.finalcutpro")

local doUntil                           = timer.doUntil

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.browser.height.changeBrowserClipHeightAlreadyInProgress -> boolean
--- Variable
--- Change timeline clip height already in progress.
mod.changeBrowserClipHeightAlreadyInProgress = false

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
            appearance:clipHeight():increment()
        else
            appearance:clipHeight():decrement()
        end
        return true
    else
        return false
    end
end

-- changeBrowserClipHeightRelease() -> none
-- Function
-- Change Browser Clip Height Release.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function changeBrowserClipHeightRelease()
    mod.changeBrowserClipHeightAlreadyInProgress = false
    fcp.libraries.appearanceAndFiltering:hide()
end

--- plugins.finalcutpro.browser.height.changeBrowserClipHeight(direction) -> none
--- Function
--- Change the Browser Clip Height
---
--- Parameters:
---  * direction - "up" or "down"
---
--- Returns:
---  * None
function mod.changeBrowserClipHeight(direction)

    --------------------------------------------------------------------------------
    -- Prevent multiple keypresses:
    --------------------------------------------------------------------------------
    if mod.changeBrowserClipHeightAlreadyInProgress then return end
    mod.changeBrowserClipHeightAlreadyInProgress = true

    --------------------------------------------------------------------------------
    -- Change Value of Zoom Slider:
    --------------------------------------------------------------------------------
    local result = shiftClipHeight(direction)

    --------------------------------------------------------------------------------
    -- Keep looping it until the key is released.
    --------------------------------------------------------------------------------
    if result then
        doUntil(function() return not mod.changeBrowserClipHeightAlreadyInProgress end, function()
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
    id = "finalcutpro.browser.height",
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
        :add("changeBrowserClipHeightUp")
        :whenActivated(function() mod.changeBrowserClipHeight("up") end)
        :whenReleased(function() changeBrowserClipHeightRelease() end)

    fcpxCmds
        :add("changeBrowserClipHeightDown")
        :whenActivated(function() mod.changeBrowserClipHeight("down") end)
        :whenReleased(function() changeBrowserClipHeightRelease() end)

    return mod
end

return plugin
