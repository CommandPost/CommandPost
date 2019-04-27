--- === plugins.finalcutpro.browser.insertvertical ===
---
--- Insert Clips Vertically from Browser to Timeline.

local require = require

local log               = require "hs.logger".new "addnote"

local fcp               = require "cp.apple.finalcutpro"
local dialog            = require "cp.dialog"
local i18n              = require "cp.i18n"
local go                = require "cp.rx.go"

local Do                = go.Do
local If                = go.If
local Throw             = go.Throw
local Given             = go.Given
local List              = go.List
local Retry             = go.Retry

local plugin = {
    id              = "finalcutpro.browser.insertvertical",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]    = "fcpxCmds",
    }
}

function plugin.init(deps)

    local timeline = fcp:timeline()
    local libraries = fcp:browser():libraries()
    deps.fcpxCmds
        :add("insertClipsVerticallyFromBrowserToTimeline")
        :whenActivated(
            Do(libraries:doShow())
            :Then(
                If(function()
                    local clips = libraries:selectedClips()
                    return clips and #clips >= 2
                end):Then(
                    Given(List(function() return libraries:selectedClips() end))
                        :Then(function(child)
                            log.df("Selecting clip: %s", child)
                            libraries:selectClip(child)
                            return true
                        end)
                        :Then(function()
                            log.df("Connecting to primary storyline")
                            return true
                        end)
                        :Then(fcp:doSelectMenu({"Edit", "Connect to Primary Storyline"}))
                        :Then(function()
                            log.df("Focussing on timeline.")
                            return true
                        end)
                        :Then(timeline:doFocus())
                        :Then(
                            Retry(function()
                                if timeline.isFocused() then
                                    return true
                                else
                                    return Throw("Failed to make the timeline focused.")
                                end
                            end):UpTo(10):DelayedBy(100)
                        )
                        :Then(function()
                            log.df("Go to previous edit.")
                            return true
                        end)
                        :Then(fcp:doSelectMenu({"Mark", "Previous", "Edit"}))
                        :Then(function()
                            log.df("End of block")
                            return true
                        end)
                ):Otherwise(
                    Throw("No clips selected in the Browser.")
                )
            )
            :Catch(function(message)
                log.ef("Error in insertClipsVerticallyFromBrowserToTimeline: %s", message)
                dialog.displayMessage(message)
            end)
        )
        :titled(i18n("insertClipsVerticallyFromBrowserToTimeline"))

end

return plugin