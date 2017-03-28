--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                              W E B A P P                                   --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.webapp ===
--- Proof of concept WebApp Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("webapp")

local hsminweb			= require("hs.httpserver.hsminweb")
local inspect			= require("hs.inspect")
local timer				= require("hs.timer")

local template			= require("cp.template")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

function webAppAction(value)
	log.df("Action Recieved: %s", value)
	if value == "cpHighlightBrowserPlayhead" then
		mod.playhead.highlight()
	end
end

function mod.start()

	if mod._server then
		log.df("CommandPost WebApp Already Running")
	else
		mod._server = hsminweb.new()
			:name("CommandPost Webapp")
			:port(12345)
			:cgiEnabled(true)
			:documentRoot(mod.path)
			:luaTemplateExtension("lp")
			:directoryIndex({"index.lp"})
			:start()
		log.df("Started CommandPost WebApp.")
	end

	return mod

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
		["finalcutpro.browser.playhead"] 	= "playhead",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)
	mod.playhead = deps.playhead
	mod.path = env:pathToAbsolute("html")
	return mod
end

function plugin.postInit()
	timer.doAfter(0.1, mod.start)
end

return plugin