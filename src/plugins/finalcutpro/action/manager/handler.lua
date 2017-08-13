--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.action.handler ===
---
--- A support class for handler handlers. It is not used directly, rather
--- it is a 'super class' that provides common functionality.
---
--- Instances of the class primarily need to provide functions for the following:
---
--- ```lua
--- local handler = actionManager:addHandler("foobar")
--- :onChoices(function(choices) ... end)
--- :onExecute(function(action) ... end)
--- ```
---
--- The choices added to the `choices` should have the `params` value set to a table
--- containing the details of the action to execute if the choice is selected.

local log				= require("hs.logger").new("actnhndlr")

local choices			= require("cp.choices")
local config			= require("cp.config")
local prop				= require("cp.prop")

local handler = {}

handler.mt = {}
handler.mt.__index = handler

--- plugins.finalcutpro.action.handler.new(id) -> handler
--- Constructor
--- Creates a new handler with the specified ID.
---
--- Parameters:
--- * `id`		- The unique ID of the action handler.
---
--- Returns:
--- * The new action handler instance.
function handler.new(id)
	local o = {
		_id = id,
	}

	return prop.extend(o, handler.mt)
end

--- plugins.finalcutpro.action.handler:onExecute(executeFn) -> handler
--- Method
--- Configures the function to call when a choice is executed. This will be passed
--- the choice parameters in a single table.
---
--- Parameters:
--- * `executeFn`		- The function to call when executing.
---
--- Returns:
--- * This action handler.
function handler.mt:onExecute(executeFn)
	self._onExecute = executeFn
	return self
end

--- plugins.finalcutpro.action.handler:onChoices(choicesFn) -> handler
--- Method
--- Adds a callback function which will receive the `cp.choices` instance to add
--- choices to. This will only get called when required - the results will be cached
--- if the [cached](#cached) property is set to `true`.
---
--- Parameters:
--- * `choicesFn`		- The function with the signature of `function(choices) -> nothing`
---
--- Returns:
--- * This action handler.
function handler.mt:onChoices(choicesFn)
	self._onChoices = choicesFn
	return self
end

--- plugins.finalcutpro.action.handler:onActionId(actionFn) -> handler
--- Method
--- Configures a function to handle converting an action to unique ID.
--- The function is passed the `action` table and should return a string.
---
--- Parameters:
--- * `actionFn`	- The function with a signature of `function(action) -> string`
---
--- Returns:
--- * This action handler.
function handler.mt:onActionId(actionFn)
	self._onActionId = actionFn
	return self
end


--- plugins.finalcutpro.action.handler:id() -> string
--- Method
--- Returns the ID for this handler.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The ID string.
function handler.mt:id()
	return self._id
end

--- plugins.finalcutpro.action.handler.cached <cp.prop: boolean>
--- Field
--- If set to `true` (the default), any choices created will be cached until [reset] is called.
handler.mt.cached = prop.TRUE()
:bind(handler.mt)
:watch(function(cached, self)
	-- reset the cache
	self:reset()
end)

--- plugins.finalcutpro.action.handler.choices <cp.prop: cp.choices; read-only>
--- Field
--- Provides `cp.choices` instance for the handler. May be watched/monitored/etc.
--- The contents of the choices will have a `params` field, which contains a unique set
--- of values that identify the choice. This can be passed to the [execute](#execute)
--- method to trigger the choice.
handler.mt.choices = prop(function(self)
	local result = self._choices
	if not result then
		result = choices.new()
		-- populate the result
		self._onChoices(result)

 		-- cache if appropriate
		if self:cached() then
			self._choices = result
		end
	end
	return result
end)
:bind(handler.mt)

-- plugins.finalcutpro.action.handler._onChoices(choices) -> nil
-- Method
-- Default handler for adding choices. Throws an error message.
--
-- Parameters:
-- * `choices`	- The `cp.choices` to add to.
--
-- Returns:
-- * Nothing
function handler.mt:_onChoices(choices)
	error("unimplmemented: handler:onChoices(choicesFn)")
end

function handler.mt:_onActionId(action)
	error("unimplemented: handler:onActionId(actionFn)")
end

--- plugins.finalcutpro.action.handler:actionId(action) -> string
--- Method
--- Returns a string that can be used as a unique ID for the action details.
function handler.mt:actionId(action)
	return self._onActionId(action)
end

--- plugins.finalcutpro.action.handler:execute(action) -> boolean
--- Method
--- Executes the action, based on values in the table.
---
--- Parameters:
--- * `action`		- A table of details about the action.
---
--- Returns:
--- * `true` if the execution succeeded.
function handler.mt:execute(action)
	if action then
		return self:_doExecute(action) ~= false
	end
	return false
end

-- plugins.finalcutpro.action.handler._onExecute(action) -> nil
-- Method
-- Default handler for executing. Throws an error message.
--
-- Parameters:
-- * `action`	- The table of parameters being executed.
--
-- Returns:
-- * Nothing
function handler.mt._onExecute(action)
	error("unimplemented: handler:onExecute(executeFn)")
end

--- plugins.finalcutpro.action.handler:reset() -> nil
--- Method
--- Resets the handler, clearing any cached result and requesting new ones.
---
--- Parameters:
--- * None
---
--- Returns:
--- * Nothing
function handler.mt:reset()
	self._choices = nil
	self.choices:update()
end

return handler