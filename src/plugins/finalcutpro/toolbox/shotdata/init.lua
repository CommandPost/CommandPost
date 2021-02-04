--- === plugins.finalcutpro.toolbox.shotdata ===
---
--- Shot Data Toolbox Panel.

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

local xml                       = require "hs._asm.xml"

local chooseFileOrFolder        = dialog.chooseFileOrFolder
local copy                      = fnutils.copy
local doesDirectoryExist        = tools.doesDirectoryExist
local ensureDirectoryExists     = tools.ensureDirectoryExists
local getFilenameFromPath       = tools.getFilenameFromPath
local removeFilenameFromPath    = tools.removeFilenameFromPath
local spairs                    = tools.spairs
local split                     = tools.split
local tableCount                = tools.tableCount
local webviewAlert              = dialog.webviewAlert
local writeToFile               = tools.writeToFile

local mod = {}

-- TEMPLATE_NUMBER_OF_NODES -> number
-- Constant
-- The minimum number of nodes a Shot Data template will have.
-- This is used to detect if a title is actually a Shot Data template.
local TEMPLATE_NUMBER_OF_NODES = 128

-- DEFAULT_SCENE_PREFIX -> string
-- Constant
-- The default Scene Prefix value.
local DEFAULT_SCENE_PREFIX = "INT"

-- DEFAULT_SCENE_TIME -> string
-- Constant
-- The default Scene Time value.
local DEFAULT_SCENE_TIME = "Dawn"

-- DEFAULT_SHOT_SIZE_AND_TYPE -> string
-- Constant
-- The default Shot Size & Type value.
local DEFAULT_SHOT_SIZE_AND_TYPE = "WS"

-- DEFAULT_CAMERA_ANGLE -> string
-- Constant
-- The default camera angle value.
local DEFAULT_CAMERA_ANGLE = "Eye Line"

-- DEFAULT_FLAG -> string
-- Constant
-- The default flag value.
local DEFAULT_FLAG = "false"

-- TEMPLATE_ORDER -> table
-- Constant
-- A table containing the order of the headings when exporting to a CSV.
local TEMPLATE_ORDER = {
    [1]     = "Shot Number",
    [2]     = "Scene Location",
    [3]     = "Shot Duration",
    [4]     = "Scene Number",
    [5]     = "Scene Prefix",
    [6]     = "Scene Time",
    [7]     = "Scene Time Range",
    [8]     = "Scene Set",
    [9]     = "Script Page No.",
    [10]    = "Scene Characters",
    [11]    = "Scene Cast",
    [12]    = "Scene Description",
    [13]    = "Shot Size & Type",
    [14]    = "Camera Movement",
    [15]    = "Camera Angle",
    [16]    = "Equipment",
    [17]    = "Lens",
    [18]    = "Lighting Notes",
    [19]    = "VFX",
    [20]    = "VFX Description",
    [21]    = "SFX",
    [22]    = "SFX Description",
    [23]    = "Music Track",
    [24]    = "Production Design",
    [25]    = "Props",
    [26]    = "Props Notes",
    [27]    = "Wardrobe ID",
    [28]    = "Wardrobe Notes",
    [29]    = "Hair",
    [30]    = "Make Up",
    [31]    = "Flag",
    [32]    = "User Notes 1",
    [33]    = "User Notes 2",
    [34]    = "Start Date",
    [35]    = "End Date",
    [36]    = "Days",
}

-- TEMPLATE -> table
-- Constant
-- A table that contains all the fields of the Shot Data Motion Template.
local TEMPLATE = {
    [1]     = { label = "Shot Data",            ignore = true  },
    [2]     = { label = "Shot Number",          ignore = false },
    [3]     = { label = "Shot Number",          ignore = true  },
    [4]     = { label = "Scene Location",       ignore = false },
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
    [31]    = { label = "Script Page No.",      ignore = false },
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
    [86]    = { label = "VFX Description",      ignore = false },
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
    webviewAlert(mod._manager.getWebview(), function(result)
        if result == i18n("ok") then
            local moviesPath = os.getenv("HOME") .. "/Movies"
            if not ensureDirectoryExists(moviesPath, "Motion Templates.localized", "Titles.localized", "CommandPost") then
                webviewAlert(mod._manager.getWebview(), function() end, i18n("shotDataFailedToInstallTemplate"), i18n("shotDataFailedToInstallTemplateDescription"), i18n("ok"), nil, "warning")
                return
            end
            local runString = [[cp -R "]] .. config.basePath .. "/plugins/finalcutpro/toolbox/shotdata/motiontemplate/Shot Data" .. [[" "]] .. os.getenv("HOME") .. "/Movies/Motion Templates.localized/Titles.localized/CommandPost" .. [["]]
            local output, status = hs.execute(runString)
            if output and status then
                webviewAlert(mod._manager.getWebview(), function() end, i18n("shotDataInstalledSuccessfully"), i18n("shotDataInstalledSuccessfullyDescription"), i18n("ok"), nil, "informational")
            else
                webviewAlert(mod._manager.getWebview(), function() end, i18n("shotDataFailedToInstallTemplate"), i18n("shotDataFailedToInstallTemplateDescription"), i18n("ok"), nil, "warning")
            end
        end
    end, i18n("shotDataInstallMotionTemplate"), i18n("shotDataInstallMotionTemplateDescription"), i18n("ok"), i18n("cancel"), "informational")
end

-- secondsToClock(seconds) -> string
-- Function
-- Converts seconds to a string in the hh:mm:ss format.
--
-- Parameters:
--  * seconds - The number of seconds to convert.
--
-- Returns:
--  * A string
local function secondsToClock(seconds)
    seconds = tonumber(seconds)
    if seconds <= 0 then
        return "00:00:00";
    else
        local hours = string.format("%02.f", math.floor(seconds/3600));
        local mins = string.format("%02.f", math.floor(seconds/60 - (hours*60)));
        local secs = string.format("%02.f", math.floor(seconds - hours*3600 - mins *60));
        return hours..":"..mins..":"..secs
    end
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
            local nodeName = node:name()
            if nodeName == "spine" or nodeName == "gap" or nodeName == "asset-clip" or nodeName == "video" then
                --------------------------------------------------------------------------------
                -- Secondary Storyline:
                --------------------------------------------------------------------------------
                processTitles(node:children())
            elseif nodeName == "title" then
                --------------------------------------------------------------------------------
                -- Title:
                --------------------------------------------------------------------------------
                local results = {}

                local scenePrefixValue          = DEFAULT_SCENE_PREFIX
                local sceneTimeValue            = DEFAULT_SCENE_TIME
                local shotSizeAndTypeValue      = DEFAULT_SHOT_SIZE_AND_TYPE
                local cameraAngleValue          = DEFAULT_CAMERA_ANGLE

                local flagValue                 = DEFAULT_FLAG
                local vfxFlagValue              = DEFAULT_FLAG
                local sfxFlagValue              = DEFAULT_FLAG

                local titleDuration             = nil

                --------------------------------------------------------------------------------
                -- Get title duration:
                --------------------------------------------------------------------------------
                for _, v in pairs(node:rawAttributes()) do
                    if v:name() == "duration" then
                        titleDuration = v:stringValue()
                        break
                    end
                end

                --------------------------------------------------------------------------------
                -- Format Title Duration:
                --------------------------------------------------------------------------------
                if titleDuration then
                    titleDuration = titleDuration:gsub("s", "")
                    if titleDuration:find("/") then
                        local elements = split(titleDuration, "/")
                        titleDuration = tostring(tonumber(elements[1]) / tonumber(elements[2]))
                    end
                    local convertedValue = secondsToClock(titleDuration)
                    if convertedValue ~= "00:00:00" then
                        titleDuration = convertedValue
                    else
                        titleDuration = titleDuration .. " seconds"
                    end
                end

                --------------------------------------------------------------------------------
                -- Process Nodes:
                --------------------------------------------------------------------------------
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
                            elseif name == "VFX" then
                                if value == "1" then
                                    vfxFlagValue = "true"
                                end
                            elseif name == "SFX" then
                                if value == "1" then
                                    sfxFlagValue = "true"
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
                    results["VFX"] = vfxFlagValue
                    results["SFX"] = sfxFlagValue

                    --------------------------------------------------------------------------------
                    -- If the Shot Duration field is empty, populate it with the Title Duration:
                    --------------------------------------------------------------------------------
                    if titleDuration and not results["Shot Duration"] then
                        results["Shot Duration"] = titleDuration
                    end

                    --------------------------------------------------------------------------------
                    -- Add results to data table:
                    --------------------------------------------------------------------------------
                    table.insert(data, copy(results))
                end
            end
        end

    end
end

-- processFCPXML(path) -> none
-- Function
-- Process a FCPXML file.
--
-- Parameters:
--  * path - A string containing the path to the FCPXML file.
--
-- Returns:
--  * None
local function processFCPXML(path)
    if path then
        if fcpxml.valid(path) then
            --------------------------------------------------------------------------------
            -- Open the FCPXML:
            --------------------------------------------------------------------------------
            local document = xml.open(path)
            local spine = document:XPathQuery("/fcpxml[1]/library[1]/event[1]/project[1]/sequence[1]/spine[1]")
            local spineChildren = spine and spine[1] and spine[1]:children()

            --------------------------------------------------------------------------------
            -- If there's no spineChildren, then try another path (for drag & drop):
            --------------------------------------------------------------------------------
            if not spineChildren then
                spine = document:XPathQuery("/fcpxml[1]/project[1]/sequence[1]/spine[1]")
                spineChildren = spine and spine[1] and spine[1]:children()
            end

            --------------------------------------------------------------------------------
            -- If drag and drop FCPXML, then use the project name for the filename:
            --------------------------------------------------------------------------------
            if spineChildren and not originalFilename then
                local projectName = spine and spine[1] and spine[1]:parent():parent():rawAttributes()[1]:stringValue()
                originalFilename = projectName
            end

            --------------------------------------------------------------------------------
            -- Reset our data table:
            --------------------------------------------------------------------------------
            data = {}

            --------------------------------------------------------------------------------
            -- Process the titles:
            --------------------------------------------------------------------------------
            processTitles(spineChildren)

            --------------------------------------------------------------------------------
            -- Abort if we didn't get any results:
            --------------------------------------------------------------------------------
            if not next(data) then
                webviewAlert(mod._manager.getWebview(), function() end, i18n("failedToProcessFCPXML"), i18n("shotDataFCPXMLFailedDescription"), i18n("ok"), nil, "warning")
                return
            end

            --------------------------------------------------------------------------------
            -- Convert the titles data to CSV data:
            --------------------------------------------------------------------------------
            local output = ""

            local numberOfHeadings = tableCount(TEMPLATE_ORDER)

            for i=1, numberOfHeadings do
                output = output .. TEMPLATE_ORDER[i]
                if i ~= numberOfHeadings then
                    output = output .. ","
                end
            end

            output = output .. "\n"

            for _, row in pairs(data) do
                for i=1, numberOfHeadings do
                    local currentHeading = TEMPLATE_ORDER[i]
                    local value = row[currentHeading]
                    if value then
                        if value:match(",") then
                            output = output .. [["]] .. value .. [["]]
                        else
                            output = output .. value
                        end
                        if i ~= numberOfHeadings then
                            output = output .. ","
                        end
                    else
                        --------------------------------------------------------------------------------
                        -- This should never happen, unless the Motion Template has changed:
                        --------------------------------------------------------------------------------
                        log.ef("Invalid Heading: %s", currentHeading)
                    end
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
    local result = chooseFileOrFolder(i18n("pleaseSelectAFCPXMLFileToConvert") .. ":", mod.lastOpenPath(), true, false, false, {"fcpxml"}, true)
    local path = result and result["1"]
    if path then
        originalFilename = getFilenameFromPath(path, true)
        mod.lastOpenPath(removeFilenameFromPath(path))
        processFCPXML(path)
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
        --------------------------------------------------------------------------------
        -- Install Motion Template:
        --------------------------------------------------------------------------------
        if callbackType == "installMotionTemplate" then
            installMotionTemplate()
        --------------------------------------------------------------------------------
        -- Convert a FCPXML to CSV:
        --------------------------------------------------------------------------------
        elseif callbackType == "convertFCPXMLtoCSV" then
            convertFCPXMLtoCSV()
        --------------------------------------------------------------------------------
        -- Convert a FCPXML to CSV via Drop Zone:
        -----------------------------
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
            -- Reset the original filename (as we'll use
            -- the project name instead):
            ---------------------------------------------------
            originalFilename = nil

            ---------------------------------------------------
            -- Write the FCPXML data to a temporary file:
            ---------------------------------------------------
            writeToFile(path, value)

            ---------------------------------------------------
            -- Process the FCPXML:
            ---------------------------------------------------
            processFCPXML(path)
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
        height          = 355,
    })
    :addContent(1, generateContent, false)

    --------------------------------------------------------------------------------
    -- Setup Callback Manager:
    --------------------------------------------------------------------------------
    mod._panel:addHandler("onchange", "shotDataPanelCallback", callback)

    return mod
end

return plugin
