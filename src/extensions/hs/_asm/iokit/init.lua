--- === hs._asm.iokit ===
---
--- Stuff about the module

local USERDATA_TAG = "hs._asm.iokit"
local module       = require(USERDATA_TAG..".internal")
local objectMT     = hs.getObjectMetatable(USERDATA_TAG)

local basePath = package.searchpath(USERDATA_TAG, package.path)
if basePath then
    basePath = basePath:match("^(.+)/init.lua$")
    if require"hs.fs".attributes(basePath .. "/docs.json") then
        require"hs.doc".registerJSONFile(basePath .. "/docs.json")
    end
end

-- local log = require("hs.logger").new(USERDATA_TAG, require"hs.settings".get(USERDATA_TAG .. ".logLevel") or "warning")

-- private variables and methods -----------------------------------------

-- Public interface ------------------------------------------------------

module.serviceForRegistryID = function(id)
    local matchCriteria = module.dictionaryMatchingRegistryID(id)
    return matchCriteria and module.serviceMatching(matchCriteria) or nil
end

module.serviceForBSDName = function(name)
    local matchCriteria = module.dictionaryMatchingBSDName(name)
    return matchCriteria and module.serviceMatching(matchCriteria) or nil
end

module.serviceForName = function(name)
    local matchCriteria = module.dictionaryMatchingName(name)
    return matchCriteria and module.serviceMatching(matchCriteria) or nil
end

module.servicesForClass = function(class)
    local matchCriteria = module.dictionaryMatchingClass(class)
    return matchCriteria and module.servicesMatching(matchCriteria) or nil
end

objectMT.bundleID = function(self, ...)
    return module.bundleIDForClass(self:class(...))
end

objectMT.superclass = function(self, ...)
    return module.superclassForClass(self:class(...))
end

-- Return Module Object --------------------------------------------------

return module
