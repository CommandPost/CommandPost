--- === cp.apple.fcpxml ===
---
--- This extension adds functions and methods that simplify the creation
--- and management of the FCPXML document structure. It allows you to load FCPXML files
--- from file, or build them from scratch using Lua - which you can then export back to a
--- FCPXML file.
---
--- With the Final Cut Pro X XML (FCPXML) format, you can transfer the details of your
--- events and projects between Final Cut Pro X and third-party applications, devices,
--- and media asset management tools that do not natively recognize Final Cut Pro X events
--- or projects. FCPXML 1.8 requires Final Cut Pro X 10.4.1 or later.
---
--- FCPXML describes certain aspects of projects and events that are useful for other
--- applications. It does not describe all possible data, and therefore is not a substitute
--- for the native project and event data organized in a library bundle.
---
--- You can use Final Cut Pro X to export and import FCPXML documents to accomplish the following tasks:
---  * Exchange Final Cut Pro X event and project data with other applications.
---  * Create new Final Cut Pro X events and projects.
---
--- The Key Features of this extension include:
---  * Access an FCPXML document’s resources, events, clips, and projects through simple object properties.
---  * Create and modify resources, events, clips, and projects with included properties and methods.
---  * Easily manipulate timing values.
---  * Output FCPXML files with proper text formatting.
---  * Validate FCPXML documents with the DTD.
---
--- Here is a list of Final Cut Pro X terms used in this extension:
---
---  * A clip is a reference to media, such as a video, audio, or still image file, that allows
---    you to edit and annotate the media without directly modifying it. A clip controls which
---    portions of the media you would like to use, and it allows you to organize the media based
---    on keywords you have applied. Clips can also contain other clips to represent composite media.
---  * Use a Final Cut Pro X project and its primary container, a sequence, to build a finished movie.
---    The sequence defines your movie’s final appearance. You build a sequence by bringing clips into
---    it from one or more events, or by creating new clips within the sequence. You adjust and arrange
---    the clips, along with other story elements in the sequence, to produce your movie. Every clip in
---    a project is unique to that project (not shared), but referenced media always resides in an event
---    and may be shared across more than one project.
---  * Use a Final Cut Pro X event to store and organize clips and projects. You can import media files
---    into a new or existing event. You can copy these files into an event’s own media folder, or reference
---    them in their original locations. Final Cut Pro X tracks each imported file as an asset and ensures
---    your event contains at least one clip per asset.
---  * Use a Final Cut Pro X library to organize your events. The library is a container that you use to
---    keep track of all events, projects, and media related to your work.
---
--- This extension was inspired and uses code based on [Pipeline](https://github.com/reuelk/pipeline).
--- Thank you Reuel Kim for making something truly awesome, and releasing it as Open Source!

--------------------------------------------------------------------------------
--
-- USEFUL RESOURCES:
-- -----------------
--
-- Pipeline Documentation               https://reuelk.github.io/pipeline/index.html
-- Demystifying Final Cut Pro XMLs​     http://www.fcp.co/final-cut-pro/tutorials/1912-demystifying-final-cut-pro-xmls-by-philip-hodgetts-and-gregory-clarke
-- About Final Cut Pro X XML 1.8        https://developer.apple.com/library/archive/documentation/FinalCutProX/Reference/FinalCutProXXMLFormat/Introduction/Introduction.html#//apple_ref/doc/uid/TP40011227-CH1-SW1
--
--
-- NOTES:
-- ------
--
-- * 'time' attributes are expressed as a rational number of seconds (e.g., "1001/30000s")
--   with a 64-bit numerator and 32-bit denominator.
--   Integer 'time' values, such as 5 seconds, may be expressed as whole numbers (e.g., '5s').
--
-- * A 'timelist' is a semi-colon-separated list of time values
--
-- * A 'resource' is a project element potentially referenced by other project elements.
--   To support such references, all resource instances require a local ID attribute.
--
-- * A 'media' defines a reference to new or existing media via an FCP-assigned unique
--   identifier ('uid'). If 'uid' is not specified, FCP creates a new media object as
--   specified by the optional child element. If 'projectRef' is not specified, FCP
--   uses the default instance.
--
-- * A 'format' describes video properties.
--
-- * An 'asset' defines a reference to external source media (i.e., a local file).
--   'uid' is an FCP-assigned unique ID; if not specified, FCP creates a new default
--   clip for the asset.
--
-- * An 'effect' defines a reference to a built-in or user-defined Motion effect,
--   FxPlug plug-in, audio bundle, or audio unit.
--
-- STORY ELEMENTS:
-- * The 'ao_attrs' entity declares the attributes common to 'anchorable' objects.
-- * The 'lane' attribute specifies where the object is contained/anchored relative to its parent:
--    * 0   = contained inside its parent (default)
--    * >0  = anchored above its parent
--    * <0  = anchored below its parent
-- * The 'offset' attribute defines the location of the object in the parent timeline (default is '0s').
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--
-- FCPXML Structure:
--
-- 1) <fcpxml>
--      a) <event>
--      b) <import-options>
--      c) <library>
--      d) <project>
--      e) <resources>
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--
-- THINGS TO ADD:
--
-- Properties for attribute nodes within element tags:
-- * fcpxType
-- * fcpxName
-- * fcpxDuration
-- * fcpxStart
-- * fcpxStartValue
-- * fcpxOffset
-- * fcpxTCFormat
-- * fcpxFormatRef
-- * fcpxRefOrID
-- * fcpxRef
-- * fcpxID
-- * fcpxEnabled
-- * fcpxRole
-- * fcpxLane
-- * fcpxNote
-- * fcpxValue
-- * fcpxSrc
-- * fcpxFrameDuration
-- * fcpxWidth
-- * fcpxHeight
-- * fcpxAudioLayout
-- * fcpxAudioRate
-- * fcpxRenderColorSpace
-- * fcpxHasAudio
-- * fcpxHasVideo
-- * fcpxAngleID
-- * fcpxSrcEnable
-- * fcpxUID
-- * fcpxParentInPoint
-- * fcpxParentOutPoint
-- * fcpxLocalInPoint
-- * fcpxLocalOutPoint
-- * fcpxTimelineInPoint
-- * fcpxTimelineOutPoint
--
--
-- Other element properties that are beyond the element itself:
-- * fcpxmlString
-- * isFCPXEvent
-- * isFCPXEventItem
-- * isFCPXResource
-- * isFCPXProject
-- * fcpxProjectSequence
-- * fcpxProjectSpine
-- * fcpxProjectClips
-- * fcpxParentEvent
-- * fcpxResource
-- * fcpxAnnotations
-- * fcpxMetadata
-- * fcpxMulticamAngles
-- * referencingClips(inEvent:)
--
--
-- Methods for events:
-- * eventItems
-- * eventProjects
-- * eventClips
-- * eventClips(forResourceID:)
-- * eventClips(containingResource:)
-- * addToEvent(item:)
-- * addToEvent(items:)
-- * removeFromEvent(itemIndex:)
-- * removeFromEvent(itemIndexes:)
-- * removeFromEvent(items:)
-- * Methods for event clips
--
--
-- Methods for event clips:
-- * addToClip(annotationElements:)
--
--
-- Retrieving format information:
-- * formatValues()
--
--
-- Miscellaneous:
-- * urls()
-- * allReferenceIDs()
-- * subelements(forName:usingAbsoluteMatch:)
-- * clips()
-- * clips(forFCPXName:usingAbsoluteMatch:)
-- * clips(forElementType:)
--
--
-- Timing methods:
-- * clipRangeIncludes(_:)
-- * clipRangeIsEnclosedBetween(_:outPoint:)
-- * clipRangeOverlapsWith(_:outPoint:)
-- * childElementsWithinRangeOf(_:outPoint:elementType:)
--
--------------------------------------------------------------------------------


local log                   = require("hs.logger").new("fcpxml")

local fnutils               = require("hs.fnutils")

local config                = require("cp.config")
local flicks                = require("cp.time.flicks")
local tools                 = require("cp.tools")

local xml                   = require("hs._asm.xml")

--------------------------------------------------------------------------------
-- Local Extensions:
--------------------------------------------------------------------------------
local compoundClip          = require("cp.apple.fcpxml.compoundClip")
local event                 = require("cp.apple.fcpxml.event")
local gap                   = require("cp.apple.fcpxml.gap")
local multicamClip          = require("cp.apple.fcpxml.multicamClip")
local multicamResource      = require("cp.apple.fcpxml.multicamResource")
local project               = require("cp.apple.fcpxml.project")
local resource              = require("cp.apple.fcpxml.resource")
local secondaryStoryline    = require("cp.apple.fcpxml.secondaryStoryline")
local title                 = require("cp.apple.fcpxml.title")


local mod = {}
mod.mt = {}
mod.mt.__index = mod.mt

--------------------------------------------------------------------------------
-- CONSTANTS:
--------------------------------------------------------------------------------

-- NOTE: Some of these constant tables are probably not needed, as we should
--       probably do most of the work in methods rather than constant tables.

--- cp.apple.fcpxml.METADATA_TYPES -> table
--- Constant
--- Supported Metadata Types in FCPXML Documents.
mod.METADATA_TYPES = {
    string = "string",
    boolean = "boolean",
    integer = "integer",
    float = "float",
    date = "date",
    timecode = "timecode",
}

--- cp.apple.fcpxml.COLLECTION_TYPES -> table
--- Constant
--- Supported Collection Types in FCPXML Documents.
mod.COLLECTION_TYPES = {
    collectionFolder = "collection-folder",
    keywordCollection = "keyword-collection",
    smartCollection = "smart-collection",
}

--- cp.apple.fcpxml.EVENT_ITEM_TYPES -> table
--- Constant
--- Supported Event Item Types in FCPXML Documents.
mod.EVENT_ITEM_TYPES = {
    clip = "clip",
    audition = "audition",
    mcClip = "mc-clip",
    refClip = "ref-clip",
    syncClip = "sync-clip",
    assetClip = "asset-clip",
    collectionFolder = "collection-folder",
    keywordCollection = "keyword-collection",
    smartCollection = "smart-collection",
    project = "project",
}

--- cp.apple.fcpxml.RESOURCE_TYPES -> table
--- Constant
--- Supported Resource Types in FCPXML Documents.
mod.RESOURCE_TYPES = {
    asset = "asset",
    effect = "effect",
    format = "format",
    media = "media",
}

--- cp.apple.fcpxml.FIELD_ORDER -> table
--- Constant
--- Supported Field Order values.
mod.FIELD_ORDER = {
    progressive = "progressive",
    upper = "upper first",
    lower = "lower first",
}

--- cp.apple.fcpxml.COLOR_SPACE -> table
--- Constant
--- Supported Field Order values.
mod.COLOR_SPACE = {
    ntsc = "Rec. 601 (NTSC)",
    pal = "Rec. 601 (PAL)",
    rec709 = "Rec. 709",
    rec2020 = "Rec. 2020",
    rec2020pq = "Rec. 2020 PQ",
    rec2020hlg = "Rec. 2020 HLG",
}

--- cp.apple.fcpxml.PROJECTION -> table
--- Constant
--- Supported Projection values.
mod.PROJECTION = {
    none = "none",
    equirectangular = "equirectangular",
    cubic = "cubic",
}

--- cp.apple.fcpxml.STEREOSCOPIC -> table
--- Constant
--- Supported Stereoscopic values.
mod.STEREOSCOPIC = {
    mono = "mono",
    sideBySide = "side by side",
    overUnder = "over under"
}

--- cp.apple.fcpxml.PROJECTION_OVERRIDE -> table
--- Constant
--- Supported Projection Override values.
mod.PROJECTION_OVERRIDE = {
    none = "none",
    equirectangular = "equirectangular",
    fisheye = "fisheye",
    backToBackFisheye = "back-to-back fisheye",
    cubic = "cubic",
}

--- cp.apple.fcpxml.STEREOSCOPIC_OVERRIDE -> table
--- Constant
--- Supported Stereoscopic Override values.
mod.STEREOSCOPIC_OVERRIDE = {
    mono = "mono",
    sideBySide = "side by side",
    overUnder = "over under",
}

--- cp.apple.fcpxml.COLOR_SPACE_OVERRIDE -> table
--- Constant
--- Supported Color Space Override values.
mod.COLOR_SPACE_OVERRIDE = {
    ntsc = "Rec. 601 (NTSC)",
    pal = "Rec. 601 (PAL)",
    rec709 = "Rec. 709",
    rec2020 = "Rec. 2020",
    rec2020pq = "Rec. 2020 PQ",
    rec2020hlg = "Rec. 2020 HLG",
    sRGB = "sRGB IEC61966-2.1",
    adobeRGB = "Adobe RGB (1998)",
}

--- cp.apple.fcpxml.AUDIO_SAMPLE_RATE -> table
--- Constant
--- Supported Audio Sample Rate values.
mod.AUDIO_SAMPLE_RATE = {
    32k = "32k",
    441k = "44.1k",
    48k = "48k",
    882k = "88.2k",
    96k = "96k",
    1764k = "176.4k",
    192k = "192k",
}

--- cp.apple.fcpxml.TIMECODE_FORMAT -> table
--- Constant
--- Supported Timecode Format values.
mod.TIMECODE_FORMAT = {
    df = "DF",   -- Drop Frame
    ndf = "NDF",  -- Non-drop Frame
}

--- cp.apple.fcpxml.AUDIO_OUTPUT_CHANNEL -> table
--- Constant
--- Supported Audio Output Channel Values.
mod.AUDIO_OUTPUT_CHANNEL = {
    l = "L",
    r = "R",
    c = "C",
    lfe = "LFE",
    ls = "Ls",
    rs = "Rs",
    x = "X",
}

--- cp.apple.fcpxml.AUDIO_FADE_TYPE -> table
--- Constant
--- Supported Audio Fade Type Values.
mod.AUDIO_FADE_TYPE = {
    linear = "linear",
    easeIn = "easeIn",
    easeOut = "easeOut",
    easeInOut = "easeInOut",
}

--- cp.apple.fcpxml.EQ_MODE -> table
--- Constant
--- Supported EQ Mode Values.
mod.EQ_MODE = {
    flat = "flat",
    voiceEnhance = "voice_enhance",
    musicEnhance = "music_enhance",
    loudness = "loudness",
    humReduction = "hum_reduction",
    bassBoost = "bass_boost",
    bassReduce = "bass_reduce",
    trebleBoost = "treble_boost",
    trebleReduce = "treble_reduce",
}

--- cp.apple.fcpxml.ANCHOR_ITEMS -> table
--- Constant
--- Supported Anchor Item Values. The 'anchor_item' entity declares the valid anchorable story elements. When present, anchored items must have a non-zero 'lane' value.
mod.ANCHOR_ITEMS = {
    audio = "audio",
    video = "video",
    clip = "clip",
    title = "title",
    caption = "caption",
    mcClip = "mc-clip",
    refClip = "ref-clip",
    syncClip = "sync-clip",
    assetClip = "asset-clip",
    audition = "audition",
    spine = "spine",
}

--- cp.apple.fcpxml.CLIP_ITEMS -> table
--- Constant
--- Supported Clip Item Values. The 'clip_item' entity declares the primary story elements that may appear inside a clip.
mod.CLIP_ITEMS = {
    audio = "audio",
    video = "video",
    clip = "clip",
    title = "title",
    mcClip = "mc-clip",
    refClip = "ref-clip",
    syncClip = "sync-clip",
    assetClip = "asset-clip",
    audition = "audition",
    gap = "gap",
}

--- cp.apple.fcpxml.MARKER_ITEMS -> table
--- Constant
--- Supported Marker Item Values.
mod.MARKER_ITEMS = {
    marker = "marker",
    chapterMarker = "chapter-marker",
    rating = "rating",
    keyword = "keyword",
    analysisMarker = "analysis-marker",
}

--------------------------------------------------------------------------------
-- FCPXML DOCUMENT CONSTRUCTORS:
--------------------------------------------------------------------------------

--- cp.apple.fcpxml.new() -> fcpxmlDocument Object
--- Constructor
--- Create a new empty FCPXML Document object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A new FCPXML object.
function mod.new()

    --------------------------------------------------------------------------------
    -- TODO: We need to actually setup the new FCPXML Document Object here.
    --------------------------------------------------------------------------------

    local o = {}
    return setmetatable(o, {__index = mod.mt})
end

--- cp.apple.fcpxml.open(file) -> fcpxmlDocument Object
--- Constructor
--- Create a new FCPXML Document object from the specified file.
---
--- Parameters:
---  * file - An FCPXML document you want to read from an external file.
---
--- Returns:
---  * A new FCPXML object.
function mod.open(file)
    if not file or not tools.doesFileExist(file) then
        log.df("FCPXML Document does not exist: %s", file)
        return
    end

    if not mod.valid(file) then
        log.ef("FCPXML Document is not valid: %s", file)
        return
    end

    local _xml = xml.open(file)
    if not _xml then
        log.ef("FCPXML Document could not be read: %s", file)
    end

    --------------------------------------------------------------------------------
    -- TODO: We need to actually process the XML here.
    --------------------------------------------------------------------------------

    local o = {
        _xml = _xml,
    }
    return setmetatable(o, {__index = mod.mt})
end

--------------------------------------------------------------------------------
-- FCPXML ELEMENT CONSTRUCTORS:
--------------------------------------------------------------------------------

--- cp.apple.fcpxml.newResource() -> fcpxmlResource Object
--- Constructor
--- Creates a new resource object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A new resource object.
function mod.newResource(...)

    --------------------------------------------------------------------------------
    -- TODO: I'm not really sure whether we should have a generic `newResource()`
    -- function or split it up so that we have `newClip()`, etc.
    --------------------------------------------------------------------------------

    return resource.new(...)
end

--- cp.apple.fcpxml.newEvent(name[, items]) -> fcpxmlEvent Object
--- Constructor
--- Creates a new event object.
---
--- Parameters:
---  * name - The name of the event.
---  * items - An optional table of items to add to the event.
---
--- Returns:
---  * A new event object.
function mod.newEvent(...)
    return event.new(...)
end

--- cp.apple.fcpxml.newProject(name, format, duration, timecodeStart, timecodeFormat, audioLayout, audioRate, renderColorSpace[, clips]) -> fcpxmlProject Object
--- Constructor
--- Creates a new project FCPXML object and optionally adds clips to it.
---
--- Parameters:
---  * name - The name of the project as a string.
---  * format - The format of the project.
---  * duration - The duration of the project.
---  * timecodeStart - The start timecode of the project.
---  * timecodeFormat - The timecode format of the project.
---  * audioLayout - The audio layout of the project.
---  * audioRate - The audio sample rate of the project.
---  * renderColorSpace - The render color space of the project.
---  * clips - An optional table of clips you want to add to the project.
---
--- Returns:
---  * A new project object.
function mod.newProject(...)
    return project.new(...)
end

--- cp.apple.fcpxml.newCompoundClip(name, ref, offset, duration, startTimecode, useAudioSubroles) -> fcpxmlCompoundClip Object
--- Constructor
--- Creates a new ref-clip FCPXML Document object.
---
--- Parameters:
---  * name - The name of the Compound Clip as string.
---  * ref - The reference ID of the compound clip as string.
---  * offset - The offset of the compound clip in flicks.
---  * duration - The duration of the compound clip in flicks.
---  * startTimecode - The start timecode in flicks.
---  * useAudioSubroles - A boolean.
---
--- Returns:
---  * A new Compound Clip object.
function mod.newCompoundClip(...)
    return compoundClip.new(...)
end

--- cp.apple.fcpxml.newMulticamResource(name, id, formatRef, startTimecode, timecodeFormat, renderColorSpace, angles) -> fcpxmlMulticamResource Object
--- Constructor
--- Creates a new FCPXML multicam reference FCPXML Document object.
---
--- Parameters:
---  * name - The name of the Multicam Resource as a string.
---  * id - The ID of the Multicam Resource as a string.
---  * formatRef - The format of the Multicam Resource.
---  * startTimecode - The start timecode in flicks.
---  * timecodeFormat - The timecode format (see: `cp.apple.fcpxml.TIMECODE_FORMAT`).
---  * renderColorSpace - The render color space (see: `cp.apple.fcpxml.COLOR_SPACE`).
---  * angles - A table of angle objects.
---
--- Returns:
---  * A new Multicam Resource object.
function mod.newMulticamResource(...)
    return multicamResource.new(...)
end

--- cp.apple.fcpxml.newMulticamClip(name, refID, offset, startTimecode, duration, mcSources) -> fcpxmlMulticamClip Object
--- Constructor
--- Creates a new multicam event clip FCPXML Document object.
---
--- Parameters:
---  * name - The name of the Multicam Clip as a string.
---  * refID - The reference ID of the Multicam Clip.
---  * offset - The offset of the Multicam clip in flicks.
---  * startTimecode - The start timecode in flicks.
---  * duration - The duration of the Multicam clip.
---  * mcSources - A table of multicam sources.
---
--- Returns:
---  * A new Multicam Clip object.
function mod.newMulticamClip(...)
    return multicamClip.new()
end

--- cp.apple.fcpxml.newSecondaryStoryline(lane, offset, formatRef, clips) -> fcpxmlSecondaryStoryline Object
--- Constructor
--- Creates a new secondary storyline FCPXML Document object.
---
--- Parameters:
---  * lane - The lane you want the secondary storyline to appear.
---  * offset - The offset of the secondary storyline in flicks.
---  * formatRef - The format of the secondary storyline.
---  * clips - A table of clips.
---
--- Returns:
---  * A new Secondary Storyline object.
function mod.newSecondaryStoryline(...)
    return secondaryStoryline.new(...)
end

--- cp.apple.fcpxml.newGap(offset, duration, startTimecode) -> fcpxmlGap Object
--- Constructor
--- Creates a new gap to be used in a timeline.
---
--- Parameters:
---  * offset - The offset of the Gap clip in flicks.
---  * duration - The duration of the Gap clip in flicks.
---  * startTimecode - The start timecode of the Gap clip in flicks.
---
--- Returns:
---  * A new Gap Clip object.
function mod.newGap(...)
    return gap.new(...)
end

--- cp.apple.fcpxml.newTitle(titleName, lane, offset, ref, duration, start, role, titleText, textStyleID, newTextStyle, newTextStyleAttributes) -> fcpxmlTitle Object
--- Constructor
--- Creates a new title to be used in a timeline.
---
--- Parameters:
---  * titleName
---  * lane
---  * offset
---  * ref
---  * duration
---  * start
---  * role
---  * titleText
---  * textStyleID
---  * newTextStyle
---  * newTextStyleAttributes
---
--- Returns:
---  * A new Title object.
---
--- Notes:
---  * `newTextStyleAttributes` is only used if `newTextStyle` is set to `true`.
---  * When `newTextStyle` is set to `true`, the following atttributes can be used
---    within the `newTextStyleAttributes` table:
---      * font - The font name as string (defaults to "Helvetica").
---      * fontSize - The font size a number (defaults to 62).
---      * fontFace - The font face as a string (defaults to "Regular").
---      * fontColor - The font color as a `hs.drawing.color` object (defaults to black).
---      * strokeColor - The stroke color as a `hs.drawing.color` object (defaults to `nil`).
---      * strokeWidth - The stroke width as a number (defaults to 2).
---      * shadowColor - The stroke color as a `hs.drawing.color` object (defaults to `nil`).
---      * shadowDistance - The shadow distance as a number (defaults to 5).
---      * shadowAngle - The shadow angle as a number (defaults to 315).
---      * shadowBlurRadius - The shadow blur radius as a number (defaults to 1).
---      * alignment - The text alignment as a string (defaults to "center").
---      * xPosition - The x position of the title (defaults to 0).
---      * yPosition - The y position of the title (defaults to 0).
function mod.newTitle(...)
    return title.new(...)
end

-- TODO: Add Generator Object?

--------------------------------------------------------------------------------
-- FUNCTIONS:
--------------------------------------------------------------------------------

--- cp.apple.fcpxml.supportedDTDs() -> table
--- Function
--- Returns a table containing the version numbers of all the DTD documents included in this extension.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of supported DTD versions as strings.
function mod.supportedDTDs()
    local result = {}
    local path = config.scriptPath .. "/cp/apple/fcpxml/dtd"
    local files = tools.dirFiles(path)
    for _, file in pairs(files) do
        if file:sub(-4) == ".dtd" then
            table.insert(result, file:sub(8, 8) .. "." .. file:sub(10, 10))
        end
    end
    return result
end

--- cp.apple.fcpxml.latestDTDVersion() -> string
--- Function
--- Gets the latest supported FCPXML DTD version.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The latest DTD version as a string, for example: "1.8".
function mod.latestDTDVersion()
    local supportedDTDs = mod.supportedDTDs()
    table.sort(supportedDTDs)
    return supportedDTDs[#supportedDTDs]
end

--- cp.apple.fcpxml:valid(filename[, version]) -> boolean
--- Method
--- Validates an FCPXML document against a document type definition (DTD).
---
--- Parameters:
---  * filename - The path and filename of the FCPXML document you want to validate.
---  * version - The optional FCPXML version you want to validate against.
---
--- Returns:
---  * `true` if valid, otherwise `false`.
function mod.valid(filename, version)
    if not filename or not tools.doesFileExist(filename) then
        log.ef("Filename is not valid: %s", filename)
        return false
    end

    local supportedDTDs = mod.supportedDTDs()
    if version and not fnutils.contains(supportedDTDs, version) then
        log.ef("Invalid version: %s", version)
        return false
    end

    if not version then
        version = mod.latestDTDVersion()
    end

    local major = version:sub(1,1)
    local minor = version:sub(3,3)

    local dtdPath = config.scriptPath .. "/cp/apple/fcpxml/dtd/" .. "FCPXMLv" .. major .. "_" .. minor .. ".dtd"

    local _, status = hs.execute([[xmllint --noout --dtdvalid "]] .. dtdPath .. [[" "]] .. filename .. [["]])
    return status or false
end

--------------------------------------------------------------------------------
-- METHODS:
--------------------------------------------------------------------------------

--- cp.apple.fcpxml:resources() -> table
--- Method
--- An table of all resources in the FCPXML document.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table
function mod.mt.resources()
    -- TODO: Write code here.
end

--- cp.apple.fcpxml:library() -> libraryObject
--- Method
--- Gets the Final Cut Pro Library.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `libraryObject`
function mod.mt.library()
    -- TODO: Write code here.
end

--- cp.apple.fcpxml:events() -> table
--- Method
--- An table of all event elements in the FCPXML document.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table
function mod.mt.events()
    -- TODO: Write code here.
end

--- cp.apple.fcpxml:formatResources() -> table
--- Method
--- An table of all format resources in the FCPXML document.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table
function mod.mt.formatResources()
    -- TODO: Write code here.
end

--- cp.apple.fcpxml:assetResources() -> table
--- Method
--- An table of all asset resources in the FCPXML document.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table
function mod.mt.assetResources()
    -- TODO: Write code here.
end

--- cp.apple.fcpxml:multicamResources() -> table
--- Method
--- An table of all multicam resources in the FCPXML document.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table
function mod.mt.multicamResources()
    -- TODO: Write code here.
end

--- cp.apple.fcpxml:compoundResources() -> table
--- Method
--- An table of all compound clip resources in the FCPXML document.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table
function mod.mt.compoundResources()
    -- TODO: Write code here.
end

--- cp.apple.fcpxml:effectResources() -> table
--- Method
--- An table of all effect resources in the FCPXML document.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table
function mod.mt.effectResources()
    -- TODO: Write code here.
end

--- cp.apple.fcpxml:allProjects() -> table
--- Method
--- An table of all projects in all events in the FCPXML document.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table
function mod.mt.allProjects()
    -- TODO: Write code here.
end

--- cp.apple.fcpxml:allClips() -> table
--- Method
--- An table of all clips in all events in the FCPXML document.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table
function mod.mt.allClips()
    -- TODO: Write code here.
end

--- cp.apple.fcpxml:roles() -> table
--- Method
--- An table of all roles used in the FCPXML document.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table
function mod.mt.roles()
    -- TODO: Write code here.
end

--- cp.apple.fcpxml:lastResourceID() -> number
--- Method
--- The highest resource ID number used in the FCPXML document.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A number
function mod.mt.lastResourceID()
    -- TODO: Write code here.
end

--- cp.apple.fcpxml:lastTextStyleID() -> number
--- Method
--- The highest text style ID number used in the FCPXML document.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A number
function mod.mt.lastTextStyleID()
    -- TODO: Write code here.
end

--- cp.apple.fcpxml:xmlVersion([version]) -> string
--- Method
--- Gets or sets the FCPXML version of the FCPXML document.
---
--- Parameters:
---  * version - An optional string to set the version of the FCPXML document (for example: "1.8").
---
--- Returns:
---  * A string containing the XML version of the FCPXML document.
function mod.mt.xmlVersion(version)
    -- TODO: Write code here.
end

--- cp.apple.fcpxml:eventNames() -> table
--- Method
--- The names of all events as strings in a table.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table containing all of the event names as strings.
function mod.mt.eventNames()
    -- TODO: Write code here.
end

--- cp.apple.fcpxml:allEventItems() -> table
--- Method
--- All items from all events.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table
function mod.mt.allEventItems()
    -- TODO: Write code here.
end

--- cp.apple.fcpxml:allEventItemNames() -> table
--- Method
--- The names of all items from all events.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table
function mod.mt.allEventItemNames()
    -- TODO: Write code here.
end

--- cp.apple.fcpxml:allProjectNames() -> table
--- Method
--- The names of all projects from all events.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table
function mod.mt.allProjectNames()
    -- TODO: Write code here.
end

--- cp.apple.fcpxml:resource(id) -> resourceObject | nil
--- Method
--- Returns the resource that matches the given ID string.
---
--- Parameters:
---  * id - The ID string of the resource you want to access.
---
--- Returns:
---  * A resource object or `nil` if the resource does not exist.
function mod.mt.resource(id)
    -- TODO: Write code here.
end

--- cp.apple.fcpxml:assetResources(file) -> table | nil
--- Method
--- Returns asset resources that match the given file.
---
--- Parameters:
---  * file - The file path.
---
--- Returns:
---  * A table of resource objects or `nil` if no assets match.
function mod.mt.resource(file)
    -- TODO: Write code here.
end

--- cp.apple.fcpxml:saveToFile(filename) -> boolean
--- Method
--- Saves the FCPML Document to the specified filename.
---
--- Parameters:
---  * filename - the path and name of the file to save.
---
--- Returns:
---  * Status - a boolean value indicating success (`true`) or failure (`false`).
function mod.mt.saveToFile(filename)
    -- TODO: Write code here.
end

--- cp.apple.fcpxml:add(resources) -> boolean
--- Method
--- Adds one or more resources to the FCPXML document.
---
--- Parameters:
---  * resources - A single `resourceObject` or a table of `resourceObject`'s to add to the FCPXML document.
---
--- Returns:
---  * `true` if successfully added, otherwise `false`.
function mod.mt.add(resources)
    -- TODO: Write code here.
end

--- cp.apple.fcpxml:remove(resources) -> boolean
--- Method
--- Removes one or more resources from the FCPXML document.
---
--- Parameters:
---  * resources - A single `resourceObject` or a table of `resourceObject`'s to add to the FCPXML document.
---
--- Returns:
---  * `true` if successfully removed, otherwise `false`.
function mod.mt.remove(resources)
    -- TODO: Write code here.
end

--- cp.apple.fcpxml:removeAllResources() -> boolean
--- Method
--- Removes all resources from the FCPXML document.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if successful, otherwise `false`.
function mod.mt.removeAllResources()
    -- TODO: Write code here.
end

--- cp.apple.fcpxml:removeAllEvents() -> boolean
--- Method
--- Removes all events from the library.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if successful, otherwise `false`.
function mod.mt.removeAllEvents()
    -- TODO: Write code here.
end

return mod