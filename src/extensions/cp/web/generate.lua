--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--             G E N E R A L    P R E F E R E N C E S    P A N E L            --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.web.generate ===
---
--- Functions for Generating HTML UI Items

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("prefsGenerate")

--------------------------------------------------------------------------------
-- CONSTANTS:
--------------------------------------------------------------------------------

-- None

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------
local mod = {}

	--------------------------------------------------------------------------------
	-- CONSTANTS:
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

	--------------------------------------------------------------------------------
	-- SET WEBVIEW LABEL:
	--------------------------------------------------------------------------------
	function mod.setWebviewLabel(value)
		log.df("setWebviewLabel to: %s", value)
		mod._webviewLabel = value
	end

	--------------------------------------------------------------------------------
	-- GENERATE CHECKBOX:
	--------------------------------------------------------------------------------
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

	--------------------------------------------------------------------------------
	-- GENERATE HEADING:
	--------------------------------------------------------------------------------
	function mod.heading(data)

		local result = "<h3>" .. data["title"] .. "</h3>\n"
		return result

	end

	--------------------------------------------------------------------------------
	-- GENERATE BUTTON:
	--------------------------------------------------------------------------------
	function mod.button(data, customTrigger)

		local result = data["title"]
		if customTrigger then result = customTrigger end

		local id = "button" .. randomWord(20)

		local result = [[<p class="uiItem"><a id="]] .. id ..  [[" class="button" href="#">]] .. data["title"] .. [[</a></p>
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

	--------------------------------------------------------------------------------
	-- GENERATE DROPDOWN:
	--------------------------------------------------------------------------------
	function mod.dropdown(title, data, customTrigger)

		local result = title
		if customTrigger then result = customTrigger end

		local id = "dropdown" .. randomWord(20)

		local options = ""

		for i, v in ipairs(data) do
			local selected = ""
			if v["checked"] then selected = [[ selected="selected" ]] end

			options = options .. [[<option value="]] .. v["title"] .. [["]] .. selected .. [[>]] .. v["title"] .. [[</option>]]

		end

		local result = [[<p class="uiItem">]] .. title .. [[: <select id="]] .. id .. [[">]] .. options .. [[</select></p>
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

	--------------------------------------------------------------------------------
	-- INITIALISE MODULE:
	--------------------------------------------------------------------------------
	function mod.init()
		return mod
	end

return mod.init()