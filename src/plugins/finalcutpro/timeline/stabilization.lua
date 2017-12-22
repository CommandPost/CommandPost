--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.timeline.stabilization ===
---
--- Stabilization Shortcut

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log							= require("hs.logger").new("stabilization")

local fcp							= require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

function mod.stabilization(value)

	--------------------------------------------------------------------------------
	-- Set Stabilization:
	--------------------------------------------------------------------------------
	local inspector = fcp:inspector():videoInspector()
	if type(value) == "boolean" then
		inspector:stabilization(value)
	else
		--------------------------------------------------------------------------------
		-- Toggle:
		--------------------------------------------------------------------------------
		local value = inspector:stabilization()
		inspector:stabilization(not value)
	end

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id = "finalcutpro.timeline.stabilization",
	group = "finalcutpro",
	dependencies = {
		["finalcutpro.commands"]			= "fcpxCmds",
	}
}

function plugin.init(deps)

	--------------------------------------------------------------------------------
	-- Commands:
	--------------------------------------------------------------------------------
	local cmds = deps.fcpxCmds

	cmds:add("cpStabilizationToggle")
		:groupedBy("timeline")
		:whenActivated(function() mod.stabilization() end)

	cmds:add("cpStabilizationEnable")
		:groupedBy("timeline")
		:whenActivated(function() mod.stabilization(true) end)

	cmds:add("cpStabilizationDisable")
		:groupedBy("timeline")
		:whenActivated(function() mod.stabilization(false) end)

	return mod
end

return plugin