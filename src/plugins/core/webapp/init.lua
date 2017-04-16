--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                              W E B A P P                                   --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.webapp ===
---
--- WebApp Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("webapp")

local hsminweb			= require("hs.httpserver.hsminweb")
local inspect			= require("hs.inspect")
local pasteboard		= require("hs.pasteboard")
local timer				= require("hs.timer")

local config			= require("cp.config")
local tools				= require("cp.tools")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

mod.DEFAULT_PORT 			= 12345
mod.DEFAULT_SETTING			= false
mod.PREFERENCE_NAME 		= "enableWebApp"

function mod.start()
	if mod._server then
		log.df("CommandPost WebApp Already Running")
	else
		mod._server = hsminweb.new()
			:name("CommandPost Webapp")
			:port(mod.DEFAULT_PORT)
			:cgiEnabled(true)
			:documentRoot(mod.path)
			:luaTemplateExtension("lp")
			:directoryIndex({"index.lp"})
			:start()
		log.df("Started CommandPost WebApp.")
	end
	return mod
end

function mod.stop()
	mod._server:stop()
	mod._server = nil
	log.df("Stopped CommandPost WebApp")
end

function mod.copyLinkToClipboard()
	pasteboard.setContents(mod.hostname)
end

function mod.getEnableWebApp()
	return config.get(mod.PREFERENCE_NAME, mod.DEFAULT_SETTING)
end

function mod.toggleEnableWebApp()
	local enableWebApp = config.get(mod.PREFERENCE_NAME, mod.DEFAULT_SETTING)
	config.set(mod.PREFERENCE_NAME, not enableWebApp)
	if enableWebApp then
		mod.stop()
	else
		mod.start()
	end
end

--------------------------------------------------------------------------------
-- GET HOSTNAME:
--------------------------------------------------------------------------------
local function getHostname()
	local _hostname, _status = hs.execute("hostname")
	if _status and _hostname then
		return "http://" .. tools.trim(_hostname) .. ":" .. mod.DEFAULT_PORT
	else
		return nil
	end
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "core.webapp",
	group			= "core",
	dependencies	= {
		["core.preferences.panels.webapp"] 	= "webappPreferences",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)

	--------------------------------------------------------------------------------
	-- Get Hostname:
	--------------------------------------------------------------------------------
	mod.hostname = getHostname() or "Failed to Resolve Hostname!"

	--------------------------------------------------------------------------------
	-- Get Path:
	--------------------------------------------------------------------------------
	mod.path = env:pathToAbsolute("html")

	--------------------------------------------------------------------------------
	-- Setup Preferences:
	--------------------------------------------------------------------------------
	deps.webappPreferences:addHeading(10, function()
		return { title = "Introduction:" }
	end)

	:addText(15, function()
		return { title = "<p>The <span style='font-weight: bold;'>WebApp</span> is a very easy way to control CommandPost via your mobile phone or tablet.</p><p>All you need to do is connect your device to the same network as this machine, enable the WebApp below, then access the WebApp via your devices browser by entering the below URL:</p><p style='font-size: 15px; font-weight:bold;'>" .. mod.hostname .. "</p>"}
	end)

	:addButton(20, function()
		return { title = "Copy Link to Clipboard",	fn = mod.copyLinkToClipboard }
	end)

	deps.webappPreferences:addHeading(25, function()
		return { title = "<br />Settings:" }
	end)

	:addCheckbox(30, function()
		return { title = "Enable WebApp",	fn = mod.toggleEnableWebApp, checked = mod.getEnableWebApp() }
	end)

	return mod
end

function plugin.postInit()

	--------------------------------------------------------------------------------
	-- Start the WebApp if Enabled:
	--------------------------------------------------------------------------------
	if mod.getEnableWebApp() then
		timer.doAfter(1, mod.start)
	end

end

return plugin