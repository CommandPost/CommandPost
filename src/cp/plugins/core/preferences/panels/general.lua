--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--             G E N E R A L    P R E F E R E N C E S    P A N E L            --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.plugins.core.preferences.panels.general ===
---
--- General Preferences Panel

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("prefsGeneral")

local application								= require("hs.application")
local base64									= require("hs.base64")
local console									= require("hs.console")
local drawing									= require("hs.drawing")
local geometry									= require("hs.geometry")
local screen									= require("hs.screen")
local timer										= require("hs.timer")
local toolbar                  					= require("hs.webview.toolbar")
local urlevent									= require("hs.urlevent")
local webview									= require("hs.webview")

local image										= require("hs.image")

local dialog									= require("cp.dialog")
local fcp										= require("cp.finalcutpro")
local metadata									= require("cp.metadata")
local plugins									= require("cp.plugins")
local template									= require("cp.template")
local tools										= require("cp.tools")

--------------------------------------------------------------------------------
-- CONSTANTS:
--------------------------------------------------------------------------------

local DEFAULT_PRIORITY 							= 0

local UI_CHECKBOX								= 1
local UI_HEADING								= 2
local UI_BUTTON									= 3
local UI_DROPDOWN								= 4

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------
local mod = {}

	mod._uiItems 								= {}

	mod._checkboxCount 							= 0
	mod._buttonCount 							= 0
	mod._dropdownCount 							= 0

	--------------------------------------------------------------------------------
	-- CONTROLLER CALLBACK:
	--------------------------------------------------------------------------------
	local function controllerCallback(message)

		--log.df("Callback Result: %s", hs.inspect(message))

		local title = message["body"][1]
		local result = message["body"][2]

		for i, v in ipairs(mod._uiItems) do
			--------------------------------------------------------------------------------
			-- Dropdown Items:
			--------------------------------------------------------------------------------
			if v["uiType"] == UI_DROPDOWN then
				if v["title"] == title then
					local data = v["itemFn"]()
					for a, b in ipairs(data) do
						if b["title"] == result then
							if type(b["fn"]) == "function" then
								--------------------------------------------------------------------------------
								-- Trigger Function:
								--------------------------------------------------------------------------------
								b["fn"]()
								return
							else
								log.df("Failed to trigger Dropdown Callback Function.")
								return
							end
						end
					end
				end
			else
			--------------------------------------------------------------------------------
			-- Everything Else:
			--------------------------------------------------------------------------------
				local data = v["itemFn"]()
				if data["title"] == title then
					if type(data["fn"]) == "function" then
						--------------------------------------------------------------------------------
						-- Trigger Function:
						--------------------------------------------------------------------------------
						data["fn"]()
						return
					else
						log.df("Failed to trigger Callback Function.")
						return
					end
				end
			end
		end

	end

	--------------------------------------------------------------------------------
	-- GENERATE CHECKBOX:
	--------------------------------------------------------------------------------
	local function generateCheckbox(data)

		local isChecked = ""
		if data["checked"] then
			isChecked = " checked"
		end

		local id = "checkbox" .. mod._checkboxCount

		local result = [[<input type="checkbox" id="]] .. id .. [[" value=""]] .. isChecked .. [[> ]] .. data["title"] .. [[<br />
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
	local function generateHeading(data)

		local result = "<h3>" .. data["title"] .. "</h3>\n"
		return result

	end

	--------------------------------------------------------------------------------
	-- GENERATE BUTTON:
	--------------------------------------------------------------------------------
	local function generateButton(data)

		local id = "button" .. mod._buttonCount

		local result = [[<a id="]] .. id ..  [[" class="button" href="#">]] .. data["title"] .. [[</a><br />
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
	local function generateDropdown(title, data)

		local id = "dropdown" .. mod._dropdownCount

		local options = ""

		for i, v in ipairs(data) do
			local selected = ""
			if v["checked"] then selected = [[ selected="selected" ]] end

			options = options .. [[<option value="]] .. v["title"] .. [["]] .. selected .. [[>]] .. v["title"] .. [[</option>]]

		end

		local result = title .. [[: <select id="]] .. id .. [[">]] .. options .. [[</select><br />
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


	--------------------------------------------------------------------------------
	-- GENERATE CONTENT:
	--------------------------------------------------------------------------------
	local function generateContent()

		local result = ""

		table.sort(mod._uiItems, function(a, b) return a.priority < b.priority end)
		for i, v in ipairs(mod._uiItems) do

			local data = v["itemFn"]()

			local uiType = v["uiType"]

			if uiType == UI_CHECKBOX then
				result = result .. "\n" .. generateCheckbox(data)
			elseif uiType == UI_HEADING then
				result = result .. "\n" .. generateHeading(data)
			elseif uiType == UI_BUTTON then
				result = result .. "\n" .. generateButton(data)
			elseif uiType == UI_DROPDOWN then
				result = result .. "\n" .. generateDropdown(v["title"], data)

			end

		end

		return result
	end

	--------------------------------------------------------------------------------
	-- INITIALISE MODULE:
	--------------------------------------------------------------------------------
	function mod.init(deps)

		mod._webviewLabel 	= deps.manager.getLabel()

		local id 			= "general"
		local label 		= "General"
		local image			= image.imageFromName("NSPreferencesGeneral")
		local priority		= 1
		local tooltip		= "General Preferences"
		local contentFn		= generateContent
		local callbackFn 	= controllerCallback

		deps.manager.addPanel(id, label, image, priority, tooltip, contentFn, callbackFn)

		return mod

	end

	--------------------------------------------------------------------------------
	-- ADD CHECKBOX:
	--------------------------------------------------------------------------------
	function mod:addCheckbox(priority, itemFn)

		--log.df("Adding Checkbox to General Preferences Panel: %s", itemFn)

		priority = priority or DEFAULT_PRIORITY

		mod._uiItems[#mod._uiItems + 1] = {
			priority = priority,
			itemFn = itemFn,
			uiType = UI_CHECKBOX,
		}

		return self

	end

	--------------------------------------------------------------------------------
	-- ADD HEADING:
	--------------------------------------------------------------------------------
	function mod:addHeading(priority, itemFn)

		priority = priority or DEFAULT_PRIORITY

		mod._uiItems[#mod._uiItems + 1] = {
			priority = priority,
			itemFn = itemFn,
			uiType = UI_HEADING,
		}

		return self

	end

	--------------------------------------------------------------------------------
	-- ADD BUTTON:
	--------------------------------------------------------------------------------
	function mod:addButton(priority, itemFn)

		priority = priority or DEFAULT_PRIORITY

		mod._uiItems[#mod._uiItems + 1] = {
			priority = priority,
			itemFn = itemFn,
			uiType = UI_BUTTON,
		}

		return self

	end

	--------------------------------------------------------------------------------
	-- ADD DROPDOWN:
	--------------------------------------------------------------------------------
	function mod:addDropdown(priority, title, itemFn)

		priority = priority or DEFAULT_PRIORITY

		mod._uiItems[#mod._uiItems + 1] = {
			title = title,
			priority = priority,
			itemFn = itemFn,
			uiType = UI_DROPDOWN,
		}

		return self

	end

--------------------------------------------------------------------------------
-- THE PLUGIN:
--------------------------------------------------------------------------------
local plugin = {}

	--------------------------------------------------------------------------------
	-- DEPENDENCIES:
	--------------------------------------------------------------------------------
	plugin.dependencies = {
		["cp.plugins.core.preferences.manager"]			= "manager",
	}

	--------------------------------------------------------------------------------
	-- INITIALISE PLUGIN:
	--------------------------------------------------------------------------------
	function plugin.init(deps)
		return mod.init(deps)
	end

return plugin