--- === plugins.finalcutpro.browser.insertvertical ===
---
--- Insert Clips Vertically from Browser to Timeline.

local require = require

local log               = require "hs.logger".new "addnote"

local dialog            = require "cp.dialog"
local fcp               = require "cp.apple.finalcutpro"
local go                = require "cp.rx.go"
local i18n              = require "cp.i18n"

local displayMessage    = dialog.displayMessage

local Do                = go.Do
local Given             = go.Given
local If                = go.If
local List              = go.List
local Throw             = go.Throw

local plugin = {
    id              = "finalcutpro.browser.insertvertical",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]    = "fcpxCmds",
    }
}

function plugin.init(deps)

    local libraries = fcp:browser():libraries()
    deps.fcpxCmds
        :add("insertClipsVerticallyFromBrowserToTimeline")
        :whenActivated(
            Do(libraries:doShow())
            :Then(
                If(function()
                    local clips = libraries:selectedClips()
                    return clips and #clips >= 1
                end):Then(
                    Given(List(function()
                        if libraries():isListView() then
                            local indexes = {}
                            local selectedClips = libraries:selectedClips()
                            for i, clip in pairs(selectedClips) do
                                indexes[i] = libraries:indexOfClip(clip)
                            end
                            return indexes
                        else
                            return libraries:selectedClips()
                        end
                    end))
                        :Then(function(clip)
                            if libraries():isListView() then
                                if not libraries:selectClipAt(clip) then
                                    return Throw("Failed to select clip at index %s.", clip)
                                end
                            else
                                if not libraries:selectClip(clip) then
                                    return Throw("Failed to select clip.")
                                end
                            end
                            -----------------------------------------------------------------------
                            -- TODO: These selectMenu's should be replaced with doSelectMenu's.
                            --       Chris tried everything he could think of to keep everything
                            --       Rx-ified, but failed to get the timing/order to work properly.
                            -----------------------------------------------------------------------
                            if not fcp:selectMenu({"Edit", "Connect to Primary Storyline"}) then
                                return Throw("Failed to Connect to Primary Storyline.")
                            end
                            if not fcp:selectMenu({"Window", "Go To", "Timeline"}) then
                                return Throw("Failed to go to timeline.")
                            end
                            if not fcp:selectMenu({"Mark", "Previous", "Edit"}) then
                                return Throw("Failed to go to previous edit.")
                            end
                            return true
                        end)
                ):Otherwise(
                    Throw(i18n("noSelectedClipsInBrowser"))
                )
            )
            :Catch(function(message)
                log.ef("Error in insertClipsVerticallyFromBrowserToTimeline: %s", message)
                displayMessage(message)
            end)
        )
        :titled(i18n("insertClipsVerticallyFromBrowserToTimeline"))

end

return plugin