--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.action.manager ===
---
--- Action Manager Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log						= require("hs.logger").new("actnmngr")

local fnutils					= require("hs.fnutils")
local timer						= require("hs.timer")
local urlevent					= require("hs.urlevent")

local config					= require("cp.config")
local dialog					= require("cp.dialog")

local prop						= require("cp.prop")

local handler					= require("handler")
local activator					= require("activator")

local insert, remove			= table.insert, table.remove
local copy						= fnutils.copy

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

local ARRAY_DELIM = "||"
local UNDEFINED = "_undefined"

local function split(str, pat)
   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
   local fpat = "(.-)" .. pat
   local last_end = 1
   local s, e, cap = str:find(fpat, 1)
   while s do
      if s ~= 1 or cap ~= "" then
         insert(t,cap)
      end
      last_end = e+1
      s, e, cap = str:find(fpat, last_end)
   end
   if last_end <= #str then
      cap = str:sub(last_end)
      insert(t, cap)
   end
   return t
end

local function isNumberString(value)
	return value:match("^[0-9\\.\\-]$") ~= nil
end

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

local function thawParams(params)
	-- defrost any arrays
	local thawed = {}
	for key,value in pairs(params) do
		if value:find(ARRAY_DELIM) then
			value = split(value, ARRAY_DELIM)
		elseif isNumberString(value) then
			value = tonumber(value)
		end
		thawed[key] = value
	end
	return thawed
end

-- TODO: Add documentation
function mod.init()
	-- Unknown command handler
	urlevent.bind(UNDEFINED, function()
		dialog.displayMessage(i18n("actionUndefinedError"))
	end)
end

-- TODO: Add documentation
function mod.getURL(choice)
	if choice and choice.type then
		-- log.df("getURL: command = %s", hs.inspect(command))
		local params = freezeParams(choice.params)
		return string.format("commandpost://%s?%s", choice.type, params)
	else
		return string.format("commandpost://"..UNDEFINED)
	end
end

--- plugins.finalcutpro.action.manager.addHandler(id) -> handler
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

	log.df("Creating new handler for '%s'", id)

	local h = handler.new(id)
	mod._handlers[id] = h

	-- create a URL watcher for the handler.
	urlevent.bind(id, function(eventName, params)
		if eventName ~= id then
			-- Mismatch!
			dialog.displayMessage(i18n("actionMismatchError", {expected = id, actual = eventName}))
			return
		end
		params = thawParams(params)
		h.execute(params)
	end)

	mod.handlers:update()
	mod.handlerIds:update()

	return h
end

--- plugins.finalcutpro.action.manager.handlers <cp.prop: table of handlers; read-only>
--- Constant
--- Provides access to the set of handlers registered with the manager. It
--- returns a table with the handler ID's as the key and the handler as the value.
--- As such, use `pairs(...)` to loop through them.
mod.handlers = prop(function()
	return copy(mod._handlers)
end)

--- plugins.finalcutpro.action.manager.handlerIds <cp.prop: table of strings; read-only>
--- Constant
--- Returns a list of registered handler IDs.
mod.handlerIds = prop(function()
	local ids = {}
	for id,_ in pairs(mod._handlers) do
		insert(ids, id)
	end
	return ids
end)

--- plugins.finalcutpro.action.manager.getHandler(id) -> handler
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

--- plugins.finalcutpro.action.manager.getActivator(id) -> activator
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
	id				= "finalcutpro.action.manager",
	group			= "finalcutpro",
}

function plugin.init(deps)
	mod.init()
	return mod
end

return plugin