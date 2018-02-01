--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.action.manager ===
---
--- Action Manager Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log						= require("hs.logger").new("actnmngr")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local fnutils					= require("hs.fnutils")
local timer						= require("hs.timer")
local urlevent					= require("hs.urlevent")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config					= require("cp.config")
local dialog					= require("cp.dialog")
local prop						= require("cp.prop")
local tools                     = require("cp.tools")

--------------------------------------------------------------------------------
-- Module Extensions:
--------------------------------------------------------------------------------
local activator					= require("activator")
local handler					= require("handler")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {
	_actions	= {},
	_actionIds	= {},
	_handlers	= {},
	_activators	= {},
	_cache		= {},
}

local ARRAY_DELIM   = "||"
local UNDEFINED     = "_undefined"

local insert        = table.insert, table
local copy		    = fnutils.copy
local format	    = string.format

-- freezeParams(params) -> string
-- Function
-- Freezes a table of `params` into a string
--
-- Parameters:
--  * `params` - A table of paramaters
--
-- Returns:
--  * A string
local function freezeParams(params)
	local result = ""
	if params then
		for key,value in pairs(params) do
			if result ~= "" then
				result = result .. "&"
			end
			if type(value) == "table" and #value > 0 then
				value = table.concat(value, ARRAY_DELIM)
			end
			result = result .. key .. "=" .. value
		end
	end
	return result
end

-- thawParams(params) -> table
-- Function
-- Defrosts any arrays.
--
-- Parameters:
--  * `params` - A table of paramaters
--
-- Returns:
--  * The thawed result as a table
local function thawParams(params)
	local thawed = {}
	for key,value in pairs(params) do
		if value:find(ARRAY_DELIM) then
			value = tools.split(value, ARRAY_DELIM)
		elseif tools.isNumberString(value) then
			value = tonumber(value)
		end
		thawed[key] = value
	end
	return thawed
end

--- plugins.core.action.manager.init() -> none
--- Function
--- Initialises the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init()
    --------------------------------------------------------------------------------
	-- Unknown command handler:
	--------------------------------------------------------------------------------
	urlevent.bind(UNDEFINED, function()
		dialog.displayMessage(i18n("actionUndefinedError"))
	end)
end

--- plugins.core.action.manager.getURL(handlerId, action) -> string
--- Function
--- Gets a URL based on the Handler ID & Action Table.
---
--- Parameters:
---  * `handlerId` - The Handler ID
---  * `action` The action table
---
--- Returns:
--- * A string
function mod.getURL(handlerId, action)
	local handler = mod.getHandler(handlerId)
	if handler and action then
		local params = freezeParams(action)
		return format("commandpost://%s?%s", handlerId, params)
	else
		return format("commandpost://"..UNDEFINED)
	end
end

--- plugins.core.action.manager.addHandler(id) -> handler
--- Function
--- Adds a new action handler with the specified unique ID and returns it for further configuration.
---
--- Parameters:
--- * `id`		- The unique ID
---
--- Returns:
--- * The `handler` instance.
function mod.addHandler(id)
	if mod._handlers[id] then
		error("Duplicate Action Handler ID: "..id)
	end

	local h = handler.new(id)
	mod._handlers[id] = h

    --------------------------------------------------------------------------------
	-- Create a URL watcher for the handler:
	--------------------------------------------------------------------------------
	urlevent.bind(id, function(eventName, params)
		if eventName ~= id then
			-- Mismatch!
			dialog.displayMessage(i18n("actionMismatchError", {expected = id, actual = eventName}))
			return
		end
		params = thawParams(params)
		h:execute(params)
	end)

	mod.handlers:update()
	mod.handlerIds:update()

	return h
end

--- plugins.core.action.manager.handlers <cp.prop: table of handlers; read-only>
--- Constant
--- Provides access to the set of handlers registered with the manager. It
--- returns a table with the handler ID's as the key and the handler as the value.
--- As such, use `pairs(...)` to loop through them.
mod.handlers = prop(function()
	return copy(mod._handlers)
end)

--- plugins.core.action.manager.handlerIds <cp.prop: table of strings; read-only>
--- Constant
--- Returns a list of registered handler IDs.
mod.handlerIds = prop(function()
	local ids = {}
	for id,_ in pairs(mod._handlers) do
		insert(ids, id)
	end
	return ids
end)

--- plugins.core.action.manager.getHandler(id) -> handler
--- Function
--- Returns an existing handler with the specified ID.
---
--- Parameters:
--- * `id`			- The unique ID of the action handler.
---
--- Returns:
--- * The action handler, or `nil`
function mod.getHandler(id)
	return mod._handlers[id]
end

--- plugins.core.action.manager.getActivator(id) -> activator
--- Function
--- Returns an activator with the specified ID. If it doesn't exist, it will be created.
--- Future calls to get the same ID, and it will return the same instance each time.
---
--- Parameters:
--- * `activatorId`		- The unique ID of the activator.
---
--- Returns:
--- * The activator with the specified ID.
function mod.getActivator(activatorId)
	local a = mod._activators[activatorId]
	if not a then
		a = activator.new(activatorId, mod)
		mod._activators[activatorId] = a
	end
	return a
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "core.action.manager",
	group			= "core",
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
	mod.init()
	return mod
end

return plugin