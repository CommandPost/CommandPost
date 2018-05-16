--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.strings ===
---
--- The `cp.strings` for I18N lookups related to Final Cut Pro.
--- This has been populated with common lookups for user interface values
--- that appear in Final Cut Pro.

-- local log                   = require("hs.logger").new("fcpStrings")
-- local inspect               = require("hs.inspect")

local app                   = require("cp.apple.finalcutpro.app")
local strings               = require("cp.strings")
local localeID              = require("cp.i18n.localeID")

local mod = {}

mod._strings = strings.new()
:fromPlist("${appPath}/Contents/Resources/${locale}.lproj/PELocalizable.strings")
:fromPlist("${appPath}/Contents/Frameworks/Flexo.framework/Resources/${locale}.lproj/FFLocalizable.strings")
:fromPlist("${appPath}/Contents/Frameworks/LunaKit.framework/Resources/${locale}.lproj/Commands.strings")
:fromPlist("${appPath}/Contents/Frameworks/Ozone.framework/Resources/${locale}.lproj/Localizable.strings") -- Text
:fromPlist("${appPath}/Contents/PlugIns/InternalFiltersXPC.pluginkit/Contents/PlugIns/Filters.bundle/Contents/Resources/${locale}.lproj/Localizable.strings") -- Added for Final Cut Pro 10.4

local function resetStrings()
    mod._strings:context({
        appPath = app:path(),
        locale = app:currentLocale().aliases,
    })
end

--- cp.apple.finalcutpro:string(key[, locale][, quiet]]) -> string
--- Method
--- Looks up an application string with the specified `key`.
--- If no `context` value is provided, the [current context](#context) is used.
---
--- Parameters:
---  * `key`	- The key to look up.
---  * `locale` - Optional locale to retrieve the key for, if available. May be a `string` or `cp.i18n.localeID`.
---  * `quiet`	- Optional boolean, defaults to `false`. If `true`, no warnings are logged for missing keys.
---
--- Returns:
---  * The requested string or `nil` if the application is not running.
function mod:find(key, locale, quiet)
    if type(locale) == "boolean" then
        quiet = locale
        locale = nil
    end
    local context = nil
    if locale ~= nil then
        locale = localeID(locale)
        context = {locale = locale.aliases}
    end
    return self._strings and self._strings:find(key, context, quiet)
end

--- cp.apple.finalcutpro:keysWithString(string[, lang]) -> {string}
--- Method
--- Looks up an application string and returns an array of keys that match. It will take into account current language the app is running in, or use `lang` if provided.
---
--- Parameters:
---  * `string`	- The string to look up.
---  * `lang`	- The language (defaults to current FCPX language).
---
--- Returns:
---  * The array of keys with a matching string.
---
--- Notes:
---  * This method may be very inefficient, since it has to search through every possible key/value pair to find matches. It is not recommended that this is used in production.
function mod:findKeys(string, locale)
    local context
    if locale then
        locale = localeID(locale)
        context = {locale = locale.aliases}
    end
    return self._strings and self._strings:findKeys(string, context)
end

app.currentLocale:watch(function() resetStrings() end, true)

return mod
