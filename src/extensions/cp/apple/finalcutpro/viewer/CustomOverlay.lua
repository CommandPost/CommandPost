--- === cp.apple.finalcutpro.viewer.CustomOverlay ===
---
--- Represents a "Custom Overlay" value that can be enabled/disabled from FCP.
local require = require

local fcpApp                = require "cp.apple.finalcutpro.app"
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

local userOverlaysPath = pathToAbsolute("~/Library/Application Support/ProApps/Custom Overlays")

--- cp.apple.finalcutpro.viewer.CustomOverlay.userOverlaysPath() -> string
--- Function
--- Returns the absolute path to the location where Custom Overlay images are stored for the current user.
function CustomOverlay.static.userOverlaysPath()
    return userOverlaysPath
end

--- cp.apple.finalcutpro.viewer.CustomOverlay.userOverlays <cp.prop: CustomOverlay; read-only>
--- Constant
--- Contains the current list of `CustomOverlay`s available.
CustomOverlay.static.userOverlays = prop(function()
    local overlays = {}

    for file in fs.dir(CustomOverlay.userOverlaysPath()) do
        local overlay = CustomOverlay.forFileName(file)
        if overlay then
            insert(overlays, overlay)
        end
    end

    return overlays
end)

local VIEWER_PREFIX = "Canvas"
local EVENT_VIEWER_PREFIX = "Viewer"

--- cp.apple.finalcutpro.viewer.CustomOverlay.viewerEnabled <cp.prop: boolean; live>
--- Constant
--- Is `true` if the `Viewer` `CustomOverlay` is enabled.
CustomOverlay.static.viewerEnabled = fcpApp.preferences:prop("FFPlayerDisplayedCustomOverlay"..VIEWER_PREFIX):mutate(
    -- TODO: Trigger "View > Show in Viewer > Show Custom Overlay" to actually toggle, to avoid UI update lag
    function(original) return original() == 1 end,
    function(newValue, original) original:set(newValue and 1 or 0) end
)

--- cp.apple.finalcutpro.viewer.CustomOverlay.viewerFileName <cp.prop: string; live>
--- Constant
--- The `Viewer` `CustomOverlay` file name.
CustomOverlay.static.viewerFileName = fcpApp.preferences:prop("FFCustomOverlaySelected"..VIEWER_PREFIX):mutate(
    function(original)
        return original()
    end,
    function(value, original)
        original:set(nil)
        original:set(value)
    end
)

--- cp.apple.finalcutpro.viewer.CustomOverlay.viewerOpacity <cp.prop: number; live>
--- Constant
--- The `Viewer` `CustomOverlay` opacity.
CustomOverlay.static.viewerOpacity = fcpApp.preferences:prop("FFCustomOverlaySelected"..VIEWER_PREFIX.."_Opacity")

--- cp.apple.finalcutpro.viewer.CustomOverlay.eventViewerEnabled <cp.prop: boolean; live>
--- Constant
--- Is `true` if the `EventViewer` `CustomOverlay` is enabled.
CustomOverlay.static.eventViewerEnabled = fcpApp.preferences:prop("FFPlayerDisplayedCustomOverlay"..EVENT_VIEWER_PREFIX):mutate(
    -- TODO: Trigger "View > Show in Event Viewer > Show Custom Overlay" to actually toggle, to avoid UI update lag
    function(original) return original() == 1 end,
    function(newValue, original) original:set(newValue and 1 or 0) end
)

--- cp.apple.finalcutpro.viewer.CustomOverlay.eventViewerFileName <cp.prop: string; live>
--- Constant
--- The `EventViewer` `CustomOverlay` file name.
CustomOverlay.static.eventViewerFileName = fcpApp.preferences:prop("FFCustomOverlaySelected"..EVENT_VIEWER_PREFIX):mutate(
    function(original)
        return original()
    end,
    function(value, original)
        original:set(nil)
        original:set(value)
    end
)

--- cp.apple.finalcutpro.viewer.CustomOverlay.eventViewerOpacity <cp.prop: number; live>
--- Constant
--- The `EventViewer` `CustomOverlay` opacity.
CustomOverlay.static.eventViewerOpacity = fcpApp.preferences:prop("FFCustomOverlaySelected"..EVENT_VIEWER_PREFIX.."_Opacity")

--- cp.apple.finalcutpro.viewer.CustomOverlay.viewerOverlay <cp.prop: CustomOverlay; live>
--- Constant
--- The `Viewer` `CustomOverlay`.
CustomOverlay.static.viewerOverlay = CustomOverlay.viewerFileName:mutate(
    function(original)
        local fileName = original()
        return CustomOverlay.forFileName(fileName)
    end,
    function(value, original)
        local filePath = value and value.filePath
        if filePath and not pathToAbsolute(filePath) then
            original:set(value.fileName)
        else
            original:set(nil)
        end
    end
)

--- cp.apple.finalcutpro.viewer.CustomOverlay.eventViewerOverlay <cp.prop: CustomOverlay; live>
--- Constant
--- The `EventViewer` `CustomOverlay`.
CustomOverlay.static.eventViewerOverlay = CustomOverlay.eventViewerFileName:mutate(
    function(original)
        local fileName = original()
        return CustomOverlay.forFileName(fileName)
    end,
    function(value, original)
        local filePath = value and value.filePath
        if filePath and not pathToAbsolute(filePath) then
            original:set(value.fileName)
        else
            original:set(nil)
        end
    end
)

--- cp.apple.finalcutpro.viewer.CustomOverlay.forFileName(fileName) -> CustomOverlay | nil
--- Constructor
--- If a supported file with the provided `fileName` exists in the `Custom Overlays` folder, return a new `CustomOverlay`
--- that describes it.
---
--- Parameters:
---  * fileName - The simple file name (eg. "My Overlay.png")
---
--- Returns:
---  * The `CustomOverlay`, or `nil` if the file does not exist, or is not one of the supported formats.
function CustomOverlay.static.forFileName(fileName)
    local name, ext = getNameAndExtensionFromFile(fileName)
    if ext and CustomOverlay.ALLOWED_IMAGE_EXTENSIONS:has(ext) 
        and pathToAbsolute(CustomOverlay.userOverlaysPath().."/"..fileName)
    then
        return CustomOverlay(name, ext)
    end
    return nil
end

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

--- cp.apple.finalcutpro.viewer.CustomOverlay.name <string>
--- Field
--- The name of the overlay, as appears in the Viewer's 'Choose Custom Overlay' menu.

--- cp.apple.finalcutpro.viewer.CustomOverlay.extension <string>
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

--- cp.apple.finalcutpro.viewer.CustomOverlay.viewerEnabled <cp.prop: boolean; live>
--- Field
--- Indicates if this `CustomOverlay` is currently selected for the `Viewer`. It may not be visible if `CustomOverlay.viewerEnabled()` is not `true`.
function CustomOverlay.lazy.prop:viewerEnabled()
    return CustomOverlay.viewerFileName:mutate(
        function(original)
            return original() == self.fileName
        end,
        function(value, original)
            if value then
                original:set(self.fileName)
            else
                -- only clear it if currently set to this file name.
                if original() == self.fileName then
                    original:set(nil)
                end
            end
        end
    )
end

--- cp.apple.finalcutpro.viewer.CustomOverlay.eventViewerEnabled <cp.prop: boolean; live>
--- Field
--- Indicates if this `CustomOverlay` is currently enabled for the `EventViewer`. It may not be visible if `CustomOverlay.eventViewerEnabled()` is not `true`.
function CustomOverlay.lazy.prop:eventViewerEnabled()
    return CustomOverlay.eventViewerFileName:mutate(
        function(original)
            return original() == self.fileName
        end,
        function(value, original)
            if value then
                original:set(self.fileName)
            else
                -- only clear it if currently set to this file name.
                if original() == self.fileName then
                    original:set(nil)
                end
            end
        end
    )
end

--- cp.apple.finalcutpro.viewer.CustomOverlay.viewerOpacity <cp.prop: number; live>
--- Field
--- The opacity of the overlay in the `Viewer`, if enabled.
function CustomOverlay.lazy.prop:viewerOpacity()
    return fcpApp.preferences:prop(self.fileName.."_Opacity_"..VIEWER_PREFIX)
end

--- cp.apple.finalcutpro.viewer.CustomOverlay.eventViewerOpacity <cp.prop: number; live>
--- Field
--- The opacity of the overlay in the `EventViewer`, if enabled.
function CustomOverlay.lazy.prop:eventViewerOpacity()
    return fcpApp.preferences:prop(self.fileName.."_Opacity_"..EVENT_VIEWER_PREFIX)
end

function CustomOverlay:__eq(other)
    return self.name == other.name and self.extension == other.extension
end

function CustomOverlay:__tostring()
    return self.name
end

return CustomOverlay