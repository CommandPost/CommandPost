local USERDATA_TAG = "hs._asm.axuielement"
local module       = {}
local ax           = require(USERDATA_TAG)

local examine_axuielement
examine_axuielement = function(element, showParent, depth, seen)
    seen = seen or {}
    depth = depth or 1
    local result

    if getmetatable(element) == hs.getObjectMetatable(USERDATA_TAG) and seen[element] then return seen[element] end

    if depth > 0 and getmetatable(element) == hs.getObjectMetatable(USERDATA_TAG) then
        result = {
            actions = {},
            attributes = {},
            parameterizedAttributes = {},
            pid = object.pid(element)
        }
        seen[element] = result

    -- actions

        if object.actionNames(element) then
            for i,v in ipairs(object.actionNames(element)) do
                result.actions[v] = object.actionDescription(element, v)
            end
        end

    -- attributes

        if object.attributeNames(element) then
            for i,v in ipairs(object.attributeNames(element)) do
                local value
                if (v ~= ax.attributes.general.parent and v ~= ax.attributes.general.topLevelUIElement) or showParent then
                    value = examine_axuielement(object.attributeValue(element, v), showParent, depth - 1, seen)
                else
                    value = "--parent:skipped"
                end
                if object.isAttributeSettable(element, v) == true then
                    result.attributes[v] = {
                        settable = true,
                        value    = value
                    }
                else
                    result.attributes[v] = value
                end
            end
        end

    -- parameterizedAttributes

        if object.parameterizedAttributeNames(element) then
            for i,v in ipairs(object.parameterizedAttributeNames(element)) do
                -- for now, stick in the name until I have a better idea about what to do with them,
                -- since the AXUIElement.h Reference doesn't appear to offer a way to enumerate the
                -- parameters
                table.insert(result.parameterizedAttributes, v)
            end
        end

    elseif depth > 0 and type(element) == "table" then
        result = {}
        for k,v in pairs(element) do
            result[k] = examine_axuielement(v, showParent, depth - 1, seen)
        end
    else
        if type(element) == "table" then
            result = "--table:max-depth-reached"
        elseif getmetatable(element) == hs.getObjectMetatable(USERDATA_TAG) then
            result = "--axuielement:max-depth-reached"
        else
            result = element
        end
    end
    return result
end

module.browse = function(xyzzy, showParent, depth)
    if type(showParent) == "number" then showParent, depth = nil, showParent end
    showParent = showParent or false
    local theElement
    -- seems deep enough for most apps and keeps us from a potential loop, though there
    -- are protections against loops built in, so... maybe I'll remove it later
    depth = depth or 100
    if type(xyzzy) == "nil" then
        theElement = ax.systemWideElement()
    elseif getmetatable(xyzzy) == hs.getObjectMetatable(USERDATA_TAG) then
        theElement = xyzzy
    elseif getmetatable(xyzzy) == hs.getObjectMetatable("hs.window") then
        theElement = ax.windowElement(xyzzy)
    elseif getmetatable(xyzzy) == hs.getObjectMetatable("hs.application") then
        theElement = ax.applicationElement(xyzzy)
    else
        error("nil, "..USERDATA_TAG..", hs.window, or hs.application object expected", 2)
    end

    return examine_axuielement(theElement, showParent, depth, {})
end

