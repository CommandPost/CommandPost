--- === cp.apple.fcpxml ===
---
--- A collection of tools for handling FCPXML Documents.

--------------------------------------------------------------------------------
--
-- USEFUL RESOURCES:
-- -----------------
--
-- Pipeline Documentation               https://reuelk.github.io/pipeline/index.html
-- Demystifying Final Cut Pro XMLs​      http://www.fcp.co/final-cut-pro/tutorials/1912-demystifying-final-cut-pro-xmls-by-philip-hodgetts-and-gregory-clarke
-- FCPXML Reference                     https://developer.apple.com/documentation/professional_video_applications/fcpxml_reference?language=objc
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

local log                   = require "hs.logger".new "fcpxml"

local fnutils               = require "hs.fnutils"

local config                = require "cp.config"
local tools                 = require "cp.tools"

local xml                   = require "hs._asm.xml"

local semver                = require "semver"

local execute               = _G.hs.execute

local mod = {}

--- cp.apple.fcpxml.timeStringToSeconds(value) -> number
--- Function
--- Converts a FCPXML time string into a number in seconds.
---
--- Parameters:
---  * value - A string FCPXML time value (i.e. "3400/2500s")
---
--- Returns:
---  * A number which has the time value in seconds
---  * A number of the denominator if not a whole number (i.e. 2500)
---  * A number of the numerator if not a whole number (i.e. 3400)
---
--- Notes:
---  * Final Cut Pro expresses time values as a rational number of seconds with a 64-bit
---    numerator and a 32-bit denominator. Frame rates for NTSC-compatible media,
---    for example, use a frame duration of 1001/30000s (29.97 fps) or 1001/60000s (59.94 fps).
---    If a time value is equal to a whole number of seconds, Final Cut Pro may reduce the
---    fraction into whole seconds (for example, 5s).
function mod.timeStringToSeconds(value)
    --------------------------------------------------------------------------------
    -- Remove the "s" at the end:
    --------------------------------------------------------------------------------
    if value:sub(-1) == "s" then
        value = value:sub(1, -2)
    end

    --------------------------------------------------------------------------------
    -- If there's a slash then do the maths:
    --------------------------------------------------------------------------------
    local numerator
    local denominator
    if string.find(value, "/") then
        local values = value:split("/")
        local valueA = values and values[1] and tonumber(values[1])
        local valueB = values and values[2] and tonumber(values[2])
        if valueA and valueB then
            value = valueA / valueB
            numerator = valueA
            denominator = valueB
        end
    end

    return tonumber(value), denominator, numerator
end

--- cp.apple.fcpxml.numberToTimeString(value, [denominator]) -> number
--- Function
--- Converts a number into a FCPXML friendly time value string (i.e. "3400/2500s")
---
--- Parameters:
---  * value - A number in seconds
---  * denominator - A optional number of the denominator (i.e. 2500)
---
--- Returns:
---  * A string (i.e. "3400/2500s" or "2s")
---
--- Notes:
---  * Final Cut Pro expresses time values as a rational number of seconds with a 64-bit
---    numerator and a 32-bit denominator. Frame rates for NTSC-compatible media,
---    for example, use a frame duration of 1001/30000s (29.97 fps) or 1001/60000s (59.94 fps).
---    If a time value is equal to a whole number of seconds, Final Cut Pro may reduce the
---    fraction into whole seconds (for example, 5s).
function mod.numberToTimeString(value, denominator)
    if value == math.floor(value) then
        --------------------------------------------------------------------------------
        -- It's a whole number:
        --------------------------------------------------------------------------------
        return tostring(value) .. "s"
    elseif not denominator then
        --------------------------------------------------------------------------------
        -- The supplied denominator was nil:
        --------------------------------------------------------------------------------
        return tostring(value) .. "s"
    else
        local numerator = value * denominator
        return string.format("%.0f", numerator) .. "/" .. string.format("%.0f", denominator) .. "s"
    end
end

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
            local vPosition = file:find("v")
            local version = file:sub(vPosition + 1, -5):gsub("_", ".")
            table.insert(result, version)
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
    table.sort(supportedDTDs, function(a,b) return semver(a) < semver(b) end)
    return supportedDTDs[#supportedDTDs]
end

--- cp.apple.fcpxml:valid(path[, version]) -> string|boolean, string
--- Function
--- Validates an FCPXML document against a document type definition (DTD).
---
--- Parameters:
---  * path - The path and path of the FCPXML document you want to validate.
---  * version - The optional FCPXML version you want to validate against.
---
--- Returns:
---  * The FCPXML path or `false` if not valid.
---  * The output from xmllint as a string.
---
--- Notes:
---  * If a version is not supplied, we will try and read the version
---    from the file itself, and if that's not possible, we'll default
---    to the latest FCPXML version.
---  * If a `fcpxmld` bundle path is supplied, this function will return
---    the path to the `Info.fcpxml` document if valid.
function mod.valid(path, version)
    --------------------------------------------------------------------------------
    -- Look inside FCPXML Bundles for metadata:
    --------------------------------------------------------------------------------
    local extension = tools.getFileExtensionFromPath(path)
    if extension and extension == "fcpxmld" then
        path = path .. "/Info.fcpxml"
    end

    --------------------------------------------------------------------------------
    -- Make sure the file actually exists:
    --------------------------------------------------------------------------------
    if not path or not tools.doesFileExist(path) then
        --log.ef("[cp.apple.fcpxml] FCPXML path is not valid: %s", path)
        return false
    end

    --------------------------------------------------------------------------------
    -- Make sure the file is actually an XML file:
    --------------------------------------------------------------------------------
    local validXML, document = pcall(function() return xml.open(path) end)
    if not validXML or not document then
        --log.ef("[cp.apple.fcpxml] Invalid XML document: %s", path)
        return false
    end

    --------------------------------------------------------------------------------
    -- If no version is supplied, lets try read it from the file:
    --------------------------------------------------------------------------------
    if not version then
        local documentChildren = document:children()
        local baseElement = documentChildren and documentChildren[1]
        local attributes = baseElement and baseElement:rawAttributes()
        local documentVersion = attributes and attributes[1] and attributes[1]:stringValue()
        if documentVersion and documentVersion ~= "" then
            version = documentVersion
        end
    end

    --------------------------------------------------------------------------------
    -- Make sure the version matches one of our DTDs:
    --------------------------------------------------------------------------------
    local supportedDTDs = mod.supportedDTDs()
    if version and not fnutils.contains(supportedDTDs, version) then
        --log.ef("[cp.apple.fcpxml] Invalid FCPXML Version: %s", version)
        return false
    end

    --------------------------------------------------------------------------------
    -- Convert the supplied version (or the latest version if none is supplied or
    -- detected in the FCPXML document itself) to a `semver` object:
    --------------------------------------------------------------------------------
    if version then
        version = semver(version)
    else
        version = semver(mod.latestDTDVersion())
    end

    --------------------------------------------------------------------------------
    -- Use `xmllint` to make sure the file is valid:
    --------------------------------------------------------------------------------
    local dtdPath = config.scriptPath .. "/cp/apple/fcpxml/dtd/" .. "FCPXMLv" .. version.major .. "_" .. version.minor .. ".dtd"
    local output, status = execute([[xmllint --noout --noblanks --dtdvalid "]] .. dtdPath .. [[" "]] .. path .. [["]])
    return status and path or false, output
end

return mod