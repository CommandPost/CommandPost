--- Supports 'defrosting' a table which is made up from an 'NSKeyArchiver' record.

local mod = {}

mod.ARCHIVER_KEY 			= "$archiver"
mod.ARCHIVER_VALUE 			= "NSKeyedArchiver"

mod.OBJECTS_KEY 			= "$objects"
mod.TOP_KEY					= "$top"
mod.ROOT_KEY				= "root"

mod.CFUID					= "CF$UID"

local function checkArchiver(archive)
	return archive[mod.ARCHIVER_KEY] == mod.ARCHIVER_VALUE
end

local function isReference(data)
	return type(data) == 'table' and data[mod.CFUID] ~= nil
end

local function getReferenceID(data)
	return data[mod.CFUID]
end

--------------------------------------------------------------------------------
-- GETS THE SPECIFIED OBJECT, LOOKING UP THE REFERENCE OBJECT IF NECESSARY:
--------------------------------------------------------------------------------
local function get(data, objects, cache)
	local result = nil
	if isReference(data) then
		-- it's a reference
		local id = getReferenceID(data) + 1
		-- try getting from the cache first
		result = cache[id]
		if not result then
			-- and defrost the 'objects' record
			local object = objects[id]
			if type(object) == "table" then
				-- otherwise, we create a new cached object
				result = {}
				cache[id] = result
				for k,v in pairs(object) do
					result[k] = get(v, objects, cache)
				end
			else
				result = object
				cache[id] = result
			end
		end
	elseif type(data) == "table" then
		result = {}
		for k,v in pairs(data) do
			result[k] = get(v, objects, cache)
		end
	else
		result = data
	end
	return result
end

--- hs.plist.archiver.unarchive(archive) -> table
--- Unarchives a LUA table which was archived into a plist using the NSKeyedArchiver.
---
--- Parameters:
--- * `archive`	- the table containing the archive plist as a table
--- * `root`	- (optional) the key for the root element to unarchive. Defaults to 'root'
--- Returns:
--- * The unarchived 
function mod.unarchive(archive, root)
	if checkArchiver(archive) then
		root = root or mod.ROOT_KEY
		local objects = archive[mod.OBJECTS_KEY]
		local cache = {}
		local top = archive[mod.TOP_KEY]
		if top and top[root] then
			return get(top[root], objects, cache)
		end
	end
	return nil
end

return mod