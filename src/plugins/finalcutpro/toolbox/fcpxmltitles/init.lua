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
local tools                     = require "cp.tools"

local csv                       = require "csv"
local xml                       = require "hs._asm.xml"

local chooseFileOrFolder        = dialog.chooseFileOrFolder
local doesDirectoryExist        = tools.doesDirectoryExist
local getFilenameFromPath       = tools.getFilenameFromPath
local removeFilenameFromPath    = tools.removeFilenameFromPath
local trim                      = tools.trim
local webviewAlert              = dialog.webviewAlert
local writeToFile               = tools.writeToFile

local mod = {}

local xmlPath
local csvData
local originalFilename

-- desktopPath -> string
-- Constant
-- Path to the users desktop
local desktopPath = os.getenv("HOME") .. "/Desktop/"

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

--- plugins.finalcutpro.toolbox.fcpxmltitles.lastExportPath <cp.prop: string>
--- Field
--- Last Export Path
mod.lastExportPath = config.prop("toolbox.fcpxmltitles.lastExportPath", desktopPath)

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
    --------------------------------------------------------------------------------
    -- Setup the context:
    --------------------------------------------------------------------------------
    local context = {
    }
    return renderPanel(context)
end

local function exportNewFCPXML(exportPath)
    --------------------------------------------------------------------------------
    -- Export New FCPXML:
    --------------------------------------------------------------------------------
    if not xmlPath then
        webviewAlert(mod._manager.getWebview(), function() end, "No FCPXML Template detected.", "Please load a valid FCPXML Template and try again.", "OK", nil, "warning")
        return
    end
    if not csvData then
        webviewAlert(mod._manager.getWebview(), function() end, "No CSV Data detected.", "Please load a valid CSV file and try again.", "OK", nil, "warning")
        return
    end

    local originalTitleColumn = tonumber(mod.originalTitleColumn())
    local newTitleColumn = tonumber(mod.newTitleColumn())

    if originalTitleColumn == newTitleColumn then
        webviewAlert(mod._manager.getWebview(), function() end, "Invalid columns selected.", "The original and new columns cannot be the same. Please check your settings and try again.", "OK", nil, "warning")
        return
    end

    local lookup = {}

    local firstLine = true
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
            else
                webviewAlert(mod._manager.getWebview(), function() end, "Invalid CSV Data detected.", "Please check the contents of the CSV file, and that you have the columns set correctly, then try again.", "OK", nil, "warning")
                return
            end
        end
    end

    local errorLog = ""
    local document = xml.open(xmlPath)
    local spine = document:XPathQuery("/fcpxml[1]/library[1]/event[1]/project[1]/sequence[1]/spine[1]")
    local spineChildren = spine and spine[1] and spine[1]:children()
    if spineChildren then
        for _, v in pairs(spineChildren) do
            local children = v:children()
            if children then
                for _, vv in pairs(children) do
                    if vv:name() == "title" then
                        local newValue = nil
                        local nodeChildren = vv:children()
                        for _, vvv in pairs(nodeChildren) do
                            if vvv:name() == "text" then
                                local textStyles = vvv:children()
                                if textStyles then
                                    for _, vvvv in pairs(textStyles) do
                                        local originalValue = vvvv:stringValue()

                                        if originalValue then
                                            if mod.trimWhiteSpace() then
                                                originalValue = originalValue and trim(originalValue)
                                            end
                                            if mod.removeLineBreaks() then
                                                originalValue = originalValue and string.gsub(originalValue, "\n", "")
                                            end
                                        end
                                        newValue = originalValue and lookup[originalValue]
                                        if newValue then
                                            vvvv:setStringValue(newValue)
                                        else
                                            errorLog = errorLog .. " * " .. originalValue .. "\n"
                                        end
                                    end
                                end
                            end
                        end
                        if newValue then
                            local rawAttributes = vv:rawAttributes()
                            for _, vvv in pairs(rawAttributes) do
                                if vvv:name() == "name" then
                                    vvv:setStringValue(newValue)
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    local nodeOptions = xml.nodeOptions
    local options = nodeOptions.compactEmptyElement | nodeOptions.useDoubleQuotes
    local result = document:xmlString(options)

    if not doesDirectoryExist(mod.lastExportPath()) then
        mod.lastExportPath(desktopPath)
    end

    if not exportPath then
        local exportPathResult = chooseFileOrFolder("Please select an output directory:", mod.lastExportPath(), false, true, false)
        exportPath = exportPathResult and exportPathResult["1"]
    end

    if exportPath then
        mod.lastExportPath(exportPath)
        local exportedFilePath = exportPath .. "/" .. originalFilename .. " (Updated Titles).fcpxml"
        writeToFile(exportedFilePath, result)

        local sendToFCPX = function()
            if mod.sentToFinalCutPro() then
                fcp:importXML(exportedFilePath)
            end
        end

        if errorLog == "" then
            if mod.sentToFinalCutPro() then
                sendToFCPX()
            else
                webviewAlert(mod._manager.getWebview(), function() end, "Success!", "A new FCPXML has been exported successfully.", "OK")
            end
        else
            webviewAlert(mod._manager.getWebview(), sendToFCPX, "Success!", "A new FCPXML has been exported successfully. However, there were some titles that could not be found in the CSV:\n\n" .. errorLog, "OK")
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
    local injectScript = mod._manager.injectScript
    local callbackType = params and params["type"]
    if callbackType then
        if callbackType == "loadFCPXMLTemplate" then
            --------------------------------------------------------------------------------
            -- Load FCPXML Template:
            --------------------------------------------------------------------------------
            if not doesDirectoryExist(mod.lastFCPXMLPath()) then
                mod.lastFCPXMLPath(desktopPath)
            end
            local result = chooseFileOrFolder("Please select a FCPXML Template:", mod.lastFCPXMLPath(), true, false, false, {"fcpxml"}, true)
            local path = result and result["1"]
            if path then
                if fcpxml.valid(path) then
                    mod.lastFCPXMLPath(removeFilenameFromPath(path))
                    xmlPath = path
                    originalFilename = getFilenameFromPath(path, true)
                else
                    webviewAlert(mod._manager.getWebview(), function() end, "Invalid FCPXML File.", "The supplied FCPXML did not pass DTD validation. Please check that the FCPXML supplied is valid and try again.", "OK", nil, "warning")
                end
            end
        elseif callbackType == "loadCSVData" then
            --------------------------------------------------------------------------------
            -- Load CSV Data:
            --------------------------------------------------------------------------------
            if not doesDirectoryExist(mod.lastCSVPath()) then
                mod.lastCSVPath(desktopPath)
            end
            local result = chooseFileOrFolder("Please select a FCPXML Template:", mod.lastCSVPath(), true, false, false, {"csv"}, true)
            local path = result and result["1"]
            if path then
                mod.lastCSVPath(removeFilenameFromPath(path))
                csvData = csv.open(path)
                if not csvData then
                    webviewAlert(mod._manager.getWebview(), function() end, "Failed to process the CSV file.", "Please check the contents of the CSV file and try again.", "OK", nil, "warning")
                end
            end
        elseif callbackType == "exportNewFCPXML" then
            exportNewFCPXML()
        elseif callbackType == "batchProcessFolder" then
            if not doesDirectoryExist(mod.lastBatchProcessPath()) then
                mod.lastBatchProcessPath(desktopPath)
            end

            local exportPathResult = chooseFileOrFolder("Please select a folder to Batch Process:", mod.lastBatchProcessPath(), false, true, false)
            local exportPath = exportPathResult and exportPathResult["1"]

            if exportPath then
                mod.lastBatchProcessPath(exportPath)
                local files = tools.dirFiles(exportPath)

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

                local bothFiles = {}
                for _, file in pairs(fcpxmlFiles) do
                    if tools.tableContains(csvFiles, file) then
                        table.insert(bothFiles, file)
                    end
                end

                for _, file in pairs(bothFiles) do
                    local fcpxmlPath = exportPath .. "/" .. file .. ".fcpxml"
                    local csvPath = exportPath .. "/" .. file .. ".csv"

                    xmlPath = fcpxmlPath
                    csvData = csv.open(csvPath)
                    originalFilename = file

                    exportNewFCPXML(exportPath)
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
        elseif callbackType == "updateUI" then
            --------------------------------------------------------------------------------
            -- Update UI:
            --------------------------------------------------------------------------------
            local originalTitleColumn = mod.originalTitleColumn()
            local newTitleColumn = mod.newTitleColumn()

            local script = [[
                changeValueByID("originalTitleColumn", "]] .. originalTitleColumn .. [[");
                changeValueByID("newTitleColumn", "]] .. newTitleColumn .. [[");
                changeCheckedByID("trimWhiteSpace", ]] .. tostring(mod.trimWhiteSpace()) .. [[);
                changeCheckedByID("removeLineBreaks", ]] .. tostring(mod.removeLineBreaks()) .. [[);
                changeCheckedByID("sentToFinalCutPro", ]] .. tostring(mod.sentToFinalCutPro()) .. [[);
            ]]

            injectScript(script)
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
    -- Inter-plugin Connectivity:
    --------------------------------------------------------------------------------
    mod._manager                = deps.manager
    mod._webviewLabel           = deps.manager.getLabel()
    mod._env                    = env

    --------------------------------------------------------------------------------
    -- Setup Utilities Panel:
    --------------------------------------------------------------------------------
    mod._panel          =  deps.manager.addPanel({
        priority        = 1,
        id              = "fcpxmlTitles",
        label           = "FCPXML Titles",
        image           = image.imageFromPath(env:pathToAbsolute("/images/XML.icns")),
        tooltip         = "FCPXML Titles",
        height          = 430,
    })

    :addContent(1, generateContent, false)

    --------------------------------------------------------------------------------
    -- Setup Callback Manager:
    --------------------------------------------------------------------------------
    mod._panel:addHandler("onchange", "fcpxmlTitlesPanelCallback", callback)

    return mod
end

return plugin
