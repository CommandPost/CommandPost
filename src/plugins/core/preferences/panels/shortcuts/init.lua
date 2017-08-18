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

local fs										= require("hs.fs")
local image										= require("hs.image")
local inspect									= require("hs.inspect")
local keycodes									= require("hs.keycodes")
local timer										= require("hs.timer")
local toolbar                  					= require("hs.webview.toolbar")
local webview									= require("hs.webview")

local commands									= require("cp.commands")
local config									= require("cp.config")
local dialog									= require("cp.dialog")
local fcp										= require("cp.apple.finalcutpro")
local html										= require("cp.web.html")
local ui										= require("cp.web.ui")
local plist										= require("cp.plist")
local tools										= require("cp.tools")

local _											= require("moses")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local DEFAULT_PRIORITY 							= 0
local DEFAULT_SHORTCUTS							= "Default Shortcuts"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--------------------------------------------------------------------------------
-- SPLIT STRING:
--------------------------------------------------------------------------------
local function split(str, pat)
	local t = {}  -- NOTE: use {n = 0} in Lua-5.0
	local fpat = "(.-)" .. pat
	local last_end = 1
	local s, e, cap = str:find(fpat, 1)
	while s do
	  if s ~= 1 or cap ~= "" then
		 table.insert(t,cap)
	  end
	  last_end = e+1
	  s, e, cap = str:find(fpat, last_end)
	end
	if last_end <= #str then
	  cap = str:sub(last_end)
	  table.insert(t, cap)
	end
	return t
end

local function deleteShortcuts()
	-- Deletes the DEFAULT_SHORTCUTS, if present.
	local shortcutsFile = fs.pathToAbsolute(commands.getShortcutsPath(DEFAULT_SHORTCUTS))
	if shortcutsFile then
		local ok, err = os.remove(shortcutsFile)
		if not ok then
			log.ef("Unable to remove default shortcuts: %s", err)
			return false
		end
	end
	return true
end

local function resetShortcuts()
	if dialog.displayYesNoQuestion(i18n("shortcutsResetConfirmation")) then
		if deleteShortcuts() then
			dialog.displayMessage(i18n("shortcutsResetComplete"), {"OK"})
			hs.reload()
		end
	end
end

config.watch({
	reset = deleteShortcuts,
})

--------------------------------------------------------------------------------
-- CONTROLLER CALLBACK:
--------------------------------------------------------------------------------
local function controllerCallback(message)

	local body = message.body
	local action = body.action

	-- log.df("Callback message: %s", hs.inspect(message))

	-- TODO: Can this whole updateShortcut action be removed??

	if action == "updateShortcut" then
		--------------------------------------------------------------------------------
		-- Values from Callback:
		--------------------------------------------------------------------------------
		local modifiers = split(body.modifiers, ":")

		--------------------------------------------------------------------------------
		-- Setup Controller:
		--------------------------------------------------------------------------------
		local group = commands.group(body.group)

		--------------------------------------------------------------------------------
		-- Get the correct Command:
		--------------------------------------------------------------------------------
		local theCommand = group:get(body.command)

		if theCommand then
			--------------------------------------------------------------------------------
			-- Clear Previous Shortcuts:
			--------------------------------------------------------------------------------
			theCommand:deleteShortcuts()

			--------------------------------------------------------------------------------
			-- Setup New Shortcut:
			--------------------------------------------------------------------------------
			if body.keyCode and body.keyCode ~= "" then
				theCommand:activatedBy(modifiers, body.keyCode)
			end

			commands.saveToFile(DEFAULT_SHORTCUTS)
		else
			log.wf("Unable to find command to update: %s:%s", group, command)
		end
	elseif body[1] == "resetShortcuts" then
		resetShortcuts()
	end
end

local function updateShortcut(id, params)

	--------------------------------------------------------------------------------
	-- Values from Callback:
	--------------------------------------------------------------------------------
	local modifiers = split(params.modifiers, ":")

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
		if params.keyCode and params.keyCode ~= "" then
			theCommand:activatedBy(modifiers, params.keyCode)
		end

		--------------------------------------------------------------------------------
		--
		-- TODO: Check that the shortcut was actually added and alert user if not.
		--
		--------------------------------------------------------------------------------

		commands.saveToFile(DEFAULT_SHORTCUTS)
	else
		log.wf("Unable to find command to update: %s:%s", params.group, params.command)
	end

end

--------------------------------------------------------------------------------
-- GENERATE LIST OF SHORTCUTS:
--------------------------------------------------------------------------------
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
		local selected = shortcut and _.same(shortcut:getModifiers(), split(modifiers.value, ":")) and " selected" or ""
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

	-- the group select
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

--------------------------------------------------------------------------------
-- INITIALISE MODULE:
--------------------------------------------------------------------------------
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

	mod._panel:addHandler("onchange", "updateShortcut", updateShortcut)

	return mod

end

function mod.setGroupEditor(groupId, editorFn)
	if not mod._groupEditors then
		mod._groupEditors = {}
	end
	mod._groupEditors[groupId] = editorFn
end

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
	commands.loadFromFile(DEFAULT_SHORTCUTS)
end

return plugin