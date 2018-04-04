--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.inspector.info.InfoInspector ===
---
--- Video Inspector Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

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
local PropertyRow                       = require("cp.ui.PropertyRow")
local TextField                         = require("cp.ui.TextField")

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
    return element ~= nil and #element >= 4
        and #axutils.childrenWithRole(element, "AXStaticText") == 3
        and axutils.childWithRole(element, "AXScrollArea") ~= nil
end

--- cp.apple.finalcutpro.inspector.info.InfoInspector:new(parent) -> InfoInspector object
--- Method
--- Creates a new InfoInspector object
---
--- Parameters:
---  * `parent`     - The parent
---
--- Returns:
---  * A InfoInspector object
-- TODO: Use a function instead of a method.
function InfoInspector:new(parent) -- luacheck: ignore

    local o = prop.extend({
        _parent = parent,
        _child = {}
    }, InfoInspector)

    o.sceneRow = o:propertyRow("Scene")
    o.scene = TextField:new(o, function()
        return axutils.childWithRole(o.sceneRow:children(), "AXTextField")
    end)

    o.takeRow = o:propertyRow("Take")
    o.take = TextField:new(o, function()
        return axutils.childWithRole(o.takeRow:children(), "AXTextField")
    end)

    return o
end

--- cp.apple.finalcutpro.inspector.info.InfoInspector:propertyRow(title) -> PropertyRow
--- Method
--- Gets the Property Row object.
---
--- Parameters:
---  * title - The title of the Property Row.
---
--- Returns:
---  * A `PropertyRow` object.
function InfoInspector:propertyRow(title)
    return PropertyRow.new(self, title, "propertiesUI")
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

--- cp.apple.finalcutpro.inspector.info.InfoInspector:UI() -> hs._asm.axuielement object
--- Method
--- Returns the `hs._asm.axuielement` object for the Info Inspector
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `hs._asm.axuielement` object.
function InfoInspector:UI()
    return axutils.cache(self, "_ui",
        function()
            local ui = self:parent():panelUI()
            return InfoInspector.matches(ui) and ui or nil
        end,
        InfoInspector.matches
    )
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
function InfoInspector:propertiesUI()
    return axutils.cache(self, "_properties", function()
        return axutils.childWithRole(self:UI(), "AXScrollArea")
    end)
end

--- cp.apple.finalcutpro.inspector.info.InfoInspector:isShowing() -> boolean
--- Method
--- Is the Info Inspector currently showing?
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if showing, otherwise `false`
function InfoInspector:isShowing()
    return self:UI() ~= nil
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
        self:app():menuBar():selectMenu({"Window", "Go To", "Inspector"})
    end
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
        self._metadataViewButton = MenuButton.new(self, function()
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

--- cp.apple.finalcutpro.inspector.info.InfoInspector.metadataView <cp.prop: string>
--- Field
--- Gets the name of the current metadata view.
InfoInspector.metadataView = prop(
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
):bind(InfoInspector)

--------------------------------------------------------------------------------
--
-- INFO INSPECTOR:
--
--------------------------------------------------------------------------------

return InfoInspector
