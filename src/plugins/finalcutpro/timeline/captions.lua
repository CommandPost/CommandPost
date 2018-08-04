--- === plugins.finalcutpro.timeline.captions ===
---
--- Caption Tools

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
--local log                               = require("hs.logger").new("pasteTextAsCaption")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local pasteboard                        = require("hs.pasteboard")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local dialog                            = require("cp.dialog")
local fcp                               = require("cp.apple.finalcutpro")

local go                                = require("cp.rx.go")
local Given, Require                    = go.Given, go.Require

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.timeline.captions.pasteTextAsCaption() -> none
--- Function
--- Paste Text As Caption
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.pasteTextAsCaption()

    --------------------------------------------------------------------------------
    -- Check Pasteboard contents for text:
    --------------------------------------------------------------------------------
    return Given(
        Require(pasteboard.readString())
        :OrThrow("No text could be found on the Pasteboard.")
    ):Then(
        --------------------------------------------------------------------------------
        -- Check that the timeline is showing:
        --------------------------------------------------------------------------------
        Require(fcp:timeline():doShow())
        :OrThrow("Unable to show the Timeline")
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
        Require(fcp:doSelectMenu({"Edit", "Paste"}))
        :OrThrow("Unable to paste text back into Final Cut Pro.")
    )
    :Catch(function(message)
        dialog.displayErrorMessage("Unable to 'Paste Text as Caption': "..message)
    end)
    :Now()
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.timeline.captions",
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
    -- Add Commands:
    --------------------------------------------------------------------------------
    if deps.fcpxCmds then
        deps.fcpxCmds:add("cpPasteTextAsCaption")
            :whenActivated(mod.pasteTextAsCaption)
    end

    return mod
end

return plugin
