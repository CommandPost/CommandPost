local is                    = require("cp.is")
local prop                  = require("cp.prop")
local axutils               = require("cp.ui.axutils")

local Button                = require("cp.ui.Button")
local CheckBox              = require("cp.ui.CheckBox")
local PopUpButton           = require("cp.ui.PopUpButton")
local PropertyRow           = require("cp.ui.PropertyRow")
local TextField             = require("cp.ui.TextField")

local childFromLeft, childFromRight             = axutils.childFromLeft, axutils.childFromRight
local childMatching, childrenMatching           = axutils.childMatching, axutils.childrenMatching

local format                = string.format

local PropertyPanel = {}
PropertyPanel.mt = {}
PropertyPanel.mt.__index = PropertyPanel.mt

--- cp.ui.PropertyPanel.new(parent, finderFn) -> cp.ui.PropertyPanel
--- Constructor
--- Creates a new `PropertyPanel`, which is a container that typically has multiple `PropertyRows`.
---
--- The `rowProps` is a table containing named `cp.prop` values, typically created with functions like
--- `PropertyPanel.header(...)`. Eg:
---
--- ```lua
--- local panel = PropertyPanel.new(parent, function() return ... end)
--- ```
function PropertyPanel.new(parent, finderFn, rowProps)
    local o = prop.extend({
        _parent = parent,
        _finder = finderFn,
        _rows = {},
    }, PropertyPanel.mt)

    local UI = prop(function(self)
        return axutils.cache(self, "_ui", self._finder)
    end)

    local isShowing = UI:mutate(function(original)
        local ui = original()
        return ui ~= nil
    end)

    prop.bind(o) {
        UI = UI,
        isShowing = isShowing,
    }

    if rowProps then
        -- binds additional property/header rows.
        prop.bind(rowProps)
    end

    return o
end

--- cp.ui.PropertyPanel.bind(parent[, uiSource]) -> function
--- Function
--- Returns a factory function that can be used to bind `PropertyRow`s to
--- the `parent`. By default, it will look for the `UI` function/cp.prop on
--- the `parent`, which should return the `hs._asm.axuielement` which contains the properties.
---
--- You can provide an alternate `uiSource`, which can be:
--- * A string, which is the name of a function/cp.prop on `parent` which will return the `axuielement`.
--- * A function, which will be called without parameters, and should return the `axuielement`.
--- * A `cp.prop` which will be called without parameters, and should return the `asuilement`.
---
--- It will return a function that can be called, passing in a `table` which has names mapped to `cp.prop` values that will return a `PropertyRow`.
--- The simplest way to produce these is via the other factory functions in `PropertyPanel`, such as `section` or `text`.
---
--- It will result in `cp.prop` values getting bound to the `parent` with the names in the table.
---
--- Typical useage will be something like follows:
---
--- ```lua
--- PropertyPanel.bind(parent) {
---     sectionOne              = PropertyPanel.section "FFSectionOneKey" {     -- sections can contain other properties
---         propertyOne         = PropertyPanel.text "FFTextPropertyOne"        -- simple text field property
---     },
---     topLevelProperty        = PropertyPanel.slider "FFTopLevelProp"
--- }
--- ```
---
--- Parameters:
--- * owner     - the object that will have the `PropertyRow`s bound to it.
function PropertyPanel.bind(parent, uiSource)
    local uiFinder = PropertyRow.getPropertyUIFinder(parent)
    if uiFinder and uiSource then
        error(format("The parent already has a UI Source assigned."))
    elseif not uiFinder then
        uiFinder = uiSource or "UI"
        if is.string(uiFinder) then
            uiFinder = parent[uiFinder]
            if is.nt.callable(uiFinder) then
                error(format("Expected `parent.%s` to be callable: %s", type(uiFinder)))
            end
        end
        if is.callable(uiFinder) then
            local fn = uiFinder
            uiFinder = function() return fn(parent) end
        else
            error(format("Expected the UI source to be callable: %s", type(uiFinder)))
        end
        PropertyRow.setPropertyUIFinder(parent, uiFinder)
    end

    return function(properties)
        prop.bind(parent)(properties)
    end
end

-- Common PropertyRow types --

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

--- cp.ui.PropertyPanel.header(labelKey[, index]) -> function
--- Function
--- Returns a 'header row' factory function that can be called to create a header row that contains other `PropertyRow' `cp.prop`s.
---
--- This does *not* return an actual `cp.prop`. Rather, it returns a 'factory' function that will help configure the sub-properties of
--- of the header. This can be used as follows:
---
--- ```lua
--- local o = {}
--- prop.bind(o) {
---   headerOne         = PropertyRow.header "FFHeaderOneKey" {     -- has sub-properties inside the `{}`
---     subRowOne       = PropertyRow.text "FFSubRowOneKey",
---     subRowTwo       = PropertyRow.slider "FFSubRowTwoKey",
---   },
---   headerTwo         = PropertyRow.header "FFHeaderTwoKey" {}    -- no sub-properties, still needs `{}`
--- }
---
--- -- access subRowOne
--- local value = o:headerOne():subRowOne()
--- ```
---
--- The `o.headerOne` property will be a `cp.prop` with the following built-in additional properties:
---
--- * `enabled`     - a `cp.ui.CheckBox` which reports if the header row is enabled.
--- * `toggle`      - a `cp.ui.Button` which will toggle the show/hide button (if present)
--- * `reset`       - a `cp.ui.Button` which will reset the sub-property values, if present in the UI.
--- * `expanded`    - a `cp.prop` which reports if the header/section is currently expanded.
---
--- Parameters:
--- * labelKey      - The I18N lookup key to find the row with.
--- * index         - (optional) The occurrence of the key value in the parent. Sometimes multiple rows have the same title. Defaults to `1`.
---
--- Returns:
--- * A function which will create the header row when called.
function PropertyPanel.header(labelKey, index)
    return function(subProps)
        local header = prop(function(self)
            local row = self:row(labelKey, index)
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

local function rowProp(labelKey, prepareFn, index)
    return prop(function(self)
        local row = self:row(labelKey, index)
        row.reset       = Button.new(row, function() return childFromRight(row:children(), 1) end)

        if prepareFn then
            prepareFn(row)
        end

        return row
    end):cached()
end

--- cp.ui.PropertyRow.xyProperty(labelKey[, index]) -> cp.prop
--- Function
--- Creates a new `cp.prop` that contains a `PropertyRow`  matching the `labelKey`.
---
--- Parameters:
--- * labelKey      - The I18N key that the row lable matches.
--- * index         - The instance number of that label (defaults to `1`).
---
--- Returns:
--- * The `cp.prop` that returns the `TextField
function PropertyPanel.xyProperty(labelKey, index)
    return rowProp(labelKey, function(row)
        row.x = TextField.new(row, function() return childFromLeft(childrenMatching(row:children(), TextField.matches), 1) end, tonumber)
        row.y = TextField.new(row, function() return childFromLeft(childrenMatching(row:children(), TextField.matches), 2) end, tonumber)
    end, index)
end

function PropertyPanel.sliderProperty(labelKey, index)
    return rowProp(labelKey, function(row)
        row.value = TextField.new(row, function() return childFromLeft(row:children(), 3) end, tonumber)
    end, index)
end

function PropertyPanel.menuProperty(labelKey, index)
    return rowProp(labelKey, function(row)
        row.value = PopUpButton.new(row, function() return childFromRight(row:children(), 2) end)
    end, index)
end

function PropertyPanel.checkBoxProperty(labelKey, index)
    return rowProp(labelKey, function(row)
        row.value = CheckBox.new(row, function() return childFromLeft(childMatching(row:children(), CheckBox.matches), 1) end)
    end, index)
end

function PropertyPanel.mt:parent()
    return self._parent
end

function PropertyPanel.mt:app()
    return self:parent():app()
end

function PropertyPanel.mt:show()
    self:parent():show()
    return self
end

function PropertyPanel.mt:hide()
    local parent = self:parent()
    if parent.hide then
        parent:hide()
    end
    return self
end

--- cp.ui.PropertyPanel:row(labelKey, index) -> cp.ui.PropertyRow
--- Method
--- Returns a `PropertyRow` for a row with the specified label key.
---
--- Parameters:
--- * labelKey  - The key for the label (see FCP App `keysWithString` method).
---
--- Returns:
--- * The `PropertyRow`.
function PropertyPanel.mt:row(labelKey, index)
    local key = labelKey
    if index ~= nil and index > 1 then
        key = labelKey .. "_" .. tostring(index)
    end

    local row = self._rows[key]

    if not row then
        row = PropertyRow.new(self, labelKey, "UI", index)
        self._rows[key] = row
    end

    return row
end

function PropertyPanel.mt:panel()
    return self
end

--- cp.ui.PropertyPanel:bind(rowProps) -> self
--- Method
--- Adds the table of row properties to the panel.
---
--- Parameters:
--- * rowProps  - The table of `cp.props` to add.
function PropertyPanel.mt:bind(rowProps)
    prop.bind(self)(rowProps)
    return self
end

function PropertyPanel.mt:__call(rowProps)
    return self:bind(rowProps)
end


return PropertyPanel