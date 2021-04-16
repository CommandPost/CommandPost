--- === cp.18n ===
---
--- CommandPost's Internationalisation & Localisation Manger.

local require       = require

local log           = require "hs.logger".new "i18n"

local fs            = require "hs.fs"
local host          = require "hs.host"
local json          = require "hs.json"

local config        = require "cp.config"
local tools         = require "cp.tools"

local i18n          = require "i18n"

local dir           = fs.dir
local locale        = host.locale
local mergeTable    = tools.mergeTable
local read          = json.read
local split         = tools.split

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
                    local fileSplit = split(file, "_")
                    local fileLanguage = fileSplit[1]
                    local languageCode = fileSplit[2]:sub(1, -6)

                    --------------------------------------------------------------------------------
                    -- Only load English and the active language:
                    --------------------------------------------------------------------------------
                    if languageCode == "en" or languageCode == userLocale then
                        --log.df("Loading: %s - %s", fileLanguage, languageCode)
                        allLanguages = mergeTable(allLanguages, {[languageCode] = data})
                    end

                    --------------------------------------------------------------------------------
                    -- Add language to the table of installed languages:
                    --------------------------------------------------------------------------------
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
