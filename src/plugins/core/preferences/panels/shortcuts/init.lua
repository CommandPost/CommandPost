--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--           S H O R T C U T S    P R E F E R E N C E S    P A N E L          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === core.preferences.panels.shortcuts ===
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
local keycodes									= require("hs.keycodes")
local timer										= require("hs.timer")
local toolbar                  					= require("hs.webview.toolbar")
local webview									= require("hs.webview")

local config									= require("cp.config")
local commands									= require("cp.commands")
local dialog									= require("cp.dialog")
local generate									= require("cp.web.generate")

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

local function resetShortcuts()
	if dialog.displayYesNoQuestion(i18n("shortcutsResetConfirmation")) then
		-- Deletes the DEFAULT_SHORTCUTS, if present.
		local shortcutsFile = fs.pathToAbsolute(commands.getShortcutsPath(DEFAULT_SHORTCUTS))
		if shortcutsFile then
			log.df("Removing shortcuts file: '%s'", shortcutsFile)
			os.remove(shortcutsFile)
			dialog.displayAlertMessage(i18n("shortcutsResetComplete"))
			hs.reload()
		end
	end
end

--------------------------------------------------------------------------------
-- CONTROLLER CALLBACK:
--------------------------------------------------------------------------------
local function controllerCallback(message)

	local body = message.body
	local action = body.action

	-- log.df("Callback message: %s", hs.inspect(message))
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

--------------------------------------------------------------------------------
-- GENERATE LIST OF SHORTCUTS:
--------------------------------------------------------------------------------
function getAllKeyCodes()

	local shortcuts = {}

	for i, v in pairs(keycodes.map) do
	  if type(v) == "number" then
	  	if v <= 9 then
	  		local alreadyExists = false
	  		for x, y in pairs(shortcuts) do
	  			if shortcuts[x] == tostring(v) then
	  				alreadyExists = true
	  			end
	  		end
	  		if not alreadyExists then
		  		shortcuts[#shortcuts + 1] = tostring(v)
		  	end
	  	end
	  else
	  	shortcuts[#shortcuts + 1] = v
	  end
	end

	table.sort(shortcuts, function(a, b) return a < b end)

	return shortcuts

end

local baseModifiers = {
	{ value = "command",	label = "⌘" },
	{ value = "shift",		label = "⇧" },
	{ value = "option",		label = "⌥" },
	{ value = "control",	label = "^" },
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

local function isHacksShortcutsEnabled()
	return config.get("enableHacksShortcutsInFinalCutPro", false)
end

--------------------------------------------------------------------------------
-- GENERATE CONTENT:
--------------------------------------------------------------------------------
local function generateContent()

	local context = {
		shortcuts 				= getShortcutList(),
		modifierOptions 		= modifierOptions,
		keyCodeOptions 			= keyCodeOptions,
		checkModifier 			= checkModifier,
		webviewLabel 			= mod._manager.getLabel(),
		shortcutsEnabled		= not isHacksShortcutsEnabled(),
		generate				= generate,
	}

	return renderPanel(context)

end

--------------------------------------------------------------------------------
-- UPDATE CUSTOM SHORTCUTS SECTION:
--------------------------------------------------------------------------------
function mod.updateCustomShortcutsVisibility()

	local enableHacksShortcutsInFinalCutPro = isHacksShortcutsEnabled()

	if enableHacksShortcutsInFinalCutPro then
		mod._manager.injectScript([[
			document.getElementById("customiseShortcuts").className = "disabled";
			document.getElementById("enableCustomShortcuts").checked = true;
		]])
	else
		mod._manager.injectScript([[
			document.getElementById("customiseShortcuts").className = "";
			document.getElementById("enableCustomShortcuts").checked = false;
		]])
	end

	mod._manager.show()

end

--------------------------------------------------------------------------------
-- INITIALISE MODULE:
--------------------------------------------------------------------------------
function mod.init(deps, env)

	mod.allKeyCodes = getAllKeyCodes()

	mod._manager = deps.manager
	mod._hacksShortcuts = deps.hacksShortcuts

	mod._webviewLabel = deps.manager.getLabel()

	mod._env = env

	local id 		= "shortcuts"
	local label 	= "Shortcuts"
	local image		= image.imageFromPath("/System/Library/PreferencePanes/Keyboard.prefPane/Contents/Resources/Keyboard.icns")
	local priority	= 2030
	local tooltip	= "Shortcuts Panel"
	local contentFn	= generateContent
	local callbackFn 	= controllerCallback

	deps.manager.addPanel(id, label, image, priority, tooltip, contentFn, callbackFn)

	return mod

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