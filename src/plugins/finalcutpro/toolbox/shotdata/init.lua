--- === plugins.finalcutpro.toolbox.shotdata ===
---
--- FCPXML Titles Toolbox Panel

local require                   = require

local log                       = require "hs.logger".new "shotdata"

local dialog                    = require "hs.dialog"
local fnutils                   = require "hs.fnutils"
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
local copy                      = fnutils.copy
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

local DEFAULT_SCENE_PREFIX = "INT"
local DEFAULT_SCENE_TIME = "Dawn"
local DEFAULT_SHOT_SIZE_AND_TYPE = "WS"
local DEFAULT_CAMERA_ANGLE = "Eye Line"
local DEFAULT_FLAG = "false"

local TEMPLATE_NUMBER_OF_NODES = 185

local TEMPLATE = {
    [1]     = { label = "Shot Data",            ignore = true  },
    [2]     = { label = "Shot Number",          ignore = false },
    [3]     = { label = "Shot Number",          ignore = true  },
    [4]     = { label = "Shot Location",        ignore = false },
    [5]     = { label = "Scene Location",       ignore = true  },
    [6]     = { label = "Shot Duration",        ignore = false },
    [7]     = { label = "Shot Duration",        ignore = true  },
    [8]     = { label = "Script Data",          ignore = true  },
    [9]     = { label = "Scene Number",         ignore = false },
    [10]    = { label = "Scene Number",         ignore = true },
    [11]    = { label = "INT",                  ignore = true },
    [12]    = { label = "EXT",                  ignore = true },
    [13]    = { label = "I/E",                  ignore = true },
    [14]    = { label = "Scene Prefix",         ignore = true },
    [15]    = { label = "Dawn",                 ignore = true },
    [16]    = { label = "Dawn (Twilight)",      ignore = true },
    [17]    = { label = "Sunrise",              ignore = true },
    [18]    = { label = "Morning",              ignore = true },
    [19]    = { label = "Daytime",              ignore = true },
    [20]    = { label = "Evening",              ignore = true },
    [21]    = { label = "Sunset",               ignore = true },
    [22]    = { label = "Sunset",               ignore = true },
    [23]    = { label = "Dusk (Twilight)",      ignore = true },
    [24]    = { label = "Dusk",                 ignore = true },
    [25]    = { label = "Night",                ignore = true },
    [26]    = { label = "Scene Time",           ignore = true },
    [27]    = { label = "Scene Time Range",     ignore = false },
    [28]    = { label = "Scene Time Range",     ignore = true },
    [29]    = { label = "Scene Set",            ignore = false },
    [30]    = { label = "Scene Set",            ignore = true },
    [31]    = { label = "Script Page No",       ignore = false },
    [32]    = { label = "Script Page No.",      ignore = true },
    [33]    = { label = "Scene Characters",     ignore = false },
    [34]    = { label = "Scene Characters",     ignore = true },
    [35]    = { label = "Scene Cast",           ignore = false },
    [36]    = { label = "Scene Cast",           ignore = true },
    [37]    = { label = "Scene Description",    ignore = false },
    [38]    = { label = "Scene Description",    ignore = true },
    [39]    = { label = "CAMERA & LENS DATA",   ignore = true },
    [40]    = { label = "WS",                   ignore = true },
    [41]    = { label = "MWS",                  ignore = true },
    [42]    = { label = "EWS",                  ignore = true },
    [43]    = { label = "Master",               ignore = true },
    [44]    = { label = "FS",                   ignore = true },
    [45]    = { label = "MFS",                  ignore = true },
    [46]    = { label = "Cowboy Shot",          ignore = true },
    [47]    = { label = "Medium",               ignore = true },
    [48]    = { label = "CU",                   ignore = true },
    [49]    = { label = "Choker",               ignore = true },
    [50]    = { label = "MCU",                  ignore = true },
    [51]    = { label = "ECU",                  ignore = true },
    [52]    = { label = "Cutaway",              ignore = true },
    [53]    = { label = "Cut-In",               ignore = true },
    [54]    = { label = "Zoom-In",              ignore = true },
    [55]    = { label = "Pan",                  ignore = true },
    [56]    = { label = "Two Shot",             ignore = true },
    [57]    = { label = "OTS",                  ignore = true },
    [58]    = { label = "POV",                  ignore = true },
    [59]    = { label = "Montage",              ignore = true },
    [60]    = { label = "CGI",                  ignore = true },
    [61]    = { label = "Weather Shot",         ignore = true },
    [62]    = { label = "Arial Shot",           ignore = true },
    [63]    = { label = "Shot Size & Type",     ignore = true },
    [64]    = { label = "Camera Movement",      ignore = false },
    [65]    = { label = "Camera Movement",      ignore = true },
    [66]    = { label = "Eye Level",            ignore = true },
    [67]    = { label = "High Angle",           ignore = true },
    [68]    = { label = "Low Angle",            ignore = true },
    [69]    = { label = "Shoulder Level",       ignore = true },
    [70]    = { label = "Hip Level",            ignore = true },
    [71]    = { label = "Knee Level",           ignore = true },
    [72]    = { label = "Ground Level",         ignore = true },
    [73]    = { label = "Dutch Angle/Tilt",     ignore = true },
    [74]    = { label = "POV",                  ignore = true },
    [75]    = { label = "Camera Angle",         ignore = true },
    [76]    = { label = "Equipment",            ignore = false },
    [77]    = { label = "Equipment",            ignore = true },
    [78]    = { label = "Lens",                 ignore = false },
    [79]    = { label = "Lens",                 ignore = true },
    [80]    = { label = "Lighting Notes",       ignore = false },
    [81]    = { label = "Lighting Notes",       ignore = true },
    [82]    = { label = "VFX DATA",             ignore = true },
    [83]    = { label = "No",                   ignore = true },
    [84]    = { label = "Yes",                  ignore = true },
    [85]    = { label = "VFX",                  ignore = true },
    [86]    = { label = "AA VFX Description",   ignore = true },
    [87]    = { label = "VFX Description",      ignore = true },
    [88]    = { label = "SOUND & MUSIC DATA",   ignore = true },
    [89]    = { label = "No",                   ignore = true },
    [90]    = { label = "Yes",                  ignore = true },
    [91]    = { label = "SFX",                  ignore = true },
    [92]    = { label = "SFX Description",      ignore = false },
    [93]    = { label = "SFX Description",      ignore = true },
    [94]    = { label = "Music Track",          ignore = false },
    [95]    = { label = "Music Track",          ignore = true },
    [96]    = { label = "ART DEPARTMENT DATA",  ignore = true },
    [97]    = { label = "Production Design",    ignore = false },
    [98]    = { label = "Production Design",    ignore = true },
    [99]    = { label = "Props",                ignore = false },
    [100]   = { label = "Props ID",             ignore = true },
    [101]   = { label = "Props Notes",          ignore = false },
    [102]   = { label = "Props Notes",          ignore = true },
    [103]   = { label = "Wardrobe ID",          ignore = true },
    [104]   = { label = "Wardrobe ID",          ignore = false },
    [105]   = { label = "Wardrobe Notes",       ignore = false },
    [106]   = { label = "Wardrobe Notes",       ignore = true },
    [107]   = { label = "HAIR & MAKE UP DATA",  ignore = true },
    [108]   = { label = "Hair",                 ignore = false },
    [109]   = { label = "Hair",                 ignore = true },
    [110]   = { label = "Make Up",              ignore = false },
    [111]   = { label = "Make Up",              ignore = true },
    [112]   = { label = "USER DATA",            ignore = true },
    [113]   = { label = "No",                   ignore = true },
    [114]   = { label = "Yes",                  ignore = true },
    [115]   = { label = "Flag",                 ignore = true },
    [116]   = { label = "User Notes 1",         ignore = false },
    [117]   = { label = "Notes 1",              ignore = true },
    [118]   = { label = "User Notes 2",         ignore = false },
    [119]   = { label = "Notes 2",              ignore = true },
    [120]   = { label = "SCHEDULE DATA",        ignore = true },
    [121]   = { label = "Start Date",           ignore = false },
    [122]   = { label = "Start Date",           ignore = true },
    [123]   = { label = "End Date",             ignore = false },
    [124]   = { label = "End Date",             ignore = true },
    [125]   = { label = "Days",                 ignore = false },
    [126]   = { label = "Days",                 ignore = true },
}

-- data -> table
-- Variable
-- A table containing all the current data being processed.
local data = {}

-- originalFilename -> string
-- Variable
-- Original filename of the FCPXML.
local originalFilename = ""

-- desktopPath -> string
-- Constant
-- Path to the users desktop
local desktopPath = os.getenv("HOME") .. "/Desktop/"

--- plugins.finalcutpro.toolbox.shotdata.lastOpenPath <cp.prop: string>
--- Field
--- Last open path
mod.lastOpenPath = config.prop("toolbox.shotdata.lastOpenPath", desktopPath)

--- plugins.finalcutpro.toolbox.shotdata.lastSavePath <cp.prop: string>
--- Field
--- Last save path
mod.lastSavePath = config.prop("toolbox.shotdata.lastSavePath", desktopPath)

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

-- installMotionTemplate() -> none
-- Function
-- Install Motion Template.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function installMotionTemplate()
    webviewAlert(mod._manager.getWebview(), function() end, "Not yet implimented.", "This feature hasn't been built yet.", i18n("ok"), nil, "warning")
end

-- processTitles(nodes) -> none
-- Function
-- Process Titles.
--
-- Parameters:
--  * nodes - A table of XML nodes.
--
-- Returns:
--  * None
local function processTitles(nodes)
    if nodes then
        for _, node in pairs(nodes) do
            local name = node:name()
            if name == "spine" or name == "gap" or name == "asset-clip" then
                --------------------------------------------------------------------------------
                -- Secondary Storyline:
                --------------------------------------------------------------------------------
                processTitles(node:children())
            elseif name == "title" then
                --------------------------------------------------------------------------------
                -- Title:
                --------------------------------------------------------------------------------
                local results = {}

                local scenePrefixValue          = DEFAULT_SCENE_PREFIX
                local sceneTimeValue            = DEFAULT_SCENE_TIME
                local shotSizeAndTypeValue      = DEFAULT_SHOT_SIZE_AND_TYPE
                local cameraAngleValue          = DEFAULT_CAMERA_ANGLE
                local flagValue                 = DEFAULT_FLAG

                local nodeChildren = node:children()
                if nodeChildren and #nodeChildren >= TEMPLATE_NUMBER_OF_NODES then
                    local textCount = 1
                    for _, nodeChild in pairs(nodeChildren) do
                        if nodeChild:name() == "text" then
                            --------------------------------------------------------------------------------
                            -- Text Node:
                            --------------------------------------------------------------------------------
                            if TEMPLATE[textCount].ignore == false then
                                local textStyles = nodeChild:children()
                                local textStyle = textStyles and textStyles[1]
                                if textStyle and textStyle:name() == "text-style" then
                                    local value = textStyle:stringValue()
                                    local label = TEMPLATE[textCount].label
                                    results[label] = value
                                end
                            end
                            textCount = textCount + 1
                        elseif nodeChild:name() == "param" then
                            --------------------------------------------------------------------------------
                            -- Parameter Node:
                            --------------------------------------------------------------------------------
                            local rawAttributes = nodeChild:rawAttributes()
                            local name, value
                            for _, v in pairs(rawAttributes) do
                                if v:name() == "name" then
                                    name = v:stringValue()
                                elseif v:name() == "value" then
                                    value = v:stringValue()
                                end
                            end
                            if name == "Scene Prefix" then
                                scenePrefixValue = value:match("%((.*)%)")
                            elseif name == "Scene Time" then
                                sceneTimeValue = value:match("%((.*)%)")
                            elseif name == "Shot Size & Type" then
                                shotSizeAndTypeValue = value:match("%((.*)%)")
                            elseif name == "Camera Angle" then
                                cameraAngleValue = value:match("%((.*)%)")
                            elseif name == "Flag" then
                                if value == "1" then
                                    flagValue = "true"
                                end
                            end
                        end
                    end

                    --------------------------------------------------------------------------------
                    -- Add Parameter values to results table:
                    --------------------------------------------------------------------------------
                    results["Scene Prefix"] = scenePrefixValue
                    results["Scene Time"] = sceneTimeValue
                    results["Shot Size & Type"] = shotSizeAndTypeValue
                    results["Camera Angle"] = cameraAngleValue
                    results["Flag"] = flagValue

                    --------------------------------------------------------------------------------
                    -- Add results to data table:
                    --------------------------------------------------------------------------------
                    table.insert(data, copy(results))
                end
            end
        end

    end
end

-- convertFCPXMLtoCSV() -> none
-- Function
-- Converts a FCPXML to a CSV.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function convertFCPXMLtoCSV()
    if not doesDirectoryExist(mod.lastOpenPath()) then
        mod.lastOpenPath(desktopPath)
    end
    local result = chooseFileOrFolder("Please select a FCPXML file to convert:", mod.lastOpenPath(), true, false, false, {"fcpxml"}, true)
    local path = result and result["1"]
    if path then
        if fcpxml.valid(path) then
            mod.lastOpenPath(removeFilenameFromPath(path))

            originalFilename = getFilenameFromPath(path, true)

            local document = xml.open(path)
            local spine = document:XPathQuery("/fcpxml[1]/library[1]/event[1]/project[1]/sequence[1]/spine[1]")
            local spineChildren = spine and spine[1] and spine[1]:children()
            data = {}
            processTitles(spineChildren)

            if not next(data) then
                webviewAlert(mod._manager.getWebview(), function() end, "Failed to process FCPXML.", "CommandPost was unable to process the FCPXML. Please make sure the FCPXML contains a single timeline, which contains the Shot Data titles.", i18n("ok"), nil, "warning")
            end

            --------------------------------------------------------------------------------
            -- Convert the titles data to CSV data:
            --------------------------------------------------------------------------------
            local output = ""
            local firstTitle = data[1]
            local firstTitleCount = tableCount(firstTitle)

            local count = 1
            for heading, _ in pairs(firstTitle) do
                if heading:match(",") then
                    output = output .. [["]] .. heading .. [["]]
                else
                    output = output .. heading
                end
                if count < firstTitleCount then
                    output = output .. ", "
                end
                count = count + 1
            end

            output = output .. "\n"

            for _, row in pairs(data) do
                count = 1
                for _, value in pairs(row) do
                    if value:match(",") then
                        output = output .. [["]] .. value .. [["]]
                    else
                        output = output .. value
                    end
                    if count < firstTitleCount then
                        output = output .. ", "
                    end
                    count = count + 1
                end
                output = output .. "\n"
            end

            --------------------------------------------------------------------------------
            -- Make sure last save path still exists, otherwise use Desktop:
            --------------------------------------------------------------------------------
            if not doesDirectoryExist(mod.lastSavePath()) then
                mod.lastSavePath(desktopPath)
            end

            local exportPathResult = chooseFileOrFolder(i18n("pleaseSelectAnOutputDirectory") .. ":", mod.lastSavePath(), false, true, false)
            local exportPath = exportPathResult and exportPathResult["1"]

            if exportPath then
                mod.lastSavePath(exportPath)
                local exportedFilePath = exportPath .. "/" .. originalFilename .. ".csv"
                writeToFile(exportedFilePath, output)
                webviewAlert(mod._manager.getWebview(), function() end, i18n("success") .. "!", i18n("theCSVHasBeenExportedSuccessfully"), i18n("ok"))
            end
        else
            webviewAlert(mod._manager.getWebview(), function() end, i18n("invalidFCPXMLFile"), i18n("theSuppliedFCPXMLDidNotPassDtdValidationPleaseCheckThatTheFCPXMLSuppliedIsValidAndTryAgain"), i18n("ok"), nil, "warning")
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
        if callbackType == "installMotionTemplate" then
            --------------------------------------------------------------------------------
            -- Install Motion Template:
            --------------------------------------------------------------------------------
            installMotionTemplate()
        elseif callbackType == "convertFCPXMLtoCSV" then
            --------------------------------------------------------------------------------
            -- Convert a FCPXML to CSV:
            --------------------------------------------------------------------------------
            convertFCPXMLtoCSV()
        else
            --------------------------------------------------------------------------------
            -- Unknown Callback:
            --------------------------------------------------------------------------------
            log.df("Unknown Callback in Shot Data Toolbox Panel:")
            log.df("id: %s", inspect(id))
            log.df("params: %s", inspect(params))
        end
    end
end

local plugin = {
    id              = "finalcutpro.toolbox.shotdata",
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
        priority        = 2,
        id              = "shotdata",
        label           = i18n("shotData"),
        image           = image.imageFromPath(env:pathToAbsolute("/images/XML.icns")),
        tooltip         = i18n("shotData"),
        height          = 230,
    })
    :addContent(1, generateContent, false)

    --------------------------------------------------------------------------------
    -- Setup Callback Manager:
    --------------------------------------------------------------------------------
    mod._panel:addHandler("onchange", "shotDataPanelCallback", callback)

    return mod
end

return plugin
