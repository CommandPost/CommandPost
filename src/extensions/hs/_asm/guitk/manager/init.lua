-- maybe save some pain, if the shim is installed; otherwise, expect an objc dump to console when this loads on stock Hammerspoon without pull #2308 applied

--- === hs._asm.guitk.manager ===
---
--- This submodule provides a content manager for an `hs._asm.guitk` window that allows the placement and managerment of multiple gui elements.
---
--- A manager can also act as an element to another manager -- this allows for the grouping of elements as single units for display or other purposes. See `hs._asm.guitk.element.button` for a further discussion of this when using the radio button style.
---
--- Elements can be added and managed through the methods of this module.  There are also metamethods which allow you to manipulate the elements in an array like fashion. Each element is represented as a table and can be accessed from the manager as if it were an array. Valid index numbers range from 1 to `#hs._asm.guitk.manager:elements()` when getting an element or its attributes, or 1 to `#hs._asm.guitk.manager:elements() + 1` when replacing or assigning a new element. To access the userdata representing a specific element you can use the following syntax: `hs._asm.guitk.manager[#]._element` or `hs._asm.guitk.manager(#)` where # is the index number or the string `id` specified in the `frameDetails` attribute described below.
---
--- The specific attributes of each element will depend upon the type of element (see `hs._asm.guitk.element`) and the following manager specific attributes:
---
--- * `_element`     - A read-only attribute whos value is the userdata representing the gui element itself.
--- * `_fittingSize` - A read-only size-table specifying the default height and width for the element. Not all elements have a default height or width and the value for one or more of these keys may be 0.
--- * `_type`        - A read-only string indicating the userdata name for the element.
--- * `frameDetails` - A table containing positioning and identification information about the element.  All of it's keys are optional and are as follows:
---   * `x`  - The horizontal position of the elements left side. Only one of `x`, `rX`, or`cX` can be set; setting one will clear the others.
---   * `rX`  - The horizontal position of the elements right side. Only one of `x`, `rX`, or`cX` can be set; setting one will clear the others.
---   * `cX` - The horizontal position of the elements center point. Only one of `x`, `rX`, or`cX` can be set; setting one will clear the others.
---   * `y`  - The vertical position of the elements top. Only one of `y`, `bY`, or `cY` can be set; setting one will clear the others.
---   * `bY`  - The vertical position of the elements bottom. Only one of `y`, `bY`, or `cY` can be set; setting one will clear the others.
---   * `cY` - The vertical position of the elements center point. Only one of `y`, `bY`, or `cY` can be set; setting one will clear the others.
---   * `h`  - The element's height. If this is set, it will be used instead of the default height as returned by the `_fittingSize` attribute. If the default height is 0, then this *must* be set or the element will be effectively invisible.
---   * `w`  - The element's width. If this is set, it will be used instead of the default width as returned by the `_fittingSize` attribute. If the default width is 0, then this *must* be set or the element will be effectively invisible.
---   * `id` - A string specifying an identifier which can be used to reference this element through the manager's metamethods without requiring knowledge of the element's index position.
---
---   * `honorCanvasMove` - A boolean, default nil (false), indicating whether or not the frame wrapper functions for `hs.canvas` objects should honor location changes when made with `hs.canvas:topLeft` or `hs.canvas:frame`. This is a (hopefully temporary) fix because canvas objects are not aware of the `hs._asm.guitk` frameDetails model for element placement.
---
---   * Note that `x`, `rX`, `cX`, `y`, `bY`, `cY`, `h`, and `w` may be specified as numbers or as strings representing percentages of the element's parent width (for `x`, `rX`, `cX`, and `w`) or height (for `y`, `bY`, `cY`, and `h`). Percentages should specified in the string as defined for your locale or in the `en_US` locale (as a fallback) which is either a number followed by a % sign or a decimal number.
---
--- * When assigning a new element to the manager through the metamethods, you can assign the userdata directly or by using the table format described above. For example:
---
--- ~~~lua
--- manager = hs._asm.guitk.manager.new()
--- manager[1] = hs._asm.guitk.element.button.new(...)  -- direct assignment of the element
--- manager[2] = {                                      -- as a table
---   _element = hs._asm.guitk.element.button.new(...), -- the only time that `_element` can be assigned a value
---   frameDetails = { cX = "50%", cY = "50%" },
---   id = "secondButton", -- the only time that `id` can be set outside of the `frameDetails` table
---   -- other button specific attributes as defined in `hs._asm.guitk.element.button`
--- }
--- ~~~
---
--- You can remove an existing element by setting its value to nil, e.g. `manager[1] = nil`.

local USERDATA_TAG = "hs._asm.guitk.manager"
local module       = require(USERDATA_TAG .. ".internal")
local managerMT    = hs.getObjectMetatable(USERDATA_TAG)

local commonViewMethods = require(USERDATA_TAG:gsub("manager", "element") .. "._view")

local fnutils = require("hs.fnutils")
local inspect = require("hs.inspect")

require("hs.canvas")
local canvasMT = hs.getObjectMetatable("hs.canvas")

local basePath = package.searchpath(USERDATA_TAG, package.path)
if basePath then
    basePath = basePath:match("^(.+)/init.lua$")
    if require"hs.fs".attributes(basePath .. "/docs.json") then
        require"hs.doc".registerJSONFile(basePath .. "/docs.json")
    end
end

local log = require("hs.logger").new(USERDATA_TAG, require"hs.settings".get(USERDATA_TAG .. ".logLevel") or "warning")

-- private variables and methods -----------------------------------------

-- a simplified one line inspect used to stringify tables
local finspect = function(...)
    local args = table.pack(...)
    if args.n == 1 and type(args[1]) == "table" then
        args = args[1]
    else
        args.n = nil -- supress the count from table.pack
    end

    -- causes issues with recursive calls to __tostring in inspect
    local mt = getmetatable(args)
    if mt then setmetatable(args, nil) end
    local answer = inspect(args, { newline = " ", indent = "" })
    if mt then setmetatable(args, mt) end
    return answer
end


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
    local keys = {}
    for i,v in ipairs(getmetatable(element)["_propertyList"] or {}) do table.insert(keys, v) end
    local builtin = { "_element", "_fittingSize", "frameDetails", "_type" }
    table.move(builtin, 1, #builtin, #keys + 1, keys)

    return function(_, k)
        local v = nil
        k = table.remove(keys)
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

    -- if requested, merge in common view methods and update properties table
--     if managerMT._inheritView then
    local propertieslist = managerMT._propertyList or {}
    for k,v in pairs(commonViewMethods) do
        if not managerMT[k] then
            if type(v) == "function" then
                if fnutils.contains(commonViewMethods._propertyList, k) then
                    table.insert(propertieslist, k)
                end
            end
        end
    end
    managerMT._propertyList = propertieslist
-- --         managerMT._inheritView  = nil -- can't clear because this is checked in __index since these methods only "exist" if the manager is an element of another manager
--     end

-- Public interface ------------------------------------------------------

-- wrap canvas so it's size and topLeft methods work with the manager
local canvasSize = canvasMT.size
local canvasTL   = canvasMT.topLeft

-- -- Calling _nextResponder on a canvas results in a lot of logging because the built in canvas window object has no converter. Waiting
-- -- on adding one until I decide how best to integrate canvas with guitk; in the mean time, this check doesn't trigger the messages.
-- local isCanvasViewSeparated = function(self)
--     local r, s = pcall(self.level, self)
--     return not r
-- end

canvasMT.size = function(self, ...)
--     local parent = isCanvasViewSeparated(self) and commonViewMethods._nextResponder(self) or nil
    local parent = commonViewMethods._nextResponder(self)
    if parent and getmetatable(parent) == managerMT then
        local args = table.pack(...)
        if args.n == 0 then
            local ans = parent:elementFrameDetails(self)._effective
            return { h = ans.h, w = ans.w }
        else
            return parent:elementFrameDetails(self, { h = args[1].h, w = args[1].w })
        end
    else
        return canvasSize(self, ...)
    end
end

canvasMT.topLeft = function(self, ...)
--     local parent = isCanvasViewSeparated(self) and commonViewMethods._nextResponder(self) or nil
    local parent = commonViewMethods._nextResponder(self)
    if parent and getmetatable(parent) == managerMT then
        local args = table.pack(...)
        if args.n == 0 then
            local ans = parent:elementFrameDetails(self)._effective
            return { x = ans.x, y = ans.y }
        else
            local frameDetails = parent:elementFrameDetails(self)
            if frameDetails.honorCanvasMove then
                return parent:elementFrameDetails(self, { x = args[1].x, y = args[1].y })
            else
                return self
            end
        end
    else
        return canvasTL(self, ...)
    end
end

--- hs._asm.guitk.manager:elementPropertyList(element) -> managerObject
--- Method
--- Return a table of key-value pairs containing the properties for the specified element
---
--- Parameters:
---  * `element` - the element userdata to create the property list for
---
--- Returns:
---  * a table containing key-value pairs describing the properties of the element.
---
--- Notes:
---  * The table returned by this method does not support modifying the property values as can be done through the `hs._asm.guitk.manager` metamethods (see the top-level documentation for `hs._asm.guitk.manager`).
---
---  * This method is wrapped so that elements which are assigned to a manager can access this method as `hs._asm.guitk.element:propertyList()`
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
--         return setmetatable(results, { __tostring = inspect })
        return setmetatable(results, { __tostring = function(self)
            return (inspect(self, { process = function(item, path)
                if path[#path] == inspect.KEY then return item end
                if path[#path] == inspect.METATABLE then return nil end
                if #path > 0 and type(item) == "table" then
                    return finspect(item)
                else
                    return item
                end
            end
            }):gsub("[\"']{", "{"):gsub("}[\"']", "}"))
        end})    else
        error("unexpected arguments", 2)
    end
end

--- hs._asm.guitk.manager:elementRemoveFromManager(element) -> managerObject
--- Method
--- Remove the specified element from the manager
---
--- Parameters:
---  * `element` - the element userdata to remove from this manager
---
--- Returns:
---  * the manager object
---
--- Notes:
---  * This method is wrapped so that elements which are assigned to a manager can access this method as `hs._asm.guitk.element:removeFromManager()`
---
---  * See also [hs._asm.guitk.manager:remove](#remove)
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

--- hs._asm.guitk.manager:elementId(element, [id]) -> managerObject | string
--- Method
--- Get or set the string identifier for the specified element.
---
--- Parameters:
---  * `element` - the element userdata to get or set the id of.
---  * `id`      - an optional string, or explicit nil to remove, to change the element's identifier to
---
--- Returns:
---  * If an argument is provided, the manager object; otherwise the current value.
---
--- Notes:
---  * This method is wrapped so that elements which are assigned to a manager can access this method as `hs._asm.guitk.element:id([id])`
managerMT.elementId = function(self, element, ...)
    local args = table.pack(...)
    local details = self:elementFrameDetails(element)
    if args.n == 0 then
        return details.id
    elseif args.n == 1 and (type(args[1]) == "string" or type(args[1]) == "nil") then
        details.id = args[1] or false
        return self:elementFrameDetails(element, details)
    else
        error("expected a single string as an argument", 2)
    end
end

managerMT._insert = managerMT.insert     -- save raw version
managerMT.insert = function(self, ...)
    local args = table.pack(...)
    local element = args[1]
    local details = args[2]
    if element and getmetatable(element) == canvasMT then
        local newDetails = {}
        -- shallow copy so we don't modify a table the user might re-use
        for k,v in pairs(details or {}) do newDetails[k] = v end
        local size = element:size()
        if type(newDetails.h) == "nil" then newDetails.h = size.h end
        if type(newDetails.w) == "nil" then newDetails.w = size.w end
        args[2] = newDetails
    end
    return managerMT._insert(self, table.unpack(args))
end

managerMT.__call  = function(self, ...) return self:element(...) end
managerMT.__len   = function(self) return #self:elements() end

managerMT.__core  = managerMT.__index
managerMT.__index = function(self, key)
    if managerMT.__core[key] then
        return managerMT.__core[key]
    else

-- check common view methods if we're not the contentManager of a window since, hey, we are actually a view!
        local parentObj = self:_nextResponder()
        if not parentObj or getmetatable(parentObj) == managerMT then
            local fn = commonViewMethods[key]
            if fn then
                return fn
            elseif parentObj and type(key) == "string" then
-- check our own "element[A-Z]\w+" methods since we're acting as an element
                parentFN = parentObj["element" .. key:sub(1,1):upper() .. key:sub(2)]
                if parentFN then
                    if type(parentFN) == "function" or (getmetatable(parentFN) or {}).__call then
                        return function(self, ...)
                            local answer = parentFN(parentObj, self, ...)
                            if answer == parentObj then
                                return self
                            else
                                return answer
                            end
                        end
                    else
                        return parentFN
                    end
                end
            end
        end

-- check to see if its an index or key to an element of this manager
        local element = self(key)
        if element then
            return wrappedElementWithMT(self, element)
        end

-- finally pass through method requests that aren't defined for the manager to the guitk object itself
        if parentObj then
            local parentFN = parentObj[key]
            if parentFN and type(parentFN) == "function" or (getmetatable(parentFN) or {}).__call then
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
                error("index out of bounds", 2)
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
                            log.wf("insert metamethod, unrecognized key %s for %s", k, newElement.__type)
                        end
                    end
                end

                if self:element(key) then self:remove(key) end
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
    -- id is optional and it would just be a second way to access the same object, so stick with indicies
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
