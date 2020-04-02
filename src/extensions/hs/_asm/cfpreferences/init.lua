--- === hs._asm.cfpreferences ===
---
--- Stuff about the module

-- maybe save some pain, if the shim is installed; otherwise, expect an objc dump to console when this loads on stock Hammerspoon without pull #2308 applied
if package.searchpath("hs._asm.coroutineshim", package.path) then
    require"hs._asm.coroutineshim"
end

local USERDATA_TAG = "hs._asm.cfpreferences"
local module       = require(USERDATA_TAG..".internal")

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

-- module.predefinedKeys = ls.makeConstantsTable(module.predefinedKeys)

-- Return Module Object --------------------------------------------------

return module
