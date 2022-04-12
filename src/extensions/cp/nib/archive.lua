--- === cp.nib.archive ===
---
--- This module represents a NIB Archive.

local require                               = require

local bytes                                 = require "hs.bytes"
local fs                                    = require "hs.fs"

local varint                                = require "cp.nib.varint"

local exactly                               = bytes.exactly
local uint8, uint32le                       = bytes.uint8, bytes.uint32le
local int8, int16le, int32le, int64le       = bytes.int8, bytes.int16le, bytes.int32le, bytes.int64le
local float32le, float64le                  = bytes.float32le, bytes.float64le

local format                                = string.format
local insert                                = table.insert

-- Unique key for the CLASSNAME value in object instances.
local CLASSNAME_ID = {}

local VALUE_HANDLERS = {
    [0] = int8,
    [1] = int16le,
    [2] = int32le,
    [3] = int64le,
    [4] = function(data, index) return true, index end,
    [5] = function(data, index) return false, index end,
    [6] = float32le,
    [7] = float64le,
    [8] = function(data, index)
        local length, index = bytes.read(data, index, varint)
        return bytes.read(data, index, exactly(length))
    end,
    [9] = function(data, index) return nil, index end,
    [10] = int32le, -- object reference
}

local OBJECT_HANDLERS = {
    ["NSMutableDictionary"] = function(instance, class, values)
        setmetatable(instance, {
            __index = values["NS.objects"]
        })
    end,
}

-- The value type indicating the number is an index into the objects table.
local REFERENCE_TYPE = 10

local archive = {}
archive.mt = {}
archive.mt.__index = archive.mt

--- cp.nib.archive.new(objects, keys, values, classes[, defrostFn]) -> cp.nib.archive
--- Constructor
--- Creates a new `cp.nib.archive` instance.
---
--- Parameters:
---  * objects - The objects table.
---  * keys - The keys table.
---  * values - The values table.
---  * classes - The classes table.
---  * defrostFn - The defrost function. (optional)
---
--- Returns:
---  * The new `cp.nib.archive` instance.
function archive.new(objects, keys, values, classes, defrostFn)
    local self = {
        objects = objects,
        keys = keys,
        values = values,
        classes = classes,
        defrostFn = defrostFn,
    }
    setmetatable(self, archive.mt)
    return self
end

--- cp.nib.archive:getObject(id) -> table
--- Method
--- Gets the object instance with the given `id`.
---
--- Parameters:
---  * id - The id of the object to get.
---
--- Returns:
---  * The object with the given `id`.
function archive.mt:getObject(id)
    local objectDef = self.objects[id]
    local instance = objectDef.instance
    if instance == nil then
        instance = self:_createObject(objectDef)
        objectDef.instance = instance
    end
    return instance
end

-- cp.nib.archive:_createObject(objectDef) -> table
-- Method
-- Creates an object from the given `objectDef`.
--
-- Parameters:
--  * objectDef - The object definition.
--
-- Returns:
--  * The created object.
function archive.mt:_createObject(objectDef)
    local class = self.classes[objectDef.classIndex]
    if class == nil then
        error(format("Class #%d not found", objectDef.classIndex))
    end
    local classname = class.classname

    local instance = {
        [CLASSNAME_ID] = classname
    }
    objectDef.instance = instance

    for i = objectDef.valuesIndex, objectDef.valuesIndex + objectDef.valuesCount - 1 do
        local valueDef = self.values[i]
        local key = self.keys[valueDef.keyIndex]
        local value = valueDef.value
        if value == REFERENCE_TYPE then
            value = self:getObject(value)
        end
        instance[key] = value
    end

    return instance
end

--- cp.nib.archiver.SIGNATURE -> string
--- Constant
--- `NIBArchive` byte streams begin with this value (`"NIBArchive"`)
archive.SIGNATURE = "NIBArchive"

--- cp.nib.archiver.isSupported(data) -> boolean
--- Function
--- Checks if the given `string` of `data` is an NIBArchive.
---
--- Parameters:
---  * data - The data to check.
---
--- Returns:
---  * `true` if the `data` is an NIBArchive, `false` otherwise.
function archive.isSupported(data)
    local value, major, minor = bytes.read(data, bytes.exactly(10), int32le, int32le)
    return value == archive.SIGNATURE and major == 1 and minor >= 9
end

-- The length of the signature/version header
local HEADER_INDEX = 1 + #archive.SIGNATURE + 4 + 4

-- createArchiveHeader(objectCount, firstObject, keyCount, firstKey, valueCount, firstValue, classCount, firstClass) -> table
-- Function
-- Creates an `NIBArchive` header table.
--
-- Parameters:
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
local function createArchiveHeader(objectCount, firstObject, keyCount, firstKey, valueCount, firstValue, classCount, firstClass)
    return {
        objectCount = objectCount,
        firstObject = firstObject+1,
        keyCount = keyCount,
        firstKey = firstKey+1,
        valueCount = valueCount,
        firstValue = firstValue+1,
        classCount = classCount,
        firstClass = firstClass+1,
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
    local index = header.firstKey
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
    local index = header.firstValue
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

-- defrostObject(instance, class, values[, defrostFn])
-- Function
-- Defrosts the given `instance` with the given `class` and `instanceValues`.
-- If the `defrostFn` is given, it is called with the `instance` and `class` as parameters.
-- If not, there are default defrosting rules for common classes, such as `NSArray` and `NSDictionary`.
--
-- Parameters:
--  * instance - The instance to into.
--  * class - The class of the instance.
--  * values - The `table` of values of the instance.
--  * defrostFn - The optional defrosting function.
--
-- Returns:
--  * Nothing
local function defrostObject(instance, class, instanceValues, defrostFn)

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
local function processObjects(data, header, classes, values, defrostFn)
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

        defrostObject(instance, class, instanceValues, defrostFn)
    end
    return objects
end

--- cp.nib.archive.fromBytes(data, defrostFn) -> cp.nib.archive | nil, string
--- Constructor
--- Creates a new `cp.nib.archive` instance from the given `data` byte array.
---
--- Parameters:
---  * data - The data to create the archive from.
---  * defrostFn - The defrost function. (optional)
---
--- Returns:
---  * If successfull, the new `cp.nib.archive` instance.
---  * If not successfull, `nil`, followed by the error message.
function archive.fromBytes(data, defrostFn)
    if not archive.isSupported(data) then
        return nil, "Not a supported NIB archive"
    end
    local header = createArchiveHeader(bytes.read(data, HEADER_INDEX,
        int32le, int32le,   -- objectCount, firstObject
        int32le, int32le,   -- keyCount, firstKey
        int32le, int32le,   -- valueCount, firstValue
        int32le, int32le    -- classCount, firstClass
    ))

    local keys, values, classes, objects, err
    keys, err = processKeys(data, header)
    if not keys then
        return nil, err
    end
    values, err = processValues(data, header, keys)
    if not values then
        return nil, err
    end
    classes, err = processClasses(data, header)
    if not classes then
        return nil, err
    end
    objects, err = processObjects(data, header, classes, values, defrostFn)
    if not objects then
        return nil, err
    end

    return archive.new(objects)
end
