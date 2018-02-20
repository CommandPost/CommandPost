--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                  B A T C H    E X P O R T    P L U G I N                   --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.export.batch ===
---
--- Batch Export Plugin

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log           = require("hs.logger").new("batch")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local fnutils       = require("hs.fnutils")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils       = require("cp.ui.axutils")
local compressor    = require("cp.apple.compressor")
local config        = require("cp.config")
local dialog        = require("cp.dialog")
local fcp           = require("cp.apple.finalcutpro")
local just          = require("cp.just")
local tools         = require("cp.tools")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY = 2000

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

-- plugins.finalcutpro.export.batch._existingClipNames -> table
-- Variable
-- Table of existing clip names.
mod._existingClipNames = {}

--- plugins.finalcutpro.export.batch.replaceExistingFiles <cp.prop: boolean>
--- Field
--- Defines whether or not a Batch Export should Replace Existing Files.
mod.replaceExistingFiles = config.prop("batchExportReplaceExistingFiles", false)

--- plugins.finalcutpro.export.batch.useCustomFilename <cp.prop: boolean>
--- Field
--- Defines whether or not the Batch Export tool should override the clipname with a custom filename.
mod.useCustomFilename = config.prop("batchExportOverrideClipnameWithCustomFilename", false)

--- plugins.finalcutpro.export.batch.customFilename <cp.prop: string>
--- Field
--- Custom Filename for Batch Export.
mod.customFilename = config.prop("batchExportCustomFilename", i18n("batchExport"))

--- plugins.finalcutpro.export.batch.ignoreMissingEffects <cp.prop: boolean>
--- Field
--- Defines whether or not a Batch Export should Ignore Missing Effects.
mod.ignoreMissingEffects = config.prop("batchExportIgnoreMissingEffects", false)

--- plugins.finalcutpro.export.batch.ignoreProxies <cp.prop: boolean>
--- Field
--- Defines whether or not a Batch Export should Ignore Proxies.
mod.ignoreProxies = config.prop("batchExportIgnoreProxies", false)

-- selectShare() -> boolean
-- Function
-- Select Share Destination from the Final Cut Pro Menubar
--
-- Parameters:
--  * None
--
-- Returns:
--  * `true` if successful otherwise `false`
local function selectShare(destinationPreset)
    return fcp:menuBar():selectMenu({"File", "Share", function(menuItem)
        if destinationPreset == nil then
            return menuItem:attributeValue("AXMenuItemCmdChar") ~= nil
        else
            local title = menuItem:attributeValue("AXTitle")
            return title and string.find(title, destinationPreset, 1, true) ~= nil
        end
    end})
end

-- sendClipsToCompressor(libraries, clips, exportPath, destinationPreset, replaceExisting) -> boolean
-- Function
-- Send Clips to Compressor
--
-- Parameters:
--  * libraries - selected Library
--  * clips - table of selected Clips
--  * exportPath - Export Path as `string`
--  * destinationPreset - Destination Preset as `string`
--  * replaceExisting - `true` if you want to replace existing files otherwise `false`
--
-- Returns:
--  * `true` if successful otherwise `false`
local function sendClipsToCompressor(libraries, clips, exportPath, destinationPreset, replaceExisting)

    --------------------------------------------------------------------------------
    -- Launch Compressor:
    --------------------------------------------------------------------------------
    if not compressor:isRunning() then
        local result = just.doUntil(function()
            compressor:launch()
            return compressor:isFrontmost()
        end, 10, 0.1)
        if not result then
            dialog.displayErrorMessage("Failed to Launch Compressor.")
            return false
        end
    end

    for _,clip in ipairs(clips) do

        --------------------------------------------------------------------------------
        -- Make sure Final Cut Pro is Active:
        --------------------------------------------------------------------------------
        local result = just.doUntil(function()
            fcp:launch()
            return fcp:isFrontmost()
        end, 10, 0.1)
        if not result then
            dialog.displayErrorMessage("Failed to switch back to Final Cut Pro.\n\nThis shouldn't happen.")
            return false
        end

        --------------------------------------------------------------------------------
        -- Select Item:
        --------------------------------------------------------------------------------
        libraries:selectClip(clip)

        --------------------------------------------------------------------------------
        -- Make sure the Library is selected:
        --------------------------------------------------------------------------------
        if not fcp:menuBar():selectMenu({"Window", "Go To", "Libraries"}) then
            dialog.displayErrorMessage("Could not trigger 'Go To Libraries'.")
            return false
        end

        --------------------------------------------------------------------------------
        -- Trigger Export:
        --------------------------------------------------------------------------------
        if not fcp:menuBar():selectMenu({"File", "Send to Compressor"}) then
            dialog.displayErrorMessage("Could not trigger 'Send to Compressor'.")
            return false
        end

    end
    return true

end

-- batchExportClips(libraries, clips, exportPath, destinationPreset, replaceExisting) -> boolean
-- Function
-- Batch Export Clips
--
-- Parameters:
--  * libraries - selected Library
--  * clips - table of selected Clips
--  * exportPath - Export Path as `string`
--  * destinationPreset - Destination Preset as `string`
--  * replaceExisting - `true` if you want to replace existing files otherwise `false`
--
-- Returns:
--  * `true` if successful otherwise `false`
local function batchExportClips(libraries, clips, exportPath, destinationPreset, replaceExisting)

    local errorFunction = " Error occurred in batchExportClips()."
    local firstTime = true
    for _,clip in ipairs(clips) do

        --------------------------------------------------------------------------------
        -- Select Item:
        --------------------------------------------------------------------------------
        libraries:selectClip(clip)

        --------------------------------------------------------------------------------
        -- Trigger Export:
        --------------------------------------------------------------------------------
        if not selectShare(destinationPreset) then
            dialog.displayErrorMessage("Could not trigger Share Menu Item." .. errorFunction)
            return false
        end

        --------------------------------------------------------------------------------
        -- Wait for Export Dialog to open:
        --------------------------------------------------------------------------------
        local exportDialog = fcp:exportDialog()

        --------------------------------------------------------------------------------
        -- Handle this dialog box:
        --
        -- This project is currently set to use proxy media.
        -- FFShareProxyPlaybackEnabledMessageText
        --------------------------------------------------------------------------------
        if not just.doUntil(function() return exportDialog:isShowing() end) then
            local triggerError = true
            local windowUIs = fcp:windowsUI()
            if windowUIs then
                for _, windowUI in pairs(windowUIs) do
                    local sheets = axutils.childrenWithRole(windowUI, "AXSheet")
                    if sheets then
                        for _, sheet in pairs(sheets) do
                            local continueButton = axutils.childWith(sheet, "AXTitle", fcp:string("FFMissingMediaDefaultButtonText"))
                            if axutils.childrenMatching(sheet, function(child)
                                if child:attributeValue("AXStaticText") and child:attributeValue("AXStaticText") == fcp:strings("FFShareProxyPlaybackEnabledMessageText") then
                                    return child
                                end
                            end) and continueButton then
                                if mod.ignoreProxies() then
                                    --------------------------------------------------------------------------------
                                    -- Press the 'Continue' button:
                                    --------------------------------------------------------------------------------
                                    local result = continueButton:performAction("AXPress")
                                    if result ~= nil then
                                        triggerError = false
                                    end
                                else
                                    dialog.displayErrorMessage("Proxy files were detected, which has aborted the Batch Export.\n\nProxy files can be ignored via the Batch Export settings if required.")
                                    return false
                                end
                            end
                        end
                    end
                end
            end
            if triggerError then
                dialog.displayErrorMessage("Failed to open the 'Export' window." .. errorFunction)
                return false
            end
        end

        --------------------------------------------------------------------------------
        -- Handle this dialog box:
        --
        -- “%@” has missing or offline titles, effects, generators, or media.
        -- FFMissingMediaMessageText
        --------------------------------------------------------------------------------
        if not just.doUntil(function() return exportDialog:isShowing() end) then
            local triggerError = true
            local windowUIs = fcp:windowsUI()
            if windowUIs then
                for _, windowUI in pairs(windowUIs) do
                    local sheets = axutils.childrenWithRole(windowUI, "AXSheet")
                    if sheets then
                        for _, sheet in pairs(sheets) do
                            local continueButton = axutils.childWith(sheet, "AXTitle", fcp:string("FFMissingMediaDefaultButtonText"))
                            if axutils.childrenMatching(sheet, function(child)
                                if child:attributeValue("AXStaticText") and string.gsub(child:attributeValue("AXStaticText"), [[“%@” ]], "") == fcp:strings("FFMissingMediaMessageText") then
                                    return child
                                end
                            end) and continueButton then
                                if mod.ignoreMissingEffects() then
                                    --------------------------------------------------------------------------------
                                    -- Press the 'Continue' button:
                                    --------------------------------------------------------------------------------
                                    local result = continueButton:performAction("AXPress")
                                    if result ~= nil then
                                        triggerError = false
                                    end
                                else
                                    dialog.displayErrorMessage("Missing or offline titles, effects or generators were detected, which has aborted the Batch Export.\n\nMissing & Offline Effects can be ignored via the Batch Export settings if required.")
                                    return false
                                end
                            end
                        end
                    end
                end
            end
            if triggerError then
                dialog.displayErrorMessage("Failed to open the 'Export' window." .. errorFunction)
                return false
            end
        end
        exportDialog:pressNext()

        --------------------------------------------------------------------------------
        -- If 'Next' has been clicked (as opposed to 'Share'):
        --------------------------------------------------------------------------------
        local saveSheet = exportDialog:saveSheet()
        if exportDialog:isShowing() then

            --------------------------------------------------------------------------------
            -- Click 'Save' on the save sheet:
            --------------------------------------------------------------------------------
            if not just.doUntil(function() return saveSheet:isShowing() end) then
                dialog.displayErrorMessage("Failed to open the 'Save' window." .. errorFunction)
                return false
            end

            --------------------------------------------------------------------------------
            -- Set Custom Export Path (or Default to Desktop):
            --------------------------------------------------------------------------------
            if firstTime then
                saveSheet:setPath(exportPath)
                firstTime = false
            end

            --------------------------------------------------------------------------------
            -- Make sure we don't already have a clip with the same name in the batch:
            --------------------------------------------------------------------------------
            local filename = saveSheet:filename():getValue()
            if filename then
                local newFilename = filename

                --------------------------------------------------------------------------------
                -- Inject Custom Filenames:
                --------------------------------------------------------------------------------
                local customFilename = mod.customFilename()
                local useCustomFilename = mod.useCustomFilename()
                if useCustomFilename and customFilename then
                    newFilename = customFilename
                end

                while fnutils.contains(mod._existingClipNames, newFilename) do
                    newFilename = tools.incrementFilename(newFilename)
                end
                if filename ~= newFilename then
                    saveSheet:filename():setValue(newFilename)
                end
                table.insert(mod._existingClipNames, newFilename)
            end

            --------------------------------------------------------------------------------
            -- Click 'Save' on the save sheet:
            --------------------------------------------------------------------------------
            saveSheet:pressSave()

        end

        --------------------------------------------------------------------------------
        -- Make sure Save Window is closed:
        --------------------------------------------------------------------------------
        while saveSheet:isShowing() do
            local replaceAlert = saveSheet:replaceAlert()
            if replaceExisting and replaceAlert:isShowing() then
                replaceAlert:pressReplace()
            else
                replaceAlert:pressCancel()

                local originalFilename = saveSheet:filename():getValue()
                if originalFilename == nil then
                    dialog.displayErrorMessage("Failed to get the original Filename." .. errorFunction)
                    return false
                end

                local newFilename = tools.incrementFilename(originalFilename)

                saveSheet:filename():setValue(newFilename)
                saveSheet:pressSave()
            end
        end

    end
    return true
end

--- plugins.finalcutpro.export.batch.changeExportDestinationPreset() -> boolean
--- Function
--- Change Export Destination Preset.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if successful otherwise `false`
function mod.changeExportDestinationPreset()

    if not fcp:isRunning() then
        dialog.displayMessage(i18n("batchExportFinalCutProClosed"))
        return false
    end

    local shareMenuItems = fcp:menuBar():findMenuItemsUI({"File", "Share"})
    if not shareMenuItems then
        dialog.displayErrorMessage(i18n("batchExportDestinationsNotFound"))
        return false
    end

    local destinations = {}

    if compressor:isInstalled() then
        destinations[#destinations + 1] = i18n("sendToCompressor")
    end

    for i = 1, #shareMenuItems-2 do
        local item = shareMenuItems[i]
        local title = item:attributeValue("AXTitle")
        if title ~= nil then
            local value = string.sub(title, 1, -4)
            --------------------------------------------------------------------------------
            -- It's the default:
            --------------------------------------------------------------------------------
            if item:attributeValue("AXMenuItemCmdChar") then
                --------------------------------------------------------------------------------
                -- Remove (default) text:
                --------------------------------------------------------------------------------
                local firstBracket = string.find(value, " %(", 1)
                if firstBracket == nil then
                    firstBracket = string.find(value, "（", 1)
                end
                value = string.sub(value, 1, firstBracket - 1)
            end
            destinations[#destinations + 1] = value
        end
    end

    local batchExportDestinationPreset = config.get("batchExportDestinationPreset")
    local defaultItems = {}
    if batchExportDestinationPreset ~= nil then defaultItems[1] = batchExportDestinationPreset end

    local result = dialog.displayChooseFromList(i18n("selectDestinationPreset"), destinations, defaultItems)
    if result and #result > 0 then
        config.set("batchExportDestinationPreset", result[1])
    end

    return true
end

--- plugins.finalcutpro.export.batch.changeExportDestinationFolder() -> boolean
--- Function
--- Change Export Destination Folder.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if successful otherwise `false`
function mod.changeExportDestinationFolder()
    local result = dialog.displayChooseFolder(i18n("selectDestinationFolder"))
    if result == false then return false end
    config.set("batchExportDestinationFolder", result)
    return true
end

--- plugins.finalcutpro.export.batch.batchExport() -> boolean
--- Function
--- Batch Export.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if successful otherwise `false`
function mod.batchExport()

    --------------------------------------------------------------------------------
    -- Reset Existing Clip Names:
    --------------------------------------------------------------------------------
    mod._existingClipNames = nil
    mod._existingClipNames = {}

    --------------------------------------------------------------------------------
    -- Set Custom Export Path (or Default to Desktop):
    --------------------------------------------------------------------------------
    local batchExportDestinationFolder = config.get("batchExportDestinationFolder")
    local NSNavLastRootDirectory = fcp:getPreference("NSNavLastRootDirectory")
    local exportPath = "~/Desktop"
    if batchExportDestinationFolder ~= nil then
         if tools.doesDirectoryExist(batchExportDestinationFolder) then
            exportPath = batchExportDestinationFolder
         end
    else
        if tools.doesDirectoryExist(NSNavLastRootDirectory) then
            exportPath = NSNavLastRootDirectory
        end
    end

    --------------------------------------------------------------------------------
    -- Destination Preset:
    --------------------------------------------------------------------------------
    local destinationPreset = config.get("batchExportDestinationPreset")

    if destinationPreset == i18n("sendToCompressor") then
        if not compressor:isInstalled() then
            log.df("Apple Compressor could not be detected.")
            destinationPreset = nil
            config.set("batchExportDestinationPreset", nil)
        end
    end

    if destinationPreset == nil then

        local defaultItem = fcp:menuBar():findMenuUI({"File", "Share", function(menuItem)
            return menuItem:attributeValue("AXMenuItemCmdChar") ~= nil
        end})

        if defaultItem == nil then
            dialog.displayErrorMessage(i18n("batchExportNoDestination"))
            return false
        else
            -- Trim the trailing '(default)…'
            destinationPreset = defaultItem:attributeValue("AXTitle"):match("(.*) %([^()]+%)…$")
        end

    end

    --------------------------------------------------------------------------------
    -- Replace Existing Files Option:
    --------------------------------------------------------------------------------
    local replaceExisting = mod.replaceExistingFiles()

    local libraries = fcp:browser():libraries()

    if not libraries:isShowing() then
        dialog.displayErrorMessage(i18n("batchExportEnableBrowser"))
        return false
    end

    --------------------------------------------------------------------------------
    -- Check if we have any currently-selected clips:
    --------------------------------------------------------------------------------
    local clips = libraries:selectedClips()

    if libraries:sidebar():isFocused() then
        --------------------------------------------------------------------------------
        -- Use All Clips:
        --------------------------------------------------------------------------------
        clips = libraries:clips()
    end

    local batchExportSucceeded
    if clips and #clips > 0 then

        --------------------------------------------------------------------------------
        -- Display Dialog:
        --------------------------------------------------------------------------------
        local countText = " "
        if #clips > 1 then countText = " " .. tostring(#clips) .. " " end
        local replaceFilesMessage
        if replaceExisting then
            replaceFilesMessage = i18n("batchExportReplaceYes")
        else
            replaceFilesMessage = i18n("batchExportReplaceNo")
        end
        local result = dialog.displayMessage(i18n("batchExportCheckPath", {count=countText, replace=replaceFilesMessage, path=exportPath, preset=destinationPreset, item=i18n("item", {count=#clips})}), {i18n("continue") .. " " .. i18n("batchExport"), i18n("cancel")})
        if result == nil then return end

        --------------------------------------------------------------------------------
        -- Export the clips:
        --------------------------------------------------------------------------------
        if destinationPreset == i18n("sendToCompressor") then
            batchExportSucceeded = sendClipsToCompressor(libraries, clips, exportPath, destinationPreset, replaceExisting)
        else
            batchExportSucceeded = batchExportClips(libraries, clips, exportPath, destinationPreset, replaceExisting)
        end

    else
        --------------------------------------------------------------------------------
        -- No Clips are Available:
        --------------------------------------------------------------------------------
        dialog.displayErrorMessage(i18n("batchExportNoClipsSelected"))
        return false
    end

    --------------------------------------------------------------------------------
    -- Batch Export Complete:
    --------------------------------------------------------------------------------
    if batchExportSucceeded then
        dialog.displayMessage(i18n("batchExportComplete"), {i18n("done")})
        return true
    end

    --------------------------------------------------------------------------------
    -- Shouldn't ever get to this point:
    --------------------------------------------------------------------------------
    return false

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.export.batch",
    group           = "finalcutpro",
    dependencies    = {
        ["core.menu.manager"]               = "manager",
        ["finalcutpro.menu.tools"]          = "prefs",
        ["finalcutpro.commands"]            = "fcpxCmds",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Add items to Menubar:
    --------------------------------------------------------------------------------
    local section = deps.prefs:addSection(PRIORITY)
    local menu = section:addMenu(1000, function() return i18n("batchExport") end)
    menu:addItems(1, function()
        return {
            { title = i18n("performBatchExport"),   fn = function()

                --------------------------------------------------------------------------------
                -- Make sure Final Cut Pro is Active:
                --------------------------------------------------------------------------------
                local result = just.doUntil(function()
                    fcp:launch()
                    return fcp:isFrontmost()
                end, 10, 0.1)
                if not result then
                    dialog.displayErrorMessage("Failed to switch back to Final Cut Pro.\n\nThis shouldn't happen.")
                    return false
                end

                mod.batchExport()
            end, disabled=not fcp:isRunning() },
            { title = "-" },
            { title = i18n("setDestinationPreset"), fn = mod.changeExportDestinationPreset },
            { title = i18n("setDestinationFolder"), fn = mod.changeExportDestinationFolder },
            { title = "-" },
            { title = i18n("replaceExistingFiles"), fn = function() mod.replaceExistingFiles:toggle() end, checked = mod.replaceExistingFiles() },
            { title = i18n("ignoreMissingEffects"), fn = function() mod.ignoreMissingEffects:toggle() end, checked = mod.ignoreMissingEffects() },
            { title = i18n("ignoreProxies"), fn = function() mod.ignoreProxies:toggle() end, checked = mod.ignoreProxies() },
            { title = "-" },
            { title = string.upper(i18n("customFilename")) .. ": " .. mod.customFilename(), disabled = true },
            { title = "-" },
            { title = i18n("useCustomFilename"), fn = function() mod.useCustomFilename:toggle() end, checked = mod.useCustomFilename() },
            { title = i18n("setCustomFilename"), fn = function()
                local result = mod.customFilename(dialog.displayTextBoxMessage(i18n("enterCustomFilename") .. ":", i18n("enterCustomFilenameError"), mod.customFilename(), function(value)
                    if value and type("value") == "string" and value ~= tools.trim("") and tools.safeFilename(value, value) == value then
                        return true
                    else
                        return false
                    end
                end))
                if type(result) == "string" then
                    mod.customFilename(result)
                end
            end },
        }
    end)

    --------------------------------------------------------------------------------
    -- Commands:
    --------------------------------------------------------------------------------
    deps.fcpxCmds:add("cpBatchExportFromBrowser")
        :activatedBy():ctrl():option():cmd("e")
        :whenActivated(mod.batchExport)

    --------------------------------------------------------------------------------
    -- Return the module:
    --------------------------------------------------------------------------------
    return mod
end

return plugin
