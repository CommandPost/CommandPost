--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                T A N G E N T    M A N A G E R    P L U G I N               --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.tangent.manager ===
---
--- Tangent Control Surface Manager
---
--- This plugin allows Hammerspoon to communicate with Tangent's range of
--- panels (Element, Virtual Element Apps, Wave, Ripple and any future panels).
---
--- Download the Tangent Developer Support Pack & Tangent Hub Installer for Mac
--- here: http://www.tangentwave.co.uk/developer-support/

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("tangentMan")

local tangent									= require("hs.tangent")

local config									= require("cp.config")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------

local mod = {}

function mod.callback(id, metadata)
	log.df("id: %s", id)
	log.df("metadata: %s", hs.inspect(metadata))
end

--- plugins.finalcutpro.tangent.manager.start() -> boolean
--- Function
--- Starts the Tangent Plugin
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if successfully started, otherwise `false`
function mod.start()
	if tangent.isTangentHubInstalled() then
		local result, errorMessage = tangent.connect("CommandPost", mod._path)
		if result then
			tangent.callback(mod.callback)
			return true
		else
			log.ef("Failed to start Tangent Support: %s", errorMessage)
			return false
		end
	else
		return false
	end
end

--- plugins.finalcutpro.tangent.manager.stop() -> boolean
--- Function
--- Stops the Tangent Plugin
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.stop()
	tangent.disconnect()
end

--- plugins.finalcutpro.tangent.manager.enabled <cp.prop: boolean>
--- Field
--- Enable or disables the Tangent Manager.
mod.enabled = config.prop("enableTangent", true):watch(function(enabled)
	if enabled then
		mod.start()
	else
		mod.stop()
	end
end)

--- plugins.finalcutpro.tangent.manager.init(deps, env) -> none
--- Function
--- Initialises the Tangent Plugin
---
--- Parameters:
---  * deps - Dependencies Table
---  * env - Environment Table
---
--- Returns:
---  * None
function mod.init(deps, env)
	if mod.enabled() then
		mod.start()
	end
	return mod
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id			= "core.tangent.manager",
	group		= "core",
	required	= true,
	dependencies	= {
		["core.preferences.panels.tangent"]				= "prefs",
		["core.preferences.manager"]					= "prefsManager",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)

	--------------------------------------------------------------------------------
	-- Get XML Path:
	--------------------------------------------------------------------------------
	mod._path = env:pathToAbsolute("/xml")

	--------------------------------------------------------------------------------
	-- Setup Preferences Panel:
	--------------------------------------------------------------------------------
	if deps.prefs then
		deps.prefs
			:addContent(1, [[
				<style>
					.tangentButtonOne {
						float:left;
					}
					.tangentButtonTwo {
						float:left;
						margin-left:-10px;
					}
				</style>
			]], true)
			:addHeading(2, "Tangent Panel Support")
			:addParagraph(3,
			[[CommandPost offers native managed support of the entire range of Tangent's panels, including the Element, Wave, Ripple, the Element-Vs iPad app, and any future panels.<br />
			<br />
			All actions within CommandPost can be assigned to any Tangent panel button/wheel using Tangent's Mapper application.<br />
			<br />]], true)
			:addCheckbox(4,
				{
					label = "Enable Tangent Support",
					onchange = function(_, params)
						mod.enabled(params.checked)
					end,
					checked = mod.enabled,
				}
			)
			:addParagraph(5, "<br />", true)
			:addButton(6,
				{
					label = "Open Tangent Mapper",
					onclick = function(_, params)
						os.execute('open "/Applications/Tangent/Tangent Mapper.app"')
					end,
					class = "tangentButtonOne",
				}
			)
			:addButton(7,
				{
					label = "Download Tangent Hub",
					onclick = function(_, params)
						os.execute('open "http://www.tangentwave.co.uk/download/tangent-hub-installer-mac/"')
					end,
					class = "tangentButtonTwo",
				}
			)
			:addButton(8,
				{
					label = "Visit Tangent Website",
					onclick = function(_, params)
						os.execute('open "http://www.tangentwave.co.uk/"')
					end,
					class = "tangentButtonTwo",
				}
			)

	end

	--------------------------------------------------------------------------------
	-- Return Module:
	--------------------------------------------------------------------------------
	return mod.init()
end

return plugin