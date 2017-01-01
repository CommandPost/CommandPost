--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--           P A S T E B O A R D     S U P P O R T     L I B R A R Y          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
---
--- Authors:
---
---  > David Peterson (https://randomphotons.com/)
---  > Chris Hocking (https://latenitefilms.com)
---
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------

local clipboard = {}

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------
local base64									= require("hs.base64")
local fs										= require("hs.fs")
local host										= require("hs.host")
local inspect									= require("hs.inspect")
local pasteboard 								= require("hs.pasteboard")
local plist 									= require("hs.plist")
local settings									= require("hs.settings")
local timer										= require("hs.timer")

local plist										= require("hs.plist")
local protect 									= require("hs.fcpxhacks.modules.protect")
local tools										= require("hs.fcpxhacks.modules.tools")

local log										= require("hs.logger").new("clipboard")

--------------------------------------------------------------------------------
-- LOCAL VARIABLES:
--------------------------------------------------------------------------------

clipboard.timer									= nil									-- Clipboard Watcher Timer
clipboard.watcherFrequency 						= 0.5									-- Clipboard Watcher Update Frequency
clipboard.lastChange 							= pasteboard.changeCount()				-- Displays how many times the pasteboard owner has changed (indicates a new copy has been made)
clipboard.currentChange 						= pasteboard.changeCount()				-- Current Change Count
clipboard.history								= {}									-- Clipboard History
clipboard.historyMaximumSize 					= 5										-- Maximum Size of Clipboard History
clipboard.hostname								= host.localizedName()					-- Hostname
clipboard.excludedClassnames					= {"FFAnchoredTimeMarker"}				-- Data we don't want to count when copying.

local CLIPBOARD = protect({
	--------------------------------------------------------------------------------
	-- Standard types:
	--------------------------------------------------------------------------------
	ARRAY 										= "NSMutableArray",
	SET 										= "NSMutableSet",
	OBJECTS 									= "NS.objects",

	--------------------------------------------------------------------------------
	-- Dictionary:
	--------------------------------------------------------------------------------
	DICTIONARY									= "NSDictionary",
	KEYS										= "NS.keys",
	VALUES										= "NS.objects",

	--------------------------------------------------------------------------------
	-- FCPX Types:
	--------------------------------------------------------------------------------
	ANCHORED_ANGLE 								= "FFAnchoredAngle",
	ANCHORED_COLLECTION 						= "FFAnchoredCollection",
	ANCHORED_SEQUENCE 							= "FFAnchoredSequence",
	ANCHORED_CLIP								= "FFAnchoredClip",
	GAP 										= "FFAnchoredGapGeneratorComponent",
	GENERATOR									= "FFAnchoredGeneratorComponent",
	TIMERANGE_AND_OBJECT 						= "FigTimeRangeAndObject",

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
-- GETS THE SPECIFIED OBJECT, LOOKING UP THE REFERENCE OBJECT IF NECESSARY:
--------------------------------------------------------------------------------
local function _get(data, objects)
	if type(data) == 'table' and data["CF$UID"] then
		-- it's a reference
		return objects[data["CF$UID"]+1]
	else
		return data
	end
end

--------------------------------------------------------------------------------
-- PROCESS OBJECT:
--------------------------------------------------------------------------------
-- Processes the provided data object, which should have a '$class' property.
-- Returns: string (primary clip name), integer (number of clips)
--------------------------------------------------------------------------------
function clipboard.processObject(data, objects)
	data = _get(data, objects)
	if type(data) == "table" then
		-- inspect(data) is potentially expensive, so make sure debug is on first.
		local class = _get(data['$class'], objects)
		if class then
			local classname = _get(class["$classname"], objects)
			if classname == CLIPBOARD.ARRAY or classname == CLIPBOARD.SET then
				return clipboard.processMutableCollection(data, objects)
			elseif classname == CLIPBOARD.ANCHORED_ANGLE then
				return clipboard.processAnchoredAngle(data, objects)
			elseif classname == CLIPBOARD.ANCHORED_COLLECTION then
				return clipboard.processAnchoredCollection(data, objects)
			elseif classname == CLIPBOARD.TIMERANGE_AND_OBJECT then
				return clipboard.processTimeRangeAndObject(data, objects)
			elseif classname == CLIPBOARD.DICTIONARY then
				return clipboard.processDictionary(data, objects)
			elseif classname == CLIPBOARD.GAP then
				return clipboard.processGap(data, objects)
			elseif classname == CLIPBOARD.GENERATOR then
				return clipboard.processGenerator(data, objects)
			elseif clipboard.isClassnameSupported(classname) then
				return clipboard.processSimpleContent(data, objects)
			end
			if log.getLogLevel() >= 4 then
				log.d("Unsupported classname: "..classname)
				-- log.d("Object:\n"..inspect(data))
			end
		end
	end
	return nil, 0
end

function clipboard.isClassnameSupported(classname)
	for i,name in ipairs(clipboard.excludedClassnames) do
		if name == classname then
			return false
		end
	end
	return true
end

--------------------------------------------------------------------------------
-- PROCESS MUTABLE COLLECTION:
--------------------------------------------------------------------------------
-- Processes the 'NSDictionary' object
-- Params:
--		* data: 	The data object to process
--		* objects:	The table of objects
-- Returns: string (primary clip name), integer (number of clips)
--------------------------------------------------------------------------------
function clipboard.processMutableCollection(data, objects)
	local name = nil
	local count = 0
	local obs = _get(data[CLIPBOARD.OBJECTS], objects)
	for k,v in ipairs(obs) do
		log.d("processing item #"..k)
		v = _get(v, objects)
		local n,c = clipboard.processObject(v, objects)
		if name == nil then
			name = n
		end
		count = count + c
	end
	return name, count
end

--------------------------------------------------------------------------------
-- PROCESS DICTIONARY:
--------------------------------------------------------------------------------
-- Processes the 'NSMutableArray' object
-- Params:
--		* data: 	The data object to process
--		* objects:	The table of objects
-- Returns: string (primary clip name), integer (number of clips)
--------------------------------------------------------------------------------
function clipboard.processDictionary(data, objects)
	local name = nil
	local count = 0

	local keys = _get(data[CLIPBOARD.KEYS], objects)
	local values = _get(data[CLIPBOARD.VALUES], objects)

	for i,key in ipairs(keys) do
		key = _get(key, objects)
		local value = _get(values[i], objects)

		if key == "objects" then
			local n,c = clipboard.processObject(value, objects)
			if name == nil then
				name = n
			end
			count = count + c
		end
	end
	return name, count
end

--------------------------------------------------------------------------------
-- PROCESS ANCHORED COLLECTION:
--------------------------------------------------------------------------------
-- Processes 'FFAnchoredCollection' objects
-- Returns: string (primary clip name), integer (number of clips)
--------------------------------------------------------------------------------
function clipboard.processAnchoredCollection(data, objects)
	local displayName = _get(data.displayName, objects)
	if displayName == CLIPBOARD.TIMELINE_DISPLAY_NAME then
		log.d("Processing a copy from the Timeline")
		return clipboard.processObject(data.containedItems, objects)
	else
		local _, count = clipboard.processObject(data.anchoredItems, objects)
		return displayName, count + 1
	end
end

--------------------------------------------------------------------------------
-- PROCESS GAP:
--------------------------------------------------------------------------------
-- Processes 'FFAnchoredGapGeneratorComponent' objects
-- Returns: string (primary clip name), integer (number of clips)
--------------------------------------------------------------------------------
function clipboard.processGap(data, objects)
	local displayName = _get(data.displayName, objects)
	local count = 0
	if data.anchoredItems then
		displayName, count = clipboard.processObject(data.anchoredItems, objects)
	end
	return displayName, count
end

--------------------------------------------------------------------------------
-- PROCESS GENERATOR:
--------------------------------------------------------------------------------
-- Processes 'FFAnchoredGeneratorComponent' objects
-- Returns: string (primary clip name), integer (number of clips)
--------------------------------------------------------------------------------
function clipboard.processGenerator(data, objects)
	local displayName = _get(data.displayName, objects)
	local count = 1
	if data.anchoredItems then
		local n, c = clipboard.processObject(data.anchoredItems, objects)
		displayName = displayName or n
		count = count + c
	end
	return displayName, count
end

--------------------------------------------------------------------------------
-- PROCESS ANCHORED ANGLE:
--------------------------------------------------------------------------------
-- Processes 'FFAnchoredAngle' objects.
-- Returns: string (primary clip name), integer (number of clips)
--------------------------------------------------------------------------------
function clipboard.processAnchoredAngle(data, objects)
	local _, count = clipboard.processObject(data.anchoredItems, objects)
	return _get(data.displayName, objects), count + 1
end

--------------------------------------------------------------------------------
-- PROCESS SIMPLE CONTENT:
--------------------------------------------------------------------------------
-- Process objects which have a displayName, such as Compound Clips, Images, etc.
-- Returns: string (primary clip name), integer (number of clips)
--------------------------------------------------------------------------------
function clipboard.processSimpleContent(data, objects)
	local displayName = _get(data.displayName, objects)
	if displayName then
		return displayName, 1
	else
		return nil, 0
	end
end

--------------------------------------------------------------------------------
-- PROCESS TIME RANGE AND OBJECT:
--------------------------------------------------------------------------------
-- Process 'FigTimeRangeAndObject' objects, typically content copied from the Browser
-- Returns: string (primary clip name), integer (number of clips)
--------------------------------------------------------------------------------
function clipboard.processTimeRangeAndObject(data, objects)
	return clipboard.processObject(data.object, objects)
end

--------------------------------------------------------------------------------
-- FIND CLIP NAME:
--------------------------------------------------------------------------------
-- Searches the Plist XML data for the first clip name, and returns it, along with the
-- total number of clips that have been copied.
-- Returns the 'default' value and 0 if the data could not be interpreted.
-- Example use:
--	 local name = findClipName(myXmlData, "Unknown")
--------------------------------------------------------------------------------
function clipboard.findClipName(fcpxTable, default)

	local top = fcpxTable['$top']
	local objects = fcpxTable['$objects']

	local name, count = clipboard.processObject(top.root, objects)

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

--------------------------------------------------------------------------------
-- WATCH THE FINAL CUT PRO CLIPBOARD FOR CHANGES:
--------------------------------------------------------------------------------
function clipboard.startWatching()

	--------------------------------------------------------------------------------
	-- Used for debugging:
	--------------------------------------------------------------------------------
	log.d("Starting Clipboard Watcher.")

	--------------------------------------------------------------------------------
	-- Get Clipboard History from Settings:
	--------------------------------------------------------------------------------
	clipboard.history = settings.get("fcpxHacks.clipboardHistory") or {}

	--------------------------------------------------------------------------------
	-- Reset:
	--------------------------------------------------------------------------------
	clipboard.currentChange = pasteboard.changeCount()
	clipboard.lastChange = pasteboard.changeCount()

	--------------------------------------------------------------------------------
	-- Watch for Clipboard Changes:
	--------------------------------------------------------------------------------
	clipboard.timer = timer.new(clipboard.watcherFrequency, function()

		clipboard.currentChange = pasteboard.changeCount()

			if (clipboard.currentChange > clipboard.lastChange) then

		 	local clipboardContent = pasteboard.allContentTypes()
		 	if clipboardContent[1][1] == CLIPBOARD.UTI then

				--------------------------------------------------------------------------------
				-- Set Up Variables:
				--------------------------------------------------------------------------------
				local addToClipboardHistory 	= true

				--------------------------------------------------------------------------------
				-- Save Clipboard Data:
				--------------------------------------------------------------------------------
				local currentClipboardData 		= pasteboard.readDataForUTI(CLIPBOARD.UTI)
				local currentClipboardLabel 	= os.date()


				local clipboardTable = plist.binaryToTable(currentClipboardData)
				local fcpxData = clipboardTable[CLIPBOARD.PASTEBOARD_OBJECT]
				if fcpxData then
					local fcpxTable = plist.base64ToTable(fcpxData)
					currentClipboardLabel = clipboard.findClipName(fcpxTable, currentClipboardLabel)
				else
					log.e("The clipboard does not contain any data.")
					addToClipboardHistory = false
				end

				--------------------------------------------------------------------------------
				-- If all is good then...
				--------------------------------------------------------------------------------
				if addToClipboardHistory then

					--------------------------------------------------------------------------------
					-- Used for debugging:
					--------------------------------------------------------------------------------
					log.d("Added '"..currentClipboardLabel.."' to FCPX's Clipboard.")

					--------------------------------------------------------------------------------
					-- Shared Clipboard:
					--------------------------------------------------------------------------------
					local enableSharedClipboard = settings.get("fcpxHacks.enableSharedClipboard")
					if enableSharedClipboard then
						local sharedClipboardPath = settings.get("fcpxHacks.sharedClipboardPath")
						if sharedClipboardPath ~= nil then

							local sharedClipboardPlistFile = sharedClipboardPath .. clipboard.hostname .. ".fcpxhacks"

							--------------------------------------------------------------------------------
							-- Create Plist file if one doesn't already exist:
							--------------------------------------------------------------------------------
							if not tools.doesFileExist(sharedClipboardPlistFile) then

								log.d("Creating new Shared Clipboard Plist File.")

local blankPlist = [[
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>SharedClipboardLabel1</key>
	<string></string>
	<key>SharedClipboardLabel2</key>
	<string></string>
	<key>SharedClipboardLabel3</key>
	<string></string>
	<key>SharedClipboardLabel4</key>
	<string></string>
	<key>SharedClipboardLabel5</key>
	<string></string>
	<key>SharedClipboardData1</key>
	<string></string>
	<key>SharedClipboardData2</key>
	<string></string>
	<key>SharedClipboardData3</key>
	<string></string>
	<key>SharedClipboardData4</key>
	<string></string>
	<key>SharedClipboardData5</key>
	<string></string>
</dict>
</plist>
]]

								local file = io.open(sharedClipboardPlistFile, "w")
								file:write(blankPlist)
								file:close()

							end

							--------------------------------------------------------------------------------
							-- Reading Plist file:
							--------------------------------------------------------------------------------
							if tools.doesFileExist(sharedClipboardPlistFile) then
								local plistData = plist.xmlFileToTable(sharedClipboardPlistFile)
								if plistData ~= nil then

									encodedCurrentClipboardData = base64.encode(currentClipboardData)

									local newPlistData = {}
									newPlistData["SharedClipboardLabel1"] = currentClipboardLabel
									newPlistData["SharedClipboardData1"] = encodedCurrentClipboardData
									newPlistData["SharedClipboardLabel2"] = plistData["SharedClipboardLabel1"]
									newPlistData["SharedClipboardData2"] = plistData["SharedClipboardData1"]
									newPlistData["SharedClipboardLabel3"] = plistData["SharedClipboardLabel2"]
									newPlistData["SharedClipboardData3"] = plistData["SharedClipboardData2"]
									newPlistData["SharedClipboardLabel4"] = plistData["SharedClipboardLabel3"]
									newPlistData["SharedClipboardData4"] = plistData["SharedClipboardData3"]
									newPlistData["SharedClipboardLabel5"] = plistData["SharedClipboardLabel4"]
									newPlistData["SharedClipboardData5"] = plistData["SharedClipboardData4"]


local newPlist = [[
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>SharedClipboardLabel1</key>
	<string>]] .. newPlistData["SharedClipboardLabel1"] .. [[</string>
	<key>SharedClipboardLabel2</key>
	<string>]] .. newPlistData["SharedClipboardLabel2"] .. [[</string>
	<key>SharedClipboardLabel3</key>
	<string>]] .. newPlistData["SharedClipboardLabel3"] .. [[</string>
	<key>SharedClipboardLabel4</key>
	<string>]] .. newPlistData["SharedClipboardLabel4"] .. [[</string>
	<key>SharedClipboardLabel5</key>
	<string>]] .. newPlistData["SharedClipboardLabel5"] .. [[</string>
	<key>SharedClipboardData1</key>
	<string>]] .. newPlistData["SharedClipboardData1"] .. [[</string>
	<key>SharedClipboardData2</key>
	<string>]] .. newPlistData["SharedClipboardData2"] .. [[</string>
	<key>SharedClipboardData3</key>
	<string>]] .. newPlistData["SharedClipboardData3"] .. [[</string>
	<key>SharedClipboardData4</key>
	<string>]] .. newPlistData["SharedClipboardData4"] .. [[</string>
	<key>SharedClipboardData5</key>
	<string>]] .. newPlistData["SharedClipboardData5"] .. [[</string>
</dict>
</plist>
]]

									local file = io.open(sharedClipboardPlistFile, "w")
									file:write(newPlist)
									file:close()

								else
									log.e("Failed to read Shared Clipboard Plist File.")
								end

							else
								log.e("Shared Clipboard Plist File doesn't appear to exist.")
							end

						end
					end

					--------------------------------------------------------------------------------
					-- Clipboard History:
					--------------------------------------------------------------------------------
					local currentClipboardItem = {currentClipboardData, currentClipboardLabel}

					while (#(clipboard.history) >= clipboard.historyMaximumSize) do
						table.remove(clipboard.history,1)
					end
					table.insert(clipboard.history, currentClipboardItem)

					--------------------------------------------------------------------------------
					-- Update Settings:
					--------------------------------------------------------------------------------
					settings.set("fcpxHacks.clipboardHistory", clipboard.history)

					--------------------------------------------------------------------------------
					-- Refresh Menubar:
					--------------------------------------------------------------------------------
					refreshMenuBar()
				end
		 	end
			clipboard.lastChange = clipboard.currentChange
		end
	end)
	clipboard.timer:start()

end

--------------------------------------------------------------------------------
-- STOP WATCHING THE CLIPBOARD:
--------------------------------------------------------------------------------
function clipboard.stopWatching()
	if clipboard.timer then
		clipboard.timer:stop()
		clipboard.timer = nil
	end
end

--------------------------------------------------------------------------------
-- IS THIS MODULE WATCHING THE CLIPBOARD:
-------------------------------------------------------------------------------
function clipboard.isWatching()
	return clipboard.timer or false
end

--------------------------------------------------------------------------------
-- GET CLIPBOARD HISTORY:
--------------------------------------------------------------------------------
function clipboard.getHistory()
	return clipboard.history
end

--------------------------------------------------------------------------------
-- CLEAR CLIPBOARD HISTORY:
--------------------------------------------------------------------------------
function clipboard.clearHistory()
	clipboard.history = {}
	settings.set("fcpxHacks.clipboardHistory", clipboard.history)
	clipboard.currentChange = pasteboard.changeCount()
end

return clipboard
