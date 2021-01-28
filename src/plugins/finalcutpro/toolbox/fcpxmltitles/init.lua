--- === plugins.finalcutpro.toolbox.fcpxmltitles ===
---
--- FCPXML Titles Toolbox Panel

local require                   = require

local log                       = require "hs.logger".new "fcpxmltitles"

local dialog                    = require "hs.dialog"
local image                     = require "hs.image"
local inspect                   = require "hs.inspect"

local config                    = require "cp.config"
local fcp                       = require "cp.apple.finalcutpro"
local fcpxml                    = require "cp.apple.fcpxml"
local i18n                      = require "cp.i18n"
local tools                     = require "cp.tools"

local csv                       = require "csv"
local xml                       = require "hs._asm.xml"

local chooseFileOrFolder        = dialog.chooseFileOrFolder
local dirFiles                  = tools.dirFiles
local doesDirectoryExist        = tools.doesDirectoryExist
local getFilenameFromPath       = tools.getFilenameFromPath
local removeFilenameFromPath    = tools.removeFilenameFromPath
local spairs                    = tools.spairs
local tableCount                = tools.tableCount
local trim                      = tools.trim
local webviewAlert              = dialog.webviewAlert
local writeToFile               = tools.writeToFile

local mod = {}

-- data -> table
-- Variable
-- Stores both the processed FCPXML and CSV data:
local data = {}

-- count -> number
-- Variable
-- Counter used when getting titles.
local count = 1

-- updateTitlesCount -> number
-- Variable
-- Counter used when updating titles.
local updateTitlesCount = 1

-- xmlPath -> string
-- Variable
-- FCPXML Path
local xmlPath

-- originalFilename -> string
-- Variable
-- Original FCPXML Filename. Used to populate export filename.
local originalFilename

-- csvLoaded -> boolean
-- Variable
-- Is a CSV file currently loaded?
local csvLoaded = false

-- fcpxmlLoaded -> boolean
-- Variable
-- Is a FCPXML file currently loaded?
local fcpxmlLoaded = false

-- desktopPath -> string
-- Constant
-- Path to the users desktop
local desktopPath = os.getenv("HOME") .. "/Desktop/"

--- plugins.finalcutpro.toolbox.fcpxmltitles.ignoreFirstRow <cp.prop: boolean>
--- Field
--- Ignore first row of CSV?
mod.ignoreFirstRow = config.prop("toolbox.fcpxmltitles.ignoreFirstRow", true)

--- plugins.finalcutpro.toolbox.fcpxmltitles.sentToFinalCutPro <cp.prop: boolean>
--- Field
--- Send to Final Cut Pro
mod.sentToFinalCutPro = config.prop("toolbox.fcpxmltitles.sentToFinalCutPro", true)

--- plugins.finalcutpro.toolbox.fcpxmltitles.trimWhiteSpace <cp.prop: boolean>
--- Field
--- Trim White Space
mod.trimWhiteSpace = config.prop("toolbox.fcpxmltitles.trimWhiteSpace", true)

--- plugins.finalcutpro.toolbox.fcpxmltitles.removeLineBreaks <cp.prop: boolean>
--- Field
--- Remove Line Breaks
mod.removeLineBreaks = config.prop("toolbox.fcpxmltitles.removeLineBreaks", true)

--- plugins.finalcutpro.toolbox.fcpxmltitles.originalTitleColumn <cp.prop: string>
--- Field
--- Original Title Column
mod.originalTitleColumn = config.prop("toolbox.fcpxmltitles.originalTitleColumn", "1")

--- plugins.finalcutpro.toolbox.fcpxmltitles.newTitleColumn <cp.prop: string>
--- Field
--- New Title Column
mod.newTitleColumn = config.prop("toolbox.fcpxmltitles.newTitleColumn", "3")

--- plugins.finalcutpro.toolbox.fcpxmltitles.lastBatchProcessPath <cp.prop: string>
--- Field
--- Last Batch Process Path
mod.lastBatchProcessPath = config.prop("toolbox.fcpxmltitles.lastBatchProcessPath", desktopPath)

--- plugins.finalcutpro.toolbox.fcpxmltitles.lastFCPXMLPath <cp.prop: string>
--- Field
--- Last FCPXMLPath
mod.lastFCPXMLPath = config.prop("toolbox.fcpxmltitles.lastFCPXMLPath", desktopPath)

--- plugins.finalcutpro.toolbox.fcpxmltitles.lastFCPXMLPath <cp.prop: string>
--- Field
--- Last FCPXMLPath
mod.lastCSVPath = config.prop("toolbox.fcpxmltitles.lastCSVPath", desktopPath)

--- plugins.finalcutpro.toolbox.fcpxmltitles.lastExportFCPXMLPath <cp.prop: string>
--- Field
--- Last Export Path
mod.lastExportFCPXMLPath = config.prop("toolbox.fcpxmltitles.lastExportFCPXMLPath", desktopPath)

--- plugins.finalcutpro.toolbox.fcpxmltitles.lastExportCSVPath <cp.prop: string>
--- Field
--- Last Export CSV Path
mod.lastExportCSVPath = config.prop("toolbox.fcpxmltitles.lastExportCSVPath", desktopPath)

-- renderPanel(context) -> none
-- Function
-- Generates the Preference Panel HTML Content.
--
-- Parameters:
--  * context - Table of data that you want to share with the renderer
--
-- Returns:
--  * HTML content as string
local function renderPanel(context)
    if not mod._renderPanel then
        local err
        mod._renderPanel, err = mod._env:compileTemplate("html/panel.html")
        if err then
            error(err)
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
    local context = {
        i18n = i18n,
    }
    return renderPanel(context)
end

-- updateUI() -> none
-- Function
-- Update the UI
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function updateUI()
    local injectScript = mod._manager.injectScript

    local originalTitleColumn = mod.originalTitleColumn()
    local newTitleColumn = mod.newTitleColumn()

    local script = [[
        changeValueByID("originalTitleColumn", "]] .. originalTitleColumn .. [[");
        changeValueByID("newTitleColumn", "]] .. newTitleColumn .. [[");
        changeCheckedByID("trimWhiteSpace", ]] .. tostring(mod.trimWhiteSpace()) .. [[);
        changeCheckedByID("removeLineBreaks", ]] .. tostring(mod.removeLineBreaks()) .. [[);
        changeCheckedByID("sentToFinalCutPro", ]] .. tostring(mod.sentToFinalCutPro()) .. [[);
        changeCheckedByID("ignoreFirstRow", ]] .. tostring(mod.ignoreFirstRow()) .. [[);
    ]]

    if tableCount(data) == 0 then
        script = script .. [[
            document.getElementById("editorBody").innerHTML = "<tr><td>]] .. i18n("nothingLoaded") .. [[.</td></tr>";
        ]]
    else
        local rows = ""
        for i, v in spairs(data) do
            rows = rows .. [[
                <tr>
                    <td><input type="text" value="]] .. v.original .. [[" disabled></td>
                    <td><input type="text" value="]] .. v.new .. [[" onchange="updateNew(this, ]] .. i .. [[)"></td>
                </tr>
            ]]
        end

        script = script .. [[
            document.getElementById("editorBody").innerHTML = `]] .. rows .. [[`
        ]]
    end

    injectScript(script)
end

-- getTitles(nodes) -> none
-- Function
-- Adds any titles to the existing `data` table.
--
-- Parameters:
--  * nodes - A table of XML nodes.
--
-- Returns:
--  * None
local function getTitles(nodes)
    if nodes then
        for _, node in pairs(nodes) do
            local name = node:name()
            if name == "spine" or name == "gap" or name == "asset-clip" then
                getTitles(node:children())
            elseif name == "title" then
                local nodeChildren = node:children()
                for _, nodeChild in pairs(nodeChildren) do
                    if nodeChild:name() == "text" then
                        local textStyles = nodeChild:children()
                        if textStyles then
                            for _, textStyle in pairs(textStyles) do
                                local originalValue = textStyle:stringValue()
                                if originalValue then
                                    if mod.trimWhiteSpace() then
                                        originalValue = originalValue and trim(originalValue)
                                    end
                                    if mod.removeLineBreaks() then
                                        originalValue = originalValue and string.gsub(originalValue, "\n", "")
                                    end
                                end
                                data[count] = {
                                    original = originalValue,
                                    new = "",
                                }
                                count = count + 1
                            end
                        end
                    end
                end
            end
        end
    end
end

-- updateTitles(nodes) -> none
-- Function
-- Updates titles.
--
-- Parameters:
--  * nodes - A table of XML nodes.
--
-- Returns:
--  * errorLog - A string containing any errors
local function updateTitles(nodes, errorLog)
    if nodes then
        for _, node in pairs(nodes) do
            local name = node:name()
            if name == "spine" or name == "gap" or name == "asset-clip" then
                updateTitles(node:children(), errorLog)
            elseif name == "title" then
                local newValue = nil
                local nodeChildren = node:children()
                for _, nodeChild in pairs(nodeChildren) do
                    if nodeChild:name() == "text" then
                        local textStyles = nodeChild:children()
                        if textStyles then
                            for _, textStyle in pairs(textStyles) do
                                local originalValue = textStyle:stringValue()

                                if originalValue then
                                    if mod.trimWhiteSpace() then
                                        originalValue = originalValue and trim(originalValue)
                                    end
                                    if mod.removeLineBreaks() then
                                        originalValue = originalValue and string.gsub(originalValue, "\n", "")
                                    end
                                end

                                if data[updateTitlesCount] and data[updateTitlesCount].original then
                                    if data[updateTitlesCount].original == originalValue then
                                        newValue = data[updateTitlesCount].new
                                    end
                                end

                                --------------------------------------------------------------------------------
                                -- Backup plan if CSV file is out of order for some reason:
                                --------------------------------------------------------------------------------
                                if not newValue then
                                    for _, v in pairs(data) do
                                        if v.original == originalValue then
                                            newValue = v.new
                                            break
                                        end
                                    end
                                end

                                if newValue and newValue ~= "" then
                                    textStyle:setStringValue(newValue)
                                else
                                    errorLog = errorLog .. " * " .. originalValue .. "\n"
                                end

                                updateTitlesCount = updateTitlesCount + 1

                            end
                        end
                    end
                end
                if newValue then
                    local rawAttributes = node:rawAttributes()
                    for _, rawAttribute in pairs(rawAttributes) do
                        if rawAttribute:name() == "name" then
                            rawAttribute:setStringValue(newValue)
                        end
                    end
                end

            end
        end
    end
    return errorLog
end

-- reset() -> none
-- Function
-- Resets all the stored values and reloads the UI.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function reset()
    data = {}
    count = 1

    xmlPath = nil
    originalFilename = nil

    csvLoaded = false
    fcpxmlLoaded = false

    updateUI()
end

-- processCSV(csvData) -> none
-- Function
-- Process a CSV file into data table.
--
-- Parameters:
--  * csvData - The CSV data to process.
--
-- Returns:
--  * None
local function processCSV(csvData)
    local originalTitleColumn = tonumber(mod.originalTitleColumn())
    local newTitleColumn = tonumber(mod.newTitleColumn())

    local lookup = {}
    local orderedLookup = {}

    local firstLine = mod.ignoreFirstRow()
    local csvCount = 1
    for fields in csvData:lines() do
        if firstLine then
            firstLine = false
        else
            local original = fields[originalTitleColumn]
            local new = fields[newTitleColumn]
            if original and new then
                if mod.trimWhiteSpace() then
                    original = original and trim(original)
                    new = new and trim(new)
                end
                if mod.removeLineBreaks() then
                    original = original and string.gsub(original, "\n", "")
                    new = new and string.gsub(new, "\n", "")
                end
                lookup[original] = new
                orderedLookup[csvCount] = {}
                orderedLookup[csvCount].new = new
                orderedLookup[csvCount].original = original
            end
            csvCount = csvCount + 1
        end
    end

    for i, v in spairs(data) do
        if orderedLookup[i] and orderedLookup[i].original and orderedLookup[i].new and orderedLookup[i].original == v.original then
            data[i].new = orderedLookup[i].new or ""
        else
            if lookup[v.original] then
                data[i].new = lookup[v.original]
            else
                data[i].new = ""
            end
        end
    end
end

-- callback() -> none
-- Function
-- JavaScript Callback for the Panel
--
-- Parameters:
--  * id - ID as string
--  * params - Table of paramaters
--
-- Returns:
--  * None
local function callback(id, params)
    local callbackType = params and params["type"]
    if callbackType then
        if callbackType == "loadFCPXMLTemplate" then
            --------------------------------------------------------------------------------
            -- Load FCPXML Template:
            --------------------------------------------------------------------------------
            if not doesDirectoryExist(mod.lastFCPXMLPath()) then
                mod.lastFCPXMLPath(desktopPath)
            end
            local result = chooseFileOrFolder(i18n("pleaseSelectAFCPXMLTemplate") .. ":", mod.lastFCPXMLPath(), true, false, false, {"fcpxml"}, true)
            local path = result and result["1"]
            if path then
                if fcpxml.valid(path) then
                    mod.lastFCPXMLPath(removeFilenameFromPath(path))
                    xmlPath = path
                    originalFilename = getFilenameFromPath(path, true)

                    data = {} -- Reset data.
                    count = 1 -- Reset count.

                    local document = xml.open(path)
                    local spine = document:XPathQuery("/fcpxml[1]/library[1]/event[1]/project[1]/sequence[1]/spine[1]")
                    local spineChildren = spine and spine[1] and spine[1]:children()
                    getTitles(spineChildren)

                    fcpxmlLoaded = true
                    updateUI()
                else
                    webviewAlert(mod._manager.getWebview(), function() end, i18n("invalidFCPXMLFile"), i18n("theSuppliedFCPXMLDidNotPassDtdValidationPleaseCheckThatTheFCPXMLSuppliedIsValidAndTryAgain"), i18n("ok"), nil, "warning")
                end
            end
         elseif callbackType == "dropbox" then
            ---------------------------------------------------
            -- Make CommandPost active:
            ---------------------------------------------------
            hs.focus()

            ---------------------------------------------------
            -- Get value from UI:
            ---------------------------------------------------
            local value = params["value"] or ""
            local path = os.tmpname() .. ".fcpxml"

            ---------------------------------------------------
            -- Write the FCPXML data to a temporary file:
            ---------------------------------------------------
            writeToFile(path, value)

            ---------------------------------------------------
            -- Process the FCPXML:
            ---------------------------------------------------
            if fcpxml.valid(path) then
                xmlPath = path
                originalFilename = "Dragged FCPXML"

                data = {} -- Reset data.
                count = 1 -- Reset count.

                local document = xml.open(path)
                local spine = document:XPathQuery("/fcpxml[1]/project[1]/sequence[1]/spine[1]")
                local spineChildren = spine and spine[1] and spine[1]:children()
                getTitles(spineChildren)

                fcpxmlLoaded = true
                updateUI()
            else
                webviewAlert(mod._manager.getWebview(), function() end, i18n("invalidFCPXMLFile"), i18n("theSuppliedFCPXMLDidNotPassDtdValidationPleaseCheckThatTheFCPXMLSuppliedIsValidAndTryAgain"), i18n("ok"), nil, "warning")
            end
        elseif callbackType == "loadCSVData" then
            --------------------------------------------------------------------------------
            -- Load CSV Data:
            --------------------------------------------------------------------------------
            if not doesDirectoryExist(mod.lastCSVPath()) then
                mod.lastCSVPath(desktopPath)
            end
            local result = chooseFileOrFolder(i18n("pleaseSelectACSVFile") .. ":", mod.lastCSVPath(), true, false, false, {"csv"}, true)
            local path = result and result["1"]
            if path then
                mod.lastCSVPath(removeFilenameFromPath(path))
                local csvData = csv.open(path)
                if not csvData then
                    webviewAlert(mod._manager.getWebview(), function() end, i18n("failedToProcessTheCSVFile"), i18n("pleaseCheckTheContentsOfTheCSVFileAndTryAgain"), i18n("ok"), nil, "warning")
                    return
                end

                local originalTitleColumn = tonumber(mod.originalTitleColumn())
                local newTitleColumn = tonumber(mod.newTitleColumn())
                if originalTitleColumn == newTitleColumn then
                    webviewAlert(mod._manager.getWebview(), function() end, i18n("invalidColumnsSelected"), i18n("theOriginalAndNewColumnsCannotBeTheSamePleaseCheckYourSettingsAndTryAgain"), "OK", nil, "warning")
                    return
                end

                processCSV(csvData)

                csvLoaded = true
                updateUI()
            end
        elseif callbackType == "batchProcessFolder" then
            local originalTitleColumn = tonumber(mod.originalTitleColumn())
            local newTitleColumn = tonumber(mod.newTitleColumn())
            if originalTitleColumn == newTitleColumn then
                webviewAlert(mod._manager.getWebview(), function() end, i18n("invalidColumnsSelected"), i18n("theOriginalAndNewColumnsCannotBeTheSamePleaseCheckYourSettingsAndTryAgain"), i18n("ok"), nil, "warning")
                return
            end

            if not doesDirectoryExist(mod.lastBatchProcessPath()) then
                mod.lastBatchProcessPath(desktopPath)
            end

            local exportPathResult = chooseFileOrFolder(i18n("pleaseSelectAFolderToBatchProcess") .. ":", mod.lastBatchProcessPath(), false, true, false)
            local exportPath = exportPathResult and exportPathResult["1"]

            if not exportPath then return end

            mod.lastBatchProcessPath(exportPath)
            local files = dirFiles(exportPath)

            local fcpxmlFiles = {}
            local csvFiles = {}

            for _, file in pairs(files) do
                if file:sub(-7) == ".fcpxml" then
                    table.insert(fcpxmlFiles, file:sub(1, -8))
                end
                if file:sub(-4) == ".csv" then
                    table.insert(csvFiles, file:sub(1, -5))
                end
            end

            local fileCount = 0
            local bothFiles = {}
            for _, file in pairs(fcpxmlFiles) do
                if tools.tableContains(csvFiles, file) then
                    table.insert(bothFiles, file)
                    fileCount = fileCount + 1
                end
            end

            local nodeOptions = xml.nodeOptions
            local options = nodeOptions.compactEmptyElement | nodeOptions.useDoubleQuotes

            for i, file in pairs(bothFiles) do
                --------------------------------------------------------------------------------
                -- Reset data for each file:
                --------------------------------------------------------------------------------
                data = {}
                count = 1
                updateTitlesCount = 1

                --------------------------------------------------------------------------------
                -- Read FCPXML File:
                --------------------------------------------------------------------------------
                local fcpxmlPath = exportPath .. "/" .. file .. ".fcpxml"
                local document = xml.open(fcpxmlPath)
                local spine = document:XPathQuery("/fcpxml[1]/library[1]/event[1]/project[1]/sequence[1]/spine[1]")
                local spineChildren = spine and spine[1] and spine[1]:children()
                getTitles(spineChildren)

                --------------------------------------------------------------------------------
                -- Read CSV File:
                --------------------------------------------------------------------------------
                local csvPath = exportPath .. "/" .. file .. ".csv"
                local csvData = csv.open(csvPath)
                processCSV(csvData)

                --------------------------------------------------------------------------------
                -- Update FCPXML File:
                --------------------------------------------------------------------------------
                local errorLog = updateTitles(spineChildren, "")

                local result = document:xmlString(options)
                local exportedFilePath = exportPath .. "/" .. file .. " (" .. i18n("updatedTitles") .. ").fcpxml"
                writeToFile(exportedFilePath, result)

                local sendToFCPX = function()
                    if mod.sentToFinalCutPro() then
                        fcp:importXML(exportedFilePath)
                    end
                end

                if errorLog == "" then
                    if mod.sentToFinalCutPro() then
                        sendToFCPX()
                        reset()
                    else
                        if i == fileCount then
                            webviewAlert(mod._manager.getWebview(), reset, i18n("success") .. "!", i18n("theBatchOfFCPXMLsHasBeenExportedSuccessfully"), i18n("ok"))
                        end
                    end
                else
                    webviewAlert(mod._manager.getWebview(), sendToFCPX, i18n("success") .. "!", i18n("aNewFCPXMLHasBeenExportedSuccessfully") .. "\n\n" .. i18n("howeverThereWereSomeTitlesThatCouldNotBeFoundInTheCSV") .. ":\n\n" .. errorLog, i18n("ok"))
                end
            end
        elseif callbackType == "exportCSV" then
            if not fcpxmlLoaded then
                webviewAlert(mod._manager.getWebview(), function() end, i18n("noFCPXMLTemplateDetected"), i18n("pleaseLoadAValidFCPXMLTemplateAndTryAgain"), i18n("ok"), nil, "warning")
                return
            end

            local result = i18n("originalTitle") .. ", " .. i18n("newTitle").. "\n"
            for _, v in spairs(data) do
                result = result .. [["]] .. v.original .. [[","]] .. v.new .. [["]] .. "\n"
            end

            if not doesDirectoryExist(mod.lastExportCSVPath()) then
                mod.lastExportCSVPath(desktopPath)
            end

            local exportPathResult = chooseFileOrFolder(i18n("pleaseSelectAnOutputDirectory") .. ":", mod.lastExportCSVPath(), false, true, false)
            local exportPath = exportPathResult and exportPathResult["1"]

            if exportPath then
                mod.lastExportCSVPath(exportPath)
                local exportedFilePath = exportPath .. "/" .. originalFilename .. ".csv"
                writeToFile(exportedFilePath, result)
                webviewAlert(mod._manager.getWebview(), function() end, i18n("success") .. "!", i18n("theCSVHasBeenExportedSuccessfully"), i18n("ok"))
            end
        elseif callbackType == "exportNewFCPXML" then
            if not fcpxmlLoaded then
                webviewAlert(mod._manager.getWebview(), function() end, i18n("noFCPXMLTemplateDetected"), i18n("pleaseLoadAValidFCPXMLTemplateAndTryAgain"), i18n("ok"), nil, "warning")
                return
            end
            if not csvLoaded then
                webviewAlert(mod._manager.getWebview(), function() end, i18n("noCSVDataDetected"), i18n("pleaseLoadAValidCSVFileAndTryAgain"), i18n("ok"), nil, "warning")
            end

            local document = xml.open(xmlPath)
            local spine = document:XPathQuery("/fcpxml[1]/library[1]/event[1]/project[1]/sequence[1]/spine[1]")
            local spineChildren = spine and spine[1] and spine[1]:children()
            local errorLog = ""
            updateTitlesCount = 1
            errorLog = updateTitles(spineChildren, errorLog)

            local nodeOptions = xml.nodeOptions
            local options = nodeOptions.compactEmptyElement | nodeOptions.useDoubleQuotes
            local result = document:xmlString(options)

            if not doesDirectoryExist(mod.lastExportFCPXMLPath()) then
                mod.lastExportFCPXMLPath(desktopPath)
            end

            local exportPathResult = chooseFileOrFolder(i18n("pleaseSelectAnOutputDirectory") .. ":", mod.lastExportFCPXMLPath(), false, true, false)
            local exportPath = exportPathResult and exportPathResult["1"]

            if exportPath then
                mod.lastExportFCPXMLPath(exportPath)
                local exportedFilePath = exportPath .. "/" .. originalFilename .. " (" .. i18n("updatedTitles") .. ").fcpxml"
                writeToFile(exportedFilePath, result)

                local sendToFCPX = function()
                    if mod.sentToFinalCutPro() then
                        fcp:importXML(exportedFilePath)
                    end
                end

                if errorLog == "" then
                    if mod.sentToFinalCutPro() then
                        sendToFCPX()
                        reset()
                    else
                        webviewAlert(mod._manager.getWebview(), reset, i18n("success") .. "!", i18n("aNewFCPXMLHasBeenExportedSuccessfully"), i18n("ok"))
                    end
                else
                    webviewAlert(mod._manager.getWebview(), sendToFCPX, i18n("success") .. "!", i18n("aNewFCPXMLHasBeenExportedSuccessfully") .. " " .. i18n("howeverThereWereSomeTitlesThatCouldNotBeFoundInTheCSV") .. ":\n\n" .. errorLog, i18n("ok"))
                end
            end
        elseif callbackType == "newTitleColumn" then
            local value = params["value"]
            mod.newTitleColumn(value)
        elseif callbackType == "originalTitleColumn" then
            local value = params["value"]
            mod.originalTitleColumn(value)
        elseif callbackType == "trimWhiteSpace" then
            local value = params["value"]
            mod.trimWhiteSpace(value)
        elseif callbackType == "removeLineBreaks" then
            local value = params["value"]
            mod.removeLineBreaks(value)
        elseif callbackType == "sentToFinalCutPro" then
            local value = params["value"]
            mod.sentToFinalCutPro(value)
        elseif callbackType == "ignoreFirstRow" then
            local value = params["value"]
            mod.ignoreFirstRow(value)
        elseif callbackType == "updateUI" then
            updateUI()
        elseif callbackType == "updateNew" then
            local bid = params["id"]
            local value = params["value"]
            data[bid].new = value
        elseif callbackType == "reset" then
            reset()
        else
            --------------------------------------------------------------------------------
            -- Unknown Callback:
            --------------------------------------------------------------------------------
            log.df("Unknown Callback in FCPXML Titles Utilities Panel:")
            log.df("id: %s", inspect(id))
            log.df("params: %s", inspect(params))
        end
    end
end

local plugin = {
    id              = "finalcutpro.toolbox.fcpxmltitles",
    group           = "finalcutpro",
    dependencies    = {
        ["core.toolbox.manager"]    = "manager",
    }
}

function plugin.init(deps, env)
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Inter-plugin Connectivity:
    --------------------------------------------------------------------------------
    mod._manager                = deps.manager
    mod._env                    = env

    --------------------------------------------------------------------------------
    -- Setup Utilities Panel:
    --------------------------------------------------------------------------------
    mod._panel          =  deps.manager.addPanel({
        priority        = 1,
        id              = "fcpxmlTitles",
        label           = i18n("fcpxmlTitles"),
        image           = image.imageFromPath(env:pathToAbsolute("/images/XML.icns")),
        tooltip         = i18n("fcpxmlTitles"),
        height          = 810,
    })
    :addContent(1, generateContent, false)

    --------------------------------------------------------------------------------
    -- Setup Callback Manager:
    --------------------------------------------------------------------------------
    mod._panel:addHandler("onchange", "fcpxmlTitlesPanelCallback", callback)

    return mod
end

return plugin
