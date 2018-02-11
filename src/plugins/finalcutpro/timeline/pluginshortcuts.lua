--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.timeline.pluginshortcuts ===
---
--- Controls for Final Cut Pro's Plugin Shortcuts (for use with Hack Shortcuts).

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                               = require("hs.logger").new("plugShort")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local fcp                               = require("cp.apple.finalcutpro")
local plugins                           = require("cp.apple.finalcutpro.plugins")
local config                            = require("cp.config")
local prop                              = require("cp.prop")
local tools                             = require("cp.tools")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- MAX_SHORTCUTS -> number
-- Constant
-- The maximum number of shortcuts
local MAX_SHORTCUTS = 9

-- PRIORITY -> number
-- Constant
-- The menubar position priority.
local PRIORITY = 50000

-- GROUP -> number
-- Constant
-- The Group
local GROUP = "fcpx"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

local insert, sort = table.insert, table.sort

local pluginTypeDetails = {}
for _,type in pairs(plugins.types) do
    insert(pluginTypeDetails, { type = type, label = i18n(GROUP .. "_" ..type.."_action") })
end
sort(pluginTypeDetails, function(a, b) return a.label < b.label end)

--- plugins.finalcutpro.timeline.pluginshortcuts.init(handlerId, action, shortcutNumber) -> none
--- Function
--- Initialise the module.
---
--- Parameters:
---  * `deps` - Dependancies
---
--- Returns:
---  * The module
function mod.init(deps)
    mod._actionmanager = deps.actionmanager
    mod._apply = {
        [plugins.types.generator]       = deps.generators.apply,
        [plugins.types.title]           = deps.titles.apply,
        [plugins.types.transition]      = deps.transitions.apply,
        [plugins.types.audioEffect]     = deps.audioeffects.apply,
        [plugins.types.videoEffect]     = deps.videoeffects.apply,
    }

    return mod
end

--- plugins.finalcutpro.timeline.pluginshortcuts.shortcuts <cp.prop: table>
--- Variable
--- Table of shortcuts.
mod.shortcuts = prop(
    function()
        return config.get(fcp:currentLanguage() .. ".pluginShortcuts", {})
    end,
    function(value)
        config.set(fcp:currentLanguage() .. ".pluginShortcuts", value)
    end
)

--- plugins.finalcutpro.timeline.pluginshortcuts.setShortcut(handlerId, action, shortcutNumber) -> none
--- Function
--- Sets a shortcut.
---
--- Parameters:
---  * `handlerId`      - The action handler ID.
---  * `action`         - The action.
---  * `shortcutNumber` - The shortcut number, between 1 and 5, which is being assigned.
---
--- Returns:
---  * None
function mod.setShortcut(handlerId, action, shortcutNumber)
    assert(shortcutNumber >= 1 and shortcutNumber <= MAX_SHORTCUTS)
    local shortcuts = mod.shortcuts()
    local handlerShortcuts = shortcuts[handlerId]
    if not handlerShortcuts then
        handlerShortcuts = {}
        shortcuts[handlerId] = handlerShortcuts
    end
    handlerShortcuts[shortcutNumber] = action
    mod.shortcuts(shortcuts)
end

--- plugins.finalcutpro.timeline.pluginshortcuts.getShortcut(handlerId, shortcutNumber) -> shortcut
--- Function
--- Gets a shortcut.
---
--- Parameters:
---  * `handlerId`      - The action handler ID.
---  * `shortcutNumber` - The shortcut number, between 1 and 5, which is being assigned.
---
--- Returns:
---  * The shortcut
function mod.getShortcut(handlerId, shortcutNumber)
    local shortcuts = mod.shortcuts()
    local handlerShortcuts = shortcuts[handlerId]
    return handlerShortcuts and handlerShortcuts[shortcutNumber]
end

--- plugins.finalcutpro.timeline.pluginshortcuts.applyShortcut(handlerId, shortcutNumber) -> none
--- Function
--- Applies a shortcut.
---
--- Parameters:
---  * `handlerId`      - The action handler ID.
---  * `shortcutNumber` - The shortcut number, between 1 and 5, which is being assigned.
---
--- Returns:
---  * None
function mod.applyShortcut(handlerID, shortcutNumber)

    local action = mod.getShortcut(handlerID, shortcutNumber)
    local handler = mod._actionmanager.getHandler(handlerID)
    if handler then
        handler:execute(action)
    else
        log.ef("Failed to find Plugins Shortcut Handler.")
    end

end

--- plugins.finalcutpro.timeline.pluginshortcuts.assignShortcut(shortcutNumber, handlerId) -> none
--- Function
--- Asks the user to assign the specified video effect shortcut number to a selected effect.
--- A chooser will be displayed, and the selected item will become the shortcut.
---
--- Parameters:
---  * `handlerId`      - The action handler ID.
---  * `shortcutNumber` - The shortcut number, between 1 and 5, which is being assigned.
---
--- Returns:
---  * None
function mod.assignShortcut(handlerId, shortcutNumber)
    local activator = mod._actionmanager.getActivator("finalcutpro.timeline.plugin.shortcuts."..handlerId)
        :allowHandlers(handlerId)
        :onActivate(function(_, action)
            if action ~= nil then
                --------------------------------------------------------------------------------
                -- Save the selection:
                --------------------------------------------------------------------------------
                mod.setShortcut(handlerId, action, shortcutNumber)
            end
        end)
    --------------------------------------------------------------------------------
    -- Not configurable by the user:
    --------------------------------------------------------------------------------
    activator:configurable(false)
    --------------------------------------------------------------------------------
    -- Don't bother remembering the last query:
    --------------------------------------------------------------------------------
    activator:lastQueryRemembered(false)

    activator:show()
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------

local plugin = {
    id = "finalcutpro.timeline.pluginshortcuts",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.menu.timeline"]                   = "menu",
        ["finalcutpro.commands"]                        = "fcpxCmds",
        ["core.action.manager"]                         = "actionmanager",
        ["finalcutpro.timeline.generators"]             = "generators",
        ["finalcutpro.timeline.titles"]                 = "titles",
        ["finalcutpro.timeline.transitions"]            = "transitions",
        ["finalcutpro.timeline.audioeffects"]           = "audioeffects",
        ["finalcutpro.timeline.videoeffects"]           = "videoeffects",
        ["finalcutpro.hacks.shortcuts"]                 = "shortcuts",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    mod.init(deps)

    mod._actionmanager = deps.actionmanager

    local menu = deps.menu:addMenu(PRIORITY, function()
        if deps.shortcuts then -- and deps.shortcuts.active() then
            return i18n("pluginShortcuts")
        end
    end)

    --------------------------------------------------------------------------------
    -- Loop through the plugin types:
    --------------------------------------------------------------------------------
    for _,details in pairs(pluginTypeDetails) do
        local type, label = GROUP .. "_" .. details.type, details.label
        --------------------------------------------------------------------------------
        -- The 'Assign Shortcuts' menu:
        --------------------------------------------------------------------------------
        local submenu = menu:addMenu(PRIORITY, function() return label end)

        submenu:addItems(1000, function()
            --------------------------------------------------------------------------------
            -- Effects Shortcuts:
            --------------------------------------------------------------------------------
            local shortcuts = mod.shortcuts()
            local handlerShortcuts  = shortcuts[type] or {}

            local items = {}

            for i = 1,MAX_SHORTCUTS do
                local shortcut = handlerShortcuts[i]
                local shortcutName = shortcut and shortcut.name or i18n("unassignedTitle")
                items[i] = { title = i18n("pluginShortcutTitle", { number = i, title = shortcutName}), fn = function() mod.assignShortcut(type, i) end }
            end

            return items
        end)

        --------------------------------------------------------------------------------
        -- Commands with default shortcuts:
        --------------------------------------------------------------------------------
        local fcpxCmds = deps.fcpxCmds
        for i = 1, MAX_SHORTCUTS do
            fcpxCmds:add("cp" .. tools.firstToUpper(details.type) .. tostring(i))
                :groupedBy("timeline")
                :whenPressed(function() mod.applyShortcut(type, i) end)
        end
    end

    return mod
end

return plugin