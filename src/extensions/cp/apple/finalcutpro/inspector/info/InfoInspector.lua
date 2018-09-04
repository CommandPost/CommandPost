--- === cp.apple.finalcutpro.inspector.info.InfoInspector ===
---
--- Video Inspector Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
--local log                               = require("hs.logger").new("infoInspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils                           = require("cp.ui.axutils")
local Element                           = require("cp.ui.Element")
local MenuButton                        = require("cp.ui.MenuButton")
local prop                              = require("cp.prop")

local If                                = require("cp.rx.go.If")

local strings                           = require("cp.apple.finalcutpro.strings")
local IP                                = require("cp.apple.finalcutpro.inspector.InspectorProperty")

local hasProperties                     = IP.hasProperties
local textField, staticText, menuButton = IP.textField, IP.staticText, IP.menuButton

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local InfoInspector = Element:subclass("InfoInspector")

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
    if Element.matches(element) and #element >= 4 and #axutils.childrenWithRole(element, "AXStaticText") == 3 then
        local scrollArea = axutils.childWithRole(element, "AXScrollArea")
        return scrollArea and scrollArea:attributeValue("AXDescription") == strings:find("FFInspectorModuleMetadataScrollViewAXDescription")
    end
    return false
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

    local UI = parent.panelUI:mutate(function(original)
        return axutils.cache(self, "_ui",
            function()
                local ui = original()
                return InfoInspector.matches(ui) and ui or nil
            end,
            InfoInspector.matches
        )
    end)

    Element.initialize(self, parent, UI)

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

--- cp.apple.finalcutpro.inspector.info.InfoInspector:propertiesUI() -> hs._asm.axuielement object
--- Method
--- Returns the `hs._asm.axuielement` object for the Properties UI.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `hs._asm.axuielement` object.
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
            local text = self:metadataViewButton():getTitle()
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
            self:metadataViewButton():selectItemMatching(text)
        end
    )
end

--- cp.apple.finalcutpro.inspector.info.InfoInspector:show() -> none
--- Method
--- Shows the Info Inspector.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function InfoInspector:show()
    if not self:isShowing() then
        self:parent():selectTab("Info")
    end
    return self
end

--- cp.apple.finalcutpro.inspector.audio.InfoInspector:doShow() -> cp.rx.go.Statment
--- Method
--- A [Statement](cp.rx.go.Statement.md) that shows the Audio Inspector.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement`, resolving to `true` if successful and sending an error if not.
function InfoInspector:doShow()
    return If(self.isShowing):Is(false):Then(
        self:parent():doSelectTab("Info")
    ):Otherwise(true)
    :Label("InfoInspector:doShow")
end

--- cp.apple.finalcutpro.inspector.info.InfoInspector:show() -> MenuButton
--- Method
--- Gets the Info Inspector Metadata View Button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * An `MenuButton` object.
function InfoInspector.lazy.method:metadataViewButton()
    return MenuButton(self, function()
        local ui = self:parent():bottomBarUI()
        local menu = axutils.childFromLeft(ui, 1)
        if menu:attributeValue("AXRole") == "AXGroup" then
            menu = menu[1]
        end
        return MenuButton.matches(menu) and menu or nil
    end)
end

--------------------------------------------------------------------------------
--
-- INFO INSPECTOR:
--
--------------------------------------------------------------------------------

return InfoInspector
