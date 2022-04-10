local insert, unpack        = table.insert, table.unpack
local char                  = string.char

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
        -- log.df("varint: index: %d", index)
        local result = 0
        local shift = 0
        local byte
        repeat
            byte = value:byte(index)
            index = index + 1
            result = result + ((byte & 0x7F) << shift)
            shift = shift + 7
        until (byte & 0x80) ~= 0
        -- log.df("varint: result: %d; index: %d", result, index)
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

return varint