--- === cp.plist.archiver ===
---
--- Supports 'defrosting' a table which is made up from an 'NSKeyArchiver' record.

local require = require

local plist	= require("cp.plist")


local mod = {}

-- TODO: Add Documentation
mod.ARCHIVER_KEY = "$archiver"

-- TODO: Add Documentation
mod.ARCHIVER_VALUE = "NSKeyedArchiver"

-- The objects definition
mod.OBJECTS_KEY = "$objects"

-- The key of the top-level object.
mod.TOP_KEY	= "$top"

-- The key when referencing another object
mod.CFUID	= "CF$UID"

-- checkArchiver(archive) -> boolean
-- Function
-- Checks if the given `archive` is an archiver.
--
-- Parameters:
--  * archive - The archive to check.
--
-- Returns:
--  * `true` if the `archive` is an archiver, `false` otherwise.
local function checkArchiver(archive)
    return archive[mod.ARCHIVER_KEY] == mod.ARCHIVER_VALUE
end

-- isReference(data) -> boolean
-- Function
-- Checks if the given `data` is a reference object (ie. it is a `table` with a `CF$UID` key).
--
-- Parameters:
--  * data - The data to check.
--
-- Returns:
--  * `true` if the `data` is a reference object, `false` otherwise.
local function isReference(data)
    return type(data) == 'table' and data[mod.CFUID] ~= nil
end

-- getReferenceID(data) -> number
-- Function
-- Gets the reference ID of the given `data` table.
--
-- Parameters:
--  * data - The data to check.
--
-- Returns:

local function getReferenceID(data)
    return data[mod.CFUID]
end

-- defrostClass(data, defrostFn) -> table
-- Function
-- Defrosts the given `data` table using the given `defrostFn` (if provided).
--
-- Parameters:
--  * data - The data to defrost.
--  * defrostFn - The defrost function to use. (optional)
--
-- Returns:
--  * The defrosted data.
--
-- Notes:
-- * If the `defrostFn` is not provided, it will still support some basic classnames:
--   * `NSArray`/`NSMutableArray`
--   * `NSDictionary`/`NSMutableDictionary`
--   * `NSSet`/`NSMutableSet`
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

-- get(data, objects, cache, defrostFn) -> table
-- Function
-- Gets the specified object from the given `data` table, using the given `objects` table and `cache` table if required.
--
-- Parameters:
--  * data - The data `table` to get the object from.
--  * objects - The list of objects stored in the plist
--  * cache - The cache of defrosted objects we've already processed.
--  * defrostFn - The defrost function to use. (optional)
--
-- Returns:
--  * The object `table`.
local function get(data, objects, cache, defrostFn)
    local result
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

--- cp.plist.archiver.unarchiveBase64(base64data, defrostFn) -> table
--- Function
--- Unarchives a Base64 encoded `string` which was archived into a plist using the `NSKeyedArchiver`.
---
--- Parameters:
---  * `base64data`	- the file containing the archive plist
---  * `defrostFn`	- (optional) a function which will be passed an object with a `'$class'` entry
---
--- Returns:
---  * The unarchived plist.
---
--- Notes:
---  * A 'defrost' function can be provided, which will be called whenever a table with a `'$class'`
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
