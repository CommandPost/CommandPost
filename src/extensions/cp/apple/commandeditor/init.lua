--- === cp.apple.commandeditor ===
---
--- Functions to control and manage Apple's Command Editor - used in Final Cut Pro,
--- Motion and Compressor.

local require           = require
local log               = require "hs.logger".new "cmdEditor"

local fnutils           = require "hs.fnutils"

local shortcut          = require "cp.commands.shortcut"
local tools             = require "cp.tools"

local contains          = fnutils.contains

local mod = {}

--- cp.apple.commandeditor.padKeys -> table
--- Variable
--- Table of Pad Keys
mod.padKeys = { "*", "+", "/", "-", "=", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "clear", "enter" }

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

    if input == " "                                     then result = "space"       end
    if string.find(input, "NSF1FunctionKey")            then result = "f1"          end
    if string.find(input, "NSF2FunctionKey")            then result = "f2"          end
    if string.find(input, "NSF3FunctionKey")            then result = "f3"          end
    if string.find(input, "NSF4FunctionKey")            then result = "f4"          end
    if string.find(input, "NSF5FunctionKey")            then result = "f5"          end
    if string.find(input, "NSF6FunctionKey")            then result = "f6"          end
    if string.find(input, "NSF7FunctionKey")            then result = "f7"          end
    if string.find(input, "NSF8FunctionKey")            then result = "f8"          end
    if string.find(input, "NSF9FunctionKey")            then result = "f9"          end
    if string.find(input, "NSF10FunctionKey")           then result = "f10"         end
    if string.find(input, "NSF11FunctionKey")           then result = "f11"         end
    if string.find(input, "NSF12FunctionKey")           then result = "f12"         end
    if string.find(input, "NSF13FunctionKey")           then result = "f13"         end
    if string.find(input, "NSF14FunctionKey")           then result = "f14"         end
    if string.find(input, "NSF15FunctionKey")           then result = "f15"         end
    if string.find(input, "NSF16FunctionKey")           then result = "f16"         end
    if string.find(input, "NSF17FunctionKey")           then result = "f17"         end
    if string.find(input, "NSF18FunctionKey")           then result = "f18"         end
    if string.find(input, "NSF19FunctionKey")           then result = "f19"         end
    if string.find(input, "NSF20FunctionKey")           then result = "f20"         end
    if string.find(input, "NSUpArrowFunctionKey")       then result = "up"          end
    if string.find(input, "NSDownArrowFunctionKey")     then result = "down"        end
    if string.find(input, "NSLeftArrowFunctionKey")     then result = "left"        end
    if string.find(input, "NSRightArrowFunctionKey")    then result = "right"       end
    if string.find(input, "NSDeleteFunctionKey")        then result = "delete"      end
    if string.find(input, "NSHomeFunctionKey")          then result = "home"        end
    if string.find(input, "NSEndFunctionKey")           then result = "end"         end
    if string.find(input, "NSPageUpFunctionKey")        then result = "pageup"      end
    if string.find(input, "NSPageDownFunctionKey")      then result = "pagedown"    end
    if string.find(input, "NSDeleteCharacter")          then result = "delete"      end
    if string.find(input, "NSCarriageReturnCharacter")  then result = "return"      end

    --------------------------------------------------------------------------------
    -- Convert to lowercase:
    --------------------------------------------------------------------------------
    result = string.lower(result)
    return result

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
    for i=1, #mod.padKeys do
        if input == mod.padKeys[i] then result = "pad" .. input end
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
    if string.find(input, "command") then result[#result + 1] = "command" end
    if string.find(input, "control") then result[#result + 1] = "control" end
    if string.find(input, "option") then result[#result + 1] = "option" end
    if string.find(input, "shift") then result[#result + 1] = "shift" end
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
    local match = true

    if contains(inputA, "ctrl") and not contains(inputB, "ctrl") then match = false end
    if contains(inputA, "alt") and not contains(inputB, "alt") then match = false end
    if contains(inputA, "cmd") and not contains(inputB, "cmd") then match = false end
    if contains(inputA, "shift") and not contains(inputB, "shift") then match = false end

    return match
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
            table.insert(answer, k)
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
        log.ef("Command does not exist in Command Set: %s", id)
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
            if string.find(commmand["modifiers"], "keypad") then keypadModifier = true end
            modifiers = mod.translateModifiers(commmand["modifiers"])
        elseif commmand["modifierMask"] ~= nil then
            modifiers = mod.modifierMaskToModifiers(commmand["modifierMask"])
            if tools.tableContains(modifiers, "numericpad") then
                keypadModifier = true
            end
        end

        if commmand["characterString"] ~= nil then
            if keypadModifier then
                keyCode = mod.keypadCharacterToKeyCode(commmand["characterString"])
            else
                keyCode = mod.characterStringToKeyCode(commmand["characterString"])
            end
        elseif commmand["character"] ~= nil then
            if keypadModifier then
                keyCode = mod.keypadCharacterToKeyCode(commmand["character"])
            else
                keyCode = mod.characterStringToKeyCode(commmand["character"])
            end
        end

        if keyCode ~= nil and keyCode ~= "" then
            shortcuts[#shortcuts + 1] = shortcut.new(modifiers, keyCode)
        end
    end

    return shortcuts
end

return mod
