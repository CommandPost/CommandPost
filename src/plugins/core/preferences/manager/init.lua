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

--------------------------------------------------------------------------------
-- SETTINGS:
--------------------------------------------------------------------------------
mod.defaultWindowStyle	= {"titled", "closable", "nonactivating", "resizable"}
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

--------------------------------------------------------------------------------
-- HIGHEST PRIORITY ID:
--------------------------------------------------------------------------------
local function highestPriorityID()

	local sortedPanels = mod._panels
	return #mod._panels > 0 and mod._panels[1].id or nil

end

--------------------------------------------------------------------------------
-- GENERATE HTML:
--------------------------------------------------------------------------------
local function generateHTML()
	-- log.df("generateHTML: called")
	local env = {}

	env.debugMode = config.get("debugMode", false)
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

--- plugins.core.preferences.manager.init() -> nothing
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
	-- Centre on Screen:
	--------------------------------------------------------------------------------
	local screenFrame = screen.mainScreen():frame()
	local defaultRect = {x = (screenFrame.w/2) - (mod.defaultWidth/2), y = (screenFrame.h/2) - (mod.defaultHeight/2), w = mod.defaultWidth, h = mod.defaultHeight}

	--------------------------------------------------------------------------------
	-- Setup Web View Controller:
	--------------------------------------------------------------------------------
	mod.controller = webview.usercontent.new(WEBVIEW_LABEL)
		:setCallback(function(message)
			-- log.df("webview callback called: %s", hs.inspect(message))
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
	mod.toolbar = toolbar.new(WEBVIEW_LABEL)
		:canCustomize(true)
		:autosaves(true)
		:setCallback(function(toolbar, webview, id)
			mod.selectPanel(id)
		end)

	--------------------------------------------------------------------------------
	-- Setup Web View:
	--------------------------------------------------------------------------------
	local prefs = {}
	if config.get("debugMode") then prefs = {developerExtrasEnabled = true} end
	mod.webview = webview.new(defaultRect, prefs, mod.controller)
		:windowStyle(mod.defaultWindowStyle)
		:shadow(true)
		:allowNewWindows(false)
		:allowTextEntry(true)
		:windowTitle(mod.defaultTitle)
		:toolbar(mod.toolbar)

	return mod
end

--- plugins.core.preferences.manager.showPreferences() -> boolean
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

	--[[
	log.df("Selecting Panel with ID: %s", id)
	if mod.webview and mod.webview:hswindow() then
		log.df("Size: %s", hs.inspect(mod.webview:hswindow():size()))
	end
	--]]

	local js = ""

	for i, v in ipairs(mod._panels) do

		--------------------------------------------------------------------------------
		-- Resize Panel:
		--------------------------------------------------------------------------------
		if v.id == id and v.height then
			mod.webview:hswindow():setSize({w = mod.defaultWidth, h = v.height })
		end

		local style = v.id == id and "block" or "none"
		js = js .. [[
			document.getElementById(']] .. v.id .. [[').style.display = ']] .. style .. [[';
		]]
	end

	mod.webview:evaluateJavaScript(js)
	mod.toolbar:selectedItem(id)

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
	id				= "core.preferences.manager",
	group			= "core",
	dependencies	= {
		["core.menu.bottom"]	= "bottom",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)

	mod.setPanelRenderer(env:compileTemplate("html/panels.html"))

	deps.bottom:addItem(PRIORITY, function()
		return { title = i18n("preferences") .. "...", fn = mod.show }
	end)

	return mod.init()
end

return plugin