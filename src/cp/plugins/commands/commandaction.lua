--- A `action` which will execute a command with matching group/id values.
--- The plugin registers itself with the `cp.plugins.actions.actionmanager`.

-- Includes
local commands			= require("cp.commands")
local choices			= require("cp.choices")
local metadata			= require("cp.metadata")

-- The Modules
local mod = {}

local ID	= "command"

function mod.id()
	return ID
end

--- cp.plugins.actions.commandaction.choices() -> table
--- Function
--- Returns an array of available choices
function mod.choices()
	-- Cache the choices, since commands don't change while the app is running.
	if not mod._choices then
		mod._choices = choices.new(ID)
		for _,id in pairs(commands.groupIds()) do
			local group = commands.group(id)
			for _,cmd in pairs(group:getAll()) do
				local title = cmd:getTitle()
				if title then
					local subText = cmd:getSubtitle()
					if not subText and cmd:getGroup() then
						subText = i18n(cmd:getGroup() .. "_group")
					end
					local params = {
						group	= group:id(),
						id		= cmd:id(),
					}
					mod._choices:add(title)
						:subText(subText)
						:params(params)
						:favorite(mod.isFavorite(params))
						:popularity(mod.getPopularity(params))
				end
			end
		end
	end
	return mod._choices
end

function mod.options(params)
	local options = { "execute" }
	if mod.isFavorite(params) then
		options[#options + 1] = "unfavorite"
	else
		options[#options + 1] = "favorite"
	end
	return options
end

function mod.getFavorites()
	return metadata.get("commandFavorites", {})
end

function mod.setFavorites(value)
	metadata.set("commandFavorites", value)
end

function mod.isFavorite(params)
	local favorites = mod.getFavorites()
	local id = mod.getCommandID(params)
	return id and favorites and favorites[id] == true
end

function mod.getCommandID(params)
	return string.format("%s:%s", params.group, params.id)
end

function mod.favorite(params)
	local favorites = mod.getFavorites()
	favorites[mod.getCommandID(params)] = true
	mod.setFavorites(favorites)
end

function mod.unfavorite(params)
	local favorites = mod.getFavorites()
	favorites[mod.getCommandID(params)] = nil
	mod.setFavorites(favorites)
end

function mod.getPopularityIndex()
	return metadata.get("commandPopularityIndex", {})
end

function mod.setPopularityIndex(value)
	metadata.set("commandPopularityIndex", value)
end

function mod.getPopularity(params)
	local index = mod.getPopularityIndex()
	local id = mod.getCommandID(params)
	return index[id] or 0
end

function mod.incPopularity(params)
	local index = mod.getPopularityIndex()
	local id = mod.getCommandID(params)
	local pop = index[id] or 0
	index[id] = pop + 1
	mod.setPopularityIndex(index)
end

--- cp.plugins.actions.commandaction.execute(params) -> boolean
--- Function
--- Executes the action with the provided parameters.
---
--- Parameters:
--- * `params`	- A table of parameters, matching the following:
---		* `group`	- The Command Group ID
---		* `id`		- The specific Command ID within the group.
---
--- * `true` if the action was executed successfully.
function mod.execute(params)
	local group = commands.group(params.group)
	if group then
		local cmdId = params.id
		if cmdId == nil or cmdId == "" then
			-- No command ID provided!
			dialog.displayMessage(i18n("cmdIdMissingError"))
			return false
		end
		local cmd = group:get(cmdId)
		if cmd == nil then
			-- No matching command!
			dialog.displayMessage(i18n("cmdDoesNotExistError"), {id = cmdId})
			return false
		end
		
		-- Ensure the command group is active
		group:activate(
			function() cmd:activated() end,
			function() dialog.displayMessage(i18n("cmdGroupNotActivated"), {id = group.id}) end
		)
		mod.incPopularity(params)
		mod.reset()
		return true
	end
	return false
end

function mod.reset()
	mod._choices = nil
end

-- The Plugin
local plugin = {}

plugin.dependencies = {
	["cp.plugins.actions.actionmanager"] = "actionmanager",
}

function plugin.init(deps)
	deps.actionmanager.addAction(mod)
	return mod
end

return plugin