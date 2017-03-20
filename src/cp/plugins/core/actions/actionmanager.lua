--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                        A C T I O N    M A N A G E R                        --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------
local log						= require("hs.logger").new("actnmngr")

local fnutils					= require("hs.fnutils")
local urlevent					= require("hs.urlevent")

--------------------------------------------------------------------------------
-- CONSTANTS:
--------------------------------------------------------------------------------
local ARRAY_DELIM 				= "||"
local UNDEFINED 				= "_undefined"

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------
local mod = {
	_actions	= {},
	_cache		= {},
}

	--------------------------------------------------------------------------------
	-- SPLIT:
	--------------------------------------------------------------------------------
	local function split(str, pat)
	   local t = {}  -- NOTE: use {n = 0} in Lua-5.0
	   local fpat = "(.-)" .. pat
	   local last_end = 1
	   local s, e, cap = str:find(fpat, 1)
	   while s do
		  if s ~= 1 or cap ~= "" then
			 table.insert(t,cap)
		  end
		  last_end = e+1
		  s, e, cap = str:find(fpat, last_end)
	   end
	   if last_end <= #str then
		  cap = str:sub(last_end)
		  table.insert(t, cap)
	   end
	   return t
	end

	--------------------------------------------------------------------------------
	-- IS NUMBER STRING:
	--------------------------------------------------------------------------------
	local function isNumberString(value)
		return value:match("^[0-9\\.\\-]$") ~= nil
	end

	--------------------------------------------------------------------------------
	-- FREEZE PARAMETERS:
	--------------------------------------------------------------------------------
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

	--------------------------------------------------------------------------------
	-- THAW PARAMETERS:
	--------------------------------------------------------------------------------
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

	--------------------------------------------------------------------------------
	-- INITIALISE MODULE:
	--------------------------------------------------------------------------------
	function mod.init()
		-- Unknown command handler
		urlevent.bind(UNDEFINED, function()
			dialog.displayMessage(i18n("actionUndefinedError"))
		end)
	end

	--------------------------------------------------------------------------------
	-- GET URL:
	--------------------------------------------------------------------------------
	function mod.getURL(choice)
		if choice and choice.type then
			-- log.df("getURL: command = %s", hs.inspect(command))
			local params = freezeParams(choice.params)
			return string.format("commandpost://%s?%s", choice.type, params)
		else
			return string.format("commandpost://"..UNDEFINED)
		end
	end

	--------------------------------------------------------------------------------
	-- ADD ACTION:
	--------------------------------------------------------------------------------
	function mod.addAction(action)
		-- log.df("adding action: %s", hs.inspect(action))
		mod._actions[action.id()] = action

		urlevent.bind(action.id(), function(eventName, params)
			if eventName ~= action.id() then
				-- Mismatch!
				dialog.displayMessage(i18n("actionMismatchError", {expected = action.id(), actual = eventName}))
				return
			end
			params = thawParams(params)
			action.execute(params)
		end)
	end

	--------------------------------------------------------------------------------
	-- GET ACTION:
	--------------------------------------------------------------------------------
	function mod.getAction(id)
		return mod._actions[id]
	end

	--------------------------------------------------------------------------------
	-- EXECUTE ACTION:
	--------------------------------------------------------------------------------
	function mod.execute(actionId, params)
		local action = mod.getAction(actionId)
		if action then
			if action:execute(params) then
				return true
			else
				log.wf("Unable to handle action '%s' with params: %s", hs.inspect(actionId), hs.inspect(params))
			end
		end
	end

	--------------------------------------------------------------------------------
	-- EXECUTE CHOICE:
	--------------------------------------------------------------------------------
	function mod.executeChoice(choice)
		return mod.execute(choice.type, choice.params)
	end

	--------------------------------------------------------------------------------
	-- CHOICES:
	--------------------------------------------------------------------------------
	function mod.choices()
		local result = {}
		for type,action in pairs(mod._actions) do
			local c = mod._cache[type]
			if c == nil then
				c = action:choices()
				if c:isStatic() then
					mod._cache[type] = c
				end
			end
			fnutils.concat(result, c:getChoices())
		end
		table.sort(result, function(a, b) return a.text < b.text end)
		return result
	end

--------------------------------------------------------------------------------
-- THE PLUGIN:
--------------------------------------------------------------------------------
local plugin = {}

	--------------------------------------------------------------------------------
	-- DEPENDENCIES:
	--------------------------------------------------------------------------------
	plugin.dependencies = {
	}

	--------------------------------------------------------------------------------
	-- INITIALISE PLUGIN:
	--------------------------------------------------------------------------------
	function plugin.init(deps)
		mod.init()
		return mod
	end

return plugin