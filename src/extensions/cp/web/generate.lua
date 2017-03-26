--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--             G E N E R A L    P R E F E R E N C E S    P A N E L            --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.web.generate ===
---
--- Functions for Generating HTML UI Items

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("prefsGenerate")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- None

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
mod.UI_CHECKBOX								= 1
mod.UI_HEADING								= 2
mod.UI_BUTTON								= 3
mod.UI_DROPDOWN								= 4

--------------------------------------------------------------------------------
-- RANDOM STRING GENERATOR:
--------------------------------------------------------------------------------
local function randomLetter()
	local str="abcdefghijklmnopqrstuvwxyz"
	return string.char(str:byte(math.random(1, #str)))
end

--------------------------------------------------------------------------------
-- RANDOM WORD GENERATOR:
--------------------------------------------------------------------------------
local function randomWord(length)
	local result = ""
	for i=1, length do
		result = result .. randomLetter()
	end
	return result
end

--- cp.web.generate.setWebviewLabel() -> none
--- Sets the WebView Label
---
--- Parameters:
---  * value - WebView Label as string
---
--- Returns:
---  * None
---
function mod.setWebviewLabel(value)
	mod._webviewLabel = value
end

--- cp.web.generate.checkbox() -> string
--- Generates a HTML Checkbox
---
--- Parameters:
---  * data - Table containing the data you want to display on the Checkbox
---  * customTrigger - Custom label used for JavaScript Callback
---
--- Returns:
---  * String containing the HTML
---
function mod.checkbox(data, customTrigger)

	local result = data["title"]
	if customTrigger then result = customTrigger end

	local isChecked = ""
	if data["checked"] then
		isChecked = " checked"
	end

	local id = "checkbox" .. randomWord(20)

	local result = [[<p class="uiItem"><input type="checkbox" id="]] .. id .. [[" value=""]] .. isChecked .. [[> ]] .. data["title"] .. [[</p>
	<script>
		var ]] .. id .. [[=document.getElementById("]] .. id .. [[");
		]] .. id .. [[.onchange = function (){
			try {
				var checked = document.getElementById("]] .. id .. [[").checked;
				var result = ["]] .. result .. [[", checked];
				webkit.messageHandlers.]] .. mod._webviewLabel .. [[.postMessage(result);
			} catch(err) {
				alert('An error has occurred. Does the controller exist yet?');
			}
		}
	</script>
	]]

	return result

end

--- cp.web.generate.heading() -> string
--- Generates a HTML Heading
---
--- Parameters:
---  * data - Table containing the data you want to display on the Checkbox
---
--- Returns:
---  * String containing the HTML
---
function mod.heading(data)

	local result = "<h3>" .. data["title"] .. "</h3>\n"
	return result

end

--- cp.web.generate.button() -> string
--- Generates a HTML Button
---
--- Parameters:
---  * data - Table containing the data you want to display on the Checkbox
---  * customTrigger - Custom label used for JavaScript Callback
---  * customWidth - Number to set the width of the button to
---
--- Returns:
---  * String containing the HTML
---
function mod.button(data, customTrigger, customWidth)

	local result = data["title"]
	if customTrigger then result = customTrigger end

	local id = "button" .. randomWord(20)

	local style = ""
	if customWidth then
		style = [[ style="width: ]] .. customWidth .. [[px;" ]]
	end

	local result = [[<p class="uiItem"><a id="]] .. id ..  [[" ]] .. style .. [[class="button" href="#">]] .. data["title"] .. [[</a></p>
	<script>
		var ]] .. id .. [[=document.getElementById("]] .. id .. [[");
		]] .. id .. [[.onclick = function (){
			try {
				var result = ["]] .. result .. [["];
				webkit.messageHandlers.]] .. mod._webviewLabel .. [[.postMessage(result);
			} catch(err) {
				alert('An error has occurred. Does the controller exist yet?');
			}
		}
	</script>
	]]

	return result

end

--- cp.web.generate.dropdown() -> string
--- Generates a HTML Dropdown
---
--- Parameters:
---  * title - Title to put in front of the Dropdown. Can be "".
---  * data - Table containing the data you want to display on the Checkbox
---  * customTrigger - Custom label used for JavaScript Callback
---
--- Returns:
---  * String containing the HTML
---
function mod.dropdown(title, data, customTrigger)

	local result = title
	if customTrigger then result = customTrigger end

	if title ~= "" then title = title .. ": " end

	local id = "dropdown" .. randomWord(20)

	local options = ""

	for i, v in ipairs(data) do
		local selected = ""
		if v["checked"] then selected = [[ selected="selected" ]] end

		options = options .. [[<option value="]] .. v["title"] .. [["]] .. selected .. [[>]] .. v["title"] .. [[</option>]]

	end

	local result = [[<p class="uiItem">]] .. title .. [[<select id="]] .. id .. [[">]] .. options .. [[</select></p>
	<script>
		var ]] .. id .. [[=document.getElementById("]] .. id .. [[");
		]] .. id .. [[.onchange = function (){
			try {
				var dropdownResult = document.getElementById("]] .. id .. [[").value;
				var result = ["]] .. result .. [[", dropdownResult];
				webkit.messageHandlers.]] .. mod._webviewLabel .. [[.postMessage(result);
			} catch(err) {
				alert('An error has occurred. Does the controller exist yet?');
			}
		}
	</script>
	]]

	return result

end

--- cp.web.generate.init() -> none
--- Initialises the module
---
--- Parameters:
---  * None
---
--- Returns:
---  * Table containing the module
---
function mod.init()
	return mod
end

return mod.init()