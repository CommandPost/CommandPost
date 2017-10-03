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
			--------------------------------------------------------------------------------
			-- Bad Icon File Extension:
			--------------------------------------------------------------------------------
			dialog.webviewAlert(mod._manager.getWebview(), function() end, i18n("badTouchBarIcon"), i18n("pleaseTryAgain"), i18n("ok"))
		elseif params["type"] == "updateIcon" then
			--------------------------------------------------------------------------------
			-- Update Icon:
			--------------------------------------------------------------------------------
			mod._tb.updateIcon(params["buttonID"], params["groupID"], params["icon"])
		elseif params["type"] == "updateAction" then				
			
			--------------------------------------------------------------------------------
			-- Restrict Allowed Handlers for Activator to current group:
			--------------------------------------------------------------------------------
			local allowedHandlers = {}			
			local handlerIds = mod._actionmanager.handlerIds()			
			for _,id in pairs(handlerIds) do				
				local handlerTable = tools.split(id, "_")
				if handlerTable[1] == params["groupID"] then
					table.insert(allowedHandlers, id)
				end										
			end					
			mod.activator:allowHandlers(table.unpack(allowedHandlers))
			
			--------------------------------------------------------------------------------
			-- Setup Activator Callback:
			--------------------------------------------------------------------------------
			mod.activator:onActivate(function(handler, action, text)										
					local actionTitle = text													
					local handlerID = handler:id()
					
					mod._tb.updateAction(params["buttonID"], params["groupID"], actionTitle, handlerID, action)	
					mod._manager.refresh()				
				end)
				
			--------------------------------------------------------------------------------
			-- Show Activator:
			--------------------------------------------------------------------------------	
			mod.activator:show()			
			
		elseif params["type"] == "updateLabel" then
			--------------------------------------------------------------------------------
			-- Update Label:
			--------------------------------------------------------------------------------
			mod._tb.updateLabel(params["buttonID"], params["groupID"], params["label"])
		elseif params["type"] == "iconClicked" then			
			--------------------------------------------------------------------------------
			-- Icon Clicked:
			--------------------------------------------------------------------------------
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
			else
				--------------------------------------------------------------------------------
				-- Clear Icon:
				--------------------------------------------------------------------------------
				mod._tb.updateIcon(params["buttonID"], params["groupID"], nil)
				mod._manager.refresh()			
			end
		elseif params["type"] == "updateGroup" then			 			
			--------------------------------------------------------------------------------
			-- Update Group:
			--------------------------------------------------------------------------------
			mod.lastGroup(params["groupID"])			
		else
			--------------------------------------------------------------------------------
			-- Unknown Callback:
			--------------------------------------------------------------------------------
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

--------------------------------------------------------------------------------
--
-- VIRTUAL TOUCH BAR:
-- 
--------------------------------------------------------------------------------

mod.virtual = {}

--- plugins.finalcutpro.touchbar.virtual.enabled <cp.prop: boolean>
--- Field
--- Is `true` if the plugin is enabled.
mod.virtual.enabled = config.prop("displayVirtualTouchBar", false):watch(function(enabled)
	--------------------------------------------------------------------------------
	-- Check for compatibility:
	--------------------------------------------------------------------------------
	if enabled and not mod._tb.supported() then
		dialog.displayMessage(i18n("touchBarError"))
		mod.enabled(false)
	end
	if enabled then
		mod._tb.virtual.start()
	else
		mod._tb.virtual.stop()
	end
end)

--- plugins.finalcutpro.touchbar.virtual.VISIBILITY_ALWAYS -> string
--- Constant
--- Virtual Touch Bar is Always Visible
mod.virtual.VISIBILITY_ALWAYS		= "Always"

--- plugins.finalcutpro.touchbar.virtual.VISIBILITY_FCP -> string
--- Constant
--- Virtual Touch Bar is only visible when Final Cut Pro is active.
mod.virtual.VISIBILITY_FCP			= "Final Cut Pro"

--- plugins.finalcutpro.touchbar.virtual.VISIBILITY_DEFAULT -> string
--- Constant
--- The default visibility.
mod.virtual.VISIBILITY_DEFAULT		= mod.virtual.VISIBILITY_FCP

--- plugins.finalcutpro.touchbar.virtual.LOCATION_TIMELINE -> string
--- Constant
--- Virtual Touch Bar is displayed in the top centre of the Final Cut Pro timeline
mod.virtual.LOCATION_TIMELINE		= "TimelineTopCentre"

--- plugins.finalcutpro.touchbar.virtual.visibility <cp.prop: string>
--- Field
--- When should the Virtual Touch Bar be visible?
mod.virtual.visibility = config.prop("virtualTouchBarVisibility", mod.virtual.VISIBILITY_DEFAULT):watch(function(enabled)
	if mod.visibility() == VISIBILITY_ALWAYS then 
		mod._tb.virtual.show()
	else
		if fcp.isFrontmost() then 
			mod._tb.virtual.show()
		else
			mod._tb.virtual.hide()
		end
	end
end)

-- visibilityOptions() -> none
-- Function
-- Generates a list of visibilities for the Preferences dropdown
--
-- Parameters:
--  * None
--
-- Returns:
--  * A table of visibilities
function visibilityOptions()
 	local visibilityOptions = {}
	visibilityOptions[#visibilityOptions + 1] = {
		label = i18n("always"),
		value = mod.VISIBILITY_ALWAYS,
	}
	visibilityOptions[#visibilityOptions + 1] = {
		label = i18n("finalCutPro"),
		value = mod.VISIBILITY_FCP,
	} 
	return visibilityOptions
end

-- visibilityOptions() -> none
-- Function
-- Generates a list of visibilities for the Preferences dropdown
--
-- Parameters:
--  * None
--
-- Returns:
--  * A table of visibilities
function locationOptions()
	local locationOptions = {}
	locationOptions[#locationOptions + 1] = {
		label = i18n("topCentreOfTimeline"),
		value = mod.virtual.LOCATION_TIMELINE,
	}
	locationOptions[#locationOptions + 1] = {
		label = i18n("mouseLocation"),
		value = deps.tb.virtual.LOCATION_MOUSE,
	}
	locationOptions[#locationOptions + 1] = {
		label = i18n("draggable"),
		value = deps.tb.virtual.LOCATION_DRAGGABLE,
	} 	
	return locationOptions
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
	mod._actionmanager	= deps.actionmanager
	mod._env			= env

	--------------------------------------------------------------------------------
	-- Setup Activator:
	--------------------------------------------------------------------------------
	mod.activator = deps.actionmanager.getActivator("touchbarPreferences")		
	mod.activator:enableAllHandlers()
	mod.activator:preloadChoices()
	
	--------------------------------------------------------------------------------
	-- Visibility Options:
	--------------------------------------------------------------------------------


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
				label		= i18n("enableCustomisedTouchBar"),
				checked		= mod.enabled,
				onchange	= function(id, params) mod.enabled(params.checked) end,
			}
		)	
		:addCheckbox(4,
			{
				label		= i18n("enableVirtualTouchBar"),
				checked		= mod.virtual.enabled,
				onchange	= function(id, params) mod.virtual.enabled(params.checked) end,
			}
		)					
		:addSelect(5,
			{
				label		= i18n("visibility"),
				value		= mod.virtual.visibility(),
				options		= visibilityOptions,
				required	= true,
			}
		)
		:addSelect(6,
			{
				label		= i18n("location"),
				value		= mod._tb.virtual.location(),
				options		= locationOptions,
				required	= true,
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
		["core.action.manager"]				= "actionmanager",
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

return plugin