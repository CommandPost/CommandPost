--- === plugins.finalcutpro.pasteboard.shared ===
---
--- Shared Pasteboard Plugin.

local require               = require

--local log                   = require "hs.logger".new "shared"

local base64                = require "hs.base64"
local fs                    = require "hs.fs"
local host                  = require "hs.host"
local timer                 = require "hs.timer"

local config                = require "cp.config"
local dialog                = require "cp.dialog"
local fcp                   = require "cp.apple.finalcutpro"
local i18n                  = require "cp.i18n"
local json                  = require "cp.json"
local tools                 = require "cp.tools"

local Do                    = require "cp.rx.go.Do"
local Throw                 = require "cp.rx.go.Throw"

local displayChooseFolder   = dialog.displayChooseFolder
local displayTextBoxMessage = dialog.displayTextBoxMessage
local doAfter               = timer.doAfter
local doesDirectoryExist    = tools.doesDirectoryExist

local mod = {}

-- HISTORY_EXTENSION -> string
-- Constant
-- Shared Pasteboard File Extension.
local HISTORY_EXTENSION = ".cpSharedPasteboard"

-- MAXIMUM_HISTORY -> number
-- Constant
-- The maximum number of items in the shared Pasteboard History.
local MAXIMUM_HISTORY = 5

--- plugins.finalcutpro.pasteboard.shared.enabled <cp.prop: boolean>
--- Field
--- Gets whether or not the shared pasteboard is enabled as a boolean.
mod.enabled = config.prop("enabledShardPasteboard", false)

--- plugins.finalcutpro.pasteboard.shared.path <cp.prop: string>
--- Field
--- The Shared Pasteboard Root Path.
mod.path = config.prop("sharedPasteboardPath", nil)

--- plugins.finalcutpro.pasteboard.shared.validRootPath() -> boolean
--- Function
--- Gets whether or not the current root path exists.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if it exists otherwise `false`.
function mod.validRootPath()
    return doesDirectoryExist(mod.path())
end

-- watchUpdate(data, name) -> none
-- Function
-- Pasteboard updated callback.
--
-- Parameters:
--  * data - The data from the Pasteboard.
--  * name - The name of the item on the Pasteboard.
--
-- Returns:
--  * None
local function watchUpdate(data, name)
    if data and name and mod.validRootPath() then
        local folderName
        if mod._overrideFolder ~= nil then
            folderName = mod._overrideFolder
            mod._overrideFolder = nil
        else
            folderName = mod.getLocalFolderName()
        end

        --------------------------------------------------------------------------------
        -- First, read the existing history:
        --------------------------------------------------------------------------------
        local history = mod.getHistory(folderName) or {}

        --------------------------------------------------------------------------------
        -- Drop old history items:
        --------------------------------------------------------------------------------
        while (#history >= MAXIMUM_HISTORY) do
            table.remove(history, 1)
        end

        --------------------------------------------------------------------------------
        -- Add the new item:
        --------------------------------------------------------------------------------
        local item = {
            name = name,
            data = base64.encode(data),
        }
        table.insert(history, item)

        --------------------------------------------------------------------------------
        -- Save the updated history:
        --------------------------------------------------------------------------------
        mod.setHistory(folderName, history)
    end
end

--- plugins.finalcutpro.pasteboard.shared.update() -> none
--- Function
--- Starts or stops the Shared Pasteboard watcher.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.update()
    if mod.enabled() then
        --------------------------------------------------------------------------------
        -- Enabled:
        --------------------------------------------------------------------------------
        if not mod._watcherId then
            mod._watcherId = mod._manager.watch({
                update  = watchUpdate,
            })
        end
    else
        --------------------------------------------------------------------------------
        -- Disabled:
        --------------------------------------------------------------------------------
        if mod._watcherId then
            mod._manager.unwatch(mod._watcherId)
            mod._watcherId = nil
        end
        mod.path(nil)
    end
end

--- plugins.finalcutpro.pasteboard.shared.getFolderNames() -> table
--- Function
--- Returns the list of folder names as an array of strings.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of folder names.
function mod.getFolderNames()
    local folders = {}
    local rootPath = mod.path()
    if rootPath then
        local path = fs.pathToAbsolute(rootPath)
        if path then
            local contents, data = fs.dir(path)

            for file in function() return contents(data) end do
                local name = file:match("(.+)%"..HISTORY_EXTENSION.."$")
                if name then
                    folders[#folders+1] = name
                end
            end
            table.sort(folders, function(a, b) return a < b end)
        end
    end
    return folders
end

--- plugins.finalcutpro.pasteboard.shared.getLocalFolderName() -> string
--- Function
--- Gets the local folder name.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The local folder name as a string.
function mod.getLocalFolderName()
    return host.localizedName()
end

--- plugins.finalcutpro.pasteboard.shared.overrideNextFolderName(overrideFolder) -> none
--- Function
--- Overrides the folder name for the next clip which is copied from Final Cut Pro to the
--- specified value. Once the override has been used, the standard folder name via
--- `mod.getLocalFolderName()` will be used for subsequent copy operations.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The local folder name as a string.
function mod.overrideNextFolderName(overrideFolder)
    mod._overrideFolder = overrideFolder
end

--- plugins.finalcutpro.pasteboard.shared.copyWithCustomClipName() -> None
--- Function
--- Triggers a copy with custom clip name action.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.copyWithCustomClipName()
    local menuBar = fcp.menu
    if menuBar:isEnabled({"Edit", "Copy"}) then
        local result = displayTextBoxMessage(i18n("overrideClipNamePrompt"), i18n("overrideValueInvalid"), "")
        if result == false then return end
        mod.overrideNextClipName(result)
        menuBar:selectMenu({"Edit", "Copy"})
    end
end

--- plugins.finalcutpro.pasteboard.shared.getHistoryPath(folderName, fileExtension) -> string
--- Function
--- Gets the History Path.
---
--- Parameters:
---  * folderName - The folder name
---  * fileExtension - The file extension
---
--- Returns:
---  * The history path as a string
function mod.getHistoryPath(folderName, fileExtension)
    fileExtension = fileExtension or HISTORY_EXTENSION
    return mod.path() .. folderName .. fileExtension
end

--- plugins.finalcutpro.pasteboard.shared.getHistory(folderName) -> table
--- Function
--- Gets the history for a supplied folder name.
---
--- Parameters:
---  * folderName - The folder name
---
--- Returns:
---  * The history in a table.
function mod.getHistory(folderName)
    local filePath = mod.getHistoryPath(folderName)
    return json.read(filePath) or {}
end

--- plugins.finalcutpro.pasteboard.shared.setHistory(folderName, history) -> boolean
--- Function
--- Sets the history.
---
--- Parameters:
---  * folderName - The folder name
---  * history - A table of the history
---
--- Returns:
---  * `true` if successful otherwise `false`.
function mod.setHistory(folderName, history)
    local filePath = mod.getHistoryPath(folderName)
    if history and #history > 0 then
        return json.write(filePath, history)
    else
        --------------------------------------------------------------------------------
        -- Remove it:
        --------------------------------------------------------------------------------
        os.remove(filePath)
    end
    return false
end

--- plugins.finalcutpro.pasteboard.shared.setHistory(folderName, history) -> none
--- Function
--- Clears the history.
---
--- Parameters:
---  * folderName - The folder name
---
--- Returns:
---  * None
function mod.clearHistory(folderName)
    mod.setHistory(folderName, nil)
end

--- plugins.finalcutpro.pasteboard.shared.copyWithCustomClipNameAndFolder() -> none
--- Function
--- Copy with Custom Label & Folder.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.copyWithCustomClipNameAndFolder()
    local menuBar = fcp.menu
    if menuBar:isEnabled({"Edit", "Copy"}) then
        local result = displayTextBoxMessage(i18n("overrideClipNamePrompt"), i18n("overrideValueInvalid"), "")
        if result == false then return end
        mod._manager.overrideNextClipName(result)

        result = displayTextBoxMessage(i18n("overrideFolderNamePrompt"), i18n("overrideValueInvalid"), "")
        if result == false then return end
        mod.overrideNextFolderName(result)

        menuBar:selectMenu({"Edit", "Copy"})
    end
end

--- plugins.finalcutpro.pasteboard.shared.doDecodeHistoryItem(folderName, index) -> string | nil
--- Function
--- Decodes a Paste History Item.
---
--- Parameters:
---  * folderName - The folder name
---  * index - The index of the item you want to decode
---
--- Returns:
---  * The decoded Pasteboard History Item or `nil`.
function mod.doDecodeHistoryItem(folderName, index)
    return Do(function()
        local item = mod.getHistory(folderName)[index]
        if item then
            local data = base64.decode(item.data)
            if data then
                return data
            end
        end
        return Throw("Unable to decode the item data for '%s' at %d.", folderName, index)
    end)
    :Label("plugins.finalcutpro.pasteboard.shared.doDecodeHistoryItem(folderName, index)")
end

--- plugins.finalcutpro.pasteboard.shared.doPasteHistoryItem(folderName, index) -> none
--- Function
--- Paste History Item.
---
--- Parameters:
---  * folderName - The folder name
---  * index - The index of the item you want to paste
---
--- Returns:
---  * None
function mod.doPasteHistoryItem(folderName, index)
    local originalContents = mod._manager.readFCPXData()
    return Do(mod.doDecodeHistoryItem(folderName, index))
    :Then(function(data)
        --------------------------------------------------------------------------------
        -- Put item back in the pasteboard quietly:
        --------------------------------------------------------------------------------
        mod._manager.writeFCPXData(data, true)
    end)
    :Then(fcp:doLaunch())
    :Then(fcp:doShortcut("Paste"))
    :Then(function()
        if originalContents then
            --------------------------------------------------------------------------------
            -- Restore the original Pasteboard Contents:
            --------------------------------------------------------------------------------
            doAfter(0.3, function()
                mod._manager.writeFCPXData(originalContents, true)
            end)
        end
    end)
end

--- plugins.finalcutpro.pasteboard.shared.generateSharedPasteboardMenu() -> table
--- Function
--- Generates the shared pasteboard menu.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The shared pasteboard menu as a table.
function mod.generateSharedPasteboardMenu()
    local folderItems = {}
    if mod.enabled() and not mod.validRootPath() then
        table.insert(folderItems, { title = i18n("theSharedFolderCouldNotBeFound"), disabled = true })
    elseif mod.enabled() then
        local fcpxRunning = fcp:isRunning()

        local sharedPasteboardFolderModified = fs.attributes(mod.path(), "modification")
        local folderNames
        if sharedPasteboardFolderModified ~= mod._sharedPasteboardFolderModified or mod._folderNames == nil then
            folderNames = mod.getFolderNames()
            mod._folderNames = folderNames
            mod._sharedPasteboardFolderModified = sharedPasteboardFolderModified
            --log.df("Creating Folder Names Cache")
        else
            folderNames = mod._folderNames
            --log.df("Using Folder Names Cache")
        end

        if #folderNames > 0 then
            for _,folder in ipairs(folderNames) do
                local historyItems = {}

                local history
                local historyFolderModified = fs.attributes(mod.getHistoryPath(folder), "modification")

                if mod._historyFolderModified == nil or mod._historyFolderModified[folder] == nil or historyFolderModified ~= mod._historyFolderModified[folder] or mod._history == nil or mod._history[folder] == nil then
                    history = mod.getHistory(folder)
                    if mod._history == nil then mod._history = {} end
                    mod._history[folder] = history
                    if mod._historyFolderModified == nil then mod._historyFolderModified = {} end
                    mod._historyFolderModified[folder] = historyFolderModified
                    --log.df("Creating History Cache for " .. folder)
                else
                    history = mod._history[folder]
                    --log.df("Using History Cache for " .. folder)
                end

                if #history > 0 then
                    for i=#history, 1, -1 do
                        local item = history[i]
                        table.insert(historyItems, {title = item.name, fn = function() mod.doPasteHistoryItem(folder, i):Now() end, disabled = not fcpxRunning})
                    end
                    table.insert(historyItems, { title = "-" })
                    table.insert(historyItems, { title = i18n("clearSharedPasteboard"), fn = function() mod.clearHistory(folder) end })
                else
                    table.insert(historyItems, { title = i18n("empty"), disabled = true })
                end
                table.insert(folderItems, { title = folder, menu = historyItems })
            end
        else
            table.insert(folderItems, { title = i18n("empty"), disabled = true })
        end
    end
    return folderItems
end

-- toggleEnabled() -> none
-- Function
-- Toggles the Shared Pasteboard.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function toggleEnabled()
    if mod.enabled() then
        mod.path(nil)
        mod.enabled(false)
    else
        local result = displayChooseFolder(i18n("sharedPasteboardRootFolder"))
        if result then
            mod.path(result)
            mod.enabled(true)
        end
    end
end

local plugin = {
    id              = "finalcutpro.pasteboard.shared",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.pasteboard.manager"]  = "manager",
        ["finalcutpro.commands"]            = "fcpxCmds",
        ["finalcutpro.menu.manager"]        = "menu",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if FCPX is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Initialise Module:
    --------------------------------------------------------------------------------
    mod._manager = deps.manager

    --------------------------------------------------------------------------------
    -- Add menu items:
    --------------------------------------------------------------------------------
    deps.menu.pasteboard
      :addMenu(2000, function() return i18n("sharedPasteboardHistory") end)
      :addItem(1000, function()
            return {
                title       = i18n("enableSharedPasteboard"),
                fn          = toggleEnabled,
                checked     = mod.enabled()
            }
      end)
      :addSeparator(2000)
      :addItems(3000, function() return mod.generateSharedPasteboardMenu() end)

    --------------------------------------------------------------------------------
    -- Commands:
    --------------------------------------------------------------------------------
    deps.fcpxCmds
      :add("cpCopyWithCustomLabelAndFolder")
      :whenActivated(function()
            mod.copyWithCustomClipNameAndFolder()
      end)

    --------------------------------------------------------------------------------
    -- Force the enabled watcher to trigger:
    --------------------------------------------------------------------------------
    mod.enabled:watch(mod.update)
    mod.enabled:update()

    return mod
end

return plugin
