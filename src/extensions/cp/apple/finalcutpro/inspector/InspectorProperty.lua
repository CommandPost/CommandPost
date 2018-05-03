--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.inspector.InspectorProperty ===
---
--- `InspectorProperty` contains helper functions for handling common property
--- types that occur in various `Inspectors` in FCP.
---
--- In addition to specific property row types like `textField`, `slider`, etc.,
--- there is also a `section`, which is for rows which expand/collapse to reveal
--- other properties.

-- local log                   = require("hs.logger").new("InspectorProperty")

local is                    = require("cp.is")
local prop                  = require("cp.prop")

local axutils               = require("cp.ui.axutils")
local Button                = require("cp.ui.Button")
local CheckBox              = require("cp.ui.CheckBox")
local MenuButton            = require("cp.ui.MenuButton")
local PopUpButton           = require("cp.ui.PopUpButton")
local PropertyRow           = require("cp.ui.PropertyRow")
local StaticText            = require("cp.ui.StaticText")
local TextField             = require("cp.ui.TextField")

local childFromLeft, childFromRight = axutils.childFromLeft, axutils.childFromRight
local childrenMatching      = axutils.childrenMatching

local mod = {}

--- cp.apple.finalcutpro.inspector.InspectorProperty.hasProperties(parent, uiFinder) -> boolean
--- Function
--- This will prepare the `parent` to handle containing `PropertyRow` children, and returns
--- a function which can pass in a table of properties to bind to the parent.
---
--- E.g.:
---
--- ```lua
--- local o = {
---     propertiesUI = ...,
--- }
--- InspectorProperty.hasProperties(o, o.propertiesUI) {
---     propOne     = InspectorProperty.textField "FFPropOne",
---     sectionOne  = InspectorProperty.section "FFSectionOne" {
---         sliderOne   = InspectorProperty.slider "FFSliderOne",
---     },
--- }
--- ```
---
--- Parameters:
--- * parent    - The parent table.
--- * uiFinder  - The function or cp.prop which will be called to find the parent UI element. Functions will be passed the `parent` when being executed.
---
--- Returns:
---
function mod.hasProperties(parent, uiFinder)
    PropertyRow.prepareParent(parent, uiFinder)
    return function(props)
        prop.bind(parent)(props)
    end
end

local function propShow(self)
    local parent = self:parent()
    parent:show()
    self.section:expanded(true)
    return self
end

local function propHide(self)
    self.section:expanded(false)
    return self
end

--- cp.apple.finalcutpro.inspector.InspectorProperty.section(labelKey[, index]) -> function
--- Function
--- Returns a 'section row' factory function that can be called to create a section row that contains other `PropertyRow' `cp.prop`s.
---
--- This does *not* return an actual `cp.prop`. Rather, it returns a 'factory' function that will help configure the sub-properties of
--- of the section. This can be used as follows:
---
--- ```lua
--- local o = {}
--- prop.bind(o) {
---   sectionOne         = InspectorProperty.section "FFHeaderOneKey" {     -- has sub-properties inside the `{}`
---     subRowOne       = InspectorProperty.textField "FFSubRowOneKey",
---     subRowTwo       = InspectorProperty.slider "FFSubRowTwoKey",
---   },
---   sectionTwo         = InspectorProperty.section "FFHeaderTwoKey" {}    -- no sub-properties, still needs `{}`
--- }
---
--- -- access subRowOne
--- local value = o:sectionOne():subRowOne()
--- ```
---
--- The `o.sectionOne` property will be a `cp.prop` with the following built-in additional properties:
---
--- * `enabled`     - a `cp.ui.CheckBox` which reports if the section row is enabled.
--- * `toggle`      - a `cp.ui.Button` which will toggle the show/hide button (if present)
--- * `reset`       - a `cp.ui.Button` which will reset the sub-property values, if present in the UI.
--- * `expanded`    - a `cp.prop` which reports if the section is currently expanded.
---
--- Parameters:
--- * labelKey      - The I18N lookup key to find the row with.
--- * index         - (optional) The occurrence of the key value in the parent. Sometimes multiple rows have the same title. Defaults to `1`.
---
--- Returns:
--- * A function which will create the section row when called.
function mod.section(labelKey, index)
    return function(subProps)
        local section = prop(function(self)
            local row = PropertyRow.new(self, labelKey, index)
            -- sections are also parents of other PropertyRows.
            PropertyRow.prepareParent(row, row.propertiesUI:mutate(function(original)
                local propsUI = original()
                local rowUI = row:UI()
                if propsUI and rowUI then
                    local frame = rowUI:frame()
                    local rowPos = frame.y + frame.h
                    return childrenMatching(propsUI, function(child)
                        local childFrame = child:frame()
                        return childFrame.y >= rowPos
                    end)
                end
                return nil
            end))

            row.enabled     = CheckBox.new(row, function() return childFromLeft(row:children(), 1) end)
            row.toggle      = Button.new(row, function() return childFromRight(row:children(), 2) end)
            row.reset       = Button.new(row, function() return childFromRight(row:children(), 1) end)
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

            if subProps then
                prop.bind(row)(subProps)
                -- hijack the 'show' function
                for _,p in pairs(subProps) do
                    local subRow = p()
                    subRow.section = row
                    subRow.show = propShow
                    subRow.hide = propHide
                end
            end

            return row
        end):cached()

        return section
    end
end

--- cp.apple.finalcutpro.inspector.InspectorProperty.simple(labelKey[, prepareFn][, index]]) -> cp.prop <cp.ui.PropertyRow; read-only>
--- Function
--- Creates a new `cp.prop` that contains a `PropertyRow`  matching the `labelKey`.
---
--- It has no additional properties, but it does allow a `prepareFn` to be provided, which will be
--- called after the `PropertyRow` is created, and passed the new `PropertyRow` as the first argument.
---
--- Parameters:
--- * labelKey      - The I18N key that the row lable matches.
--- * prepareFn     - The function to call to perform additional preparations on the row.
--- * index         - The instance number of that label (defaults to `1`).
---
--- Returns:
--- * The `cp.prop` that returns the `PropertyRow`.
local function simple(labelKey, prepareFn, index)
    if is.number(prepareFn) then
        index = prepareFn
        prepareFn = nil
    end

    return prop(function(self)
        local row = PropertyRow.new(self, labelKey, index)
        row.reset       = Button.new(row, function() return childFromRight(row:children(), 1) end)

        if prepareFn then
            prepareFn(row)
        end

        return row
    end):cached()
end

mod.simple = simple

--- cp.apple.finalcutpro.inspector.InspectorProperty.textField(labelKey[, index]) -> cp.prop <cp.ui.PropertyRow; read-only>
--- Function
--- Creates a new `cp.prop` that contains a `PropertyRow`  matching the `labelKey`.
---
--- It has one additional property:
--- * `value`   - A `cp.ui.TextField` which contains the text value.
---
--- Parameters:
--- * labelKey      - The I18N key that the row lable matches.
--- * index         - The instance number of that label (defaults to `1`).
---
--- Returns:
--- * The `cp.prop` that returns the `PropertyRow`.
function mod.textField(labelKey, index)
    return simple(labelKey, function(row)
        row.value = TextField.new(row, function() return childFromRight(row:children(), 1, TextField.matches) end)
    end, index)
end

--- cp.apple.finalcutpro.inspector.InspectorProperty.numberField(labelKey[, index]) -> cp.prop <cp.ui.PropertyRow; read-only>
--- Function
--- Creates a new `cp.prop` that contains a `PropertyRow`  matching the `labelKey`.
---
--- It has one additional property:
--- * `value`   - A `cp.ui.TextField` which contains the number value.
---
--- Parameters:
--- * labelKey      - The I18N key that the row lable matches.
--- * index         - The instance number of that label (defaults to `1`).
---
--- Returns:
--- * The `cp.prop` that returns the `PropertyRow`.
function mod.numberField(labelKey, index)
    return simple(labelKey, function(row)
        row.value = TextField.new(row, function() return childFromRight(row:children(), 1, TextField.matches) end, tonumber)
    end, index)
end

--- cp.apple.finalcutpro.inspector.InspectorProperty.staticText(labelKey[, index]) -> cp.prop <cp.ui.PropertyRow; read-only>
--- Function
--- Creates a new `cp.prop` that contains a `PropertyRow`  matching the `labelKey`.
---
--- It has one additional property:
--- * `value`   - A `cp.ui.StaticText` which contains the text value.
---
--- Parameters:
--- * labelKey      - The I18N key that the row lable matches.
--- * index         - The instance number of that label (defaults to `1`).
---
--- Returns:
--- * The `cp.prop` that returns the `PropertyRow`.
function mod.staticText(labelKey, index)
    return simple(labelKey, function(row)
        row.value = StaticText.new(row, function() return childFromRight(row:children(), 1, StaticText.matches) end)
    end, index)
end

--- cp.apple.finalcutpro.inspector.InspectorProperty.xy(labelKey[, index]) -> cp.prop <cp.ui.PropertyRow; read-only>
--- Function
--- Creates a new `cp.prop` that contains a `PropertyRow`  matching the `labelKey`.
---
--- It has two additional properties:
--- * `x`   - A `cp.ui.TextField` containing the 'X' value.
--- * `y`   - A `cp.ui.TextField` containing the `Y` value.
---
--- Parameters:
--- * labelKey      - The I18N key that the row lable matches.
--- * index         - The instance number of that label (defaults to `1`).
---
--- Returns:
--- * The `cp.prop` that returns the `PropertyRow`.
function mod.xy(labelKey, index)
    return mod.simple(labelKey, function(row)
        row.x = TextField.new(row, function() return childFromLeft(row:children(), 1, TextField.matches) end, tonumber)
        row.y = TextField.new(row, function() return childFromLeft(row:children(), 2, TextField.matches) end, tonumber)
    end, index)
end


--- cp.apple.finalcutpro.inspector.InspectorProperty.slider(labelKey[, index]) -> cp.prop <cp.ui.PropertyRow; read-only>
--- Function
--- Creates a new `cp.prop` that contains a `PropertyRow`  matching the `labelKey`.
---
--- It has one additional property:
--- * `value`   - A `cp.ui.TextField` which contains the value of the slider.
---
--- Parameters:
--- * labelKey      - The I18N key that the row lable matches.
--- * index         - The instance number of that label (defaults to `1`).
---
--- Returns:
--- * The `cp.prop` that returns the `PropertyRow`.
function mod.slider(labelKey, index)
    return mod.simple(labelKey, function(row)
        row.value = TextField.new(row, function() return childFromRight(row:children(), 1, TextField.matches) end, tonumber)
    end, index)
end

--- cp.apple.finalcutpro.inspector.InspectorProperty.menuButton(labelKey[, index]) -> cp.prop <cp.ui.PropertyRow; read-only>
--- Function
--- Creates a new `cp.prop` that contains a `PropertyRow`  matching the `labelKey`.
---
--- It has one additional property:
--- * `value`   - A `cp.ui.MenuButton` which contains the text value.
---
--- Parameters:
--- * labelKey      - The I18N key that the row lable matches.
--- * index         - The instance number of that label (defaults to `1`).
---
--- Returns:
--- * The `cp.prop` that returns the `PropertyRow`.
function mod.menuButton(labelKey, index)
    return mod.simple(labelKey, function(row)
        row.value = MenuButton.new(row, function() return childFromRight(row:children(), 1, MenuButton.matches) end)
    end, index)
end

--- cp.apple.finalcutpro.inspector.InspectorProperty.popUpButton(labelKey[, index]) -> cp.prop <cp.ui.PropertyRow; read-only>
--- Function
--- Creates a new `cp.prop` that contains a `PropertyRow`  matching the `labelKey`.
---
--- It has one additional property:
--- * `value`   - A `cp.ui.PopUpButton` which contains the text value.
---
--- Parameters:
--- * labelKey      - The I18N key that the row lable matches.
--- * index         - The instance number of that label (defaults to `1`).
---
--- Returns:
--- * The `cp.prop` that returns the `PropertyRow`.
function mod.popUpButton(labelKey, index)
    return mod.simple(labelKey, function(row)
        row.value = PopUpButton.new(row, function() return childFromRight(row:children(), 1, PopUpButton.matches) end)
    end, index)
end

--- cp.apple.finalcutpro.inspector.InspectorProperty.checkBox(labelKey[, index]) -> cp.prop <cp.ui.PropertyRow; read-only>
--- Function
--- Creates a new `cp.prop` that contains a `PropertyRow`  matching the `labelKey`.
---
--- It has one additional property:
--- * `value`   - A `cp.ui.CheckBox` which contains the boolean value for the row.
---
--- Parameters:
--- * labelKey      - The I18N key that the row lable matches.
--- * index         - The instance number of that label (defaults to `1`).
---
--- Returns:
--- * The `cp.prop` that returns the `PropertyRow`.
function mod.checkBox(labelKey, index)
    return mod.simple(labelKey, function(row)
        row.value = CheckBox.new(row, function() return childFromLeft(row:children(), 1, CheckBox.matches) end)
    end, index)
end

return mod
