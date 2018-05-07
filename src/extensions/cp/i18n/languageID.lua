--- === cp.i18n.languageID ===

--- As per [Apple's documentation](https://developer.apple.com/library/content/documentation/MacOSX/Conceptual/BPInternational/LanguageandLocaleIDs/LanguageandLocaleIDs.html#//apple_ref/doc/uid/10000171i-CH15-SW6),
--- a `language ID` is a code which identifies either a language used across multiple regions,
--- a dialect from a specific region, or a script used in multiple regions. See the [parse](#parse) function for details.
---
--- When you parse a code with the [forCode](#forCode) function, it will result in a table that contains a
--- reference to the approprate `cp.i18n.language` table, and up to one of either the matching `cp.i18n.region`
--- or `cp.i18n.script` tables. These contain the full details for each language/regin/script, as appropriate.
---
--- You can also convert the resulting table back to the code via `tostring`, or the [code](#code) method.

-- local log               = require("hs.logger").new("languageID")

local language          = require("cp.i18n.language")
local region            = require("cp.i18n.region")
local script            = require("cp.i18n.script")

local localeID          = require("cp.i18n.localeID")

local match, format     = string.match, string.format

local mod = {}
mod.mt = {}
mod.mt.__index = mod.mt

local cache = {}
local LANG_PATTERN = "^([a-z][a-z])$"
local LANG_REGION_PATTERN = "^([a-z][a-z])-([A-Z][A-Z])$"
local LANG_SCRIPT_PATTERN = "^([a-z][a-z])-(%a%a%a%a)$"

--- cp.i18n.languageID.parse(code) -> string, string, string
--- Function
--- Parses a `language ID` into three possible string components:
--- 1. The ISO 693-1 language code
--- 2. The ISO 15924 script code
--- 3. The ISO 3166-1 region code
---
--- This is one of the following patterns:
---
--- * `[language]` - eg. `"en"`, or `"fr"`. The covers the language across all languages and scripts.
--- * `[language]-[script]` - eg. "az-Arab" for Azerbaijani in Arabic script, "az-Latn" for Azerbaijani in Latin script.
--- * `[language]-[region]` - eg. "en-AU" for Australian English, "fr-CA" for Canadian French, etc.
---
--- It will then return the matched component in three return values: language, region, script.
--- If a script is specified, the `region` will be `nil`. Eg.:
---
--- ```lua
--- local lang, scrpt, rgn, scrpt = languageID.parse("en-AU") -- results in "en", nil, "AU"
--- ```
---
--- Parameters:
--- * code      - The `language ID` code. Eg. "en-AU".
---
--- Returns:
--- * language  - The two-character lower-case alpha language code.
--- * script    - the four-character mixed-case alpha script code.
--- * region    - The two-character upper-case alpha region code.
function mod.parse(code)
    local l, s, r
    l = match(code, LANG_PATTERN)
    if not l then
        l, r = match(code, LANG_REGION_PATTERN)
        if not r then
            l, s = match(code, LANG_SCRIPT_PATTERN)
        end
    end
    return l, s, r
end

--- cp.i18n.languageID.forCode(code) -> cp.i18n.languageID, string
--- Constructor
--- Creates, or retrieves from the cache, a `languageID` instance for the specified `code`.
---
--- If the code can't be parsed, or if the actual language/region/script codes don't exist,
--- `nil` is returned.
---
--- Parameters:
--- * code      - The language ID code.
---
--- Returns:
--- * The matching `languageID`, or `nil` if the language ID couldn't be found.
--- * The error message, or `nil` if there was no problem.
function mod.forCode(code)
    local id = cache[code]
    if not id then
        local languageCode, scriptCode, regionCode = mod.parse(code)
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
            if regionCode then
                theRegion = region[regionCode]
                if not theRegion then
                    return nil, format("Unable to find region: %s", regionCode)
                else
                    theCode = theCode .. "-" .. theRegion.alpha2
                    theName = theName .. " (" .. theRegion.name .. ")"
                    theLocalName = theLocalName .. " (" .. theRegion.alpha2 .. ")"
                end
            end
            if scriptCode then
                theScript = script[scriptCode]
                if not theScript then
                    return nil, format("Unable to find script: %s", scriptCode)
                else
                    theCode = theCode .. "-" .. theScript.alpha4
                    theName = theName .. " (" .. theScript.name .. ")"
                    theLocalName = theLocalName .. " (" .. theScript.alpha2 .. ")"
                end
            end

            id = setmetatable({
                code = theCode,
                name = theName,
                localName = theLocalName,
                language = theLanguage,
                region = theRegion,
                script = theScript,
            }, mod.mt)
            cache[code] = id
        else
            return nil, format("Unable to parse language ID: %s", code)
        end
    end
    return id
end

--- cp.i18n.languageID:toLocaleID() -> cp.i18n.localeID
--- Method
--- Returns the `cp.i18n.localeID` equivalent for this `languageID`.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The matching `localeID`.
function mod.mt:toLocaleID()
    local localeCode = self.language.alpha2
    if self.script then
        localeCode = localeCode .. "-" .. self.script.alpha4
    end

    if self.region then
        localeCode = localeCode .. "_" .. self.region.alpha2
    end

    return localeID.forCode(localeCode)
end

--- cp.i18n.languageID.code <string>
--- Field
--- The language ID code.

--- cp.i18n.languageID.language <cp.i18n.language>
--- Field
--- The matching `language` details.

--- cp.i18n.languageID.region <cp.i18n.region>
--- Field
--- The matching `region` details, if appropriate. Will be `nil` if no region was specified in the `code`.

--- cp.i18n.languageID.script <cp.i18n.script>
--- Field
--- The matching `script` details, if appropriate. Will be `nil` if no script was specified in the `code`.

function mod.mt:__tostring()
    return self:displayName()
end

return mod