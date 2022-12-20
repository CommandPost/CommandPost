--- === plugins.finalcutpro.toolbox.titlestokeywords ===
---
--- Converts Titles to Keywords

local require                   = require

local hs                        = _G.hs

local log                       = require "hs.logger".new "titlestokeywords"

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

local fn                        = require "cp.fn"
local fntable                   = require "cp.fn.table"
local fnvalue                   = require "cp.fn.value"

local xml                       = require "hs._asm.xml"

local chain                     = fn.chain
local default                   = fnvalue.default
local get                       = fntable.get
local is                        = fnvalue.is
local pipe                      = fn.pipe

local between                   = tools.between
local doesIntersect             = time.doesIntersect
local escapeTilda               = tools.escapeTilda
local lines                     = tools.lines
local replace                   = tools.replace
local tableContains             = tools.tableContains
local tableCount                = tools.tableCount
local trim                      = tools.trim
local urlFromPath               = fs.urlFromPath
local webviewAlert              = dialog.webviewAlert
local writeToFile               = tools.writeToFile

local mod = {}

-- ALTERNATIVE_COMMA -> string
-- Constant
-- An alternative comma to use to avoid a FCPXML bug.
local ALTERNATIVE_COMMA = "‚" -- NOTE: This isn't actually a "normal" comma, even though it looks like one in some fonts.

--- plugins.finalcutpro.toolbox.titlestokeywords.addSpaceAfterSequence <cp.prop: boolean>
--- Field
--- Add Space After Sequence
mod.addSpaceAfterSequence = config.prop("toolbox.titlestokeywords.addSpaceAfterSequence", true)

--- plugins.finalcutpro.toolbox.titlestokeywords.treatFavoriteAndRejectAsRatingsInsteadOfKeywords <cp.prop: boolean>
--- Field
--- Treat FAVORITE and REJECT as ratings instead of keywords
mod.treatFavoriteAndRejectAsRatingsInsteadOfKeywords = config.prop("toolbox.titlestokeywords.treatFavoriteAndRejectAsRatingsInsteadOfKeywords", true)

--- plugins.finalcutpro.toolbox.titlestokeywords.replaceCommasWithAlternativeCommas <cp.prop: boolean>
--- Field
--- Remove Project from Event
mod.replaceCommasWithAlternativeCommas = config.prop("toolbox.titlestokeywords.replaceCommasWithAlternativeCommas", true)

--- plugins.finalcutpro.toolbox.titlestokeywords.removeProjectFromEvent <cp.prop: boolean>
--- Field
--- Remove Project from Event
mod.removeProjectFromEvent = config.prop("toolbox.titlestokeywords.removeProjectFromEvent", true)

--- plugins.finalcutpro.toolbox.titlestokeywords.mergeWithExistingEvent <cp.prop: boolean>
--- Field
--- Merge With Existing Event?
mod.mergeWithExistingEvent = config.prop("toolbox.titlestokeywords.mergeWithExistingEvent", false)

--- plugins.finalcutpro.toolbox.titlestokeywords.useTitleContentsInsteadOfTitleName <cp.prop: boolean>
--- Field
--- Use Title Contents Instead of Title Name?
mod.useTitleContentsInsteadOfTitleName = config.prop("toolbox.titlestokeywords.useTitleContentsInsteadOfTitleName", false)

--- plugins.finalcutpro.toolbox.titlestokeywords.textEditor <cp.prop: string>
--- Field
--- Last Text Editor Value
mod.textEditor = config.prop("toolbox.titlestokeywords.textEditor", "")

--- plugins.finalcutpro.toolbox.titlestokeywords.textEditorTwo <cp.prop: string>
--- Field
--- Last Text Editor Two Value
mod.textEditorTwo = config.prop("toolbox.titlestokeywords.textEditorTwo", "")

--- plugins.finalcutpro.toolbox.titlestokeywords.prefix <cp.prop: string>
--- Field
--- Last Prefix Value
mod.prefix = config.prop("toolbox.titlestokeywords.prefix", " - ")

--- plugins.finalcutpro.toolbox.titlestokeywords.suffix <cp.prop: string>
--- Field
--- Last Suffix Value
mod.suffix = config.prop("toolbox.titlestokeywords.suffix", " - ")

--- plugins.finalcutpro.toolbox.titlestokeywords.startOrEnd <cp.prop: string>
--- Field
--- Last Start or End Value
mod.startOrEnd = config.prop("toolbox.titlestokeywords.startOrEnd", "start")

--- plugins.finalcutpro.toolbox.titlestokeywords.startWith <cp.prop: string>
--- Field
--- Last Start With Value
mod.startWith = config.prop("toolbox.titlestokeywords.startWith", "1")

--- plugins.finalcutpro.toolbox.titlestokeywords.duration <cp.prop: string>
--- Field
--- Duration of the titles created by "Create Titles from Text"
mod.duration = config.prop("toolbox.titlestokeywords.duration", "5")

--- plugins.finalcutpro.toolbox.titlestokeywords.stepValue <cp.prop: string>
--- Field
--- Last Step With Value
mod.stepValue = config.prop("toolbox.titlestokeywords.stepValue", "1")

--- plugins.finalcutpro.toolbox.titlestokeywords.padding <cp.prop: string>
--- Field
--- Last Padding Value
mod.padding = config.prop("toolbox.titlestokeywords.padding", "0")

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

-- findSpineChildren(document) -> table
-- Function
-- Finds the `spine` nodes in a FCPXML document.
--
-- Parameters:
--  * document - The FCPXML document.
--
-- Returns:
--  * The list of `spine` nodes
local findSpineChildren = chain // xPath "/fcpxml[1]/event[1]/project[1]/sequence[1]/spine[1]" >> children

-- getAllTitlesOnTimeline(spineChildren)
-- Function
-- Get all the Titles on a timeline.
--
-- Parameters:
--  * spineChildren - A table of nodes.
--
-- Returns:
--  * A table of title metadata
--  * A table of unique names
local function getAllTitlesOnTimeline(spineChildren)
    local titles = {}
    local uniqueTitleNames = {}
    local titleCount = 1

    --------------------------------------------------------------------------------
    -- Iterate all the spine children to find connected titles, and get their
    -- name, duration and position on the timeline:
    --------------------------------------------------------------------------------
    for _, node in ipairs(spineChildren) do
        if isNamed "clip" (node) or isNamed "asset-clip" (node) or isNamed "mc-clip" (node) or isNamed "sync-clip" (node) or isNamed "gap" (node) then
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

            --------------------------------------------------------------------------------
            -- Iterate all the nodes of the clip:
            --------------------------------------------------------------------------------
            local clipNodes = node:children() or {}
            for _, clipNode in ipairs(clipNodes) do
                if isNamed "spine" (clipNode) then
                    --------------------------------------------------------------------------------
                    -- A secondary storyline:
                    --------------------------------------------------------------------------------
                    local ssOffset = timeAttribute "offset" (clipNode)
                    for _, ssNode in ipairs(children(clipNode)) do
                        if isNamed "title" (ssNode) then
                            --------------------------------------------------------------------------------
                            -- Work out the titles position in relation to the timeline:
                            --------------------------------------------------------------------------------
                            local titleAttributes = ssNode:attributes()

                            local duration = titleAttributes and titleAttributes["duration"]
                            local durationAsTime = time.new(duration)

                            local offset = titleAttributes and titleAttributes["offset"]
                            local offsetAsTime = time.new(offset)

                            --------------------------------------------------------------------------------
                            -- Connected Clip Position on Timeline =
                            -- Connected Clip Offset - Parent Start Time + Parent Offset
                            --------------------------------------------------------------------------------
                            local positionOnTimelineAsTime = offsetAsTime - parentStartAsTime + parentOffsetAsTime + ssOffset

                            --------------------------------------------------------------------------------
                            -- Get the Titles Names:
                            --------------------------------------------------------------------------------
                            local titleNodeName = ""
                            if mod.useTitleContentsInsteadOfTitleName() then
                                local nodeChildren = ssNode:children()
                                for _, nodeChild in ipairs(nodeChildren) do
                                    if nodeChild:name() == "text" then
                                        local textStyles = nodeChild:children() or {}
                                        for _, textStyle in ipairs(textStyles) do
                                            local originalValue = textStyle:stringValue() or ""
                                            originalValue = trim(originalValue)
                                            originalValue = string.gsub(originalValue, "\n", "")
                                            titleNodeName = originalValue
                                        end
                                    end
                                end
                            else
                                titleNodeName = titleAttributes["name"]
                            end

                            --------------------------------------------------------------------------------
                            -- Keep track of unique title names:
                            --------------------------------------------------------------------------------
                            uniqueTitleNames[titleNodeName] = true

                            --------------------------------------------------------------------------------
                            -- Save the title data to a table:
                            --------------------------------------------------------------------------------
                            titles[titleCount] = {}
                            titles[titleCount]["name"]                      = titleNodeName
                            titles[titleCount]["durationAsTime"]            = durationAsTime
                            titles[titleCount]["positionOnTimelineAsTime"]  = positionOnTimelineAsTime
                            titleCount = titleCount + 1
                        end
                    end
                elseif isNamed "title" (clipNode) then
                    --------------------------------------------------------------------------------
                    -- A title connected to a clip in the Primary Storyline:
                    --
                    -- EXAMPLE:
                    --
                    -- <title ref="r3" lane="1" offset="1s" name="One Second" start="3600s" duration="1s">
                    --------------------------------------------------------------------------------

                    --------------------------------------------------------------------------------
                    -- Work out the titles position in relation to the timeline:
                    --------------------------------------------------------------------------------
                    local titleAttributes = clipNode:attributes()

                    local duration = titleAttributes and titleAttributes["duration"]
                    local durationAsTime = time.new(duration)

                    local offset = titleAttributes and titleAttributes["offset"]
                    local offsetAsTime = time.new(offset)

                    --------------------------------------------------------------------------------
                    -- Connected Clip Position on Timeline =
                    -- Connected Clip Offset - Parent Start Time + Parent Offset
                    --------------------------------------------------------------------------------
                    local positionOnTimelineAsTime = offsetAsTime - parentStartAsTime + parentOffsetAsTime

                    --------------------------------------------------------------------------------
                    -- Get the Titles Names:
                    --------------------------------------------------------------------------------
                    local titleNodeName = ""
                    if mod.useTitleContentsInsteadOfTitleName() then
                        local nodeChildren = clipNode:children()
                        for _, nodeChild in ipairs(nodeChildren) do
                            if nodeChild:name() == "text" then
                                local textStyles = nodeChild:children() or {}
                                for _, textStyle in ipairs(textStyles) do
                                    local originalValue = textStyle:stringValue() or ""
                                    originalValue = trim(originalValue)
                                    originalValue = string.gsub(originalValue, "\n", "")
                                    titleNodeName = originalValue
                                end
                            end
                        end
                    else
                        titleNodeName = titleAttributes["name"]
                    end

                    --------------------------------------------------------------------------------
                    -- Keep track of unique title names:
                    --------------------------------------------------------------------------------
                    uniqueTitleNames[titleNodeName] = true

                    --------------------------------------------------------------------------------
                    -- Save the title data to a table:
                    --------------------------------------------------------------------------------
                    titles[titleCount] = {}
                    titles[titleCount]["name"]                      = titleNodeName
                    titles[titleCount]["durationAsTime"]            = durationAsTime
                    titles[titleCount]["positionOnTimelineAsTime"]  = positionOnTimelineAsTime
                    titleCount = titleCount + 1
                end
            end
        end
    end
    return titles, uniqueTitleNames
end

-- checkIfTitlesIntersectWithClips(spineChildren, titles)
-- Function
-- Check if a Title Intersects with Clips:
--
-- Parameters:
--  * spineChildren - A table of nodes.
--  * titles - A table of title metadata
--
-- Returns:
--  * A table of title metadata
local function checkIfTitlesIntersectWithClips(spineChildren, titles)
    local titlesToAdd = {}
    local titlesToAddCount = 1

    --------------------------------------------------------------------------------
    -- Iterate all the spine children again to test each clip on the timeline:
    --------------------------------------------------------------------------------
    for _, node in ipairs(spineChildren) do
        local parentClipType = node:name()
        if parentClipType == "clip" or parentClipType == "asset-clip" or parentClipType == "mc-clip" or parentClipType == "sync-clip" or parentClipType == "gap" then
            --------------------------------------------------------------------------------
            -- Get the 'start', 'offset', 'duration' and 'ref' of the current clip:
            --------------------------------------------------------------------------------
            local nodeAttributes = node:attributes()

            local parentStart = nodeAttributes and nodeAttributes["start"]
            local parentStartAsTime = time.new(parentStart)

            local parentOffset = nodeAttributes and nodeAttributes["offset"]
            local parentOffsetAsTime = time.new(parentOffset)

            local parentDuration = nodeAttributes and nodeAttributes["duration"]
            local parentDurationAsTime = time.new(parentDuration)

            local parentRef = nodeAttributes and nodeAttributes["ref"]
            if parentClipType == "sync-clip" then
                --------------------------------------------------------------------------------
                -- 'sync-clip' doesn't contain a 'ref' so we need to look for an 'asset-clip'
                -- inside to get it:
                --------------------------------------------------------------------------------
                local syncClipNodes = node:children()
                for _, syncClipNode in ipairs(syncClipNodes) do
                    local clipName = syncClipNode:name()
                    if clipName == "asset-clip" then
                        local syncClipAttributes = syncClipNode:attributes()
                        parentRef = syncClipAttributes and syncClipAttributes["ref"]
                    end
                end
            elseif parentClipType == "clip" then
                --------------------------------------------------------------------------------
                -- 'clip' doesn't contain a 'ref' so we need to look for an 'audio' or 'video'
                -- inside to get it:
                --------------------------------------------------------------------------------
                local syncClipNodes = node:children()
                for _, syncClipNode in ipairs(syncClipNodes) do
                    local clipName = syncClipNode:name()
                    if clipName == "audio" or clipName == "video" then
                        local syncClipAttributes = syncClipNode:attributes()
                        parentRef = syncClipAttributes and syncClipAttributes["ref"]
                    end
                end
            end

            --------------------------------------------------------------------------------
            -- First we see if anything on the primary storyline has a title above it:
            --------------------------------------------------------------------------------
            if parentClipType ~= "gap" then
                for _, currentTitle in ipairs(titles) do

                    local titleName                         = currentTitle.name
                    local titlePositionOnTimelineAsTime     = currentTitle.positionOnTimelineAsTime
                    local titleDurationAsTime               = currentTitle.durationAsTime

                    --------------------------------------------------------------------------------
                    -- Is the title position between the clip start time and end time?
                    --------------------------------------------------------------------------------
                    if doesIntersect(titlePositionOnTimelineAsTime, titleDurationAsTime, parentOffsetAsTime, parentDurationAsTime) then
                        local differenceBetweenClipStartAndTitleStartAsTime = titlePositionOnTimelineAsTime - parentOffsetAsTime

                        --------------------------------------------------------------------------------
                        -- Make sure the title doesn't start earlier than the clip:
                        --------------------------------------------------------------------------------
                        if differenceBetweenClipStartAndTitleStartAsTime < time.ZERO then
                            differenceBetweenClipStartAndTitleStartAsTime = time.ZERO
                        end

                        --------------------------------------------------------------------------------
                        -- Calculate the new offset for the clip:
                        --------------------------------------------------------------------------------
                        local newOffsetAsTime = parentStartAsTime + differenceBetweenClipStartAndTitleStartAsTime
                        local newOffsetString = time.tostring(newOffsetAsTime)

                        --------------------------------------------------------------------------------
                        -- Make sure the title doesn't extend past the clip:
                        --------------------------------------------------------------------------------
                        local titleEndPositionAsTime = titlePositionOnTimelineAsTime + titleDurationAsTime
                        local parentEndPositionAsTime = parentOffsetAsTime + parentDurationAsTime
                        if titleEndPositionAsTime >= parentEndPositionAsTime then
                            titleDurationAsTime = parentDurationAsTime - differenceBetweenClipStartAndTitleStartAsTime
                        end
                        local titleDurationString = time.tostring(titleDurationAsTime)

                        --------------------------------------------------------------------------------
                        -- Add a new title:
                        --------------------------------------------------------------------------------
                        titlesToAdd[titlesToAddCount]                  = {}
                        titlesToAdd[titlesToAddCount]["clipType"]      = parentClipType
                        titlesToAdd[titlesToAddCount]["ref"]           = parentRef
                        titlesToAdd[titlesToAddCount]["duration"]      = titleDurationString
                        titlesToAdd[titlesToAddCount]["name"]          = titleName
                        titlesToAdd[titlesToAddCount]["offset"]        = newOffsetString

                        --------------------------------------------------------------------------------
                        -- Increment the title count:
                        --------------------------------------------------------------------------------
                        titlesToAddCount = titlesToAddCount + 1
                    end
                end
            end

            --------------------------------------------------------------------------------
            -- Then we see if there's any other video clips above the primary storyline:
            --------------------------------------------------------------------------------
            local ignoreFirstNodeInSyncClip = true
            local connectedClips = node:children() or {}
            for _, connectedClip in ipairs(connectedClips) do
                local connectedClipType = connectedClip:name()

                --------------------------------------------------------------------------------
                -- Ignore the first node in a sync-clip:
                --------------------------------------------------------------------------------
                local allow = true
                if parentClipType == "sync-clip" then
                    if ignoreFirstNodeInSyncClip then
                        allow = false
                        ignoreFirstNodeInSyncClip = false
                    end
                end

                if allow and connectedClipType == "asset-clip" or connectedClipType == "mc-clip" or connectedClipType == "sync-clip" then
                    --------------------------------------------------------------------------------
                    -- Get the 'start', 'offset' and 'ref' of the current clip:
                    --------------------------------------------------------------------------------
                    local connectedClipAttributes = connectedClip:attributes()

                    local connectedClipStart = connectedClipAttributes and connectedClipAttributes["start"]
                    local connectedClipStartAsTime = time.new(connectedClipStart)

                    local connectedClipOffset = connectedClipAttributes and connectedClipAttributes["offset"]
                    local connectedClipOffsetAsTime = time.new(connectedClipOffset)

                    local connectedClipDuration = connectedClipAttributes and connectedClipAttributes["duration"]
                    local connectedClipDurationAsTime = time.new(connectedClipDuration)

                    local connectedClipRef = connectedClipAttributes and connectedClipAttributes["ref"]

                    --------------------------------------------------------------------------------
                    -- 'sync-clip' doesn't contain a 'ref' so we need to look for an 'asset-clip'
                    -- inside first, before we look for titles:
                    --------------------------------------------------------------------------------
                    if connectedClipType == "sync-clip" then
                        local syncClipNodes = connectedClip:children()
                        for _, syncClipNode in ipairs(syncClipNodes) do
                            local clipName = syncClipNode:name()
                            if clipName == "asset-clip" then
                                local syncClipAttributes = syncClipNode:attributes()
                                connectedClipRef = syncClipAttributes and syncClipAttributes["ref"]
                            end
                        end
                    --------------------------------------------------------------------------------
                    -- 'clip' doesn't contain a 'ref' so we need to look for an 'video' or 'audio'
                    -- inside first, before we look for titles:
                    --------------------------------------------------------------------------------
                    elseif connectedClipType == "clip" then
                        local syncClipNodes = connectedClip:children()
                        for _, syncClipNode in ipairs(syncClipNodes) do
                            local clipName = syncClipNode:name()
                            if clipName == "audio" or clipName == "video" then
                                local syncClipAttributes = syncClipNode:attributes()
                                connectedClipRef = syncClipAttributes and syncClipAttributes["ref"]
                            end
                        end
                    end

                    --------------------------------------------------------------------------------
                    -- Connected Clip Position on Timeline =
                    -- Connected Clip Offset - Parent Start Time + Parent Offset
                    --------------------------------------------------------------------------------
                    local connectedClipPositionOnTimelineAsTime = connectedClipOffsetAsTime - parentStartAsTime + parentOffsetAsTime

                    --------------------------------------------------------------------------------
                    -- Check to see if the current clip overlaps any of our titles:
                    --------------------------------------------------------------------------------
                    for _, currentTitle in ipairs(titles) do

                        local titleName                         = currentTitle.name
                        local titlePositionOnTimelineAsTime     = currentTitle.positionOnTimelineAsTime
                        local titleDurationAsTime               = currentTitle.durationAsTime

                        --------------------------------------------------------------------------------
                        -- Is the title position between the clip start time and end time?
                        --------------------------------------------------------------------------------
                        if doesIntersect(titlePositionOnTimelineAsTime, titleDurationAsTime, connectedClipPositionOnTimelineAsTime, connectedClipDurationAsTime) then

                            local differenceBetweenClipStartAndTitleStartAsTime = titlePositionOnTimelineAsTime - connectedClipPositionOnTimelineAsTime

                            --------------------------------------------------------------------------------
                            -- Make sure the title doesn't start earlier than the clip:
                            --------------------------------------------------------------------------------
                            if differenceBetweenClipStartAndTitleStartAsTime < time.ZERO then
                                differenceBetweenClipStartAndTitleStartAsTime = time.ZERO
                            end

                            --------------------------------------------------------------------------------
                            -- Calculate the new offset for the clip:
                            --------------------------------------------------------------------------------
                            local newOffsetAsTime = connectedClipStartAsTime + differenceBetweenClipStartAndTitleStartAsTime
                            local newOffsetString = time.tostring(newOffsetAsTime)

                            --------------------------------------------------------------------------------
                            -- Make sure the title doesn't extend past the clip:
                            --------------------------------------------------------------------------------
                            local titleEndPositionAsTime = titlePositionOnTimelineAsTime + titleDurationAsTime
                            local parentEndPositionAsTime = connectedClipPositionOnTimelineAsTime + connectedClipDurationAsTime
                            if titleEndPositionAsTime >= parentEndPositionAsTime then
                                titleDurationAsTime = connectedClipDurationAsTime - differenceBetweenClipStartAndTitleStartAsTime
                            end
                            local titleDurationString = time.tostring(titleDurationAsTime)

                            --------------------------------------------------------------------------------
                            -- Add a new title:
                            --------------------------------------------------------------------------------
                            titlesToAdd[titlesToAddCount]                  = {}
                            titlesToAdd[titlesToAddCount]["clipType"]      = connectedClipType
                            titlesToAdd[titlesToAddCount]["ref"]           = connectedClipRef
                            titlesToAdd[titlesToAddCount]["duration"]      = titleDurationString
                            titlesToAdd[titlesToAddCount]["name"]          = titleName
                            titlesToAdd[titlesToAddCount]["offset"]        = newOffsetString

                            --------------------------------------------------------------------------------
                            -- Increment the title count:
                            --------------------------------------------------------------------------------
                            titlesToAddCount = titlesToAddCount + 1
                        end
                    end
                end
            end
        end
    end

    return titlesToAdd
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
    -- Access the "Event > Project > Sequence > Spine":
    --------------------------------------------------------------------------------
    local spineChildren = findSpineChildren(document)

    --------------------------------------------------------------------------------
    -- Abort if the FCPXML doesn't contain "Event > Project > Sequence > Spine":
    --------------------------------------------------------------------------------
    if not spineChildren then
        return showError(i18n("invalidDataDetected") .. ".", i18n("titlesToMarkersNoTitlesDetected"))
    end

    --------------------------------------------------------------------------------
    -- Iterate all the spine children to find connected titles, and get their
    -- name, duration and position on the timeline:
    --------------------------------------------------------------------------------
    local titles, uniqueTitleNames = getAllTitlesOnTimeline(spineChildren)

    --------------------------------------------------------------------------------
    -- Abort - no Titles!
    --------------------------------------------------------------------------------
    if tableCount(titles) == 0 then
        return showError(i18n("invalidDataDetected") .. ".", i18n("titlesToMarkersNoTitlesDetected"))
    end

    --------------------------------------------------------------------------------
    -- Iterate all the spine children again to test each clip on the timeline:
    --------------------------------------------------------------------------------
    local titlesToAdd = checkIfTitlesIntersectWithClips(spineChildren, titles)

    --------------------------------------------------------------------------------
    -- Abort - no Titles!
    --------------------------------------------------------------------------------
    if tableCount(titlesToAdd) == 0 then
        return showError(i18n("invalidDataDetected") .. ".", i18n("titlesToMarkersNoTitlesDetected"))
    end

    --------------------------------------------------------------------------------
    -- Add the new keywords to the END of the event:
    --
    -- EXAMPLE:
    -- <keyword-collection name="One Second"/>
    --------------------------------------------------------------------------------
    local event = xPath "/fcpxml[1]/event[1]" (document)
    for clipName, _ in pairs(uniqueTitleNames) do
        local shouldSkip = false
        if mod.treatFavoriteAndRejectAsRatingsInsteadOfKeywords() then
            if clipName == "FAVORITE" or clipName == "REJECT" then
                shouldSkip = true
            end
        end
        if not shouldSkip then
            event:addNode("keyword-collection")
            local numberOfNodes = event:childCount()
            local newNode = event:children()[numberOfNodes]

            --------------------------------------------------------------------------------
            -- Replace Commas if we need to:
            --------------------------------------------------------------------------------
            local newClipName = clipName
            if mod.replaceCommasWithAlternativeCommas() then
                newClipName = replace(newClipName, ",", ALTERNATIVE_COMMA)
            end
            newNode:addAttribute("name", newClipName)
        end
    end

    --------------------------------------------------------------------------------
    -- Add the new keywords to the individual clips:
    --
    -- EXAMPLE:
    -- <asset-clip ref="r1" name="Green 25fps 10sec" duration="10s" format="r2" tcFormat="NDF" modDate="2022-08-05 15:48:48 +1000">
    --     <keyword start="1s" duration="1s" value="One Second"/>
    -- </asset-clip>
    --------------------------------------------------------------------------------
    local eventChildren = event:children()
    for _, eventNode in ipairs(eventChildren) do
        local clipType = eventNode:name()
        if clipType == "asset-clip" or clipType == "mc-clip" or clipType == "gap" then
            --------------------------------------------------------------------------------
            -- Add markers for asset-clip and mc-clip's:
            --------------------------------------------------------------------------------
            local attributes = eventNode:attributes()
            for _, v in ipairs(titlesToAdd) do
                if v.ref == attributes.ref and v.clipType == "asset-clip" then
                    --------------------------------------------------------------------------------
                    -- DTD v1.10:
                    --
                    -- <!-- An 'asset-clip' is a clip that references an asset. -->
                    -- <!-- All available media components in the asset are implicitly included. -->
                    -- <!-- Clips have a media reference and zero or more anchored items. -->
                    -- <!-- Use 'audioStart' and 'audioDuration' to define J/L cuts (i.e., split edits) on composite A/V clips. -->
                    -- <!ELEMENT asset-clip (note?, %timing-params;, %intrinsic-params;, (%anchor_item;)*, (%marker_item;)*, audio-channel-source*, (%video_filter_item;)*, filter-audio*, metadata?)>
                    --
                    -- <!ENTITY % video_filter_item "(filter-video | filter-video-mask)">
                    --------------------------------------------------------------------------------

                    --------------------------------------------------------------------------------
                    -- We need to insert our 'keyword' BEFORE markers, 'audio-channel-source',
                    -- 'filter-video', 'filter-video-mask', 'filter-audio' and 'metadata':
                    --------------------------------------------------------------------------------
                    local whereToInsert = eventNode:childCount() + 1
                    local eventNodeChildren = eventNode:children() or {} -- Just incase there are no children!
                    local abortClipNames = {"marker", "chapter-marker", "rating", "keyword", "analysis-marker", "audio-channel-source", "filter-video", "filter-video-mask", "filter-audio", "metadata"}
                    for i, vv in ipairs(eventNodeChildren) do
                        local abortName = vv:name()
                        if tableContains(abortClipNames, abortName) then
                            whereToInsert = i
                            break
                        end
                    end

                    --------------------------------------------------------------------------------
                    -- Is it a keyword or a rating?
                    --------------------------------------------------------------------------------
                    local newNodeType = "keyword"
                    if mod.treatFavoriteAndRejectAsRatingsInsteadOfKeywords() and v.name == "FAVORITE" or v.name == "REJECT" then
                        newNodeType = "rating"
                    end

                    eventNode:addNode(newNodeType, whereToInsert)
                    local newNode = eventNode:children()[whereToInsert]
                    newNode:addAttribute("start", v.offset)
                    newNode:addAttribute("duration", v.duration)

                    --------------------------------------------------------------------------------
                    -- Replace Commas if we need to:
                    --------------------------------------------------------------------------------
                    local newClipName = v.name
                    if mod.replaceCommasWithAlternativeCommas() then
                        newClipName = replace(newClipName, ",", ALTERNATIVE_COMMA)
                    end
                    if newNodeType == "rating" then
                        newClipName = string.lower(newClipName)
                    end
                    newNode:addAttribute("value", newClipName)
                elseif v.ref == attributes.ref and v.clipType == "mc-clip" then
                    --------------------------------------------------------------------------------
                    -- DTD v1.10:
                    --
                    -- <!-- An 'mc-clip' element defines an edited range of a/v data from a source 'multicam' media. -->
                    -- <!ELEMENT mc-clip (note?, %timing-params;, %intrinsic-params-audio;, mc-source*, (%anchor_item;)*, (%marker_item;)*, filter-audio*, metadata?)>
                    --------------------------------------------------------------------------------

                    --------------------------------------------------------------------------------
                    -- We need to insert our 'keyword' BEFORE markers, 'filter-audio' and 'metadata':
                    --------------------------------------------------------------------------------
                    local whereToInsert = eventNode:childCount() + 1
                    local eventNodeChildren = eventNode:children() or {} -- Just incase there are no children!
                    local abortClipNames = {"marker", "chapter-marker", "rating", "keyword", "analysis-marker", "filter-audio", "metadata"}
                    for i, vv in ipairs(eventNodeChildren) do
                        local abortName = vv:name()
                        if tableContains(abortClipNames, abortName) then
                            whereToInsert = i
                            break
                        end
                    end

                    --------------------------------------------------------------------------------
                    -- Is it a keyword or a rating?
                    --------------------------------------------------------------------------------
                    local newNodeType = "keyword"
                    if mod.treatFavoriteAndRejectAsRatingsInsteadOfKeywords() and v.name == "FAVORITE" or v.name == "REJECT" then
                        newNodeType = "rating"
                    end

                    eventNode:addNode(newNodeType, whereToInsert)
                    local newNode = eventNode:children()[whereToInsert]
                    newNode:addAttribute("start", v.offset)
                    newNode:addAttribute("duration", v.duration)

                    --------------------------------------------------------------------------------
                    -- Replace Commas if we need to:
                    --------------------------------------------------------------------------------
                    local newClipName = v.name
                    if mod.replaceCommasWithAlternativeCommas() then
                        newClipName = replace(newClipName, ",", ALTERNATIVE_COMMA)
                    end
                    if newNodeType == "rating" then
                        newClipName = string.lower(newClipName)
                    end
                    newNode:addAttribute("value", newClipName)
                end
            end
        elseif clipType == "sync-clip" then
            --------------------------------------------------------------------------------
            -- Add markers for sync-clips:
            --------------------------------------------------------------------------------
            local syncClipNodes = eventNode:children()
            for _, syncClipNode in ipairs(syncClipNodes) do
                local syncClipNodeName = syncClipNode:name()
                if syncClipNodeName == "asset-clip" or syncClipNodeName == "mc-clip" then
                    local attributes = syncClipNode:attributes()
                    for _, v in ipairs(titlesToAdd) do
                        if v.ref == attributes.ref and v.clipType == "sync-clip" then
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
                            -- We need to insert our 'keyword' BEFORE markers, 'sync-source', 'filter-video',
                            -- 'filter-video-mask', 'filter-audio' and 'metadata'.
                            --------------------------------------------------------------------------------
                            local whereToInsert = eventNode:childCount() + 1
                            local eventNodeChildren = eventNode:children()  or {} -- Just incase there are no children!
                            local abortClipNames = {"marker", "chapter-marker", "rating", "keyword", "analysis-marker", "sync-source", "filter-video", "filter-video-mask", "filter-audio", "metadata"}
                            for i, vv in pairs(eventNodeChildren) do
                                local abortName = vv:name()
                                if tableContains(abortClipNames, abortName) then
                                    whereToInsert = i
                                    break
                                end
                            end

                            --------------------------------------------------------------------------------
                            -- Is it a keyword or a rating?
                            --------------------------------------------------------------------------------
                            local newNodeType = "keyword"
                            if mod.treatFavoriteAndRejectAsRatingsInsteadOfKeywords() and v.name == "FAVORITE" or v.name == "REJECT" then
                                newNodeType = "rating"
                            end

                            eventNode:addNode(newNodeType, whereToInsert)
                            local newNode = eventNode:children()[whereToInsert]
                            newNode:addAttribute("start", v.offset)
                            newNode:addAttribute("duration", v.duration)

                            --------------------------------------------------------------------------------
                            -- Replace Commas if we need to:
                            --------------------------------------------------------------------------------
                            local newClipName = v.name
                            if mod.replaceCommasWithAlternativeCommas() then
                                newClipName = replace(newClipName, ",", ALTERNATIVE_COMMA)
                            end
                            if newNodeType == "rating" then
                                newClipName = string.lower(newClipName)
                            end
                            newNode:addAttribute("value", newClipName)
                        end
                    end
                end
            end
        elseif clipType == "clip" then
            --------------------------------------------------------------------------------
            -- Add markers for clips:
            --------------------------------------------------------------------------------
            local syncClipNodes = eventNode:children()
            for _, syncClipNode in ipairs(syncClipNodes) do
                local syncClipNodeName = syncClipNode:name()
                if syncClipNodeName == "audio" or syncClipNodeName == "video" then
                    local currentAttributes = syncClipNode:attributes()
                    for _, v in ipairs(titlesToAdd) do
                        if v.ref == currentAttributes.ref and v.clipType == "clip" then
                            --------------------------------------------------------------------------------
                            -- DTD v1.10:
                            --
                            -- <!-- A 'clip' is a container for other story elements. -->
                            -- <!-- Clips have only one primary item, and zero or more anchored items. -->
                            -- <!-- Use 'audioStart' and 'audioDuration' to define J/L cuts (i.e., split edits) on composite A/V clips. -->
                            --
                            -- <!ELEMENT clip (note?, %timing-params;, %intrinsic-params;, (spine | (%clip_item;) | caption)*, (%marker_item;)*, audio-channel-source*, (%video_filter_item;)*, filter-audio*, metadata?)>
                            -- <!ATTLIST clip %clip_attrs;>
                            -- <!ATTLIST clip format IDREF #IMPLIED>				<!-- default is same as parent -->
                            -- <!ATTLIST clip audioStart %time; #IMPLIED>
                            -- <!ATTLIST clip audioDuration %time; #IMPLIED>
                            -- <!ATTLIST clip tcStart %time; #IMPLIED>				<!-- clip timecode origin -->
                            -- <!ATTLIST clip tcFormat (DF | NDF) #IMPLIED>		<!-- timecode display format (DF=drop frame; NDF=non-drop frame) -->
                            -- <!ATTLIST clip modDate CDATA #IMPLIED>
                            --
                            --------------------------------------------------------------------------------

                            --------------------------------------------------------------------------------
                            -- We need to insert our 'keyword' BEFORE markers, 'audio-channel-source',
                            -- 'filter-video', 'filter-video-mask', 'filter-audio' and 'metadata'.
                            --------------------------------------------------------------------------------
                            local whereToInsert = eventNode:childCount() + 1
                            local eventNodeChildren = eventNode:children()  or {} -- Just incase there are no children!
                            local abortClipNames = {"marker", "chapter-marker", "rating", "keyword", "analysis-marker", "audio-channel-source", "filter-video", "filter-video-mask", "filter-audio", "metadata"}
                            for i, vv in pairs(eventNodeChildren) do
                                local abortName = vv:name()
                                if tableContains(abortClipNames, abortName) then
                                    whereToInsert = i
                                    break
                                end
                            end

                            --------------------------------------------------------------------------------
                            -- Is it a keyword or a rating?
                            --------------------------------------------------------------------------------
                            local newNodeType = "keyword"
                            if mod.treatFavoriteAndRejectAsRatingsInsteadOfKeywords() and v.name == "FAVORITE" or v.name == "REJECT" then
                                newNodeType = "rating"
                            end

                            eventNode:addNode(newNodeType, whereToInsert)
                            local newNode = eventNode:children()[whereToInsert]
                            newNode:addAttribute("start", v.offset)
                            newNode:addAttribute("duration", v.duration)

                            --------------------------------------------------------------------------------
                            -- Replace Commas if we need to:
                            --------------------------------------------------------------------------------
                            local newClipName = v.name
                            if mod.replaceCommasWithAlternativeCommas() then
                                newClipName = replace(newClipName, ",", ALTERNATIVE_COMMA)
                            end
                            if newNodeType == "rating" then
                                newClipName = string.lower(newClipName)
                            end
                            newNode:addAttribute("value", newClipName)
                        end
                    end
                end
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Remove the project from the FCPXML:
    --------------------------------------------------------------------------------
    if mod.removeProjectFromEvent() then
        local projectIndex
        eventChildren = event:children()
        for i, eventNode in ipairs(eventChildren) do
            local clipType = eventNode:name()
            if clipType == "project" then
                projectIndex = i
                break
            end
        end
        event:removeNode(projectIndex)
    end

    --------------------------------------------------------------------------------
    -- Rename Event Metadata:
    --------------------------------------------------------------------------------
    if not mod.mergeWithExistingEvent() then
        local originalEventName = event:attributes().name
        event:addAttribute("name", originalEventName .. " ✅")
        event:removeAttribute("uid")
    end

    --------------------------------------------------------------------------------
    -- Work out if there's only one library currently open, and if so, lets
    -- insert the library path to make import more seamless.
    --------------------------------------------------------------------------------
    local activeLibraryPaths = fcp:activeLibraryPaths()
    if tableCount(activeLibraryPaths) == 1 then
        local libraryPath = urlFromPath(activeLibraryPaths[1])
        if libraryPath then
            local fcpxmlData = xPath "/fcpxml[1]" (document)
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

    log.df("The Titles To Keywords FCPXML was temporarily saved to: %s", outputPath)

    --------------------------------------------------------------------------------
    -- Validate the FCPXML before sending to FCPX:
    --------------------------------------------------------------------------------
    if not fcpxml.valid(outputPath) then
        return showError("DTD Validation Failed.", "The data we've generated for Final Cut Pro does not pass DTD validation.\n\nThis is most likely a bug in CommandPost.\n\nPlease refer to the CommandPost Debug Console for the path to the failed FCPXML file if you'd like to review it.\n\nPlease send any useful information to the CommandPost Developers so that this issue can be resolved.")
    end

    --------------------------------------------------------------------------------
    -- Send the FCPXML file to Final Cut Pro:
    --------------------------------------------------------------------------------
    fcp:importXML(outputPath)
end

-- createTitlesFromText(text) -> none
-- Function
-- Create Titles from Text.
--
-- Parameters:
--  * text - The text to process.
--
-- Returns:
--  * None
local function createTitlesFromText(textA, textB)
    --------------------------------------------------------------------------------
    -- Start with a FCPXML Template:
    --------------------------------------------------------------------------------
    local templatePath = config.basePath .. "/plugins/finalcutpro/toolbox/titlestokeywords/templates/empty.fcpxml"
    local document = xml.open(templatePath)

    --------------------------------------------------------------------------------
    -- Access the "Event > Project > Sequence > Spine":
    --------------------------------------------------------------------------------
    local spine = xPath "/fcpxml[1]/library[1]/event[1]/project[1]/sequence[1]/spine[1]" (document)

    local duration = tonumber(mod.duration())

    local durationAsTime = time.new(duration)

    local textLinesA = lines(textA)
    local numberOfLinesInA = #textLinesA

    local textLines = lines(textA .. "\n" .. textB)

    if mod.treatFavoriteAndRejectAsRatingsInsteadOfKeywords() then
        table.insert(textLines, 1, "REJECT")
        table.insert(textLines, 1, "FAVORITE")
    end

    --------------------------------------------------------------------------------
    -- Ignore if there's no text to process:
    --------------------------------------------------------------------------------
    if #textLines == 0 then
        return showError(i18n("noTextDetected"), i18n("noTextDetectedDescription"))
    end

    local totalDuration = durationAsTime * time.new(#textLines)

    --------------------------------------------------------------------------------
    -- Add a Gap on the primary storyline:
    --
    -- <gap name="Gap" offset="0s" start="3600s" duration="36s">
    --------------------------------------------------------------------------------
    spine:addNode("gap")
    local gap = xPath "/fcpxml[1]/library[1]/event[1]/project[1]/sequence[1]/spine[1]/gap[1]" (document)
    gap:addAttribute("name", "Gap")
    gap:addAttribute("offset", "0s")
    gap:addAttribute("start", "0s")
    gap:addAttribute("duration", time.tostring(totalDuration))

    --------------------------------------------------------------------------------
    -- Add a secondary storyline:
    --
    -- <spine lane="1" offset="3600s">
    --------------------------------------------------------------------------------
    gap:addNode("spine")
    local secondaryStoryline = xPath "/fcpxml[1]/library[1]/event[1]/project[1]/sequence[1]/spine[1]/gap[1]/spine[1]" (document)
    secondaryStoryline:addAttribute("lane", "1")
    secondaryStoryline:addAttribute("offset", "0s")

    for i, v in ipairs(textLines) do
        --------------------------------------------------------------------------------
        -- EXAMPLE:
        --
        -- <title ref="r2" offset="0s" name="AAA" start="3600s" duration="25100/2500s">
        --     <text>
        --         <text-style ref="ts1">Title</text-style>
        --     </text>
        --     <text-style-def id="ts1">
        --         <text-style font="Helvetica" fontSize="63" fontFace="Regular" fontColor="1 1 1 1" alignment="center"/>
        --     </text-style-def>
        -- </title>
        --------------------------------------------------------------------------------
        secondaryStoryline:addNode("title")
        local titleNode = secondaryStoryline:children()[i]

        local offset = (i - 1) * duration
        local offsetAsTime = time.new(offset)

        titleNode:addAttribute("ref", "r2")
        titleNode:addAttribute("offset",  time.tostring(offsetAsTime))
        titleNode:addAttribute("name", v)
        titleNode:addAttribute("start", "0s")
        titleNode:addAttribute("duration", time.tostring(durationAsTime))

        --------------------------------------------------------------------------------
        -- Add roles:
        --------------------------------------------------------------------------------
        titleNode:addAttribute("role", "KEYWORD.KEYWORD-1")
        if mod.treatFavoriteAndRejectAsRatingsInsteadOfKeywords() then
            if v == "REJECT" then
                titleNode:addAttribute("role", "REJECT.REJECT-1")
            elseif v == "FAVORITE" then
                titleNode:addAttribute("role", "FAVORITE.FAVORITE-1")
            end
        end

        --------------------------------------------------------------------------------
        -- Add Position Metadata if needed:
        --------------------------------------------------------------------------------
        local positionValue
        local countOffset = 0
        if mod.treatFavoriteAndRejectAsRatingsInsteadOfKeywords() then
            countOffset = 2
            if i == 1 then
                positionValue = "0 -200"
            elseif i == 2 then
                positionValue = "0 -300"
            end
        end
        if not positionValue and i <= (numberOfLinesInA + countOffset) then
            if ((i - countOffset) % 2 == 0) then
                --------------------------------------------------------------------------------
                -- Offset the position of every even title in the left text box:
                --------------------------------------------------------------------------------
                positionValue = "0 -100"
            end
        end
        if i > (numberOfLinesInA + countOffset) then
            positionValue = "0 100"
        end
        if positionValue then
            --------------------------------------------------------------------------------
            -- Example:
            --
            -- <param name="Position" key="9999/999166631/999166633/1/100/101" value="0 100"/>
            --------------------------------------------------------------------------------
            titleNode:addNode("param")
            local positionNode = titleNode:children()[1]
            positionNode:addAttribute("name", "Position")
            positionNode:addAttribute("key", "9999/999166631/999166633/1/100/101")
            positionNode:addAttribute("value", positionValue)
        end

        titleNode:addNode("text")
        local textNode = titleNode:children()[titleNode:childCount()]

        textNode:addNode("text-style")
        local textStyleNode = textNode:children()[1]

        textStyleNode:addAttribute("ref", "ts" .. i)
        textStyleNode:setStringValue(v)


        titleNode:addNode("text-style-def")
        local textStyleDefNode = titleNode:children()[titleNode:childCount()]

        textStyleDefNode:addAttribute("id", "ts" .. i)

        textStyleDefNode:addNode("text-style")

        local textStyleDefTextStyleNode = textStyleDefNode:children()[1]

        textStyleDefTextStyleNode:addAttribute("font", "Helvetica")

        --------------------------------------------------------------------------------
        -- Adjust font size:
        --------------------------------------------------------------------------------
        local fontSize = "30"
        if mod.treatFavoriteAndRejectAsRatingsInsteadOfKeywords() then
            if i == 1 or i == 2 then
                fontSize = "50"
            end
        end
        if i > (numberOfLinesInA + countOffset) then
            fontSize = "50"
        end

        textStyleDefTextStyleNode:addAttribute("fontSize", fontSize)
        textStyleDefTextStyleNode:addAttribute("fontFace", "Regular")
        textStyleDefTextStyleNode:addAttribute("fontColor", "1 1 1 1")
        textStyleDefTextStyleNode:addAttribute("alignment", "center")
    end

    --------------------------------------------------------------------------------
    -- Work out if there's only one library currently open, and if so, lets
    -- insert the library path to make import more seamless.
    --------------------------------------------------------------------------------
    local activeLibraryPaths = fcp:activeLibraryPaths()
    if tableCount(activeLibraryPaths) == 1 then
        local libraryPath = urlFromPath(activeLibraryPaths[1])
        if libraryPath then
            local fcpxmlData = xPath "/fcpxml[1]" (document)
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

    log.df("The Titles from Text FCPXML was temporarily saved to: %s", outputPath)

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
        changeValueByID("textEditor", `]]   .. escapeTilda(mod.textEditor())    .. [[`);
        changeValueByID("textEditorTwo", `]].. escapeTilda(mod.textEditorTwo()) .. [[`);
        changeValueByID("prefix", `]]       .. escapeTilda(mod.prefix())        .. [[`);
        changeValueByID("suffix", `]]       .. escapeTilda(mod.suffix())        .. [[`);
        changeValueByID("startOrEnd", `]]   .. escapeTilda(mod.startOrEnd())    .. [[`);
        changeValueByID("startWith", `]]    .. escapeTilda(mod.startWith())     .. [[`);
        changeValueByID("stepValue", `]]    .. escapeTilda(mod.stepValue())     .. [[`);
        changeValueByID("padding", `]]      .. escapeTilda(mod.padding())       .. [[`);
        changeValueByID("duration", `]]     .. escapeTilda(mod.duration())      .. [[`);

        changeCheckedByID("mergeWithExistingEvent", ]] .. tostring(mod.mergeWithExistingEvent()) .. [[);
        changeCheckedByID("useTitleContentsInsteadOfTitleName", ]] .. tostring(mod.useTitleContentsInsteadOfTitleName()) .. [[);
        changeCheckedByID("removeProjectFromEvent", ]] .. tostring(mod.removeProjectFromEvent()) .. [[);
        changeCheckedByID("replaceCommasWithAlternativeCommas", ]] .. tostring(mod.replaceCommasWithAlternativeCommas()) .. [[);
        changeCheckedByID("treatFavoriteAndRejectAsRatingsInsteadOfKeywords", ]] .. tostring(mod.treatFavoriteAndRejectAsRatingsInsteadOfKeywords()) .. [[);
        changeCheckedByID("addSpaceAfterSequence", ]] .. tostring(mod.addSpaceAfterSequence()) .. [[);
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
        elseif callbackType == "sendToFinalCutPro" then
            --------------------------------------------------------------------------------
            -- Send to Final Cut Pro:
            --------------------------------------------------------------------------------
            local textEditor = params["textEditor"]
            local textEditorTwo = params["textEditorTwo"]

            createTitlesFromText(textEditor, textEditorTwo)
        elseif callbackType == "addSequence" then
            --------------------------------------------------------------------------------
            -- Add Sequence:
            --------------------------------------------------------------------------------
            local startWith = params["startWith"]
            local padding = params["padding"]
            local stepValue = params["stepValue"]
            local startOrEnd = params["startOrEnd"]
            local textEditor = params["textEditor"]
            local textEditorLines = textEditor:split("\n")

            local prefix = ""
            if mod.addSpaceAfterSequence() then
                prefix = " "
            end

            local counter = tonumber(startWith)

            for i, v in pairs(textEditorLines) do
                local sequenceValue = string.format("%0" .. padding .. "d", counter)

                if startOrEnd == "start" then
                    textEditorLines[i] = sequenceValue .. prefix .. v
                else
                    textEditorLines[i] = v .. sequenceValue
                end

                counter = counter + tonumber(stepValue)
            end

            local result = table.concat(textEditorLines, "\n")
            mod.textEditor(result)

            updateUI()
        elseif callbackType == "addSuffix" then
            --------------------------------------------------------------------------------
            -- Add Suffix:
            --------------------------------------------------------------------------------
            local textEditor = params["textEditor"]
            local suffix = params["suffix"]
            local textEditorLines = textEditor:split("\n")

            for i, v in pairs(textEditorLines) do
                textEditorLines[i] = v .. suffix
            end

            local result = table.concat(textEditorLines, "\n")
            mod.textEditor(result)

            updateUI()
        elseif callbackType == "addPrefix" then
            --------------------------------------------------------------------------------
            -- Add Prefix:
            --------------------------------------------------------------------------------
            local textEditor = params["textEditor"]
            local prefix = params["prefix"]
            local textEditorLines = textEditor:split("\n")

            for i, v in pairs(textEditorLines) do
                textEditorLines[i] = prefix .. v
            end

            local result = table.concat(textEditorLines, "\n")
            mod.textEditor(result)

            updateUI()
        elseif callbackType == "clear" then
            --------------------------------------------------------------------------------
            -- Clear:
            --------------------------------------------------------------------------------
            mod.textEditor("")
            updateUI()
        elseif callbackType == "reset" then
            --------------------------------------------------------------------------------
            -- Reset:
            --------------------------------------------------------------------------------
            mod.textEditor("")
            mod.prefix(" - ")
            mod.suffix(" - ")
            mod.startOrEnd("start")
            mod.startWith("1")
            mod.stepValue("1")
            mod.padding("0")
            mod.addSpaceAfterSequence(true)
            updateUI()
        elseif callbackType == "updateChecked" then
            --------------------------------------------------------------------------------
            -- Update Checked:
            --------------------------------------------------------------------------------
            local tid = params["id"]
            local value = params["value"]
            if tid == "mergeWithExistingEvent" then
                mod.mergeWithExistingEvent(value)
            elseif tid == "useTitleContentsInsteadOfTitleName" then
                mod.useTitleContentsInsteadOfTitleName(value)
            elseif tid == "removeProjectFromEvent" then
                mod.removeProjectFromEvent(value)
            elseif tid == "replaceCommasWithAlternativeCommas" then
                mod.replaceCommasWithAlternativeCommas(value)
            elseif tid == "treatFavoriteAndRejectAsRatingsInsteadOfKeywords" then
                mod.treatFavoriteAndRejectAsRatingsInsteadOfKeywords(value)
            elseif tid == "addSpaceAfterSequence" then
                mod.addSpaceAfterSequence(value)
            end
        elseif callbackType == "update" then
            --------------------------------------------------------------------------------
            -- A user interface element has changed value:
            --------------------------------------------------------------------------------
            mod.textEditor(params["textEditor"])
            mod.textEditorTwo(params["textEditorTwo"])
            mod.prefix(params["prefix"])
            mod.suffix(params["suffix"])
            mod.startOrEnd(params["startOrEnd"])
            mod.startWith(params["startWith"])
            mod.stepValue(params["stepValue"])
            mod.padding(params["padding"])
            mod.duration(params["duration"])
        elseif callbackType == "updateUI" then
            --------------------------------------------------------------------------------
            -- Update the User Interface:
            --------------------------------------------------------------------------------
            updateUI()
        else
            --------------------------------------------------------------------------------
            -- Unknown Callback:
            --------------------------------------------------------------------------------
            log.df("Unknown Callback in Titles to Keywords Toolbox Panel:")
            log.df("id: %s", inspect(id))
            log.df("params: %s", inspect(params))
        end
    end
end

local plugin = {
    id              = "finalcutpro.toolbox.titlestokeywords",
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
    local toolboxID = "titlesToKeywords"
    mod._panel          =  deps.manager.addPanel({
        priority        = 10,
        id              = toolboxID,
        label           = i18n("titlesToKeywords"),
        image           = image.imageFromPath(env:pathToAbsolute("/images/LibraryTextStyleIcon.icns")),
        tooltip         = i18n("titlesToKeywords"),
        height          = 980,
    })
    :addContent(1, generateContent, false)

    --------------------------------------------------------------------------------
    -- Setup Callback Manager:
    --------------------------------------------------------------------------------
    mod._panel:addHandler("onchange", "titlesToKeywordsPanelCallback", callback)

    --------------------------------------------------------------------------------
    -- Drag & Drop Text to the Dock Icon:
    --------------------------------------------------------------------------------
    mod._preferences.registerDragAndDropTextAction("titlesToKeywords", i18n("sendFCPXMLToTitlesToKeywords"), function(value)
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
    mod._preferences.registerDragAndDropFileAction("shotdata", i18n("sendFCPXMLToTitlesToKeywords"), function(path)
        processFCPXML(path)
    end)

    return mod
end

return plugin
