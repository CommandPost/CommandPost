--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                 I G N O R E   C A R D S   P L U G I N                      --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.import.ignorecard ===
---
--- Ignore Final Cut Pro's Media Import Window.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log						= require("hs.logger").new("ignorecard")

local fs						= require("hs.fs")
local application				= require("hs.application")
local timer						= require("hs.timer")

local fcp						= require("cp.apple.finalcutpro")
local config					= require("cp.config")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.import.ignorecard.getDeviceWatcher() -> none
--- Function
--- Media Import Window Watcher
---
--- Parameters:
---  * None
---
--- Returns:
---  * An `hs.fs.volume` object
function mod.getDeviceWatcher()
	if not mod.newDeviceMounted then
		--log.df("Watching for new media...")
		mod.newDeviceMounted = fs.volume.new(function(event, table)
			if event == fs.volume.didMount then

				--log.df("Media Inserted.")

				local mediaImport = fcp:mediaImport()

				if mediaImport:isShowing() then
					-- Media Import was already open. Bail!
					--log.df("Already in Media Import. Continuing...")
					return
				end

				local mediaImportCount = 0
				local stopMediaImportTimer = false
				local currentApplication = application.frontmostApplication()
				--log.df("Currently using '"..currentApplication:name().."'")

				local fcpxHidden = not fcp:isShowing()

				mediaImportTimer = timer.doUntil(
					function()
						return stopMediaImportTimer
					end,
					function()
						if not fcp:isRunning() then
							--log.df("FCPX is not running. Stop watching.")
							stopMediaImportTimer = true
						else
							if mediaImport:isShowing() then
								mediaImport:hide()
								if fcpxHidden then fcp:hide() end
								currentApplication:activate()
								--log.df("Hid FCPX and returned to '"..currentApplication:name().."'.")
								stopMediaImportTimer = true
							end
							mediaImportCount = mediaImportCount + 1
							if mediaImportCount == 500 then
								--log.df("Gave up watching for the Media Import window after 5 seconds.")
								stopMediaImportTimer = true
							end
						end
					end,
					0.01
				)

			end
		end)
	end
	return mod.newDeviceMounted
end

--- plugins.finalcutpro.import.ignorecard.update() -> none
--- Function
--- Starts to stops the Ignore Card device watcher.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.update()
	local watcher = mod.getDeviceWatcher()
	if mod.enabled() then
		watcher:start()
	else
		watcher:stop()
	end
end

--- plugins.finalcutpro.import.ignorecard.enabled <cp.prop: boolean>
--- Variable
--- Toggles the Ignore Card Plugin
mod.enabled = config.prop("enableMediaImportWatcher", false):watch(mod.update)

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.import.ignorecard",
	group			= "finalcutpro",
	dependencies	= {
		["finalcutpro.preferences.app"]	= "prefs",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

	--------------------------------------------------------------------------------
	-- Setup Menubar Preferences Panel:
	--------------------------------------------------------------------------------
	if deps.prefs.panel then
		deps.prefs.panel
			--------------------------------------------------------------------------------
			-- Add Preferences Heading:
			--------------------------------------------------------------------------------
			:addHeading(1, i18n("general"))

			--------------------------------------------------------------------------------
			-- Add Preferences Checkbox:
			--------------------------------------------------------------------------------
			:addCheckbox(1.1,
			{
				label = i18n("ignoreInsertedCameraCards"),
				onchange = function(_, params) mod.enabled(params.checked) end,
				checked = mod.enabled,
			}
		)
	end

	--------------------------------------------------------------------------------
	-- Update the watcher status based on the settings:
	--------------------------------------------------------------------------------
	mod.update()

	return mod
end

return plugin