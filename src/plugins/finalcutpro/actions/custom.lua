--- === plugins.finalcutpro.actions.custom ===
---
--- Creates a bunch of commands that can be used to assign actions to.
--- This allows you to assign any action to a shortcut key in CommandPost.

local require       = require

local log           = require "hs.logger".new "customAction"

local fcp           = require "cp.apple.finalcutpro"
local config        = require "cp.config"
local prop          = require "cp.prop"
local tools         = require "cp.tools"
local i18n          = require "cp.i18n"

local mod           = {}

-- MAXIMUM -> number
-- Constant
-- The maximum number of shortcuts
local MAXIMUM = 20

--- plugins.finalcutpro.actions.custom.shortcuts <cp.prop: table>
--- Variable
--- Table of shortcuts.
mod.customActions = prop(
    function()
        return config.get(fcp:currentLocale().code .. ".actions.custom", {})
    end,
    function(value)
        config.set(fcp:currentLocale().code .. ".actions.custom", value)
    end
):cached()

--- plugins.finalcutpro.actions.custom.apply(id) -> none
--- Function
--- Applies a shortcut.
---
--- Parameters:
---  * `id` - The Custom Action ID.
---
--- Returns:
---  * None
function mod.apply(id)
    local shortcuts = mod.customActions()
    local item = shortcuts and shortcuts[tostring(id)]
    if item then
        local handler = mod._actionmanager.getHandler(item.handlerID)
        if handler then
            handler:execute(item.action)
        else
            tools.playErrorSound()
            log.ef("Failed to find Custom Action Handler for: %s (%s)", item.actionTitle, id)
        end
    else
        tools.playErrorSound()
        log.ef("No Custom Action at ID: %s", id)
    end
end

--- plugins.finalcutpro.actions.custom.assign(id, handlerId) -> none
--- Function
--- Assigns an Action to a Shortcut via a Console.
---
--- Parameters:
---  * `id` - The Custom Action ID.
---  * `completionFn` - An optional completion function that triggers when a selection is made.
---
--- Returns:
---  * None
function mod.assign(id, completionFn)
    --------------------------------------------------------------------------------
    -- Set up an Activator:
    --------------------------------------------------------------------------------
    local activator = mod._actionmanager.getActivator("finalcutpro.actions.custom")
        :onActivate(function(handler, action, text)
            if action ~= nil then
                --------------------------------------------------------------------------------
                -- Save the Action to Preferences:
                --------------------------------------------------------------------------------
                if text and type(text) == "userdata" then
                    text = text:convert("text")
                end
                local shortcuts = mod.customActions()
                shortcuts[tostring(id)] = {
                    handlerID = handler:id(),
                    action = action,
                    actionTitle = text
                }
                mod.customActions(shortcuts)

                --------------------------------------------------------------------------------
                -- Execute the Completion Function if required:
                --------------------------------------------------------------------------------
                if completionFn and type(completionFn) == "function" then
                    local ok, result = xpcall(completionFn, debug.traceback)
                    if not ok then
                        log.ef("Error while triggering completionFn for Custom Action %s:\n%s", id, result)
                        return nil
                    end
                end
            end
        end)

    --------------------------------------------------------------------------------
    -- Remove Final Cut Pro Commands from Activator:
    --------------------------------------------------------------------------------
    local handlerIds = mod._actionmanager.handlerIds()
    activator:allowHandlers(table.unpack(tools.removeFromTable(handlerIds, "fcpx_cmds")))

    --------------------------------------------------------------------------------
    -- Don't bother remembering the last query:
    --------------------------------------------------------------------------------
    activator:lastQueryRemembered(false)

    --------------------------------------------------------------------------------
    -- Preload Choices:
    --------------------------------------------------------------------------------
    activator:preloadChoices()

    --------------------------------------------------------------------------------
    -- Show the activator:
    --------------------------------------------------------------------------------
    activator:show()
end

local plugin = {
    id = "finalcutpro.actions.custom",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"]                        = "fcpxCmds",
        ["core.action.manager"]                         = "actionmanager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Setup Action Manager:
    --------------------------------------------------------------------------------
    mod._actionmanager = deps.actionmanager

    --------------------------------------------------------------------------------
    -- Setup the plugin commands:
    --------------------------------------------------------------------------------
    local fcpxCmds = deps.fcpxCmds
    for i = 1, MAXIMUM do
        fcpxCmds:add("cpCustomAction" .. tostring(i))
            :groupedBy("action")
            :whenPressed(function() mod.apply(i) end)
            :titled(i18n("action") .. " " .. string.format("%02d", i))

            --------------------------------------------------------------------------------
            -- This tells CommandPost to display an "action" in the Shortcuts Preferences:
            --------------------------------------------------------------------------------
            :action(
                --------------------------------------------------------------------------------
                -- Getter:
                --------------------------------------------------------------------------------
                function()
                    local shortcuts = mod.customActions()
                    local id = tostring(i)
                    return shortcuts and shortcuts[id] and shortcuts[id].actionTitle
                end,
                --------------------------------------------------------------------------------
                -- Setter:
                --------------------------------------------------------------------------------
                function(clear, completionFn)
                    if clear then
                        --------------------------------------------------------------------------------
                        -- Clear Action:
                        --------------------------------------------------------------------------------
                        local shortcuts = mod.customActions()
                        local id = tostring(i)
                        shortcuts[id] = nil
                        mod.customActions(shortcuts)
                    else
                        --------------------------------------------------------------------------------
                        -- Assign Action:
                        --------------------------------------------------------------------------------
                        mod.assign(i, completionFn)
                    end
                end)
    end
    return mod
end

return plugin
