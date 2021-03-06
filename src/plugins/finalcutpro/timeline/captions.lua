--- === plugins.finalcutpro.timeline.captions ===
---
--- Caption Tools

local require = require

local eventtap                          = require "hs.eventtap"
local keycodes                          = require "hs.keycodes"
local pasteboard                        = require "hs.pasteboard"

local dialog                            = require "cp.dialog"
local fcp                               = require "cp.apple.finalcutpro"
local go                                = require "cp.rx.go"

local event                             = eventtap.event
local Given, Require, Retry             = go.Given, go.Require, go.Retry
local map                               = keycodes.map

local mod = {}

--- plugins.finalcutpro.timeline.captions.doPasteTextAsCaption() -> cp.rx.go.Statement
--- Function
--- A [Statement](../cp/cp.rx.go.Statement.md) to Paste Text As Caption.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `cp.rx.go.Statement`
function mod.doPasteTextAsCaption()
    --------------------------------------------------------------------------------
    -- Check Pasteboard contents for text:
    --------------------------------------------------------------------------------
    return Given(
        Require(pasteboard.readString)
        :OrThrow("No text could be found on the Pasteboard.")
    ):Then(
        --------------------------------------------------------------------------------
        -- Check that the timeline is showing:
        --------------------------------------------------------------------------------
        fcp.timeline:doShow()
    ):Then(
        --------------------------------------------------------------------------------
        -- Add Caption:
        --------------------------------------------------------------------------------
        Require(fcp:doSelectMenu({"Edit", "Captions", "Add Caption"}))
        :OrThrow("A new caption could not be added.")
    ):Then(
        --------------------------------------------------------------------------------
        -- Paste Text:
        --------------------------------------------------------------------------------
        Retry(fcp:doSelectMenu({"Edit", "Paste"}))
        :UpTo(5):DelayedBy(100)
    ):Then(
        --------------------------------------------------------------------------------
        -- Close Caption box & Move playhead to the end of the caption:
        --------------------------------------------------------------------------------
        function()
            event.newKeyEvent(map.escape, true):post()
            event.newKeyEvent(map.down, true):post()
        end
    ):Catch(function(message)
        dialog.displayErrorMessage("Unable to 'Paste Text as Caption': "..message)
    end)
end

local plugin = {
    id = "finalcutpro.timeline.captions",
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
    -- Add Commands:
    --------------------------------------------------------------------------------
    deps.fcpxCmds
        :add("cpPasteTextAsCaption")
        :whenActivated(mod.doPasteTextAsCaption())

    return mod
end

return plugin
