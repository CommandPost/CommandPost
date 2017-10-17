--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--         S T R E A M    D E C K    P R E F E R E N C E S    P A N E L       --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.preferences.panels.streamdeck ===
---
--- Stream Deck Preferences Panel

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("prefsStreamDeck")

local application								= require("hs.application")
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

--- plugins.core.preferences.panels.streamdeck.supportedExtensions -> string
--- Variable
--- Table of supported extensions for Stream Deck Icons.
mod.supportedExtensions = {"jpeg", "jpg", "tiff", "gif", "png", "tif", "bmp"}

--- plugins.core.preferences.panels.streamdeck.defaultIconPath -> string
--- Variable
--- Default Path where built-in icons are stored
mod.defaultIconPath = config.assetsPath .. "/icons"

--- plugins.core.preferences.panels.streamdeck.enabled <cp.prop: boolean>
--- Field
--- Enable or disable Stream Deck Support.
mod.enabled = config.prop("enableStreamDesk", false)

--- plugins.core.preferences.panels.streamdeck.lastGroup <cp.prop: string>
--- Field
--- Last group used in the Preferences Drop Down.
mod.lastGroup = config.prop("streamDeckPreferencesLastGroup", nil)

-- resetStreamDeck() -> none
-- Function
-- Prompts to reset shortcuts to default.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function resetStreamDeck()

	dialog.webviewAlert(mod._manager.getWebview(), function(result)
		if result == i18n("yes") then
			mod._sd.clear()
			mod._manager.refresh()
		end
	end, i18n("streamDeckResetConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")

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

	local streamDeckGroupSelect = ui.select({
		id			= "streamDeckGroupSelect",
		value		= defaultGroup,
		options		= groupOptions,
		required	= true,
	}) .. ui.javascript([[
		var streamDeckGroupSelect = document.getElementById("streamDeckGroupSelect")
		streamDeckGroupSelect.onchange = function(e) {

			//
			// Change Group Callback:
			//
			try {
				var result = {
					id: "streamDeckPanelCallback",
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

			console.log("streamDeckGroupSelect changed");
			var groupControls = document.getElementById("streamDeckGroupControls");
			var value = streamDeckGroupSelect.options[streamDeckGroupSelect.selectedIndex].value;
			var children = groupControls.children;
			for (var i = 0; i < children.length; i++) {
			  var child = children[i];
			  if (child.id == "streamDeckGroup_" + value) {
				  child.classList.add("selected");
			  } else {
				  child.classList.remove("selected");
			  }
			}
		}
	]])

	local context = {
		_						= _,
		streamDeckGroupSelect	= streamDeckGroupSelect,
		groups					= commands.groups(),
		defaultGroup			= defaultGroup,

		groupEditor				= mod.getGroupEditor,

		webviewLabel 			= mod._manager.getLabel(),

		maxItems				= mod._sd.maxItems,
		sd						= mod._sd,
	}

	return renderPanel(context)

end

-- streamDeckPanelCallback() -> none
-- Function
-- JavaScript Callback for the Preferences Panel
--
-- Parameters:
--  * id - ID as string
--  * params - Table of paramaters
--
-- Returns:
--  * None
local function streamDeckPanelCallback(id, params)
	if params and params["type"] then
		if params["type"] == "badExtension" then
			--------------------------------------------------------------------------------
			-- Bad Icon File Extension:
			--------------------------------------------------------------------------------
			dialog.webviewAlert(mod._manager.getWebview(), function() end, i18n("badstreamDeckIcon"), i18n("pleaseTryAgain"), i18n("ok"))
		elseif params["type"] == "updateIcon" then
			--------------------------------------------------------------------------------
			-- Update Icon:
			--------------------------------------------------------------------------------
			mod._sd.updateIcon(params["buttonID"], params["groupID"], params["icon"])
		elseif params["type"] == "updateAction" then

			--------------------------------------------------------------------------------
			-- Restrict Allowed Handlers for Activator to current group (and global):
			--------------------------------------------------------------------------------
			local allowedHandlers = {}
			local handlerIds = mod._actionmanager.handlerIds()
			for _,id in pairs(handlerIds) do
				local handlerTable = tools.split(id, "_")
				if handlerTable[1] == params["groupID"] or handlerTable[1] == "global" then
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

					mod._sd.updateAction(params["buttonID"], params["groupID"], actionTitle, handlerID, action)
					mod._manager.refresh()
				end)

			--------------------------------------------------------------------------------
			-- Show Activator:
			--------------------------------------------------------------------------------
			mod.activator:show()
		elseif params["type"] == "clearAction" then
			mod._sd.updateAction(params["buttonID"], params["groupID"], nil, nil, nil)
			mod._manager.refresh()
		elseif params["type"] == "updateLabel" then
			--------------------------------------------------------------------------------
			-- Update Label:
			--------------------------------------------------------------------------------
			mod._sd.updateLabel(params["buttonID"], params["groupID"], params["label"])
		elseif params["type"] == "iconClicked" then
			--------------------------------------------------------------------------------
			-- Icon Clicked:
			--------------------------------------------------------------------------------
			local result = dialog.chooseFileOrFolder(i18n("pleaseSelectAnIcon"), mod.defaultIconPath, true, false, false, mod.supportedExtensions, true)
			local failed = false
			if result and result["1"] then
				local path = tools.unescape(string.sub(result["1"], 8))
				local icon = image.imageFromPath(path)
				if icon then
					local encodedIcon = icon:encodeAsURLString()
					if encodedIcon then
						mod._sd.updateIcon(params["buttonID"], params["groupID"], encodedIcon)
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
				mod._sd.updateIcon(params["buttonID"], params["groupID"], nil)
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
			log.df("Unknown Callback in Stream Deck Preferences Panel:")
			log.df("id: %s", hs.inspect(id))
			log.df("params: %s", hs.inspect(params))
		end
	end
end

--- plugins.core.preferences.panels.streamdeck.setGroupEditor(groupId, editorFn) -> none
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

--- plugins.core.preferences.panels.streamdeck.getGroupEditor(groupId) -> none
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

--- plugins.core.preferences.panels.streamdeck.init(deps, env) -> module
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
	mod._sd				= deps.sd
	mod._manager		= deps.manager
	mod._webviewLabel	= deps.manager.getLabel()
	mod._actionmanager	= deps.actionmanager
	mod._env			= env

	--------------------------------------------------------------------------------
	-- Setup Activator:
	--------------------------------------------------------------------------------
	mod.activator = deps.actionmanager.getActivator("streamdeckPreferences")
	mod.activator:enableAllHandlers()
	mod.activator:preloadChoices()

	--------------------------------------------------------------------------------
	-- Setup Preferences Panel:
	--------------------------------------------------------------------------------
	mod._panel 			=  deps.manager.addPanel({
		priority 		= 2032,
		id				= "streamdeck",
		label			= i18n("streamdeckPanelLabel"),
		image			= image.imageFromPath(tools.iconFallback(env:pathToAbsolute("images/streamdeck.icns"))),
		tooltip			= i18n("streamdeckPanelTooltip"),
		height			= 570,
	})
		:addHeading(6, i18n("streamDeck"))
		:addCheckbox(7,
			{
				label		= i18n("enableStreamDeck"),
				checked		= mod.enabled,
				onchange	= function(id, params)
					if #application.applicationsForBundleID("com.elgato.StreamDeck") == 0 then
						mod.enabled(params.checked)
					else
						dialog.webviewAlert(mod._manager.getWebview(), function() end, i18n("streamDeckAppRunning"), i18n("streamDeckAppRunningMessage"), i18n("ok"))
						mod._manager.refresh()
					end
				end,
			}
		)
		:addParagraph(8, [[<span class="tip">]] .. "<strong>" .. string.upper(i18n("tip")) .. ": </strong>" .. i18n("streamDeckAppTip") .. "</span>\n\n", true)
		:addContent(10, generateContent, true)

	mod._panel:addButton(20,
		{
			label		= i18n("streamDeckReset"),
			onclick		= resetStreamDeck,
			class		= "resetShortcuts",
		}
	)

	--------------------------------------------------------------------------------
	-- Setup Callback Manager:
	--------------------------------------------------------------------------------
	mod._panel:addHandler("onchange", "streamDeckPanelCallback", streamDeckPanelCallback)

	return mod

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "core.preferences.panels.streamdeck",
	group			= "core",
	dependencies	= {
		["core.preferences.manager"]		= "manager",
		["core.streamdeck.manager"]			= "sd",
		["core.action.manager"]				= "actionmanager",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)
	return mod.init(deps, env)
end

return plugin