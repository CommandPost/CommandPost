--- === hs._asm.guitk.manager ===
---
--- Element placement managers for use with `hs._asm.guitk` windows.

local USERDATA_TAG = "hs._asm.guitk.manager"
local module       = require(USERDATA_TAG .. ".internal")
local managerMT    = hs.getObjectMetatable(USERDATA_TAG)

local fnutils = require("hs.fnutils")
local inspect = require("hs.inspect")

local basePath = package.searchpath(USERDATA_TAG, package.path)
if basePath then
    basePath = basePath:match("^(.+)/init.lua$")
    if require"hs.fs".attributes(basePath .. "/docs.json") then
        require"hs.doc".registerJSONFile(basePath .. "/docs.json")
    end
end

local log = require("hs.logger").new(USERDATA_TAG, require"hs.settings".get(USERDATA_TAG .. ".logLevel") or "warning")

-- private variables and methods -----------------------------------------

local wrappedElementMT = {
    __e = setmetatable({}, { __mode = "k" })
}

local wrappedElementWithMT = function(manager, element)
    local newItem = {}
    wrappedElementMT.__e[newItem] = { manager = manager, element = element }
    return setmetatable(newItem, wrappedElementMT)
end

wrappedElementMT.__index = function(self, key)
    local obj = wrappedElementMT.__e[self]
    local manager, element = obj.manager, obj.element

-- this key doesn't correspond to a method
    if key == "_element" then
        return element

-- should be inherited through hs._asm.guitk.element init.lua's metamethods, but nsviews from other
-- sources (e.g. canvas, webview, etc) don't get included through this mechanism yet
    elseif key == "frameDetails" then
        return manager:elementFrameDetails(element)
    elseif key == "_fittingSize" then
        return manager:elementFittingSize(element)

-- convenience lookup
    elseif key == "_type" then
        return getmetatable(element).__type

-- try property methods
    elseif element[key] then
        return element[key](element)
    else
        return nil
    end
end

wrappedElementMT.__newindex = function(self, key, value)
    local obj = wrappedElementMT.__e[self]
    local manager, element = obj.manager, obj.element

    if key == "_element" or key == "_type" or key == "_fittingSize" then
        error(key .. " cannot be modified", 2)
    elseif key == "frameDetails" then
        manager:elementFrameDetails(element, value)
    elseif element[key] then
        element[key](element, value)
    else
        error(tostring(key) .. " unrecognized property", 2)
    end
    manager:elementAutoPosition(element)
end

wrappedElementMT.__pairs = function(self)
    local obj = wrappedElementMT.__e[self]
    local manager, element = obj.manager, obj.element
    local propertiesList = getmetatable(obj.element)["_propertyList"] or {}
    local builtin = { "_element", "_fittingSize", "frameDetails", "_type" }
    table.move(builtin, 1, #builtin, #propertiesList + 1, propertiesList)

    return function(_, k)
        local v = nil
        k = table.remove(propertiesList)
        if k then v = self[k] end
        return k, v
    end, self, nil
end

wrappedElementMT.__tostring = function(self)
    local obj = wrappedElementMT.__e[self]
    local manager, element = obj.manager, obj.element
    return tostring(manager:elementPropertyList(element))
end

wrappedElementMT.__len = function(self) return 0 end

-- Public interface ------------------------------------------------------

managerMT.elementPropertyList = function(self, element, ...)
    local args = table.pack(...)
    if args.n == 0 then
        local results = {}
        local propertiesList = getmetatable(element)["_propertyList"] or {}
        for i,v in ipairs(propertiesList) do results[v] = element[v](element) end
        results._element     = element
        results.frameDetails = self:elementFrameDetails(element)
        results._fittingSize = self:elementFittingSize(element)
        results._type        = getmetatable(element).__type
        return setmetatable(results, { __tostring = inspect })
    else
        error("unexpected arguments", 2)
    end
end

managerMT.elementRemoveFromManager = function(self, element, ...)
    local idx
    for i,v in ipairs(self:elements()) do
        if element == v then
            idx = i
            break
        end
    end
    if idx then
        return self:remove(idx, ...)
    else
        error("invalid element or element not managed by this content manager", 2)
    end
end

managerMT.elementId = function(self, element, ...)
    local args = table.pack(...)
    local details = self:elementFrameDetails(element)
    if args.n == 0 then
        return details.id
    elseif args.n == 1 and type(args[1]) == "string" then
        details.id = args[1]
        return self:elementFrameDetails(element, details)
    else
        error("expected a single string as an argument", 2)
    end
end

managerMT.__call  = function(self, ...) return self:element(...) end
managerMT.__len   = function(self) return #self:elements() end

managerMT.__core  = managerMT.__index
managerMT.__index = function(self, key)
    if managerMT.__core[key] then
        return managerMT.__core[key]
    else
        local element = self(key)
        if element then
            return wrappedElementWithMT(self, element)
        end

-- pass through method requests that aren't defined for the manager to the guitk object itself
        if type(key) == "string" then
            local parentObj = self:_nextResponder()
            if parentObj then
                local parentFN = parentObj[key]
                if parentFN then
                    return function(self, ...)
                        local answer = parentFN(parentObj, ...)
                        if answer == parentObj then
                            return self
                        else
                            return answer
                        end
                    end
                end
            end
        end
    end
    return nil
end

managerMT.__newindex = function(self, key, value)
    if type(value) == "nil" then
        if type(key) == "string" or math.type(key) == "integer" then
            local element = self(key)
            if element then
                return managerMT.elementRemoveFromManager(self, element)
            end
        end
        error("invalid identifier or index for element removal", 2)
    else
        if math.type(key) == "integer" then
            if key < 1 or key > (#self + 1) then
                error("replacement index out of bounds", 2)
            end
            if type(value) == "userdata" then value = { _element = value } end
            if type(value) == "table" and pcall(self.elementFittingSize, self, value._element) then
                local newElement = value._element
                local details = value.frameDetails or {}
                if value.id then details.id = value.id end
                for k, v in pairs(value) do
                    if k ~= "_element" and k ~= "frameDetails" and k ~= "id" then
                        if newElement[k] then
                            newElement[k](newElement, v)
                        else
                            log.wf("%s:insert metamethod, unrecognized key %s", USERDATA_TAG, k)
                        end
                    end
                end

                local oldElement = self:element(key)
                if oldElement then self:remove(key) end
                self:insert(newElement, details, key)
            else
                error("replacement value does not specify an element", 2)
            end
        else
            error("expected integer for element assignment", 2)
        end
    end
end

managerMT.__pairs = function(self)
    local keys = {}
    for i = #self, 1, -1 do table.insert(keys, i) end

    return function(_, k)
        local v = nil
        k = table.remove(keys)
        if k then v = self[k] end
        return k, v
    end, self, nil
end

-- Return Module Object --------------------------------------------------

return module
