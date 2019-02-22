--- === plugins.finalcutpro.inspector.video ===
---
--- Final Cut Pro Video Inspector Additions.

local require = require

local log               = require("hs.logger").new("videoInspector")

local fcp               = require("cp.apple.finalcutpro")
local tools             = require("cp.tools")
local dialog            = require("cp.dialog")

local go                = require("cp.rx.go")
local Do                = go.Do
local WaitUntil         = go.WaitUntil

local function doSpatialConformType(value)
    local timeline = fcp:timeline()
    local timelineContents = timeline:contents()
    local spatialConformType = fcp:inspector():video():spatialConform():type()

    return Do(function()
        --------------------------------------------------------------------------------
        -- Make sure at least one clip is selected:
        --------------------------------------------------------------------------------
        local clips = timelineContents:selectedClipsUI()
        if clips and #clips == 0 then
            log.f("Set Spatial Conform Failed: No clips selected.")
            tools.playErrorSound()
            return false
        end

        return Do(spatialConformType:doSelectValue(value))
        :Then(WaitUntil(spatialConformType):Is(value):TimeoutAfter(2000))
        :Then(true)
    end)
    :Catch(function(message)
        dialog.displayErrorMessage(message)
        return false
    end)
    :Label("video.doSpatialConformType")

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.inspector.video",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]        = "fcpxCmds",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    local fcpxCmds = deps.fcpxCmds
    fcpxCmds
        :add("cpSetSpatialConformTypeToFit")
        :whenActivated(doSpatialConformType("Fit"))

    fcpxCmds
        :add("cpSetSpatialConformTypeToFill")
        :whenActivated(doSpatialConformType("Fill"))

    fcpxCmds
        :add("cpSetSpatialConformTypeToNone")
        :whenActivated(doSpatialConformType("None"))
end

return plugin
