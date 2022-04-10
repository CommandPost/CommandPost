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

local insert                                = table.insert

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

-- processObjects(data, objectCount, objectStart) -> table
-- Function
-- Processes the given `data` string, with the specified object count and offset.
-- All object records are processed and added to the `object` table.
--
-- Parameters:
--  * data - The `string` of bytes to process.
--  * objectCount - The number of objects in the archive.
--  * objectStart - The offset of the first object.
--
-- Returns:
--  * A table containing the processed `object` table.
--
-- Notes:
--  * Each object record is the following sequence of bytes:
--    * The class name index, as a `varint`. An offset into the list of class names.
--    * Values index, as a `varint`. An offset into the list of values for the first value.
--    * The number of values, as a `varint`.
local function processObjects(data, objectCount, objectStart)
    -- log.df("processObjects")
    local objects = {}
    local index = objectStart+1
    for _ = 1, objectCount do
        local classIndex, valuesIndex, valuesCount
        classIndex, valuesIndex, valuesCount, index = bytes.read(data, index, varint, varint, varint)
        -- log.df("processObjects: classIndex: %d; valuesIndex: %d; valuesCount: %d; index: %d", classIndex, valuesIndex, valuesCount, index)
        insert(objects, {
            classIndex = classIndex+1,
            valuesIndex = valuesIndex+1,
            valuesCount = valuesCount,
        })
    end
    return objects
end

-- processKeys(data, keyCount, keyStart) -> table
-- Function
-- Processes the given `data` string, with the specified key count and offset.
-- All key records are processed and added to the `key` table.
--
-- Parameters:
--  * data - The `string` of bytes to process.
--  * keyCount - The number of keys in the archive.
--  * keyStart - The offset of the first key.
--
-- Returns:
--  * A table containing the processed `key` table.
--
-- Notes:
--  * Each key record is the following sequence of bytes:
--    * Key name length, as a `varint`.
--    * Key name, as a `string`, with the length specified by the previous `varint`.
local function processKeys(data, keyCount, keyStart)
    -- log.df("processKeys")
    local keys = {}
    local index = keyStart+1
    for _ = 1, keyCount do
        local keyLength, key
        -- log.df("processKeys: reading from index: %d", index)
        keyLength, index = bytes.read(data, index, varint)
        -- log.df("processKeys: keyLength: %d; index: %d", keyLength, index)
        key, index = bytes.read(data, index, exactly(keyLength))
        insert(keys, key)
    end
    return keys
end

-- processValues(data, valueCount, valueStart) -> table
-- Function
-- Processes the given `data` string, with the specified value count and offset.
-- All value records are processed and added to the `value` table.
--
-- Parameters:
--  * data - The `string` of bytes to process.
--  * valueCount - The number of values in the archive.
--  * valueStart - The offset of the first value.
--
-- Returns:
--  * A table containing the processed `value` table.
--
-- Notes:
--  * Each value record is the following sequence of bytes:
--    * The key index, as a `varint`. An offset into the list of keys, for the key that this value is associated with.
--    * The value type, as a `uint8`. One of the following:
--      * `0` - int8: 1 byte
--      * `1` - int16 LE: 2 bytes
--      * `2` - int32 LE: 4 bytes
--      * `3` - int64 LE: 8 bytes
--      * `4` - true: 0 bytes
--      * `5` - false: 0 bytes
--      * `6` - float32 LE: 4 bytes
--      * `7` - float64 LE: 8 bytes
--      * `8` - string: the length of the string as a `varint`, followed by the string itself.
--      * `9` - nil: 0 bytes
--      * `10` - object reference: 4 bytes uint32 LE (index into the list of objects)
local function processValues(data, valueCount, valueStart)
    -- log.df("processValues")
    local values = {}
    local index = valueStart+1
    for _ = 1, valueCount do
        local keyIndex, valueType, value
        keyIndex, valueType, index = bytes.read(data, index, varint, uint8)
        if valueType == 0 then
            value, index = bytes.read(data, index, int8)
        elseif valueType == 1 then
            value, index = bytes.read(data, index, int16le)
        elseif valueType == 2 then
            value, index = bytes.read(data, index, int32le)
        elseif valueType == 3 then
            value, index = bytes.read(data, index, int64le)
        elseif valueType == 4 then
            value = true
        elseif valueType == 5 then
            value = false
        elseif valueType == 6 then
            value, index = bytes.read(data, index, float32le)
        elseif valueType == 7 then
            value, index = bytes.read(data, index, float64le)
        elseif valueType == 8 then
            local stringLength, string
            stringLength, index = bytes.read(data, index, varint)
            string, index = bytes.read(data, index, exactly(stringLength))
            value = string
        elseif valueType == 9 then
            value = nil
        elseif valueType == 10 then
            value, index = bytes.read(data, index, uint32le)
        end
        insert(values, {
            keyIndex = keyIndex+1,
            valueType = valueType,
            value = value,
        })
    end
    return values
end

-- processClasses(data, classCount, classStart) -> table
-- Function
-- Processes the given `data` string, with the specified class count and offset.
-- All class records are processed and added to the `class` table.
--
-- Parameters:
--  * data - The `string` of bytes to process.
--  * classCount - The number of classes in the archive.
--  * classStart - The offset of the first class.
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
local function processClasses(data, classCount, classStart)
    -- log.df("processClasses")
    local classes = {}
    local index = classStart+1
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

-- processArchive(data, header) -> table
-- Function
-- Processes the given `data` string, with the specified archive header providing counts and offsets.
-- All object, key, value, and class records are processed and added to the `object`, `key`, `value`, and `class` tables, respectively.
--
-- Parameters:
--  * data - The `string` of bytes to process.
--  * header - The `NIBArchive` header table.
--
-- Returns:
--  * A table containing the processed `object`, `key`, `value`, and `class` tables.
local function processArchive(data, header)
    -- 1. Process the objects.
    local objects = processObjects(data, header.objectCount, header.objectStart)
    -- 2. Process the keys.
    local keys = processKeys(data, header.keyCount, header.keyStart)
    -- 3. Process the values.
    local values = processValues(data, header.valueCount, header.valueStart)
    -- 4. Process the classes.
    local classes = processClasses(data, header.classCount, header.classStart)

    return {
        object = objects,
        key = keys,
        value = values,
        class = classes,
    }
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
    local archive = processArchive(data, header)

    local cache = {}

    defrost(archive, cache)    

    return cache
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

mod._varint = varint

return mod