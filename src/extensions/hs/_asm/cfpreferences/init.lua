--- === hs._asm.cfpreferences ===
---
--- Stuff about the module

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
