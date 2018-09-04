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
local MenuButton                        = require("cp.ui.MenuButton")
local prop                              = require("cp.prop")

local strings                           = require("cp.apple.finalcutpro.strings")
local IP                                = require("cp.apple.finalcutpro.inspector.InspectorProperty")

local hasProperties                     = IP.hasProperties
local textField, staticText, menuButton = IP.textField, IP.staticText, IP.menuButton

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local InfoInspector = {}

--- cp.apple.finalcutpro.inspector.info.InfoInspector.metadataViews -> table
--- Constant
--- Metadata Views
InfoInspector.metadataViews = {
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
function InfoInspector.matches(element)
    if element ~= nil and #element >= 4 and #axutils.childrenWithRole(element, "AXStaticText") == 3 then
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
function InfoInspector.new(parent)

    local o = prop.extend({
        _parent = parent,
        _child = {},

--- cp.apple.finalcutpro.inspector.info.InfoInspector:UI() -> hs._asm.axuielement object
--- Method
--- Returns the `hs._asm.axuielement` object for the Info Inspector
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `hs._asm.axuielement` object.
        UI = parent.panelUI:mutate(function(original, self)
            return axutils.cache(self, "_ui",
                function()
                    local ui = original()
                    return InfoInspector.matches(ui) and ui or nil
                end,
                InfoInspector.matches
            )
        end),
    }, InfoInspector)

    prop.bind(o) {
--- cp.apple.finalcutpro.inspector.info.InfoInspector:propertiesUI() -> hs._asm.axuielement object
--- Method
--- Returns the `hs._asm.axuielement` object for the Properties UI.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `hs._asm.axuielement` object.
        propertiesUI = o.UI:mutate(function(original, self)
            return axutils.cache(self, "_properties", function()
                return axutils.childWithRole(original(), "AXScrollArea")
            end)
        end),

--- cp.apple.finalcutpro.inspector.info.InfoInspector:isShowing() -> boolean
--- Method
--- Is the Info Inspector currently showing?
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if showing, otherwise `false`
        isShowing = o.UI:mutate(function(original)
            return original() ~= nil
        end),

--- cp.apple.finalcutpro.inspector.info.InfoInspector.metadataView <cp.prop: string>
--- Field
--- Gets the name of the current metadata view.
        metadataView = prop(
            function(self)
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
            function(value, self)
                self:show()
                local key = InfoInspector.metadataViews[value]
                local text = self:app():string(key)
                self:metadataViewButton():selectItemMatching(text)
            end
        ),
    }

    hasProperties(o, o.propertiesUI) {
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

    return o
end

--- cp.apple.finalcutpro.inspector.info.InfoInspector:parent() -> table
--- Method
--- Returns the InfoInspector's parent table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function InfoInspector:parent()
    return self._parent
end

--- cp.apple.finalcutpro.inspector.info.InfoInspector:app() -> table
--- Method
--- Returns the `cp.apple.finalcutpro` app table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application object as a table
function InfoInspector:app()
    return self:parent():app()
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

--- cp.apple.finalcutpro.inspector.info.InfoInspector:show() -> MenuButton
--- Method
--- Gets the Info Inspector Metadata View Button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * An `MenuButton` object.
function InfoInspector:metadataViewButton()
    if not self._metadataViewButton then
        self._metadataViewButton = MenuButton(self, function()
            local ui = self:parent():bottomBarUI()
            local menu = axutils.childFromLeft(ui, 1)
            if menu:attributeValue("AXRole") == "AXGroup" then
                menu = menu[1]
            end
            return MenuButton.matches(menu) and menu or nil
        end)
    end
    return self._metadataViewButton
end

--------------------------------------------------------------------------------
--
-- INFO INSPECTOR:
--
--------------------------------------------------------------------------------

return InfoInspector
