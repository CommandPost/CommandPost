--- === plugins.finalcutpro.toolbox.sonytimecode ===
---
--- Adds correct timecode from Sony cameras in a FCPXML.

local require                   = require

local hs                        = _G.hs

local log                       = require "hs.logger".new "sonytimecode"

local dialog                    = require "hs.dialog"
local fs                        = require "hs.fs"
local image                     = require "hs.image"
local inspect                   = require "hs.inspect"

local config                    = require "cp.config"
local fcp                       = require "cp.apple.finalcutpro"
local fcpxml                    = require "cp.apple.fcpxml"
local i18n                      = require "cp.i18n"
local time                      = require "cp.apple.fcpxml.time"
local tools                     = require "cp.tools"

local xml                       = require "hs._asm.xml"

local chooseFileOrFolder        = dialog.chooseFileOrFolder
local doesDirectoryExist        = tools.doesDirectoryExist
local doesFileExist             = tools.doesFileExist
local doesIntersect             = time.doesIntersect
local newFromTimecode           = time.newFromTimecode
local replace                   = tools.replace
local spairs                    = tools.spairs
local tableContains             = tools.tableContains
local tableCount                = tools.tableCount
local urlFromPath               = fs.urlFromPath
local webviewAlert              = dialog.webviewAlert
local writeToFile               = tools.writeToFile

local mod = {}

-- desktopPath -> string
-- Constant
-- Path to the users desktop
local desktopPath = os.getenv("HOME") .. "/Desktop/"

--- plugins.finalcutpro.toolbox.sonytimecode.lastExportPath <cp.prop: string>
--- Field
--- Last Export Path
mod.lastExportPath = config.prop("toolbox.sonytimecode.lastExportPath", desktopPath)

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

-- processFCPXML(path) -> none
-- Function
-- Process a FCPXML file
--
-- Parameters:
--  * path - The path to the FCPXML file.
--
-- Returns:
--  * None
local function processFCPXML(path)
    --------------------------------------------------------------------------------
    -- This is where we'll store a table of clips:
    --------------------------------------------------------------------------------
    local clips = {}

    --------------------------------------------------------------------------------
    -- Open the FCPXML document:
    --------------------------------------------------------------------------------
    local fcpxmlPath = fcpxml.valid(path)
    local document = fcpxmlPath and xml.open(fcpxmlPath)

    --------------------------------------------------------------------------------
    -- Abort if the FCPXML is not valid:
    --------------------------------------------------------------------------------
    if not document then
        local webview = mod._manager.getWebview()
        if webview then
            webviewAlert(webview, function() end, i18n("invalidFCPXMLFile"), i18n("theSuppliedFCPXMLDidNotPassDtdValidationPleaseCheckThatTheFCPXMLSuppliedIsValidAndTryAgain"), i18n("ok"), nil, "warning")
        end
        return
    end

    --------------------------------------------------------------------------------
    -- Access the "FCPXML > Resources":
    --------------------------------------------------------------------------------
    local resourcesContainer = document:XPathQuery("/fcpxml[1]/resources[1]")
    local resources = resourcesContainer and resourcesContainer[1]
    local resourcesChildren = resources and resources:children()

    --------------------------------------------------------------------------------
    -- Access the "FCPXML > Project":
    --------------------------------------------------------------------------------
    local projectContainer = document:XPathQuery("/fcpxml[1]/project[1]")
    local project = projectContainer and projectContainer[1]
    local projectAttributes = project:rawAttributes() and project:attributes()
    local projectName = projectAttributes and projectAttributes.name

    --------------------------------------------------------------------------------
    -- Abort if the FCPXML doesn't contain any Resources:
    --------------------------------------------------------------------------------
    if not projectName or not resourcesChildren or (resourcesChildren and #resourcesChildren < 1) then
        local webview = mod._manager.getWebview()
        if webview then
            webviewAlert(webview, function() end, i18n("invalidDataDetected") .. ".", i18n("sonyTimecodeError"), i18n("ok"), nil, "warning")
        end
        return
    end

    --------------------------------------------------------------------------------
    -- Iterate all the Resources:
    --------------------------------------------------------------------------------
    for _, node in pairs(resourcesChildren) do
        local nodeName = node:name()
        local nodeAttributes = node:rawAttributes() and node:attributes()
        if nodeName == "asset" and nodeAttributes and nodeAttributes.start == "0s" then
            local nodeChildren = node:children() or {}
            for _, nodeChild in pairs(nodeChildren) do
                local nodeChildName = nodeChild:name()
                local nodeChildAttributes = nodeChild:rawAttributes() and nodeChild:attributes()
                if nodeChildName == "media-rep" and nodeChildAttributes and nodeChildAttributes.kind == "original-media" then
                    local src = nodeChildAttributes.src or ""
                    if src:sub(-4) == ".MP4" or src:sub(-4) == ".mp4" then
                        --------------------------------------------------------------------------------
                        -- Remove the file://
                        --------------------------------------------------------------------------------
                        src = replace(src, "file://", "")

                        --------------------------------------------------------------------------------
                        -- Remove any URL encoding:
                        --------------------------------------------------------------------------------
                        src = src:gsub('%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)

                        --------------------------------------------------------------------------------
                        -- Replace the MP4 extension with the XML extension:
                        --------------------------------------------------------------------------------
                        src = src:sub(1, -5) .. "M01.XML"

                        --------------------------------------------------------------------------------
                        -- Does the file actually exist?
                        --------------------------------------------------------------------------------
                        if not doesFileExist(src) then
                            log.df("[Sony Timecode Toolbox] No sidecar file detected: %s", src)
                        else
                            --------------------------------------------------------------------------------
                            -- Lets read the XML sidecar file:
                            --
                            -- Example:
                            --
                            -- <?xml version="1.0" encoding="UTF-8"?>
                            -- <NonRealTimeMeta xmlns="urn:schemas-professionalDisc:nonRealTimeMeta:ver.2.20" xmlns:lib="urn:schemas-professionalDisc:lib:ver.2.00" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" lastUpdate="2022-09-25T11:57:59+10:00">
                            -- 	<TargetMaterial umidRef="060A2B340101010501010D4313000000C20AA47F479805C59C50D1FFFEAC3B63"/>
                            -- 	<Duration value="4380"/>
                            -- 	<LtcChangeTable tcFps="25" halfStep="false">
                            -- 		<LtcChange frameCount="0" value="17305719" status="increment"/>
                            -- 		<LtcChange frameCount="4379" value="21250020" status="end"/>
                            -- 	</LtcChangeTable>
                            -- 	<CreationDate value="2022-09-25T11:57:59+10:00"/>
                            -- 	<VideoFormat>
                            -- 		<VideoRecPort port="DIRECT"/>
                            -- 		<VideoFrame videoCodec="AVC_3840_2160_HP@L51" captureFps="25p" formatFps="25p"/>
                            -- 		<VideoLayout pixel="3840" numOfVerticalLine="2160" aspectRatio="16:9"/>
                            -- 	</VideoFormat>
                            -- 	<AudioFormat numOfChannel="2">
                            -- 		<AudioRecPort port="DIRECT" audioCodec="LPCM16" trackDst="CH1"/>
                            -- 		<AudioRecPort port="DIRECT" audioCodec="LPCM16" trackDst="CH2"/>
                            -- 	</AudioFormat>
                            -- 	<Device manufacturer="Sony" modelName="ILME-FX3" serialNo="4294967295"/>
                            -- 	<RecordingMode type="normal" cacheRec="false"/>
                            -- 	<AcquisitionRecord>
                            -- 		<Group name="CameraUnitMetadataSet">
                            -- 			<Item name="CaptureGammaEquation" value="s-cinetone"/>
                            -- 			<Item name="CaptureColorPrimaries" value="rec709"/>
                            -- 			<Item name="CodingEquations" value="rec709"/>
                            -- 		</Group>
                            -- 		<ChangeTable name="ImagerControlInformation">
                            -- 			<Event status="start" frameCount="0"/>
                            -- 		</ChangeTable>
                            -- 		<ChangeTable name="LensControlInformation">
                            -- 			<Event status="start" frameCount="0"/>
                            -- 		</ChangeTable>
                            -- 		<ChangeTable name="DistortionCorrection">
                            -- 			<Event status="start" frameCount="0"/>
                            -- 		</ChangeTable>
                            -- 		<ChangeTable name="Gyroscope">
                            -- 			<Event status="start" frameCount="0"/>
                            -- 		</ChangeTable>
                            -- 		<ChangeTable name="Accelerometor">
                            -- 			<Event status="start" frameCount="0"/>
                            -- 		</ChangeTable>
                            -- 	</AcquisitionRecord>
                            -- </NonRealTimeMeta>
                            --------------------------------------------------------------------------------
                            local sonyXML = xml.open(src)
                            if not sonyXML then
                                log.df("[Sony Timecode Toolbox] Failed to read sidecar file: %s", src)
                            else
                                --------------------------------------------------------------------------------
                                -- First we get the tcFps value:
                                --------------------------------------------------------------------------------
                                local changeTableContainer = sonyXML:XPathQuery("/NonRealTimeMeta[1]/LtcChangeTable[1]")
                                local changeTableNode = changeTableContainer and changeTableContainer[1]

                                local changeTableNodeAttributes = changeTableNode:rawAttributes() and changeTableNode:attributes()

                                local tcFps = changeTableNodeAttributes and changeTableNodeAttributes.tcFps and tonumber(changeTableNodeAttributes.tcFps)

                                if not tcFps then
                                    log.df("[Sony Timecode Toolbox] Failed to read tcFps: %s", src)
                                else
                                    --------------------------------------------------------------------------------
                                    -- Now lets get the start timecode:
                                    --------------------------------------------------------------------------------
                                    local startTimecodeContainer = sonyXML:XPathQuery("/NonRealTimeMeta[1]/LtcChangeTable[1]/LtcChange[@status='increment']")
                                    local startTimecodeNode = startTimecodeContainer and startTimecodeContainer[1]
                                    if startTimecodeNode then

                                        local startTimecodeAttributes = startTimecodeNode:rawAttributes() and startTimecodeNode:attributes()
                                        local startTimecodeValue = startTimecodeAttributes and startTimecodeAttributes.value

                                        if startTimecodeValue and startTimecodeValue:len() == 8 then
                                            -- 00000000
                                            -- ffssmmhh
                                            -- 12345678
                                            local h = startTimecodeValue:sub(7,8)
                                            local m = startTimecodeValue:sub(5,6)
                                            local s = startTimecodeValue:sub(3,4)
                                            local f = startTimecodeValue:sub(1,2)

                                            local tc = h .. ":" .. m .. ":" .. s .. ":" .. f

                                            local timeValue = time.newFromTimecode(tc, tcFps)

                                            if timeValue then
                                                --------------------------------------------------------------------------------
                                                -- We have our start timecode, lets put it back in the FCPXML:
                                                --------------------------------------------------------------------------------
                                                node:addAttribute("start", time.tostring(timeValue))
                                            else
                                                log.df("[Sony Timecode Toolbox] Failed to add new start timecode: %s", src)
                                            end
                                        else
                                            log.df("[Sony Timecode Toolbox] Failed to read start timecode: %s", src)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Now lets delete the project:
    --------------------------------------------------------------------------------
    projectContainer = document:XPathQuery("/fcpxml[1]/project[1]")
    project = projectContainer and projectContainer[1]

    local fcpxmlContainer = document:XPathQuery("/fcpxml[1]")
    local fcpxmlNode = fcpxmlContainer and fcpxmlContainer[1]

    fcpxmlNode:removeNode(2)

    --------------------------------------------------------------------------------
    -- ...and put it back within an Library > Event:
    --------------------------------------------------------------------------------
    fcpxmlNode:addNode("library")

    local libraryContainer = document:XPathQuery("/fcpxml[1]/library[1]")
    local libraryNode = libraryContainer and libraryContainer[1]

    libraryNode:addNode("event")

    local eventContainer = document:XPathQuery("/fcpxml[1]/library[1]/event[1]")
    local eventNode = eventContainer and eventContainer[1]

    eventNode:insertNode(project)

    --------------------------------------------------------------------------------
    -- Ask where to save the FCPXML:
    --------------------------------------------------------------------------------
    if not doesDirectoryExist(mod.lastExportPath()) then
        mod.lastExportPath(desktopPath)
    end

    local exportPathResult = chooseFileOrFolder(i18n("pleaseSelectAnOutputDirectory") .. ":", mod.lastExportPath(), false, true, false)
    local exportPath = exportPathResult and exportPathResult["1"]

    if exportPath then
        mod.lastExportPath(exportPath)

        --------------------------------------------------------------------------------
        -- Output the revised FCPXML to file:
        --------------------------------------------------------------------------------
        local nodeOptions = xml.nodeOptions.compactEmptyElement | xml.nodeOptions.preserveAll | xml.nodeOptions.useDoubleQuotes | xml.nodeOptions.prettyPrint
        local xmlOutput = document:xmlString(nodeOptions)

        local outputPath = exportPath .. "/" .. projectName .. " - Fixed.fcpxml"

        writeToFile(outputPath, xmlOutput)
    end
end

-- updateUI() -> none
-- Function
-- Update the user interface.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function updateUI()
    local injectScript = mod._manager.injectScript
    local script = [[
    ]]
    injectScript(script)
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
        if callbackType == "dropbox" then
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
            processFCPXML(path)
        elseif callbackType == "updateUI" then
            --------------------------------------------------------------------------------
            -- Update the User Interface:
            --------------------------------------------------------------------------------
            updateUI()
        else
            --------------------------------------------------------------------------------
            -- Unknown Callback:
            --------------------------------------------------------------------------------
            log.df("Unknown Callback in Sony Timecode Toolbox Panel:")
            log.df("id: %s", inspect(id))
            log.df("params: %s", inspect(params))
        end
    end
end

local plugin = {
    id              = "finalcutpro.toolbox.sonytimecode",
    group           = "finalcutpro",
    dependencies    = {
        ["core.toolbox.manager"]        = "manager",
        ["core.preferences.general"]    = "preferences",
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
    mod._preferences            = deps.preferences
    mod._env                    = env

    --------------------------------------------------------------------------------
    -- Setup Utilities Panel:
    --------------------------------------------------------------------------------
    local toolboxID = "sonytimecode"
    mod._panel          =  deps.manager.addPanel({
        priority        = 90,
        id              = toolboxID,
        label           = i18n("sonyTimecode"),
        image           = image.imageFromPath(env:pathToAbsolute("/images/sony.png")),
        tooltip         = i18n("sonyTimecode"),
        height          = 300,
    })
    :addContent(1, generateContent, false)

    --------------------------------------------------------------------------------
    -- Setup Callback Manager:
    --------------------------------------------------------------------------------
    mod._panel:addHandler("onchange", "sonyTimecodePanelCallback", callback)

    --------------------------------------------------------------------------------
    -- Drag & Drop Text to the Dock Icon:
    --------------------------------------------------------------------------------
    mod._preferences.registerDragAndDropTextAction("sonytimecode", i18n("sendFCPXMLToSonyTimecodeToolbox"), function(value)
        ---------------------------------------------------
        -- Setup a temporary file path:
        ---------------------------------------------------
        local path = os.tmpname() .. ".fcpxml"

        ---------------------------------------------------
        -- Write the FCPXML data to a temporary file:
        ---------------------------------------------------
        writeToFile(path, value)

        ---------------------------------------------------
        -- Process the FCPXML:
        ---------------------------------------------------
        processFCPXML(path)
    end)

    --------------------------------------------------------------------------------
    -- Drag & Drop File to the Dock Icon:
    --------------------------------------------------------------------------------
    mod._preferences.registerDragAndDropFileAction("sonytimecode", i18n("sendFCPXMLToSonyTimecodeToolbox"), function(path)
        processFCPXML(path)
    end)

    return mod
end

return plugin
