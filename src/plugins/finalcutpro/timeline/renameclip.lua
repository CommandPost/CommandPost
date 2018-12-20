--- === plugins.finalcutpro.timeline.renameclip ===
---
--- Rename Clip

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log = require("hs.logger").new("renameClip")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils = require("cp.ui.axutils")
local fcp = require("cp.apple.finalcutpro")
local go = require("cp.rx.go")
local tools = require("cp.tools")

local If, Do = go.If, go.Do

local MenuButton = require("cp.ui.MenuButton")

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.timeline.renameclip",
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
    -- Rename Clip Rx:
    --------------------------------------------------------------------------------
    local doRenameClip = function()

        local selectedClip, item
        return If(function()
            local content = fcp:timeline():contents()
            local selectedClips = content:selectedClipsUI()
            if selectedClips and #selectedClips == 1 then
                selectedClip = selectedClips[1]
            end
            return selectedClip
        end)
        :Then(
            Do(function()
                selectedClip:performAction("AXShowMenu")
            end):ThenYield()
        )
        :Then(function()
            local parent = selectedClip:attributeValue("AXParent")
            local menu = axutils.childWithRole(parent, "AXMenu")
            item = axutils.childWith(menu, "AXTitle", fcp:string("FFRename Bin Object"))
        end)
        :Then(
            Do(function()
                item:performAction("AXPress")
            end):ThenYield()
        )
        :Catch(function(message)
            tools.playErrorSound()
            log.ef("doRenameClip: %s", message)
        end)
    end

    --------------------------------------------------------------------------------
    -- Add Commands:
    --------------------------------------------------------------------------------
    deps.fcpxCmds:add("renameClip")
        :whenActivated(function() doRenameClip():Now() end)
        :titled(fcp:string("FFRename Bin Object"))

end

return plugin
