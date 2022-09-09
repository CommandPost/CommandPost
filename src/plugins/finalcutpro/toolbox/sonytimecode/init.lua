--- === plugins.finalcutpro.toolbox.sonytimecode ===
---
--- Adds correct timecode from Sony cameras in a FCPXML.

local require                   = require

local hs                        = _G["hs"]

local log                       = require "hs.logger".new "sonytimecode"

local dialog                    = require "hs.dialog"
local image                     = require "hs.image"
local inspect                   = require "hs.inspect"

local config                    = require "cp.config"
local fcp                       = require "cp.apple.finalcutpro"
local fcpxml                    = require "cp.apple.fcpxml"
local i18n                      = require "cp.i18n"
local time                      = require "cp.apple.fcpxml.time"
local timecode                  = require "cp.apple.fcpxml.timecode"
local tools                     = require "cp.tools"

local xml                       = require "hs._asm.xml"

local fn                        = require "cp.fn"
local fntable                   = require "cp.fn.table"
local fnvalue                   = require "cp.fn.value"
local chain, pipe               = fn.chain, fn.pipe
local get                       = fntable.get
local is                        = fnvalue.is

local chooseFileOrFolder        = dialog.chooseFileOrFolder
local doesDirectoryExist        = tools.doesDirectoryExist
local doesFileExist             = tools.doesFileExist
local fileLinesBackward         = tools.fileLinesBackward
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

---------------------------------------------------
-- HELPER FUNCTIONS:
---------------------------------------------------

-- xPathQuery(xPath) -> function(node) -> table
-- Function
-- A function combinator that takes an XPath query and returns a function that takes
-- a node and returns the result of the query, usually a table with one or more values.
--
-- Parameters:
--  * xPath - The XPath query.
--
-- Returns:
--  * The function.
local function xPathQuery(xPath)
    return function(node)
        return node:XPathQuery(xPath)
    end
end

-- xPath(value) -> function(node) -> anything | nil
-- Function
-- A function combinator that takes an XPath query and returns a chain function that takes
-- a node and returns the first result of the query, or `nil` if nothing was found.
--
-- Parameters:
--  * xPath - The XPath query.
--
-- Returns:
--  * The chain function.
local function xPath(value)
    return chain // xPathQuery(value) >> get(1)
end


-- name(node) -> string | nil
-- Function
-- Returns the name of the node.
--
-- Parameters:
--  * node - The node.
--
-- Returns:
--  * The name of the node, or `nil` if it doesn't have one.
local function name(node)
    return node:name()
end

-- isNamed(name) -> function(node) -> boolean
-- Function
-- Returns a function that takes a node and returns `true` if the node has the specified name.
--
-- Parameters:
--  * name - The name to check for.
--
-- Returns:
--  * The function.
local function isNamed(value)
    return pipe // name >> is(value)
end

-- attributes(node) -> table | nil
-- Function
-- Returns the attributes of a node as a table if present, or `nil` if not available.
--
-- Parameters:
--  * node - The node.
--
-- Returns:
--  * The attributes table, or `nil`.
local function attributes(node)
    return node:rawAttributes() and node:attributes()
end

-- attribute(name) -> function(node) -> any | nil
-- Function
-- Returns a function that takes a node and returns the value of the attribute with the specified name.
--
-- Parameters:
--  * name - The name of the attribute.
--
-- Returns:
--  * The function.
local function attribute(name)
    return chain // attributes >> get(name)
end

-- children(node) -> table | nil
-- Function
-- Returns the children of a node as a table if present, or `nil` if not available.
--
-- Parameters:
--  * node - The node.
--
-- Returns:
--  * The children table, or `nil`.
local function children(node)
    return node:children()
end

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

-- showError(message) -> false
-- Function
-- Shows an error message, returning `false` to indicate the function failed.
--
-- Parameters:
--  * message - The error message
--
-- Returns:
--  * `false`
local function showError(title, message)
    local webview = mod._manager.getWebview()
    log.ef(message)
    if webview then
        webviewAlert(webview, function() end, title, message, i18n("ok"), nil, "warning")
    end
    return false
end

-- findResources(document) -> table | nil
-- Function
-- Finds the `resources` nodes in a FCPXML document.
--
-- Parameters:
--  * document - The FCPXML document.
--
-- Returns:
--  * The `resources` nodes, or `nil` if not found.
local findResources = chain // xPath "/fcpxml[1]/resources[1]" >> children

-- findProjectName(document) -> string | nil
-- Function
-- Finds the name of the project in a FCPXML document.
--
-- Parameters:
--  * document - The FCPXML document.
--
-- Returns:
--  * The project name, or `nil` if not found.
local findProjectName = chain // xPath "/fcpxml[1]/project[1]" >> attribute "name"

-- findSpineChildren(document) -> table | nil
-- Function
-- Finds the `spine` nodes in a FCPXML document.
--
-- Parameters:
--  * document - The FCPXML document.
--
-- Returns:
--  * The `spine` nodes, or `nil` if not found.
local findSpineChildren = chain // xPath "/fcpxml[1]/project[1]/sequence[1]/spine[1]" >> children

-- isKind(value) -> function(node) -> boolean
-- Function
-- Returns a function that takes a node and returns `true` if the node has the specified `kind` attribute.
--
-- Parameters:
--  * value - The value to check for.
--
-- Returns:
--  * The function.
local function isKind(value)
    return chain // attribute "kind" >> is(value)
end

--- endsWith(value) -> function(node) -> boolean
--- Function
--- Returns a function that takes a node and returns `true` if the node has the specified `src` attribute that ends with the specified value.
---
--- Parameters:
---  * value - The value to check for.
---
--- Returns:
---  * The function.
local function endsWith(value)
    value = value:lower()
    return function(str)
        return str:lower():sub(-#value) == value
    end
end

-- urlToFilename(url) -> string
-- Function
-- Converts a URL to a filename.
--
-- Parameters:
--  * url - The URL.
--
-- Returns:
--  * The filename.
local function urlToFilename(url)
    local path = url:match("file://(.*)")
    --------------------------------------------------------------------------------
    -- Remove any URL encoding:
    --------------------------------------------------------------------------------
    return path:gsub('%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
end

-- exportMP4MetadataToFile(originalSrc) -> string
-- Function
-- Exports the metadata from an MP4 file to a temporary file.
--
-- Parameters:
--  * originalSrc - The MP4 filename.
--
-- Returns:
--  * The temporary filename, or `nil` if an error occurred.
local function exportMP4MetadataToFile(originalPath)
    local startOfMetadata = [[<?xml version="1.0" encoding="UTF-8"?>]]
    local endOfMetadata = "</NonRealTimeMeta>"

    local data = {}

    local count = 0
    local max = 50

    local hasStarted = false

    for line in fileLinesBackward(originalPath) do

        if count >= max then
            return nil
        end

        if line:find(endOfMetadata, 1, true) then
            hasStarted = true
        end

        count = count + 1

        local shouldEnd = false

        if hasStarted and line and line ~= "" then

            local startOfLine = line:find(startOfMetadata, 1, true)
            if startOfLine then
                shouldEnd = true
                line = line:sub(startOfLine)
            end

            table.insert(data, 1, line)
        end

        if shouldEnd then
            break
        end
    end

    if not hasStarted then
        return nil
    end

    local result = table.concat(data, "\n")

    local outputPath = os.tmpname() .. ".xml"

    writeToFile(outputPath, result)

    return outputPath
end

-- findLtcChangeTable(document) -> table | nil
-- Function
-- Finds the LTC Change Table in a FCPXML document.
--
-- Parameters:
--  * document - The FCPXML document.
local findLtcChangeTable = chain // xPath "/NonRealTimeMeta[1]/LtcChangeTable[1]"

-- findLtcChangeStartTimecode(document) -> string | nil
-- Function
-- Finds the timecode for initial "increment" change of the `LtcChangeTable` node.
--
-- Parameters:
--  * document - The `LtcChangeTable` node.
--
-- Returns:
--  * The timecode, or `nil` if not found.
local findLtcChangeStartTimecode =
    chain // xPath "/NonRealTimeMeta[1]/LtcChangeTable[1]/LtcChange[@status='increment']"
        >> attribute "value"

-- processFCPXML(path) -> boolean
-- Function
-- Process a FCPXML file
--
-- Parameters:
--  * path - The path to the FCPXML file.
--
-- Returns:
--  * `true` if successful, `false` if not.
local function processFCPXML(path)
    --------------------------------------------------------------------------------
    -- Open the FCPXML document:
    --------------------------------------------------------------------------------
    local fcpxmlPath = fcpxml.valid(path)
    local document = fcpxmlPath and xml.open(fcpxmlPath)

    --------------------------------------------------------------------------------
    -- Abort if the FCPXML is not valid:
    --------------------------------------------------------------------------------
    if not document then
        return showError(i18n("invalidFCPXMLFile"), i18n("theSuppliedFCPXMLDidNotPassDtdValidationPleaseCheckThatTheFCPXMLSuppliedIsValidAndTryAgain"))
    end

    --------------------------------------------------------------------------------
    -- Access the "FCPXML > Resources":
    --------------------------------------------------------------------------------
    local resourcesChildren = findResources(document) or {}
    if #resourcesChildren < 1 then
        return showError(i18n("invalidDataDetected") .. ".", i18n("sonyTimecodeError"))
    end

    --------------------------------------------------------------------------------
    -- Access the "FCPXML > Project":
    --------------------------------------------------------------------------------
    local projectName = findProjectName(document)

    --------------------------------------------------------------------------------
    -- Abort if the FCPXML doesn't contain a Project:
    --------------------------------------------------------------------------------
    if not projectName then
        return showError(i18n("invalidDataDetected") .. ".", i18n("sonyTimecodeError"))
    end

    --------------------------------------------------------------------------------
    -- Iterate all the Resources to get the format's frameDuration:
    --------------------------------------------------------------------------------
    local frameDurations = {}
    for _, node in pairs(resourcesChildren) do
        if isNamed "format" (node) then
            local nodeAttributes    = attributes(node)
            local id                = nodeAttributes.id
            local frameDuration     = nodeAttributes.frameDuration
            if id and frameDuration then
                frameDurations[id] = time.new(frameDuration)
            end
        end
    end

    --log.df("[Sony Timecode Toolbox] Frame Durations: %s", hs.inspect(frameDurations))

    --------------------------------------------------------------------------------
    -- Iterate all the Resources:
    --------------------------------------------------------------------------------
    local startTimes = {}
    for _, node in pairs(resourcesChildren) do
        if not isNamed "asset" (node) then break end

        local nodeAttributes = attributes(node)
        if not nodeAttributes or nodeAttributes.start ~= "0s" then break end

        local assetID = nodeAttributes.id
        local formatID = nodeAttributes.format
        local frameDuration = frameDurations[formatID]

        if not frameDuration then
            log.df("[Sony Timecode Toolbox] Failed to lookup frame duration for asset: %s.", assetID)
        end

        for _, nodeChild in ipairs(children(node) or {}) do
            if not isNamed "media-rep" (nodeChild) then break end
            if not isKind "original-media" (nodeChild) then break end

            local nodeChildAttributes = attributes(nodeChild)

            local src = nodeChildAttributes.src or ""
            if not endsWith ".mp4" (src) then break end

            --------------------------------------------------------------------------------
            -- Remove the file://
            --------------------------------------------------------------------------------
            src = urlToFilename(src)

            --------------------------------------------------------------------------------
            -- Save the original filename for later:
            --------------------------------------------------------------------------------
            local originalSrc = src

            --------------------------------------------------------------------------------
            -- Replace the MP4 extension with the XML extension:
            --------------------------------------------------------------------------------
            src = src:sub(1, -5) .. "M01.XML"

            --------------------------------------------------------------------------------
            -- Does the sidecar file actually exist?
            --------------------------------------------------------------------------------
            if not doesFileExist(src) then
                log.df("[Sony Timecode Toolbox] No sidecar file detected: %s", src)

                --------------------------------------------------------------------------------
                -- If no sidecar file, lets try the file itself:
                --------------------------------------------------------------------------------
                if doesFileExist(originalSrc) then
                    local outputFile = exportMP4MetadataToFile(originalSrc)
                    if not outputFile then
                        log.df("[Sony Timecode Toolbox] Failed to export metadata from MP4 file: %s", originalSrc)
                        break
                    end

                    src = outputFile
                    log.df("[Sony Timecode Toolbox] Successfully read metadata from file: %s", originalSrc)
                end
            end

            if not doesFileExist(src) then
                log.df("[Sony Timecode Toolbox] No embedded metadata detected: %s", originalSrc)
                break
            end
            
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
                break
            end

            --------------------------------------------------------------------------------
            -- First we get the 'tcFps' value:
            --------------------------------------------------------------------------------
            local ltcChangeTable = findLtcChangeTable(sonyXML)
            local tcFps = attribute "tcFps" (ltcChangeTable) >> tonumber
            if not tcFps then
                log.df("[Sony Timecode Toolbox] Failed to find 'tcFps' value in sidecar file: %s", src)
                break
            end

            local halfStep = attribute "halfStep" (ltcChangeTable) == "true"
            local startTimecodeValue = findLtcChangeStartTimecode(sonyXML)

            if not startTimecodeValue then
                log.df("[Sony Timecode Toolbox] Failed to find 'startTimecodeValue' value in sidecar file: %s", src)
                break
            end

            if not startTimecodeValue:len() == 8 then
                log.df("[Sony Timecode Toolbox] 'startTimecodeValue' value of '%s' is not 8 characters in sidecar file: %s", startTimecodeValue, src)
                break
            end

            local startTimecode = timecode.fromFFSSMMHH(startTimecodeValue)

            local totalFrames = startTimecode:totalFramesWithFPS(tcFps)

            --------------------------------------------------------------------------------
            -- If halfStep is true, we need to double the total frame count
            -- (eg, 50fps recorded, 25fps playback)
            --------------------------------------------------------------------------------
            if halfStep then
                totalFrames = totalFrames * 2
            end

            --------------------------------------------------------------------------------
            -- Now we multiply total frames by the frame duration to get the time in seconds.
            --------------------------------------------------------------------------------
            local timeValue = time.new(totalFrames) * frameDuration

            --------------------------------------------------------------------------------
            -- We have our start timecode, lets put it back in the FCPXML:
            --------------------------------------------------------------------------------
            node:addAttribute("start", time.tostring(timeValue))

            --------------------------------------------------------------------------------
            -- Save the 'start' time for later:
            --------------------------------------------------------------------------------
            startTimes[assetID] = timeValue

            log.df("-----------------------")
            log.df("[Sony Timecode Toolbox] File: %s", originalSrc)
            log.df("[Sony Timecode Toolbox] tcFps from metadata: %s", tcFps)
            log.df("[Sony Timecode Toolbox] halfStep from metadata: %s", halfStep)
            log.df("[Sony Timecode Toolbox] Timecode from metadata: %s", startTimecode)
            log.df("[Sony Timecode Toolbox] Frame Duration from FCPXML: %s", frameDuration)
            log.df("[Sony Timecode Toolbox] Converted Timecode: %s", timeValue)
            log.df("-----------------------")
        end
    end

    --log.df("[Sony Timecode Toolbox] Start Times: %s", hs.inspect(startTimes))

    --------------------------------------------------------------------------------
    -- Iterate all the Spine Elements:
    --------------------------------------------------------------------------------
    local spineChildren = findSpineChildren(document) or {}
    
    for _, node in pairs(spineChildren) do
        if isNamed "asset-clip" (node) then
            local ref       = attribute "ref" (node)
            local start     = attribute "start" (node)
            log.df("Current Asset Ref: %s, Start: %s", ref, start)

            if ref and start then
                local startAsTime = time.new(start)
                local startTime = startTimes[ref]

                if startAsTime and startTime then
                    local newStart = startAsTime + startTime

                    node:addAttribute("start", time.tostring(newStart))

                    log.df("Updated Asset Clip: %s", time.tostring(newStart))
                end
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Now lets delete the project:
    --------------------------------------------------------------------------------
    local project = xPath "/fcpxml[1]/project[1]" (document)
    local fcpxmlNode = xPath "/fcpxml[1]" (document)
    fcpxmlNode:removeNode(2)

    --------------------------------------------------------------------------------
    -- ...and put it back within an Library > Event:
    --------------------------------------------------------------------------------
    fcpxmlNode:addNode("library")
    local libraryNode = xPath "/fcpxml[1]/library[1]" (document)

    libraryNode:addNode("event")
    local eventNode = xPath "/fcpxml[1]/library[1]/event[1]" (document)

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

        --------------------------------------------------------------------------------
        -- Open the folder in Finder:
        --------------------------------------------------------------------------------
        hs.execute([[open "]] .. exportPath .. [["]])
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
