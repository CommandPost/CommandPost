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

local httpserver		= require("hs.httpserver")
local inspect			= require("hs.inspect")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

local function htmlInterface()
	local html = [[
		<!DOCTYPE html>
		<html>
			<body>

			<div id="demo">
				<h1>CommandPost</h1>
				<button type="button" onclick="highlightBrowserPlayhead()">Highlight Browser Playhead</button>
			</div>

			<script>
			function highlightBrowserPlayhead() {
				var xhttp = new XMLHttpRequest();
			  	xhttp.open("GET", "/action/cpHighlightBrowserPlayhead", true);
			  	xhttp.send();
			}
			</script>

			</body>
		</html>
		]]
	return html
end

local function serverCallback(requestType, requestPath, requestHeaders, requestBody)

	--[[
	log.df("requestType: %s", inspect(requestType))
	log.df("requestPath: %s", inspect(requestPath))
	log.df("requestHeaders: %s", inspect(requestHeaders))
	log.df("requestBody: %s", inspect(requestBody))
	--]]

	if string.sub(requestPath,1,8)  == "/action/" then
		if string.sub(requestPath,9) == "cpHighlightBrowserPlayhead" then
			mod.playhead.highlight()
		end
	end

	local returnResponseCode = 200
	local returnBody = htmlInterface()
	local returnHeaders = {
        ["Content-Type"]  = "text/html",
    }

	return returnBody, returnResponseCode, returnHeaders

end

function mod.start()

	if mod._server then
		log.df("CommandPost WebApp Already Running")
	else
		mod._server = httpserver.new()
			:setName("CommandPost Webapp")
			:setPort(12345)
			:setCallback(serverCallback)
			:start()
		log.df("Started CommandPost WebApp.")
	end

	return mod

end

function mod.init()
	mod.start()
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
	mod.path = env:pathToAbsolute("")
	return mod.init()
end

return plugin