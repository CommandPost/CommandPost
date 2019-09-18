--- === cp.18n ===
---
--- CommandPost's Internationalisation & Localisation Manger.

local require   = require

local log       = require "hs.logger".new "i18n"

local fs        = require "hs.fs"
local host      = require "hs.host"
local json      = require "hs.json"

local config    = require "cp.config"
local tools     = require "cp.tools"

local i18n      = require "i18n"

local locale    = host.locale
local read      = json.read
local dir       = fs.dir

local mod = {}

-- getLanguageCode(t) -> string
-- Function
-- Gets the language code from a table
--
-- Parameters:
--  * The table containing the language data
--
-- Returns:
--  * A string with the language code
local function getLanguageCode(t)
    -- TODO: There has to be a smarter way to do this?
    for id, _ in pairs(t) do -- luacheck: ignore
        return id
    end
end

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

    --- cp.i18n.installedLanguages -> table
    --- Variable
    --- A table containing all of the installed languages.
    cpi18n.installedLanguages = {}

    local userLocale
    if config.get("language") == nil then
        userLocale = locale.current()
    else
        userLocale = config.get("language")
    end

    local languagePath = config.languagePath
    local allLanguages = {}
    local iterFn, dirObj = dir(languagePath)
    if not iterFn then
        log.ef("An error occured in cp.18n.init: %s", dirObj)
    else
        for file in dir(languagePath) do
            if file:sub(-5) == ".json" then
                local path = languagePath .. "/" .. file
                local data = read(path)
                if data then
                    --------------------------------------------------------------------------------
                    -- Only load English and the active language:
                    --------------------------------------------------------------------------------
                    if (data["en"] or data[userLocale]) then
                        allLanguages = tools.mergeTable(allLanguages, data)
                    end

                    --------------------------------------------------------------------------------
                    -- Add language to the table of installed languages:
                    --------------------------------------------------------------------------------
                    local fileLanguage = file:sub(1, -6)
                    local languageCode = getLanguageCode(data)
                    table.insert(cpi18n.installedLanguages, { id = languageCode, language = fileLanguage })
                end
            end
        end
    end
    if next(allLanguages) ~= nil then
        cpi18n.load(allLanguages)
    end

    --------------------------------------------------------------------------------
    -- Sort the table of installed languages:
    --------------------------------------------------------------------------------
    table.sort(cpi18n.installedLanguages, function(a, b) return a.language < b.language end)

    cpi18n.setLocale(userLocale)
    return cpi18n
end

return mod.init()
