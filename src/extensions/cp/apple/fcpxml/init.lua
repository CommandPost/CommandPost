--- === cp.apple.fcpxml ===
---
--- A collection of tools for handling FCPXML Documents.

--local log                   = require "hs.logger".new "fcpxml"

local fnutils               = require "hs.fnutils"

local config                = require "cp.config"
local tools                 = require "cp.tools"

local xml                   = require "hs._asm.xml"

local semver                = require "semver"

local execute               = _G.hs.execute

local mod = {}

--- cp.apple.fcpxml.HAS_OFFSET_ATTRIBUTE <table: string:boolean>
--- Constant
--- Table of elements that have an `offset` attribute.
mod.HAS_OFFSET_ATTRIBUTE = {
    ["asset-clip"]  = true,
    ["audio"]       = true,
    ["caption"]     = true,
    ["clip"]        = true,
    ["gap"]         = true,
    ["mc-clip"]     = true,
    ["ref-clip"]    = true,
    ["spine"]       = true,
    ["sync-clip"]   = true,
    ["title"]       = true,
    ["transition"]  = true,
    ["video"]       = true,
}

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