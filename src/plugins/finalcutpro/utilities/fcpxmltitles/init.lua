--- === plugins.finalcutpro.utilities.fcpxmltitles ===
---
--- FCPXML Titles Utilities Panel

local require                   = require

local log                       = require "hs.logger".new "prefsLoupedeckCT"

local application               = require "hs.application"
local canvas                    = require "hs.canvas"
local dialog                    = require "hs.dialog"
local fnutils                   = require "hs.fnutils"
local image                     = require "hs.image"
local inspect                   = require "hs.inspect"
local loupedeckct               = require "hs.loupedeckct"
local menubar                   = require "hs.menubar"
local mouse                     = require "hs.mouse"

local config                    = require "cp.config"
local html                      = require "cp.web.html"
local i18n                      = require "cp.i18n"
local json                      = require "cp.json"
local tools                     = require "cp.tools"

local csv                       = require "csv"

local chooseFileOrFolder        = dialog.chooseFileOrFolder
local copy                      = fnutils.copy
local doesDirectoryExist        = tools.doesDirectoryExist
local getFilenameFromPath       = tools.getFilenameFromPath
local getFilenameFromPath       = tools.getFilenameFromPath
local imageFromURL              = image.imageFromURL
local infoForBundlePath         = application.infoForBundlePath
local mergeTable                = tools.mergeTable
local readFromFile              = tools.readFromFile
local removeFilenameFromPath    = tools.removeFilenameFromPath
local removeFilenameFromPath    = tools.removeFilenameFromPath
local spairs                    = tools.spairs
local tableContains             = tools.tableContains
local trim                      = tools.trim
local webviewAlert              = dialog.webviewAlert
local writeToFile               = tools.writeToFile

local mod = {}

local xmlData
local csvData
local originalFilename

local desktopPath = os.getenv("HOME") .. "/Desktop/"

--- plugins.finalcutpro.utilities.fcpxmltitles.originalTitleColumn <cp.prop: string>
--- Field
--- Original Title Column
mod.originalTitleColumn = config.prop("utilities.fcpxmltitles.originalTitleColumn", "1")

--- plugins.finalcutpro.utilities.fcpxmltitles.newTitleColumn <cp.prop: string>
--- Field
--- New Title Column
mod.newTitleColumn = config.prop("utilities.fcpxmltitles.newTitleColumn", "3")

--- plugins.finalcutpro.utilities.fcpxmltitles.lastFCPXMLPath <cp.prop: string>
--- Field
--- Last FCPXMLPath
mod.lastFCPXMLPath = config.prop("utilities.fcpxmltitles.lastFCPXMLPath", desktopPath)

--- plugins.finalcutpro.utilities.fcpxmltitles.lastFCPXMLPath <cp.prop: string>
--- Field
--- Last FCPXMLPath
mod.lastCSVPath = config.prop("utilities.fcpxmltitles.lastCSVPath", desktopPath)

--- plugins.finalcutpro.utilities.fcpxmltitles.lastExportPath <cp.prop: string>
--- Field
--- Last Export Path
mod.lastExportPath = config.prop("utilities.fcpxmltitles.lastExportPath", desktopPath)

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

local function literalize(str)
    return str:gsub("[%(%)%.%%%+%-%*%?%[%]%^%$]", function(c) return "%" .. c end)
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
                mod.lastFCPXMLPath(removeFilenameFromPath(path))
                xmlData = readFromFile(path)
                originalFilename = getFilenameFromPath(path, true)
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
            --------------------------------------------------------------------------------
            -- Export New FCPXML:
            --------------------------------------------------------------------------------
            if not xmlData then
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
                        lookup[original] = new
                    else
                        webviewAlert(mod._manager.getWebview(), function() end, "Invalid CSV Data detected.", "Please check the contents of the CSV file, and that you have the columns set correctly, then try again.", "OK", nil, "warning")
                        return
                    end
                end
            end

            local result = xmlData

            for original, new in pairs(lookup) do
                result = string.gsub(result, ">" .. literalize(original) .. "<", ">" .. new .. "<")
            end

            if not doesDirectoryExist(mod.lastExportPath()) then
                mod.lastExportPath(desktopPath)
            end

            local exportPathResult = chooseFileOrFolder("Please select an output directory:", mod.lastExportPath(), false, true, false)
            local exportPath = exportPathResult and exportPathResult["1"]

            if exportPath then
                mod.lastExportPath(exportPath)
                local p = exportPath .. "/" .. originalFilename .. " (Updated Titles).fcpxml"
                writeToFile(p, result)
            end
        elseif callbackType == "newTitleColumn" then
            local value = params["value"]
            mod.newTitleColumn(value)
        elseif callbackType == "originalTitleColumn" then
            local value = params["value"]
            mod.originalTitleColumn(value)
        elseif callbackType == "updateUI" then
            --------------------------------------------------------------------------------
            -- Update UI:
            --------------------------------------------------------------------------------
            local originalTitleColumn = mod.originalTitleColumn()
            local newTitleColumn = mod.newTitleColumn()

            local script = [[
                changeValueByID("originalTitleColumn", "]] .. originalTitleColumn .. [[");
                changeValueByID("newTitleColumn", "]] .. newTitleColumn .. [[");
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
    id              = "finalcutpro.utilities.fcpxmltitles",
    group           = "finalcutpro",
    dependencies    = {
        ["core.utilities.manager"]    = "manager",
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
        height          = 280,
    })

    :addContent(1, generateContent, false)

    --------------------------------------------------------------------------------
    -- Setup Callback Manager:
    --------------------------------------------------------------------------------
    mod._panel:addHandler("onchange", "fcpxmlTitlesPanelCallback", callback)

    return mod
end

return plugin
