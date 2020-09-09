--- === cp.adobe.aftereffects ===
---
--- Adobe After Effects Extension

local require           = require

--local log				        = require "hs.logger".new "ae"

local osascript         = require "hs.osascript"

local app               = require "cp.adobe.aftereffects.app"
local shortcuts         = require "cp.adobe.aftereffects.shortcuts"

local config            = require "cp.config"
local delegator         = require "cp.delegator"
local lazy              = require "cp.lazy"
local tools             = require "cp.tools"

local class             = require "middleclass"

local applescript       = osascript.applescript
local readFromFile      = tools.readFromFile

local aftereffects = class("cp.adobe.aftereffects")
    :include(lazy)
    :include(delegator)
    :delegateTo("app")

function aftereffects:initialize()
--- cp.adobe.aftereffects.app <cp.app>
--- Constant
--- The `cp.app` for After Effects.
    self.app = app

--- cp.adobe.aftereffects.preferences <cp.app.prefs>
--- Constant
--- The `cp.app.prefs` for After Effects.
    self.preferences = app.preferences

    app:update()
end

--- cp.adobe.aftereffects:preferencesPath() -> string | nil
--- Function
--- The path to After Effects Preferences folder.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A string or `nil` if no path can be found.
function aftereffects:preferencesPath()
    local version = self:version()
    if version then
        local major = version.major
        local minor = version.minor
        local path = os.getenv("HOME") .. "/Library/Preferences/Adobe/After Effects/" .. major .. "." .. minor .. "/"
        return path
    end
end

--- cp.adobe.aftereffects:preferencesFilePath() -> string
--- Function
--- The path to the main Preferences file.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A string
function aftereffects:preferencesFilePath()
    local version = self:version()
    local major = version.major
    local minor = version.minor
    local preferencesPath = self:preferencesPath()
    local prefsFile =  preferencesPath and preferencesPath .. "Adobe After Effects " .. major .. "." .. minor .. " Prefs.txt"
    return prefsFile
end

--- cp.adobe.aftereffects:allowScriptsToWriteFilesAndAccessNetwork() -> boolean
--- Function
--- Is "Allow Scripts to Write Files and Access Network" enabled in After Effects Preferences?
---
--- Parameters:
---  * None
---
--- Returns:
---  * A boolean
function aftereffects:allowScriptsToWriteFilesAndAccessNetwork()
    local preferencesFilePath = self:preferencesFilePath()
    local preferencesContents = preferencesFilePath and readFromFile(preferencesFilePath)
    return preferencesContents and preferencesContents:find([["Pref_SCRIPTING_FILE_NETWORK_SECURITY" = "1"]], 1, true) and true or false
end

--- cp.adobe.aftereffects:refreshPreferences() -> none
--- Function
--- If After Effects is running, this forces the preferences file to be saved to disk.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function aftereffects:refreshPreferences()
    if self:running() then
        applescript([[
            tell application id "]] .. self:bundleID() .. [["
                DoScriptFile "]] .. config.bundledPluginsPath .. [[/aftereffects/preferences/js/refreshprefs.jsx"
            end tell
        ]])
    end
end

--- cp.adobe.aftereffects:shortcutsPreferencesPath() -> string
--- Function
--- Gets the active shortcut key preferences file path.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A string
function aftereffects:shortcutsPreferencesPath()
    --------------------------------------------------------------------------------
    -- NOTE: You can also use this ExtendScript:
    --       app.preferences.getPrefAsString('General Section', 'Shortcut File Location', PREFType.PREF_Type_MACHINE_SPECIFIC)
    --       However, I'm not sure how you can get this result to CommandPost easily?
    --------------------------------------------------------------------------------

    --------------------------------------------------------------------------------
    -- NOTE: I've commented out refreshPreferences() because it adds a
    --       substantial delay due to the fact that it triggers AppleScript.
    --------------------------------------------------------------------------------
    --self:refreshPreferences()

    local preferencesFilePath = self:preferencesFilePath()
    local preferencesContents = preferencesFilePath and readFromFile(preferencesFilePath)
    if preferencesContents then
        for line in string.gmatch(preferencesContents,'[^\r\n]+') do
            if line:find([["Shortcut File Location" =]], 1, true) then
                local preferencesPath = self: preferencesPath()
                return preferencesPath .. "aeks/" .. line:sub(30, -2)
            end
        end
    end
end

-- processKeyboardShortcut(currentSection, id, value) -> table
-- Function
-- Converts a keyboard shortcut from an After Effects format to the Hammerspoon format.
--
-- Parameters:
--  * section - The section as a string
--  * id - The ID as a string
--  * value - The keyboard shortcut as a string in the After Effects format
--
-- Returns:
--  * A table containing the modifiers, key and label
local function processKeyboardShortcut(section, id, value)
    --------------------------------------------------------------------------------
    -- Translate modifiers and key:
    --------------------------------------------------------------------------------
    local mods = {}
    local key = ""
    local components = value:split("+")
    for _, comp in pairs(components) do
        if shortcuts.modifiers[comp] then
            table.insert(mods, shortcuts.modifiers[comp])
        elseif shortcuts.keys[comp] then
            key = shortcuts.keys[comp]
        end
    end

    --------------------------------------------------------------------------------
    -- Get human-readable value:
    --------------------------------------------------------------------------------
    local label = id
    if shortcuts.labels[section] and shortcuts.labels[section][id] then
        label = shortcuts.labels[section][id]
    end

    --------------------------------------------------------------------------------
    -- If we don't have a human-readable value on file, just use the ID:
    --------------------------------------------------------------------------------
    if label == "" then
        label = id
    end

    --------------------------------------------------------------------------------
    -- Return result:
    --------------------------------------------------------------------------------
    return {
        ["modifiers"] = mods,
        ["character"] = key,
        ["label"] = label,
    }
end

--- cp.adobe.aftereffects:shortcutsPreferences() -> table
--- Function
--- Gets a table of all the active After Effects keyboard shortcuts.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table
function aftereffects:shortcutsPreferences()
    local shortcutsPreferencesPath = self:shortcutsPreferencesPath()
    local preferencesContents = shortcutsPreferencesPath and readFromFile(shortcutsPreferencesPath)

    local result = {}
    if preferencesContents then
        local currentSection
        local lastID, lastValue
        for line in string.gmatch(preferencesContents,'[^\r\n]+') do
            if line:sub(1,1) ~= "#" and line ~= "" then
                if line:sub(1, 2) == [[["]] then
                    --------------------------------------------------------------------------------
                    -- Section Heading:
                    --------------------------------------------------------------------------------
                    local value = line:sub(3, -3)
                    if value and value ~= "** header **" then
                        currentSection = value
                    end
                elseif currentSection then
                    if line:sub(1, 2) == [[	"]] then
                        --------------------------------------------------------------------------------
                        -- Single line value (or start of multi-line value):
                        --------------------------------------------------------------------------------
                        local start, finish = line:find([[".-"]])
                        local id = line:sub(start + 1, finish - 1)
                        local value = line:sub(finish + 5, -2)
                        if line:sub(-1) == [[\]] then
                            --------------------------------------------------------------------------------
                            -- Start of a multi-line value:
                            --------------------------------------------------------------------------------
                            lastID = id
                            lastValue = value:sub(1, -2)
                        else
                            --------------------------------------------------------------------------------
                            -- Single line value:
                            --------------------------------------------------------------------------------
                            local s, f = value:find([[%(.-%)]])
                            value = value:sub(s + 1, f - 1)

                            value = processKeyboardShortcut(currentSection, id, value)

                            if not result[currentSection] then result[currentSection] = {} end
                            result[currentSection][id] = value
                        end
                    else
                        --------------------------------------------------------------------------------
                        -- Continuation of a multi-line value:
                        --------------------------------------------------------------------------------
                        local start, finish = line:find([[".-"]])
                        local v = line:sub(start + 1, finish - 1)
                        if line:sub(-1) == [["]] then
                            --------------------------------------------------------------------------------
                            -- End of a multi-line value:
                            --------------------------------------------------------------------------------
                            local id = lastID
                            lastValue = lastValue .. v

                            local s, f = lastValue:find([[%(.-%)]])
                            local value = lastValue:sub(s + 1, f - 1)

                            value = processKeyboardShortcut(currentSection, id, value)

                            if not result[currentSection] then result[currentSection] = {} end
                            result[currentSection][id] = value
                        else
                            --------------------------------------------------------------------------------
                            -- Middle of a multi-line value:
                            --------------------------------------------------------------------------------
                            lastValue = lastValue .. v
                        end
                    end
                end
            end
        end
    end
    return result
end

return aftereffects()
