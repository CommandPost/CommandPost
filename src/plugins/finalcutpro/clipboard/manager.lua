--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--              C L I P B O A R D   M A N A G E R    P L U G I N              --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.clipboard.manager ===
---
--- Clipboard Manager.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("clipmgr")

local pasteboard 								= require("hs.pasteboard")
local timer										= require("hs.timer")
local uuid										= require("hs.host").uuid

local plist 									= require("cp.plist")
local protect 									= require("cp.protect")
local archiver									= require("cp.plist.archiver")
local fcp										= require("cp.apple.finalcutpro")
local dialog 									= require("cp.dialog")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local CLIPBOARD = protect({
	--------------------------------------------------------------------------------
	-- FCPX Types:
	--------------------------------------------------------------------------------
	ANCHORED_COLLECTION 						= "FFAnchoredCollection",
	MARKER										= "FFAnchoredTimeMarker",
	GAP 										= "FFAnchoredGapGeneratorComponent",

	--------------------------------------------------------------------------------
	-- The default name used when copying from the Timeline:
	--------------------------------------------------------------------------------
	TIMELINE_DISPLAY_NAME 						= "__timelineContainerClip",

	--------------------------------------------------------------------------------
	-- The pasteboard/clipboard property containing the copied clips:
	--------------------------------------------------------------------------------
	PASTEBOARD_OBJECT 							= "ffpasteboardobject",
	UTI 										= "com.apple.flexo.proFFPasteboardUTI"
})

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

mod.excludedClassnames					= {CLIPBOARD.MARKER}				-- Data we don't want to count when copying.
mod.watcherFrequency					= 0.5

--------------------------------------------------------------------------------
-- IS TIMELINE CLIP:
--------------------------------------------------------------------------------
function mod.isTimelineClip(data)
	return data.displayName == CLIPBOARD.TIMELINE_DISPLAY_NAME
end

--------------------------------------------------------------------------------
-- PROCESS OBJECT:
--------------------------------------------------------------------------------
-- Processes the provided data object, which should have a '$class' property.
-- Returns: string (primary clip name), integer (number of clips)
--------------------------------------------------------------------------------
function mod.processObject(data)
	if type(data) == "table" then
		local class = data['$class']
		if class then
			return mod.processContent(data)
		elseif data[1] then
			-- it's an array
			return mod.processArray(data)
		end
	end
	return nil, 0
end

function mod.isClassnameSupported(classname)
	for i,name in ipairs(mod.excludedClassnames) do
		if name == classname then
			return false
		end
	end
	return true
end

--------------------------------------------------------------------------------
-- PROCESS ARRAY COLLECTION:
--------------------------------------------------------------------------------
-- Processes an 'array' table
-- Params:
--		* data: 	The data object to process
-- Returns: string (primary clip name), integer (number of clips)
--------------------------------------------------------------------------------
function mod.processArray(data)
	local name = nil
	local count = 0
	for i,v in ipairs(data) do
		local n,c = mod.processObject(v, objects)
		if name == nil then
			name = n
		end
		count = count + c
	end
	return name, count
end

--------------------------------------------------------------------------------
-- SUPPORTS CONTAINED ITEMS:
--------------------------------------------------------------------------------
function mod.supportsContainedItems(data)
	local classname = mod.getClassname(data)
	return data.containedItems and classname ~= CLIPBOARD.ANCHORED_COLLECTION
end

--------------------------------------------------------------------------------
-- GET CLASSNAME:
--------------------------------------------------------------------------------
function mod.getClassname(data)
	return data["$class"]["$classname"]
end

--------------------------------------------------------------------------------
-- PROCESS SIMPLE CONTENT:
--------------------------------------------------------------------------------
-- Process objects which have a displayName, such as Compound Clips, Images, etc.
-- Returns: string (primary clip name), integer (number of clips)
--------------------------------------------------------------------------------
function mod.processContent(data)
	if not mod.isClassnameSupported(classname) then
		return nil, 0
	end

	if mod.isTimelineClip(data) then
		-- Just process the contained items directly
		return mod.processObject(data.containedItems)
	end

	local displayName = data.displayName
	local count = displayName and 1 or 0

	if mod.getClassname(data) == CLIPBOARD.GAP then
		displayName = nil
		count = 0
	end

	if mod.supportsContainedItems(data) then
		n, c = mod.processObject(data.containedItems)
		count = count + c
		displayName = displayName or n
	end

	if data.anchoredItems then
		n, c = mod.processObject(data.anchoredItems)
		count = count + c
		displayName = displayName or n
	end

	if displayName then
		return displayName, count
	else
		return nil, 0
	end
end

--------------------------------------------------------------------------------
-- FIND CLIP NAME:
--------------------------------------------------------------------------------
-- Searches the Pasteboard binary plist data for the first clip name, and returns it.
-- Returns the 'default' value if the pasteboard contains a media clip but we could not interpret it.
-- Returns `nil` if the data did not contain FCPX Clip data.
-- Example use:
--	 local name = mod.findClipName(myFcpxData, "Unknown")
--------------------------------------------------------------------------------
function mod.findClipName(fcpxData, default)
	local data = mod.unarchiveFCPXData(fcpxData)

	if data then
		local name, count = mod.processObject(data.root.objects)

		if name then
			if count > 1 then
				return name.." (+"..(count-1)..")"
			else
				return name
			end
		else
			return default
		end
	end
	return nil
end

--------------------------------------------------------------------------------
-- OVERRIDE CLIP NAME:
--------------------------------------------------------------------------------
-- Overrides the name for the next clip which is copied from FCPX to the specified
-- value. Once the override has been used, the standard clip name via
-- `mod.findClipName(...)` will be used for subsequent copy operations.
--
--------------------------------------------------------------------------------
function mod.overrideNextClipName(overrideName)
	mod._overrideName = overrideName
end

--------------------------------------------------------------------------------
-- COPY WITH CUSTOM LABEL:
--------------------------------------------------------------------------------
function mod.copyWithCustomClipName()
	log.d("Copying Clip with custom Clip Name")
	local menuBar = fcp:menuBar()
	if menuBar:isEnabled("Edit", "Copy") then
		local result = dialog.displayTextBoxMessage(i18n("overrideClipNamePrompt"), i18n("overrideValueInvalid"), "")
		if result == false then return end
		mod.overrideNextClipName(result)
		menuBar:selectMenu("Edit", "Copy")
	end
end

--------------------------------------------------------------------------------
-- READ FINAL CUT PRO DATA:
--------------------------------------------------------------------------------
-- Reads FCPX Data from the Pasteboard as a binary Plist, if present.
-- If not, nil is returned.
--------------------------------------------------------------------------------
function mod.readFCPXData()
	local clipboardContent = pasteboard.allContentTypes()
	if clipboardContent ~= nil then
		if clipboardContent[1] ~= nil then
			if clipboardContent[1][1] == CLIPBOARD.UTI then
				return pasteboard.readDataForUTI(CLIPBOARD.UTI)
			end
		end
	end
	return nil
end

--------------------------------------------------------------------------------
-- UNARCHIVE FINAL CUT PRO DATA:
--------------------------------------------------------------------------------
function mod.unarchiveFCPXData(fcpxData)
	if not fcpxData then
		fcpxData = mod.readFCPXData()
	end

	local clipboardTable = plist.binaryToTable(fcpxData)
	if clipboardTable then
		local base64Data = clipboardTable[CLIPBOARD.PASTEBOARD_OBJECT]
		if base64Data then
			local fcpxTable = plist.base64ToTable(base64Data)
			if fcpxTable then
				return archiver.unarchive(fcpxTable)
			end
		end
	end
	log.e("The clipboard does not contain any FCPX clip data.")
	return nil
end

--------------------------------------------------------------------------------
-- WRITE FINAL CUT PRO DATA:
--------------------------------------------------------------------------------
function mod.writeFCPXData(fcpxData, quiet)
	--------------------------------------------------------------------------------
	-- Write data back to Clipboard:
	--------------------------------------------------------------------------------
	if quiet then mod.stopWatching() end
	local result = pasteboard.writeDataForUTI(CLIPBOARD.UTI, fcpxData)
	if quiet then mod.startWatching() end

	return result
end

--------------------------------------------------------------------------------
-- WATCHERS:
--------------------------------------------------------------------------------
function mod.watch(events)
	local startWatching = false
	if not mod._watchers then
		mod._watchers = {}
		mod._watchersCount = 0
		startWatching = true
	end
	local id = uuid()
	mod._watchers[id] = {update = events.update}
	mod._watchersCount = mod._watchersCount + 1

	if startWatching then
		mod.startWatching()
	end

	return {id=id}
end

--------------------------------------------------------------------------------
-- UNWATCH:
--------------------------------------------------------------------------------
function mod.unwatch(id)
	if mod._watchers then
		if mod._watchers[id.id] then
			mod._watchers[id.id] = nil
			mod._watchersCount = mod._watchersCount - 1
			if mod._watchersCount < 1 then
				mod.stopWatching()
			end
			return true
		end
	end
	return false
end

--------------------------------------------------------------------------------
-- START WATCHING:
--------------------------------------------------------------------------------
function mod.startWatching()
	if mod._watchersCount < 1 then
		return
	end

	--log.d("Starting Clipboard Watcher.")

	if mod._timer then
		mod.stopWatching()
	end

	--------------------------------------------------------------------------------
	-- Reset:
	--------------------------------------------------------------------------------
	mod._lastChange = pasteboard.changeCount()

	--------------------------------------------------------------------------------
	-- Watch for Clipboard Changes:
	--------------------------------------------------------------------------------
	mod._timer = timer.new(mod.watcherFrequency, function()
		if not mod._watchers then
			return
		end

		local currentChange = pasteboard.changeCount()

		if (currentChange > mod._lastChange) then
			--------------------------------------------------------------------------------
			-- Read Clipboard Data:
			--------------------------------------------------------------------------------
			local data = mod.readFCPXData()

			--------------------------------------------------------------------------------
			-- Notify watchers
			--------------------------------------------------------------------------------
			if data then
				local name = nil
				-- An override was set
				if mod._overrideName ~= nil then
					-- apply it
					name = mod._overrideName
					-- reset it
					mod._overrideName = nil
				else
					-- find the name from inside the clip data
					name = mod.findClipName(data, os.date())
				end
				for _,events in pairs(mod._watchers) do
					if events.update then
						events.update(data, name)
					end
				end
			end
		end
		mod._lastChange = currentChange
	end)
	mod._timer:start()

	--log.d("Started Clipboard Watcher")
end

--------------------------------------------------------------------------------
-- STOP WATCHING THE CLIPBOARD:
--------------------------------------------------------------------------------
function mod.stopWatching()
	if mod._timer then
		mod._timer:stop()
		mod._timer = nil
		--log.d("Stopped Clipboard Watcher")
	end
end

--------------------------------------------------------------------------------
-- IS THIS MODULE WATCHING THE CLIPBOARD:
-------------------------------------------------------------------------------
function mod.isWatching()
	return mod._timer ~= nil
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.clipboard.manager",
	group			= "finalcutpro",
	dependencies	= {
		["finalcutpro.commands"]	= "fcpxCmds",
	}
}

function plugin.init(deps)
	--------------------------------------------------------------------------------
	-- COMMANDS:
	--------------------------------------------------------------------------------
	deps.fcpxCmds:add("cpCopyWithCustomLabel")
		:whenActivated(mod.copyWithCustomClipName)

	return mod
end

return plugin