--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.inspector.video.VideoInspector ===
---
--- Video Inspector Module.
---
--- Header Rows (`compositing`, `transform`, etc.) have the following properties:
--- * enabled   - (cp.ui.CheckBox) Indicates if the section is enabled.
--- * toggle    - (cp.ui.Button) Will toggle the Hide/Show button.
--- * reset     - (cp.ui.Button) Will reset the contents of the section.
--- * expanded  - (cp.prop <boolean>) Get/sets whether the section is expanded.
---
--- Property Rows depend on the type of property:
---
--- Menu Property:
--- * value     - (cp.ui.PopUpButton) The current value of the property.
---
--- Slider Property:
--- * value     - (cp.ui.Slider) The current value of the property.
---
--- XY Property:
--- * x         - (cp.ui.TextField) The current 'X' value.
--- * y         - (cp.ui.TextField) The current 'Y' value.
---
--- CheckBox Property:
--- * value     - (cp.ui.CheckBox) The currently value.
---
--- For example:
--- ```lua
--- local video = fcp:inspector():video()
--- -- Menu Property:
--- video:compositing():blendMode():value("Subtract")
--- -- Slider Property:
--- video:compositing():opacity():value(50.0)
--- -- XY Property:
--- video:transform():position():x(-10.0)
--- -- CheckBox property:
--- video:stabilization():tripodMode():value(true)
--- ```
---
--- You should also be able to show a specific property and it will be revealed:
--- ```lua
--- video:stabilization():smoothing():show():value(1.5)
--- ```


--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log								= require("hs.logger").new("videoInspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local prop								= require("cp.prop")
local axutils							= require("cp.ui.axutils")
local Button                            = require("cp.ui.Button")
local CheckBox                          = require("cp.ui.CheckBox")
local PropertyRow                       = require("cp.ui.PropertyRow")
local TextField                         = require("cp.ui.TextField")
local Slider                            = require("cp.ui.Slider")
local PopUpButton                       = require("cp.ui.PopUpButton")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local VideoInspector = {}

local function propShow(self)
    local parent = self:parent()
    parent:show()
    self.header:expanded(true)
    return self
end

local function propHide(self)
    self.header:expanded(false)
    return self
end

local function rowRow(row, lKey, index)
    return row:parent():row(lKey, index)
end

-- creates a new header row PropertyRow with some additional properties:
-- * enabled - The 'enabled' checkbox.
-- * toggle - the Hide/Show toggle button
-- * reset  - The reset button
-- * expanded - a cp.prop which gets/sets whether the row is expanded.
local function headerRow(labelKey, index)
    return function(subProps)
        local header = prop(function(self)
            local row = self:row(labelKey, index)
            row.enabled     = CheckBox.new(row, function() return axutils.childFromLeft(row:children(), 1) end)
            row.toggle      = Button.new(row, function() return axutils.childFromRight(row:children(), 2) end)
            row.reset       = Button.new(row, function() return axutils.childFromRight(row:children(), 1) end)
            row.expanded    = prop(
                function(theRow)
                    local iHide = theRow:app():string("FFInspectorHeaderControllerButtonHide")
                    return theRow.toggle:title() == iHide
                end,
                function(newValue, theRow, theProp)
                    local currentValue = theProp:get()
                    if newValue ~= currentValue then
                        theRow.toggle()
                    end
                end
            ):bind(row)

            -- gets called by propertyRows
            row.row = rowRow

            if subProps then
                prop.bind(row)(subProps)
                -- hijack the 'show' function
                for _,p in pairs(subProps) do
                    local subRow = p()
                    subRow.header = row
                    subRow.show = propShow
                    subRow.hide = propHide
                end
            end

            return row
        end):cached()


        return header
    end
end

local function propertyRow(labelKey, prepareFn, index)
    return prop(function(self)
        local row = self:row(labelKey, index)
        row.reset       = Button.new(row, function() return axutils.childFromRight(row:children(), 1) end)

        if prepareFn then
            prepareFn(row)
        end

        return row
    end):cached()
end

local function xyProperty(labelKey, index)
    return propertyRow(labelKey, function(row)
        row.x = TextField.new(row, function() return axutils.childFromLeft(axutils.childrenMatching(row:children(), TextField.matches), 1) end, tonumber)
        row.y = TextField.new(row, function() return axutils.childFromLeft(axutils.childrenMatching(row:children(), TextField.matches), 2) end, tonumber)
    end, index)
end

local function sliderProperty(labelKey, index)
    return propertyRow(labelKey, function(row)
        row.value = TextField.new(row, function() return axutils.childFromLeft(row:children(), 3) end, tonumber)
    end, index)
end

local function menuProperty(labelKey, index)
    return propertyRow(labelKey, function(row)
        row.value = PopUpButton.new(row, function() return axutils.childFromRight(row:children(), 2) end)
    end, index)
end

local function checkBoxProperty(labelKey, index)
    return propertyRow(labelKey, function(row)
        row.value = CheckBox.new(row, function() return axutils.childFromLeft(axutils.childMatching(row:children(), CheckBox.matches), 1) end)
    end, index)
end

--- cp.apple.finalcutpro.inspector.video.VideoInspector.matches(element)
--- Function
--- Checks if the provided element could be a VideoInspector.
---
--- Parameters:
--- * element   - The element to check
---
--- Returns:
--- * `true` if it matches, `false` if not.
function VideoInspector.matches(element)
    if element then
        if element:attributeValue("AXRole") == "AXGroup" and #element == 1 then
            local group = element[1]
            return group and group:attributeValue("AXRole") == "AXGroup" and #group == 1
        end
    end
    return false
end

--- cp.apple.finalcutpro.inspector.video.VideoInspector.new(parent) -> cp.apple.finalcutpro.video.VideoInspector
--- Constructor
--- Creates a new `VideoInspector` object
---
--- Parameters:
---  * `parent`		- The parent
---
--- Returns:
---  * A `VideoInspector` object
-- TODO: Use a function instead of a method.
function VideoInspector.new(parent) -- luacheck: ignore
    local o
    o = prop.extend({
        _parent = parent,
        _child = {},
        _rows = {},

--- cp.apple.finalcutpro.inspector.color.VideoInspector.UI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- Returns the `hs._asm.axuielement` object for the Video Inspector.
        UI = parent.panelUI:mutate(function(original)
            return axutils.cache(o, "_ui",
                function()
                    local ui = original()
                    return VideoInspector.matches(ui) and ui or nil
                end,
                VideoInspector.matches
            )
        end),

    }, VideoInspector)

    prop.bind(o) {
--- cp.apple.finalcutpro.inspector.color.VideoInspector.isShowing <cp.prop: boolean; read-only>
--- Field
--- Checks if the VideoInspector is currently showing.
        isShowing = o.UI:mutate(function(original)
            return original() ~= nil
        end),

--- cp.apple.finalcutpro.inspector.color.VideoInspector.contentUI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- The `axuielement` containing the properties rows, if available.
        contentUI = o.UI:mutate(function(original)
            return axutils.cache(o, "_contentUI", function()
                local ui = original()
                if ui then
                    local group = ui[1]
                    if group then
                        local scrollArea = group[1]
                        return scrollArea and scrollArea:attributeValue("AXRole") == "AXScrollArea" and scrollArea
                    end
                end
                return nil
            end)
        end),

        effects             = headerRow "FFInspectorBrickEffects" {},
        compositing         = headerRow "FFHeliumBlendCompositingEffect" {
            blendMode       = menuProperty "FFHeliumBlendMode",
            opacity         = sliderProperty "FFHeliumBlendOpacity",
        },

        transform           = headerRow "FFHeliumXFormEffect" {
            position        = xyProperty "FFHeliumXFormPosition",
            rotation        = sliderProperty "FFHeliumXFormRotation",
            scaleAll        = sliderProperty "FFHeliumXFormScaleInspector",
            scaleX          = sliderProperty "FFHeliumXFormScaleXInspector",
            scaleY          = sliderProperty "FFHeliumXFormScaleYInspector",
            anchor          = xyProperty "FFHeliumXFormAnchor",
        },

        crop                = headerRow "FFHeliumCropEffect" {
            type            = menuProperty "FFType",
            left            = sliderProperty "FFCropLeft",
            right           = sliderProperty "FFCropRight",
            top             = sliderProperty "FFCropTop",
            bottom          = sliderProperty "FFCropBottom",
        },
        distort             = headerRow "FFHeliumDistortEffect" {
            bottomLeft      = xyProperty "PerspectiveTile::Bottom Left",
            bottomRight     = xyProperty "PerspectiveTile::Bottom Right",
            topRight        = xyProperty "PerspectiveTile::Top Right",
            topLeft         = xyProperty "PerspectiveTile::Top Left",
        },
        stabilization       = headerRow "FFStabilizationEffect" {
            method          = menuProperty "FFStabilizationAlgorithmRequested",
            smoothing       = sliderProperty "FFStabilizationInertiaCamSmooth",
            tripodMode      = checkBoxProperty "FFStabilizationUseTripodMode",
        },
        rollingShutter      = headerRow "FFRollingShutterEffect" {
            amount          = menuProperty "FFRollingShutterAmount",
        },
        spatialConform      = headerRow "FFHeliumConformEffect" {
            type            = menuProperty("FFType", 2),
        },
    }

    return o
end

--- cp.apple.finalcutpro.inspector.video.VideoInspector:parent() -> table
--- Method
--- Returns the VideoInspector's parent table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function VideoInspector:parent()
    return self._parent
end

--- cp.apple.finalcutpro.inspector.video.VideoInspector:app() -> table
--- Method
--- Returns the `cp.apple.finalcutpro` app table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application object as a table
function VideoInspector:app()
    return self:parent():app()
end

--------------------------------------------------------------------------------
--
-- VIDEO INSPECTOR:
--
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.video.VideoInspector:show() -> VideoInspector
--- Method
--- Shows the Video Inspector
---
--- Parameters:
---  * None
---
--- Returns:
---  * VideoInspector
function VideoInspector:show()
    self:parent():selectTab("Video")
    return self
end

--- cp.apple.finalcutpro.inspector.video.VideoInspector:row(labelKey, index) -> PropertyRow
--- Method
--- Returns a `PropertyRow` for a row with the specified label key.
---
--- Parameters:
--- * labelKey  - The key for the label (see FCP App `keysWithString` method).
---
--- Returns:
--- * The `PropertyRow`.
function VideoInspector:row(labelKey, index)
    local key = labelKey
    if index ~= nil and index > 1 then
        key = labelKey .. "_" .. tostring(index)
    end

    local row = self._rows[key]

    if not row then
        row = PropertyRow.new(self, labelKey, "contentUI", index)
        self._rows[key] = row
    end

    return row
end

return VideoInspector