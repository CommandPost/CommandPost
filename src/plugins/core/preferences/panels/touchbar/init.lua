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
local log										= require("hs.logger").new("prefsShortcuts")

local dialog									= require("hs.dialog")
local fnutils									= require("hs.fnutils")
local fs										= require("hs.fs")
local hotkey									= require("hs.hotkey")
local image										= require("hs.image")
local inspect									= require("hs.inspect")
local keycodes									= require("hs.keycodes")
local timer										= require("hs.timer")
local toolbar                  					= require("hs.webview.toolbar")
local webview									= require("hs.webview")

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

--- plugins.core.preferences.panels.touchbar.maxItems
--- Constant
--- The maximum number of Touch Bar items per group.
mod.maxItems = 8

--- plugins.core.preferences.panels.touchbar.enabled <cp.prop: boolean>
--- Field
--- Enable or disable Touch Bar Support.
mod.enabled = config.prop("enableTouchBar", false)

local function getShortcutList()
	local shortcuts = {}
	for _,groupId in ipairs(commands.groupIds()) do
		local group = commands.group(groupId)
		local cmds = group:getAll()
		for id,cmd in pairs(cmds) do
			-- log.df("Processing command: %s", id)
			local cmdShortcuts = cmd:getShortcuts()
			if cmdShortcuts and #cmdShortcuts > 0 then
				for i,shortcut in ipairs(cmd:getShortcuts()) do
					shortcuts[#shortcuts+1] = {
						groupId = groupId,
						command = cmd,
						shortcutIndex = i,
						shortcut = shortcut,
						shortcutId = ("%s_%s"):format(id, i),
					}
				end
			else
				shortcuts[#shortcuts+1] = {
					groupId = groupId,
					command = cmd,
					shortcutIndex = 1,
					shortcutId = ("%s_%s"):format(id, 1),
				}

			end
		end
	end
	table.sort(shortcuts, function(a, b)
		return a.groupId < b.groupId
			or a.groupId == b.groupId and a.command:getTitle() < b.command:getTitle()
	end)

	return shortcuts
end

-- resetShortcuts() -> none
-- Function
-- Prompts to reset shortcuts to default.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function resetShortcuts()

	dialog.webviewAlert(mod._manager.getWebview(), function(result) 
		if result == i18n("yes") then
			mod._manager.refresh()					
		end
	end, i18n("shortcutsResetConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")

end

config.watch({
	reset = deleteShortcuts,
})

local function renderRows(context)
	if not mod._renderRows then
		mod._renderRows, err = mod._env:compileTemplate("html/rows.html")
		if err then
			error(err)
		end
	end
	return mod._renderRows(context)
end

local function renderPanel(context)
	if not mod._renderPanel then
		mod._renderPanel, err = mod._env:compileTemplate("html/panel.html")
		if err then
			error(err)
		end
	end
	return mod._renderPanel(context)
end

--------------------------------------------------------------------------------
-- GENERATE CONTENT:
--------------------------------------------------------------------------------
local function generateContent()

	--------------------------------------------------------------------------------	
	-- The Group Select:
	--------------------------------------------------------------------------------
	local groupOptions = {}
	local defaultGroup = nil
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
		touchBarGroupSelect.onchange = function() {
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
		
		maxItems				= mod.maxItems
	}

	return renderPanel(context)

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

	mod.allKeyCodes		= getAllKeyCodes()

	mod._manager		= deps.manager

	mod._webviewLabel	= deps.manager.getLabel()

	mod._env			= env

	mod._panel 			=  deps.manager.addPanel({
		priority 		= 2031,
		id				= "touchbar",
		label			= i18n("touchbarPanelLabel"),
		image			= image.imageFromPath(tools.iconFallback("/System/Library/PreferencePanes/Trackpad.prefPane/Contents/Resources/Trackpad.icns")),
		tooltip			= i18n("touchbarPanelTooltip"),
		height			= 550,
	})

	mod._panel
		:addHeading(1, i18n("touchBarPreferences"))
		:addCheckbox(3,
			{
				label		= "Enable Touch Bar Support",
				checked		= mod.enabled,
				onchange	= function(id, params) mod.enabled(params.checked) end,
			}
		)	
		:addContent(10, generateContent, true)

	local shortcutsEnabledClass  = ""
	if shortcutsEnabled then shortcutsEnabledClass = "  buttonDisabled" end

	mod._panel:addButton(20,
		{
			label		= i18n("touchBarReset"),
			onclick		= resetShortcuts,
			class		= "resetShortcuts" .. shortcutsEnabledClass,
		}
	)

	mod._panel:addHandler("onchange", "updateShortcut", updateShortcut)

	return mod

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
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "core.preferences.panels.touchbar",
	group			= "core",
	dependencies	= {
		["core.preferences.manager"]		= "manager",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)
	return mod.init(deps, env)
end

function plugin.postInit(deps)

end

return plugin