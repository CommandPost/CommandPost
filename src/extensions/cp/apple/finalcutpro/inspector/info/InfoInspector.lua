--- === cp.apple.finalcutpro.inspector.info.InfoInspector ===
---
--- Video Inspector Module.

local require               = require

--local log                   = require "hs.logger".new "infoInspect"

local axutils               = require "cp.ui.axutils"
local BasePanel             = require "cp.apple.finalcutpro.inspector.BasePanel"
local IP                    = require "cp.apple.finalcutpro.inspector.InspectorProperty"
local MenuButton            = require "cp.ui.MenuButton"
local prop                  = require "cp.prop"
local strings               = require "cp.apple.finalcutpro.strings"

local hasProperties         = IP.hasProperties
local menuButton            = IP.menuButton
local staticText            = IP.staticText
local textField             = IP.textField

local childFromLeft         = axutils.childFromLeft
local childrenWithRole      = axutils.childrenWithRole
local childWithRole         = axutils.childWithRole
local withAttributeValue    = axutils.withAttributeValue
local withRole              = axutils.withRole

local InfoInspector = BasePanel:subclass("InfoInspector")

--- cp.apple.finalcutpro.inspector.info.InfoInspector.metadataViews -> table
--- Constant
--- Metadata Views
InfoInspector.static.metadataViews = {
    ["Basic"] = "basic viewset",
    ["General"] = "general viewset",
    ["Extended"] = "extended viewset",
    ["Audio"] = "audio viewset",
    ["EXIF"] = "exif viewset",
    ["IPTC"] = "iptc viewset",
    ["Settings"] = "settings viewset",
    ["HDR"] = "hdr viewset",
    ["DPP Editorial/Services"] = "DPPEditorialServicesViewSet",
    ["DPP Media"] = "DPPMediaViewSet",
    ["MXF"] = "MXFViewSet",
}

--- cp.apple.finalcutpro.inspector.info.InfoInspector.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function InfoInspector.static.matches(element)
    local root = BasePanel.matches(element) and withRole(element, "AXGroup")
    local scrollArea = root and #childrenWithRole(root, "AXStaticText") >= 2 and childWithRole(root, "AXScrollArea")
    return scrollArea and withAttributeValue(scrollArea, "AXDescription", strings:find("FFInspectorModuleMetadataScrollViewAXDescription")) or false
end

--- cp.apple.finalcutpro.inspector.info.InfoInspector.new(parent) -> InfoInspector object
--- Constructor
--- Creates a new InfoInspector object
---
--- Parameters:
---  * `parent`     - The parent
---
--- Returns:
---  * A InfoInspector object
function InfoInspector:initialize(parent)
    BasePanel.initialize(self, parent, "Info")

    hasProperties(self, self.propertiesUI) {
        name                    = textField "Name",
        lastModified            = staticText "Last Modified",
        notes                   = textField "Notes",

        videoRoles              = menuButton "Video Roles",
        audioRoles              = menuButton "Audio Roles",

        clipStart               = staticText "Start",
        clipEnd                 = staticText "End",
        clipDuration            = staticText "Duration",

        reel                    = textField "Reel",
        scene                   = textField "Scene",
        take                    = textField "Take",
        cameraAngle             = textField "Camera Angle",
        cameraName              = textField "Camera Name",

        cameraLUT               = menuButton "Log Processing",
        colorProfile            = staticText "color profile",

        projectionMode          = menuButton "FFMD360ProjectionType",
        stereoscopicMode        = menuButton "FFMD3DStereoMode",

        mediaStart              = staticText "Media Start",
        mediaEnd                = staticText "Media End",
        mediaDuration           = staticText "Media Duration",

        frameSize               = staticText "Frame Size",
        videoFrameRate          = staticText "Video Frame Rate",

        audioOutputChannels     = staticText "Audio Channel Count",
        audioSampleRate         = staticText "Audio Sample Rate",
    }
end

--- cp.apple.finalcutpro.inspector.info.InfoInspector:propertiesUI() -> hs.axuielement object
--- Method
--- Returns the `hs.axuielement` object for the Properties UI.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `hs.axuielement` object.
function InfoInspector.lazy.prop:propertiesUI()
    return self.UI:mutate(function(original)
        return axutils.cache(self, "_properties", function()
            return axutils.childWithRole(original(), "AXScrollArea")
        end)
    end)
end

--- cp.apple.finalcutpro.inspector.info.InfoInspector.metadataView <cp.prop: string>
--- Field
--- Gets the name of the current metadata view.
function InfoInspector.lazy.prop:metadataView()
    return prop(
        function()
            local text = self.metadataViewButton:getTitle()
            if text then
                local app = self:app()
                for k,v in pairs(InfoInspector.metadataViews) do
                    if app:string(v) == text then
                        return k
                    end
                end
            end
            return nil
        end,
        function(value)
            self:show()
            local key = InfoInspector.metadataViews[value]
            local text = self:app():string(key)
            self.metadataViewButton:selectItemMatching(text)
        end
    )
end

--- cp.apple.finalcutpro.inspector.info.InfoInspector.metadataViewButton <cp.io.MenuButton>
--- Field
--- The Info Inspector Metadata View Button.
function InfoInspector.lazy.value:metadataViewButton()
    return MenuButton(self, function()
        local ui = self:parent():bottomBarUI()
        local menu = childFromLeft(ui, 1)
        if menu:attributeValue("AXRole") == "AXGroup" then
            menu = menu[1]
        end
        return MenuButton.matches(menu) and menu or nil
    end)
end

return InfoInspector
