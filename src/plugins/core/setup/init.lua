--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                      W E L C O M E   M A N A G E R                         --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.setup ===
---
--- Manager for the CommandPost Setup Screen.

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
local prop										= require("cp.prop")

local _											= require("moses")

local panel										= require("panel")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

-- The `panel` class
mod.panel									= panel

--------------------------------------------------------------------------------
-- SETTINGS:
--------------------------------------------------------------------------------
mod.defaultWidth 							= 900
mod.defaultHeight 							= 470
mod.defaultTitle 							= i18n("setupTitle")

mod._processedPanels						= 0
mod._currentPanel							= nil
mod._panelQueue								= {}


mod.FIRST_PRIORITY	= 0
mod.LAST_PRIORITY	= 1000

mod.onboardingRequired = config.prop("setupOnboardingRequired", true)

--- plugins.core.setup.visible <cp.prop: boolean; read-only>
--- Constant
--- A property indicating if the welcome window is visible on screen.
mod.visible		= prop.new(function() return mod.webview and mod.webview:hswindow() and mod.webview:hswindow():isVisible() or false end)

--- plugins.core.setup.enabled <cp.prop: boolean>
--- Constant
--- Set to `true` if the manager is enabled. Defaults to `false`.
--- Panels can be added while disabled. Once enabled, the window will appear and display the panels.
mod.enabled		= prop.FALSE():watch(function(enabled)
	-- show the welcome window, if any panels are registered.
	mod.show()
end)

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
	return panel.WEBVIEW_LABEL
end

--------------------------------------------------------------------------------
-- GENERATE HTML:
--------------------------------------------------------------------------------
local function generateHTML()
	local env = {}

	env.debugMode = config.developerMode()

	env.panel = mod.currentPanel()
	env.panelCount = mod.panelCount()
	env.panelNumber = mod.panelNumber()

	local result, err = mod.renderPanel(env)
	if err then
		log.ef("Error while rendering Setup Panel: %s", err)
		return err
	else
		return result
	end
end

--- plugins.core.setup.panelCount() -> number
--- Function
--- The number of panels currently being processed in this session.
--- This includes panels already processed, the current panel, and remaining panels.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The number of panels.
function mod.panelCount()
	return mod._processedPanels + #mod._panelQueue
end

--- plugins.core.setup.panelNumber() -> number
--- Function
--- The number of the panel currently being viewed.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the current panel number, or `0` if no panels are registered.
function mod.panelNumber()
	return mod._processedPanels
end

--- plugins.core.setup.panelQueue() -> table of panels
--- Function
--- The table of panels remaining to be processed. Panels are removed from the queue
--- one at a time and idisplayed in the window via the `nextPanel()` function.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The table of panels remaining to be processed.
function mod.panelQueue()
	return mod._panelQueue
end

function mod.currentPanel()
	return mod._currentPanel
end

--------------------------------------------------------------------------------
-- CHECK IF WE NEED THE WELCOME SCREEN:
--------------------------------------------------------------------------------
function mod.init(env)
	mod.setPanelRenderer(env:compileTemplate("html/template.html"))
	mod.visible:update()
	
	return mod
end

--------------------------------------------------------------------------------
-- CREATE THE WELCOME SCREEN:
--------------------------------------------------------------------------------
function mod.new()
	if mod.nextPanel() then
		--------------------------------------------------------------------------------
		-- Centre on Screen:
		--------------------------------------------------------------------------------
		local screenFrame = screen.mainScreen():frame()
		local defaultRect = {
			x = (screenFrame.w/2) - (mod.defaultWidth/2),
			y = (screenFrame.h/2) - (mod.defaultHeight/2),
			w = mod.defaultWidth,
			h = mod.defaultHeight
		}

		--------------------------------------------------------------------------------
		-- Setup Web View Controller:
		--------------------------------------------------------------------------------
		mod.controller = webview.usercontent.new(mod.getLabel())
			:setCallback(function(message)
				-- log.df("webview callback called: %s", hs.inspect(message))
				local body = message.body
				local id = body.id
				local params = body.params

				local panel = mod.currentPanel()
				local handler = panel and panel:getHandler(id)
				if handler then
					return handler(id, params)
				end
			end)

		--------------------------------------------------------------------------------
		-- Setup Web View:
		--------------------------------------------------------------------------------
		local options = {
			developerExtrasEnabled = config.developerMode(),
		}
	
		mod.webview = webview.new(defaultRect, options, mod.controller)
			:windowStyle({"titled", "closable", "nonactivating"})
			:shadow(true)
			:allowNewWindows(false)
			:allowTextEntry(true)
			:windowTitle(mod.defaultTitle)
			:html(generateHTML())

		--------------------------------------------------------------------------------
		-- Show Setup Screen:
		--------------------------------------------------------------------------------
		mod.webview:show()
		mod.visible:update()
		mod.focus()
	end
end

function mod.show()
	if mod.visible() or not mod.enabled() then
		return
	else
		mod.new()
	end
end

function mod.update()
	mod.visible:update()
	if mod.webview then
		mod.webview:html(generateHTML())
	end
end

--------------------------------------------------------------------------------
-- DELETE WEBVIEW:
--------------------------------------------------------------------------------
function mod.delete()
	if mod.webview then
		mod.webview:delete()
		mod.webview = nil
		mod._panelQueue = {}
		mod._currentPanel = nil
		mod._processedPanels = 0
	end
	mod.visible:update()
end

--------------------------------------------------------------------------------
-- INJECT SCRIPT:
--------------------------------------------------------------------------------
function mod.injectScript(script)
	if mod.webview then
		mod.webview:evaluateJavaScript(script)
	end
end

function mod.focus()
	mod.visible:update()
	if mod.webview then
		timer.doAfter(0.1, function()
			mod.webview:hswindow():focus()
		end)
		return true
	end
	return false
end

--- plugins.core.setup.nextPanel() -> boolean
--- Function
--- Moves to the next panel. If the window is visible, the panel will be updated.
--- If no panels are left in the queue, the window will be closed.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if there was another panel to move to, or `false` if no panels remain.
function mod.nextPanel()
	if #mod._panelQueue > 0 then
		mod._currentPanel = mod._panelQueue[1]
		table.remove(mod._panelQueue, 1)
		mod._processedPanels = mod._processedPanels+1
		mod.update()
		mod.focus()
		return true
	else
		mod.delete()
		return false
	end
end

--- plugins.core.setup.addPanel(newPanel) -> panel
--- Function
--- Adds the new panel to the manager. Panels are created via the
--- `plugins.core.setup.panel.new(...)` function.
---
--- If the Setup Manager is `enabled`, the window will be displayed
--- immediately when a panel is added.
---
--- Parameters:
---  * `newPanel`	- The panel to add.
---
--- Returns:
---  * The manager.
function mod.addPanel(newPanel)
	--log.df("Adding Setup Panel with ID: %s", id)
	mod._panelQueue[#mod._panelQueue + 1] = newPanel
	
	-- sort by priority
	table.sort(mod._panelQueue, function(a, b) return a.priority < b.priority end)

	return mod
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "core.setup",
	group			= "core",
	required		= true,
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)
	return mod.init(env)
end

--------------------------------------------------------------------------------
-- POST INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.postInit(deps, env)
	mod.onboardingRequired:watch(function(required)
		if required then
			local iconPath = env:pathToAbsolute("images/commandpost_icon.png")
			
			-- The intro panel
			mod.addPanel(
				panel.new("intro", mod.FIRST_PRIORITY)
					:addIcon(10, {src = iconPath})
					:addHeading(20, config.appName)
					:addSubHeading(30, i18n("introTagLine"))
					:addParagraph(i18n("introText"), true)
					:addButton(1, {
						value	= i18n("continue"),
						onclick = function() mod.nextPanel() end,
					})
					:addButton(2, {
						value	= i18n("quit"),
						onclick	= function() config.application():kill() end,
					})
			)
			
			-- The outro panel
			mod.addPanel(
				panel.new("outro", mod.LAST_PRIORITY)
					:addIcon(10, {src = iconPath})
					:addSubHeading(30, i18n("outroTitle"))
					:addParagraph(i18n("outroText"), true)
					:addButton(1, {
						value	= i18n("close"),
						onclick	= function()
							mod.onboardingRequired(false)
							mod.nextPanel()
						end,
					})
			)
			mod.show()
		end
	end, true)
	
	return mod.enabled(true)
end

return plugin