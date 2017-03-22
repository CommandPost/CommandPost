--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--             G E N E R A L    P R E F E R E N C E S    P A N E L            --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.plugins.core.preferences.generate ===
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
	-- COUNTERS:
	--------------------------------------------------------------------------------
	mod._checkboxCount 							= 0
	mod._buttonCount 							= 0
	mod._dropdownCount 							= 0

	--------------------------------------------------------------------------------
	-- CONSTANTS:
	--------------------------------------------------------------------------------
	mod.UI_CHECKBOX								= 1
	mod.UI_HEADING								= 2
	mod.UI_BUTTON								= 3
	mod.UI_DROPDOWN								= 4

	--------------------------------------------------------------------------------
	-- SET WEBVIEW LABEL:
	--------------------------------------------------------------------------------
	function mod.setWebviewLabel(value)
		mod._webviewLabel = value
	end

	--------------------------------------------------------------------------------
	-- GENERATE CHECKBOX:
	--------------------------------------------------------------------------------
	function mod.checkbox(data)

		local isChecked = ""
		if data["checked"] then
			isChecked = " checked"
		end

		local id = "checkbox" .. mod._checkboxCount

		local result = [[<p class="uiItem"><input type="checkbox" id="]] .. id .. [[" value=""]] .. isChecked .. [[> ]] .. data["title"] .. [[</p>
		<script>
    		var ]] .. id .. [[=document.getElementById("]] .. id .. [[");
    		]] .. id .. [[.onchange = function (){
				try {
					var checked = document.getElementById("]] .. id .. [[").checked;
					var result = ["]] .. data["title"] .. [[", checked];
					webkit.messageHandlers.]] .. mod._webviewLabel .. [[.postMessage(result);
				} catch(err) {
					alert('An error has occurred. Does the controller exist yet?');
				}
    		}
		</script>
		]]

		mod._checkboxCount = mod._checkboxCount + 1

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
	function mod.button(data)

		local id = "button" .. mod._buttonCount

		local result = [[<p class="uiItem"><a id="]] .. id ..  [[" class="button" href="#">]] .. data["title"] .. [[</a></p>
		<script>
    		var ]] .. id .. [[=document.getElementById("]] .. id .. [[");
    		]] .. id .. [[.onclick = function (){
				try {
					var result = ["]] .. data["title"] .. [["];
					webkit.messageHandlers.]] .. mod._webviewLabel .. [[.postMessage(result);
				} catch(err) {
					alert('An error has occurred. Does the controller exist yet?');
				}
    		}
		</script>
		]]

		mod._buttonCount = mod._buttonCount + 1

		return result

	end

	--------------------------------------------------------------------------------
	-- GENERATE DROPDOWN:
	--------------------------------------------------------------------------------
	function mod.dropdown(title, data)

		local id = "dropdown" .. mod._dropdownCount

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
					var result = ["]] .. title .. [[", dropdownResult];
					webkit.messageHandlers.]] .. mod._webviewLabel .. [[.postMessage(result);
				} catch(err) {
					alert('An error has occurred. Does the controller exist yet?');
				}
    		}
		</script>
		]]

		mod._dropdownCount = mod._dropdownCount + 1

		return result

	end

return mod