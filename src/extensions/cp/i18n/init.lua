--- === cp.18n ===
---
--- CommandPost's Internationalisation & Localisation Manger.

local require = require

local log                       = require("hs.logger").new("i18n")

local fs                        = require("hs.fs")
local host                      = require("hs.host")
local json                      = require("hs.json")

local config                    = require("cp.config")
local tools                     = require("cp.tools")

local i18n                      = require("i18n")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- cp.18n.init() -> none
--- Function
--- Initialise the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init()
    local cpi18n = i18n
    if not mod._loaded then
        local languagePath = config.languagePath
        local allLanguages = {}
        local iterFn, dirObj = fs.dir(languagePath)
        if not iterFn then
            log.ef("An error occured in cp.18n.init: %s", dirObj)
        else
            for file in fs.dir(languagePath) do
                if file:sub(-5) == ".json" then
                    local path = languagePath .. "/" .. file
                    local data = io.open(path, "r")
                    local content, decoded
                    if data then
                        content = data:read("*all")
                        data:close()
                    end
                    if content then
                        decoded = json.decode(content)
                        if decoded and type(decoded) == "table" then
                            allLanguages = tools.mergeTable(allLanguages, decoded)
                        end
                    end
                end
            end
        end
        if next(allLanguages) ~= nil then
            cpi18n.load(allLanguages)
        end
        local userLocale
        if config.get("language") == nil then
            userLocale = host.locale.current()
        else
            userLocale = config.get("language")
        end
        cpi18n.setLocale(userLocale)
    end
    return cpi18n
end

return mod.init()
