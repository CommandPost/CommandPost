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
	if mod._server then
		mod._server:stop()
		mod._server = nil
		log.df("Stopped CommandPost WebApp")
	end
end

function mod.copyLinkToClipboard()
	pasteboard.setContents(mod.hostname)
end

function mod.update()
	if mod.enabled() then
		mod.start()
	else
		mod.stop()
	end
end

mod.enabled = config.prop(mod.PREFERENCE_NAME, mod.DEFAULT_SETTING):watch(mod.update)

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
	mod.hostname = getHostname() or i18n("webappUnresolvedHostname")

	--------------------------------------------------------------------------------
	-- Get Path:
	--------------------------------------------------------------------------------
	mod.path = env:pathToAbsolute("html")

	--------------------------------------------------------------------------------
	-- Setup Preferences:
	--------------------------------------------------------------------------------
	deps.webappPreferences:addHeading(10, i18n ("webappIntroduction"))

	:addParagraph(15, i18n("webappInstructions"), true)

	:addHeading(25, i18n("webappSettings"))
	:addCheckbox(30,
		{
			label = i18n("webappEnable"),
			onchange = function() mod.enabled:toggle() end,
			checked = mod.enabled,
		}
	)

	:addHeading(40, i18n("webappHostname"))
	:addParagraph(45, mod.hostname)
	:addButton(50,
		{
			label = "Copy Link to Clipboard",
			onclick = mod.copyLinkToClipboard
		}
	)


	return mod
end

function plugin.postInit()

	--------------------------------------------------------------------------------
	-- Start the WebApp if Enabled:
	--------------------------------------------------------------------------------
	if mod.enabled() then
		timer.doAfter(1, mod.start)
	end

end

return plugin