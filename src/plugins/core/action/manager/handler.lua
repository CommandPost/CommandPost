--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.action.handler ===
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

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log               = require("hs.logger").new("actnhndlr")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local choices           = require("cp.choices")
local prop              = require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local handler = {}

handler.mt = {}
handler.mt.__index = handler.mt

--- plugins.core.action.handler.new(id, group) -> handler
--- Constructor
--- Creates a new handler with the specified ID.
---
--- Parameters:
--- * `id`      - The unique ID of the action handler.
--- * `group`   - The group the handler belongs to.
---
--- Returns:
--- * The new action handler instance.
function handler.new(id, group)
    local o = {
        _id = id,
        _group = group
    }

    return prop.extend(o, handler.mt)
end

--- plugins.core.action.handler:onExecute(executeFn) -> handler
--- Method
--- Configures the function to call when a choice is executed. This will be passed
--- the choice parameters in a single table.
---
--- Parameters:
--- * `executeFn`       - The function to call when executing.
---
--- Returns:
--- * This action handler.
function handler.mt:onExecute(executeFn)
    self._onExecute = executeFn
    return self
end

--- plugins.core.action.handler:onChoices(choicesFn) -> handler
--- Method
--- Adds a callback function which will receive the `cp.choices` instance to add
--- choices to. This will only get called when required - the results will be cached
--- if the [cached](#cached) property is set to `true`.
---
--- Parameters:
--- * `choicesFn`       - The function with the signature of `function(choices) -> nothing`
---
--- Returns:
--- * This action handler.
function handler.mt:onChoices(choicesFn)
    self._onChoices = choicesFn
    return self
end

--- plugins.core.action.handler:onActionId(actionFn) -> handler
--- Method
--- Configures a function to handle converting an action to unique ID.
--- The function is passed the `action` table and should return a string.
---
--- Parameters:
--- * `actionFn`    - The function with a signature of `function(action) -> string`
---
--- Returns:
--- * This action handler.
function handler.mt:onActionId(actionFn)
    self._onActionId = actionFn
    return self
end

--- plugins.core.action.handler:group() -> string
--- Method
--- Returns the group for this handler.
---
--- Parameters:
--- * None
---
--- Returns:
--- * Group as string.
function handler.mt:group()
    return self._group
end

--- plugins.core.action.handler:id() -> string
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

--- plugins.core.action.handler.cached <cp.prop: boolean>
--- Field
--- If set to `true` (the default), any choices created will be cached until [reset] is called.
handler.mt.cached = prop.TRUE()
:bind(handler.mt)
:watch(function(_, self)
    -- reset the cache
    self:reset()
end)

--- plugins.core.action.handler.choices <cp.prop: cp.choices; read-only>
--- Field
--- Provides `cp.choices` instance for the handler. May be watched/monitored/etc.
--- The contents of the choices will have a `params` field, which contains a unique set
--- of values that identify the choice. This can be passed to the [execute](#execute)
--- method to trigger the choice.
handler.mt.choices = prop(function(self)
    local result = self._choices
    if not result then
        result = choices.new(self:id())
        -- populate the result
        local incomplete = self._onChoices(result) == true

        -- cache if appropriate
        if not incomplete and self:cached() then
            self._choices = result
        end
    end
    return result
end)
:bind(handler.mt)

-- plugins.core.action.handler._onChoices(choices) -> nil
-- Method
-- Default handler for adding choices. Throws an error message.
--
-- Parameters:
-- * `choices`  - The `cp.choices` to add to.
--
-- Returns:
-- * Nothing
function handler.mt._onChoices(_)
    log.df("unimplemented: handler:onChoices(choicesFn)")
end

function handler.mt._onActionId(_)
    log.df("unimplemented: handler:onActionId(actionFn)")
end

--- plugins.core.action.handler:actionId(action) -> string
--- Method
--- Returns a string that can be used as a unique ID for the action details.
function handler.mt:actionId(action)
    return self._onActionId(action)
end

-- plugins.core.action.handler._onExecute(action) -> nil
-- Method
-- Default handler for executing. Throws an error message.
--
-- Parameters:
-- * `action`   - The table of parameters being executed.
--
-- Returns:
-- * Nothing
function handler.mt._onExecute(_)
    log.df("unimplemented: handler:onExecute(executeFn)")
end

--- plugins.core.action.handler:execute(action) -> boolean
--- Method
--- Executes the action, based on values in the table.
---
--- Parameters:
--- * `action`      - A table of details about the action.
---
--- Returns:
--- * `true` if the execution succeeded.
function handler.mt:execute(action)
    if action then
        return self._onExecute(action) ~= false
    end
    return false
end

--- plugins.core.action.handler:reset([updateNow]) -> nil
--- Method
--- Resets the handler, clearing any cached result and requesting new ones.
---
--- Parameters:
--- * `updateNow`   - (optional) If `true`, the choices will update immediately, otherwise they will update when the choices are next requested.
---
--- Returns:
--- * Nothing
function handler.mt:reset(updateNow)
    self._choices = nil
    if updateNow then
        self.choices:update()
    end
end

return handler