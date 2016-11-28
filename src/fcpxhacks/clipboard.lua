--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--  Support libary for handling clipboard/pasteboard data.                    --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


local plistParse = require("fcpxhacks.plistParse")
local protect = require("fcpxhacks.protect")

local CLIPBOARD = protect({
	-- Standard types
	ARRAY = "NSMutableArray",
	SET = "NSMutableSet",
		
	-- FCPX Types
	ANCHORED_ANGLE = "FFAnchoredAngle",
	ANCHORED_COLLECTION = "FFAnchoredCollection",
	ANCHORED_SEQUENCE = "FFAnchoredSequence",
	GAP = "FFAnchoredGapGeneratorComponent",
	TIMERANGE_AND_OBJECT = "FigTimeRangeAndObject",
		
	-- The default name used when copying from the Timeline
	TIMELINE_DISPLAY_NAME = "__timelineContainerClip"
})

function parseRoot(xmlData)
	local data = plistParse(xmlData)
	local options = {
		depth = 7,
		include = [],
		exclude = []
	}
	return lookup(data['$top'].root, data['$objects'], options.depth, options)
end

function lookup(value, objects, depth, options)
  if (Array.isArray(value)) then
    local result = []
    for i,v in ipairs(value) do
      result[i] = lookup(v, objects, depth, options)
		end
    return result
	end
  if value and typeof value == 'table' then
    if value['CF$UID'] != undefined and depth > 0 then
      local result = lookup(objects[value['CF$UID']], objects, depth-1, options)
      result._UID = value['CF$UID']
      return result
		end
    
    local result = {}
    for local key,value in pairs(value) do
      if ((!options.include or options.include.indexOf(key) >= 0) and (!options.exclude or options.exclude.indexOf(key) == -1)) then
        result[key] = lookup(value[key], objects, depth, options)
			end
		end
    return result
	end
  
  return value
end

-- Processes the provided data object, which should have a '$class' property.
-- Returns: string (primary clip name), integer (number of clips)
function processObject(data)
	if data['$class'] and data['$classname'] then
		local class = data['$class']['$classname']
		if class == "NSMutableArray" or class == "NSMutableSet" then
			return processMutableCollection(data)
		elseif class == CLIPBOARD.ANCHORED_ANGLE then
			return processAnchoredAngle(data)
		elseif class == CLIPBOARD.ANCHORED_COLLECTION then
			return processAnchoredCollection(data)
		elseif class == CLIPBOARD.TIMERANGE_AND_OBJECT then
			return processTimeRangeAndObject(data)
		end
	end
	return nil, 0
end

-- Processes the 'NSMutableArray' object
-- Returns: string (primary clip name), integer (number of clips)
function processMutableCollection(data)
	local name = nil, count = 0
	local objects = data['NS.Objects']
	for k,v in ipairs(objects) do
		local n,c = processObject(e)
		if name == nil then
			name = n
		end
		count += c
	end
	return name, count
end

-- Processes 'FFAnchoredCollection' objects
-- Returns: string (primary clip name), integer (number of clips)
function processAnchoredCollection(data)
	if data.displayName == CLIPBOARD.TIMELINE_DISPLAY_NAME then
		return processObject(data.containedItems)
	else
		return data.displayName, processObject(data.anchoredItems) + 1
	end
end

-- Processes 'FFAnchoredAngle' objects.
-- Returns: string (primary clip name), integer (number of clips)
function processAnchoredAngle(data)
	return data.displayName, processObject(data.anchoredItems) + 1
end

-- Process 'FFAnchoredSequence' objects
-- Returns: string (primary clip name), integer (number of clips)
function processAnchoredSequence(data)
	return data.displayName, 1
end

-- Process 'FigTimeRangeAndObject' objects, typically content copied from the Browser
-- Returns: string (primary clip name), integer (number of clips)
function processTimeRangeAndObject(data)
	return processObject(data.object)
end

local mod = {}

-- Searches the Plist XML data for the first clip name, and returns it, along with the
-- total number of clips that have been copied.
-- Returns the 'default' value and 0 if the data could not be interpreted.
-- Example use:
--   local name,count = findClipName(myXmlData, "Unknown")
function mod.findClipName(xmlData, default)
	local root = parseRoot(xmlData)
	local name, count = processObject(root)

	if name then
		return name, count
	else
		return default, 0
	end
end

return mod
