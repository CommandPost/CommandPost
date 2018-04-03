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
-- CommandPost Extensions:
--------------------------------------------------------------------------------
-- local log                                       = require("hs.logger").new("fcptng_timeline")
local fcp                                       = require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.tangent.timeline.group
--- Constant
--- The `core.tangent.manager.group` that collects FPX Timeline actions/parameters/etc.
mod.group = nil

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
    mod.group = fcpGroup:group(i18n("timeline"))
    local tlBaseID = 0x00040000

    -- TIMELINE ZOOM:
    local appearance = fcp:timeline():toolbar():appearance()
    local zoom = appearance:zoomAmount()

    mod.group:parameter(tlBaseID + 0x01)
        :name(i18n("timelineZoom"))
        :name9(i18n("timelineZoom9"))
        :minValue(0)
        :maxValue(10)
        :stepSize(0.2)
        :onGet(function() zoom:getValue() end)
        :onChange(function(value) zoom:show():shiftValue(value) end)
        :onReset(function() zoom:show():setValue(10) end)
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