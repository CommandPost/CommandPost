--- === cp.apple.finalcutpro.export.destinations ===
---
--- Provides access to the list of Share Destinations configured for the user.

local _							= require("moses")

local log						= require("hs.logger").new("destinations")

local pathwatcher				= require("hs.pathwatcher")

local plist						= require("cp.plist")
local archiver					= require("cp.plist.archiver")

local mod = {}

mod.PREFERENCES_PATH	= "~/Library/Preferences"
mod.DESTINATIONS_FILE	= "com.apple.FinalCut.UserDestinations.plist"
mod.DESTINATIONS_PATH	= mod.PREFERENCES_PATH .. "/" .. mod.DESTINATIONS_FILE

local function load()
	local destinationsPlist, err = plist.fileToTable(mod.DESTINATIONS_PATH)
	if destinationsPlist then
		return archiver.unarchiveBase64(destinationsPlist.FFShareDestinationsKey).root
	else
		return nil, err
	end
end

local function watch()
	if not mod._watcher then
		mod._watcher = pathwatcher.new(mod.PREFERENCES_PATH, function(files)
			for _,file in pairs(files) do
				if file:sub(string.len(mod.DESTINATIONS_FILE)*-1) == mod.DESTINATIONS_FILE then
					mod._details, err = load()
					if err then
						log.wf("Unable to load FCPX User Destinations")
					end
					return
				end
			end
		end):start()
	end
end

--- cp.apple.finalcutpro.export.destinations.details() -> table
--- Function
--- Returns the full details of the current Share Destinations as a table.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The table of Share Destinations.
function mod.details()
	if not mod._details then
		mod._details, err = load()
		watch()
	end
	return mod._details
end

--- cp.apple.finalcutpro.export.destinations.names() -> table
--- Function
--- Returns an array of the names of destinations, in their current order.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The table of Share Destination names.
function mod.names()
	local list = mod.details()
	if list then
		return _.map(list, function(_, e) return e.name end)
	else
		return nil
	end
end

--- cp.apple.finalcutpro.export.destinations.indexOf(name) -> number
--- Function
--- Returns the index of the Destination with the specified name, or `nil` if not found.
---
--- Parameters:
---  * `name`	- The name of the Destination
---
--- Returns:
---  * The index of the named Destination, or `nil`.
function mod.indexOf(name)
	local list = mod.details()
	if list then
		return _.detect(list, function(e) return e.name == name end)
	else
		return nil
	end
end

return mod