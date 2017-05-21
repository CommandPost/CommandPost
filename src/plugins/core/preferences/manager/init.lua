--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                     P R E F E R E N C E S   M A N A G E R                  --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.preferences.manager ===
---
--- Manager for the CommandPost Preferences Panel.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("prefsMgr")

local geometry									= require("hs.geometry")
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
local WEBVIEW_LABEL								= "preferences"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

mod._panels				= {}
mod._handlers			= {}

--- plugins.core.preferences.manager.position
--- Constant
--- Returns the last frame saved in settings.
mod.position = config.prop("preferencesPosition", nil)

--- plugins.core.preferences.manager.lastTab
--- Constant
--- Returns the last tab saved in settings.
mod.lastTab = config.prop("preferencesLastTab", nil)

--------------------------------------------------------------------------------
-- SETTINGS:
--------------------------------------------------------------------------------
mod.defaultWindowStyle	= {"titled", "closable", "nonactivating"}
mod.defaultWidth 		= 524
mod.defaultHeight 		= 338
mod.defaultTitle 		= i18n("preferences")

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
local function currentPanelID()
	local id = mod.lastTab()
	if id and isPanelIDValid(id) then
		return id
	else
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
	env.currentPanelID = currentPanelID()

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
	elseif action == "frameChange" then
		if frame then
			mod.position(frame)
		end
	end
end

--- plugins.core.preferences.manager.init() -> nothing
--- Function
--- Initialises the preferences panel.
---
--- Parameters:
--- * None
---
--- Returns:
--- * Nothing
function mod.init(env)
	mod.setPanelRenderer(env:compileTemplate("html/panels.html"))

	return mod
end

--- plugins.core.preferences.manager.maxPanelHeight() -> number
--- Function
--- Returns the maximum size defined by a panel.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The maximum panel height.
function mod.maxPanelHeight()
	local max = mod.defaultHeight
	for _,panel in ipairs(mod._panels) do
		max = panel.height ~= nil and panel.height < max and max or panel.height
	end
	return max
end

local function centredPosition()
	local sf = screen.mainScreen():frame()
	return {x = sf.x + (sf.w/2) - (mod.defaultWidth/2), y = sf.y + (sf.h/2) - (mod.maxPanelHeight()/2), w = mod.defaultWidth, h = mod.defaultHeight}
end

local function isOffScreen(rect)
	if rect then
		-- check all the screens
		rect = geometry.new(rect)
		for _,screen in ipairs(screen.allScreens()) do
			if rect:inside(screen:frame()) then
				return false
			end
		end
		return true
	else
		return true
	end
end

function mod.new()

	--------------------------------------------------------------------------------
	-- Use last Position or Centre on Screen:
	--------------------------------------------------------------------------------
	local defaultRect = mod.position()
	if isOffScreen(defaultRect) then
		defaultRect = centredPosition()
	end

	--------------------------------------------------------------------------------
	-- Setup Web View Controller:
	--------------------------------------------------------------------------------
	mod.controller = webview.usercontent.new(WEBVIEW_LABEL)
		:setCallback(function(message)
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

		local toolbar = mod.toolbar
		for _,panel in ipairs(mod._panels) do
			local item = panel:getToolbarItem()

			toolbar:addItems(item)
			-- toolbar:insertItem(item.id, index)
			if not toolbar:selectedItem() then
				toolbar:selectedItem(item.id)
			end
		end
	end

	--------------------------------------------------------------------------------
	-- Setup Web View:
	--------------------------------------------------------------------------------
	local prefs = {}
	prefs.developerExtrasEnabled = config.developerMode()
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

--- plugins.core.preferences.manager.show() -> boolean
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
		mod.new()
	end

	if next(mod._panels) == nil then
		dialog.displayMessage("There are no Preferences Panels to display.")
		return nil
	else
		mod.selectPanel(currentPanelID())
		mod.webview:html(generateHTML())
		mod.webview:show()
		mod.focus()
	end

	--------------------------------------------------------------------------------
	-- Select Panel:
	--------------------------------------------------------------------------------

	return true
end

function mod.focus()
	return mod.webview and mod.webview:hswindow() and mod.webview:hswindow():raise():focus()
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
	if mod.webview then
		mod.webview:evaluateJavaScript(script)
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

	for i, panel in ipairs(mod._panels) do
		--------------------------------------------------------------------------------
		-- Resize Panel:
		--------------------------------------------------------------------------------
		if panel.id == id and panel.height then
			mod.webview:size({w = mod.defaultWidth, h = panel.height })
		end

		local style = panel.id == id and "block" or "none"
		js = js .. [[
			document.getElementById(']] .. panel.id .. [[').style.display = ']] .. style .. [[';
		]]
	end

	mod.webview:evaluateJavaScript(js)
	mod.toolbar:selectedItem(id)

	--------------------------------------------------------------------------------
	-- Save Last Tab in Settings:
	--------------------------------------------------------------------------------
	mod.lastTab(id)

end

local function comparePriorities(a, b)
	return a.priority < b.priority
end

--- plugins.core.preferences.manager.addPanel(params) -> plugins.core.preferences.manager.panel
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

	local newPanel = panel.new(params, mod)

	local index = _.sortedIndex(mod._panels, newPanel, comparePriorities)
	table.insert(mod._panels, index, newPanel)

	if mod.toolbar then
		local item = panel:getToolbarItem()

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
	id				= "core.preferences.manager",
	group			= "core",
	required		= true,
	dependencies 	= {
		["core.commands.global"] = "global",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)

	--------------------------------------------------------------------------------
	-- Commands:
	--------------------------------------------------------------------------------
	local global = deps.global
	global:add("cpPreferences")
		:whenActivated(mod.show)

	return mod.init(env)
end

return plugin