--- === hs._asm.guitk.element ===
---
--- Elements which can be used with `hs._asm.guitk.manager` objects for display `hs._asm.guitk` windows.

local USERDATA_TAG = "hs._asm.guitk.element"
local module       = {}

require("hs.drawing.color")
require("hs.image")
require("hs.styledtext")

local fnutils = require("hs.fnutils")
local inspect = require("hs.inspect")

local commonControllerMethods = require(USERDATA_TAG .. "._controller")
local commonViewMethods       = require(USERDATA_TAG .. "._view")

local metatables = {}
local basePath = package.searchpath(USERDATA_TAG, package.path)
if basePath then
    basePath = basePath:match("^(.+)/init.lua$")
    local fs = require("hs.fs")
    for file in fs.dir(basePath) do
        if file:match("^[^_].*%.so$") then
            local name = file:match("^(.*)%.so$")
            module[name] = require(USERDATA_TAG .. "." .. name)
            metatables[name] = hs.getObjectMetatable(USERDATA_TAG .. "." .. name)
        end
    end

    if fs.attributes(basePath .. "/docs.json") then
        require"hs.doc".registerJSONFile(basePath .. "/docs.json")
    end
else
    return error("unable to determine basepath for " .. USERDATA_TAG, 2)
end

-- local log = require("hs.logger").new(USERDATA_TAG, require"hs.settings".get(USERDATA_TAG .. ".logLevel") or "warning")

-- private variables and methods -----------------------------------------

-- Public interface ------------------------------------------------------

module.datepicker.calendarIdentifiers = ls.makeConstantsTable(module.datepicker.calendarIdentifiers)

for k,v in pairs(metatables) do

    -- if requested, merge in common controller methods and update properties table
    if v._inheritController then
        local propertieslist = v._propertyList or {}
        for k2,v2 in pairs(commonControllerMethods) do
            if not v[k2] then
                if type(v2) == "function" then
                    v[k2] = function(self, ...)
                        if getmetatable(self) ~= v then -- keep an explicit override
                            error(string.format("ERROR: incorrect userdata type for argument 1 (expected %s)", v.__type), 2)
                        end
                        return v2(self, ...)
                    end
                    if fnutils.contains(commonControllerMethods._propertyList, k2) then
                        table.insert(propertieslist, k2)
                    end
                else
                    v[k2] = v2
                end
            end
        end
        v._propertyList      = propertieslist
        v._inheritController = nil
    end

    -- if requested, merge in common view methods and update properties table
    if v._inheritView then
        local propertieslist = v._propertyList or {}
        for k2,v2 in pairs(commonViewMethods) do
            if not v[k2] then
                if type(v2) == "function" then
                    v[k2] = function(self, ...)
                        if getmetatable(self) ~= v then -- keep an explicit override
                            error(string.format("ERROR: incorrect userdata type for argument 1 (expected %s)", v.__type), 2)
                        end
                        return v2(self, ...)
                    end
                    if fnutils.contains(commonViewMethods._propertyList, k2) then
                        table.insert(propertieslist, k2)
                    end
                else
                    v[k2] = v2
                end
            end
        end
        v._propertyList = propertieslist
        v._inheritView  = nil
    end

    -- if nextResponder method exists, allow passing unrecognized methods up the chain
    if v._nextResponder then
        v.__core = v.__index
        v.__index = function(self, key)
            if v.__core[key] then
                return v.__core[key]
            elseif type(key) == "string" then
                local parentObj = self:_nextResponder()
                if parentObj then
                    local parentFN = parentObj[key]
                    if parentFN then
                        if type(parentFN) == "function" then
                            return function(self, ...)
                                local answer = parentFN(parentObj, ...)
                                if answer == parentObj then
                                    return self
                                else
                                    return answer
                                end
                            end
                        else
                            return parentFN
                        end
                    else
    -- if parent has a method matching our key prefixed with "element", pass self in as first argument
                        parentFN = parentObj["element" .. key:sub(1,1):upper() .. key:sub(2)]
                        if parentFN then
                            if type(parentFN) == "function" then
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
            end
            return nil
        end
    end
end

-- Return Module Object --------------------------------------------------

return module
