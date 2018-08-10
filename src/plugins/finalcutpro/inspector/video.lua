--- === plugins.finalcutpro.inspector.video ===
---
--- Final Cut Pro Video Inspector Additions.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log               = require("hs.logger").new("videoInspector")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local fcp               = require("cp.apple.finalcutpro")
local tools             = require("cp.tools")
local dialog            = require("cp.dialog")

local go                = require("cp.rx.go")
local Do                = go.Do
local WaitUntil         = go.WaitUntil

local function doSetSpatialConform(value)
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
    :Label("video.doSetSpatialConform")

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

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    if deps.fcpxCmds then
        deps.fcpxCmds
            :add("cpSetSpatialConformTypeToFit")
            :whenActivated(doSetSpatialConform("Fit"))

        deps.fcpxCmds
            :add("cpSetSpatialConformTypeToFill")
            :whenActivated(doSetSpatialConform("Fill"))

        deps.fcpxCmds
            :add("cpSetSpatialConformTypeToNone")
            :whenActivated(doSetSpatialConform("None"))
    end

end

return plugin