--- === plugins.finalcutpro.menu.menuaction ===
---
--- A `action` which will trigger an Final Cut Pro menu with a matching path, if available/enabled.
--- Registers itself with the `plugins.core.actions.actionmanager`.

local require = require

local log               = require "hs.logger".new "menuaction"

local fnutils           = require "hs.fnutils"
local host              = require "hs.host"
local image             = require "hs.image"

local config            = require "cp.config"
local destinations      = require "cp.apple.finalcutpro.export.destinations"
local fcp               = require "cp.apple.finalcutpro"
local i18n              = require "cp.i18n"
local localeID          = require "cp.i18n.localeID"
local text              = require "cp.web.text"
local tools             = require "cp.tools"

local concat            = table.concat
local imageFromPath     = image.imageFromPath
local insert            = table.insert
local locale            = host.locale
local localizedString   = locale.localizedString
local unescapeXML       = text.unescapeXML

local findCommonWordWithinTwoStrings = tools.findCommonWordWithinTwoStrings

local mod = {}

-- ID -> string
-- Constant
-- The menu ID.
local ID = "menu"

-- GROUP -> string
-- Constant
-- The group ID.
local GROUP = "fcpx"

-- ICON -> hs.image object
-- Constant
-- Icon
local ICON = imageFromPath(config.basePath .. "/plugins/finalcutpro/console/images/menu.png")

--- plugins.finalcutpro.menu.menuaction.actionId(params) -> string
--- Function
--- Gets the action ID from the parameters table.
---
--- Parameters:
---  * params - Parameters table.
---
--- Returns:
---  * Action ID as string.
function mod.actionId(params)
    return ID .. ":" .. concat(params.path, "||")
end

-- processSubMenu(menu, path, localeCode, choices) -> table
-- Function
-- Processes a Final Cut Pro sub-menu.
--
-- Parameters:
--  * menu - The menu table to process
--  * localeCode - The current locale code
--  * choices - A table of existing choices
--  * path - A table containing the current path
--
-- Returns:
--  * A table of choices.
local function processSubMenu(menu, localeCode, choices, path)
    for _, v in pairs(menu) do
        if type(v) == "table" then
            if not v.seperator and v[localeCode] and v[localeCode] ~= "" and v.submenu then
                --------------------------------------------------------------------------------
                -- Submenu:
                --------------------------------------------------------------------------------
                local newPath = fnutils.copy(path)
                local title = unescapeXML(v[localeCode])
                table.insert(newPath, title)
                choices = processSubMenu(v.submenu, localeCode, choices, newPath)
            elseif not v.seperator and v[localeCode] and v[localeCode] ~= "" then
                --------------------------------------------------------------------------------
                -- Menu Item:
                --------------------------------------------------------------------------------
                local title = unescapeXML(v[localeCode])
                local params = {}
                params.path = fnutils.concat(fnutils.copy(path), { title })
                params.locale = localeCode
                params.plain = true
                table.insert(choices, {
                    text = title,
                    subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
                    params = params,
                    id = mod.actionId(params),
                })
            end
        end
    end
    return choices
end

-- processMenu(menu, path, localeCode, choices) -> table
-- Function
-- Processes a Final Cut Pro menu.
--
-- Parameters:
--  * menu - The menu table to process
--  * localeCode - The current locale code
--
-- Returns:
--  * A table of choices.
local function processMenu(menu, localeCode)
    local choices = {}
    for _, v in pairs(menu) do
        if type(v) == "table" then
            if v.submenu and v[localeCode] and v[localeCode] ~= "Debug" then
                local path = { v[localeCode] }
                choices = processSubMenu(v.submenu, localeCode, choices, path)
            end
        end
    end
    return choices
end

-- legacyScan() -> table
-- Function
-- Scans the Final Cut Pro Menubar via the Accessibility Framework.
--
-- Parameters:
--  * None
--
-- Returns:
--  * A table of choices.
local function legacyScan() -- luacheck: ignore
    local choices = {}
    fcp:menu():visitMenuItems(function(path, menuItem)
        local title = menuItem:title()
        if path[1] ~= "Apple" then
            local params = {}
            params.path = fnutils.concat(fnutils.copy(path), { title })
            params.locale = fcp:currentLocale().code
            insert(choices, {
                text = title,
                subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
                params = params,
                id = mod.actionId(params),
            })
        end
    end)
    return choices
end

-- compareLegacyVersusNew(choices) -> table
-- Function
-- Compares the supplied choices with the legacy choices.
--
-- Parameters:
--  * choices - The new choices to compare
--
-- Returns:
--  * None
local function compareLegacyVersusNew(choices) -- luacheck: ignore
    --hs.console.clearConsole()
    local result = "\n"
    local legacyChoices = legacyScan()
    result = result .. "In Legacy Choices, but not in New Choices:" .. "\n"
    for _, v in pairs(legacyChoices) do
        local match = false
        for _, vv in pairs(choices) do
            if v.text == vv.text then
                match = true
                break
            end
            --------------------------------------------------------------------------------
            -- Ignore the "Services" list:
            --------------------------------------------------------------------------------
            if v.params and v.params.path and v.params.path[1] == "Final Cut Pro" and v.params.path[2] == "Services" then
                match = true
                break
            end
            --------------------------------------------------------------------------------
            -- Ignore the "Duplicate Captions to New Language" list:
            --------------------------------------------------------------------------------
            if v.params and v.params.path and v.params.path[1] == "Edit" and v.params.path[2] == "Captions" and v.params.path[3] == "Duplicate Captions to New Language" then
                match = true
                break
            end
        end
        if not match then
            result = result .. string.format("%s (%s)", v.text, v.subText) .. "\n"
        end
    end
    result = result .. "\n"
    result = result .. "\n"
    result = result .. "In New Choices, but not in Legacy Choices:" .. "\n"
    for _, v in pairs(choices) do
        local match = false
        for _, vv in pairs(legacyChoices) do
            if v.text == vv.text then
                match = true
                break
            end
        end
        if not match then
            result = result .. string.format("%s (%s)", v.text, v.subText) .. "\n"
        end
    end
    log.df("%s", result)
end

local function contentsInsideBrackets(a)
    local b = string.match(a, "%(.*%)")
    return b and b:sub(2, -2)
end

-- applyMenuWorkarounds(choices) -> table
-- Function
-- Applies a bunch of workarounds to the choices table.
--
-- Parameters:
--  * choices - A table of choices
--  * currentLocaleCode - Current locale code
--
-- Returns:
--  * A new table of choices
local function applyMenuWorkarounds(choices, currentLocaleCode)
    --------------------------------------------------------------------------------
    --
    -- WORKAROUNDS FOR MENU ITEMS THAT WERE NOT IN THE NIB:
    --
    --------------------------------------------------------------------------------
    local en = localeID("en")
    local fcpLocaleCode = fcp:currentLocale().code

    --------------------------------------------------------------------------------
    -- Final Cut Pro > Commands
    --------------------------------------------------------------------------------
    local userCommandSets = fcp:userCommandSets()
    for _, title in pairs(userCommandSets) do
        local path = {"Final Cut Pro", "Commands"}
        local params = {}
        params.path = fnutils.concat(fnutils.copy(path), { title })
        params.locale = en
        params.plain = true
        table.insert(choices, {
            text = title,
            subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
            params = params,
            id = mod.actionId(params),
        })
    end

    --------------------------------------------------------------------------------
    -- Customize… (Menu: Final Cut Pro > Commands)
    --------------------------------------------------------------------------------
    do
        local title = fcp:string("Customize")
        local path = {"Final Cut Pro", "Commands"}
        local params = {}
        params.path = fnutils.concat(fnutils.copy(path), { title .. ".*" })
        params.locale = en
        params.plain = true
        table.insert(choices, {
            text = title,
            subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
            params = params,
            id = mod.actionId(params),
        })
    end

    --------------------------------------------------------------------------------
    -- Import… (Menu: Final Cut Pro > Commands)
    --------------------------------------------------------------------------------
    do
        local title = fcp:string("Import")
        local path = {"Final Cut Pro", "Commands"}
        local params = {}
        params.path = fnutils.concat(fnutils.copy(path), { title .. ".*" })
        params.locale = en
        params.plain = true
        table.insert(choices, {
            text = title,
            subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
            params = params,
            id = mod.actionId(params),
        })
    end

    --------------------------------------------------------------------------------
    -- Export… (Menu: Final Cut Pro > Commands)
    --------------------------------------------------------------------------------
    do
        local title = fcp:string("Export")
        local path = {"Final Cut Pro", "Commands"}
        local params = {}
        params.path = fnutils.concat(fnutils.copy(path), { title .. ".*" })
        params.locale = en
        params.plain = true
        table.insert(choices, {
            text = title,
            subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
            params = params,
            id = mod.actionId(params),
        })
    end

    --------------------------------------------------------------------------------
    -- Command Sets (Menu: Final Cut Pro > Commands)
    -- Custom Command Sets (Menu: Final Cut Pro > Commands)
    --------------------------------------------------------------------------------

        -- NOTE: These are just un-click-able descriptions.

    --------------------------------------------------------------------------------
    -- Final Cut Pro > Services
    --------------------------------------------------------------------------------

        -- TODO: Need to build a list of services.
        --       On my machine I only see "Development" tools in the Services list
        --       when clicking on the Final Cut Pro menu, however I can see a lot
        --       more listed in UI Browser.

    --------------------------------------------------------------------------------
    -- File > Share
    --------------------------------------------------------------------------------
    local shares = destinations.names()
    for _, title in pairs(shares) do
        title = title .. "…"
        local path = {"File", "Share"}
        local params = {}
        params.path = fnutils.concat(fnutils.copy(path), { title })
        params.locale = en
        params.plain = true
        table.insert(choices, {
            text = title,
            subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
            params = params,
            id = mod.actionId(params),
        })
    end

    --------------------------------------------------------------------------------
    -- File > Share > Add Destination…
    --------------------------------------------------------------------------------
    do
        local title = fcp:string("FFNewDestinationTitle")
        local path = {"File", "Share"}
        local params = {}
        params.path = fnutils.concat(fnutils.copy(path), { title })
        params.locale = en
        params.plain = true
        table.insert(choices, {
            text = title,
            subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
            params = params,
            id = mod.actionId(params),
        })
    end

    --------------------------------------------------------------------------------
    -- Edit > Captions > Duplicate Captions to New Language >
    --
    -- af           Afrikaans
    -- ar           Arabic
    -- bg           Bulgarian
    -- ca           Catalan
    -- zh_Hans      Chinese (Simplified)
    -- zh_Hant      Chinese (Traditional)
    -- hr           Croatian
    -- cs           Czech
    -- da           Danish
    -- et           Estonian
    -- fi           Finnish
    -- nl           Dutch
    -- he           Hebrew
    -- hi           Hindi
    -- hu           Hungarian
    -- is           Icelandic
    -- id           Indonesian
    -- it           Italian
    -- ja           Japanese
    -- kn           Kannada
    -- kk           Kazakh
    -- ko           Korean
    -- lo           Lao
    -- lv           Latvian
    -- lt           Lithuanian
    -- lb           Luxembourgish
    -- ms           Malay
    -- ml           Malayalam
    -- mt           Maltese
    -- mr           Marathi
    -- pl           Polish
    -- pa           Punjabi
    -- ro           Romanian
    -- ru           Russian
    -- gd           Scottish Gaelic
    -- sk           Slovak
    -- sl           Slovenian
    -- sv           Swedish
    -- ta           Tamil
    -- te           Telugu
    -- th           Thai
    -- tr           Turkish
    -- uk           Ukrainian
    -- ur           Urdu
    -- vi           Vietnamese
    -- cy           Welsh
    -- zu           Zulu
    --------------------------------------------------------------------------------
    local easyLanguages = {"af", "ar", "bg", "ca", "zh_Hans", "zh_Hant", "hr", "cs", "da", "et", "fi", "nl", "he", "hi", "hu", "is", "id", "it", "ja", "kn", "kk", "ko", "lo", "lv", "lt", "lb", "ms", "ml", "mt", "mr", "pl", "pa", "ro", "ru", "gd", "sk", "sl", "sv", "ta", "te", "th", "tr", "uk", "ur", "vi", "cy", "zu"}
    for _, code in pairs(easyLanguages) do
        local _, title = localizedString(code, fcpLocaleCode)
        local _, enTitle = localizedString(code, "en")
        local path = {"Edit", "Captions", "Duplicate Captions to New Language"}
        local params = {}
        params.path = fnutils.concat(fnutils.copy(path), { enTitle })
        params.locale = en
        params.plain = true
        table.insert(choices, {
            text = title,
            subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
            params = params,
            id = mod.actionId(params),
        })
    end

    --------------------------------------------------------------------------------
    -- Edit > Captions > Duplicate Captions to New Language >
    --
    -- zh           Chinese (Cantonese)
    --------------------------------------------------------------------------------
    do
        local chineseString = localizedString("zh")
        local cantoneseString = localizedString("yue")

        local enChineseString = localizedString("zh", "en")
        local enCantoneseString = localizedString("yue", "en")

        local title = chineseString .. " (" .. cantoneseString .. ")"
        local path = {"Edit", "Captions", "Duplicate Captions to New Language"}
        local params = {}
        params.path = fnutils.concat(fnutils.copy(path), { enChineseString .. " (" .. enCantoneseString .. ")" })
        params.locale = en
        params.plain = true
        table.insert(choices, {
            text = title,
            subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
            params = params,
            id = mod.actionId(params),
        })
    end

    --------------------------------------------------------------------------------
    -- Edit > Captions > Duplicate Captions to New Language >
    --
    -- no           Norwegian
    --
    -- NOTE: The workaround for this is to compare the 'nb' and 'nn' localised
    --       strings.
    --------------------------------------------------------------------------------
    do
        local nbString = localizedString("nb")
        local nnString = localizedString("nn")

        local enNbString = localizedString("nb", "en")
        local enNnString = localizedString("nn", "en")

        local norwegianString = findCommonWordWithinTwoStrings(nbString, nnString)
        local enNorwegianString = findCommonWordWithinTwoStrings(enNbString, enNnString)

        local title = norwegianString
        local path = {"Edit", "Captions", "Duplicate Captions to New Language"}
        local params = {}
        params.path = fnutils.concat(fnutils.copy(path), { enNorwegianString })
        params.locale = en
        params.plain = true
        table.insert(choices, {
            text = title,
            subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
            params = params,
            id = mod.actionId(params),
        })
    end

    --------------------------------------------------------------------------------
    -- Edit > Captions > Duplicate Captions to New Language >
    --
    -- bn           Bangla
    -- tl           Tagalog
    --------------------------------------------------------------------------------

        -- TODO: I have no idea how to get these values. 'bn' returns "Bengali"

    --------------------------------------------------------------------------------
    -- Edit > Captions > Duplicate Captions to New Language > English >
    --
    -- en_AU            Australia                   -- English (Australia)
    -- en_CA            Canada                      -- English (Canada)
    -- en_GB            United Kingdom              -- English (United Kingdom)
    -- en_US            United States               -- English (United States)
    --------------------------------------------------------------------------------
    local englishVariants = {"en_AU", "en_CA", "en_GB", "en_US"}
    for _, code in pairs(englishVariants) do
        local _, a = localizedString(code, fcpLocaleCode)
        local _, b = localizedString(code, "en")
        local title = contentsInsideBrackets(a)
        local path = {"Edit", "Captions", "Duplicate Captions to New Language", "English"}
        local params = {}
        params.path = fnutils.concat(fnutils.copy(path), { contentsInsideBrackets(b) })
        params.locale = en
        params.plain = true
        table.insert(choices, {
            text = title,
            subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
            params = params,
            id = mod.actionId(params),
        })
    end

    --------------------------------------------------------------------------------
    -- Edit > Captions > Duplicate Captions to New Language > French >
    --
    -- fr_BE            Belgium                     -- French (Belgium)
    -- fr_CA            Canada                      -- French (Canada)
    -- fr_FR            France                      -- French (France)
    -- fr_CH            Switzerland                 -- French (Switzerland)
    --------------------------------------------------------------------------------
    local frVariants = {"fr_BE", "fr_CA", "fr_FR", "fr_CH"}
    for _, code in pairs(frVariants) do
        local _, a = localizedString(code, fcpLocaleCode)
        local _, b = localizedString(code, "en")
        local title = contentsInsideBrackets(a)
        local path = {"Edit", "Captions", "Duplicate Captions to New Language", "French"}
        local params = {}
        params.path = fnutils.concat(fnutils.copy(path), { contentsInsideBrackets(b) })
        params.locale = en
        params.plain = true
        table.insert(choices, {
            text = title,
            subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
            params = params,
            id = mod.actionId(params),
        })
    end

    --------------------------------------------------------------------------------
    -- Edit > Captions > Duplicate Captions to New Language > English/German/Greek > All
    --------------------------------------------------------------------------------
    local allString = fcp:string("FFLanguageIdentifierPopupAllCountries")
    local allMenus = {"English", "German", "Greek"}
    for _, a in pairs(allMenus) do
        local title = allString
        local path = {"Edit", "Captions", "Duplicate Captions to New Language", a}
        local params = {}
        params.path = fnutils.concat(fnutils.copy(path), { title })
        params.locale = en
        params.plain = true
        table.insert(choices, {
            text = title,
            subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
            params = params,
            id = mod.actionId(params),
        })
    end

    --------------------------------------------------------------------------------
    -- Edit > Captions > Duplicate Captions to New Language > German >
    --
    -- de_AT            Austria                     -- German (Austria)
    -- de_DE            Germany                     -- German (Germany)
    -- de_CH            Switzerland                 -- German (Switzerland)
    --------------------------------------------------------------------------------
    local deVariants = {"de_AT", "de_DE", "de_CH"}
    for _, code in pairs(deVariants) do
        local _, a = localizedString(code, fcpLocaleCode)
        local _, b = localizedString(code, "en")
        local title = contentsInsideBrackets(a)
        local path = {"Edit", "Captions", "Duplicate Captions to New Language", "German"}
        local params = {}
        params.path = fnutils.concat(fnutils.copy(path), { contentsInsideBrackets(b) })
        params.locale = en
        params.plain = true
        table.insert(choices, {
            text = title,
            subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
            params = params,
            id = mod.actionId(params),
        })
    end

    --------------------------------------------------------------------------------
    -- Edit > Captions > Duplicate Captions to New Language > Greek >
    --
    -- el_CY            Cyprus                      -- Greek (Cyprus)
    --------------------------------------------------------------------------------
    local elVariants = {"el_CY"}
    for _, code in pairs(elVariants) do
        local _, a = localizedString(code, fcpLocaleCode)
        local _, b = localizedString(code, "en")
        local title = contentsInsideBrackets(a)
        local path = {"Edit", "Captions", "Duplicate Captions to New Language", "Greek"}
        local params = {}
        params.path = fnutils.concat(fnutils.copy(path), { contentsInsideBrackets(b) })
        params.locale = en
        params.plain = true
        table.insert(choices, {
            text = title,
            subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
            params = params,
            id = mod.actionId(params),
        })
    end

    --------------------------------------------------------------------------------
    -- Edit > Captions > Duplicate Captions to New Language > Spanish >
    --
    -- es_419           Latin America               -- Spanish (Latin America)
    -- es_MX            Mexico                      -- Spanish (Mexico)
    -- es_ES            Spain                       -- Spanish (Spain)
    --------------------------------------------------------------------------------
    local esVariants = {"es_419", "es_MX", "es_ES"}
    for _, code in pairs(esVariants) do
        local _, a = localizedString(code, fcpLocaleCode)
        local _, b = localizedString(code, "en")
        local title = contentsInsideBrackets(a)
        local path = {"Edit", "Captions", "Duplicate Captions to New Language", "Spanish"}
        local params = {}
        params.path = fnutils.concat(fnutils.copy(path), { contentsInsideBrackets(b) })
        params.locale = en
        params.plain = true
        table.insert(choices, {
            text = title,
            subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
            params = params,
            id = mod.actionId(params),
        })
    end

    --------------------------------------------------------------------------------
    -- Edit > Captions > Duplicate Captions to New Language > Portuguese >
    --
    -- pt_BR            Brazil                      -- Portuguese (Brazil)
    -- pt_PT            Portugal                    -- Portuguese (Portugal)
    --------------------------------------------------------------------------------
    local ptVariants = {"pt_BR", "pt_PT"}
    for _, code in pairs(ptVariants) do
        local _, a = localizedString(code, fcpLocaleCode)
        local _, b = localizedString(code, "en")
        local title = contentsInsideBrackets(a)
        local path = {"Edit", "Captions", "Duplicate Captions to New Language", "Portuguese"}
        local params = {}
        params.path = fnutils.concat(fnutils.copy(path), { contentsInsideBrackets(b) })
        params.locale = en
        params.plain = true
        table.insert(choices, {
            text = title,
            subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
            params = params,
            id = mod.actionId(params),
        })
    end

    --------------------------------------------------------------------------------
    -- Start Dictation… (Edit)
    --------------------------------------------------------------------------------
    do
        local title = fcp:string("Start Dictation…")
        local path = {"Edit"}
        local params = {}
        params.path = fnutils.concat(fnutils.copy(path), { title })
        params.locale = en
        params.plain = true
        table.insert(choices, {
            text = title,
            subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
            params = params,
            id = mod.actionId(params),
        })
    end

    --------------------------------------------------------------------------------
    -- Emoji & Symbols (Edit)
    --------------------------------------------------------------------------------
    do
        local title = fcp:string("Emoji & Symbols") -- NOTE: It's actually "Emoji &amp; Symbols" in the Property List.
        local path = {"Edit"}
        local params = {}
        params.path = fnutils.concat(fnutils.copy(path), { title })
        params.locale = en
        params.plain = true
        table.insert(choices, {
            text = title,
            subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
            params = params,
            id = mod.actionId(params),
        })
    end

    --------------------------------------------------------------------------------
    -- Workflow Extensions
    --
    -- Frame.io (Window > Extensions)
    -- Getting Started for Final Cut Pro 10.4 (Window > Extensions)
    -- KeyFlow Pro 2 Extension (Window > Extensions)
    -- ShareBrowser (Window > Extensions)
    -- Shutterstock (Window > Extensions)
    -- Simon Says Transcription (Window > Extensions)
    --------------------------------------------------------------------------------
    local workflowExtensions = fcp.workflowExtensions()
    for _, title in pairs(workflowExtensions) do
        local path = {"Window", "Extensions"}
        local params = {}
        params.path = fnutils.concat(fnutils.copy(path), { title })
        params.locale = currentLocaleCode
        params.plain = true
        table.insert(choices, {
            text = title,
            subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
            params = params,
            id = mod.actionId(params),
        })
    end

    --------------------------------------------------------------------------------
    -- Sidebar (Window > Show in Workspace)
    --
    -- Window > Show in Workspace > Libraries
    --------------------------------------------------------------------------------
    do
        local title = fcp:string("PEEventsLibrary")
        local path = {"Window", "Show in Workspace"}
        local params = {}
        params.path = fnutils.concat(fnutils.copy(path), { title })
        params.locale = currentLocaleCode
        params.plain = true
        table.insert(choices, {
            text = title,
            subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
            params = params,
            id = mod.actionId(params),
        })
    end

    --------------------------------------------------------------------------------
    -- Custom Workspaces:
    --------------------------------------------------------------------------------
    local customWorkspaces = fcp:customWorkspaces()
    for _, title in pairs(customWorkspaces) do
        local path = {"Window", "Workspaces"}
        local params = {}
        params.path = fnutils.concat(fnutils.copy(path), { title })
        params.locale = currentLocaleCode
        params.plain = true
        table.insert(choices, {
            text = title,
            subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
            params = params,
            id = mod.actionId(params),
        })
    end

    --------------------------------------------------------------------------------
    -- Open Workspace Folder in Finder (Window > Workspaces)
    --------------------------------------------------------------------------------
    do
        local title = fcp:string("PEWorkspacesMenuOpenFolder")
        local path = {"Window", "Workspaces"}
        local params = {}
        params.path = fnutils.concat(fnutils.copy(path), { title })
        params.locale = currentLocaleCode
        params.plain = true
        table.insert(choices, {
            text = title,
            subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
            params = params,
            id = mod.actionId(params),
        })
    end

    --------------------------------------------------------------------------------
    -- Gather App Diagnostics (Help)
    --------------------------------------------------------------------------------

        -- NOTE: We can just ignore this, as it requires a modifier key to access anyway.

    --------------------------------------------------------------------------------
    -- File > Open Library > "Library Name":
    --------------------------------------------------------------------------------
    local recentLibraryNames = fcp:recentLibraryNames()
    for _, title in pairs(recentLibraryNames) do
        local path = {"File", "Open Library"}
        local params = {}
        params.path = fnutils.concat(fnutils.copy(path), { title .. ".*" })
        params.locale = en
        params.plain = true
        table.insert(choices, {
            text = title,
            subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
            params = params,
            id = mod.actionId(params),
        })
    end

    --------------------------------------------------------------------------------
    -- File > Open Library > Other…:
    --------------------------------------------------------------------------------
    do
        local title = fcp:string("FFLibraryMenu_SelectOther")
        local path = {"File", "Open Library"}
        local params = {}
        params.path = fnutils.concat(fnutils.copy(path), { title })
        params.locale = currentLocaleCode
        params.plain = true
        table.insert(choices, {
            text = title,
            subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
            params = params,
            id = mod.actionId(params),
        })
    end

    --------------------------------------------------------------------------------
    -- File > Open Library > From Backup…:
    --------------------------------------------------------------------------------
    do
        local title = fcp:string("FFLibraryMenu_OpenBackup")
        local path = {"File", "Open Library"}
        local params = {}
        params.path = fnutils.concat(fnutils.copy(path), { title })
        params.locale = currentLocaleCode
        params.plain = true
        table.insert(choices, {
            text = title,
            subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
            params = params,
            id = mod.actionId(params),
        })
    end

    --------------------------------------------------------------------------------
    -- File > Open Library > Clear Recents:
    --------------------------------------------------------------------------------
    do
        local title = fcp:string("FFLibraryMenu_ClearRecents")
        local path = {"File", "Open Library"}
        local params = {}
        params.path = fnutils.concat(fnutils.copy(path), { title })
        params.locale = currentLocaleCode
        params.plain = true
        table.insert(choices, {
            text = title,
            subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
            params = params,
            id = mod.actionId(params),
        })
    end

    --------------------------------------------------------------------------------
    -- File > Copy to Library > New Library…
    --------------------------------------------------------------------------------
    do
        local title = fcp:string("FFMMToNewLibraryMenuItem")
        local path = {"File", "Copy to Library"}
        local params = {}
        params.path = fnutils.concat(fnutils.copy(path), { title })
        params.locale = currentLocaleCode
        params.plain = true
        table.insert(choices, {
            text = title,
            subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
            params = params,
            id = mod.actionId(params),
        })
    end

    --------------------------------------------------------------------------------
    -- File > Move to Library > New Library…
    --------------------------------------------------------------------------------
    do
        local title = fcp:string("FFMMToNewLibraryMenuItem")
        local path = {"File", "Move to Library"}
        local params = {}
        params.path = fnutils.concat(fnutils.copy(path), { title })
        params.locale = currentLocaleCode
        params.plain = true
        table.insert(choices, {
            text = title,
            subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
            params = params,
            id = mod.actionId(params),
        })
    end

    --------------------------------------------------------------------------------
    -- File > Copy to Library > "Library Name":
    --------------------------------------------------------------------------------
    local activeLibraryNames = fcp:activeLibraryNames()
    for _, title in pairs(activeLibraryNames) do
        local path = {"File", "Copy to Library"}
        local params = {}
        params.path = fnutils.concat(fnutils.copy(path), { title .. ".*" })
        params.locale = en
        params.plain = true
        table.insert(choices, {
            text = title,
            subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
            params = params,
            id = mod.actionId(params),
        })
    end

    --------------------------------------------------------------------------------
    -- Clip > Disable
    --------------------------------------------------------------------------------
    do
        local title = fcp:string("FFClipContextMenu_Disable_Title")
        local path = {"Clip"}
        local params = {}
        params.path = fnutils.concat(fnutils.copy(path), { title })
        params.locale = currentLocaleCode
        params.plain = true
        table.insert(choices, {
            text = title,
            subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
            params = params,
            id = mod.actionId(params),
        })
    end

    --------------------------------------------------------------------------------
    --
    -- WORKAROUNDS FOR MENU ITEMS THAT WERE IN THE NIB:
    --
    --------------------------------------------------------------------------------
    local closeLibraryString    = fcp:string("FFCloseLibrary")
    local consolidateString     = fcp:string("FFInspectorModuleLibraryPropertiesConsolidateButtonTitle")
    local copyToLibraryString   = fcp:string("FFCopy to Library…")
    local deleteString          = fcp:string("FFDelete")
    local itemString            = fcp:string("FFTimelineItemElementAccessibilityDescription")
    local moveToLibraryString   = fcp:string("FFMove to Library…")
    local openString            = fcp:string("FFLibraryBackupChooser_OpenButton")

    for i, v in pairs(choices) do
        --------------------------------------------------------------------------------
        -- 360 (View > Show in Viewer)
        -- 360 (View > Show in Event Viewer)
        --
        -- Add in missing degrees symbol.
        --------------------------------------------------------------------------------
        if v.text and v.text == "360" then
            v.text = "360°"
            v.params.path[3] = "360°"
        end

        --------------------------------------------------------------------------------
        -- Close Library (File)
        --
        -- File > Close Library "Library Name"
        --------------------------------------------------------------------------------
        if v.text and v.text == closeLibraryString then
            v.params.path = {"File", "Close Library.*"}
            v.params.plain = false
        end

        --------------------------------------------------------------------------------
        -- Item (File > Share)
        --
        -- Not needed
        --------------------------------------------------------------------------------
        if v.text and v.text == itemString then
            table.remove(choices, i)
        end

        --------------------------------------------------------------------------------
        -- Copy to Library (File)
        --
        -- It's actually a submenu called "Copy Clip to Library", "Copy Event to Library", "Copy Project to Library", etc.
        --------------------------------------------------------------------------------
        if v.text and v.text == copyToLibraryString then
            table.remove(choices, i)
        end

        --------------------------------------------------------------------------------
        -- Move to Library (File)
        --
        -- It's actually a submenu called "Move Clip to Library", "Move Event to Library", "Move Project to Library", etc.
        --------------------------------------------------------------------------------
        if v.text and v.text == moveToLibraryString then
            table.remove(choices, i)
        end

        --------------------------------------------------------------------------------
        -- Consolidate Files… (File)
        --
        -- Can be "Consolidate Library Media...", "Consolidate Event Media...", "Consolidate Project Media..."
        -- Can be "Consolidate Motion Content..."
        --------------------------------------------------------------------------------
        if v.text and string.find(v.text, consolidateString .. ".*") then
            table.remove(choices, i)
        end

        --------------------------------------------------------------------------------
        -- Delete Render Files… (File)
        --
        -- Can be "Delete Generated Event Files..." or "Delete Generated Library Files..."
        --------------------------------------------------------------------------------
        if v.text and string.match(v.text, deleteString .. ".*") then
            v.params.path = {"File", deleteString .. ".*"}
            v.params.plain = false
        end

        --------------------------------------------------------------------------------
        -- Add Default Transition (Edit)
        --
        -- Add <Default Transition>
        --------------------------------------------------------------------------------

            -- TODO: Add workaround

            -- <key>FFDefaultVideoTransition</key>
            -- <string>FxPlug:4731E73A-8DAC-4113-9A30-AE85B1761265</string>

        --------------------------------------------------------------------------------
        -- Add Default Video Effect (Edit)
        --
        -- Add <Default Video Effect>
        --------------------------------------------------------------------------------

            -- TODO: Add workaround

            -- <key>FFDefaultVideoEffect</key>
            -- <string>FFColorCorrectionGroupEffect</string>

        --------------------------------------------------------------------------------
        -- Add Default Audio Effect (Edit)
        --
        -- Add <Default Audio Effect>
        --------------------------------------------------------------------------------

            -- TODO: Add workaround

            -- <key>FFDefaultAudioEffect</key>
            -- <string>AudioUnit: 0x61756678000000ec454d4147</string>

        --------------------------------------------------------------------------------
        -- Reject (Mark)
        --
        -- Can also be "Delete" if focussed on timeline instead of browser.
        --------------------------------------------------------------------------------

            -- TODO: Add workaround

        --------------------------------------------------------------------------------
        -- Open in Timeline (Clip)
        --
        -- Can also be "Open Clip", "Open in Angle Editor",
        --------------------------------------------------------------------------------
        if v.text and string.match(v.text, openString .. ".*") then
            v.params.path = {"Clip", openString .. ".*"}
            v.params.plain = false
        end

        --------------------------------------------------------------------------------
        -- Verify and Repair Project (Clip)
        --
        -- This is a hidden menu item, you can access it by holding down OPTION when pressing Clip.
        --------------------------------------------------------------------------------

            -- TODO: I'm not sure the best way to remove this from choices?

        --------------------------------------------------------------------------------
        -- Optical Flow Classic (Modify > Retime > Video Quality)
        --
        -- This seems to be a hidden menu item.
        --------------------------------------------------------------------------------

            -- TODO: I'm not sure the best way to remove this from choices?

        --------------------------------------------------------------------------------
        -- Assign Audio Roles (Modify)
        --
        -- This is actually a sub-menu.
        --------------------------------------------------------------------------------

            -- TODO: Add workaround

        --------------------------------------------------------------------------------
        -- Assign Video Roles (Modify)
        --
        -- This is actually a sub-menu.
        --------------------------------------------------------------------------------

            -- TODO: Add workaround

        --------------------------------------------------------------------------------
        -- Assign Caption Roles (Modify)
        --
        -- This is actually a sub-menu.
        --------------------------------------------------------------------------------

            -- TODO: Add workaround

        --------------------------------------------------------------------------------
        -- Update ' ' Workspace (Window > Workspaces)
        --
        -- Update 'WORKSPACE NAME' Workspace
        --------------------------------------------------------------------------------

            -- TODO: Add workaround

        --------------------------------------------------------------------------------
        -- Open Custom Workspace Folder in Finder (Window > Workspaces)
        --
        -- Open Workspace Folder in Finder (PEWorkspacesMenuOpenFolder)
        --------------------------------------------------------------------------------

            -- TODO: Add workaround to remove this.

    end
    return choices
end

--- plugins.finalcutpro.menu.menuaction.init(actionmanager) -> none
--- Function
--- Initialises the Menu Action plugin
---
--- Parameters:
---  * `actionmanager` - the Action Manager plugin
---
--- Returns:
---  * None
function mod.init(actionmanager)

    mod._handler = actionmanager.addHandler(GROUP .. "_" .. ID, GROUP)
        :onChoices(function(choices)
            local menu = fcp:menu():getMenuTitles()
            local currentLocaleCode = fcp:currentLocale().code
            local result = processMenu(menu, currentLocaleCode)

            result = applyMenuWorkarounds(result, currentLocaleCode)

            --------------------------------------------------------------------------------
            -- For testing purposes:
            --------------------------------------------------------------------------------
            --compareLegacyVersusNew(result)

            for _,choice in ipairs(result) do
                choices:add(choice.text)
                    :subText(choice.subText)
                    :params(choice.params)
                    :image(ICON)
                    :id(choice.id)
            end
        end)
        :onExecute(function(action)
            if action and action.path then
                fcp:launch():menu():doSelectMenu(action.path, {plain=action.plain, locale=action.locale}):Now()
            end
        end)
        :onActionId(function(params)
            return ID .. ":" .. concat(params.path, "||")
        end)

    --------------------------------------------------------------------------------
    -- Watch for new Custom Workspaces:
    --------------------------------------------------------------------------------
    fcp.customWorkspaces:watch(function()
        mod._handler:reset()
    end)

    mod._handler:reset()

    -- TODO: Need to reload if the FCPX language changes.

end

local plugin = {
    id              = "finalcutpro.menu.menuaction",
    group           = "finalcutpro",
    dependencies    = {
        ["core.action.manager"] = "actionmanager",
    }
}

function plugin.init(deps)
    mod.init(deps.actionmanager)
    return mod
end

return plugin
