--- === plugins.core.language ===
---
--- Language Module.

local require       = require

local hs            = hs

local dialog        = require "hs.dialog"
local host          = require "hs.host"

local config        = require "cp.config"
local i18n          = require "cp.i18n"

local execute       = hs.execute
local find          = string.find
local locale        = host.locale
local sub           = string.sub

local plugin = {
    id              = "core.language",
    group           = "core",
    dependencies    = {
        ["core.preferences.panels.general"] = "general",
        ["core.preferences.manager"]        = "manager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Setup General Preferences Panel:
    --------------------------------------------------------------------------------
    deps.general
        :addHeading(40, i18n("languageHeading"))
        :addSelect(41,
            {
                width       =   237,
                value       =   function()
                                    local userLocale = config.get("language", locale.current())
                                    if string.find(userLocale, "_") ~= nil then
                                        userLocale = sub(userLocale, 1, find(userLocale, "_") - 1)
                                    end
                                    return userLocale
                                end,
                options     =   function()
                                    local options = {}
                                    local languages = i18n.installedLanguages
                                    for _,language in ipairs(languages) do
                                    options[#options+1] = {
                                        value = language.id,
                                        label = language.language,
                                    }
                                    end
                                    return options
                                end,
                required    =   true,
                onchange    =   function(_, params)
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
                label 		= i18n("helpTranslateCommandPost"),
                width		= 200,
                onclick		= function() execute("open '" .. config.translationURL .. "'") end,
            }
        )
end

return plugin
