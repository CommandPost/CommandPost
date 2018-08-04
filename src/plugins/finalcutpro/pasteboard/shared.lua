--- === plugins.finalcutpro.pasteboard.shared ===
---
--- Shared Pasteboard Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                                       = require("hs.logger").new("sharedPasteboard")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local base64                                    = require("hs.base64")
local fs                                        = require("hs.fs")
local host                                      = require("hs.host")
local json                                      = require("hs.json")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config                                    = require("cp.config")
local dialog                                    = require("cp.dialog")
local fcp                                       = require("cp.apple.finalcutpro")
local tools                                     = require("cp.tools")
local i18n                                      = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local TOOLS_PRIORITY        = 2000
local HISTORY_EXTENSION     = ".cpSharedPasteboard"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

-- plugins.finalcutpro.pasteboard.shared._hostname -> string
-- Variable
-- The hostname.
mod._hostname = host.localizedName()

-- plugins.finalcutpro.pasteboard.shared.maxHistory -> number
-- Variable
-- The maximum number of items in the shared Pasteboard History.
mod.maxHistory = 5

--- plugins.finalcutpro.pasteboard.shared.enabled <cp.prop: boolean>
--- Field
--- Gets whether or not the shared pasteboard is enabled as a boolean.
mod.enabled = config.prop("enabledShardPasteboard", false)

--- plugins.finalcutpro.pasteboard.shared.getRootPath() -> string
--- Function
--- Get shared pasteboard root path.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Shared Pasteboard Path as string.
function mod.getRootPath()
    return config.get("sharedPasteboardPath", nil)
end

--- plugins.finalcutpro.pasteboard.shared.setRootPath(path) -> none
--- Function
--- Sets the shared pasteboard root path.
---
--- Parameters:
---  * path - The path you want to set as a string.
---
--- Returns:
---  * None
function mod.setRootPath(path)
    config.set("sharedPasteboardPath", path)
end

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
    return tools.doesDirectoryExist(mod.getRootPath())
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
    if name then
        log.df("Pasteboard updated. Adding '%s' to shared history.", name)

        local sharedPasteboardPath = mod.getRootPath()
        if sharedPasteboardPath ~= nil then

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
            while (#history >= mod.maxHistory) do
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
        if not mod.validRootPath() then
            -- Assign a new root path:
            local result = dialog.displayChooseFolder(i18n("sharedPasteboardRootFolder"))
            if result then
                mod.setRootPath(result)
            else
                mod.enabled(false)
            end
        end
        if mod.validRootPath() and not mod._watcherId then
            mod._watcherId = mod._manager.watch({
                update  = watchUpdate,
            })
        end
    end
    if not mod.enabled() then
        if mod._watcherId then
            mod._manager.unwatch(mod._watcherId)
            mod._watcherId = nil
        end
        mod.setRootPath(nil)
    end
end

--- plugins.finalcutpro.pasteboard.shared.update() -> table
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
    local rootPath = mod.getRootPath()
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
    return mod._hostname
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
    local menuBar = fcp:menu()
    if menuBar:isEnabled({"Edit", "Copy"}) then
        local result = dialog.displayTextBoxMessage(i18n("overrideClipNamePrompt"), i18n("overrideValueInvalid"), "")
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
    return mod.getRootPath() .. folderName .. fileExtension
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
    local history = {}

    local filePath = mod.getHistoryPath(folderName)
    local file = io.open(filePath, "r")
    if file then
        local content = file:read("*all")
        file:close()
        history = json.decode(content)
    end
    return history
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
        local file = io.open(filePath, "w")
        if file then
            file:write(json.encode(history))
            file:close()
            return true
        end
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
    local menuBar = fcp:menu()
    if menuBar:isEnabled({"Edit", "Copy"}) then
        local result = dialog.displayTextBoxMessage(i18n("overrideClipNamePrompt"), i18n("overrideValueInvalid"), "")
        if result == false then return end
        mod._manager.overrideNextClipName(result)

        result = dialog.displayTextBoxMessage(i18n("overrideFolderNamePrompt"), i18n("overrideValueInvalid"), "")
        if result == false then return end
        mod.overrideNextFolderName(result)

        menuBar:selectMenu({"Edit", "Copy"})
    end
end

--- plugins.finalcutpro.pasteboard.shared.pasteHistoryItem(folderName, index) -> none
--- Function
--- Paste History Item.
---
--- Parameters:
---  * folderName - The folder name
---  * index - The index of the item you want to paste
---
--- Returns:
---  * None
function mod.pasteHistoryItem(folderName, index)
    local item = mod.getHistory(folderName)[index]
    if item then
        --------------------------------------------------------------------------------
        -- Decode the data:
        --------------------------------------------------------------------------------
        local data = base64.decode(item.data)
        if not data then
            log.w("Unable to decode the item data for '%s' at %d.", folderName, index)
        end
        --------------------------------------------------------------------------------
        -- Put item back in the pasteboard quietly:
        --------------------------------------------------------------------------------
        mod._manager.writeFCPXData(data, true)

        --------------------------------------------------------------------------------
        -- Paste in FCPX:
        --------------------------------------------------------------------------------
        fcp:launch()
        if fcp:performShortcut("Paste") then
            return true
        else
            log.w("Failed to trigger the 'Paste' Shortcut.\n\nError occurred in pasteboard.history.pasteHistoryItem().")
        end
    end
    return false
end

--- plugins.finalcutpro.pasteboard.shared.init() -> sharedPasteboard
--- Function
--- Initialises the module.
---
--- Parameters:
---  * manager - The pasteboard manager
---
--- Returns:
---  * The sharedPasteboard object
function mod.init(manager)
    mod._manager = manager

    local setEnabledValue = false
    if mod.enabled() then
        if not mod.validRootPath() then
            local result = dialog.displayMessage(i18n("sharedPasteboardPathMissing"), {"Yes", "No"})
            if result == "Yes" then
                setEnabledValue = true
            end
        else
            setEnabledValue = true
        end
    end

    mod.enabled(setEnabledValue)
    mod.enabled:watch(mod.update)

    return mod
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
    if mod.enabled() and mod.validRootPath() then
        local fcpxRunning = fcp:isRunning()

        local sharedPasteboardFolderModified = fs.attributes(mod.getRootPath(), "modification")
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
                        table.insert(historyItems, {title = item.name, fn = function() mod.pasteHistoryItem(folder, i) end, disabled = not fcpxRunning})
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

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.pasteboard.shared",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.pasteboard.manager"]   = "manager",
        ["finalcutpro.commands"]            = "fcpxCmds",
        ["finalcutpro.menu.pasteboard"]      = "menu",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Initialise Module:
    --------------------------------------------------------------------------------
    mod.init(deps.manager)

    --------------------------------------------------------------------------------
    -- Generate Menu Cache:
    --------------------------------------------------------------------------------
    mod.generateSharedPasteboardMenu()

    --------------------------------------------------------------------------------
    -- Add menu items:
    --------------------------------------------------------------------------------
    deps.menu
      :addMenu(TOOLS_PRIORITY, function() return i18n("sharedPasteboardHistory") end)
      :addItem(1000, function()
          return { title = i18n("enableSharedPasteboard"), fn = function() mod.enabled:toggle() end, checked = mod.enabled() and mod.validRootPath() }
      end)
      :addSeparator(2000)
      :addItems(3000, mod.generateSharedPasteboardMenu)

    --------------------------------------------------------------------------------
    -- Commands:
    --------------------------------------------------------------------------------
    deps.fcpxCmds
      :add("cpCopyWithCustomLabelAndFolder")
      :whenActivated(mod.copyWithCustomClipNameAndFolder)

    return mod
end

return plugin
