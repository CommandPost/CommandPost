-- Imports
local fs						= require("hs.fs")
local application				= require("hs.application")
local timer						= require("hs.timer")

local fcp						= require("cp.finalcutpro")
local metadata					= require("cp.metadata")

local log						= require("hs.logger").new("ignorecard")

-- Constants

local PRIORITY = 20000

-- Local Functions

-- The Module
local mod = {}

--------------------------------------------------------------------------------
-- RETURNS THE CURRENT ENABLED STATUS
--------------------------------------------------------------------------------
function mod.isEnabled()
	return metadata.get("enableMediaImportWatcher", false)
end

--------------------------------------------------------------------------------
-- SETS THE ENABLED STATUS AND UPDATES THE WATCHER APPROPRIATELY
--------------------------------------------------------------------------------
function mod.setEnabled(enabled)
	metadata.set("enableMediaImportWatcher", enabled)
	mod.update()
end

--------------------------------------------------------------------------------
-- TOGGLE MEDIA IMPORT WATCHER:
--------------------------------------------------------------------------------
function mod.toggleEnabled()
	mod.setEnabled(not mod.isEnabled())
end

--------------------------------------------------------------------------------
-- UPDATES THE WATCHER BASED ON THE ENABLED STATUS
--------------------------------------------------------------------------------
function mod.update()
	local watcher = mod.getDeviceWatcher()
	if mod.isEnabled() then
		watcher:start()
	else
		watcher:stop()
	end
end

--------------------------------------------------------------------------------
-- MEDIA IMPORT WINDOW WATCHER:
--------------------------------------------------------------------------------
function mod.getDeviceWatcher()
	if not mod.newDeviceMounted then
		log.df("Watching for new media...")
		mod.newDeviceMounted = fs.volume.new(function(event, table)
			if event == fs.volume.didMount then

				log.df("Media Inserted.")

				local mediaImport = fcp:mediaImport()

				if mediaImport:isShowing() then
					-- Media Import was already open. Bail!
					log.df("Already in Media Import. Continuing...")
					return
				end

				local mediaImportCount = 0
				local stopMediaImportTimer = false
				local currentApplication = application.frontmostApplication()
				log.df("Currently using '"..currentApplication:name().."'")

				local fcpxHidden = not fcp:isShowing()

				mediaImportTimer = timer.doUntil(
					function()
						return stopMediaImportTimer
					end,
					function()
						if not fcp:isRunning() then
							log.df("FCPX is not running. Stop watching.")
							stopMediaImportTimer = true
						else
							if mediaImport:isShowing() then
								mediaImport:hide()
								if fcpxHidden then fcp:hide() end
								currentApplication:activate()
								log.df("Hid FCPX and returned to '"..currentApplication:name().."'.")
								stopMediaImportTimer = true
							end
							mediaImportCount = mediaImportCount + 1
							if mediaImportCount == 500 then
								log.df("Gave up watching for the Media Import window after 5 seconds.")
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

-- The Plugin
local plugin = {}

plugin.dependencies = {
	["cp.plugins.menu.mediaimport"] = "options",
}

function plugin.init(deps)

	-- Add the menu item
	local section = deps.options:addSection(PRIORITY)
	section:addItem(200, function()
		return { title = i18n("ignoreInsertedCameraCards"),	fn = mod.toggleEnabled,	checked = mod.isEnabled() }
	end)
	section:addSeparator(900)

	-- Update the watcher status based on the settings
	mod.update()

	return mod
end

return plugin