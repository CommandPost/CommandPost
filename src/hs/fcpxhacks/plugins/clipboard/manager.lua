local uuid										= require("hs.fcpxhacks.modules.uuid")
local pasteboard 								= require("hs.pasteboard")
local plist 									= require("hs.plist")
local archiver									= require("hs.plist.archiver")
local protect 									= require("hs.fcpxhacks.modules.protect")
local timer										= require("hs.timer")
local fcp										= require("hs.finalcutpro")
local dialog 									= require("hs.fcpxhacks.modules.dialog")

local log										= require("hs.logger").new("clpmgr")

-- Constants


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

-- The Module
local mod = {}

mod.excludedClassnames					= {CLIPBOARD.MARKER}				-- Data we don't want to count when copying.
mod.watcherFrequency					= 0.5

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

function mod.supportsContainedItems(data)
	local classname = mod.getClassname(data)
	return data.containedItems and classname ~= CLIPBOARD.ANCHORED_COLLECTION
end

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

function mod.writeFCPXData(fcpxData, quiet)
	--------------------------------------------------------------------------------
	-- Write data back to Clipboard:
	--------------------------------------------------------------------------------
	if quiet then mod.stopWatching() end
	local result = pasteboard.writeDataForUTI(CLIPBOARD.UTI, fcpxData)
	if quiet then mod.startWatching() end
	
	return result
end

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

function mod.startWatching()
	if mod._watchersCount < 1 then
		return
	end
	
	--------------------------------------------------------------------------------
	-- Used for debugging:
	--------------------------------------------------------------------------------
	log.d("Starting Clipboard Watcher.")

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

	log.d("Started Clipboard Watcher")
end

--------------------------------------------------------------------------------
-- STOP WATCHING THE CLIPBOARD:
--------------------------------------------------------------------------------
function mod.stopWatching()
	if mod._timer then
		mod._timer:stop()
		mod._timer = nil
		log.d("Stopped Clipboard Watcher")
	end
end

--------------------------------------------------------------------------------
-- IS THIS MODULE WATCHING THE CLIPBOARD:
-------------------------------------------------------------------------------
function mod.isWatching()
	return mod._timer ~= nil
end

-- The Plugin
local plugin = {}

plugin.dependencies = {
	["hs.fcpxhacks.plugins.commands.fcpx"]	= "fcpxCmds",
}

function plugin.init(deps)
	-- Commands
	deps.fcpxCmds:add("FCPXCopyWithCustomLabel")
		:whenActivated(mod.copyWithCustomClipName)
	
	return mod
end

return plugin