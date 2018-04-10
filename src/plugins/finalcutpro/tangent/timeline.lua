--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.tangent.timeline ===
---
--- Final Cut Pro Tangent Timeline Group/Management

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
--local log                                       = require("hs.logger").new("fcptng_timeline")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local delayed                                   = require("hs.timer").delayed

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local deferred                                  = require("cp.deferred")
local fcp                                       = require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.tangent.timeline.group
--- Constant
--- The `core.tangent.manager.group` that collects Final Cut Pro Timeline actions/parameters/etc.
mod.group = nil

-- plugins.finalcutpro.tangent.timeline._zoomChange
-- Variable
-- Zoom Change Value
mod._zoomChange = 0

--- plugins.finalcutpro.tangent.manager.init() -> none
--- Function
--- Initialises the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init(fcpGroup)
    --------------------------------------------------------------------------------
    -- Base ID:
    --------------------------------------------------------------------------------
    local tlBaseID = 0x00040000

    --------------------------------------------------------------------------------
    -- Create Timeline Group:
    --------------------------------------------------------------------------------
    mod.group = fcpGroup:group(i18n("timeline"))

    --------------------------------------------------------------------------------
    -- Timeline Zoom:
    --------------------------------------------------------------------------------
    mod._updateZoomUI = deferred.new(0.01)

    mod._zoomDelayedCloser = delayed.new(0.5, function()
        local appearance = fcp:timeline():toolbar():appearance()
        if appearance then
            appearance:hide()
        end
    end)

    mod.group:parameter(tlBaseID + 0x01)
        :name(i18n("timelineZoom"))
        :name9(i18n("timelineZoom9"))
        :minValue(0)
        :maxValue(10)
        :stepSize(0.2)
        :onGet(function()
            local appearance = fcp:timeline():toolbar():appearance()
            if appearance then
                return appearance:show():zoomAmount():getValue()
            end
        end)
        :onChange(function(change)
            mod._zoomDelayedCloser:start()
            mod._zoomChange = mod._zoomChange + change
            mod._updateZoomUI()
        end)
        :onReset(function()
            local appearance = fcp:timeline():toolbar():appearance()
            if appearance then
                appearance:show():zoomAmount():setValue(10)
            end
        end)

    mod._updateZoomUI:action(function()
        if mod._zoomChange ~= 0 then
            local appearance = fcp:timeline():toolbar():appearance()
            if appearance then
                local currentValue = appearance:show():zoomAmount():getValue()
                if currentValue then
                    appearance:show():zoomAmount():setValue(currentValue + mod._zoomChange)
                end
            end
            mod._zoomChange = 0
        end
    end)

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.tangent.timeline",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.tangent.group"]   = "fcpGroup",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Initalise the Module:
    --------------------------------------------------------------------------------
    mod.init(deps.fcpGroup)

    return mod
end

return plugin