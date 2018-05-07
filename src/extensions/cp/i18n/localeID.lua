--- === cp.i18n.localeID ===

--- As per [Apple's documentation](https://developer.apple.com/library/content/documentation/MacOSX/Conceptual/BPInternational/LanguageandLocaleIDs/LanguageandLocaleIDs.html#//apple_ref/doc/uid/10000171i-CH15-SW6),
--- a `local ID` is a code which identifies either a language used across multiple regions,
--- a dialect from a specific region, a script used in multiple regions, or a combination of all three.
--- See the [parse](#parse) function for details.
---
--- When you parse a code with the [forCode](#forCode) function, it will result in a table that contains a
--- reference to the approprate `cp.i18n.language` table, and any specified `cp.i18n.region`
--- or `cp.i18n.script` tables. These contain the full details for each language/regin/script, as appropriate.
---
--- You can also convert the resulting table back to the code via `tostring`, or the [code](#code) method.

-- local log               = require("hs.logger").new("localeID")

local language          = require("cp.i18n.language")
local region            = require("cp.i18n.region")
local script            = require("cp.i18n.script")

local match, format     = string.match, string.format

local mod = {}
mod.mt = {}
mod.mt.__index = mod.mt

local cache = {}
local LANG_PATTERN = "^(%a+)$"
local LANG_REGION_PATTERN = "^([a-z][a-z])_([A-Z][A-Z])$"
local LANG_SCRIPT_PATTERN = "^([a-z][a-z])-(%a%a%a%a)$"
local LANG_SCRIPT_REGION_PATTERN = "^([a-z][a-z])-(%a%a%a%a)_([A-Z][A-Z])$"

--- cp.i18n.localeID.is(other) -> boolean
--- Function
--- Checks if the `other` is a `localeID`.
---
--- Parameters:
--- * other     - the other value to check.
---
--- Returns:
--- * `true` if it is a `cp.i18n.locale`, otherwise `false`.
function mod.is(other)
    return type(other) == "table" and getmetatable(other) == mod.mt
end

--- cp.i18n.localeID.parse(code) -> string, string, string
--- Function
--- Parses a `language ID` into three possible string components:
--- 1. The ISO 693-1 language code
--- 2. The ISO 15924 script code
--- 3. The ISO 3166-1 region code
---
--- This is one of the following patterns:
---
--- * `[language]` - eg. `"en"`, or `"fr"`. This covers the language across all languages and scripts. We also allow the full name (eg. "English" or "French") since this seems common in Apple's I18N management.
--- * `[language]_[region]` - eg. "en_AU" for Australian English, "fr_CA" for Canadian French, etc.
--- * `[language]-[script]` - eg. "az-Arab" for Azerbaijani in Arabic script, "az-Latn" for Azerbaijani in Latin script.
--- * `[language]-[script]_[region]` - eg. "en-Latin-AU"
---
--- It will then return the matched component in three return values: language, script, region.
--- If a `region` is specified, the `script` will be `nil`. Eg.:
---
--- ```lua
--- local lang, scrpt, rgn = localeID.parse("en_AU") -- results in "en", nil, "AU"
--- ```
---
--- Parameters:
--- * code      - The `locale ID` code. Eg. "en_AU".
---
--- Returns:
--- * language  - The two-character lower-case alpha language code.
--- * script    - the four-character mixed-case alpha script code.
--- * region    - The two-character upper-case alpha region code.
function mod.parse(code)
    local l
    local r, s = nil, nil
    l = match(code, LANG_PATTERN)
    if not l then
        l, r = match(code, LANG_REGION_PATTERN)
        if not r then
            l, s = match(code, LANG_SCRIPT_PATTERN)
            if not s then
                l, s, r = match(code, LANG_SCRIPT_REGION_PATTERN)
            end
        end
    end
    return l, r, s
end

--- cp.i18n.localeID.forCode(code) -> cp.i18n.localeID or nil
--- Constructor
--- Creates, or retrieves from the cache, a `localeID` instance for the specified `code`.
---
--- If the code can't be parsed, or if the actual language/region/script codes don't exist,
--- `nil` is returned.
---
--- Parameters:
--- * code      - The language ID code.
---
--- Returns:
--- * The matching `langaugeID`, or `nil`.
function mod.forCode(code)
    local id = cache[code]
    if not id then
        local languageCode, regionCode, scriptCode = mod.parse(code)
        if languageCode then
            local theLanguage, theRegion, theScript
            local theCode, theName, theLocalName

            theLanguage = language[languageCode]
            if not theLanguage then
                return nil, format("Unable to find language: %s", languageCode)
            else
                theCode = theLanguage.alpha2
                theName = theLanguage.name
                theLocalName = theLanguage.localName
            end
            if scriptCode or regionCode then
                theName = theName .. " ("
                theLocalName = theLocalName .. " ("
                if scriptCode then
                    theScript = script[scriptCode]
                    if not theScript then
                        return nil, format("Unable to find script: %s", scriptCode)
                    else
                        theCode = theCode .. "-" .. theScript.alpha4
                        theName = theName .. theScript.name
                        -- TODO: Get Local Names for scripts.
                        theLocalName = theLocalName .. theScript.name
                        if regionCode then
                            theName = theName .. "; "
                            theLocalName = theLocalName .. "; "
                        end
                    end
                end
                if regionCode then
                    theRegion = region[regionCode]
                    if not theRegion then
                        return nil, format("Unable to find region: %s", regionCode)
                    else
                        theCode = theCode .. "_" ..theRegion.alpha2
                        theName = theName .. theRegion.name
                        -- TODO: Get Local names for regions
                        theLocalName = theLocalName .. theRegion.alpha2
                    end
                end
                theName = theName .. ")"
                theLocalName = theLocalName .. ")"
            end

            id = setmetatable({
                code = theCode,
                name = theName,
                localName = theLocalName,
                language = theLanguage,
                script = theScript,
                region = theRegion,
            }, mod.mt)
            cache[code] = id
        else
            return nil, format("Unable to parse language ID: %s", code)
        end
    end
    return id
end

--- cp.i18n.localeID:matches(otherLocale) -> number
--- Method
--- This compares the `otherLocale` to this locale and returns a number indicating the 'strength'
--- of the match. It will be a value between `0` and `3`. The `script` and `region` in any locale
--- are optional, and if they are not provided, the local will match with another locale which
--- has the script or region defined. However, it is considered to be a weaker match.
---
--- For example:
--- ```lua
--- local l = localeID.forCode
--- local en, en_AU, en_Latn, en_Latn_AU, de = l("en"), l("en_AU"), l("en-Latn"), l("en-Latn_AU"), l("de")
---
--- en:matches(en)              == 3    -- matches exactly
--- en:matches(en_AU)           == 2    -- matches with one extra optional value filled in
--- en:matches(en_Latn)         == 2    -- matches with one extra optional value filled in
--- en:matches(en_Latn_AU)      == 1    -- matches with both optional values filled in
--- en:matches(de)              == 0    -- no match - different language
---
--- en_AU:matches(en_AU)        == 3    -- exact match
--- en_AU:matches(en)           == 0    -- language matches, but no match because "en" is missing the "AU" `region`, which is required for a match.
--- en_AU:matches(en_Latn_AU)   == 2    -- language and region match exactly, and the optional `script` value is different.
--- ```
---
--- The higher the match value, the closer they are to matching. If selecting a from multiple locales which match you will generally want the highest-ranking match.
---
--- Parameters:
--- * otherLocale       - The other locale to compare to
---
--- Returns:
--- * A number from `0` to `3` indicating the match strength.
function mod.mt:matches(otherLocale)
    local score = 0
    if mod.is(otherLocale) then
        if self.language == otherLocale.language then
            score = 1
            if self.script == otherLocale.script then -- strong match
                score = score + 1
            elseif self.script ~= nil then -- no match
                return 0
            end
            if self.region == otherLocale.region then -- strong match
                score = score + 1
            elseif self.region ~= nil then -- no match
                return 0
            end
        end
    end
    return score
end

--- cp.i18n.localeID.code <string>
--- Field
--- The locale ID code.

--- cp.i18n.localeID.name <string>
--- Field
--- The locale name in English.

--- cp.i18n.localeID.localName <string>
--- Field
--- The local name in it's own language.

--- cp.i18n.localeID.language <cp.i18n.language>
--- Field
--- The matching `language` details.

--- cp.i18n.localeID.region <cp.i18n.region>
--- Field
--- The matching `region` details, if appropriate. Will be `nil` if no region was specified in the `code`.

--- cp.i18n.localeID.script <cp.i18n.script>
--- Field
--- The matching `script` details, if appropriate. Will be `nil` if no script was specified in the `code`.

function mod.mt:__tostring()
    return format("cp.i18n.localeID: %s [%s]", self.name, self.code)
end

-- we match if we have the same code.
function mod.mt:__eq(other)
    return self.code == other.code
end

-- compares our string values.
function mod.mt:__lt(other)
    return tostring(self) < tostring(other)
end

return mod