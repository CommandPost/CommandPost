--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                    C L I P B O A R D     H I S T O R Y                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.clipboard.history ===
---
--- Clipboard History

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                                   = require("hs.logger").new("clipboardHistory")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local fcp                                   = require("cp.apple.finalcutpro")
local config                                = require("cp.config")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local DEFAULT_VALUE                         = true
local TOOLS_PRIORITY                        = 1000
local OPTIONS_PRIORITY                      = 1000

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

-- plugins.finalcutpro.clipboard.history._historyMaximumSize -> number
-- Variable
-- Maximum Size of Clipboard History
mod._historyMaximumSize = 5

--- plugins.finalcutpro.clipboard.history.enabled <cp.prop: boolean>
--- Field
--- Enable or disable the Clipboard History.
mod.enabled = config.prop("enableClipboardHistory", DEFAULT_VALUE)

--- plugins.finalcutpro.clipboard.history.getHistory() -> table
--- Function
--- Gets the Clipboard History.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of the clipboard history.
function mod.getHistory()
    if not mod._history then
        mod._history = config.get("clipboardHistory", {})
    end
    return mod._history
end

--- plugins.finalcutpro.clipboard.history.setHistory(history) -> none
--- Function
--- Sets the Clipboard History.
---
--- Parameters:
---  * history - The history in a table.
---
--- Returns:
---  * None
function mod.setHistory(history)
    mod._history = history
    config.set("clipboardHistory", history)
end

--- plugins.finalcutpro.clipboard.history.clearHistory() -> none
--- Function
--- Clears the Clipboard History.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.clearHistory()
    mod.setHistory({})
end

--- plugins.finalcutpro.clipboard.history.addHistoryItem(data, label) -> none
--- Function
--- Adds an item to the clipboard history.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.addHistoryItem(data, label)
    local history = mod.getHistory()
    local item = {data, label}
    --------------------------------------------------------------------------------
    -- Drop old history items:
    --------------------------------------------------------------------------------
    while (#(history) >= mod._historyMaximumSize) do
        table.remove(history,1)
    end
    table.insert(history, item)
    mod.setHistory(history)
end

--- plugins.finalcutpro.clipboard.history.pasteHistoryItem(index) -> none
--- Function
--- Pastes a Clipboard History Item.
---
--- Parameters:
---  * index - The index of the clipboard history item.
---
--- Returns:
---  * None
function mod.pasteHistoryItem(index)
    local item = mod.getHistory()[index]
    if item then
        --------------------------------------------------------------------------------
        -- Put item back in the clipboard quietly.
        --------------------------------------------------------------------------------
        mod._manager.writeFCPXData(item[1], true)

        --------------------------------------------------------------------------------
        -- Paste in FCPX:
        --------------------------------------------------------------------------------
        fcp:launch()
        if fcp:performShortcut("Paste") then
            return true
        else
            log.w("Failed to trigger the 'Paste' Shortcut.\n\nError occurred in clipboard.history.pasteHistoryItem().")
        end
    end
    return false
end

-- watchUpdate(data, name) -> none
-- Function
-- Callback for when something is added to the clipboard.
--
-- Parameters:
--  * data - The raw clipboard data
--  * name - The name of the clipboard data
--
-- Returns:
--  * None
local function watchUpdate(data, name)
    if name then
        --log.df("Clipboard updated. Adding '%s' to history.", name)
        mod.addHistoryItem(data, name)
    end
end

--- plugins.finalcutpro.clipboard.history.update() -> none
--- Function
--- Enable or disable the Clipboard History.
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

--- plugins.finalcutpro.clipboard.history.init(manager) -> Clipboard History Object
--- Function
--- Initialises the module.
---
--- Parameters:
---  * manager - The clipboard manager object.
---
--- Returns:
---  * Clipboard History Object
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
    id              = "finalcutpro.clipboard.history",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.clipboard.manager"]   = "manager",
        ["finalcutpro.menu.clipboard"]      = "menu",

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
    deps.menu:addMenu(TOOLS_PRIORITY, function() return i18n("localClipboardHistory") end)
        :addItem(OPTIONS_PRIORITY, function()
            return { title = i18n("enableClipboardHistory"),    fn = function()
                mod.enabled:toggle()
                mod.update()
            end, checked = mod.enabled()}
        end)
        :addSeparator(2000)
        :addItems(3000, function()
            local historyItems = {}
            if mod.enabled() then
                local fcpxRunning = fcp:isRunning()
                local history = mod.getHistory()
                if #history > 0 then
                    for i=#history, 1, -1 do
                        local item = history[i]
                        table.insert(historyItems, {title = item[2], fn = function() mod.pasteHistoryItem(i) end, disabled = not fcpxRunning})
                    end
                    table.insert(historyItems, { title = "-" })
                    table.insert(historyItems, { title = i18n("clearClipboardHistory"), fn = mod.clearHistory })
                else
                    table.insert(historyItems, { title = i18n("emptyClipboardHistory"), disabled = true })
                end
            end
            return historyItems
        end)

    return mod
end

return plugin
