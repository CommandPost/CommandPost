--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                           C O M M A N D P O S T                            --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finder.texttools ===
---
--- Handy text tools.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log				    = require("hs.logger").new("textTools")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local eventtap              = require("hs.eventtap")
local pasteboard			= require("hs.pasteboard")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finder.texttools.processText(value, copyAndPaste) -> none
--- Function
--- Processes Text
---
--- Parameters:
---  * value - The type of text manipulation you want to do. Current values are: `uppercase`, `lowercase` or `camelcase`.
---  * copyAndPaste - A boolean that defines whether or not we should trigger copy and paste.
---
--- Returns:
---  * None
function mod.processText(value, copyAndPaste)
    if copyAndPaste then
        eventtap.keyStroke({"command"}, "c")
    end
    local contents = pasteboard.getContents()
    if contents and type(contents) == "string" then
        local result = ""
        if value == "uppercase" then
            result = string.upper(contents)
        elseif value == "lowercase" then
            result = string.lower(contents)
        elseif value == "camelcase" then
            result = string.lower(contents):gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
        end
        pasteboard.setContents(result)
        if copyAndPaste then
            eventtap.keyStroke({"command"}, "v")
        end
    else
        log.ef("Clipboard Contents is invalid: %s", contents)
    end
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finder.texttools",
	group			= "finder",
	dependencies	= {
		["core.commands.global"]					= "global",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

	--------------------------------------------------------------------------------
	-- Commands:
	--------------------------------------------------------------------------------
	local global = deps.global

    --------------------------------------------------------------------------------
    -- Add Commands:
    --------------------------------------------------------------------------------
	global:add("cpMakeClipboardTextUppercase")
		:whenActivated(function() mod.processText("uppercase", false) end)

	global:add("cpMakeClipboardTextLowercase")
		:whenActivated(function() mod.processText("lowercase", false) end)

	global:add("cpMakeClipboardTextCamelcase")
		:whenActivated(function() mod.processText("camelcase", false) end)

	global:add("cpMakeSelectedTextUppercase")
		:whenActivated(function() mod.processText("uppercase", true) end)

	global:add("cpMakeSelectedTextLowercase")
		:whenActivated(function() mod.processText("lowercase", true) end)

	global:add("cpMakeSelectedTextCamelcase")
		:whenActivated(function() mod.processText("camelcase", true) end)

	return mod
end

return plugin