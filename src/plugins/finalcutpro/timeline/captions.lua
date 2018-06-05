--- === plugins.finalcutpro.timeline.captions ===
---
--- Caption Tools

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

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
    local contents = pasteboard.readString()
    if not contents then
       dialog.displayErrorMessage("Could not 'Paste Text as Caption' because no text could be found on the Pasteboard.")
    end

    --------------------------------------------------------------------------------
    -- Check that the timeline is showing:
    --------------------------------------------------------------------------------
    local timeline = fcp:timeline()
    timeline:show()
    if not timeline:isShowing() then
        dialog.displayErrorMessage("Could not 'Paste Text as Caption' because the timeline could not be made visible.")
    end

    --------------------------------------------------------------------------------
    -- Add Caption:
    --------------------------------------------------------------------------------
    if not fcp:selectMenu({"Edit", "Captions", "Add Caption"}) then
        dialog.displayErrorMessage("Could not 'Paste Text as Caption' because a new caption could not be added.")
    end

    --------------------------------------------------------------------------------
    -- Paste Text:
    --------------------------------------------------------------------------------
    if not fcp:selectMenu({"Edit", "Paste"}) then
        dialog.displayErrorMessage("Could not 'Paste Text as Caption' because we could not paste text back into Final Cut Pro.")
    end

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