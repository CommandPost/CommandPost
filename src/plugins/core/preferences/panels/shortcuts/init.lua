--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--           S H O R T C U T S    P R E F E R E N C E S    P A N E L          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.preferences.panels.shortcuts ===
---
--- Shortcuts Preferences Panel

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
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local DEFAULT_PRIORITY 							= 0

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

mod.DEFAULT_SHORTCUTS							= "Default Shortcuts"

-- restoreDefaultShortcuts() -> boolean
-- Function
-- Restores the Default Shortcuts from the Cache.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function restoreDefaultShortcuts()

	for groupID, group in pairs(mod.defaultShortcuts) do	
		for cmdID,cmd in pairs(group) do			
			for shortcutID,shortcut in pairs(cmd) do
				local tempGroup = commands.group(groupID)
				local tempCommand = tempGroup:get(cmdID)				
				if tempCommand then
					tempCommand:deleteShortcuts()
					tempCommand:activatedBy(shortcut["modifiers"], shortcut["keycode"])
				end		
			end
		end 
	
	end

end

-- cacheShortcuts() -> boolean
-- Function
-- Caches the Default Shortcuts for use later.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function cacheShortcuts()
	
	log.df("Caching Default Shortcuts.")

	mod.defaultShortcuts = {}

	local groupIDs = commands.groupIds()
	for _, groupID in ipairs(groupIDs) do

		local group = commands.group(groupID)
		
		if not mod.defaultShortcuts[groupID] then
			mod.defaultShortcuts[groupID] = {}
		end
					
		local cmds = group:getAll()

		for cmdID,cmd in pairs(cmds) do
		
			if not mod.defaultShortcuts[groupID][cmdID] then
				mod.defaultShortcuts[groupID][cmdID] = {}
			end
			
			local shortcuts = cmd:getShortcuts()
			
			for shortcutID,shortcut in pairs(shortcuts) do
			
				local tempShortcuts = {}							
				local tempModifiers = shortcut:getModifiers()
				local tempKeycode = shortcut:getKeyCode()
				
				tempShortcuts = { 
					["modifiers"] = tempModifiers,
					["keycode"] = tempKeycode
				}
				
				mod.defaultShortcuts[groupID][cmdID][shortcutID] = tempShortcuts
			
			end			
		end
	end	
	
end

-- resetShortcutsToNone() -> none
-- Function
-- Resets all Shortcuts to None.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function resetShortcutsToNone()
	
	dialog.webviewAlert(mod._manager.getWebview(), function(result)
		if result == i18n("yes") then		
			local groupIDs = commands.groupIds()
			for _, groupID in ipairs(groupIDs) do
	  
				local group = commands.group(groupID)
				local cmds = group:getAll()

				for id,cmd in pairs(cmds) do
					cmd:deleteShortcuts()
				end
			end
	
			commands.saveToFile(mod.DEFAULT_SHORTCUTS)
	
			mod._manager.refresh()		
		end 
	end, i18n("shortcutsSetNoneConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")

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
			restoreDefaultShortcuts()
			commands.saveToFile(mod.DEFAULT_SHORTCUTS)
			mod._manager.refresh()					
		end
	end, i18n("shortcutsResetConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")

end

config.watch({
	reset = deleteShortcuts,
})

-- shortcutAlreadyInUse(modifiers, keycode) -> none
-- Function
-- Checks to see if a keyboard shortcut is already being used by CommandPost.
--
-- Parameters:
--  * modifiers - Modifier keys in a table
--  * keycode - Keycode
--
-- Returns:
--  * `true` if already in use, otherwise `false`.
local function shortcutAlreadyInUse(modifiers, keycode)
	
	local groupIDs = commands.groupIds()
	for _, groupID in ipairs(groupIDs) do

		local group = commands.group(groupID)
		local cmds = group:getAll()

		for id,cmd in pairs(cmds) do
		
			local shortcuts = cmd:getShortcuts()
			
			for _,shortcut in pairs(shortcuts) do
				local tempModifiers = shortcut:getModifiers()
				local tempKeycode = shortcut:getKeyCode()
				
				local modifierMatch = true
				if #modifiers ~= #tempModifiers then
					modifierMatch = false
				else
					for _, mod in pairs(tempModifiers) do
						if not fnutils.contains(modifiers, mod) then
							modifierMatch = false
						end
					end
				end
				
				if keycode == tempKeycode and modifierMatch then		
					return true
				end								
			end			
		end
	end
	return false
	
end

-- updateShortcut(id, params) -> none
-- Function
-- Updates a Shortcut.
--
-- Parameters:
--  * id - The ID of the shortcut
--  * params - The params of the shortcut
--
-- Returns:
--  * None
local function updateShortcut(id, params)
	
	--------------------------------------------------------------------------------
	-- Values from Callback:
	--------------------------------------------------------------------------------
	local modifiers = tools.split(params.modifiers, ":")

	--------------------------------------------------------------------------------
	-- Setup Controller:
	--------------------------------------------------------------------------------
	local group = commands.group(params.group)

	--------------------------------------------------------------------------------
	-- Get the correct Command:
	--------------------------------------------------------------------------------
	local theCommand = group:get(params.command)

	if theCommand then
	
		--------------------------------------------------------------------------------
		-- Clear Previous Shortcuts:
		--------------------------------------------------------------------------------
		theCommand:deleteShortcuts()

		--------------------------------------------------------------------------------
		-- Setup New Shortcut:
		--------------------------------------------------------------------------------
		if params.keyCode and params.keyCode ~= "" and params.keyCode ~= "none" and params.modifiers and params.modifiers ~= "none" then
									
			--------------------------------------------------------------------------------
			-- Check to see that the shortcut isn't already being used already by macOS:
			--------------------------------------------------------------------------------
			local assignable = hotkey.assignable(modifiers, params.keyCode)
			local systemAssigned = hotkey.systemAssigned(modifiers, params.keyCode)
			if assignable and not systemAssigned then 			
				--------------------------------------------------------------------------------
				-- Check to see that the shortcut isn't already being used by CommandPost:
				--------------------------------------------------------------------------------
				if shortcutAlreadyInUse(modifiers, params.keyCode) then 	
					dialog.webviewAlert(mod._manager.getWebview(), function() end, i18n("shortcutAlreadyInUse"), i18n("shortcutDuplicateError") .. "\n\n" .. i18n("shortcutPleaseTryAgain"), i18n("continue"), "", "informational")					
				else
					theCommand:activatedBy(modifiers, params.keyCode)
				end
			else
				dialog.webviewAlert(mod._manager.getWebview(), function() end, i18n("shortcutAlreadyInUseByMacOS"), i18n("shortcutPleaseTryAgain"), i18n("continue"), "", "informational")
			end
						
		end

		--------------------------------------------------------------------------------
		-- Save to file:
		--------------------------------------------------------------------------------
		commands.saveToFile(mod.DEFAULT_SHORTCUTS)
	else
		log.wf("Unable to find command to update: %s:%s", params.group, params.command)
	end

end

-- getAllKeyCodes() -> none
-- Function
-- Generate a table of all shortcut keys available.
--
-- Parameters:
--  * None
--
-- Returns:
--  * Table
function getAllKeyCodes()

	--------------------------------------------------------------------------------
	-- TODO: Work out a way to ONLY display keyboard shortcuts that the system
	--       actually has on it's keyboard.
	--
	--       See: https://github.com/Hammerspoon/hammerspoon/issues/1307
	--------------------------------------------------------------------------------
	local shortcuts = {}

	for k,_ in pairs(keycodes.map) do
		if type(k) == "string" and k ~= "" then
			shortcuts[#shortcuts + 1] = k
		end
	end
	
	table.sort(shortcuts, function(a, b) return a < b end)

	return shortcuts

end

local baseModifiers = {
	{ value = "command",	label = "⌘" },
	{ value = "shift",		label = "⇧" },
	{ value = "option",		label = "⌥" },
	{ value = "control",	label = "⌃" },
}

function _.combinations(list)
	if _.isEmpty(list) then
		return {}
	end
	-- work with a copy of the list
	list = _.clone(list)
	local first = _.pop(list)
	local result = _({{first}})
	if not _.isEmpty(list) then
		-- get all combinations of the remainder of the list
		local combos = _.combinations(list)
		result = result:append(_.map(combos, function(i,v) return _.append({first}, v) end))
		-- add the sub-combos at the end
		result = result:append(combos)
	end
	return result:value()
end

function _.reduceCombinations(list, f, state)
	return _.map(_.combinations(list), function(i,v) return _.reduce(v, f, state) end)
end

local function iterateModifiers(list)
	return _.reduceCombinations(list, function(memo, v)
		return { value = v.value .. ":" .. memo.value, label = v.label .. memo.label}
	end)
end

local allModifiers = iterateModifiers(baseModifiers)

local function modifierOptions(shortcut)
	local out = ""
	for i,modifiers in ipairs(allModifiers) do
		local selected = shortcut and _.same(shortcut:getModifiers(), tools.split(modifiers.value, ":")) and " selected" or ""
		out = out .. ([[<option value="%s"%s>%s</option>]]):format(modifiers.value, selected, modifiers.label)
	end
	return out
end

local function keyCodeOptions(shortcut)
	local keyCodeOptions = ""
	local keyCode = shortcut and shortcut:getKeyCode()
	for _,kc in ipairs(mod.allKeyCodes) do
		local selected = keyCode == kc and " selected" or ""
		keyCodeOptions = keyCodeOptions .. ("<option%s>%s</option>"):format(selected, kc)
	end
	return keyCodeOptions
end

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

	local groupSelect = ui.select({
		id			= "shortcutsGroupSelect",
		value		= defaultGroup,
		options		= groupOptions,
		required	= true,
	}) .. ui.javascript([[
		var groupSelect = document.getElementById("shortcutsGroupSelect")
		groupSelect.onchange = function() {
			console.log("shortcutsGroupSelect changed");
			var groupControls = document.getElementById("shortcutsGroupControls");
			var value = groupSelect.options[groupSelect.selectedIndex].value;
			var children = groupControls.children;
			for (var i = 0; i < children.length; i++) {
			  var child = children[i];
			  if (child.id == "shortcutsGroup_" + value) {
				  child.classList.add("selected");
			  } else {
				  child.classList.remove("selected");
			  }
			}
		}
	]])

	local context = {
		_						= _,
		groupSelect				= groupSelect,
		groups					= commands.groups(),
		defaultGroup			= defaultGroup,

		groupEditor				= mod.getGroupEditor,
		modifierOptions 		= modifierOptions,
		keyCodeOptions 			= keyCodeOptions,
		checkModifier 			= checkModifier,

		webviewLabel 			= mod._manager.getLabel(),
	}

	return renderPanel(context)

end

--- plugins.core.preferences.panels.shortcuts.init(deps, env) -> module
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
		priority 		= 2030,
		id				= "shortcuts",
		label			= i18n("shortcutsPanelLabel"),
		image			= image.imageFromPath(tools.iconFallback("/System/Library/PreferencePanes/Keyboard.prefPane/Contents/Resources/Keyboard.icns")),
		tooltip			= i18n("shortcutsPanelTooltip"),
		height			= 490,
	})

	mod._panel:addContent(10, generateContent, true)

	local shortcutsEnabledClass  = ""
	if shortcutsEnabled then shortcutsEnabledClass = "  buttonDisabled" end

	mod._panel:addButton(20,
		{
			label		= i18n("resetShortcuts"),
			onclick		= resetShortcuts,
			class		= "resetShortcuts" .. shortcutsEnabledClass,
		}
	)

	mod._panel:addButton(21,
		{
			label		= i18n("resetShortcutsAllToNone"),
			onclick		= resetShortcutsToNone,
			class		= "resetShortcutsToNone" .. shortcutsEnabledClass,
		}
	)

	mod._panel:addHandler("onchange", "updateShortcut", updateShortcut)

	return mod

end

--- plugins.core.preferences.panels.shortcuts.setGroupEditor(groupId, editorFn) -> none
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

--- plugins.core.preferences.panels.shortcuts.getGroupEditor(groupId) -> none
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
	id				= "core.preferences.panels.shortcuts",
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

	--------------------------------------------------------------------------------
	-- Cache all the default shortcuts:
	--------------------------------------------------------------------------------	
	cacheShortcuts()
	
	--------------------------------------------------------------------------------
	-- Load Shortcuts From File:
	--------------------------------------------------------------------------------
	local result = commands.loadFromFile(mod.DEFAULT_SHORTCUTS)
	
	--------------------------------------------------------------------------------
	-- If no Default Shortcut File Exists, lets create one:
	--------------------------------------------------------------------------------
	if not result then
		local filePath = commands.getShortcutsPath(mod.DEFAULT_SHORTCUTS)
		log.df("Creating new shortcut file: '%s'", filePath)
		commands.saveToFile(mod.DEFAULT_SHORTCUTS)
	end
	
end

return plugin