--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--  Support libary for handling clipboard/pasteboard data.                    --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local log										= hs.logger.new("clipboard")

local plist 									= require("hs.fcpx-hacks.plister")
local protect 									= require("hs.fcpx-hacks.protect")
local pasteboard 								= require("hs.pasteboard")
local settings									= require("hs.settings")
local inspect									= require("inspect")

local CLIPBOARD = protect({
	-- Standard types
	ARRAY 										= "NSMutableArray",
	SET 										= "NSMutableSet",
	OBJECTS 									= "NS.Objects",
		
	-- FCPX Types
	ANCHORED_ANGLE 								= "FFAnchoredAngle",
	ANCHORED_COLLECTION 						= "FFAnchoredCollection",
	ANCHORED_SEQUENCE 							= "FFAnchoredSequence",
	GAP 										= "FFAnchoredGapGeneratorComponent",
	TIMERANGE_AND_OBJECT 						= "FigTimeRangeAndObject",
		
	-- The default name used when copying from the Timeline
	TIMELINE_DISPLAY_NAME 						= "__timelineContainerClip",
	
	-- The pasteboard/clipboard property containing the copied clips
	PASTEBOARD_OBJECT 							= "ffpasteboardobject",
	UTI 										= "com.apple.flexo.proFFPasteboardUTI"
})

-- Clipboard Watcher Timer
local clipboardTimer							= nil
-- Displays how many times the pasteboard owner has changed (indicates a new copy has been made)
local clipboardLastChange 						= pasteboard.changeCount()						

-- Clipboard History
local clipboardHistory							= {}

-- Clipboard Watcher Update Frequency
local clipboardWatcherFrequency 				= 0.5
-- Maximum Size of Clipboard History
local clipboardHistoryMaximumSize 				= 5

-- Hostname
local hostname									= host.localizedName()

-- Processes the provided data object, which should have a '$class' property.
-- Returns: string (primary clip name), integer (number of clips)
function processObject(data, objects)
	if data['$class'] and data['$class']['$classname'] then
		log.d("Object > $classname: "..data['$class']['$classname'])
		local class = data['$class']['$classname']
		if class == CLIPBOARD.ARRAY or class == CLIPBOARD.SET then
			return processMutableCollection(data, objects)
		elseif class == CLIPBOARD.ANCHORED_ANGLE then
			return processAnchoredAngle(data, objects)
		elseif class == CLIPBOARD.ANCHORED_COLLECTION then
			return processAnchoredCollection(data, objects)
		elseif class == CLIPBOARD.TIMERANGE_AND_OBJECT then
			return processTimeRangeAndObject(data, objects)
		end
	elseif data['CF$UID'] then
		log.d("Object > CF$UID: "..tostring(data['CF$UID']))
		log.d("CF$UID type: "..type(data['CF$UID']))
		return processObject(objects[data['CF$UID']+1], objects)
	end
	log.d("Object > ?: "..inspect(data))
	return nil, 0
end

-- Processes the 'NSMutableArray' object
-- Params:
--		* data: 	The data object to process
--		* objects:	The table of objects
-- Returns: string (primary clip name), integer (number of clips)
function processMutableCollection(data, objects)
	local name = nil
	local count = 0
	local objects = data[CLIPBOARD.OBJECTS]
	for k,v in ipairs(objects) do
		local n,c = processObject(e, objects)
		if name == nil then
			name = n
		end
		count = count + c 
	end
	return name, count
end

-- Processes 'FFAnchoredCollection' objects
-- Returns: string (primary clip name), integer (number of clips)
function processAnchoredCollection(data, objects)
	if data.displayName == CLIPBOARD.TIMELINE_DISPLAY_NAME then
		return processObject(data.containedItems, objects)
	else
		return data.displayName, processObject(data.anchoredItems, objects) + 1
	end
end

-- Processes 'FFAnchoredAngle' objects.
-- Returns: string (primary clip name), integer (number of clips)
function processAnchoredAngle(data, objects)
	return data.displayName, processObject(data.anchoredItems, objects) + 1
end

-- Process 'FFAnchoredSequence' objects
-- Returns: string (primary clip name), integer (number of clips)
function processAnchoredSequence(data, objects)
	return data.displayName, 1
end

-- Process 'FigTimeRangeAndObject' objects, typically content copied from the Browser
-- Returns: string (primary clip name), integer (number of clips)
function processTimeRangeAndObject(data, objects)
	return processObject(data.object, objects)
end

local mod = {}

-- Searches the Plist XML data for the first clip name, and returns it, along with the
-- total number of clips that have been copied.
-- Returns the 'default' value and 0 if the data could not be interpreted.
-- Example use:
--	 local name = findClipName(myXmlData, "Unknown")
function mod.findClipName(fcpxTable, default)
	
	local root = fcpxTable['$top']['root']
	local objects = fcpxTable['$objects']
	
	log.d("root: "..inspect(root))
	
	local name, count = processObject(root, objects)

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
function mod.startWatching()

	--------------------------------------------------------------------------------
	-- Used for debugging:
	--------------------------------------------------------------------------------
	--if debugMode then print("[FCPX Hacks] Starting Clipboard Watcher.") end

	--------------------------------------------------------------------------------
	-- Get Clipboard History from Settings:
	--------------------------------------------------------------------------------
	clipboardHistory = settings.get("fcpxHacks.clipboardHistory") or {}

	--------------------------------------------------------------------------------
	-- Reset:
	--------------------------------------------------------------------------------
	clipboardCurrentChange = pasteboard.changeCount()
	clipboardLastChange = pasteboard.changeCount()

	--------------------------------------------------------------------------------
	-- Watch for Clipboard Changes:
	--------------------------------------------------------------------------------
	clipboardTimer = hs.timer.new(clipboardWatcherFrequency, function()

		clipboardCurrentChange = pasteboard.changeCount()

			if (clipboardCurrentChange > clipboardLastChange) then

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

				
				log.d("Converting clipboard data from binary to a table.")
				local clipboardTable = plist.binaryToTable(currentClipboardData)
				local fcpxData = clipboardTable[CLIPBOARD.PASTEBOARD_OBJECT]
				if fcpxData then
					log.d("Converting pasteboard object from BASE64 to a table.")
					local fcpxTable = plist.base64ToTable(fcpxData)
					-- log.d("fcpxTable: "..inspect(fcpxTable))
					log.d("Finding the clip name.")
					currentClipboardLabel = mod.findClipName(fcpxTable, currentClipboardLabel)
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

							local file = io.open(sharedClipboardPath .. "/Final Cut Pro Shared Clipboard for " .. hostname, "w")
							file:write(currentClipboardData)
							file:close()

						end
					end

					--------------------------------------------------------------------------------
					-- Clipboard History:
					--------------------------------------------------------------------------------
					local currentClipboardItem = {currentClipboardData, currentClipboardLabel}

					while (#clipboardHistory >= clipboardHistoryMaximumSize) do
						table.remove(clipboardHistory,1)
					end
					table.insert(clipboardHistory, currentClipboardItem)

					--------------------------------------------------------------------------------
					-- Update Settings:
					--------------------------------------------------------------------------------
					settings.set("fcpxHacks.clipboardHistory", clipboardHistory)

					--------------------------------------------------------------------------------
					-- Refresh Menubar:
					--------------------------------------------------------------------------------
					refreshMenuBar()
				end
		 	end
			clipboardLastChange = clipboardCurrentChange
		end
	end)
	clipboardTimer:start()

end

function mod.stopWatching()
	if clipboardTimer then
		clipboardTimer:stop()
		clipboardTime = nil
	end
end

function mod.isWatching()
	return clipboardTimer or false
end

function mod.getHistory()
	return clipboardHistory
end

function mod.clearHistory()
	clipboardHistory = {}
	settings.set("fcpxHacks.clipboardHistory", clipboardHistory)
	clipboardCurrentChange = pasteboard.changeCount()
end

return mod
