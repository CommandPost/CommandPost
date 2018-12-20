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

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local eventtap = require("hs.eventtap")
local geometry = require("hs.geometry")

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
                --------------------------------------------------------------------------------
                -- For some weird reason `AXShowMenu` seems to freeze the system:
                --------------------------------------------------------------------------------
                --selectedClip:performAction("AXShowMenu")

                --------------------------------------------------------------------------------
                -- Here's an ugly workaround:
                --------------------------------------------------------------------------------
                local frame = selectedClip:attributeValue("AXFrame")
                local point = geometry.new(frame).center

                local RIGHT_MOUSE_DOWN = eventtap.event.types["rightMouseDown"]
                local RIGHT_MOUSE_UP = eventtap.event.types["rightMouseUp"]
                local CLICK_STATE = eventtap.event.properties.mouseEventClickState

                eventtap.event.newMouseEvent(RIGHT_MOUSE_DOWN, point):setProperty(CLICK_STATE, 1):post()
                eventtap.event.newMouseEvent(RIGHT_MOUSE_UP, point):setProperty(CLICK_STATE, 1):post()

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
