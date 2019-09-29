--- === cp.apple ===
---
--- A collection of modules related to Apple apps and frameworks.

local require   = require
local log       = require "hs.logger" .new "cp.apple"

local loader = {
    name = "cp.apple"
}
setmetatable(loader, {
    __index = function(self, key)
        local ok, result = xpcall(function() return require(self.name .. "." .. key) end, debug.traceback)
        if not ok then
            error(string.format("Error while loading extension '%s.%s': %s", self.name, key, result), 2)
        end
        log.df("Loading extension: %s.%s", self.name, key)
        self[key] = result
        return result
    end
})

return loader