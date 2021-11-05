-- imports
local require = require

local log               = require "hs.logger" .new "editnewtitle"

local fcp               = require "cp.apple.finalcutpro"
local i18n              = require "cp.i18n"
local tools             = require "cp.tools"
local axutils           = require "cp.ui.axutils"

local geometry          = require "hs.geometry"

local go                = require "cp.rx.go"

local playErrorSound    = tools.playErrorSound

local Do                = go.Do
local Throw             = go.Throw
local WaitUntil         = go.WaitUntil
local toObservable      = go.Statement.toObservable

local exactly           = axutils.match.exactly

-- local mod
local mod = {}

--- finalcutpro.timeline.editnewtitle.doSelectTopClip(position) -> cp.rx.go.Statement
--- Function
--- Creates a [Statement](cp.rx.go.Statement.md) that will select the top clip at the given position, 
--- resolving to the top clip if available.
---
--- Parameters:
---  * position - The position `table` to select the top clip at.
---
--- Returns:
---  * The [Statement](cp.rx.go.Statement)
function mod.doSelectTopClip(position)
    local contents = fcp.timeline.contents

    return Do(function()
        position = position or fcp.timeline:activePlayhead():position()

        local clipsUI = contents:positionClipsUI(position)
        if not clipsUI or #clipsUI == 0 then
            return Throw(i18n("doSelectTopClip_noclips_error"))
        end

        local topClip = axutils.childFromTop(clipsUI, 1)
        return Do(contents:doSelectClip(topClip))
        :Then(
            WaitUntil(function() return contents:selectedClipsUI() end)
            :Matches(exactly({topClip}))
            :TimeoutAfter(2000)
        )
        :Then(toObservable(topClip))
    end)
    :Label("finalcutpro.editnewtitle.doSelectTopClip")
end

local doConnectTitle = Do(fcp:doSelectMenu({"Edit", "Connect Title", 1}))
    :Label("finalcutpro.editnewtitle.doConnectTitle")

local doConnectLowerThird = Do(fcp:doSelectMenu({"Edit", "Connect Title", 2}))
    :Label("finalcutpro.editnewtitle.doConnectLowerThird")

local _doEditNewTitle
local _doEditNewLowerThird

--- finalcutpro.timeline.editnewtitle.doEditNewTitle() -> cp.rx.go.Statement
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

--- finalcutpro.timeline.editnewtitle.doEditNewLowerThirds() -> cp.rx.go.Statement
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
    local timeline = fcp.timeline
    local contents = timeline.contents

    -- Show the timeline...
    return Do(timeline:doShow())
    -- Focus on it...
    :Then(timeline:doFocus())
    :Then(function()
        -- Next, get the current active playhead position...
        local activePosition = timeline:activePlayhead():position()
        if not activePosition then
            return Throw(i18n("doEditNewTitle_noplayhead_error"))
        end

        -- Deselect any selected clips...
        return Do(contents:doSelectNone())
        -- Create the new title clip...
        :Then(doConnectNewTitle)
        -- Select the top clip above the current playhead...
        :Then(function()
            -- Get the clips above the active position
            local clipsUI = contents:positionClipsUI(activePosition, true)
            if not clipsUI or #clipsUI == 0 then
                return Throw(i18n("doEditNewTitle_noclips_error"))
            end

            -- Select the top clip (should be the new title)
            local topClipUI = axutils.childFromTop(clipsUI, 1)
            if not topClipUI then
                return Throw("Could not find top clip.")
            end

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
    :Label("editnewtitle._doEditNewTitle")
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

    fcpxCmds:add("cpEditNewTitle")
        :whenActivated(mod.doEditNewTitle())
        :subtitled(i18n("cpEditNewTitle_subtitle"))

    -- Add new command for doing the edit new title
    fcpxCmds:add("cpEditNewLowerThirds")
        :whenActivated(mod.doEditNewLowerThirds())
        :subtitled(i18n("cpEditNewLowerThirds_subtitle"))

    --------------------------------------------------------------------------------
    -- Title Edit
    --------------------------------------------------------------------------------

    return mod
end

return plugin