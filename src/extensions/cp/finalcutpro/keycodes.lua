--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Keycodes Module

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local keycodes								= require("hs.keycodes")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- cp.finalcutpro.characterStringToKeyCode() -> string
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

	if input == " " 									then result = "space"		end
	if string.find(input, "NSF1FunctionKey") 			then result = "f1" 			end
	if string.find(input, "NSF2FunctionKey") 			then result = "f2" 			end
	if string.find(input, "NSF3FunctionKey") 			then result = "f3" 			end
	if string.find(input, "NSF4FunctionKey") 			then result = "f4" 			end
	if string.find(input, "NSF5FunctionKey") 			then result = "f5" 			end
	if string.find(input, "NSF6FunctionKey") 			then result = "f6" 			end
	if string.find(input, "NSF7FunctionKey") 			then result = "f7" 			end
	if string.find(input, "NSF8FunctionKey") 			then result = "f8" 			end
	if string.find(input, "NSF9FunctionKey") 			then result = "f9" 			end
	if string.find(input, "NSF10FunctionKey") 			then result = "f10" 		end
	if string.find(input, "NSF11FunctionKey") 			then result = "f11" 		end
	if string.find(input, "NSF12FunctionKey") 			then result = "f12" 		end
	if string.find(input, "NSF13FunctionKey") 			then result = "f13" 		end
	if string.find(input, "NSF14FunctionKey") 			then result = "f14" 		end
	if string.find(input, "NSF15FunctionKey") 			then result = "f15" 		end
	if string.find(input, "NSF16FunctionKey") 			then result = "f16" 		end
	if string.find(input, "NSF17FunctionKey") 			then result = "f17" 		end
	if string.find(input, "NSF18FunctionKey") 			then result = "f18" 		end
	if string.find(input, "NSF19FunctionKey") 			then result = "f19" 		end
	if string.find(input, "NSF20FunctionKey") 			then result = "f20" 		end
	if string.find(input, "NSUpArrowFunctionKey") 		then result = "up" 			end
	if string.find(input, "NSDownArrowFunctionKey") 	then result = "down" 		end
	if string.find(input, "NSLeftArrowFunctionKey") 	then result = "left" 		end
	if string.find(input, "NSRightArrowFunctionKey") 	then result = "right" 		end
	if string.find(input, "NSDeleteFunctionKey") 		then result = "delete" 		end
	if string.find(input, "NSHomeFunctionKey") 			then result = "home" 		end
	if string.find(input, "NSEndFunctionKey") 			then result = "end" 		end
	if string.find(input, "NSPageUpFunctionKey") 		then result = "pageup" 		end
	if string.find(input, "NSPageDownFunctionKey") 		then result = "pagedown" 	end

	--------------------------------------------------------------------------------
	-- Convert to lowercase:
	--------------------------------------------------------------------------------
	result = string.lower(result)
	return result

end

mod.padKeys = { "*", "+", "/", "-", "=", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "clear", "enter" }

--- cp.finalcutpro.keypadCharacterToKeyCode() -> string
--- Function
--- Translate Keyboard Keypad Character Strings from Command Set Format into Hammerspoon Format.
---
--- Parameters:
---  * input - Character String
---
--- Returns:
---  * string or nil
function mod.keypadCharacterToKeyCode(input)

	local result = nil
	for i=1, #padKeys do
		if input == padKeys[i] then result = "pad" .. input end
	end

	return mod.characterStringToKeyCode(result)

end

--- cp.finalcutpro.fcpxModifiersToHsModifiers() -> table
--- Function
--- Translate Keyboard Modifiers from Command Set Format into Hammerspoon Format
---
--- Parameters:
---  * input - Modifiers String
---
--- Returns:
---  * table
function mod.fcpxModifiersToHsModifiers(input)

	local result = {}
	if string.find(input, "command") then result[#result + 1] = "command" end
	if string.find(input, "control") then result[#result + 1] = "control" end
	if string.find(input, "option") then result[#result + 1] = "option" end
	if string.find(input, "shift") then result[#result + 1] = "shift" end
	return result

end

--- cp.finalcutpro.modifierMaskToModifiers() -> table
--- Function
--- Translate Keyboard Modifiers from Command Set Format into Hammerspoon Format
---
--- Parameters:
---  * value - Modifiers String
---
--- Returns:
---  * table
function mod.modifierMaskToModifiers(value)

	local modifiers = {
		--AlphaShift = 1 << 16,
		shift      = 1 << 17,
		control    = 1 << 18,
		option	   = 1 << 19,
		command    = 1 << 20,
		--NumericPad = 1 << 21,
		--Help       = 1 << 22,
		--Function   = 1 << 23,
	}

	local answer = {}

	for k, v in pairs(modifiers) do
		if (value & v) == v then
			table.insert(answer, k)
		end
	end

	return answer

end

return mod