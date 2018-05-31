
-- TODO for MENUBAR
--
-- For all:
--   Document
--   Test
--   Update timer to use more inclusive run loop modes
--
-- For menu:
--   Checkout services...
--     can we provide them or use them easily? Early research was less then promising re
--     providing them (too much required Info.plist set before application run) but as to
--     using them, never really checked.
--   Can popup menu be in background thread to prevent blocking?
--
-- For menuitem:
--   some special keys don't seem to be caught; need to see if we can fix that or make list of them and remove from table
--
-- For statusitem:
--  * hs.menubar wrapper
--  * drag and drop for button itself?
--      for items? may have to add "springLoaded" to allow drag and drop to menu items
--
-- For legacy:
--    determine if stateImageSize is really needed or should remain a nop
--    image position wrong when both title and icon are set

--- === hs._asm.guitk.menubar ===
---
--- Stuff about the module

local USERDATA_TAG = "hs._asm.guitk.menubar"
local module       = {}
module.statusitem  = require(USERDATA_TAG .. ".statusitem")
module.menu        = require(USERDATA_TAG .. ".menu")
module.menu.item   = require(USERDATA_TAG .. ".menuItem")
module._legacy     = require(USERDATA_TAG .. ".legacy")

local statusitemMT = hs.getObjectMetatable(USERDATA_TAG .. ".statusitem")
local menuMT       = hs.getObjectMetatable(USERDATA_TAG .. ".menu")
local menuItemMT   = hs.getObjectMetatable(USERDATA_TAG .. ".menu.item")

local inspect = require("hs.inspect")

require("hs.drawing.color")
require("hs.image")
require("hs.styledtext")
require("hs.sound")

local basePath = package.searchpath(USERDATA_TAG, package.path)
if basePath then
    basePath = basePath:match("^(.+)/init.lua$")
    if require"hs.fs".attributes(basePath .. "/docs.json") then
        require"hs.doc".registerJSONFile(basePath .. "/docs.json")
    end
end

local log = require("hs.logger").new(USERDATA_TAG, require"hs.settings".get(USERDATA_TAG .. ".logLevel") or "warning")

-- private variables and methods -----------------------------------------

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


local wrappedItemMT = {
    __i = setmetatable({}, { __mode = "k" })
}

local wrappedItemWithMT = function(menu, item)
    local newItem = {}
    wrappedItemMT.__i[newItem] = { menu = menu, item = item }
    return setmetatable(newItem, wrappedItemMT)
end

wrappedItemMT.__index = function(self, key)
    local obj = wrappedItemMT.__i[self]
    local menu, item = obj.menu, obj.item

-- this key doesn't correspond to a method
    if key == "_item" then
        return item

-- convenience lookup
    elseif key == "_type" then
        return getmetatable(item).__type

-- try property methods
    elseif item[key] then
        return item[key](item)
    else
        return nil
    end
end

wrappedItemMT.__newindex = function(self, key, value)
    local obj = wrappedItemMT.__i[self]
    local menu, item = obj.menu, obj.item

    if key == "_item" or key == "_type" then
        error(key .. " cannot be modified", 2)
    elseif item[key] then
        item[key](item, value)
    else
        error(tostring(key) .. ": unrecognized property", 2)
    end
end

wrappedItemMT.__pairs = function(self)
    local obj = wrappedItemMT.__i[self]
    local menu, item = obj.menu, obj.item
    local keys = {}
    for i,v in ipairs(getmetatable(item)["_propertyList"] or {}) do table.insert(keys, v) end
    local builtin = { "_item", "_type" }
    table.move(builtin, 1, #builtin, #keys + 1, keys)

    return function(_, k)
        local v = nil
        k = table.remove(keys)
        if k then v = self[k] end
        return k, v
    end, self, nil
end

wrappedItemMT.__tostring = function(self)
    local obj = wrappedItemMT.__i[self]
    local menu, item = obj.menu, obj.item
    return tostring(menu:itemPropertyList(item))
end

wrappedItemMT.__len = function(self) return 0 end

menuMT.__core = menuMT.__index
menuMT.__index = function(self, key)
    if menuMT.__core[key] then
        return menuMT.__core[key]
    else
        local idx = (math.type(key) == "integer") and key or self:indexWithAttachment(key)
        local item = idx and self:itemAtIndex(idx) or nil
        return item and wrappedItemWithMT(self, item) or nil
    end
end

menuMT.__newindex = function(self, key, value)
    local idx = (math.type(key) == "integer") and key or self:indexWithAttachment(key)
    if idx then
        local newItem = nil
        if type(value) ~= "nil"  then
            if type(value) == "userdata" then value = { _item = value } end
            if type(value) == "table" and type(value._item) == "nil" then
                local newValue = {}
                -- shallow copy so we don't modify a table the user might re-use
                for k,v in pairs(value) do newValue[k] = v end
                newValue._item = module.menu.item.new(USERDATA_TAG .. ".menu.item")
                value = newValue
            end
            if type(value) == "table" and value._item.__type == USERDATA_TAG .. ".menu.item" then
                newItem = value._item
                for k, v in pairs(value) do
                    if k ~= "_item" and k ~= "_type" then
                        if newItem[k] then
                            newItem[k](newItem, v)
                        else
                            log.wf("insert metamethod, unrecognized key %s for %s", k, newItem.__type)
                        end
                    end
                end
            else
                error("value does not specify an item for assignment", 2)
            end
        end

        -- insert could fail because menuitem already belongs to a menu, so do it first
        if newItem then
            self:insert(newItem, idx)
            if self:itemAtIndex(idx + 1) then self:remove(idx + 1) end
        else
            if self:itemAtIndex(idx) then self:remove(idx) end
        end
    else
        error("invalid identifier for item assignment", 2)
    end
end

menuMT.__pairs = function(self)
    local keys = {}
    for i = #self, 1, -1 do table.insert(keys, i) end

    return function(_, k)
        local v = nil
        k = table.remove(keys)
        if k then v = self[k] end
        return k, v
    end, self, nil
end

menuMT.__call = function(self, key)
    local idx = (math.type(key) == "integer") and key or self:indexWithAttachment(key)
    return idx and self:itemAtIndex(idx) or nil
end

menuMT.__len = function(self) return self:itemCount() end

-- Public interface ------------------------------------------------------

module.menu.item._characterMap = ls.makeConstantsTable(module.menu.item._characterMap)

local _originalMenuItemMTkeyEquivalent = menuItemMT.keyEquivalent
menuItemMT.keyEquivalent = function(self, ...)
    local args = table.pack(...)
    if args.n == 0 then
        local answer = _originalMenuItemMTkeyEquivalent(self)
        for k, v in pairs(module.menu.item._characterMap) do
            if answer == v then
                answer = k
                break
            end
        end
        return answer
    elseif args.n == 1 and type(args[1]) == "string" then
        local choice = args[1]
        for k, v in pairs(module.menu.item._characterMap) do
            if choice:lower() == k then
                choice = v
                break
            end
        end
        return _originalMenuItemMTkeyEquivalent(self, choice)
    else
        return _originalMenuItemMTkeyEquivalent(self, ...) -- allow normal error to occur
    end
end

menuMT.itemPropertyList = function(self, item, ...)
    local args = table.pack(...)
    if args.n == 0 then
        local results = {}
        local propertiesList = getmetatable(item)["_propertyList"] or {}
        for i,v in ipairs(propertiesList) do results[v] = item[v](item) end
        results._item = item
        results._type = getmetatable(item).__type
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

-- Legacy support --------------------------------------------------------

module.new             = module._legacy.new
module.newWithPriority = module._legacy.newWithPriority
module.priorities      = module._legacy.priorities

-- Return Module Object --------------------------------------------------

return module
