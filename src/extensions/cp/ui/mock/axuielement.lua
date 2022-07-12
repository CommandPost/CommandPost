-- a mock definition for `axuielement` for testing.
-- Use by `require`ing this file and then calling `axuielementMock {...}`,
-- and specify any `AX` values you want to return.
local axuielementMock = {}
axuielementMock.__index = axuielementMock

function axuielementMock:attributeValue(attribute)
    return self[attribute]
end

function axuielementMock:setAttributeValue(attribute, value)
    self[attribute] = value
end

function axuielementMock:performAction(action)
    -- do nothing
end

function axuielementMock:isValid()
    return self._isValid or true
end

local function new_axuielementMock(attributes)
    return setmetatable(attributes, axuielementMock)
end

return new_axuielementMock