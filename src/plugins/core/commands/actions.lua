--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                     C  O  M  M  A  N  D      A C T I O N                   --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.commands.actions ===
---
--- An `action` which will execute a command with matching group/id values.
--- Registers itself with the `core.action.manager`.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local dialog            = require("cp.dialog")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

local ID    = "cmds"
local GROUP = "global"

local format = string.format

--- plugins.core.commands.actions.init(actionmanager, cmds) -> none
--- Function
--- Initialises the module.
---
--- Parameters:
--- * `actionmanager` - The Action Manager Plugin
--- * `cmds` - The Commands Plugin.
---
--- Returns:
--- * None
function mod.init(actionmanager, cmds)
    mod._cmds = cmds

    mod._manager = actionmanager

    mod._handler = actionmanager.addHandler(GROUP .. "_" .. ID, GROUP)
    :onChoices(mod.onChoices)
    :onExecute(mod.onExecute)
    :onActionId(mod.getId)

    -- watch for any aditional commands added after this point...
    cmds:watch({
        add     = function() mod._handler:reset() end
    })
end

--- plugins.core.commands.actions.onChoices(choices) -> none
--- Function
--- Adds available choices to the  selection.
---
--- Parameters:
--- * `choices`     - The `cp.choices` to add choices to.
---
--- Returns:
--- * None
function mod.onChoices(choices)
    for _,cmd in pairs(mod._cmds:getAll()) do
        local title = cmd:getTitle()
        if title then
            local group = cmd:getSubtitle()
            if not group and cmd:getGroup() then
                group = i18n(cmd:getGroup().."_group")
            end
            group = group or ""
            local action = {
                id      = cmd:id(),
            }
            choices:add(title)
                :subText(i18n("commandChoiceSubText", {group = group}))
                :params(action)
                :id(mod.getId(action))
        end
    end
end

--- plugins.core.commands.actions.getId(action) -> string
--- Function
--- Gets an ID from an action table
---
--- Parameters:
--- * `action`      - The action table.
---
--- Returns:
--- * The ID as a string.
function mod.getId(action)
    return format("%s:%s", ID, action.id)
end

--- plugins.core.commands.actions.execute(action) -> boolean
--- Function
--- Executes the action with the provided parameters.
---
--- Parameters:
---  * `action` - A table representing the action, matching the following:
---     * `id` - The specific Command ID within the group.
---
--- Returns:
---  * `true` if the action was executed successfully.
function mod.onExecute(action)
    local group = mod._cmds
    if group then
        local cmdId = action.id
        if cmdId == nil or cmdId == "" then
            --------------------------------------------------------------------------------
            -- No command ID provided:
            --------------------------------------------------------------------------------
            dialog.displayMessage(i18n("cmdIdMissingError"))
            return false
        end
        local cmd = group:get(cmdId)
        if cmd == nil then
            --------------------------------------------------------------------------------
            -- No matching command:
            --------------------------------------------------------------------------------
            dialog.displayMessage(i18n("cmdDoesNotExistError"), {id = cmdId})
            return false
        end

        --------------------------------------------------------------------------------
        -- Ensure the command group is active:
        --------------------------------------------------------------------------------
        group:activate(
            function() cmd:activated() end,
            function() dialog.displayMessage(i18n("cmdGroupNotActivated"), {id = group.id}) end
        )
        return true
    end
    return false
end

--- plugins.core.commands.actions.reset() -> nothing
--- Function
--- Resets the set of choices.
---
--- Parameters:
--- * None
---
--- Returns:
--- * Nothing
function mod.reset()
    mod._handler:reset()
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "core.commands.actions",
    group           = "core",
    dependencies    = {
        ["core.action.manager"]     = "actionmanager",
        ["core.commands.global"]    = "cmds",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    return mod
end

--------------------------------------------------------------------------------
-- POST INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.postInit(deps)
    --------------------------------------------------------------------------------
    -- TODO: Moving `mod.init()` from `plugin.init()` to `plugin.postInit()`
    --       is just a temporary fix until David comes up with a better fix in
    --       issue #897.
    --------------------------------------------------------------------------------
    mod.init(deps.actionmanager, deps.cmds)
    return mod
end

return plugin