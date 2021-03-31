--- === plugins.finalcutpro.language ===
---
--- Final Cut Pro Language Plugin.

local require       = require

local config                    = require "cp.config"
local dialog                    = require "cp.dialog"
local fcp                       = require "cp.apple.finalcutpro"
local i18n                      = require "cp.i18n"
local localeID                  = require "cp.i18n.localeID"

local insert                    = table.insert
local displayErrorMessage       = dialog.displayErrorMessage

local mod = {}

--- plugins.finalcutpro.language.change(locale) -> none
--- Function
--- Changes the Final Cut Pro Language to the specified locale, if supported.
---
--- Parameters:
---  * locale - The `cp.i18n.localeID` or locale string you want to change to.
---
--- Returns:
---  * `true` if successful otherwise `false`
function mod.change(locale)

    if type(locale) == "string" then
        locale = localeID.forCode(locale)
    end

    if locale == nil then
        displayErrorMessage("failedToChangeLanguage")
        return false
    end

    --------------------------------------------------------------------------------
    -- If Final Cut Pro is running...
    --------------------------------------------------------------------------------
    if fcp.app:running() and not dialog.displayYesNoQuestion(i18n("changeFinalCutProLanguage"), i18n("doYouWantToContinue")) then
        return false
    end

    --------------------------------------------------------------------------------
    -- Update Final Cut Pro's settings:
    --------------------------------------------------------------------------------
    local currentLocale = fcp.app.currentLocale()
    if currentLocale ~= locale then
        local result = fcp.app.currentLocale(locale)
        if result ~= locale then
            displayErrorMessage(i18n("failedToChangeLanguage"))
            return false
        end
    end

    return true
end

-- getFinalCutProLanguagesMenu() -> table
-- Function
-- Generates the Final Cut Pro Languages Menu.
--
-- Parameters:
--  * None
--
-- Returns:
--  * The menu as a table.
local function getFinalCutProLanguagesMenu()
    local currentLocale = fcp.app:currentLocale()
    local result = {}
    for _,locale in ipairs(fcp.app:supportedLocales()) do
        insert(result, { title = locale.localName,  fn = function() mod.change(locale) end, checked = currentLocale == locale })
    end
    table.sort(result, function(a, b) return a.title < b.title end)
    return result
end

local plugin = {
    id = "finalcutpro.language",
    group = "finalcutpro",
    dependencies = {
        ["core.menu.manager"]               = "menu",
        ["core.preferences.panels.menubar"] = "prefs",
    },
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if FCPX is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    -------------------------------------------------------------------------------
    -- New Menu Section:
    -------------------------------------------------------------------------------
    local enabled = config.prop("menubar.global.FinalCutPro.enabled", true)
    local prefs = deps.prefs.panel
    prefs:addCheckbox(105,
        {
            label = i18n("show") .. " " .. i18n("finalCutPro"),
            onchange = function(_, params) enabled(params.checked) end,
            checked = enabled,
        }
    )

    local section = deps.menu.addSection(7777778)
        :addHeading(i18n("finalCutPro"))
        :setDisabledFn(function() return not enabled() or fcp.isFrontmost() end)

    -------------------------------------------------------------------------------
    -- The FCPX Languages Menu:
    -------------------------------------------------------------------------------
    local fcpxLangs = section:addMenu(100, function()
        if fcp:isSupported() then
            return i18n("language")
        end
    end)
    fcpxLangs:addItems(1, getFinalCutProLanguagesMenu)

    return mod
end

return plugin
