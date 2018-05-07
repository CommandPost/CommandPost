--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--       F I N A L    C U T    P R O    L A N G U A G E    P L U G I N        --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.language ===
---
--- Final Cut Pro Language Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local dialog        = require("cp.dialog")
local fcp           = require("cp.apple.finalcutpro")
local localeID      = require("cp.i18n.localeID")

local insert        = table.insert

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- PRIORITY
-- Constant
-- The menubar position priority.
local PRIORITY = 6

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
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
        dialog.displayErrorMessage("failedToChangeLanguage")
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
            dialog.displayErrorMessage(i18n("failedToChangeLanguage"))
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

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.language",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.menu.top"]            = "top",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    -------------------------------------------------------------------------------
    -- New Menu Section:
    -------------------------------------------------------------------------------
    local section = deps.top:addSection(PRIORITY)

    -------------------------------------------------------------------------------
    -- The FCPX Languages Menu:
    -------------------------------------------------------------------------------
    local fcpxLangs = section:addMenu(100, function()
        if fcp.app:installed() then
            return i18n("finalCutProLanguage")
        end
    end)
    fcpxLangs:addItems(1, getFinalCutProLanguagesMenu)

    return mod
end

return plugin