--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--            D I A L O G B O X     S U P P O R T     L I B R A R Y           --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.dialog ===
---
--- A collection of handy Dialog tools for CommandPost.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("dialog")

local alert										= require("hs.alert")
local console									= require("hs.console")
local fs										= require("hs.fs")
local inspect									= require("hs.inspect")
local osascript									= require("hs.osascript")
local screen									= require("hs.screen")
local sharing									= require("hs.sharing")
local window									= require("hs.window")

local config									= require("cp.config")
local fcp										= require("cp.apple.finalcutpro")
local tools										= require("cp.tools")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local dialog = {}

-- as(appleScript) -> object
-- Function
-- Performs a AppleScript Command.
--
-- Parameters:
--  * appleScript - The AppleScript you want to execute as a string.
--
-- Returns:
--  * An object containing the parsed output that can be any type, or nil if unsuccessful
local function as(appleScript)

	local originalFocusedWindow = window.focusedWindow()
	-- log.df("originalFocusedWindow: %s", originalFocusedWindow)

	local whichBundleID = hs.processInfo["bundleID"]
	if originalFocusedWindow and originalFocusedWindow:application():bundleID() == fcp.BUNDLE_ID then
		whichBundleID = fcp.BUNDLE_ID
	end
	--log.df("whichBundleID: %s", whichBundleID)

	local appleScriptStart = [[
		set yesButton to "]] .. i18n("yes") .. [["
		set noButton to "]] .. i18n("no") .. [["

		set okButton to "]] .. i18n("ok") .. [["
		set cancelButton to "]] .. i18n("cancel") .. [["

		set iconPath to ("]] .. config.iconPath .. [[" as POSIX file)

		set errorMessageStart to "]] .. i18n("commonErrorMessageStart") .. [[\n\n"
		set errorMessageEnd to "\n\n]] .. i18n("commonErrorMessageEnd") .. [["

		tell application id "]] .. whichBundleID .. [["
			activate
	]]

	local appleScriptEnd = [[
		end tell
	]]

	local _, result = osascript.applescript(appleScriptStart .. appleScript .. appleScriptEnd)

	if originalFocusedWindow and whichBundleID == hs.processInfo["bundleID"] then
		originalFocusedWindow:focus()
	end

	return result

end

--- cp.dialog.displaySmallNumberTextBoxMessage(whatMessage, whatErrorMessage, defaultAnswer) -> boolean or string
--- Function
--- Display a dialog box prompting the user for a number input. It accepts only entries that coerce directly to class integer.
---
--- Parameters:
---  * whatMessage - The message you want to display as a string
---  * whatErrorMessage - The error message that appears if a user input is invalid
---  * defaultAnswer - The default value of the text box
---
--- Returns:
---  * `false` if cancelled if pressed otherwise the text entered in the dialog box
function dialog.displaySmallNumberTextBoxMessage(whatMessage, whatErrorMessage, defaultAnswer)
	local appleScript = [[
		set whatMessage to "]] .. whatMessage .. [["
		set whatErrorMessage to "]] .. whatErrorMessage .. [["
		set defaultAnswer to "]] .. defaultAnswer .. [["
		repeat
			try
				set dialogResult to (display dialog whatMessage default answer defaultAnswer buttons {okButton, cancelButton} with icon iconPath)
			on error
				-- Cancel Pressed:
				return false
			end try
			try
				set usersInput to (text returned of dialogResult) as number -- To accept only entries that coerce directly to class integer.
				if usersInput is not equal to missing value then
					if usersInput is not 0 then
						exit repeat
					end if
				end if
			end try
			display dialog whatErrorMessage buttons {okButton} with icon iconPath
		end repeat
		return usersInput
	]]
	return as(appleScript)
end

--- cp.dialog.displayTextBoxMessage(whatMessage, whatErrorMessage, defaultAnswer, validationFn) -> boolean or string
--- Function
--- Display a dialog box prompting the user for a text input.
---
--- Parameters:
---  * whatMessage - The message you want to display as a string
---  * whatErrorMessage - The error message that appears if a user input is invalid
---  * defaultAnswer - The default value of the text box
---  * validationFn - A function that takes one parameter and returns a boolean value
---
--- Returns:
---  * `false` if cancelled if pressed otherwise the text entered in the dialog box
function dialog.displayTextBoxMessage(whatMessage, whatErrorMessage, defaultAnswer, validationFn)
	defaultAnswer = defaultAnswer and tostring(defaultAnswer) or ""
	::retryDisplayTextBoxMessage::
	local appleScript = [[
		set whatMessage to "]] .. whatMessage .. [["
		set whatErrorMessage to "]] .. whatErrorMessage .. [["
		set defaultAnswer to "]] .. defaultAnswer .. [["
		try
			set response to text returned of (display dialog whatMessage default answer defaultAnswer buttons {okButton, cancelButton} default button 1 with icon iconPath)
		on error
			-- Cancel Pressed:
			return false
		end try
		return response
	]]
	local result = as(appleScript)
	if result == false then return false end

	if validationFn ~= nil then
		if type(validationFn) == "function" then
			if not validationFn(result) then
				dialog.displayMessage(whatErrorMessage)
				goto retryDisplayTextBoxMessage
			end
		end
	end

	return result

end

--- cp.dialog.displayChooseFile(whatMessage, fileType) -> boolean or string
--- Function
--- Display a Choose File Dialog Box.
---
--- Parameters:
---  * whatMessage - The message you want to display as a string
---  * fileType - The filetype you wish to display
---
--- Returns:
---  * `false` if cancelled if pressed otherwise the path to the file as a string
function dialog.displayChooseFile(whatMessage, fileType)
	local appleScript = [[
		set whatMessage to "]] .. whatMessage .. [["

		try
			set whichFile to POSIX path of (choose file with prompt whatMessage default location (path to desktop) of type {"]] .. fileType .. [["})
			return whichFile
		on error
			-- Cancel Pressed:
			return false
		end try
	]]
	return as(appleScript)
end

--- cp.dialog.displayChooseFolder(whatMessage) -> boolean or string
--- Function
--- Display a Choose Folder Dialog Box.
---
--- Parameters:
---  * whatMessage - The message you want to display as a string
---
--- Returns:
---  * `false` if cancelled if pressed otherwise the path to the folder as a string
function dialog.displayChooseFolder(whatMessage)
	local appleScript = [[
		set whatMessage to "]] .. whatMessage .. [["

		try
			set whichFolder to POSIX path of (choose folder with prompt whatMessage default location (path to desktop))
			return whichFolder
		on error
			-- Cancel Pressed:
			return false
		end try
	]]
	return as(appleScript)
end

--- cp.dialog.displayAlertMessage(whatMessage) -> none
--- Function
--- Display an Alert Dialog (with stop icon).
---
--- Parameters:
---  * whatMessage - The message you want to display as a string
---
--- Returns:
---  * None
function dialog.displayAlertMessage(whatMessage)
	local appleScript = [[
		set whatMessage to "]] .. whatMessage .. [["

		display dialog whatMessage buttons {okButton} with icon stop
	]]
	return as(appleScript)
end

--- cp.dialog.displayErrorMessage(whatError) -> none
--- Function
--- Display an Error Message Dialog, given the user the option to submit feedback.
---
--- Parameters:
---  * whatError - The message you want to display as a string
---
--- Returns:
---  * None
function dialog.displayErrorMessage(whatError)

	--------------------------------------------------------------------------------
	-- Write error message to console:
	--------------------------------------------------------------------------------
	log.ef(whatError)

	--------------------------------------------------------------------------------
	-- Display Dialog Box:
	--------------------------------------------------------------------------------
	local appleScript = [[
		set whatError to "]] .. whatError .. [["

		display dialog errorMessageStart & whatError & errorMessageEnd buttons {yesButton, noButton} with icon iconPath
		if the button returned of the result is equal to yesButton then
			return true
		else
			return false
		end if
	]]
	local result = as(appleScript)

	--------------------------------------------------------------------------------
	-- Send bug report:
	--------------------------------------------------------------------------------
	if result then
		local feedback = require("cp.feedback")
		feedback.showFeedback(false)
	end

end

--- cp.dialog.displayMessage(whatMessage, optionalButtons) -> object
--- Function
--- Display an Error Message Dialog, given the user the option to submit feedback.
---
--- Parameters:
---  * whatError - The message you want to display as a string
---
--- Returns:
---  * None
function dialog.displayMessage(whatMessage, optionalButtons)

	if optionalButtons == nil or type(optionalButtons) ~= "table" then
		optionalButtons = {i18n("ok")}
	end

	local buttons = 'buttons {'
	for i=1, #optionalButtons do
		buttons = buttons .. '"' .. optionalButtons[i] .. '"'
		if i ~= #optionalButtons then buttons = buttons .. ", " end
	end
	buttons = buttons .. "}"

	local appleScript = [[
		set whatMessage to "]] .. whatMessage .. [["
		set result to button returned of (display dialog whatMessage ]] .. buttons .. [[ with icon iconPath)
		return result
	]]
	return as(appleScript)

end

--- cp.dialog.displayYesNoQuestion(whatMessage) -> boolean
--- Function
--- Displays a "Yes" or "No" question.
---
--- Parameters:
---  * whatMessage - The message you want to display as a string
---
--- Returns:
---  * A boolean with the result.
function dialog.displayYesNoQuestion(whatMessage) -- returns true or false

	local appleScript = [[
		set whatMessage to "]] .. whatMessage .. [["

		display dialog whatMessage buttons {yesButton, noButton} default button 1 with icon iconPath
		if the button returned of the result is equal to yesButton then
			return true
		else
			return false
		end if
	]]
	return as(appleScript)

end

--- cp.dialog.displayChooseFromList(dialogPrompt, listOptions, defaultItems) -> table
--- Function
--- Displays a list that the user can select items from.
---
--- Parameters:
---  * dialogPrompt - The message you want to display as a string
---  * listOptions - A table containing all the options you want to include in the list as strings
---  * defaultItems - A table containing all the options you want select by default in the list as strings
---
--- Returns:
---  * A table with the selected items as strings
function dialog.displayChooseFromList(dialogPrompt, listOptions, defaultItems)

	if dialogPrompt == "nil" then dialogPrompt = "Please make your selection:" end
	if dialogPrompt == "" then dialogPrompt = "Please make your selection:" end

	if defaultItems == nil then defaultItems = {} end
	if type(defaultItems) ~= "table" then defaultItems = {} end

	local appleScript = [[
		set dialogPrompt to "]] .. dialogPrompt .. [["
		set listOptions to ]] .. inspect(listOptions) .. "\n\n" .. [[
		set defaultItems to ]] .. inspect(defaultItems) .. "\n\n" .. [[

		return choose from list listOptions with title "]] .. config.appName .. [[" with prompt dialogPrompt default items defaultItems
	]]

	return as(appleScript)

end

--- cp.dialog.displayColorPicker(customColor) -> table or nil
--- Function
--- Displays a System Colour Picker.
---
--- Parameters:
---  * customColor - An RGB Table to use as the default value
---
--- Returns:
---  * An RGB table with the selected colour or `nil`
function dialog.displayColorPicker(customColor) -- Accepts RGB Table

	local defaultColor = {65535, 65535, 65535}
	if type(customColor) == "table" then
		local validColor = true
		if customColor["red"] == nil then validColor = false end
		if customColor["green"] == nil then validColor = false end
		if customColor["blue"] == nil then validColor = false end
		if validColor then
			defaultColor = { customColor["red"] * 257 * 255, customColor["green"] * 257 * 255, customColor["blue"] * 257 * 255 }
		end
	end
	local appleScript = [[
		set defaultColor to ]] .. inspect(defaultColor) .. "\n\n" .. [[
		return choose color default color defaultColor
	]]
	local result = as(appleScript)
	if type(result) == "table" then
		local red = result[1] / 257 / 255
		local green = result[2] / 257 / 255
		local blue = result[3] / 257 / 255
		if red ~= nil and green ~= nil and blue ~= nil then
			return {red=red, green=green, blue=blue, alpha=1}
		end
	end
	return nil

end

--- cp.dialog.displayNotification(whatMessage) -> none
--- Function
--- Display's an alert on the screen.
---
--- Parameters:
---  * whatMessage - The message you want to display as a string
---
--- Returns:
---  * None
---
--- Notes:
---  * Any existing alerts will be removed to make way for the new one.
function dialog.displayNotification(whatMessage)
	alert.closeAll(0)
	alert.show(whatMessage, { textStyle = { paragraphStyle = { alignment = "center" } } })
end

return dialog