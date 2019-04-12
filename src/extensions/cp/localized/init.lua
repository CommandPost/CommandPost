--- === cp.localized ===
---
--- Helps look up localized names for folders.

local require           = require

local log               = require("hs.logger").new("localized")

local fs                = require("hs.fs")

local localeID          = require("cp.i18n.localeID")
local matcher           = require("cp.text.matcher")
local plist             = require("cp.plist")
local text              = require("cp.text")
local wtext             = require("cp.web.text")

local binaryFileToTable = plist.binaryFileToTable
local escapeXML         = wtext.escapeXML
local isBinaryPlist     = plist.isBinaryPlist
local match             = string.match
local pathToAbsolute    = fs.pathToAbsolute
local unescapeXML       = wtext.unescapeXML

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------

-- TODO: Add Documentation
local KEY_VALUE = matcher('^%"(.+)%"%s*%=%s*%"(.+)%";.*$')

-- TODO: Add Documentation
local UNICODE_ESCAPE = matcher('%\\[Uu]%d%d%d%d')

-- TODO: Add Documentation
local CHAR_ESCAPE = matcher('%\\(.)')

-- TODO: Add Documentation
local function uParser(s)
    return utf8.char(tonumber(s:sub(3):encode(), 16))
end

-- cp.localized.readLocalizedStrings(stringsFile, name) -> string | nil
-- Function
-- Returns the localized string value contained in the strings file for the specified `name`.
--
-- Parameters:
--  * `stringsFile` - Path to the .localized strings file.
--  * `name`            - The name to match. If not present in the file, `nil` is returned.
--
-- Returns:
--  * The matching key value, or `nil` if not available.
local function readLocalizedStrings(stringsFile, name)
    local stringsPath = pathToAbsolute(stringsFile)
    if stringsPath then
        --------------------------------------------------------------------------------
        -- Binary Plist:
        --------------------------------------------------------------------------------
        if isBinaryPlist(stringsFile) then
            local plistValues = binaryFileToTable(stringsFile)

            if plistValues then
                --------------------------------------------------------------------------------
                -- Escape folderCode:
                --------------------------------------------------------------------------------
                local localName = plistValues[escapeXML(name)]
                return localName and unescapeXML(localName)
            end
        --------------------------------------------------------------------------------
        --
        -- Plain Text:
        --
        -- Example:
        -- "03EF6CA6-E3E2-4DA0-B68F-26B2762A46BC" = "Perspective Reflection";
        --
        --------------------------------------------------------------------------------
        else
            local content = text.fromFile(stringsFile)
            local key, value = KEY_VALUE:match(content)
            if key and value then
                -- unescape the key.
                key = UNICODE_ESCAPE:gsub(key, uParser)
                key = CHAR_ESCAPE:gsub(key, '%1')
                if key == text(name) then
                    -- unescape the value.
                    value = UNICODE_ESCAPE:gsub(value, uParser)
                    value = CHAR_ESCAPE:gsub(value, '%1')
                    return tostring(value)
                end
            end
        end
    end
    return nil
end

-- cp.localized.readLocalizedName(path, name, locale) -> string
-- Function
-- Returns the localized `name` for the `path` in the specified `locale`. It will check
-- for common aliases for locale codes (e.g. 'en' is sometimes 'English'). If no localization
-- for the specified locale is available, it will try English, and if all else fails, the
-- original `name` is returned.
--
-- Parameters:
--  * `path`            - The full path to the folder
--  * `name`            - The name to match. If not present in the file, `nil` is returned.
--  * `locale`          - The locale to retrieve the name for.
--
-- Returns:
--  * The localized name, or `name` if not available.
local function readLocalizedName(path, name, locale)
    locale = localeID(locale)
    local localizedPath = path .. "/.localized/"
    local localized
    for _,code in ipairs(locale.aliases) do
        localized = readLocalizedStrings(localizedPath .. code .. ".strings", name)
        if localized then break end
    end
    if not localized and locale.code ~= "en" then
        localized = readLocalizedName(path, name, "en")
    end
    return localized or name
end

--- cp.localized.getLocalizedName(path[, locale]) -> string, string
--- Function
--- Returns the localized name for the `path` in the specified `locale`. If all else fails, the
--- original folder name is returned. The 'unlocalized' folder name is returned as the second value, without `.localized` at the end, if it was present.
---
--- Parameters:
---  * `path`           - The full path to the folder
---  * `locale`         - The locale to retrieve the name for.
---
--- Returns:
---  * The localized name, or `name` if not available.
---  * The original name, minus `.localized`
---
--- Notes:
---  * This function will automatically convert a colon to a dash when localising.
local function getLocalizedName(path, locale)
    local file = match(path, "^.-([^/]+)%.localized$")
    if file then -- it's localized
        local result = readLocalizedName(path, file, locale)
        if result then
            result = result:gsub(":", "/") -- Replace colon with slash
        end
        return result, file
    else
        file = match(path, "^.-([^/%.]+)$")
        return file, file
    end
end

return {
    readLocalizedStrings    = readLocalizedStrings,
    readLocalizedName       = readLocalizedName,
    getLocalizedName        = getLocalizedName,
}
