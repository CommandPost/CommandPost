--- === plugins.finalcutpro.pasteboard.history ===
---
--- Pasteboard History

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                                   = require("hs.logger").new("pasteboardHistory")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config                                = require("cp.config")
local dialog                                = require("cp.dialog")
local fcp                                   = require("cp.apple.finalcutpro")
local fnutils                               = require("hs.fnutils")
local json                                  = require("cp.json")
local i18n                                  = require("cp.i18n")

local If                                    = require("cp.rx.go.If")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local DEFAULT_VALUE                         = false
local TOOLS_PRIORITY                        = 1000
local OPTIONS_PRIORITY                      = 1000

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.pasteboard.history.FILE_NAME -> string
--- Constant
--- File name of settings file.
mod.FILE_NAME = "Pasteboard History.json"

--- plugins.finalcutpro.pasteboard.history.FOLDER_NAME -> string
--- Constant
--- Folder Name where settings file is contained.
mod.FOLDER_NAME = "Pasteboard History"

--- plugins.finalcutpro.pasteboard.history.HISTORY_MAXIMUM_SIZE -> number
--- Constant
--- Maximum Size of Pasteboard History
mod.HISTORY_MAXIMUM_SIZE = 5

--- plugins.finalcutpro.pasteboard.history.enabled <cp.prop: boolean>
--- Field
--- Enable or disable the Pasteboard History.
mod.enabled = config.prop("enablePasteboardHistory", DEFAULT_VALUE)

--- plugins.finalcutpro.pasteboard.history._history <cp.prop: table>
--- Field
--- Contains all the saved Touch Bar Buttons
mod.history = json.prop(config.userConfigRootPath, mod.FOLDER_NAME, mod.FILE_NAME, {})

--- plugins.finalcutpro.pasteboard.history.clearHistory() -> none
--- Function
--- Clears the Pasteboard History.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.clearHistory()
    mod.history:set({})
end

--- plugins.finalcutpro.pasteboard.history.addHistoryItem(data, label) -> none
--- Function
--- Adds an item to the Pasteboard history.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.addHistoryItem(data, label)
    local history = mod.history()
    local item = {data, label}
    --------------------------------------------------------------------------------
    -- Drop old history items:
    --------------------------------------------------------------------------------
    while (#(history) >= mod.HISTORY_MAXIMUM_SIZE) do
        table.remove(history,1)
    end
    table.insert(history, item)
    mod.history:set(history)
end

--- plugins.finalcutpro.pasteboard.history.doPasteHistoryItem(index) -> cp.rx.go.Statement
--- Function
--- Returns a function which will paste a Pasteboard History Item when executed.
---
--- Parameters:
---  * index - The index of the Pasteboard history item.
---
--- Returns:
---  * A [Statement](cp.rx.go.Statement.md) to be executed.
function mod.doPasteHistoryItem(index)
    local timeline = fcp:timeline()

    return If(function()
        return mod.history()[index]
    end)
    :Then(fcp:doLaunch())
    :Then(
        If(timeline.isLoaded):Then(function(item)
            --------------------------------------------------------------------------------
            -- Put item back in the Pasteboard quietly.
            --------------------------------------------------------------------------------
            mod._manager.writeFCPXData(item[1], true)
        end)
        :Then(
            -- If(fcp:doShortcut("Paste"))
            If(fcp:menu():doSelectMenu({"Edit", "Paste"}))
                :Then(true)
                :Otherwise(function()
                    log.w("Failed to trigger the 'Paste' Shortcut.\n\nError occurred in pasteboard.history.doPasteHistoryItem().")
                    return false
                end)
        ):Otherwise(function()
            dialog.displayAlertMessage(i18n("pasteboardHistory_TimelineEmpty"), i18n("pasteboardHistory_TimelineEmptyInfo"))
            return false
        end)
    )
    :Otherwise(false)
    :Label("history.doPastHistoryItem")
end


-- watchUpdate(data, name) -> none
-- Function
-- Callback for when something is added to the Pasteboard.
--
-- Parameters:
--  * data - The raw Pasteboard data
--  * name - The name of the Pasteboard data
--
-- Returns:
--  * None
local function watchUpdate(data, name)
    if name then
        --log.df("Pasteboard updated. Adding '%s' to history.", name)
        mod.addHistoryItem(data, name)
    end
end

--- plugins.finalcutpro.pasteboard.history.update() -> none
--- Function
--- Enable or disable the Pasteboard History.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.update()
    if mod.enabled() then
        if not mod._watcherId then
            mod._watcherId = mod._manager.watch({
                update  = watchUpdate,
            })
        end
    else
        if mod._watcherId then
            mod._manager.unwatch(mod._watcherId)
            mod._watcherId = nil
        end
    end
end

--- plugins.finalcutpro.pasteboard.history.init(manager) -> Pasteboard History Object
--- Function
--- Initialises the module.
---
--- Parameters:
---  * manager - The Pasteboard manager object.
---
--- Returns:
---  * Pasteboard History Object
function mod.init(manager)
    mod._manager = manager
    mod.update()
    return mod
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.pasteboard.history",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.pasteboard.manager"]  = "manager",
        ["finalcutpro.menu.pasteboard"]     = "menu",

    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Initialise the module:
    --------------------------------------------------------------------------------
    mod.init(deps.manager)

    --------------------------------------------------------------------------------
    -- Add menu items:
    --------------------------------------------------------------------------------
    deps.menu:addMenu(TOOLS_PRIORITY, function() return i18n("localPasteboardHistory") end)
        :addItem(OPTIONS_PRIORITY, function()
            return { title = i18n("enablePasteboardHistory"),    fn = function()
                mod.enabled:toggle()
                mod.update()
            end, checked = mod.enabled()}
        end)
        :addSeparator(2000)
        :addItems(3000, function()
            local historyItems = {}
            if mod.enabled() then
                local fcpxRunning = fcp:isRunning()
                local history = mod.history()
                if #history > 0 then
                    for i=#history, 1, -1 do
                        local item = history[i]
                        table.insert(historyItems, {title = item[2], fn = function() mod.doPasteHistoryItem(i):Now() end, disabled = not fcpxRunning})
                    end
                    table.insert(historyItems, { title = "-" })
                    table.insert(historyItems, { title = i18n("clearPasteboardHistory"), fn = mod.clearHistory })
                else
                    table.insert(historyItems, { title = i18n("empty"), disabled = true })
                end
            end
            return historyItems
        end)

    return mod
end

--------------------------------------------------------------------------------
-- POST INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.postInit()

    --------------------------------------------------------------------------------
    -- Migrate Legacy Property Pasteboard History to JSON:
    --------------------------------------------------------------------------------
    local legacy = config.get("pasteboardHistory", nil)
    if legacy then
        mod.history(fnutils.copy(legacy))
        config.set("pasteboardHistory", nil)
        log.df("Migrated Pasteboard History from Plist to JSON.")
    end

end

return plugin
