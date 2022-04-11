--- === cp.nib ===
---
--- Provides support for NIB files.

--- === cp.nib.archiver ===
---
--- Provides support for loading NIB files stored in the `NIBArchive` format.

local require                               = require

local log                                   = require "hs.logger" .new "nibarch"
local bytes                                 = require "hs.bytes"
local fs                                    = require "hs.fs"

local Array                                 = require "cp.nib.decoder.Array"
local Dictionary                            = require "cp.nib.decoder.Dictionary"
local Set                                   = require "cp.nib.decoder.Set"
local varint                                = require "cp.nib.varint"

local exactly                               = bytes.exactly
local uint8, uint32le                       = bytes.uint8, bytes.uint32le
local int8, int16le, int32le, int64le       = bytes.int8, bytes.int16le, bytes.int32le, bytes.int64le
local float32le, float64le                  = bytes.float32le, bytes.float64le

local format                                = string.format
local insert                                = table.insert


local VALUE_HANDLERS = {
    [0] = int8,
    [1] = int16le,
    [2] = int32le,
    [3] = int64le,
    [4] = function(_, index) return true, index end,
    [5] = function(_, index) return false, index end,
    [6] = float32le,
    [7] = float64le,
    [8] = function(data, index)
        local length
        length, index = bytes.read(data, index, varint)
        return bytes.read(data, index, exactly(length))
    end,
    [9] = function(_, index) return nil, index end,
    [10] = int32le, -- object table index
}

--- cp.nib.archiver.defaultDecoders() -> decoder, ...
--- Function
--- Returns the default decoders.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The default decoders.
local function defaultDecoders()
    return Array, Dictionary, Set
end

-- newArchiveHeader(objectCount, objectStart, keyCount, keyStart, valueCount, valueStart, classCount, classStart) -> table
-- Function
-- Creates an `NIBArchive` header table.
--
-- Parameters:
--  * objectCount - The number of objects in the archive.
--  * objectStart - The offset of the first object.
--  * keyCount - The number of keys in the archive.
--  * keyStart - The offset of the first key.
--  * valueCount - The number of values in the archive.
--  * valueStart - The offset of the first value.
--  * classCount - The number of classes in the archive.
--  * classStart - The offset of the first class.
--
-- Returns:
--  * A `table` with the above contained as keys, with starting indexes incremented by `1` for use in `1`-based arrays.
local function newArchiveHeader(objectCount, objectStart, keyCount, keyStart, valueCount, valueStart, classCount, classStart)
    return {
        objectCount = objectCount,
        objectStart = objectStart+1,
        keyCount = keyCount,
        keyStart = keyStart+1,
        valueCount = valueCount,
        valueStart = valueStart+1,
        classCount = classCount,
        classStart = classStart+1,
    }
end

-- processKeys(data, keyCount, firstKey) -> table
-- Function
-- Processes the given `data` string, with the specified key count and offset.
-- All key records are processed and added to the `key` table.
--
-- Parameters:
--  * data - The `string` of bytes to process.
--  * header - The archive header `table`.
--
-- Returns:
--  * A `1`-based table containing the processed `key` table.
--
-- Notes:
--  * Each key in the data stream is the following sequence of bytes:
--    * Key name length, as a `varint`.
--    * Key name, as a `string`, with the length specified by the previous `varint`.
local function processKeys(data, header)
    local keys = {}
    local index = header.keyStart
    for _ = 1, header.keyCount do
        local keyLength, key
        keyLength, index = bytes.read(data, index, varint)
        key, index = bytes.read(data, index, exactly(keyLength))
        insert(keys, key)
    end
    return keys
end

-- processValues(data, header, keys) -> table
-- Function
-- Processes the given `data` string, given the `valueCount` and `firstValue` in the `header` table.
-- It uses the `keys` table to lookup the key for each value.
-- All value records are processed and added to the `values` table.
--
-- Parameters:
--  * data - The `string` of bytes to process.
--  * header - The archive header `table`.
--  * keys - The keys table.
--
-- Returns:
--  * A `1`-based table containing the processed `values` table, each with the following properties:
--    * `key` - The key for the value.
--    * `type` - The type of the value.
--    * `value` - The value.
local function processValues(data, header, keys)
    local values = {}
    local index = header.valueStart
    for i = 1, header.valueCount do
        local keyIndex, key, valueType, valueHandler, value

        keyIndex, valueType, index = bytes.read(data, index, varint, uint8)
        key = keys[keyIndex+1]
        if not key then
            return nil, format("Invalid key index: %d for value #%d", keyIndex, i)
        end

        valueHandler = VALUE_HANDLERS[valueType]
        if not valueHandler then
            return nil, format("Unknown value type: %d for value #%d", valueType, i)
        end
        value, index = bytes.read(data, index, valueHandler)

        insert(values, {
            key = key,
            type = valueType,
            value = value,
        })
    end
    return values
end

-- processClasses(data, classCount, firstClass) -> table
-- Function
-- Processes the given `data` string, with the specified class count and offset.
-- All class records are processed and added to the `class` table.
--
-- Parameters:
--  * data - The `string` of bytes to process.
--  * classCount - The number of classes in the archive.
--  * firstClass - The offset of the first class.
--
-- Returns:
--  * A table containing the processed `class` table.
--
-- Notes:
--  * Each class record is the following sequence of bytes:
--    * The class name length, as a `varint`.
--    * Number of extra int32 LE values, as a `varint`. Only values `0` and `1` have been observed.
--    * The extra int32 LE values (if present)
--    * The class name, as a `string`, with the length specified by the class name length `varint`.
local function processClasses(data, classCount, firstClass)
    -- log.df("processClasses")
    local classes = {}
    local index = firstClass
    for _ = 1, classCount do
        local classnameLength, extraInt32leCount, extraInts, classname
        classnameLength, extraInt32leCount, index = bytes.read(data, index, varint, varint)
        extraInts = {}
        for j = 1, extraInt32leCount do
            extraInts[j], index = bytes.read(data, index, int32le)
        end
        classname, index = bytes.read(data, index, exactly(classnameLength))
        insert(classes, {
            classname = classname,
            extraInts = extraInts,
        })
    end
    return classes
end

-- processObjects(data, header, classes, values[, defrostFn]) -> table | nil, string
-- Function
-- Process the given data string, given the `objectCount` and `firstObject` in the `header` table.
-- It uses the `classes` and `values` tables to lookup the class and values for each object.
-- If provided, the `defrostFn` is passed the empty instance table, the class table, and the values for the object, as a list.
--
-- Parameters:
--  * data - The `string` of bytes to process.
--  * header - The archive header `table`.
--  * classes - The classes table.
--  * values - The values table.
--  * defrostFn - A function to call for each object, with the empty instance table, class table, and values table as parameters.
--
-- Returns:
--  * If successful, a `1`-based table containing the processed `objects` table.
--  * If unsuccessful, `nil` followed by a `string` containing the error message.
local function processObjects(data, header, classes, values)
    local objects = {}
    local index = header.firstObject
    for i = 1, header.objectCount do
        local classIndex, valuesIndex, valuesCount
        classIndex, valuesIndex, valuesCount, index = bytes.read(data, index, varint, varint, varint)

        local class = classes[classIndex+1]
        if not class then
            return nil, format("Invalid class index: %d for object #%d", classIndex, i)
        end

        local instanceValues = {}
        for j = 1, valuesCount do
            local value = values[valuesIndex+j]
            if not value then
                return nil, format("Invalid value index: %d for object #%d", valuesIndex, i)
            end
            insert(instanceValues, value)
        end

        local instance = {}
        objects[i] = instance
    end
    return objects
end

-- findClass(archive, index) -> table
-- Function
-- Finds the class with the given index in the given archive.
--
-- Parameters:
--  * archive - The `NIBArchive` table.
--  * index - The 0-based index of the class to find.
--
-- Returns:
--  * The class `table`, or `nil` if the class was not found.
local function findClass(archive, index)
    return archive.class[index]
end

-- findKey(archive, index) -> string
-- Function
-- Finds the key with the given index in the given archive.
--
-- Parameters:
--  * archive - The `NIBArchive` table.
--  * index - The 0-based index of the key to find.
--
-- Returns:
--  * The key `string`, or `nil` if the key was not found.
local function findKey(archive, index)
    return archive.key[index]
end

-- loadValues(archive, instance, valueStart, valueCount) -> nil
-- Function
-- Loads the values for the given instance into the given archive.
--
-- Parameters:
--  * archive - The `NIBArchive` table.
--  * instance - The instance to assign the values to.
--  * valueStart - The 0-based offset of the first value.
--  * valueCount - The number of values to load.
--
-- Returns:
--  * Nothing
local function loadValues(archive, instance, valueStart, valueCount)
    -- log.df("loadValues")
    local values = archive.value
    for i = 1, valueCount do
        local value = archive.value[valueStart+i]
        local key = findKey(archive, value.keyIndex)
        if value.valueType == 10 then
            -- TODO: Complete or delete this function
            -- instance[key] = nil
        end
    end
end

-- defrost(archive, cache)
-- Function
-- Defrosts the given `archive` table, storing objects into the `cache` table at the same index as they appear in the `archive.object` list.
--
-- Parameters:
--  * archive - The `NIBArchive` table to defrost.
--  * cache - The `table` to store the defrosted objects in.
--
-- Returns:
--  * The `cache` table.
local function defrost(archive, cache)
    -- log.df("defrost")
    for i, object in ipairs(archive.object) do
        -- log.df("defrosting object %d", i)
        local class = findClass(archive, object.classIndex)
        local instance = {
            classname = class.classname
        }
        loadValues(archive, instance, object.valueStart, object.valueCount)
    end
    return cache
end

-- The index where the NIBArchive header starts
local HEADER_INDEX = 1 + 10 + 4 + 4

local mod = {}
mod.mt = {}
mod.mt.__index = mod.mt

--- cp.nib.archiver.SIGNATURE -> string
--- Constant
--- Marks the data stream as an `NIBArchive`.
mod.SIGNATURE = "NIBArchive"

--- cp.nib.archiver.isSupported(data) -> boolean
--- Function
--- Checks if the given `data` is an NIBArchive.
---
--- Parameters:
---  * data - The data to check.
---
--- Returns:
---  * `true` if the `data` is an NIBArchive, `false` otherwise.
function mod.isSupported(data)
    local value, major, minor = bytes.read(data, bytes.exactly(10), int32le, int32le)
    return value == mod.SIGNATURE and major == 1 and minor >= 9
end

--- cp.nib.archiver.new(decoders) -> cp.nib.archiver
--- Constructor
--- Creates a new `cp.nib.archiver` instance, with the specified list of `decoders`.
---
--- Parameters:
---  * decoders - The list of `cp.nib.decoder` functions to use.
---
--- Returns:
---  * The new `cp.nib.archiver` instance.
function mod.new(decoders)
    local self = setmetatable({}, mod.mt)
    self.decoders = decoders
    return self
end

--- cp.nib.archiver:fromBytes(data) -> table | nil, string
--- Method
--- Unarchives the given `string` of bytes into a `table`, if it is a valid `NIBArchive`.
---
--- Parameters:
---  * data - The `string` of bytes to unarchive.
---
--- Returns:
---  * The `table` containing the unarchived data, or `nil` if the `archive` is not a valid `NIBArchive`.
---  * The `string` error message, if any.
function mod.mt:fromBytes(data)
    if not mod.isSupported(data) then
        return nil, string.format("Provided data is not an NIBArchive.")
    end
    local header = newArchiveHeader(bytes.read(data, HEADER_INDEX,
        uint32le, uint32le, -- objectCount, objectStart
        uint32le, uint32le, -- keyCount, keyStart
        uint32le, uint32le, -- valueCount, valueStart
        uint32le, uint32le  -- classCount, classStart
    ))
    -- log.df("unarchive: header: %s", hs.inspect(header))
    return self:_processArchive(data, header)
end

--- cp.nib.archiver:unarchiveFile(filename) -> table | nil, string
--- Method
--- Attempts to read the specified `filename` and unarchives it into a `table`, if it is a valid NIBArchive.
---
--- Parameters:
---  * filename - The `string` of the file to read.
---
--- Returns:
---  * A `table` containing the archive data, or `nil` if the file could not be read.
--- * The `string` error message, if any.
function mod.mt:fromFile(filename)
    if not filename then
        return nil, "No filename was provided"
    end

    local absoluteFilename = fs.pathToAbsolute(filename)
    if not absoluteFilename then
        return nil, string.format("The provided path was not found: %s", filename)
    end
    local file = io.open(absoluteFilename, "r") -- r read mode
    if not file then
        return nil, string.format("Unable to open '%s'", filename)
    end
    local data = file:read "*a"                 -- *a or *all reads the whole file
    file:close()

    return self:fromBytes(data)
end


-- cp.nib.archive:_processArchive(data, header) -> table
-- Method
-- Processes the given `data` string, with the specified archive header providing counts and offsets.
-- All object, key, value, and class records are processed and added to the `object`, `key`, `value`, and `class` tables, respectively.
--
-- Parameters:
--  * data - The `string` of bytes to process.
--  * header - The `NIBArchive` header table.
--
-- Returns:
--  * A table containing the processed `object`, `key`, `value`, and `class` tables.
function mod.mt:_processArchive(data, header)
    -- 1. Process the keys.
    local keys = processKeys(data, header)
    -- 2. Process the values.
    local values = processValues(data, header, keys)
    -- 3. Process the classes.
    local classes = processClasses(data, header)
    -- 4. Process the objects.
    local objects = processObjects(data, header, classes, values)

    -- 5. Decode the objects.
    local cache = {}
    for i, object in ipairs(objects) do
        local instance = {}
        cache[i] = instance
        self:_decodeObject(object, instance, cache)
    end
    return cache
end

-- cp.nib.archive:_decodeObject(object, instance, cache)
-- Method
-- Decodes the given `object` into the `instance` table, using the `cache` table to look up referenced objects.
--
-- Parameters:
--  * object - The `object` table to decode.
--  * instance - The `table` to store the decoded `object` in.
--  * cache - The `table` of `object` tables to look up.
--
-- Returns:
--  * Nothing.
function mod.mt:_decodeObject(object, instance, cache)
    local class = findClass(cache, object.classIndex)
    instance.classname = class.classname
    self:_decodeValues(instance, object.values, cache)
end

mod._varint = varint

return mod