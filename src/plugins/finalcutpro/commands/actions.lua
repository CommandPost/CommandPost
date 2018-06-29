--- === plugins.finalcutpro.commands.actions ===
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
local i18n              = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

local format = string.format

local ID = "cmds"
local GROUP = "fcpx"

--- plugins.finalcutpro.commands.actions.init(actionmanager, cmds) -> none
--- Function
--- Initialises the module.
---
--- Parameters:
---  * actionmanager - The action manager object
---  * cmds - Final Cut Pro commands manager
---
--- Returns:
---  * None
function mod.init(actionmanager, cmds)
    mod._cmds = cmds

    mod._manager = actionmanager

    mod._handler = actionmanager.addHandler(GROUP .. "_" .. ID, GROUP)
        :onChoices(mod.onChoices)
        :onExecute(mod.onExecute)
        :onActionId(mod.getId)

    --------------------------------------------------------------------------------
    -- Watch for any aditional commands added after this point...
    --------------------------------------------------------------------------------
    cmds:watch({
        add     = function() mod._handler:reset() end
    })

end

--- plugins.finalcutpro.commands.actions.onChoices(choices) -> none
--- Function
--- Adds available choices to the  selection.
---
--- Parameters:
--- * `choices` - The `cp.choices` to add choices to.
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

--- plugins.finalcutpro.commands.actionss.getId(action) -> string
--- Function
--- Gets the ID from an action.
---
--- Parameters:
--- * action - The action table.
---
--- Returns:
--- * The ID as a string.
function mod.getId(action)
    return format("%s:%s", ID, action.id)
end

--- plugins.finalcutpro.commands.actions.execute(action) -> boolean
--- Function
--- Executes the action with the provided parameters.
---
--- Parameters:
--- * `action`  - A table representing the action, matching the following:
---     * `id`      - The specific Command ID within the group.
---
--- * `true` if the action was executed successfully.
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

--- plugins.finalcutpro.commands.actions.reset() -> nothing
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
    id              = "finalcutpro.commands.actions",
    group           = "finalcutpro",
    dependencies    = {
        ["core.action.manager"]     = "actionmanager",
        ["finalcutpro.commands"]            = "cmds",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    mod.init(deps.actionmanager, deps.cmds)
    return mod
end

return plugin
