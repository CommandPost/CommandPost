--- === cp.apple.commandeditor ===
---
--- Functions to control and manage Apple's Command Editor - used in Final Cut Pro,
--- Motion and Compressor.

local require           = require
local log               = require "hs.logger".new "cmdEditor"

local fnutils           = require "hs.fnutils"

local fn                = require "cp.fn"
local shortcut          = require "cp.commands.shortcut"
local tools             = require "cp.tools"

local contains          = fnutils.contains
local copy              = fnutils.copy
local find              = string.find
local insert            = table.insert
local lower             = string.lower
local tableContains     = tools.tableContains
local sort              = fn.table.sort

local mod = {}

--- cp.apple.commandeditor.padKeys -> table
--- Constant
--- List of number keys on the number pad. Also mapped with the key name set to `true` for lookup purposes.
mod.padKeys = { "*", "+", "/", "-", "=", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "clear", "enter" }

-- map each pad key to true for quick lookup
for _, key in ipairs(mod.padKeys) do
    mod.padKeys[key] = true
end

--- cp.apple.commandeditor.supportedModifiers -> table
--- Constant
--- The list of supported modifiers
mod.supportedModifiers = { "shift", "control", "option", "command", "function" }

-- map each modifier to true for quick lookup
for _, modifier in ipairs(mod.supportedModifiers) do
    mod.supportedModifiers[modifier] = true
end

local characterStringKeyCodeMap = {
    [" "]                           = "space",
    NSF1FunctionKey                 = "f1",
    NSF2FunctionKey                 = "f2",
    NSF3FunctionKey                 = "f3",
    NSF4FunctionKey                 = "f4",
    NSF5FunctionKey                 = "f5",
    NSF6FunctionKey                 = "f6",
    NSF7FunctionKey                 = "f7",
    NSF8FunctionKey                 = "f8",
    NSF9FunctionKey                 = "f9",
    NSF10FunctionKey                = "f10",
    NSF11FunctionKey                = "f11",
    NSF12FunctionKey                = "f12",
    NSF13FunctionKey                = "f13",
    NSF14FunctionKey                = "f14",
    NSF15FunctionKey                = "f15",
    NSF16FunctionKey                = "f16",
    NSF17FunctionKey                = "f17",
    NSF18FunctionKey                = "f18",
    NSF19FunctionKey                = "f19",
    NSF20FunctionKey                = "f20",
    NSUpArrowFunctionKey            = "up",
    NSDownArrowFunctionKey          = "down",
    NSLeftArrowFunctionKey          = "left",
    NSRightArrowFunctionKey         = "right",
    NSInsertFunctionKey             = "insert",
    NSDeleteFunctionKey             = "delete",
    NSHomeFunctionKey               = "home",
    NSEndFunctionKey                = "end",
    NSPageUpFunctionKey             = "pageup",
    NSCarriageReturnCharacter       = "return",
    NSClearLineFunctionKey          = "padclear",
}

--- cp.apple.commandeditor.characterStringToKeyCode() -> string
--- Function
--- Translate Keyboard Character Strings from Command Set Format into Hammerspoon Format.
---
--- Parameters:
---  * input - Character String
---
--- Returns:
---  * Keycode as String or ""
function mod.characterStringToKeyCode(input)
    local result = tostring(input)
    return lower(characterStringKeyCodeMap[result] or result)
end

--- cp.apple.commandeditor.keypadCharacterToKeyCode() -> string
--- Function
--- Translate Keyboard Keypad Character Strings from Command Set Format into Hammerspoon Format.
---
--- Parameters:
---  * input - Character String
---
--- Returns:
---  * string or nil
function mod.keypadCharacterToKeyCode(input)
    local result = input
    if mod.padKeys[input] then
        result = "pad" .. input
    end
    return mod.characterStringToKeyCode(result)
end

--- cp.apple.commandeditor.translateModifiers() -> table
--- Function
--- Translate Keyboard Modifiers from Command Set Format into Hammerspoon Format.
---
--- Parameters:
---  * input - Modifiers String
---
--- Returns:
---  * table
function mod.translateModifiers(input)
    local result = {}
    if find(input, "command") then insert(result, "command") end
    if find(input, "control") then insert(result, "control") end
    if find(input, "option") then insert(result, "option") end
    if find(input, "shift") then insert(result, "shift") end
    return result
end

--- cp.apple.commandeditor.modifierMatch(inputA, inputB) -> boolean
--- Function
--- Compares two modifier tables.
---
--- Parameters:
---  * inputA - table of modifiers
---  * inputB - table of modifiers
---
--- Returns:
---  * `true` if there's a match otherwise `false`
---
--- Notes:
---  * This function only takes into account 'ctrl', 'alt', 'cmd', 'shift'.
function mod.modifierMatch(inputA, inputB)
    if #inputA ~= #inputB then
        return false
    end

    local sortedA, sortedB = sort(inputA), sort(inputB)
    for i = 1, #sortedA do
        if sortedA[i] ~= sortedB[i] then
            return false
        end
    end
    return true
end

--- cp.apple.commandeditor.modifierMaskToModifiers() -> table
--- Function
--- Translate Keyboard Modifiers from Apple's Property List Format into Hammerspoon Format.
---
--- Parameters:
---  * value - Modifiers String
---
--- Returns:
---  * A table of modifier strings.
function mod.modifierMaskToModifiers(value)
    local modifiers = {
        ["alphashift"]  = 1 << 16,
        ["shift"]       = 1 << 17,
        ["control"]     = 1 << 18,
        ["option"]      = 1 << 19,
        ["command"]     = 1 << 20,
        ["numericpad"]  = 1 << 21,
        ["help"]        = 1 << 22,
        ["function"]    = 1 << 23,
    }

    local answer = {}

    for k, a in pairs(modifiers) do
        if (value & a) == a then
            insert(answer, k)
        end
    end

    return answer
end

--- cp.apple.commandeditor.shortcutsFromCommandSet(id, commandSet) -> table
--- Function
--- Gets a specific command from a specified Command Set and returns a table of Shortcuts.
---
--- Parameters:
---  * id - The ID of the command you want to get.
---  * commandSet - A table containing an entire Command Set.
---
--- Returns:
---  * A table of shortcuts for a specific command.
function mod.shortcutsFromCommandSet(id, commandSet)
    if not id then
        log.ef("Shortcuts from Command Set is missing an ID: %s", id)
        return nil
    end

    if not commandSet then
        log.ef("Shortcuts from CommandSet is missing the Command Set: %s", commandSet)
        return nil
    end

    local commands = commandSet[id]
    if not commands then
        --log.ef("Command does not exist in Command Set: %s", id)
        return nil
    end

    if #commands == 0 then
        commands = { commands }
    end

    local shortcuts = {}

    for _, commmand in ipairs(commands) do
        local modifiers = nil
        local keyCode = nil
        local keypadModifier = false

        if commmand["modifiers"] ~= nil then
            if find(commmand["modifiers"], "keypad") then keypadModifier = true end
            modifiers = mod.translateModifiers(commmand["modifiers"])
        elseif commmand["modifierMask"] ~= nil then
            modifiers = mod.modifierMaskToModifiers(commmand["modifierMask"])
            if tableContains(modifiers, "numericpad") then
                keypadModifier = true
            end
        end

        local character = commmand["characterString"] or commmand["character"]
        if keypadModifier then
            keyCode = mod.keypadCharacterToKeyCode(character)
        else
            keyCode = mod.characterStringToKeyCode(character)
        end

        if keyCode ~= nil and keyCode ~= "" then
            --------------------------------------------------------------------------------
            -- We currently only know how to trigger SHIFT, CONTROL, OPTION, COMMAND and
            -- FUNCTION modifiers, so lets just ignore ALPHASHIFT, NUMERICPAD and HELP
            -- for now.
            --------------------------------------------------------------------------------
            local cleanedModifiers = {}
            if keypadModifier then
                for _, v in pairs(modifiers) do
                    if mod.supportedModifiers[v] then
                        insert(cleanedModifiers, v)
                    end
                end
            else
                cleanedModifiers = copy(modifiers)
            end

            insert(shortcuts, shortcut.new(cleanedModifiers, keyCode))
        end
    end

    return shortcuts
end

return mod
