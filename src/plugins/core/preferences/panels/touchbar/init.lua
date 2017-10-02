--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--            T O U C H B A R    P R E F E R E N C E S    P A N E L           --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.preferences.panels.touchbar ===
---
--- Touch Bar Preferences Panel

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("prefsTouchBar")

local dialog									= require("hs.dialog")
local image										= require("hs.image")
local inspect									= require("hs.inspect")

local commands									= require("cp.commands")
local config									= require("cp.config")
local fcp										= require("cp.apple.finalcutpro")
local html										= require("cp.web.html")
local plist										= require("cp.plist")
local tools										= require("cp.tools")
local ui										= require("cp.web.ui")

local _											= require("moses")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.core.preferences.panels.touchbar.supportedExtensions -> string
--- Variable
--- Table of supported extensions for Touch Bar Icons.
mod.supportedExtensions = {"jpeg", "jpg", "tiff", "gif", "png", "tif", "bmp"}

--- plugins.core.preferences.panels.touchbar.defaultIconPath -> string
--- Variable
--- Default Path where built-in icons are stored
mod.defaultIconPath = cp.config.basePath .. "/plugins/core/touchbar/icons"

--- plugins.core.preferences.panels.touchbar.enabled <cp.prop: boolean>
--- Field
--- Enable or disable Touch Bar Support.
mod.enabled = config.prop("enableTouchBar", false)

--- plugins.core.preferences.panels.touchbar.lastGroup <cp.prop: string>
--- Field
--- Last group used in the Preferences Drop Down.
mod.lastGroup = config.prop("touchBarPreferencesLastGroup", nil)

--- plugins.core.preferences.panels.touchbar.maxItems -> number
--- Variable
--- The maximum number of Touch Bar items per group.
mod.maxItems = 8

-- resetTouchBar() -> none
-- Function
-- Prompts to reset shortcuts to default.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function resetTouchBar()

	dialog.webviewAlert(mod._manager.getWebview(), function(result) 
		if result == i18n("yes") then
			mod._tb.clear()
			mod._manager.refresh()					
		end
	end, i18n("touchBarResetConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")

end

-- renderRows(context) -> none
-- Function
-- Generates the Preference Panel HTML Content.
--
-- Parameters:
--  * context - Table of data that you want to share with the renderer
--
-- Returns:
--  * HTML content as string
local function renderRows(context)
	if not mod._renderRows then
		mod._renderRows, err = mod._env:compileTemplate("html/rows.html")
		if err then
			error(err)
		end
	end
	return mod._renderRows(context)
end

-- renderPanel(context) -> none
-- Function
-- Generates the Preference Panel HTML Content.
--
-- Parameters:
--  * context - Table of data that you want to share with the renderer
--
-- Returns:
--  * HTML content as string
local function renderPanel(context)
	if not mod._renderPanel then
		mod._renderPanel, err = mod._env:compileTemplate("html/panel.html")
		if err then
			error(err)
		end
	end
	return mod._renderPanel(context)
end

-- generateContent() -> string
-- Function
-- Generates the Preference Panel HTML Content.
--
-- Parameters:
--  * None
--
-- Returns:
--  * HTML content as string
local function generateContent()

	--------------------------------------------------------------------------------	
	-- The Group Select:
	--------------------------------------------------------------------------------
	local groupOptions = {}
	local defaultGroup = nil
	if mod.lastGroup() then defaultGroup = mod.lastGroup() end -- Get last group from preferences.
	for _,id in ipairs(commands.groupIds()) do
		defaultGroup = defaultGroup or id
		groupOptions[#groupOptions+1] = { value = id, label = i18n("shortcut_group_"..id, {default = id})}
	end
	table.sort(groupOptions, function(a, b) return a.label < b.label end)

	local touchBarGroupSelect = ui.select({
		id			= "touchBarGroupSelect",
		value		= defaultGroup,
		options		= groupOptions,
		required	= true,
	}) .. ui.javascript([[
		var touchBarGroupSelect = document.getElementById("touchBarGroupSelect")
		touchBarGroupSelect.onchange = function(e) {
								
			//
			// Change Group Callback:
			//
			try {
				var result = {
					id: "touchBarPanelCallback",
					params: {
						type: "updateGroup",
						groupID: this.value,
					},
				}
				webkit.messageHandlers.]] .. mod._manager.getLabel() .. [[.postMessage(result);
			} catch(err) {
				console.log("Error: " + err)
				alert('An error has occurred. Does the controller exist yet?');
			}							
		
			console.log("touchBarGroupSelect changed");
			var groupControls = document.getElementById("touchbarGroupControls");
			var value = touchBarGroupSelect.options[touchBarGroupSelect.selectedIndex].value;
			var children = groupControls.children;
			for (var i = 0; i < children.length; i++) {
			  var child = children[i];
			  if (child.id == "touchbarGroup_" + value) {
				  child.classList.add("selected");
			  } else {
				  child.classList.remove("selected");
			  }
			}
		}
	]])

	local context = {
		_						= _,
		touchBarGroupSelect		= touchBarGroupSelect,
		groups					= commands.groups(),
		defaultGroup			= defaultGroup,

		groupEditor				= mod.getGroupEditor,

		webviewLabel 			= mod._manager.getLabel(),
		
		maxItems				= mod._tb.maxItems,
		tb						= mod._tb,
	}

	return renderPanel(context)

end

-- touchBarPanelCallback() -> none
-- Function
-- JavaScript Callback for the Preferences Panel
--
-- Parameters:
--  * id - ID as string
--  * params - Table of paramaters
--
-- Returns:
--  * None
local function touchBarPanelCallback(id, params)	
	if params and params["type"] then
		if params["type"] == "badExtension" then
			dialog.webviewAlert(mod._manager.getWebview(), function() end, i18n("badTouchBarIcon"), i18n("pleaseTryAgain"), i18n("ok"))
		elseif params["type"] == "updateIcon" then
			mod._tb.updateIcon(params["buttonID"], params["groupID"], params["icon"])
		elseif params["type"] == "updateAction" then
			mod._tb.updateAction(params["buttonID"], params["groupID"], params["action"])
		elseif params["type"] == "updateLabel" then
			mod._tb.updateLabel(params["buttonID"], params["groupID"], params["label"])
		elseif params["type"] == "iconClicked" then			
			local result = dialog.chooseFileOrFolder(i18n("pleaseSelectAnIcon"), mod.defaultIconPath, true, false, false, mod.supportedExtensions, true)
			local failed = false
			if result and result["1"] then
				local path = string.sub(result["1"], 8)								
				local icon = image.imageFromPath(path)
				if icon then
					local encodedIcon = icon:encodeAsURLString()
					if encodedIcon then 
						mod._tb.updateIcon(params["buttonID"], params["groupID"], encodedIcon)		
						mod._manager.refresh()
					else
						failed = true
					end
				else
					failed = true					
				end
				if failed then
					dialog.webviewAlert(mod._manager.getWebview(), function() end, i18n("fileCouldNotBeRead"), i18n("pleaseTryAgain"), i18n("ok"))
				end
			end
		elseif params["type"] == "updateGroup" then			 			
			mod.lastGroup(params["groupID"])			
		else
			log.df("Unknown Callback in Touch Bar Preferences Panel:")
			log.df("id: %s", hs.inspect(id))
			log.df("params: %s", hs.inspect(params))
		end							
	end	
end

--- plugins.core.preferences.panels.touchbar.setGroupEditor(groupId, editorFn) -> none
--- Function
--- Sets the Group Editor
---
--- Parameters:
---  * groupId - Group ID
---  * editorFn - Editor Function
---
--- Returns:
---  * None
function mod.setGroupEditor(groupId, editorFn)
	if not mod._groupEditors then
		mod._groupEditors = {}
	end
	mod._groupEditors[groupId] = editorFn
end

--- plugins.core.preferences.panels.touchbar.getGroupEditor(groupId) -> none
--- Function
--- Gets the Group Editor
---
--- Parameters:
---  * groupId - Group ID
---
--- Returns:
---  * Group Editor
function mod.getGroupEditor(groupId)
	return mod._groupEditors and mod._groupEditors[groupId]
end

--- plugins.core.preferences.panels.touchbar.init(deps, env) -> module
--- Function
--- Initialise the Module.
---
--- Parameters:
---  * deps - Dependancies Table
---  * env - Environment Table
---
--- Returns:
---  * The Module
function mod.init(deps, env)

	--------------------------------------------------------------------------------
	-- Inter-plugin Connectivity:
	--------------------------------------------------------------------------------
	mod._tb				= deps.tb
	mod._manager		= deps.manager
	mod._webviewLabel	= deps.manager.getLabel()
	mod._env			= env

	--------------------------------------------------------------------------------
	-- Setup Preferences Panel:
	--------------------------------------------------------------------------------	
	mod._panel 			=  deps.manager.addPanel({
		priority 		= 2031,
		id				= "touchbar",
		label			= i18n("touchbarPanelLabel"),
		image			= image.imageFromPath(tools.iconFallback("/System/Library/PreferencePanes/TouchID.prefPane/Contents/Resources/touchid_icon.icns")),
		tooltip			= i18n("touchbarPanelTooltip"),
		height			= 550,
	})
		:addHeading(1, i18n("touchBarPreferences"))
		:addCheckbox(3,
			{
				label		= "Enable Touch Bar Support",
				checked		= mod.enabled,
				onchange	= function(id, params) mod.enabled(params.checked) end,
			}
		)	
		:addContent(10, generateContent, true)

	mod._panel:addButton(20,
		{
			label		= i18n("touchBarReset"),
			onclick		= resetTouchBar,
			class		= "resetShortcuts",
		}
	)

	--------------------------------------------------------------------------------
	-- Setup Callback Manager:
	--------------------------------------------------------------------------------
	mod._panel:addHandler("onchange", "touchBarPanelCallback", touchBarPanelCallback)

	return mod

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "core.preferences.panels.touchbar",
	group			= "core",
	dependencies	= {
		["core.preferences.manager"]		= "manager",
		["core.touchbar.manager"]			= "tb",
		["finalcutpro.action.manager"]		= "actionmanager",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)
	if deps.tb.supported() then			
		return mod.init(deps, env)
	end
end

function plugin.postInit(deps, env)

	-- TO DO: Maybe we should use Actions instead of Commands?
	--[[	
	local activator = deps.actionmanager.getActivator("touchbar")
	activator:enableAllHandlers()
	local allChoices = activator:allChoices()
	
	log.df("allChoices: %s", hs.inspect(allChoices))
	--]]
	
end

return plugin