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

local chain                     = fn.chain
local default                   = fnvalue.default
local firstMatching             = fntable.firstMatching
local get                       = fntable.get
local is                        = fnvalue.is
local pipe                      = fn.pipe

local chooseFileOrFolder        = dialog.chooseFileOrFolder
local desktopPath               = tools.desktopPath
local doesDirectoryExist        = tools.doesDirectoryExist
local doesFileExist             = tools.doesFileExist
local fileLinesBackward         = tools.fileLinesBackward
local urlToFilename             = tools.urlToFilename
local webviewAlert              = dialog.webviewAlert
local writeToFile               = tools.writeToFile

local mod = {}

--- plugins.finalcutpro.toolbox.sonytimecode.lastExportPath <cp.prop: string>
--- Field
--- Last Export Path
mod.lastExportPath = config.prop("toolbox.sonytimecode.lastExportPath", desktopPath())

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
    return pipe(name, is(value))
end

-- hasOffsetAttribute(node) -> boolean
-- Function
-- Returns `true` if the node has an `offset` attribute.
--
-- Parameters:
--  * node - The node.
--
-- Returns:
--  * `true` if the node has an `offset` attribute, otherwise `false`.
local function hasOffsetAttribute(node)
    return fcpxml.HAS_OFFSET_ATTRIBUTE[name(node)] == true
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
local function attribute(nodeName)
    return chain // attributes >> get(nodeName)
end

-- children(node) -> table
-- Function
-- Returns the children of a node as a table if present, or `{}` if not available.
--
-- Parameters:
--  * node - The node.
--
-- Returns:
--  * The children table, or `nil`.
local function children(node)
    return node:children() or {}
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

-- findResources(document) -> table
-- Function
-- Finds the `resources` nodes in a FCPXML document.
--
-- Parameters:
--  * document - The FCPXML document.
--
-- Returns:
--  * The `resources` nodes.
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

-- findSpineChildren(document) -> table
-- Function
-- Finds the `spine` nodes in a FCPXML document.
--
-- Parameters:
--  * document - The FCPXML document.
--
-- Returns:
--  * The list of `spine` nodes
local findSpineChildren = chain // xPath "/fcpxml[1]/project[1]/sequence[1]/spine[1]" >> children

-- firstChildNamed(name) -> function(node) -> table | nil
-- Function
-- Returns a function that takes a node and returns the first child with the specified element name.
--
-- Parameters:
--  * name - The name of the child element
--
-- Returns:
--  * The function.
local function firstChildNamed(nameOfChildElement)
    return chain // children >> firstMatching(isNamed(nameOfChildElement))
end

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

-- timeAttribute(key) -> function(node) -> cp.apple.fcpxml.time
-- Function
-- Returns a function that takes a node and returns the value of the specified attribute
-- as a `cp.apple.fcpxml.time` object. Defaults to `0s` if the attribute is not present.
--
-- Parameters:
--  * key - The name of the attribute.
--
-- Returns:
--  * The function.
local function timeAttribute(key)
    return pipe(attribute(key), default "0s", time)
end

-- endsWith(value) -> function(node) -> boolean
-- Function
-- Returns a function that takes a node and returns `true` if the node has the specified `src` attribute that ends with the specified value.
--
-- Parameters:
--  * value - The value to check for.
--
-- Returns:
--  * The function.
local function endsWith(value)
    value = value:lower()
    return function(str)
        return str:lower():sub(-#value) == value
    end
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
    --------------------------------------------------------------------------------
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
local findVideoFrame = chain // xPath "/NonRealTimeMeta[1]/VideoFormat[1]/VideoFrame[1]"

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

-- updateTimeMap(timeMapNode, startTime) -> nil
-- Function
-- Updates the `timeMap`'s `timept` nodes with the new start timecode.
--
-- Parameters:
--  * timeMapNode - The `timeMap` node.
--  * startTime - The new start timecode.
--
-- Returns:
--  * Nothing
local function updateTimeMap(timeMapNode, startTime)
    for _, node in ipairs(children(timeMapNode)) do
        if isNamed "timept" (node) then
            --------------------------------------------------------------------------------
            -- Update the 'timept' to take into account the new asset start:
            --------------------------------------------------------------------------------
            local value = timeAttribute "value" (node)
            local newValue = value + startTime
            -- log.df("[Sony Timecode Toolbox] Updated timept: %s", time.tostring(newValue))
            node:addAttribute("value", tostring(newValue))
        end
    end
end

-- updateOffsetTimeInNode(node, parentStartTime) -> nil
-- Function
-- Updates the `offset` attribute of a node if the parent was changed.
--
-- Parameters:
--  * node - The node.
--  * parentStartTime - The new start timecode of the parent.
--
-- Returns:
--  * Nothing
local function updateOffsetTimeInNode(node, parentStartTime)
    if parentStartTime and hasOffsetAttribute(node) then
        local oldOffset = timeAttribute "offset" (node)
        local newOffset = oldOffset + parentStartTime
        node:addAttribute("offset", tostring(newOffset))
    end
end

-- updateStartTimeInNode(node, startTimes) -> time | nil
-- Function
-- Updates the `node`'s `start` attribute with the new start timecode.
-- Also handles retimed elements (with a `timeMap` child node).
--
-- Parameters:
--  * node - The node to update.
--  * startTimes - The new start timecode.
--  * parentStartTime - The parent's adjusted start time. Set to `nil` if no adjustment required.
--
-- Returns:
--  * The new start time, or `nil` if not found.
local function updateStartTimeInNode(node, startTimes)
    --------------------------------------------------------------------------------
    -- Update the "start" attribute if referencing an adjusted asset:
    --------------------------------------------------------------------------------
    if not isNamed "asset-clip" (node) and not isNamed "video" (node) then return end

    local ref           = attribute "ref" (node)
    local assetStart    = ref and startTimes[ref]

    --------------------------------------------------------------------------------
    -- Only update if we have a new start time in the original asset:
    --------------------------------------------------------------------------------
    if assetStart == nil then return end

    local timeMap = firstChildNamed "timeMap" (node)
    if timeMap then
        --------------------------------------------------------------------------------
        -- Update the 'timeMap' to take into account the new asset start:
        --------------------------------------------------------------------------------
        -- log.df("[Sony Timecode Toolbox] Updating 'timeMap' for asset: %s", ref)
        updateTimeMap(timeMap, assetStart)
    else
        --------------------------------------------------------------------------------
        -- We only update the 'start' if there's no 'timeMap' applied:
        --------------------------------------------------------------------------------
        local newStart  = timeAttribute "start" (node) + assetStart
        node:addAttribute("start", tostring(newStart))
        -- log.df("[Sony Timecode Toolbox] Updated `start` to '%s' for ref: %s", newStart, ref)
        return newStart
    end
end

-- processNodeTable(nodeTable, startTimes, parentStartTime) -> nil
-- Function
-- Updates the `nodeTable`'s `start` attribute with the new start timecode.
-- Also handles retimed elements (with a `timeMap` child node).
--
-- Parameters:
--  * nodeTable - The node table to update.
--  * startTimes - The new start timecode.
--  * parentStartTime - If provided, this is the amount the parent start time was adjusted to.
--
-- Returns:
--  * Nothing
local function processNodeTable(nodeTable, startTimes, parentStartTime)
    for _, node in ipairs(nodeTable) do
        --------------------------------------------------------------------------------
        -- Update the "offset" attribute if referencing an adjusted asset:
        --------------------------------------------------------------------------------
        updateOffsetTimeInNode(node, parentStartTime)

        --------------------------------------------------------------------------------
        -- Process the node:
        --------------------------------------------------------------------------------
        local newStartTime = updateStartTimeInNode(node, startTimes)

        --------------------------------------------------------------------------------
        -- Process the node's children:
        --------------------------------------------------------------------------------
        processNodeTable(children(node), startTimes, newStartTime)
    end
end

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
    local resourcesChildren = findResources(document)
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

    --------------------------------------------------------------------------------
    -- Iterate all the Resources:
    --------------------------------------------------------------------------------
    local startTimes = {}
    for _, node in ipairs(resourcesChildren) do
        if not isNamed "asset" (node) then goto next_resource end

        local nodeAttributes = attributes(node)
        if not nodeAttributes or nodeAttributes.start ~= "0s" then goto next_resource end

        local assetID = nodeAttributes.id
        local formatID = nodeAttributes.format
        local frameDuration = frameDurations[formatID]

        for _, nodeChild in ipairs(children(node)) do
            if not isNamed "media-rep" (nodeChild) then goto next_resource_item end
            if not isKind "original-media" (nodeChild) then goto next_resource_item end

            local src = attribute "src" (nodeChild) or ""
            if not endsWith ".mp4" (src) then goto next_resource_item end

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
                -- log.df("[Sony Timecode Toolbox] No sidecar file detected: %s", src)

                --------------------------------------------------------------------------------
                -- If no sidecar file, lets try the file itself:
                --------------------------------------------------------------------------------
                if doesFileExist(originalSrc) then
                    local outputFile = exportMP4MetadataToFile(originalSrc)
                    if not outputFile then
                        -- log.df("[Sony Timecode Toolbox] Failed to export metadata from MP4 file: %s", originalSrc)
                        goto next_resource_item
                    end

                    src = outputFile
                    -- log.df("[Sony Timecode Toolbox] Successfully read metadata from file: %s", originalSrc)
                end
            end

            if not doesFileExist(src) then
                -- log.df("[Sony Timecode Toolbox] Unable to find metadata: %s", originalSrc)
                goto next_resource_item
            end

            --------------------------------------------------------------------------------
            -- Lets read the XML sidecar file:
            --------------------------------------------------------------------------------
            local sonyXML = xml.open(src)
            if not sonyXML then
                -- log.df("[Sony Timecode Toolbox] Failed to read metadata: %s", src)
                goto next_resource_item
            end

            --------------------------------------------------------------------------------
            -- First we get the 'tcFps' value:
            --------------------------------------------------------------------------------
            local ltcChangeTable = findLtcChangeTable(sonyXML)
            local tcFps = attribute "tcFps" (ltcChangeTable)
            if not tcFps then
                log.wf("[Sony Timecode Toolbox] Failed to find 'tcFps' value in metadata, so skipping file: %s", src)
                goto next_resource_item
            end
            tcFps = tonumber(tcFps)

            --------------------------------------------------------------------------------
            -- Get the half step attribute:
            --------------------------------------------------------------------------------
            local halfStep = attribute "halfStep" (ltcChangeTable) == "true"

            --------------------------------------------------------------------------------
            -- Get the 'formatFps' value:
            --------------------------------------------------------------------------------
            local videoFrame = findVideoFrame(sonyXML)
            local formatFps = attribute "formatFps" (videoFrame)
            if not formatFps then
                log.wf("[Sony Timecode Toolbox] Failed to find 'formatFps' value in metadata, so skipping file: %s", src)
                goto next_resource_item
            end

            --------------------------------------------------------------------------------
            -- Get the start timecode string:
            --------------------------------------------------------------------------------
            local startTimecodeValue = findLtcChangeStartTimecode(sonyXML)
            if not startTimecodeValue then
                log.wf("[Sony Timecode Toolbox] Failed to find starting timecode value in metadata, so skipping file: %s", src)
                goto next_resource_item
            end

            --------------------------------------------------------------------------------
            -- Make sure the timecode string is 8 characters long:
            --------------------------------------------------------------------------------
            if not startTimecodeValue:len() == 8 then
                log.wf("[Sony Timecode Toolbox] Start timecode value of '%s' must be of the format 'FFSSMMHH' in metadata, so skipping file: %s", startTimecodeValue, src)
                goto next_resource_item
            end

            --------------------------------------------------------------------------------
            -- Handle Drop Frame Timecode:
            --------------------------------------------------------------------------------
            if tonumber(startTimecodeValue:sub(1,1)) >= 4 then
                local frameA = tonumber(startTimecodeValue:sub(1, 1))
                frameA = frameA - 4

                if frameA < 0 then
                    frameA = 0
                end

                local newStartTimecodeValue = tostring(frameA) .. startTimecodeValue:sub(2)
                --log.df("[Sony Timecode Toolbox] Converted timecode from %s to %s", startTimecodeValue, newStartTimecodeValue)

                local framerate = 29.97

                local frames, seconds, minutes, hours = newStartTimecodeValue:match("(%d%d)(%d%d)(%d%d)(%d%d)")

                local dropFrames    = math.ceil(framerate * 0.066666);
                local timeBase      = math.ceil(framerate);

                local hourFrames    = timeBase * 60 * 60;
                local minuteFrames  = timeBase * 60;
                local totalMinutes  = (60 * hours) + minutes;
                local totalFrames   = ((hourFrames * hours) + (minuteFrames * minutes) + (timeBase * seconds) + frames) - (dropFrames * (totalMinutes - (math.floor(totalMinutes / 10))));

                if halfStep then
                    --------------------------------------------------------------------------------
                    -- We'll round 59.94fps to 60fps for example:
                    --------------------------------------------------------------------------------
                    local formatFpsNumber = math.ceil(tonumber(formatFps:sub(1, -2)))
                    local multiplier = formatFpsNumber / tcFps
                    if not multiplier == math.floor(multiplier) then
                        log.wf("[Sony Timecode Toolbox] The multiplier is not a whole number (%s), so skipping file. This is a probably a bug in our DF code: %s", multiplier, src)
                        goto next_resource_item
                    end

                    totalFrames = totalFrames * multiplier
                end

                --------------------------------------------------------------------------------
                -- Now we multiply total frames by the frame duration to get the
                -- time in seconds:
                --------------------------------------------------------------------------------
                local totalFramesInTime = time(totalFrames)
                if not totalFramesInTime then
                    log.wf("[Sony Timecode Toolbox] Total Frames in Time is not valid (%s), so skipping file: %s", totalFramesInTime, src)
                    goto next_resource_item
                end

                local timeValue = totalFramesInTime  * frameDuration
                if not timeValue then
                    log.wf("[Sony Timecode Toolbox] Time Value is not valid (%s), so skipping file: %s", timeValue, src)
                    goto next_resource_item
                end

                --------------------------------------------------------------------------------
                -- We have our start timecode, lets put it back in the FCPXML:
                --------------------------------------------------------------------------------
                node:addAttribute("start", tostring(timeValue))

                --------------------------------------------------------------------------------
                -- Save the 'start' time for later:
                --------------------------------------------------------------------------------
                startTimes[assetID] = timeValue

                --------------------------------------------------------------------------------
                -- Go to the next clip:
                --------------------------------------------------------------------------------
                goto next_resource_item
            end

            --------------------------------------------------------------------------------
            -- Convert timecode string into timecode object:
            --------------------------------------------------------------------------------
            local startTimecode = timecode.fromFFSSMMHH(startTimecodeValue)
            if not startTimecode then
                log.wf("[Sony Timecode Toolbox] Failed to calculate start timecode, so skipping file: %s", src)
                goto next_resource_item
            end

            --------------------------------------------------------------------------------
            -- The timecode is always saved with the tcFps value (eg. 25fps), not the actual
            -- FPS of the clip (eg. 50fps), so we need pass that in when parsing:
            --------------------------------------------------------------------------------
            local totalFrames = startTimecode:totalFramesWithFPS(tcFps)
            if not totalFrames then
                log.wf("[Sony Timecode Toolbox] Failed to calculate valid total frames, so skipping file: %s", src)
                goto next_resource_item
            end
            if (totalFrames == math.floor(totalFrames)) == false then
                log.wf("[Sony Timecode Toolbox] Total frames is not a whole number (%s), so skipping file. This is most likely due to Drop Frame timecode: %s", totalFrames, src)
                goto next_resource_item
            end

            --------------------------------------------------------------------------------
            -- However, if halfStep is true, we need to multiply the total frame count to
            -- get the correct amount of time relative to the frame duration.
            -- (eg. 50fps recorded, 25fps playback):
            --------------------------------------------------------------------------------
            if halfStep then
                --------------------------------------------------------------------------------
                -- We'll round 59.94fps to 60fps for example:
                --------------------------------------------------------------------------------
                local formatFpsNumber = math.ceil(tonumber(formatFps:sub(1, -2)))
                local multiplier = formatFpsNumber / tcFps
                if not multiplier == math.floor(multiplier) then
                    log.wf("[Sony Timecode Toolbox] The multiplier is not a whole number (%s), so skipping file. This is most likely due to Drop Frame timecode: %s", multiplier, src)
                    goto next_resource_item
                end

                totalFrames = totalFrames * multiplier
            end

            --------------------------------------------------------------------------------
            -- Now we multiply total frames by the frame duration to get the
            -- time in seconds:
            --------------------------------------------------------------------------------
            local totalFramesInTime = time(totalFrames)
            if not totalFramesInTime then
                log.wf("[Sony Timecode Toolbox] Total Frames in Time is not valid (%s), so skipping file: %s", totalFramesInTime, src)
                goto next_resource_item
            end

            local timeValue = totalFramesInTime  * frameDuration
            if not timeValue then
                log.wf("[Sony Timecode Toolbox] Time Value is not valid (%s), so skipping file: %s", timeValue, src)
                goto next_resource_item
            end

            --------------------------------------------------------------------------------
            -- We have our start timecode, lets put it back in the FCPXML:
            --------------------------------------------------------------------------------
            node:addAttribute("start", tostring(timeValue))

            --------------------------------------------------------------------------------
            -- Save the 'start' time for later:
            --------------------------------------------------------------------------------
            startTimes[assetID] = timeValue

            ::next_resource_item::
        end
        ::next_resource::
    end

    --------------------------------------------------------------------------------
    -- Iterate all the 'spine' nodes to update the start time of asset-clips:
    --------------------------------------------------------------------------------
    processNodeTable(findSpineChildren(document), startTimes)

    --------------------------------------------------------------------------------
    -- Iterate all the 'resources' nodes to update the start time of Compound Clips
    -- and Multicam Clips:
    --------------------------------------------------------------------------------
    processNodeTable(resourcesChildren, startTimes)

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
    -- Create an XML string:
    --------------------------------------------------------------------------------
    local nodeOptions = xml.nodeOptions.compactEmptyElement | xml.nodeOptions.preserveAll | xml.nodeOptions.useDoubleQuotes | xml.nodeOptions.prettyPrint
    local xmlOutput = document:xmlString(nodeOptions)

    --------------------------------------------------------------------------------
    -- Downgrade the FCPXML:
    --------------------------------------------------------------------------------
    xmlOutput = tools.replace(xmlOutput, [[<fcpxml version="1.12">]], [[<fcpxml version="1.11">]])
    xmlOutput = tools.replace(xmlOutput, [[<fcpxml version='1.12'>]], [[<fcpxml version='1.11'>]])
    xmlOutput = tools.replace(xmlOutput, [[<fcpxml version="1.13">]], [[<fcpxml version="1.11">]])
    xmlOutput = tools.replace(xmlOutput, [[<fcpxml version='1.13'>]], [[<fcpxml version='1.11'>]])

    --------------------------------------------------------------------------------
    -- Output a temporary file:
    --------------------------------------------------------------------------------
    local outputPath = os.tmpname() .. ".fcpxml"
    writeToFile(outputPath, xmlOutput)

    --------------------------------------------------------------------------------
    -- Validate the FCPXML before sending to FCPX:
    --------------------------------------------------------------------------------
    local ok, errorMessage = fcpxml.valid(outputPath)
    if not ok then
        log.wf("[Sony Timecode Toolbox] XML Validation Error: %s", errorMessage)
        log.wf("[Sony Timecode Toolbox] Invalid FCPXML was temporarily saved to: %s", outputPath)
        return showError("DTD Validation Failed.", "The data we've generated for Final Cut Pro does not pass DTD validation.\n\nThis is most likely a bug in CommandPost.\n\nPlease refer to the CommandPost Debug Console for the path to the failed FCPXML file if you'd like to review it.\n\nPlease send any useful information to the CommandPost Developers so that this issue can be resolved.")
    end

    --------------------------------------------------------------------------------
    -- Make sure the last output path still exists, otherwise default
    -- back to the Desktop:
    --------------------------------------------------------------------------------
    if not doesDirectoryExist(mod.lastExportPath()) then
        mod.lastExportPath(desktopPath())
    end

    --------------------------------------------------------------------------------
    -- Ask where to save the FCPXML:
    --------------------------------------------------------------------------------
    local exportPathResult = chooseFileOrFolder(i18n("pleaseSelectAnOutputDirectory") .. ":", mod.lastExportPath(), false, true, false)
    local exportPath = exportPathResult and exportPathResult["1"]

    if exportPath then
        --------------------------------------------------------------------------------
        -- Update the last Export Path:
        --------------------------------------------------------------------------------
        mod.lastExportPath(exportPath)

        --------------------------------------------------------------------------------
        -- Write the XML data to file:
        --------------------------------------------------------------------------------
        outputPath = exportPath .. "/" .. projectName .. " - Fixed.fcpxml"
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
            log.ef("Unknown Callback in Sony Timecode Toolbox Panel:")
            log.ef("id: %s", inspect(id))
            log.ef("params: %s", inspect(params))
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
        height          = 335,
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
