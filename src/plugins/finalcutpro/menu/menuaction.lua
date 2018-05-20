--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                         M E N U    A C T I O N                             --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.menu.menuaction ===
---
--- A `action` which will trigger an Final Cut Pro menu with a matching path, if available/enabled.
--- Registers itself with the `plugins.core.actions.actionmanager`.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
--local log               = require("hs.logger").new("menuaction")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config            = require("cp.config")
local fcp               = require("cp.apple.finalcutpro")
local fnutils           = require("hs.fnutils")
local idle              = require("cp.idle")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- ID -> string
-- Constant
-- The menu ID.
local ID                = "menu"

-- GROUP -> string
-- Constant
-- The group ID.
local GROUP             = "fcpx"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

local insert, concat = table.insert, table.concat

--- plugins.finalcutpro.menu.menuaction.id() -> none
--- Function
--- Returns the menu ID
---
--- Parameters:
---  * None
---
--- Returns:
---  * a string contains the menu ID
function mod.id()
    return ID
end

--- plugins.finalcutpro.menu.menuaction.reload() -> none
--- Function
--- Reloads the choices.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.reload()
    local choices = {}
    fcp:menu():visitMenuItems(function(path, menuItem)
        local title = menuItem:title()

        if path[1] ~= "Apple" then
            local params = {}
            params.path = fnutils.concat(fnutils.copy(path), { title })

            insert(choices, {
                text = title,
                subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
                params = params,
                id = mod.actionId(params),
            })
        end
    end)
    config.set("plugins.finalcutpro.menu.menuaction.choices", choices)
    mod._choices = choices
    mod.reset()
end

--- plugins.finalcutpro.menu.menuaction.onChoices(choices) -> none
--- Function
--- Add choices to the chooser.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.onChoices(choices)
    if not fcp:menu():isShowing() or not mod._choices then
        return true
    end

    for _,choice in ipairs(mod._choices) do
        choices:add(choice.text)
            :subText(choice.subText)
            :params(choice.params)
            :id(choice.id)
    end
end

--- plugins.finalcutpro.menu.menuaction.reset() -> none
--- Function
--- Resets the handler.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.reset()
    mod._handler:reset()
end

--- plugins.finalcutpro.menu.menuaction.actionId(params) -> string
--- Function
--- Gets the action ID from the parameters table.
---
--- Parameters:
---  * params - Parameters table.
---
--- Returns:
---  * Action ID as string.
function mod.actionId(params)
    return ID .. ":" .. concat(params.path, "||")
end

--- plugins.finalcutpro.menu.menuaction.execute(action) -> boolean
--- Function
--- Executes the action with the provided parameters.
---
--- Parameters:
--- * `action`  - A table of parameters, matching the following:
---     * `group`   - The Command Group ID
---     * `id`      - The specific Command ID within the group.
---
--- * `true` if the action was executed successfully.
function mod.onExecute(action)
    if action and action.path then
        fcp:launch()

        fcp:menu():selectMenu(action.path)
        return true
    end
    return false
end

--- plugins.finalcutpro.menu.menuaction.init(actionmanager) -> none
--- Function
--- Initialises the Menu Action plugin
---
--- Parameters:
---  * `actionmanager` - the Action Manager plugin
---
--- Returns:
---  * None
function mod.init(actionmanager)
    mod._manager = actionmanager
    mod._handler = actionmanager.addHandler(GROUP .. "_" .. ID, GROUP)
    :onChoices(mod.onChoices)
    :onExecute(mod.onExecute)
    :onActionId(mod.actionId)

    mod._choices = config.get("plugins.finalcutpro.menu.menuaction.choices", {})
    local delay = config.get("plugins.finalcutpro.menu.menuaction.loadDelay", 5)

    --------------------------------------------------------------------------------
    -- Watch for restarts:
    --------------------------------------------------------------------------------
    fcp.isRunning:watch(function()
        idle.queue(delay, function()
            --log.df("Reloading Final Cut Menu Items")
            mod.reload()
        end)
    end, true)
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.menu.menuaction",
    group           = "finalcutpro",
    dependencies    = {
        ["core.action.manager"] = "actionmanager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    mod.init(deps.actionmanager)
    return mod
end

return plugin
