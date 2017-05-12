--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                  W A T C H   F O L D E R    M A N A G E R                  --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.watchfolders.manager ===
---
--- Manager for the CommandPost Watch Folders Panel.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("watchMan")

local screen									= require("hs.screen")
local timer										= require("hs.timer")
local toolbar                  					= require("hs.webview.toolbar")
local webview									= require("hs.webview")

local dialog									= require("cp.dialog")
local config									= require("cp.config")

local panel										= require("panel")

local _											= require("moses")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY 									= 8888889
local WEBVIEW_LABEL								= "watchfolders"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

mod._panels				= {}
mod._handlers			= {}

--- plugins.core.watchfolders.manager.position <cp.prop: table>
--- Constant
--- Returns the last frame saved in settings.
mod.position = config.prop("watchFoldersPosition", {})

--- plugins.core.watchfolders.manager.position <cp.prop: table>
--- Constant
--- Returns the last frame saved in settings.
mod.lastTab = config.prop("watchFoldersLastTab", nil)

--------------------------------------------------------------------------------
-- SETTINGS:
--------------------------------------------------------------------------------
mod.defaultWindowStyle	= {"titled", "closable", "nonactivating"}
mod.defaultWidth 		= 524
mod.defaultHeight 		= 338
mod.defaultTitle 		= i18n("watchFolders")

--------------------------------------------------------------------------------
-- GET LABEL:
--------------------------------------------------------------------------------
function mod.getLabel()
	return WEBVIEW_LABEL
end

function mod.addHandler(id, handlerFn)
	mod._handlers[id] = handlerFn
end

function mod.getHandler(id)
	return mod._handlers[id]
end

function mod.setPanelRenderer(renderer)
	mod._panelRenderer = renderer
end

-- isPanelIDValid() -> boolean
-- Function
-- Is Panel ID Valid?
--
-- Parameters:
--  * None
--
-- Returns:
--  * Boolean
local function isPanelIDValid(whichID)
	for i, v in ipairs(mod._panels) do
		if v.id == whichID then
			return true
		end
	end
	return false
end

--------------------------------------------------------------------------------
-- HIGHEST PRIORITY ID:
--------------------------------------------------------------------------------
local function highestPriorityID()
	if mod.lastTab() and isPanelIDValid(mod.lastTab()) then
		return mod.lastTab()
	else
		local sortedPanels = mod._panels
		return #mod._panels > 0 and mod._panels[1].id or nil
	end
end

--------------------------------------------------------------------------------
-- GENERATE HTML:
--------------------------------------------------------------------------------
local function generateHTML()
	local env = {}

	env.debugMode = config.developerMode()
	env.panels = mod._panels
	env.highestPriorityID = highestPriorityID()

	local result, err = mod._panelRenderer(env)
	if err then
		log.ef("Error rendering Preferences Panel Template: %s", err)
		return err
	else
		return result
	end
end

--------------------------------------------------------------------------------
-- WEBVIEW WINDOW CALLBACK:
--------------------------------------------------------------------------------
local function windowCallback(action, webview, frame)
	if action == "closing" then
		if not hs.shuttingDown then
			mod.webview = nil
		end
	elseif action == "focusChange" then
		if frame then
			local id = mod.toolbar:selectedItem()
			for i, v in ipairs(mod._panels) do
				if v.id == id then
					--log.df("Executing Load Function via manager.windowCallback.")
					v.loadFn()
				end
			end
		end
	elseif action == "frameChange" then
		if frame then
			mod.position(frame)
		end
	end
end

--- plugins.core.watchfolders.manager.init() -> nothing
--- Function
--- Initialises the preferences panel.
---
--- Parameters:
--- * None
---
--- Returns:
--- * Nothing
function mod.init()

	--------------------------------------------------------------------------------
	-- Use last Position or Centre on Screen:
	--------------------------------------------------------------------------------
	local screenFrame = screen.mainScreen():frame()
	local defaultRect = {x = (screenFrame.w/2) - (mod.defaultWidth/2), y = (screenFrame.h/2) - (mod.defaultHeight/2), w = mod.defaultWidth, h = mod.defaultHeight}
	if mod.position() then
		defaultRect = mod.position()
	end

	--------------------------------------------------------------------------------
	-- Setup Web View Controller:
	--------------------------------------------------------------------------------
	mod.controller = webview.usercontent.new(WEBVIEW_LABEL)
		:setCallback(function(message)
			--log.df("webview callback called: %s", hs.inspect(message))
			local body = message.body
			local id = body.id
			local params = body.params
			local handler = mod.getHandler(id)
			if handler then
				return handler(id, params)
			end
		end)

	--------------------------------------------------------------------------------
	-- Setup Tool Bar:
	--------------------------------------------------------------------------------
	if not mod.toolbar then
		mod.toolbar = toolbar.new(WEBVIEW_LABEL)
			:canCustomize(true)
			:autosaves(true)
			:setCallback(function(toolbar, webview, id)
				mod.selectPanel(id)
			end)
	end

	--------------------------------------------------------------------------------
	-- Setup Web View:
	--------------------------------------------------------------------------------
	local prefs = {}
	if config.developerMode() then prefs = {developerExtrasEnabled = true} end
	mod.webview = webview.new(defaultRect, prefs, mod.controller)
		:windowStyle(mod.defaultWindowStyle)
		:shadow(true)
		:allowNewWindows(false)
		:allowTextEntry(true)
		:windowTitle(mod.defaultTitle)
		:attachedToolbar(mod.toolbar)
		:deleteOnClose(true)
		:windowCallback(windowCallback)

	return mod
end

--- plugins.core.watchfolders.manager.showPreferences() -> boolean
--- Function
--- Shows the Preferences Window
---
--- Parameters:
---  * None
---
--- Returns:
---  * True if successful or nil if an error occurred
function mod.show()
	if mod.webview == nil then
		mod.init()
	end
	if next(mod._panels) == nil then
		dialog.displayMessage("There are no Preferences Panels to display.")
		return nil
	else
		mod.webview:html(generateHTML())
		mod.webview:show()
		timer.doAfter(0.1, function()
			--log.df("Attempting to bring Preferences Panel to focus.")
			mod.webview:hswindow():raise():focus()
		end)
	end

	--------------------------------------------------------------------------------
	-- Select Panel:
	--------------------------------------------------------------------------------
	mod.selectPanel(highestPriorityID())

	return true
end

function mod.hide()
	if mod.webview then
		mod.webview:delete()
		mod.webview = nil
	end
end

--------------------------------------------------------------------------------
-- INJECT SCRIPT
--------------------------------------------------------------------------------
function mod.injectScript(script)
	if mod.webview and mod.webview:frame() then
		mod.webview:evaluateJavaScript(script,
		function(result, theerror)
			if theerror then
				--log.df("Javascript Error: %s", hs.inspect(theerror))
			end
		end)
	end
end

--------------------------------------------------------------------------------
-- SELECT PANEL:
--------------------------------------------------------------------------------
function mod.selectPanel(id)

	if not mod.webview then
		return
	end

	local js = ""

	local loadFn = nil
	for i, v in ipairs(mod._panels) do

		--------------------------------------------------------------------------------
		-- Load Function for Panel:
		--------------------------------------------------------------------------------
		if v.id == id and v.loadFn then
			loadFn = v.loadFn
		end

		--------------------------------------------------------------------------------
		-- Resize Panel:
		--------------------------------------------------------------------------------
		if v.id == id and v.height and type(v.height) == "number" and mod.webview:hswindow() and mod.webview:hswindow():isVisible() then
			mod.webview:size({w = mod.defaultWidth, h = v.height })
		end

		local style = v.id == id and "block" or "none"
		js = js .. [[
			document.getElementById(']] .. v.id .. [[').style.display = ']] .. style .. [[';
		]]
	end

	mod.injectScript(js)

	mod.toolbar:selectedItem(id)

	if loadFn then
		--log.df("Executing Load Function via manager.selectPanel.")
		loadFn()
	end

	--------------------------------------------------------------------------------
	-- Save Last Tab in Settings:
	--------------------------------------------------------------------------------
	mod.lastTab(id)

end

local function comparePriorities(a, b)
	return a.priority < b.priority
end

--- plugins.core.watchfolders.manager.addPanel(params) -> plugins.core.watchfolders.manager.panel
--- Function
--- Adds a new panel with the specified `params` to the preferences manager.
---
--- Parameters:
---  * `params`	- The parameters table. Details below.
---
--- Returns:
---  * The new `panel` instance.
---
--- Notes:
---  * The `params` can have the following properties. The `priority` and `id` and properties are **required**.
---  ** `priority`		- An integer value specifying the priority of the panel compared to others.
---  ** `id`			- A string containing the unique ID of the panel.
---  ** `label`			- The human-readable label for the panel icon.
---	 ** `image`			- The `hs.image` for the panel icon.
---  ** `tooltip`		- The human-readable details for the toolbar icon when the mouse is hovering over it.
function mod.addPanel(params)

	--log.df("Adding Preferences Panel with ID: %s", id)
	local newPanel = panel.new(params, mod)

	local index = _.sortedIndex(mod._panels, newPanel, comparePriorities)
	table.insert(mod._panels, index, newPanel)

	if mod.toolbar then
		local toolbar = mod.toolbar
		local item = newPanel:getToolbarItem()

		toolbar:addItems(item)
		toolbar:insertItem(item.id, index)
		if not toolbar:selectedItem() then
			toolbar:selectedItem(item.id)
		end
	end

	return newPanel
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "core.watchfolders.manager",
	group			= "core",
	required		= true,
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)

	mod.setPanelRenderer(env:compileTemplate("html/panels.html"))

	return mod.init()
end

return plugin