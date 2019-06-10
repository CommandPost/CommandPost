--- === plugins.finalcutpro.menu.menuaction ===
---
--- A `action` which will trigger an Final Cut Pro menu with a matching path, if available/enabled.
--- Registers itself with the `plugins.core.actions.actionmanager`.

local require = require

--local log				= require "hs.logger".new "menuaction"

local fnutils           = require "hs.fnutils"
local image             = require "hs.image"

local config            = require "cp.config"
local fcp               = require "cp.apple.finalcutpro"
local i18n              = require "cp.i18n"
local idle              = require "cp.idle"

local concat            = table.concat
local imageFromPath     = image.imageFromPath
local insert            = table.insert

local mod = {}

-- ID -> string
-- Constant
-- The menu ID.
local ID = "menu"

-- GROUP -> string
-- Constant
-- The group ID.
local GROUP = "fcpx"

-- ICON -> hs.image object
-- Constant
-- Icon
local ICON = imageFromPath(config.basePath .. "/plugins/finalcutpro/console/images/menu.png")

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
local alreadyReloading = false
function mod.reload()
    if fcp:menu():showing() and not alreadyReloading then
        alreadyReloading = true
        local choices = {}
        fcp:menu():visitMenuItems(function(path, menuItem)
            local title = menuItem:title()
            if path[1] ~= "Apple" then
                local params = {}
                params.path = fnutils.concat(fnutils.copy(path), { title })
                params.locale = fcp:currentLocale()

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
        alreadyReloading = false
    end
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
    if mod._choices then
        for _,choice in ipairs(mod._choices) do
            choices:add(choice.text)
                :subText(choice.subText)
                :params(choice.params)
                :image(ICON)
                :id(choice.id)
        end
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
        fcp:launch():menu():doSelectMenu(action.path, {plain=true, locale=action.locale}):Now()
        --fcp.app:hsApplication():selectMenuItem(action.path)
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

    mod._choices = config.get("plugins.finalcutpro.menu.menuaction.choices", {})

    mod._manager = actionmanager
    mod._handler = actionmanager.addHandler(GROUP .. "_" .. ID, GROUP)
        :onChoices(mod.onChoices)
        :onExecute(mod.onExecute)
        :onActionId(mod.actionId)

    --------------------------------------------------------------------------------
    -- Watch for restarts:
    --------------------------------------------------------------------------------
    fcp.isRunning:watch(function()
        idle.queue(5, function()
            mod.reload()
        end)
    end, true)

    --------------------------------------------------------------------------------
    -- Watch for new Custom Workspaces:
    --------------------------------------------------------------------------------
    fcp.customWorkspaces:watch(function()
        mod.reload()
    end)

    --------------------------------------------------------------------------------
    -- Reload the menu cache if Final Cut Pro is already running:
    --------------------------------------------------------------------------------
    if fcp:menu():showing() then
        mod.reload()
    end

end

local plugin = {
    id              = "finalcutpro.menu.menuaction",
    group           = "finalcutpro",
    dependencies    = {
        ["core.action.manager"] = "actionmanager",
    }
}

function plugin.init(deps)
    mod.init(deps.actionmanager)
    return mod
end

return plugin
