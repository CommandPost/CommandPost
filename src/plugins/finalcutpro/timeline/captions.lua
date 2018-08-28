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
--local log                               = require("hs.logger").new("doPasteTextAsCaption")

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
local Given, Require, Retry             = go.Given, go.Require, go.Retry

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
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
        fcp:timeline():doShow()
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
    )
    :Catch(function(message)
        dialog.displayErrorMessage("Unable to 'Paste Text as Caption': "..message)
    end)
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
            :whenActivated(mod.doPasteTextAsCaption())
    end

    return mod
end

return plugin
