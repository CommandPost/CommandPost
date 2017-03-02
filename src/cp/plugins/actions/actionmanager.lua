-- Includes
local urlevent					= require("hs.urlevent")
local fnutils					= require("hs.fnutils")
local log						= require("hs.logger").new("actnmngr")

-- The Module
local mod = {
	_actions	= {},
	_cache		= {},
}

local ARRAY_DELIM = "||"

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
			value = string.split(value, ARRAY_DELIM)
		elseif isNumberString(value) then
			value = tonumber(value)
		end
		thawed[key] = value
	end
	return thawed
end

function mod.init()
	-- Unknown command handler
	urlevent.bind("_undefined", function()
		dialog.displayMessage(i18n("actionUndefinedError"))
	end)
end

function mod.getURL(choice)
	if choice and choice.type then
		-- log.df("getURL: command = %s", hs.inspect(command))
		local params = freezeParams(choice.params)
		return string.format("commandpost://%s?%s", choice.type, params)
	else
		return string.format("commandpost://_undefined")
	end
end

function mod.addAction(action)
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

function mod.getAction(id)
	return mod._actions[id]
end

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

function mod.executeChoice(choice)
	return mod.execute(choice.type, choice.params)
end

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
	return result
end

-- The Plugin
local plugin = {}

plugin.dependencies = {
}

function plugin.init(deps)
	mod.init()
	return mod
end

return plugin