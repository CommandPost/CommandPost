--- === cp.apple.finalcutpro.viewer.CustomOverlay ===
---
--- Represents a "Custom Overlay" value that can be enabled/disabled from FCP.
local require = require

local fcpApp                = require "cp.apple.finalcutpro.app"
local Set                   = require "cp.collect.Set"
local prop                  = require "cp.prop"
local tools                 = require "cp.tools"

local fs                    = require "hs.fs"
local inspect               = require "hs.inspect"
local class                 = require "middleclass"
local lazy                  = require "cp.lazy"

local pathToAbsolute                            = fs.pathToAbsolute
local getNameAndExtensionFromFile               = tools.getNameAndExtensionFromFile
local insert                                    = table.insert

local CustomOverlay = class("cp.apple.finalcutpro.viewer.CustomOverlay"):include(lazy)

--- cp.apple.finalcutpro.viewer.CustomOverlay.is(thing) -> boolean
--- Function
--- Checks if the provided `thing` is a `CustomOverlay` instance.
---
--- Parameters:
---  * thing        - The thing to check.
---
--- Returns:
---  * `true` if it is a `CustomOverlay` instance, otherwise `false`.
function CustomOverlay.static.is(thing)
    return type(thing) == "table" and thing.isInstanceOf ~= nil and thing:isInstanceOf(CustomOverlay)
end

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

--- cp.apple.finalcutpro.viewer.CustomOverlay.userOverlays <cp.prop: table of CustomOverlay; read-only>
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

local FAKE_IMAGE = "asdfghjklasdfghjklasdfghjklasdfghjkl.png"

-- Getting the image on-screen to update without it playing/scrubbing/etc requires the file name to be modified,
-- so we set it to a non-existent image and back to force it. Doesn't work for all situations unfortunately.
local function forceUpdate(fileName)
    local currentFileName = fileName:get()
    fileName:set(FAKE_IMAGE)
    fileName:set(currentFileName)
end

--- cp.apple.finalcutpro.viewer.CustomOverlay.forceViewerUpdate()
--- Function
--- Forces the current `Viewer` overlay to update. May cause a flicker. 
--- NOTE: In general, most changes will force an update automatically anyway.
function CustomOverlay.static.forceViewerUpdate()
    forceUpdate(CustomOverlay.viewerFileName)
end

--- cp.apple.finalcutpro.viewer.CustomOverlay.forceEventViewerUpdate()
--- Function
--- Forces the current `Viewer` overlay to update. May cause a flicker. 
--- NOTE: In general, most changes will force an update automatically anyway.
function CustomOverlay.static.forceEventViewerUpdate()
    forceUpdate(CustomOverlay.eventViewerFileName)
end

--- cp.apple.finalcutpro.viewer.CustomOverlay.isSelectedOnViewer <cp.prop: boolean; live>
--- Constant
--- Is `true` if the `Viewer` `CustomOverlay` is enabled.
CustomOverlay.static.isEnabledOnViewer = fcpApp.preferences:prop("FFPlayerDisplayedCustomOverlay"..VIEWER_PREFIX):mutate(
    function(original) return original() == 1 end,
    function(newValue, original) original:set(newValue and 1 or 0) end
):watch(CustomOverlay.forceViewerUpdate)

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

-- NOTE: Disabled since although the fields exist, the don't appear to do anything useful. Perhaps legacy?
-- --- cp.apple.finalcutpro.viewer.CustomOverlay.viewerOpacity <cp.prop: number; live>
-- --- Constant
-- --- The `Viewer` `CustomOverlay` opacity.
-- CustomOverlay.static.viewerOpacity = fcpApp.preferences:prop("FFCustomOverlaySelected"..VIEWER_PREFIX.."_Opacity")
-- :watch(CustomOverlay.forceViewerUpdate)

--- cp.apple.finalcutpro.viewer.CustomOverlay.isEnabledOnEventViewer <cp.prop: boolean; live>
--- Constant
--- Is `true` if the `EventViewer` `CustomOverlay` is enabled.
CustomOverlay.static.isEnabledOnEventViewer = fcpApp.preferences:prop("FFPlayerDisplayedCustomOverlay"..EVENT_VIEWER_PREFIX):mutate(
    function(original) return original() == 1 end,
    function(newValue, original) original:set(newValue and 1 or 0) end
):watch(CustomOverlay.forceEventViewerUpdate)

--- cp.apple.finalcutpro.viewer.CustomOverlay.eventViewerFileName <cp.prop: string; live>
--- Constant
--- The `EventViewer` `CustomOverlay` file name.
CustomOverlay.static.eventViewerFileName = fcpApp.preferences:prop("FFCustomOverlaySelected"..EVENT_VIEWER_PREFIX):mutate(
    function(original)
        return original()
    end,
    function(value, original)
        original:set(FAKE_IMAGE)
        original:set(value)
    end
)

-- attempts to return an overlay based on the value. May be a `CustomOverlay`, or a `string` matching the name or filename of the overlay.
local function findOverlay(value)
    if value == nil then
        return nil
    end

    if CustomOverlay.is(value) then
        return value
    elseif type(value) == "string" then
        local overlay = CustomOverlay.forFileName(value)
        if not overlay then
            return CustomOverlay.forName(value)
        end
        return overlay
    end
end

-- NOTE: Disabled since although the opacity fields exist, the don't appear to do anything useful. Perhaps legacy?
-- --- cp.apple.finalcutpro.viewer.CustomOverlay.eventViewerOpacity <cp.prop: number; live>
-- --- Constant
-- --- The `EventViewer` `CustomOverlay` opacity.
-- CustomOverlay.static.eventViewerOpacity = fcpApp.preferences:prop("FFCustomOverlaySelected"..EVENT_VIEWER_PREFIX.."_Opacity")
-- :watch(CustomOverlay.forceEventViewerUpdate)

--- cp.apple.finalcutpro.viewer.CustomOverlay.viewerOverlay <cp.prop: CustomOverlay; live>
--- Constant
--- The `Viewer` `CustomOverlay`.
CustomOverlay.static.viewerOverlay = CustomOverlay.viewerFileName:mutate(
    function(original)
        local fileName = original()
        return CustomOverlay.forFileName(fileName)
    end,
    function(value, original)
        if value == nil then
            original:set(nil)
            return
        end

        local overlay = findOverlay(value)
        if CustomOverlay.is(overlay) then
            original:set(overlay.fileName)
        else
            error(string.format("Expected a CustomOverlay or a string with the image name or the simple name, but got: %s", inspect(value)), 3)
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
        if value == nil then
            original:set(nil)
            return
        end

        local overlay = findOverlay(value)
        if CustomOverlay.is(overlay) then
            original:set(overlay.fileName)
        else
            error(string.format("Expected a CustomOverlay or a string with the image name or the simple name, but got: %s", inspect(value)), 3)
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
    if not fileName then
        return nil
    end
    local name, ext = getNameAndExtensionFromFile(fileName)
    if ext and CustomOverlay.ALLOWED_IMAGE_EXTENSIONS:has(ext) 
        and pathToAbsolute(CustomOverlay.userOverlaysPath().."/"..fileName)
    then
        return CustomOverlay(name, ext)
    end
    return nil
end

--- cp.apple.finalcutpro.viewer.CustomOverlay.forName(name) -> CustomOverlay | nil
--- Constructor
--- If a supported file with the provided `name`, as it appears in the FCP menu, exists in the `Custom Overlays` folder,
--- return a new `CustomOverlay` that describes it.
---
--- Parameters:
---  * name - The simple file name (eg. "My Overlay")
---
--- Returns:
---  * The `CustomOverlay`, or `nil` if the file does not exist, or is not one of the supported formats.
function CustomOverlay.static.forName(name)
    if not name then
        return nil
    end
    for _,o in ipairs(CustomOverlay.userOverlays()) do
        if o.name == name then
            return o
        end
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

--- cp.apple.finalcutpro.viewer.CustomOverlay.isEnabledOnViewer <cp.prop: boolean; live>
--- Field
--- If `true`, the `CustomOverlay` is enabled on the `Viewer`.
function CustomOverlay.lazy.prop:isEnabledOnViewer()
    return prop(
        function()
            return CustomOverlay.isEnabledOnViewer() and self:isSelectedOnViewer()
        end,
        function(enabled)
            if enabled then
                self:isSelectedOnViewer(true)
                CustomOverlay.isEnabledOnViewer(true)
            elseif self:isSelectedOnViewer() then
                CustomOverlay.isEnabledOnViewer(false)
            end
        end
    )
end

--- cp.apple.finalcutpro.viewer.CustomOverlay.isEnabledOnEventViewer <cp.prop: boolean; live>
--- Field
--- If `true`, the `CustomOverlay` is enabled on the `EventViewer`.
function CustomOverlay.lazy.prop:isEnabledOnEventViewer()
    return prop(
        function()
            return CustomOverlay.isEnabledOnEventViewer() and self:isSelectedOnEventViewer()
        end,
        function(enabled)
            if enabled then
                self:isSelectedOnEventViewer(true)
                CustomOverlay.isEnabledOnEventViewer(true)
            elseif self:isSelectedOnEventViewer() then
                CustomOverlay.isEnabledOnEventViewer(false)
            end
        end
    )
end

--- cp.apple.finalcutpro.viewer.CustomOverlay.isSelectedOnViewer <cp.prop: boolean; live>
--- Field
--- Indicates if this `CustomOverlay` is currently selected for the `Viewer`. It may not be visible if `CustomOverlay.isSelectedOnViewer()` is not `true`.
function CustomOverlay.lazy.prop:isSelectedOnViewer()
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

--- cp.apple.finalcutpro.viewer.CustomOverlay.isSelectedOnEventViewer <cp.prop: boolean; live>
--- Field
--- Indicates if this `CustomOverlay` is currently enabled for the `EventViewer`. It may not be visible if `CustomOverlay.isSelectedOnEventViewer()` is not `true`.
function CustomOverlay.lazy.prop:isSelectedOnEventViewer()
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
    return fcpApp.preferences:prop(self.fileName.."_Opacity_"..VIEWER_PREFIX, 100)
    :watch(CustomOverlay.forceViewerUpdate)
end

--- cp.apple.finalcutpro.viewer.CustomOverlay.eventViewerOpacity <cp.prop: number; live>
--- Field
--- The opacity of the overlay in the `EventViewer`, if enabled.
function CustomOverlay.lazy.prop:eventViewerOpacity()
    return fcpApp.preferences:prop(self.fileName.."_Opacity_"..EVENT_VIEWER_PREFIX, 100)
    :watch(CustomOverlay.forceEventViewerUpdate)
end

function CustomOverlay:__eq(other)
    return self.name == other.name and self.extension == other.extension
end

function CustomOverlay:__tostring()
    return self.name
end

return CustomOverlay