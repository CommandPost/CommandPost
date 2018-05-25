--- === plugins.core.language ===
---
--- Language Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
--local log           = require("hs.logger").new("lang")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local dialog        = require("hs.dialog")
local fs            = require("hs.fs")
local host          = require("hs.host")
local json          = require("hs.json")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config        = require("cp.config")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- LANGUAGE_PATH -> string
-- Constant
-- Language Path.
local LANGUAGE_PATH = config.languagePath

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.core.language.installedLanguages() -> table
--- Variable
--- A table of installed languages.
mod.installedLanguages = {}

--- plugins.core.language.loadCommandPostLanguages() -> nil
--- Function
--- Loads Command Post Languages
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.loadCommandPostLanguages()
    local languagePath = LANGUAGE_PATH
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
                    local fileLanguage = file:sub(1, -6)
                    local languageID
                    for id,_ in pairs(decoded) do
                        languageID = id
                    end
                    if fileLanguage and languageID then
                        mod.installedLanguages[#mod.installedLanguages + 1] = { id = languageID, language = fileLanguage }
                    end
                end
            end
        end
    end
    table.sort(mod.installedLanguages, function(a, b) return a.language < b.language end)
end

--- plugins.core.language.getCommandPostLanguages() -> table
--- Function
--- Gets CommandPost Languages in Table
---
--- Parameters:
---  * None
---
--- Returns:
---  * installedLanguages - table of Installed Languages
function mod.getCommandPostLanguages()
    if #mod.installedLanguages == 0 then
        mod.loadCommandPostLanguages()
    end
    return mod.installedLanguages
end

--- plugins.core.language.getUserLocale() -> string
--- Function
--- Gets a users locale.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The user locale as a string.
function mod.getUserLocale()
    local userLocale = config.get("language", host.locale.current())
    if string.find(userLocale, "_") ~= nil then
        userLocale = string.sub(userLocale, 1, string.find(userLocale, "_") - 1)
    end
    return userLocale
end

-- getCommandPostLanguagesMenu() -> nil
-- Function
-- Gets a table for the Menubar creation of all the supported CommandPost Languages.
--
-- Parameters:
--  * None
--
-- Returns:
--  * settingsLanguage - table of Supported Languages for CommandPost's Menubar
local function getCommandPostLanguagesMenu()
    local userLocale = config.get("language", nil)

    if mod._lastUserLocale ~= nil and mod._lastUserLocale == userLocale then
        return mod._lastCPLanguageCache
    else
        --log.df("Not using CommandPost Language Menu Cache")

        if userLocale == nil then userLocale = host.locale.current() end

        local basicUserLocale
        if string.find(userLocale, "_") ~= nil then
            basicUserLocale = string.sub(userLocale, 1, string.find(userLocale, "_") - 1)
        else
            basicUserLocale = userLocale
        end

        local settingsLanguage = {}
        local commandPostLanguages = mod.getCommandPostLanguages()
        for i,language in ipairs(commandPostLanguages) do

            local checkedLanguage = (userLocale == language["id"] or basicUserLocale == language["id"])
            if checkedLanguage then
                --log.df("Setting CommandPost Language to: %s", language["id"])
                config.set("language", language["id"])
            end

            settingsLanguage[i] = { title = language["language"], fn = function()
                config.set("language", language["id"])
                i18n.setLocale(language["id"])
            end, checked = checkedLanguage, }

        end

        mod._lastUserLocale = userLocale
        mod._lastCPLanguageCache = settingsLanguage

        return settingsLanguage
    end
end

-- getLanguageOptions() -> nil
-- Function
-- Gets a table of language options.
--
-- Parameters:
--  * None
--
-- Returns:
--  * A table of language options.
local function getLanguageOptions()
    local options = {}
    local languages = mod.getCommandPostLanguages()
    for _,language in ipairs(languages) do
        options[#options+1] = {
            value = language.id,
            label = language.language,
        }
    end
    return options
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "core.language",
    group           = "core",
    dependencies    = {
        ["core.preferences.panels.general"] = "general",
        ["core.preferences.manager"]        = "manager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    -------------------------------------------------------------------------------
    -- Cache Languages on Load:
    -------------------------------------------------------------------------------
    getCommandPostLanguagesMenu()

    --------------------------------------------------------------------------------
    -- Setup General Preferences Panel:
    --------------------------------------------------------------------------------
    deps.general
        :addHeading(40, i18n("languageHeading"))
        :addSelect(41,
            {
                width       = 237,
                value       = mod.getUserLocale,
                options     = getLanguageOptions,
                required    = true,
                onchange    = function(_, params)
                    dialog.webviewAlert(deps.manager.getWebview(), function(result)
                        if result == i18n("yes") then
                            config.set("language", params.value)
                            i18n.setLocale(params.value)
                            hs.reload()
                        end
                    end, i18n("changeLanguageRestart"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"))
                end,
            }
        )
        :addButton(41.2,
            {
                label 		= i18n("suggestATranslation"),
                width		= 200,
                onclick		= function() hs.execute("open '" .. config.translationURL .. "'") end,
            }
        )
        :addButton(41.3,
            {
                label 		= i18n("reportATranslationMistake"),
                width		= 200,
                onclick		= function() hs.execute("open '" .. config.translationURL .. "'") end,
            }
        )
    return mod
end

return plugin
