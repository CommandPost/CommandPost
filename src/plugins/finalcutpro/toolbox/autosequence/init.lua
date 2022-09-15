--- === plugins.finalcutpro.toolbox.autosequence ===
---
--- Orders clips on a timeline by timecode.

local require                   = require

local hs                        = _G.hs

local log                       = require "hs.logger".new "autosequence"

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

local doesIntersect             = time.doesIntersect
local spairs                    = tools.spairs
local tableContains             = tools.tableContains
local tableCount                = tools.tableCount
local urlFromPath               = fs.urlFromPath
local webviewAlert              = dialog.webviewAlert
local writeToFile               = tools.writeToFile

local mod = {}

--- plugins.finalcutpro.toolbox.autosequence.removeGaps <cp.prop: boolean>
--- Field
--- Remove Gaps?
mod.removeGaps = config.prop("toolbox.autosequence.removeGaps", false)

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
    -- Access the "Project > Sequence > Spine":
    --------------------------------------------------------------------------------
    local spineContainer = document:XPathQuery("/fcpxml[1]/project[1]/sequence[1]/spine[1]")
    local spine = spineContainer and spineContainer[1]
    local spineChildren = spine and spine:children()

    --------------------------------------------------------------------------------
    -- Abort if the FCPXML doesn't contain "Project > Sequence > Spine":
    --------------------------------------------------------------------------------
    if not spineChildren or (spineChildren and #spineChildren < 2) then
        local webview = mod._manager.getWebview()
        if webview then
            webviewAlert(webview, function() end, i18n("invalidDataDetected") .. ".", i18n("autoSequenceError"), i18n("ok"), nil, "warning")
        end
        return
    end

    --------------------------------------------------------------------------------
    -- Iterate all the spine children to find connected titles, and get their
    -- name, duration and position on the timeline:
    --------------------------------------------------------------------------------
    for id, node in pairs(spineChildren) do
        local parentClipType = node:name()
        if parentClipType == "clip" or parentClipType == "asset-clip" or parentClipType == "mc-clip" or parentClipType == "sync-clip" then
            --------------------------------------------------------------------------------
            -- A normal clip, gap, Multi-cam or Synchronised Clip on the Primary Storyline:
            --
            -- EXAMPLE:
            -- <asset-clip ref="r2" offset="0s" name="Red 25fps 10sec" duration="10s" tcFormat="NDF">
            -- <gap name="Gap" offset="0s" start="9067900/2500s" duration="7600/2500s">
            -- <mc-clip ref="r3" offset="10s" name="Multicam" duration="10s">
            -- <sync-clip offset="20s" name="Synchronized Clip" duration="10s" tcFormat="NDF">
            --------------------------------------------------------------------------------

            --------------------------------------------------------------------------------
            -- Save the parent "start" and "offset" of the clip for later use:
            --------------------------------------------------------------------------------
            local nodeAttributes = node:attributes()

            local parentStart = nodeAttributes and nodeAttributes["start"]
            local parentStartAsTime = time.new(parentStart)

            local parentOffset = nodeAttributes and nodeAttributes["offset"]
            local parentOffsetAsTime = time.new(parentOffset)

            local parentDuration = nodeAttributes and nodeAttributes["duration"]
            local parentDurationAsTime = time.new(parentDuration)

            table.insert(clips, {
                id = id,
                offset = parentOffsetAsTime,
                start = parentStartAsTime,
                duration = parentDurationAsTime,
                node = node,
                used = false
            })
        end
    end

    --------------------------------------------------------------------------------
    -- Abort if there's not enough clips:
    --------------------------------------------------------------------------------
    if not clips or (clips and #clips < 2) then
        local webview = mod._manager.getWebview()
        if webview then
            webviewAlert(webview, function() end, i18n("invalidDataDetected") .. ".", i18n("autoSequenceError"), i18n("ok"), nil, "warning")
        end
        return
    end

    --------------------------------------------------------------------------------
    -- Which clip has the earliest start timecode?
    --------------------------------------------------------------------------------
    local earliestClip = clips[1]
    for i = 1, #clips do
        if clips[i].start < earliestClip.start then
            earliestClip = clips[i]
        end
    end

    --------------------------------------------------------------------------------
    -- Update the PROJECT metadata:
    --
    -- <project name="All on primary storyline" uid="24DEC5B7-BD69-4008-96B7-B53F511C6254" modDate="2022-09-05 16:55:29 +1000">
    --------------------------------------------------------------------------------
    local projectObjects = document:XPathQuery("/fcpxml[1]/project[1]")
    local project = projectObjects and projectObjects[1]

    local projectAttributes = project:attributes()

    local originalName = projectAttributes.name

    project:addAttribute("name", originalName .. " ✅")
    project:removeAttribute("uid")
    project:removeAttribute("modDate")

    --------------------------------------------------------------------------------
    -- Update the SEQUENCE metadata:
    --
    -- <sequence format="r1" duration="28302800/10000s" tcStart="3600s" tcFormat="NDF" renderFormat="FFRenderFormatProRes422LT" audioLayout="stereo" audioRate="48k">
    --------------------------------------------------------------------------------
    local sequenceObjects = document:XPathQuery("/fcpxml[1]/project[1]/sequence[1]")
    local sequence = sequenceObjects and sequenceObjects[1]

    sequence:addAttribute("tcStart", time.tostring(earliestClip.start))

    --------------------------------------------------------------------------------
    -- Now we delete the spin and re-create it:
    --------------------------------------------------------------------------------
    sequence:removeNode(1)
    sequence:addNode("spine")

    --------------------------------------------------------------------------------
    -- Reload the spine:
    --------------------------------------------------------------------------------
    spineContainer = document:XPathQuery("/fcpxml[1]/project[1]/sequence[1]/spine[1]")
    spine = spineContainer and spineContainer[1]

    --------------------------------------------------------------------------------
    -- Iterate through all our clips sorted by start timecode:
    --------------------------------------------------------------------------------
    local lastEnd = time.new("0s")
    local laneCount = 1
    for i, clip in spairs(clips, function(t,a,b) return t[a].start < t[b].start end) do
        --------------------------------------------------------------------------------
        -- If we're not already using this clip:
        --------------------------------------------------------------------------------
        if not clip.used then
            --------------------------------------------------------------------------------
            -- It's now used:
            --------------------------------------------------------------------------------
            clips[i].used = true

            --------------------------------------------------------------------------------
            -- First we need to work out what clips are overlapping with the current clip:
            --------------------------------------------------------------------------------
            local aStart        = clip.start
            local aDuration     = clip.duration
            local aEnd          = aStart + aDuration

            local endOfSection  = aEnd

            local currentClips = {}
            table.insert(currentClips, clip)

            for ii = 1, #clips do
                if i ~= ii and clips[ii].used == false then

                    local bStart        = clips[ii].start
                    local bDuration     = clips[ii].duration
                    local bEnd          = bStart + bDuration

                    if doesIntersect(aStart, aDuration, bStart, bDuration) then
                        --------------------------------------------------------------------------------
                        -- This clip intersects with our current clip, so lets save it's node
                        -- for processing later:
                        --------------------------------------------------------------------------------
                        clips[ii].used = true
                        table.insert(currentClips, clips[ii])

                        if bEnd > aEnd then
                            endOfSection = bEnd
                        end
                    end
                end
            end

            --------------------------------------------------------------------------------
            -- Now we sort out our current clips by start timecode to work out which
            -- one goes on the Primary Storyline:
            --------------------------------------------------------------------------------
            local firstClip = true
            local gapStarts
            for _, currentClip in spairs(currentClips, function(t,a,b) return t[a].start < t[b].start end) do
                if firstClip then
                    --------------------------------------------------------------------------------
                    -- The first clip just gets connected to the Primary Storyline:
                    --------------------------------------------------------------------------------
                    firstClip = false

                    local node = currentClip.node
                    node:addAttribute("offset", time.tostring(currentClip.start - lastEnd))

                    spine:insertNode(node)

                    --------------------------------------------------------------------------------
                    -- If "Remove Gaps" is enabled, then do some extra maths:
                    --------------------------------------------------------------------------------
                    if mod.removeGaps() then
                        gapStarts = (currentClip.start - lastEnd) + currentClip.duration
                        lastEnd = lastEnd + gapStarts
                    end
                else
                    --------------------------------------------------------------------------------
                    -- Subsequent clips get connected to the first clip:
                    --------------------------------------------------------------------------------
                    local lastChild = spine:childCount()
                    local lastNode = spine:childAtIndex(lastChild - 1)

                    local node = currentClip.node

                    node:addAttribute("offset", time.tostring(currentClip.start))

                    node:addAttribute("lane", tostring(laneCount))
                    laneCount = laneCount + 1

                    --------------------------------------------------------------------------------
                    -- DTD v1.10:
                    --
                    -- <!-- A 'sync-clip' is a container for other story elements that are used as a synchronized clip. -->
                    -- <!-- Use 'audioStart' and 'audioDuration' to define J/L cuts (i.e., split edits) on composite A/V clips. -->
                    -- <!ELEMENT sync-clip (note?, %timing-params;, %intrinsic-params;, (spine | (%clip_item;) | caption)*, (%marker_item;)*, sync-source*, (%video_filter_item;)*, filter-audio*, metadata?)>
                    --
                    -- <!ENTITY % video_filter_item "(filter-video | filter-video-mask)">
                    -- <!ENTITY % marker_item "(marker | chapter-marker | rating | keyword | analysis-marker)">
                    --------------------------------------------------------------------------------

                    --------------------------------------------------------------------------------
                    -- We need to insert our clip BEFORE markers, 'sync-source', 'filter-video',
                    -- 'filter-video-mask', 'filter-audio' and 'metadata'.
                    --------------------------------------------------------------------------------
                    local whereToInsert = lastNode:childCount() + 1
                    local lastNodeChildren = lastNode:children() or {} -- Just incase there are no children!
                    local abortClipNames = {"marker", "chapter-marker", "rating", "keyword", "analysis-marker", "sync-source", "filter-video", "filter-video-mask", "filter-audio", "metadata"}
                    for ii, vv in pairs(lastNodeChildren) do
                        local abortName = vv:name()
                        if tableContains(abortClipNames, abortName) then
                            whereToInsert = ii
                            break
                        end
                    end

                    lastNode:insertNode(node, whereToInsert)
                end
            end

            --------------------------------------------------------------------------------
            -- If "Remove Gaps" is enabled, add a gap clip on the primary storyline if any
            -- connected clips are longer than the clip on the primary storyline:
            --------------------------------------------------------------------------------
            if mod.removeGaps() and endOfSection > aEnd then
                --------------------------------------------------------------------------------
                -- Example:
                -- <gap name="Gap" offset="3600s" start="3600s" duration="3s">
                --------------------------------------------------------------------------------
                spine:addNode("gap")

                local lastChild = spine:childCount()
                local lastNode = spine:childAtIndex(lastChild - 1)

                local gapDuration = endOfSection - aEnd

                lastNode:addAttribute("name", "Gap")
                lastNode:addAttribute("offset", time.tostring(gapStarts))
                lastNode:addAttribute("start", time.tostring(gapStarts))
                lastNode:addAttribute("duration", time.tostring(gapDuration))
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Now lets "wrap" the project in an "event" to make it cleaner:
    --------------------------------------------------------------------------------
    projectObjects = document:XPathQuery("/fcpxml[1]/project[1]")
    project = projectObjects and projectObjects[1]

    local fcpxmlObjects = document:XPathQuery("/fcpxml[1]")
    local fcpxmlObject = fcpxmlObjects and fcpxmlObjects[1]

    local lastChild = fcpxmlObject:childCount()
    fcpxmlObject:removeNode(lastChild)

    --------------------------------------------------------------------------------
    -- Example:
    -- <event name="6-9-2022 2" uid="E9D98126-4F86-4A9C-AB75-71690571C084">
    --------------------------------------------------------------------------------

    fcpxmlObject:addNode("event")

    lastChild = fcpxmlObject:childCount()

    local event = fcpxmlObject:children()[lastChild]

    event:addAttribute("name", "🎛 Sorted Timelines")

    event:insertNode(project)

    --------------------------------------------------------------------------------
    -- Work out if there's only one library currently open, and if so, lets
    -- insert the library path to make import more seamless.
    --------------------------------------------------------------------------------
    local activeLibraryPaths = fcp:activeLibraryPaths()
    if tableCount(activeLibraryPaths) == 1 then
        local libraryPath = urlFromPath(activeLibraryPaths[1])
        if libraryPath then
            local fcpxmlData = document:XPathQuery("/fcpxml[1]")[1]
            fcpxmlData:addNode("import-options", 1)
            local importOptions = fcpxmlData:children()[1]
            importOptions:addNode("option")
            local importOption = importOptions:children()[1]
            importOption:addAttribute("key", "library location")
            importOption:addAttribute("value", libraryPath)
        end
    end

    --------------------------------------------------------------------------------
    -- Output the revised FCPXML to file:
    --------------------------------------------------------------------------------
    local nodeOptions = xml.nodeOptions.compactEmptyElement | xml.nodeOptions.preserveAll | xml.nodeOptions.useDoubleQuotes | xml.nodeOptions.prettyPrint
    local xmlOutput = document:xmlString(nodeOptions)

    local outputPath = os.tmpname() .. ".fcpxml"

    writeToFile(outputPath, xmlOutput)

    log.df("The Auto Sequence FCPXML was temporarily saved to: %s", outputPath)

    --------------------------------------------------------------------------------
    -- Validate the FCPXML before sending to FCPX:
    --------------------------------------------------------------------------------
    if not fcpxml.valid(outputPath) then
        local webview = mod._manager.getWebview()
        if webview then
            webviewAlert(webview, function() end, "DTD Validation Failed.", "The data we've generated for Final Cut Pro does not pass DTD validation.\n\nThis is most likely a bug in CommandPost.\n\nPlease refer to the CommandPost Debug Console for the path to the failed FCPXML file if you'd like to review it.\n\nPlease send any useful information to the CommandPost Developers so that this issue can be resolved.", i18n("ok"), nil, "warning")
        end
        return
    end

    --------------------------------------------------------------------------------
    -- Send the FCPXML file to Final Cut Pro:
    --------------------------------------------------------------------------------
    fcp:importXML(outputPath)
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
        changeCheckedByID("removeGaps", ]] .. tostring(mod.removeGaps()) .. [[);
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
        elseif callbackType == "updateChecked" then
            --------------------------------------------------------------------------------
            -- Update Checked:
            --------------------------------------------------------------------------------
            local tid = params["id"]
            local value = params["value"]
            if tid == "removeGaps" then
                mod.removeGaps(value)
            end

        elseif callbackType == "updateUI" then
            --------------------------------------------------------------------------------
            -- Update the User Interface:
            --------------------------------------------------------------------------------
            updateUI()
        else
            --------------------------------------------------------------------------------
            -- Unknown Callback:
            --------------------------------------------------------------------------------
            log.df("Unknown Callback in Auto Sequence Toolbox Panel:")
            log.df("id: %s", inspect(id))
            log.df("params: %s", inspect(params))
        end
    end
end

local plugin = {
    id              = "finalcutpro.toolbox.autosequence",
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
    local toolboxID = "autosequence"
    mod._panel          =  deps.manager.addPanel({
        priority        = 10,
        id              = toolboxID,
        label           = i18n("autoSequence"),
        image           = image.imageFromPath(env:pathToAbsolute("/images/XMLD.icns")),
        tooltip         = i18n("autoSequence"),
        height          = 300,
    })
    :addContent(1, generateContent, false)

    --------------------------------------------------------------------------------
    -- Setup Callback Manager:
    --------------------------------------------------------------------------------
    mod._panel:addHandler("onchange", "autosequencePanelCallback", callback)

    --------------------------------------------------------------------------------
    -- Drag & Drop Text to the Dock Icon:
    --------------------------------------------------------------------------------
    mod._preferences.registerDragAndDropTextAction("autoSequence", i18n("sendFCPXMLToAutoSequenceToolbox"), function(value)
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
    mod._preferences.registerDragAndDropFileAction("autoSequence", i18n("sendFCPXMLToAutoSequenceToolbox"), function(path)
        processFCPXML(path)
    end)

    return mod
end

return plugin
