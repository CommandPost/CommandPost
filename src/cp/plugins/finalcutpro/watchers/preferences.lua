--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                 P R E F E R E N C E S    W A T C H E R                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("fcpPrefsWatcher")

local fcp				= require("cp.finalcutpro")

--------------------------------------------------------------------------------
--- THE PLUGIN:
--------------------------------------------------------------------------------
local plugin = {}

	--------------------------------------------------------------------------------
	-- INITIALISE PLUGIN:
	--------------------------------------------------------------------------------
	function plugin.init(deps)

		--------------------------------------------------------------------------------
		-- Update Preferences Cache when Final Cut Pro Preferences file is updated:
		--------------------------------------------------------------------------------
		fcp:watch({
			preferences = function()
				--log.df("Preferences file change detected. Forcing a reload.")
				fcp:getPreferences(true)
			end,
		})

	end

return plugin