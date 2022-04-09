--- === cp.nib ===
---
--- Provides support for NIB files.

--- === cp.nib.archiver ===
---
--- Provides support for loading NIB files stored in the `NIBArchive` format.

local require                               = require
local bytes                                 = require "hs.bytes"

local exactly                               = bytes.exactly
local uint8, uint32le                       = bytes.uint8, bytes.uint32le
local int8, int16le, int32le, int64le       = bytes.int8, bytes.int16le, bytes.int32le, bytes.int64le
local float32le, float64le                  = bytes.float32le, bytes.float64le

local format                                = string.format
local char                                  = string.char
local insert                                = table.insert
local unpack                                = table.unpack

-- varint(value, index) -> number, number | string
-- Function
-- Converts a byte `string` in the `NIBArchive` `varint` format into an unsigned `number` value, or a `number` value into a byte `string`.
-- It codes integers in 7-bit chunks, little-endian order. The high-bit in each byte signifies if it is the last byte.
--
-- Parameters:
--  * value - The `string` or `number` to convert.
--  * index - The index to start at, if the value is a `string`. (defaults to `1`)
--
-- Returns:
--  * The converted `number` value, or the `string` value.
--  * The second `number` will the the index of the next byte after the converted value.
local function varint(value, index)
    if type(value) == "string" then
        index = index or 1
        local result = 0
        local shift = 0
        local byte = 0
        repeat
            byte = value:byte(index)
            index = index + 1
            result = result + ((byte & 0x7F) << shift)
            shift = shift + 7
        until (byte & 0x80) ~= 0
        return result, index
    elseif type(value) == "number" then
        local result = {}
        while value > 0 do
            local byte = value & 0x7F
            value = value >> 7
            if value == 0 then
                byte = byte | 0x80
            end
            insert(result, byte)
        end
        return char(unpack(result))
    end
end

-- newArchiveHeader(major, minor, objectCount, firstObject, keyCount, firstKey, valueCount, firstValue, classCount, firstClass) -> table
-- Function
-- Creates an `NIBArchive` header table.
--
-- Parameters:
--  * major - The major version number.
--  * minor - The minor version number.
--  * objectCount - The number of objects in the archive.
--  * firstObject - The offset of the first object.
--  * keyCount - The number of keys in the archive.
--  * firstKey - The offset of the first key.
--  * valueCount - The number of values in the archive.
--  * firstValue - The offset of the first value.
--  * classCount - The number of classes in the archive.
--  * firstClass - The offset of the first class.
--
-- Returns:
--  * A `table` with the above contained as keys.
local function newArchiveHeader(major, minor, objectCount, firstObject, keyCount, firstKey, valueCount, firstValue, classCount, firstClass)
    return {
        major = major,
        minor = minor,
        objectCount = objectCount,
        firstObject = firstObject,
        keyCount = keyCount,
        firstKey = firstKey,
        valueCount = valueCount,
        firstValue = firstValue,
        classCount = classCount,
        firstClass = firstClass,
    }
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
    local objects = processObjects(data, header.objectCount, header.firstObject)
    -- 2. Process the keys.
    local keys = processKeys(data, header.keyCount, header.firstKey)
    -- 3. Process the values.
    local values = processValues(data, header.valueCount, header.firstValue)
    -- 4. Process the classes.
    local classes = processClasses(data, header.classCount, header.firstClass)

    return {
        object = objects,
        key = keys,
        value = values,
        class = classes,
    }
end

-- processObjects(data, objectCount, firstObject) -> table
-- Function
-- Processes the given `data` string, with the specified object count and offset.
-- All object records are processed and added to the `object` table.
--
-- Parameters:
--  * data - The `string` of bytes to process.
--  * objectCount - The number of objects in the archive.
--  * firstObject - The offset of the first object.
--
-- Returns:
--  * A table containing the processed `object` table.
--
-- Notes:
--  * Each object record is the following sequence of bytes:
--    * The class name index, as a `varint`. An offset into the list of class names.
--    * Values index, as a `varint`. An offset into the list of values for the first value.
--    * The number of values, as a `varint`.
local function processObjects(data, objectCount, firstObject)
    local objects = {}
    local index = firstObject
    for i = 1, objectCount do
        local classIndex, valuesIndex, valuesCount, index = bytes.read(data, index, varint, varint, varint)
        insert(objects, {
            classIndex = classIndex,
            valuesIndex = valuesIndex,
            valueCount = valueCount,
        })
    end
    return objects
end

-- processKeys(data, keyCount, firstKey) -> table
-- Function
-- Processes the given `data` string, with the specified key count and offset.
-- All key records are processed and added to the `key` table.
--
-- Parameters:
--  * data - The `string` of bytes to process.
--  * keyCount - The number of keys in the archive.
--  * firstKey - The offset of the first key.
--
-- Returns:
--  * A table containing the processed `key` table.
--
-- Notes:
--  * Each key record is the following sequence of bytes:
--    * Key name length, as a `varint`.
--    * Key name, as a `string`, with the length specified by the previous `varint`.
local function processKeys(data, keyCount, firstKey)
    local keys = {}
    local index = firstKey
    for i = 1, keyCount do
        local keyLength, key
        keyLength, index = bytes.read(data, index, varint)
        key, index = bytes.read(data, index, exactly(keyLength))
        insert(keys, key)
    end
    return keys
end

-- processValues(data, valueCount, firstValue) -> table
-- Function
-- Processes the given `data` string, with the specified value count and offset.
-- All value records are processed and added to the `value` table.
--
-- Parameters:
--  * data - The `string` of bytes to process.
--  * valueCount - The number of values in the archive.
--  * firstValue - The offset of the first value.
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
local function processValues(data, valueCount, firstValue)
    local values = {}
    local index = firstValue
    for i = 1, valueCount do
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
            keyIndex = keyIndex,
            valueType = valueType,
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
    local classes = {}
    local index = firstClass
    for i = 1, classCount do
        local classNameLength, extraInt32leCount, extraInts, className
        classNameLength, extraInt32leCount, index = bytes.read(data, index, varint, varint)
        extraInts = {}
        for j = 1, extraInt32leCount do
            extraInts[j], index = bytes.read(data, index, int32le)
        end
        className, index = bytes.read(data, index, exactly(classNameLength))
        insert(classes, {
            className = className
            extraInts = extraInts,
        })
    end
    return classes
end

-- The index where the NIBArchive header starts
local HEADER_INDEX = 11

local mod = {}

--- cp.nib.archiver.ARCHIVER_ID -> string
--- Constant
--- Marks the data stream as an `NIBArchive`.
mod.ARCHIVER_ID = "NIBArchive"

--- cp.nib.archiver.isSupported(data) -> boolean
--- Function
--- Checks if the given `data` is an NIBArchive.
---
--- Parameters:
---  * data - The data to check.
---
--- Returns:
---  * `true` if the `data` is an NIBArchive, `false` otherwise.
function mod.isSupported(data) {
    local value = bytes.read(data, bytes.exactly(10))
    return value == mod.ARCHIVER_ID
}

--- cp.nib.archiver.unarchive(archive, defrostFn) -> table | nil, string
--- Function
--- Unarchives the given `archive` bytes into a `table`, if it is a valid NIBArchive.
--- 
function mod.unarchive(data, defrostFn) {
    if not mod.isSupported(data) {
        return nil, string.format("Provided data is not an NIBArchive.")
    }
    local header = newArchiveHeader(bytes.read(data, HEADER_INDEX, uint32le, uint32le, uint32le, uint32le, uint32le, uint32le, uint32le, uint32le, uint32le))
    local archive = {
        header = header,
        data = data,
        objects = {},
        keys = {},
        values = {},
        classes = {},
    }

    local result = {}
}

return mod