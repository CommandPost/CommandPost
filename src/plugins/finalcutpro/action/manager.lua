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

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {
	_actions	= {},
	_actionIds	= {},
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

-- TODO: Add documentation
function mod.getActionIds()
	return mod._actionsIds
end

-- TODO: Add documentation
function mod.getActions()
	return mod._actions
end

-- TODO: Add documentation
function mod.addAction(action)
	-- log.df("adding action: %s", hs.inspect(action))
	
	local id = action.id()
	mod._actions[id] = action
	mod._actionIds[#mod._actionIds + 1] = id

	urlevent.bind(id, function(eventName, params)
		if eventName ~= id then
			-- Mismatch!
			dialog.displayMessage(i18n("actionMismatchError", {expected = id, actual = eventName}))
			return
		end
		params = thawParams(params)
		action.execute(params)
	end)
	
	
end

-- TODO: Add documentation
function mod.getAction(id)
	return mod._actions[id]
end

-- TODO: Add documentation
function mod.toggleActionEnabled(id)
	local action = mod.getAction(id)
	if action and action.enabled then
		action.enabled:toggle()
	end
end

-- TODO: Add documentation
function mod.enableAllActions()
	for _,action in pairs(mod._actions) do
		if action.enabled then
			action.enabled(true)
		end
	end
end

-- TODO: Add documentation
function mod.disableAllActions()
	for _,action in pairs(mod._actions) do
		if action.enabled then
			action.enabled(false)
		end
	end
end

-- TODO: Add documentation
function mod.getOptions(actionId, params)
	local action = mod.getAction(actionId)
	if action.options then
		return action.options(params)
	else
		return nil
	end
end

-- TODO: Add documentation
function mod.getHidden()
	if not mod._hidden then
		mod._hidden = config.get("actionHidden", {})
	end
	return mod._hidden
end

-- TODO: Add documentation
function mod.setHidden(value)
	mod._hidden = value
	config.set("actionHidden", value)
	-- Refresh the cache next time it's accessed.
	mod.refresh()
end

-- TODO: Add documentation
function mod.hide(id)
	if id then
		local hidden = mod.getHidden()
		hidden[id] = true
		mod.setHidden(hidden)
	end
end

-- TODO: Add documentation
function mod.unhide(id)
	if id then
		local hidden = mod.getHidden()
		hidden[id] = nil
		mod.setHidden(hidden)
	end
end

-- TODO: Add documentation
function mod.isHidden(id)
	return mod.getHidden()[id] == true
end

-- TODO: Add documentation
function mod.toggleHidden(id)
	if id then
		local hidden = mod.getHidden()
		hidden[id] = not hidden[id]
		mod.setHidden(hidden)
	end
end

-- TODO: Add documentation
function mod.getFavorites()
	if not mod._favorites then
		mod._favorites = config.get("actionFavorites", {})
	end
	return mod._favorites
end

-- TODO: Add documentation
function mod.setFavorites(value)
	mod._favorites = value
	config.set("actionFavorites", value)
	-- Sort it in a timer.
	timer.doAfter(1.0, mod.sortChoices)
end

-- TODO: Add documentation
function mod.isFavorite(id)
	local favorites = mod.getFavorites()
	return id and favorites and favorites[id] == true
end

-- TODO: Add documentation
function mod.favorite(id)
	if id then
		local favorites = mod.getFavorites()
		favorites[id] = true
		mod.setFavorites(favorites)
	end
end

-- TODO: Add documentation
function mod.unfavorite(id)
	if id then
		local favorites = mod.getFavorites()
		favorites[id] = nil
		mod.setFavorites(favorites)
	end
end

-- TODO: Add documentation
function mod.getPopularityIndex()
	if not mod._popularityIndex then
		mod._popularityIndex = config.get("actionPopularityIndex", {})
	end
	return mod._popularityIndex
end

-- TODO: Add documentation
function mod.setPopularityIndex(value)
	mod._popularityIndex = value
	config.set("actionPopularityIndex", value)
end

-- TODO: Add documentation
function mod.getPopularity(id)
	if id then
		local index = mod.getPopularityIndex()
		return index[id] or 0
	end
	return 0
end

-- TODO: Add documentation
function mod.incPopularity(id)
	if id then
		local index = mod.getPopularityIndex()
		local pop = index[id] or 0
		index[id] = pop + 1
		mod.setPopularityIndex(index)
		-- Sort it in a timer.
		timer.doAfter(1.0, mod.sortChoices)
	end
end

-- TODO: Add documentation
function mod.execute(actionId, params)
	local action = mod.getAction(actionId)
	if action then
		if action.execute(params) then
			if action.getId then
				mod.incPopularity(action.getId(params))
			end
			return true
		else
			log.wf("Unable to handle action %s with params: %s", hs.inspect(actionId), hs.inspect(params))
		end
	else
		log.wf("No action of type %s is registered", hs.inspect(actionId))
	end
	return false
end

-- TODO: Add documentation
function mod.executeChoice(choice)
	return mod.execute(choice.type, choice.params)
end

-- TODO: Add documentation
local function compareChoice(a, b)
	-- Favorites get first priority
	local afav = mod.isFavorite(a.id)
	local bfav = mod.isFavorite(b.id)
	if afav and not bfav then
		return true
	elseif bfav and not afav then
		return false
	end

	-- Then popularity, if specified
	local apop = mod.getPopularity(a.id)
	local bpop = mod.getPopularity(b.id)
	if apop > bpop then
		return true
	elseif bpop > apop then
		return false
	end

	-- Then text by alphabetical order
	if a.text < b.text then
		return true
	elseif b.text < a.text then
		return false
	end

	-- Then subText by alphabetical order
	local asub = a.subText or ""
	local bsub = b.subText or ""
	return asub < bsub
end

-- TODO: Add documentation
function mod.sortChoices()
	return table.sort(mod._choices, compareChoice)
end

-- TODO: Add documentation
function mod.addChoices(choices)
	local result = mod._choices or {}
	fnutils.concat(result, choices:getChoices())
	mod._choices = result
	mod.sortChoices()
end

-- TODO: Add documentation
function mod.allChoices()
	if not mod._allChoices then
		mod._findChoices()
	end
	return mod._allChoices
end

-- TODO: Add documentation
function mod.choices()
	if not mod._choices then
		mod._findChoices()
	end
	return mod._choices
end

-- TODO: Add documentation
function mod._findChoices()
	local result = {}
	for type,action in pairs(mod._actions) do
		if not action.enabled or action.enabled() then
			local choices = action.choices()
			if choices then
				fnutils.concat(result, choices:getChoices())
			end
		end
	end
	local hidden = mod.getHidden()
	for _,choice in ipairs(result) do
		if choice.oldText then
			choice.text = choice.oldText
		end

		if hidden[choice.id] then
			choice.oldText = choice.text
			choice.text = i18n("actionHiddenText", {text = choice.text})
			choice.hidden = true
		else
			choice.oldText = nil
			choice.hidden = nil
		end
	end
	mod._allChoices = result
	mod._choices = fnutils.filter(result, function(e) return not e.hidden end)
	mod.sortChoices()
end

-- TODO: Add documentation
function mod.refresh()
	mod._choices = nil
	mod._allChoices = nil
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.action.manager",
	group			= "core",
}

function plugin.init(deps)
	mod.init()
	return mod
end

return plugin