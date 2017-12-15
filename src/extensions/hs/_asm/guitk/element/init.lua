--- === hs._asm.guitk.element ===
---
--- THis submodule provides common methods and metamethods linking a variety of visual elements that can be used with `hs._asm.guitk` to build your own visual displays and input  interfaces within Hammerspoon.
---
--- This module by itself provides no elements, but serves as the glue between it's submodules and the guitk window and manager objects.  Elements are defined as submodules to this and may inherit methods defined in `hs._asm.guitk.element._control` and `hs._asm.guitk.element._view`.  The documentation for each specific element will indicate if it inherits methods from one of these helper submodules.
---
--- Methods invoked on element userdata objects which are not recognized by the element itself are passed up the responder chain (`hs._asm.guitk.manager` and `hs._asm.guitk`) as well, allowing you to work from the userdata which is most relevant without having to track the userdata for its supporting infrastructure separately. This will become more clear in the examples provided at a location to be determined (currently in the [../Examples](../Examples) directory of this repository folder).

local USERDATA_TAG = "hs._asm.guitk.element"
local module       = {}

require("hs.drawing.color")
require("hs.image")
require("hs.styledtext")

local fnutils = require("hs.fnutils")
local inspect = require("hs.inspect")

local commonControlMethods = require(USERDATA_TAG .. "._control")
local commonViewMethods    = require(USERDATA_TAG .. "._view")

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

module.datepicker.calendarIdentifiers   = ls.makeConstantsTable(module.datepicker.calendarIdentifiers)
module.datepicker.timezoneAbbreviations = ls.makeConstantsTable(module.datepicker.timezoneAbbreviations)
module.datepicker.timezoneNames         = ls.makeConstantsTable(module.datepicker.timezoneNames)

for k,v in pairs(metatables) do

    -- if requested, merge in common control methods and update properties table
    if v._inheritControl then
        local propertieslist = v._propertyList or {}
        for k2,v2 in pairs(commonControlMethods) do
            if not v[k2] then
                if type(v2) == "function" then
                    v[k2] = function(self, ...)
                        if getmetatable(self) ~= v then -- keep an explicit override
                            error(string.format("ERROR: incorrect userdata type for argument 1 (expected %s)", v.__type), 2)
                        end
                        return v2(self, ...)
                    end
                    if fnutils.contains(commonControlMethods._propertyList, k2) then
                        table.insert(propertieslist, k2)
                    end
                else
                    v[k2] = v2
                end
            end
        end
        v._propertyList      = propertieslist
        v._inheritControl = nil
    end

    -- if requested, merge in common view methods and update properties table
--     if v._inheritView then
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
--         v._inheritView  = nil
--     end

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
                        if type(parentFN) == "function" or (getmetatable(parentFN) or {}).__call then
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
            end
            return nil
        end
    end
end

-- Return Module Object --------------------------------------------------

return module
