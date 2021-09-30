
--- === plugins.finalcutpro.timeline.markallclips ===
---
--- Add a marker to all selected clips under the playhead, or all clips if only one clip is selected.

local require       = require

local fcp           = require "cp.apple.finalcutpro"
local axutils       = require "cp.ui.axutils"

local go            = require "cp.rx.go"
local Observable    = require "cp.rx.Observable"

local Given, Do     = go.Given, go.Do

local mod = {}

function mod.markAllClips()
    local contents = fcp.timeline.contents
    local playhead = fcp.timeline.playhead
    local skimmer = fcp.timeline.skimmingPlayhead

    local position = skimmer:position() or playhead:position()

    if not position then return end

    local clipsUI = contents:positionClipsUI(position, true)

    if not clipsUI then return end

    local selectedUI = axutils.childrenMatching(clipsUI, function(child) return child.AXSelected end)
    if #selectedUI > 1 then
        clipsUI = selectedUI
    end

    Do(
        Given(Observable.fromTable(clipsUI, ipairs))
        :Then(function(clipUI)
            return contents:doSelectClip(clipUI)
            :Then(fcp:doSelectMenu({"Mark", "Markers", "Add Marker"}))
        end)
    ):Then(
        contents:doSelectClips({})
    )
    :Now()
end

local plugin = {
    id = "finalcutpro.timeline.markallclips",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"]    = "fcpxCmds",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    deps.fcpxCmds
        :add("cpMarkAllClips")
        :activatedBy():option():shift("m")
        :whenActivated(mod.markAllClips)

    return mod
end

return plugin