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
local hsDialog									= require("hs.dialog")

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

--- cp.dialog.displayChooseFile(whatMessage, fileType[, defaultLocation]) -> boolean or string
--- Function
--- Display a Choose File Dialog Box.
---
--- Parameters:
---  * whatMessage - The message you want to display as a string
---  * fileType - The filetype you wish to display
---  * defaultLocation - Path to Default Location
---
--- Returns:
---  * `false` if cancelled if pressed otherwise the path to the file as a string
function dialog.displayChooseFile(whatMessage, fileType, defaultLocation)
	if not defaultLocation then
		defaultLocation = os.getenv("HOME") .. "/Desktop"
	end
	local appleScript = [[
		set whatMessage to "]] .. whatMessage .. [["
		try
			set whichFile to POSIX path of (choose file with prompt whatMessage default location (POSIX path of "]] .. defaultLocation .. [[") of type {"]] .. fileType .. [["})
			return whichFile
		on error
			-- Cancel Pressed:
			return false
		end try
	]]
	return as(appleScript)
end

--- cp.dialog.displayChooseFolder(whatMessage[, defaultLocation]) -> boolean or string
--- Function
--- Display a Choose Folder Dialog Box.
---
--- Parameters:
---  * whatMessage - The message you want to display as a string
---  * defaultLocation - Path to Default Location
---
--- Returns:
---  * `false` if cancelled if pressed otherwise the path to the folder as a string
function dialog.displayChooseFolder(whatMessage, defaultLocation)
	if not defaultLocation then
		defaultLocation = os.getenv("HOME") .. "/Desktop"
	end
	local appleScript = [[
		set whatMessage to "]] .. whatMessage .. [["

		try
			set whichFolder to POSIX path of (choose folder with prompt whatMessage default location (POSIX path of "]] .. defaultLocation .. [["))
			return whichFolder
		on error
			-- Cancel Pressed:
			return false
		end try
	]]
	return as(appleScript)
end

--- cp.dialog.displayAlertMessage(message) -> none
--- Function
--- Display an Alert Dialog (with stop icon).
---
--- Parameters:
---  * message - The message you want to display as a string
---
--- Returns:
---  * None
function dialog.displayAlertMessage(message, informativeText)

	if not message then message = "" end
	if not informativeText then informativeText = "" end
		
	local originalFocusedWindow = window.focusedWindow()
	hsDialog.blockAlert(message, informativeText, i18n("ok"), "", "informational")
	if originalFocusedWindow then originalFocusedWindow:focus() end

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
function dialog.displayErrorMessage(message, informativeText)

	--------------------------------------------------------------------------------
	-- Write error message to console:
	--------------------------------------------------------------------------------
	log.ef(message)

	--------------------------------------------------------------------------------
	-- Display Dialog Box:
	--------------------------------------------------------------------------------	
	if not message then message = "" end
	if not informativeText then informativeText = "" end
	local errorMessage = message .. "\n\n" .. i18n("commonErrorMessageEnd")
	local originalFocusedWindow = window.focusedWindow()
	local result = hsDialog.blockAlert(i18n("commonErrorMessageStart"), errorMessage, i18n("yes"), i18n("no"), "critical")
	if originalFocusedWindow then originalFocusedWindow:focus() end
	if result == i18n("yes") then
		local feedback = require("cp.feedback") -- This is defined here, otherwise it will cause an error.
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

--- cp.dialog.displayYesNoQuestion(message) -> boolean
--- Function
--- Displays a "Yes" or "No" question.
---
--- Parameters:
---  * whatMessage - The message you want to display as a string
---
--- Returns:
---  * `true` if yes is clicked otherwise `false`
function dialog.displayYesNoQuestion(message, informativeText) -- returns true or false

	if not message then message = "" end
	if not informativeText then informativeText = "" end
		
	local originalFocusedWindow = window.focusedWindow()
	local result = hsDialog.blockAlert(message, informativeText, i18n("yes"), i18n("no"), "informational")
	if originalFocusedWindow then originalFocusedWindow:focus() end
	
	if result == i18n("yes") then
		return true
	else
		return false
	end
	
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