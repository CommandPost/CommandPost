--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                            P L I S T    T O O L S                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.plist.archiver ===
---
--- Supports 'defrosting' a table which is made up from an 'NSKeyArchiver' record.

local plist					= require("cp.plist")

local mod = {}

mod.ARCHIVER_KEY 			= "$archiver"
mod.ARCHIVER_VALUE 			= "NSKeyedArchiver"

mod.OBJECTS_KEY 			= "$objects"
mod.TOP_KEY					= "$top"

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

local function defrostClass(data, defrostFn)
	if data["$class"] then
		local classname = data["$class"]["$classname"]
		-- check if a defrost function was provided
		if type(defrostFn) == "function" then
			local result = defrostFn(data, classname)
			if result then
				return result
			end
		end
		-- if not handled then manage some of the basic types.
		if classname == "NSMutableDictionary" or classname == "NSDictionary" then
			local keys = data["NS.keys"]
			local values = data["NS.objects"]
			local dict = {}
			for i,k in ipairs(keys) do
				dict[k] = values[i]
			end
			return dict
		elseif classname == "NSMutableArray" or classname == "NSArray" then
			return data["NS.objects"]
		elseif classname == "NSMutableSet" or classname == "NSSet" then
			return data["NS.objects"]
		end
	end
	return data
end

--------------------------------------------------------------------------------
-- GETS THE SPECIFIED OBJECT, LOOKING UP THE REFERENCE OBJECT IF NECESSARY:
--------------------------------------------------------------------------------
local function get(data, objects, cache, defrostFn)
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
					result[k] = get(v, objects, cache, defrostFn)
				end
				result = defrostClass(result, defrostFn)
				cache[id] = result
			else
				result = object
				cache[id] = result
			end
		end
	elseif type(data) == "table" then
		result = {}
		for k,v in pairs(data) do
			result[k] = get(v, objects, cache, defrostFn)
		end
		result = defrostClass(result, defrostFn)
	else
		result = data
	end
	return result
end

--- cp.plist.archiver.unarchive(archive, defrostFn) -> table
--- Function
--- Unarchives a LUA table which was archived into a plist using the NSKeyedArchiver.
---
--- Parameters:
---  * `archive`		- the table containing the archive plist as a table
---  * `defrostFn`	- (optional) a function which will be passed an object with a '$class' entry
---
--- Returns:
---  * The unarchived plist table
---
--- Notes:
---  * A 'defrost' function can be provided, which will be called whenever a table with a '$class'
---    structure is present. It will receive the table and the classname and should either return a modified value
---    if the class was handled, or `nil` if it was unable to handle the class. Eg:
---
---    ```
---    local result = archiver.unarchive(archiveData, function(frozen, classname)
--- 	   if classname == "XXMyClass" then
--- 		   return MyClass:new(frozen.foo, frozen.bar)
--- 	   end
---		   return nil
---    end)
---    ```
function mod.unarchive(archive, defrostFn)
	if checkArchiver(archive) then
		local objects = archive[mod.OBJECTS_KEY]
		local cache = {}
		local top = archive[mod.TOP_KEY]
		if top then
			return get(top, objects, cache, defrostFn)
		end
	else
		return nil, string.format("The archive was not archived by %s", mod.ARCHIVER_VALUE)
	end
end


--- cp.plist.archiver.unarchiveFile(filename, defrostFn) -> table
--- Function
--- Unarchives a plist file which was archived into a plist using the NSKeyedArchiver.
---
--- Parameters:
---  * `base64data`	- the file containing the archive plist
---  * `defrostFn`	- (optional) a function which will be passed an object with a '$class' entry
---
--- Returns:
---  * The unarchived plist.
---
--- Notes:
---  * A 'defrost' function can be provided, which will be called whenever a table with a '$class'
---    structure is present. It will receive the table and the classname and should either return a modified value
---    if the class was handled, or `nil` if it was unable to handle the class. Eg:
---
---    ```
---    local result = archiver.unarchiveFile(filename, function(frozen, classname)
--- 	   if classname == "XXMyClass" then
--- 		   return MyClass:new(frozen.foo, frozen.bar)
--- 	   end
---		   return nil
---    end)
---    ```
function mod.unarchiveBase64(base64data, defrostFn)
	local archive, err = plist.base64ToTable(base64data)
	if archive then
		return mod.unarchive(archive, defrostFn)
	else
		return nil, err
	end
end

--- cp.plist.archiver.unarchiveFile(filename, defrostFn) -> table
--- Function
--- Unarchives a plist file which was archived into a plist using the NSKeyedArchiver.
---
--- Parameters:
---  * `filename`	- the file containing the archive plist
---  * `defrostFn`	- (optional) a function which will be passed an object with a '$class' entry
---
--- Returns:
---  * The unarchived plist.
---
--- Notes:
---  * A 'defrost' function can be provided, which will be called whenever a table with a '$class'
---    structure is present. It will receive the table and the classname and should either return a modified value
---    if the class was handled, or `nil` if it was unable to handle the class. Eg:
---
---    ```
---    local result = archiver.unarchiveFile(filename, function(frozen, classname)
--- 	   if classname == "XXMyClass" then
--- 		   return MyClass:new(frozen.foo, frozen.bar)
--- 	   end
---		   return nil
---    end)
---    ```
function mod.unarchiveFile(filename, defrostFn)
	local archive, err = plist.fileToTable(filename)
	if archive then
		return mod.unarchive(archive, defrostFn)
	else
		return nil, err
	end
end

return mod