--- === cp.apple.finalcutpro.viewer.CustomOverlay ===
---
--- Represents a "Custom Overlay" value that can be enabled/disabled from FCP.
local require = require

local app                   = require "cp.app"
local Set                   = require "cp.collect.Set"
local prop                  = require "cp.prop"
local tools                 = require "cp.tools"

local fs                    = require "hs.fs"
local class                 = require "middleclass"
local lazy                  = require "cp.lazy"

local pathToAbsolute                            = fs.pathToAbsolute
local getNameAndExtensionFromFile               = tools.getNameAndExtensionFromFile
local insert                                    = table.insert

local CustomOverlay = class("cp.apple.finalcutpro.viewer.CustomOverlay"):include(lazy)

--- cp.apple.finalcutpro.ALLOWED_IMPORT_IMAGE_EXTENSIONS -> table
--- Constant
--- Table of image file extensions Final Cut Pro can import.
CustomOverlay.static.ALLOWED_IMAGE_EXTENSIONS	= Set("bmp", "gif", "jpeg", "jpg", "png", "psd", "raw", "tga", "tiff", "tif")

--- cp.apple.finalcutpro.viewer.CustomOverlay.userOverlaysPath() -> string
--- Function
--- Returns the absolute path to the location where Custom Overlay images are stored for the current user.
function CustomOverlay.static.userOverlaysPath()
    return pathToAbsolute("~/Library/Application Support/ProApps/Custom Overlays")
end

--- cp.apple.finalcutpro.viewer.CustomOverlay.userOverlays <cp.prop: CustomOverlay; read-only>
--- Constant
--- Contains the current list of `CustomOverlay`s available.
CustomOverlay.static.userOverlays = prop(function()
    local overlays = {}

    for file in fs.dir(CustomOverlay.userOverlaysPath()) do
        local name, ext = getNameAndExtensionFromFile(file)
        if ext and CustomOverlay.ALLOWED_IMAGE_EXTENSIONS:has(ext) then
            insert(overlays, CustomOverlay(name, ext))
        end
    end

    return overlays
end)

--- cp.apple.finalcutpro.viewer.CustomOverlay(name, extension) -> CustomOverlay
--- Constructor
--- Initializes a `CustomOverlay` with the specified name and file extension.
---
--- Parameters:
---  * name - The overlay name.
---  * extension - The overlay file extension.
---
--- Returns:
---  * the new `CustomOverlay`.
function CustomOverlay:initialize(name, extension)
    self.name = name
    self.extension = extension
end

--- cp.apple.viewer.CustomOverlay.name <string>
--- Field
--- The name of the overlay, as appears in the Viewer's 'Choose Custom Overlay' menu.

--- cp.apple.viewer.CustomOverlay.extension <string>
--- Field
--- The file extension of the overlay.

--- cp.apple.finalcutpro.viewer.CustomOverlay.fileName <string>
--- Field
--- The filename with extension.
function CustomOverlay.lazy.value:fileName()
    return self.name .. "." .. self.extension
end

--- cp.apple.finalcutpro.viewer.CustomOverlay.filePath <string>
--- Field
--- The absolute path to the overlay file.
function CustomOverlay.lazy.value:filePath()
    return CustomOverlay.userOverlaysPath() .. "/" .. self.fileName
end

function CustomOverlay:__tostring()
    return self.name
end

return CustomOverlay