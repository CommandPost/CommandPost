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

local app                   = require("cp.apple.finalcutpro.app")
local strings               = require("cp.strings")

local mod = {}

mod._strings = strings.new()
:fromPlist("${appPath}/Contents/Resources/${language}.lproj/PELocalizable.strings")
:fromPlist("${appPath}/Contents/Frameworks/Flexo.framework/Resources/${language}.lproj/FFLocalizable.strings")
:fromPlist("${appPath}/Contents/Frameworks/LunaKit.framework/Resources/${language}.lproj/Commands.strings")
:fromPlist("${appPath}/Contents/Frameworks/Ozone.framework/Resources/${language}.lproj/Localizable.strings") -- Text
:fromPlist("${appPath}/Contents/PlugIns/InternalFiltersXPC.pluginkit/Contents/PlugIns/Filters.bundle/Contents/Resources/${language}.lproj/Localizable.strings") -- Added for Final Cut Pro 10.4

local function resetStrings()
    mod._strings:context({
        appPath = app:path(),
        -- language = app:language(),
    })
end

--- cp.apple.finalcutpro:string(key[, lang[, quiet]]) -> string
--- Method
--- Looks up an application string with the specified `key`.
--- If no `lang` value is provided, the [current language](#currentLanguage) is used.
---
--- Parameters:
---  * `key`	- The key to look up.
---  * `lang`	- The language code to use. Defaults to the current language.
---  * `quiet`	- Optional boolean, defaults to `false`. If `true`, no warnings are logged for missing keys.
---
--- Returns:
---  * The requested string or `nil` if the application is not running.
function mod:find(key, lang, quiet)
    if type(lang) == "boolean" then
        quiet = lang
        lang = nil
    end
    lang = lang or self:currentLanguage()
    return self._strings and self._strings:find(lang, key, quiet)
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
function mod:findKeys(string, lang)
    lang = lang or self:currentLanguage()
    return self._strings and self._strings:findKeys(string, lang)
end

app.running:watch(function() resetStrings() end, true)

return mod
