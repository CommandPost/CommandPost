--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                      W E L C O M E   M A N A G E R                         --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.welcome.manager ===
---
--- Manager for the CommandPost Welcome Screen.


--- === plugins.core.welcome.manager.enableInterfaceCallback ===
---
--- Callbacks for when the Interface is enabled.


--- === plugins.core.welcome.manager.disableInterfaceCallback ===
---
--- Callbacks for when the Interface is disabled.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("welcome")

local screen									= require("hs.screen")
local timer										= require("hs.timer")
local webview									= require("hs.webview")

local dialog									= require("cp.dialog")
local config									= require("cp.config")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

local WEBVIEW_LABEL								= "welcome"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--------------------------------------------------------------------------------
-- SETTINGS:
--------------------------------------------------------------------------------
mod.defaultWidth 							= 900
mod.defaultHeight 							= 470
mod.defaultTitle 							= i18n("welcomeTitle")
mod._panels									= {}

--- plugins.core.welcome.manager.welcomeComplete <cp.prop: boolean>
--- Variable
--- If true, the Welcome window is complete.
mod.welcomeComplete	= config.prop("welcomeComplete", false)

--------------------------------------------------------------------------------
--
-- ENABLE INTERFACE CALLBACK:
--
--------------------------------------------------------------------------------

--- === plugins.core.welcome.manager.enableInterfaceCallback ===
---
--- Enable Interface Callback Module.

local enableInterfaceCallback = {}
enableInterfaceCallback._items = {}

mod.enableInterfaceCallback = enableInterfaceCallback

--- plugins.core.welcome.manager.enableInterfaceCallback:new(id, callbackFn) -> table
--- Method
--- Creates a new Enable Interface Callback.
---
--- Parameters:
--- * `id`		- The unique ID for this callback.
---
--- Returns:
---  * table that has been created
function enableInterfaceCallback:new(id, callbackFn)

	if enableInterfaceCallback._items[id] ~= nil then
		error("Duplicate Shutdown Callback: " .. id)
	end
	local o = {
		_id = id,
		_callbackFn = callbackFn,
	}
	setmetatable(o, self)
	self.__index = self

	enableInterfaceCallback._items[id] = o
	return o

end

--- plugins.core.welcome.manager.enableInterfaceCallback:get(id) -> table
--- Method
--- Creates a new Enable Interface Callback.
---
--- Parameters:
--- * `id`		- The unique ID for the callback you want to return.
---
--- Returns:
---  * table containing the callback
function enableInterfaceCallback:get(id)
	return self._items[id]
end

--- plugins.core.welcome.manager.enableInterfaceCallback:getAll() -> table
--- Method
--- Returns all of the created Enable Interface Callbacks
---
--- Parameters:
--- * None
---
--- Returns:
---  * table containing all of the created callbacks
function enableInterfaceCallback:getAll()
	return self._items
end

--- plugins.core.welcome.manager.enableInterfaceCallback:id() -> string
--- Method
--- Returns the ID of the current Enable Interface Callback
---
--- Parameters:
--- * None
---
--- Returns:
---  * The ID of the current Enable Interface Callback as a `string`
function enableInterfaceCallback:id()
	return self._id
end

--- plugins.core.welcome.manager.enableInterfaceCallback:callbackFn() -> function
--- Method
--- Returns the callbackFn of the current Enable Interface Callback
---
--- Parameters:
--- * None
---
--- Returns:
---  * The callbackFn of the current Shutdown Callback
function enableInterfaceCallback:callbackFn()
	return self._callbackFn
end

--------------------------------------------------------------------------------
--
-- DISABLE INTERFACE CALLBACK:
--
--------------------------------------------------------------------------------

--- === plugins.core.welcome.manager.disableInterfaceCallback ===
---
--- Disable Interface Callback Module.

local disableInterfaceCallback = {}
disableInterfaceCallback._items = {}

mod.disableInterfaceCallback = disableInterfaceCallback

--- plugins.core.welcome.manager.disableInterfaceCallback:new(id, callbackFn) -> table
--- Method
--- Creates a new disable Interface Callback.
---
--- Parameters:
--- * `id`		- The unique ID for this callback.
---
--- Returns:
---  * table that has been created
function disableInterfaceCallback:new(id, callbackFn)

	if disableInterfaceCallback._items[id] ~= nil then
		error("Duplicate Shutdown Callback: " .. id)
	end
	local o = {
		_id = id,
		_callbackFn = callbackFn,
	}
	setmetatable(o, self)
	self.__index = self

	disableInterfaceCallback._items[id] = o
	return o

end

--- plugins.core.welcome.manager.disableInterfaceCallback:get(id) -> table
--- Method
--- Creates a new disable Interface Callback.
---
--- Parameters:
--- * `id`		- The unique ID for the callback you want to return.
---
--- Returns:
---  * table containing the callback
function disableInterfaceCallback:get(id)
	return self._items[id]
end

--- plugins.core.welcome.manager.disableInterfaceCallback:getAll() -> table
--- Method
--- Returns all of the created disable Interface Callbacks
---
--- Parameters:
--- * None
---
--- Returns:
---  * table containing all of the created callbacks
function disableInterfaceCallback:getAll()
	return self._items
end

--- plugins.core.welcome.manager.disableInterfaceCallback:id() -> string
--- Method
--- Returns the ID of the current disable Interface Callback
---
--- Parameters:
--- * None
---
--- Returns:
---  * The ID of the current disable Interface Callback as a `string`
function disableInterfaceCallback:id()
	return self._id
end

--- plugins.core.welcome.manager.disableInterfaceCallback:callbackFn() -> function
--- Method
--- Returns the callbackFn of the current disable Interface Callback
---
--- Parameters:
--- * None
---
--- Returns:
---  * The callbackFn of the current Shutdown Callback
function disableInterfaceCallback:callbackFn()
	return self._callbackFn
end

--------------------------------------------------------------------------------
-- SET PANEL TEMPLATE PATH:
--------------------------------------------------------------------------------
function mod.setPanelRenderer(renderer)
	mod.renderPanel = renderer
end

--------------------------------------------------------------------------------
-- GET LABEL:
--------------------------------------------------------------------------------
function mod.getLabel()
	return WEBVIEW_LABEL
end

--------------------------------------------------------------------------------
-- HIGHEST PRIORITY ID:
--------------------------------------------------------------------------------
local function highestPriorityID()
	local sortedPanels = mod._panels
	table.sort(sortedPanels, function(a, b) return a.priority < b.priority end)

	for i, v in ipairs(sortedPanels) do
		if v["enabledFn"] and v["enabledFn"]() == true then
			return v["id"]
		end
	end

	return nil
end

--------------------------------------------------------------------------------
-- GENERATE HTML:
--------------------------------------------------------------------------------
local function generateHTML()
	local env = {}

	env.debugMode = config.get("debugMode", false)

	env.panels = mod._panels
	env.highestPriorityID = highestPriorityID()

	local result, err = mod.renderPanel(env)
	if err then
		log.ef("Error while rendering Welcome Panel: %s", err)
		return err
	else
		return result
	end
end

--------------------------------------------------------------------------------
-- SETUP THE USER INTERFACE ONCE WELCOME SCREEN IS COMPLETE:
--------------------------------------------------------------------------------
function mod.setupUserInterface(showNotification)
	--------------------------------------------------------------------------------
	-- Trigger All Enable Interface Callbacks:
	--------------------------------------------------------------------------------
	for i, v in pairs(enableInterfaceCallback:getAll()) do
		local fn = v:callbackFn()
		if fn and type(fn) == "function" then
			fn(value)
		end
	end

	--------------------------------------------------------------------------------
	-- Notifications:
	--------------------------------------------------------------------------------
	if showNotification then
		log.df("Successfully loaded.")
		dialog.displayNotification(config.appName .. " (v" .. config.appVersion .. ") " .. i18n("hasLoaded"))
	end
end

--------------------------------------------------------------------------------
-- DISABLE THE USER INTERFACE:
--------------------------------------------------------------------------------
function mod.disableUserInterface()
	--------------------------------------------------------------------------------
	-- Trigger All Disable Interface Callbacks:
	--------------------------------------------------------------------------------
	for i, v in pairs(disableInterfaceCallback:getAll()) do
		local fn = v:callbackFn()
		if fn and type(fn) == "function" then
			fn(value)
		end
	end
end

--------------------------------------------------------------------------------
-- ARE ANY PANELS ENABLED?
--------------------------------------------------------------------------------
local function anyPanelsEnabled()
	for i, v in ipairs(mod._panels) do
		if v["enabledFn"] and type(v["enabledFn"]) == "function" then
			if v["enabledFn"]() then
				return true
			end
		end
	end
	return false
end

--------------------------------------------------------------------------------
-- CHECK IF WE NEED THE WELCOME SCREEN:
--------------------------------------------------------------------------------
function mod.init()
	--------------------------------------------------------------------------------
	-- Are there any panels enabled?
	--------------------------------------------------------------------------------
	if anyPanelsEnabled() then
		mod.new()
	else
		mod.setupUserInterface(true)
	end
end

--------------------------------------------------------------------------------
-- CREATE THE WELCOME SCREEN:
--------------------------------------------------------------------------------
function mod.new()
	--------------------------------------------------------------------------------
	-- Centre on Screen:
	--------------------------------------------------------------------------------
	local screenFrame = screen.mainScreen():frame()
	local defaultRect = {x = (screenFrame['w']/2) - (mod.defaultWidth/2), y = (screenFrame['h']/2) - (mod.defaultHeight/2), w = mod.defaultWidth, h = mod.defaultHeight}

	--------------------------------------------------------------------------------
	-- Setup Web View Controller:
	--------------------------------------------------------------------------------
	mod.controller = webview.usercontent.new(WEBVIEW_LABEL)
		:setCallback(function(message)
			--------------------------------------------------------------------------------
			-- Trigger Callbacks:
			--------------------------------------------------------------------------------
			for i, v in ipairs(mod._panels) do
				if type(v["callbackFn"]) == "function" then
					v["callbackFn"](message)
				end
			end
		end)

	--------------------------------------------------------------------------------
	-- Setup Web View:
	--------------------------------------------------------------------------------
	local developerExtrasEnabled = {}
	if config.get("debugMode") then developerExtrasEnabled = {developerExtrasEnabled = true} end
	mod.webview = webview.new(defaultRect, developerExtrasEnabled, mod.controller)
		:windowStyle({"titled", "closable", "nonactivating"})
		:shadow(true)
		:allowNewWindows(false)
		:allowTextEntry(true)
		:windowTitle(mod.defaultTitle)
		:html(generateHTML())

	--------------------------------------------------------------------------------
	-- Select Panel:
	--------------------------------------------------------------------------------
	mod.nextPanel()

	--------------------------------------------------------------------------------
	-- Show Welcome Screen:
	--------------------------------------------------------------------------------
	mod.webview:show()
	timer.doAfter(0.1, function() mod.webview:hswindow():focus() end)
end

--------------------------------------------------------------------------------
-- DELETE WEBVIEW:
--------------------------------------------------------------------------------
function mod.delete()
	mod.webview:delete()
	mod.webview = nil
end

--------------------------------------------------------------------------------
-- INJECT SCRIPT:
--------------------------------------------------------------------------------
function mod.injectScript(script)
	if mod.webview then
		mod.webview:evaluateJavaScript(script)
	end
end

--------------------------------------------------------------------------------
-- NEXT PRIORITY ID:
--------------------------------------------------------------------------------
local function nextPriorityID(currentPanelPriority)
	local sortedPanels = mod._panels
	table.sort(sortedPanels, function(a, b) return a.priority < b.priority end)

	for i, v in ipairs(sortedPanels) do
		if v["priority"] > currentPanelPriority then
			if v["enabledFn"] and type(v["enabledFn"]) == "function" then
				if v["enabledFn"]() then
					return v["id"]
				end
			else
				return v["id"]
			end
		end
	end
	return nil
end

--------------------------------------------------------------------------------
-- GET PANEL:
--------------------------------------------------------------------------------
function mod.getPanel(id)
	for i, v in ipairs(mod._panels) do
		if v["id"] == id then
			return mod._panels[i]
		end
	end
	return nil
end

--------------------------------------------------------------------------------
-- IS PANEL ENABLED:
--------------------------------------------------------------------------------
function mod.isPanelEnabled(id)
	for i, v in ipairs(mod._panels) do
		if v["id"] == id then
			if v["enabledFn"] and type(v["enabledFn"]) == "function" then
				log.df(v["id"] .. " has a enabledFn.")
				return v["enabledFn"]()
			end
		end
	end
	return true
end

--------------------------------------------------------------------------------
-- NEXT PANEL:
--------------------------------------------------------------------------------
function mod.nextPanel(currentPanelPriority)
	if not currentPanelPriority then currentPanelPriority = 0 end

	currentPanelPriority = currentPanelPriority + 0.0000000000001

	local nextPanelID = nextPriorityID(currentPanelPriority)

	if nextPanelID then
		mod.selectPanel(nextPanelID)
	else
		-- There's no more panels left!
		mod.delete()
		mod.setupUserInterface(false)
	end
end

--------------------------------------------------------------------------------
-- SELECT PANEL:
--------------------------------------------------------------------------------
function mod.selectPanel(id)

	--log.df("Selecting Panel with ID: %s", id)

	local javascriptToInject = ""

	for i, v in ipairs(mod._panels) do
		if v["id"] == id then
			javascriptToInject = javascriptToInject .. [[
				if (document.getElementById(']] .. v["id"] .. [[')) {
					document.getElementById(']] .. v["id"] .. [[').style.display = 'block';
				};
				if (document.getElementById('dot]] .. v["id"] .. [[')) {
					document.getElementById('dot]] .. v["id"] .. [[').className = 'selected-dot';
				};
			]]
		else
			javascriptToInject = javascriptToInject .. [[
				if (document.getElementById(']] .. v["id"] .. [[')) {
					document.getElementById(']] .. v["id"] .. [[').style.display = 'none';
				};
				if (document.getElementById('dot]] .. v["id"] .. [[')) {
					document.getElementById('dot]] .. v["id"] .. [[').className = '';
				};
			]]
		end
	end

	if mod.webview then
		mod.webview:evaluateJavaScript(javascriptToInject)
	end

end

--------------------------------------------------------------------------------
-- ADD PANEL:
--------------------------------------------------------------------------------
function mod.addPanel(id, priority, contentFn, callbackFn, enabledFn)
	--log.df("Adding Welcome Panel with ID: %s", id)
	mod._panels[#mod._panels + 1] = {
		id = id,
		priority = priority,
		contentFn = contentFn,
		callbackFn = callbackFn,
		enabledFn = enabledFn,
	}
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "core.welcome.manager",
	group			= "core",
	required		= true,
	dependencies	= {
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)
	config.accessibilityStateCallback:new("welcome", function()
		--log.df("Accessibility State Changed.")
		if mod.webview == nil then
			if anyPanelsEnabled() then
				mod.disableUserInterface()
				mod.new()
			else
				mod.setupUserInterface(true)
			end
		end
	end)

	mod.setPanelRenderer(env:compileTemplate("html/template.html"))
	return mod
end

--------------------------------------------------------------------------------
-- POST INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.postInit(deps)
	return mod.init()
end

return plugin