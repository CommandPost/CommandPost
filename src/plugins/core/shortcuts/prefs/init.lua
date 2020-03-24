--- === plugins.core.shortcuts.prefs ===
---
--- Shortcuts Preferences Panel

local require = require

local log         = require "hs.logger".new "prefsShortcuts"

local dialog      = require "hs.dialog"
local fnutils     = require "hs.fnutils"
local hotkey      = require "hs.hotkey"
local image       = require "hs.image"
local keycodes    = require "hs.keycodes"

local commands    = require "cp.commands"
local config      = require "cp.config"
local tools       = require "cp.tools"
local ui          = require "cp.web.ui"
local i18n        = require "cp.i18n"

local moses       = require "moses"

local append      = moses.append
local clone       = moses.clone
local isEmpty     = moses.isEmpty
local map         = moses.map
local pop         = moses.pop
local reduce      = moses.reduce
local same        = moses.same

local mod = {}

--- plugins.core.shortcuts.prefs.DEFAULT_SHORTCUTS -> string
--- Constant
--- Default Shortcuts File Name
mod.DEFAULT_SHORTCUTS = "Default"

--- plugins.core.shortcuts.prefs.lastGroup <cp.prop: string>
--- Field
--- Last group used in the Preferences Drop Down.
mod.lastGroup = config.prop("shortcutPreferencesLastGroup", nil)

-- restoreDefaultShortcuts() -> none
-- Function
-- Restores the Default Shortcuts from the Cache.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function restoreDefaultShortcuts()
    for groupID, group in pairs(mod.defaultShortcuts) do
        for cmdID,cmd in pairs(group) do
            for _,shortcut in pairs(cmd) do
                local tempGroup = commands.group(groupID)
                local tempCommand = tempGroup:get(cmdID)
                if tempCommand then
                    tempCommand:deleteShortcuts()
                    tempCommand:activatedBy(shortcut["modifiers"], shortcut["keycode"])
                end
            end
        end

    end
end

-- deleteShortcuts() -> none
-- Function
-- Deletes all shortcuts
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function deleteShortcuts()
    for groupID, group in pairs(mod.defaultShortcuts) do
        for cmdID,_ in pairs(group) do
            local tempGroup = commands.group(groupID)
            local tempCommand = tempGroup:get(cmdID)
            if tempCommand then
                tempCommand:deleteShortcuts()
            end
        end
    end
end

-- cacheShortcuts() -> boolean
-- Function
-- Caches the Default Shortcuts for use later.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function cacheShortcuts()
    mod.defaultShortcuts = {}
    local groupIDs = commands.groupIds()
    for _, groupID in ipairs(groupIDs) do
        local group = commands.group(groupID)
        if not mod.defaultShortcuts[groupID] then
            mod.defaultShortcuts[groupID] = {}
        end
        local cmds = group:getAll()
        for cmdID,cmd in pairs(cmds) do
            if not mod.defaultShortcuts[groupID][cmdID] then
                mod.defaultShortcuts[groupID][cmdID] = {}
            end
            local shortcuts = cmd:getShortcuts()
            for shortcutID,shortcut in pairs(shortcuts) do
                local tempModifiers = shortcut:getModifiers()
                local tempKeycode = shortcut:getKeyCode()
                local tempShortcuts = {
                    ["modifiers"] = tempModifiers,
                    ["keycode"] = tempKeycode
                }
                mod.defaultShortcuts[groupID][cmdID][shortcutID] = tempShortcuts
            end
        end
    end
end

-- resetShortcutsToNone() -> none
-- Function
-- Resets all Shortcuts to None.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function resetShortcutsToNone()
    dialog.webviewAlert(mod._manager.getWebview(), function(result)
        if result == i18n("yes") then
            local groupIDs = commands.groupIds()
            for _, groupID in ipairs(groupIDs) do

                local group = commands.group(groupID)
                local cmds = group:getAll()

                for _,cmd in pairs(cmds) do
                    cmd:deleteShortcuts()
                end
            end

            commands.saveToFile(mod.DEFAULT_SHORTCUTS)

            mod._manager.refresh()
        end
    end, i18n("shortcutsSetNoneConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
end

-- resetShortcuts() -> none
-- Function
-- Prompts to reset shortcuts to default.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function resetShortcuts()
    dialog.webviewAlert(mod._manager.getWebview(), function(result)
        if result == i18n("yes") then
            restoreDefaultShortcuts()
            commands.saveToFile(mod.DEFAULT_SHORTCUTS)
            mod._manager.refresh()
        end
    end, i18n("shortcutsResetConfirmation"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"), "informational")
end

-- shortcutAlreadyInUse(modifiers, keycode) -> none
-- Function
-- Checks to see if a keyboard shortcut is already being used by CommandPost.
--
-- Parameters:
--  * modifiers - Modifier keys in a table
--  * keycode - Keycode
--
-- Returns:
--  * `true` if already in use, otherwise `false`.
local function shortcutAlreadyInUse(modifiers, keycode)
    local groupIDs = commands.groupIds()
    for _, groupID in ipairs(groupIDs) do

        local group = commands.group(groupID)
        local cmds = group:getAll()

        for _,cmd in pairs(cmds) do

            local shortcuts = cmd:getShortcuts()

            for _,shortcut in pairs(shortcuts) do
                local tempModifiers = shortcut:getModifiers()
                local tempKeycode = shortcut:getKeyCode()

                local modifierMatch = true
                if #modifiers ~= #tempModifiers then
                    modifierMatch = false
                else
                    for _, v in pairs(tempModifiers) do
                        if not fnutils.contains(modifiers, v) then
                            modifierMatch = false
                        end
                    end
                end

                if keycode == tempKeycode and modifierMatch then
                    return true
                end
            end
        end
    end
    return false
end

-- shortcutsPanelCallback(id, params) -> none
-- Function
-- Updates a Shortcut.
--
-- Parameters:
--  * id - The ID of the shortcut
--  * params - The params of the shortcut
--
-- Returns:
--  * None
local function shortcutsPanelCallback(_, params)
    local injectScript = mod._manager.injectScript
    if params then
        local paramsType = params["type"]
        if paramsType == "updateGroup" then
            --------------------------------------------------------------------------------
            -- Update Group:
            --------------------------------------------------------------------------------
            mod.lastGroup(params["groupID"])
            mod._manager.refresh()
            return
        elseif paramsType == "updateAction" then
            --------------------------------------------------------------------------------
            -- Update Action:
            --------------------------------------------------------------------------------
            local group = commands.group(params.group)
            local theCommand = group:get(params.command)
            if theCommand then
                local getFn, setFn = theCommand:getAction()
                if setFn then
                    local ok, result = xpcall(function()
                        setFn(false, function()
                            local getFnResult = getFn()
                            if getFnResult then
                                injectScript("setShortcutsAction('" .. params["group"] .. "', '" .. params["command"] .. "', '" .. (getFnResult or i18n("none")) .. "')")
                            end
                        end)
                    end, debug.traceback)
                    if not ok then
                        log.ef("Error while triggering setFn for Group '%s', Command '%s':\n%s", params["group"], params["command"], result)
                        return nil
                    end
                end
            end
            return
        elseif paramsType == "clearAction" then
            --------------------------------------------------------------------------------
            -- Clear Action:
            --------------------------------------------------------------------------------
            local group = commands.group(params.group)
            local theCommand = group:get(params.command)
            if theCommand then
                local _, setFn = theCommand:getAction()
                if setFn then
                    local ok, result = xpcall(function()
                        setFn(true)
                        injectScript("setShortcutsAction('" .. params["group"] .. "', '" .. params["command"] .. "', '" .. i18n("none") .. "')")
                    end, debug.traceback)
                    if not ok then
                        log.ef("Error while triggering setFn for Group '%s', Command '%s':\n%s", params["group"], params["command"], result)
                        return nil
                    end
                end
            end
            return
        end
    end

    --------------------------------------------------------------------------------
    -- Values from Callback:
    --------------------------------------------------------------------------------
    local modifiers = tools.split(params.modifiers, ":")

    --------------------------------------------------------------------------------
    -- Setup Controller:
    --------------------------------------------------------------------------------
    local group = commands.group(params.group)

    --------------------------------------------------------------------------------
    -- Get the correct Command:
    --------------------------------------------------------------------------------
    local theCommand = group:get(params.command)

    if theCommand then

        --------------------------------------------------------------------------------
        -- Clear Previous Shortcuts:
        --------------------------------------------------------------------------------
        theCommand:deleteShortcuts()

        --------------------------------------------------------------------------------
        -- Setup New Shortcut:
        --------------------------------------------------------------------------------
        if params.keyCode and params.keyCode ~= "" and params.keyCode ~= "none" and params.modifiers and params.modifiers ~= "none" then

            --------------------------------------------------------------------------------
            -- Check to see that the shortcut isn't already being used already by macOS:
            --------------------------------------------------------------------------------
            local assignable = hotkey.assignable(modifiers, params.keyCode)
            local systemAssigned = hotkey.systemAssigned(modifiers, params.keyCode)
            if assignable and not systemAssigned then
                --------------------------------------------------------------------------------
                -- Check to see that the shortcut isn't already being used by CommandPost:
                --------------------------------------------------------------------------------
                if shortcutAlreadyInUse(modifiers, params.keyCode) then
                    dialog.webviewAlert(mod._manager.getWebview(), function() end, i18n("shortcutAlreadyInUse"), i18n("shortcutDuplicateError") .. "\n\n" .. i18n("shortcutPleaseTryAgain"), i18n("continue"), "", "informational")
                else
                    theCommand:activatedBy(modifiers, params.keyCode)
                end
            else
                dialog.webviewAlert(mod._manager.getWebview(), function() end, i18n("shortcutAlreadyInUseByMacOS"), i18n("shortcutPleaseTryAgain"), i18n("continue"), "", "informational")
            end

        end

        --------------------------------------------------------------------------------
        -- Save to file:
        --------------------------------------------------------------------------------
        commands.saveToFile(mod.DEFAULT_SHORTCUTS)
    else
        log.wf("Unable to find command to update: %s:%s", params.group, params.command)
    end

end

-- getAllKeyCodes() -> none
-- Function
-- Generate a table of all shortcut keys available.
--
-- Parameters:
--  * None
--
-- Returns:
--  * Table
local function getAllKeyCodes()

    --------------------------------------------------------------------------------
    -- TODO: Work out a way to ONLY display keyboard shortcuts that the system
    --       actually has on it's keyboard.
    --
    --       See: https://github.com/Hammerspoon/hammerspoon/issues/1307
    --------------------------------------------------------------------------------
    local shortcuts = {}

    for k,_ in pairs(keycodes.map) do
        if type(k) == "string" and k ~= "" then
            shortcuts[#shortcuts + 1] = k
        end
    end

    table.sort(shortcuts, function(a, b) return a < b end)

    return shortcuts

end

-- baseModifiers -> table
-- Variable
-- Table of modifiers
local baseModifiers = {
    { value = "command",    label = "⌘" },
    { value = "shift",      label = "⇧" },
    { value = "option",     label = "⌥" },
    { value = "control",    label = "⌃" },
}

-- combinations(list) -> none
-- Function
-- Creates a table of every possible combination of list items
--
-- Parameters:
--  * list - Table of options
--
-- Returns:
--  * None
local function combinations(list)
    if isEmpty(list) then
        return {}
    end
    --------------------------------------------------------------------------------
    -- Work with a copy of the list:
    --------------------------------------------------------------------------------
    list = clone(list)
    local first = pop(list)
    local result = moses({{first}})
    if not isEmpty(list) then
        --------------------------------------------------------------------------------
        -- Get all combinations of the remainder of the list:
        --------------------------------------------------------------------------------
        local combos = combinations(list)
        result = result:append(map(combos, function(v) return append({first}, v) end))
        --------------------------------------------------------------------------------
        -- Add the sub-combos at the end:
        --------------------------------------------------------------------------------
        result = result:append(combos)
    end
    return result:value()
end

-- reduceCombinations(list, f, state) -> table
-- Function
-- Reduces combinations of modifiers
--
-- Parameters:
--  * list - The list
--  * f - The function
--  * state - The state
--
-- Returns:
--  * Table of reduced combinations
local function reduceCombinations(list, f, state)
    return map(combinations(list), function(v) return reduce(v, f, state) end)
end

-- iterateModifiers(list) -> table
-- Function
-- Iterates the modifiers list
--
-- Parameters:
--  * list - The list of options
--
-- Returns:
--  * Table of modifiers
local function iterateModifiers(list)
    return reduceCombinations(list, function(memo, v)
        return { value = v.value .. ":" .. memo.value, label = v.label .. memo.label}
    end)
end

-- allModifiers -> table
-- Variable
-- All modifiers in a table.
local allModifiers = iterateModifiers(baseModifiers)

-- modifierOptions(shortcut) -> none
-- Function
-- Returns the modifier option HTML of a shortcut
--
-- Parameters:
--  * shortcut - The shortcut
--
-- Returns:
--  * HTML as string
local function modifierOptions(shortcut)
    local out = ""
    for _, modifiers in ipairs(allModifiers) do
        local selected = shortcut and same(shortcut:getModifiers(), tools.split(modifiers.value, ":")) and " selected" or ""
        out = out .. ([[<option value="%s"%s>%s</option>]]):format(modifiers.value, selected, modifiers.label)
    end
    return out
end

-- keyCodeOptions(shortcut) -> none
-- Function
-- Returns the keycode option HTML of a shortcut
--
-- Parameters:
--  * shortcut - The shortcut
--
-- Returns:
--  * HTML as string
local function keyCodeOptions(shortcut)
    local options = ""
    local keyCode = shortcut and shortcut:getKeyCode()
    for _,kc in ipairs(mod.allKeyCodes) do
        local selected = keyCode == kc and " selected" or ""
        options = options .. ("<option%s>%s</option>"):format(selected, kc)
    end
    return options
end

-- renderPanel(context) -> string
-- Function
-- Gets the HTML render of the panel
--
-- Parameters:
--  * context - The context of the panel
--
-- Returns:
--  * The rendered HTML as string
local function renderPanel(context)
    if not mod._renderPanel then
        local errorMessage
        mod._renderPanel, errorMessage = mod._env:compileTemplate("html/panel.html")
        if errorMessage then
            log.ef(errorMessage)
            return nil
        end
    end
    return mod._renderPanel(context)
end

-- generateContent() -> string
-- Function
-- Generates the Preference Panel HTML Content.
--
-- Parameters:
--  * None
--
-- Returns:
--  * HTML content as string
local function generateContent()

    --------------------------------------------------------------------------------
    -- The Group Select:
    --------------------------------------------------------------------------------
    local groupLabels = {}
    local defaultGroup = nil
    if mod.lastGroup() then defaultGroup = mod.lastGroup() end -- Get last group from preferences.
    for _,id in ipairs(commands.groupIds()) do
        defaultGroup = defaultGroup or id
        table.insert(groupLabels, {
            value = id,
            label = i18n("shortcut_group_" .. id, {default = id}),
        })
    end
    table.sort(groupLabels, function(a, b) return a.label < b.label end)

    local context = {
        _                       = moses,
        groupLabels             = groupLabels,
        groups                  = commands.groups(),
        defaultGroup            = defaultGroup,
        groupEditor             = mod.getGroupEditor,
        modifierOptions         = modifierOptions,
        keyCodeOptions          = keyCodeOptions,
        i18nLabel               = i18n("label"),
        i18nAction              = i18n("action"),
        i18nModifier            = i18n("modifier"),
        i18nKey                 = i18n("key"),
        i18nApplication         = i18n("application"),
        i18nCustomiseShortcuts  = i18n("customiseShortcuts"),
        i18nNone                = i18n("none"),
        i18nSelect              = i18n("select"),
        i18nClear               = i18n("clear"),
        i18nFilterShortcuts     = i18n("filterShortcuts"),
        webviewLabel            = mod._manager.getLabel(),
    }

    return renderPanel(context)

end

--- plugins.core.shortcuts.prefs.init(deps, env) -> module
--- Function
--- Initialise the Module.
---
--- Parameters:
---  * deps - Dependancies Table
---  * env - Environment Table
---
--- Returns:
---  * The Module
function mod.init(deps, env)

    mod.allKeyCodes     = getAllKeyCodes()

    mod._manager        = deps.manager

    mod._webviewLabel   = deps.manager.getLabel()

    mod._env            = env

    mod._panel          =  deps.manager.addPanel({
        priority        = 2030,
        id              = "shortcuts",
        label           = i18n("shortcutsPanelLabel"),
        image           = image.imageFromPath(tools.iconFallback("/System/Library/PreferencePanes/Keyboard.prefPane/Contents/Resources/Keyboard.icns")),
        tooltip         = i18n("shortcutsPanelTooltip"),
        height          = 750,
    })
    mod._panel
        :addContent(10, generateContent, false)
        :addButton(20,
            {
                width       = 200,
                label       = i18n("resetShortcuts"),
                onclick     = resetShortcuts,
                class       = "resetShortcuts",
            }
        )
        :addButton(21,
            {
                width       = 200,
                label       = i18n("resetShortcutsAllToNone"),
                onclick     = resetShortcutsToNone,
                class       = "resetShortcutsToNone",
            }
        )
        :addHandler("onchange", "shortcutsPanelCallback", shortcutsPanelCallback)

    return mod

end

--- plugins.core.shortcuts.prefs.setGroupEditor(groupId, editorFn) -> none
--- Function
--- Sets the Group Editor
---
--- Parameters:
---  * groupId - Group ID
---  * editorFn - Editor Function
---
--- Returns:
---  * None
function mod.setGroupEditor(groupId, editorFn)
    if not mod._groupEditors then
        mod._groupEditors = {}
    end
    mod._groupEditors[groupId] = editorFn
end

--- plugins.core.shortcuts.prefs.getGroupEditor(groupId) -> none
--- Function
--- Gets the Group Editor
---
--- Parameters:
---  * groupId - Group ID
---
--- Returns:
---  * Group Editor
function mod.getGroupEditor(groupId)
    return mod._groupEditors and mod._groupEditors[groupId]
end

local plugin = {
    id              = "core.shortcuts.prefs",
    group           = "core",
    dependencies    = {
        ["core.controlsurfaces.manager"]        = "manager",
    }
}

function plugin.init(deps, env)
    --------------------------------------------------------------------------------
    -- Reset Watcher:
    --------------------------------------------------------------------------------
    config.watch({
    reset = deleteShortcuts,
    })

    return mod.init(deps, env)
end

function plugin.postInit()
    --------------------------------------------------------------------------------
    -- Cache all the default shortcuts:
    --------------------------------------------------------------------------------
    cacheShortcuts()

    --------------------------------------------------------------------------------
    -- Load Shortcuts From File:
    --------------------------------------------------------------------------------
    local result = commands.loadFromFile(mod.DEFAULT_SHORTCUTS)

    --------------------------------------------------------------------------------
    -- If no Default Shortcut File Exists, lets create one:
    --------------------------------------------------------------------------------
    if not result then
        commands.saveToFile(mod.DEFAULT_SHORTCUTS)
    end
end

return plugin
