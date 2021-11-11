--- === plugins.finalcutpro.timeline.editnewtitle ===
---
--- Allows adding and editing titles in Final Cut Pro's timeline.

local require = require

local log               = require "hs.logger" .new "editnewtitle"

local fcp               = require "cp.apple.finalcutpro"
local i18n              = require "cp.i18n"
local tools             = require "cp.tools"

local geometry          = require "hs.geometry"

local go                = require "cp.rx.go"

local v                 = require "semver"

local playErrorSound    = tools.playErrorSound

local Do                = go.Do
local Throw             = go.Throw

local mod = {}

local skimmingBugVersion = v("10.5")

-- requireSkimmingDisabled() -> boolean
-- Function
-- Return `true` if skimming should be disabled for the current version of FCP to work around bug #2799.
--
-- Parameters:
--  * None
--
-- Returns:
--  * `true` if skimming should be disabled.
local function requireSkimmingDisabled()
    -- TODO: Determine which versions of FCP do not give access to the skimming playhead
    return fcp:version() >= skimmingBugVersion
end

local doConnectTitle = Do(fcp:doSelectMenu({"Edit", "Connect Title", 1}))
    :Label("finalcutpro.editnewtitle.doConnectTitle")

local doConnectLowerThird = Do(fcp:doSelectMenu({"Edit", "Connect Title", 2}))
    :Label("finalcutpro.editnewtitle.doConnectLowerThird")

local _doEditNewTitle
local _doEditNewLowerThird

--- plugins.finalcutpro.timeline.editnewtitle.doEditNewTitle() -> cp.rx.go.Statement
--- Function
--- Creates the new default title.
---
--- Parameters:
---  * None
--- Returns:
---  * The `Statement` that will create the new title.
function mod.doEditNewTitle()
    if not _doEditNewTitle then
        _doEditNewTitle = mod._doEditNewTitle(doConnectTitle)
    end
    return _doEditNewTitle
end

--- plugins.finalcutpro.timeline.editnewtitle.doEditNewLowerThirds() -> cp.rx.go.Statement
--- Function
--- Creates the new two-thirds title.
---
--- Parameters:
---  * None
--- Returns:
---  * The `Statement` that will create the new title.
function mod.doEditNewLowerThirds()
    if not _doEditNewLowerThird then
        _doEditNewLowerThird = mod._doEditNewTitle(doConnectLowerThird)
    end
    return _doEditNewLowerThird
end

function mod._doEditNewTitle(doConnectNewTitle)
    local contents = fcp.timeline.contents

    -- Show the timeline...
    return Do(contents:doShow())
    -- Focus on it...
    :Then(contents:doFocus())
    -- Pause the viewer...
    :Then(fcp.viewer:doPause())
    :Then(function()
        -- Save the current skimming state...
        local skimming = fcp:isSkimmingEnabled()

        -- Disable skimming if required
        if requireSkimmingDisabled() then
            fcp:isSkimmingEnabled(false)
        end

        -- Next, get the current active playhead position...
        local activePosition = contents:activePlayhead():position()
        if not activePosition then
            return Throw(i18n("doEditNewTitle_noplayhead_error"))
        end

        -- Deselect any selected clips...
        return Do(contents:doSelectNone())
        -- Create the new title clip...
        :Then(doConnectNewTitle)
        -- Select the top clip above the current playhead...
        :Then(function()
            -- Reset skimming to original state...
            if requireSkimmingDisabled() then
                fcp:isSkimmingEnabled(skimming)
            end

            -- Get the clips above the active position
            local clipsUI = contents:positionClipsUI(activePosition, true)
            if not clipsUI or #clipsUI == 0 then
                return Throw(i18n("doEditNewTitle_noclips_error"))
            end

            -- Select the top clip (should be the new title)
            local topClipUI = clipsUI[1]

            -- calculate the center of the top clip
            local frame = geometry.rect(topClipUI.AXFrame)
            local topClipCenter = frame.center

            -- ninja click the top clip
            tools.ninjaDoubleClick(topClipCenter)

            return true
        end)
    end)
    :Catch(function(err)
        playErrorSound()
        log.ef("Error editing new title: %s", err)
    end)
    :Label("finalcutpro.timeline.editnewtitle._doEditNewTitle")
end

-- create a new plugin
local plugin = {
    id             = "finalcutpro.timeline.editnewtitle",
    group          = "finalcutpro",
    dependencies   = {
        ["finalcutpro.commands"]    = "fcpxCmds",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if FCPX is supported
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Setup plugin
    --------------------------------------------------------------------------------
    local fcpxCmds = deps.fcpxCmds

    -- Add new command for doing the edit new title
    fcpxCmds:add("cpEditNewTitle")
        :whenActivated(mod.doEditNewTitle())
        :subtitled(i18n("cpEditNewTitle_subtitle"))

    -- Add new command for doing the edit new lower thirds
    fcpxCmds:add("cpEditNewLowerThirds")
        :whenActivated(mod.doEditNewLowerThirds())
        :subtitled(i18n("cpEditNewLowerThirds_subtitle"))

    --------------------------------------------------------------------------------
    -- Title Edit
    --------------------------------------------------------------------------------

    return mod
end

return plugin