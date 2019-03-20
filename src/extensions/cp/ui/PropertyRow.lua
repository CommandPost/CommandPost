--- === cp.ui.PropertyRow ===
---
--- Represents a single property row, typically in a Property Inspector.

local require = require

local log						    = require("hs.logger").new("PropertyRow")

local inspect           = require("hs.inspect")
local geometry					= require("hs.geometry")

local axutils					  = require("cp.ui.axutils")
local Button					  = require("cp.ui.Button")
local is                = require("cp.is")
local prop						  = require("cp.prop")

local Element           = require("cp.ui.Element")

local format            = string.format
local childMatching     = axutils.childMatching
local childrenMatching  = axutils.childrenMatching

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local PropertyRow = Element:subclass("PropertyRow")

-- UI_FINDER -> table
-- Constant
-- UI Finder Table.
local UI_FINDER = {}

-- UI_FINDER_LABEL -> string
-- Constant
-- UI Finder Label.
local UI_FINDER_LABEL = "PropertyRow UI Finder"

--- cp.ui.PropertyRow.parentUIFinder(parent) -> cp.prop
--- Function
--- Returns the `cp.prop` which finds the `hs._asm.axuielement` that contains property rows from the parent.
--- This needs to be configured first by calling the `prepareParent` function with the `parent` and finder function.
---
--- Parameters:
---  * parent        - The parent which has a finder assigned.
---
--- Returns:
---  * The `cp.prop` which provides access to the finder, or `nil`.
function PropertyRow.static.parentUIFinder(parent)
    return parent[UI_FINDER]
end

--- cp.ui.PropertyRow.prepareParent(parent, uiFinder) -> none
--- Function
--- Call this to make `parent` table ready to be a parent of `PropertyRow`s.
--- Essentially, this lets `PropertyRow` instances ask the parent for the
--- `hs._asm.axuielement` that contains the property row details.
---
--- Parameters:
---  * parent    - The parent table.
---  * uiFinder  - The function or cp.prop which will be called to find the parent UI element. Functions will be passed the `parent` when being executed.
---
--- Returns:
---  * None
function PropertyRow.static.prepareParent(parent, uiFinder)
    if is.nt.callable(uiFinder) then
        error(format("The `finder` must be callable: %s", type(uiFinder)))
    end
    if parent[UI_FINDER] ~= nil then
        error("The UI Finder has already been set on this parent.")
    end

    if prop.is(uiFinder) then
        uiFinder = uiFinder:wrap(parent)
    else
        uiFinder = prop(uiFinder):bind(parent)
    end

    uiFinder:label(UI_FINDER_LABEL)

    parent[UI_FINDER] = uiFinder
end

--- cp.ui.PropertyRow.isParent(parent) -> boolean
--- Function
--- Checks if the `parent` has been prepared via [prepareParent](#prepareParent).
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if the parent is prepared.
function PropertyRow.static.isParent(parent)
    return parent[UI_FINDER] ~= nil
end

--- cp.ui.PropertyRow.matches(element) -> boolean
--- Function
--- Checks if the provided `axuielement` could be a property row.
--- Note: this does not guarantee that it *is* a property row element, just that it could be.
---
--- Parameters:
---  * element   - The element to check.
---
--- Returns:
---  * `true` if the element could be a property row.
function PropertyRow.static.matches(element)
    return element ~= nil
end

--- cp.ui.PropertyRow(parent, labelKey[, index]) -> cp.ui.PropertyRow
--- Constructor
--- Creates a new `PropertyRow` with the specified parent and label key.
---
--- If you have more than one row with the same label, specify the `index` - specifying `2` will
--- match with the second instance, for example.
---
--- Parameters:
---  * parent        - The parent object.
---  * labelKey      - The key of the label that the row will map to.
---  * index         - The row number with the same label to get. Defaults to `1`.
---
--- Returns:
---  * The new `PropertyRow` instance.
function PropertyRow:initialize(parent, labelKey, index)
    local uiFinder = PropertyRow.parentUIFinder(parent)
    if not uiFinder then
        error(format("The `parent` has not been prepared with `PropertyRow.prepareParent(...)`: %s", parent))
    end

--- cp.ui.PropertyRow.labelUI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- Returns the `axuielement` for the label UI.
    local labelUI = uiFinder:mutate(function(original)
        return axutils.cache(self, "_labelUI", function()
            local ui = original()
            if ui then
                local label = self:label()
                return childMatching(ui, function(child)
                    return child:attributeValue("AXRole") == "AXStaticText"
                        and child:attributeValue("AXValue") == label
                end, index)
            end
            return nil
        end)
    end)

--- cp.ui.PropertyRow.UI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- Returns the `axuielement` for the row.
    local UI = labelUI

    Element.initialize(self, parent, UI)

    prop.bind(self) {
        uiFinder = uiFinder,
        labelUI = labelUI,
    }

    -- keep an eye on the label as an indicator of when to update.
    uiFinder:monitor(self.label)

    self._labelKeys = is.string(labelKey) and {labelKey} or labelKey
    self._index = index or 1
end

--- cp.ui.PropertyRow:extend(extendFn) -> cp.ui.PropertyRow
--- Method
--- This method will call the provided function, passing it the current `PropertyRow`.
--- This can be used to add addtional tweaks to the row, such as adding custom Elements.
---
--- Parameters:
---  * extendFn     - A `function` that will be passed the current row.
---
--- Returns:
---  * The same `PropertyRow` instance.
function PropertyRow:extend(extendFn)
    assert(type(extendFn) == "function", "Please provide a function.")
    extendFn(self)
    return self
end

--- cp.ui.PropertyRow.propertiesUI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- The `axuielement` from the parent that contains the properties.
function PropertyRow.lazy.prop:propertiesUI()
    return self.uiFinder
end

--- cp.ui.PropertyRow.label <cp.prop: string; read-only>
--- Field
--- The label of the property row, in the current langauge.
function PropertyRow.lazy.prop:label()
    return prop(function()
        local app = self:app()
        for _,key in ipairs(self._labelKeys) do
            local label = app:string(key, true)
            if label then
                return label
            end
        end
        log.wf("Unable to find a label with these keys: [%s]%s", self._index, inspect(self._labelKeys))
        return nil
    end):monitor(self:parent():app().currentLocale)
end

--- cp.ui.PropertyRow.reset <cp.ui.Button>
--- Field
--- The `reset` button for the row, which may or may not actually exist.
--- It can be triggered by calling `row:reset()`.
function PropertyRow.lazy.value:reset()
    return Button(self, function()
        local children = self:children()
        if children then
            local last = children[#children]
            return Button.matches(last) and last or nil
        end
        return nil
    end)
end

--- cp.ui.PropertyRow:parent() -> parent
--- Method
--- Returns the parent object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * parent
function PropertyRow:parent()
    return self._parent
end

--- cp.ui.PropertyRow:app() -> App
--- Method
--- Returns the app instance.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function PropertyRow:app()
    return self:parent():app()
end

--- cp.ui.PropertyRow:show() -> self
--- Method
--- Shows the `PropertyRow`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * self
function PropertyRow:show()
    self:parent():show()
    return self
end

--- cp.ui.PropertyRow:doShow() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that shows the `PropertyRow`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * self
function PropertyRow.lazy.method:doShow()
    return self:parent():doShow():Label("PropertyRow:doShow")
end

--- cp.ui.PropertyRow:hide() -> self
--- Method
--- Hides the `PropertyRow`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * self
function PropertyRow:hide()
    local parent = self:parent()
    if parent.hide then
        parent:hide()
    end
    return self
end

--- cp.ui.PropertyRow:doHide() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will attempt to hide the `PropertyRow`.
---
--- Returns:
--- * The `Statement`.
function PropertyRow.lazy.method:doHide()
    return self:parent():doHide():Label("PropertyRow:doHide")
end

--- cp.ui.PropertyRow:labelKeys() -> string
--- Method
--- Gets the key of the label that the row will map to.
---
--- Parameters:
---  * None
---
--- Returns:
---  * string
function PropertyRow:labelKeys()
    return self._labelKeys()
end

--- cp.ui.PropertyRow:children() -> table | nil
--- Method
--- Gets a table of children for the Property Row.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of children or `nil`.
function PropertyRow:children()
    local label = self:labelUI()
    if not label then
        return nil
    end

    local children = self._children
    -- check the children are still valid
    if children and #children > 0 and not axutils.isValid(children[1]) then
        children = nil
    end
    -- check if we have children cached
    if not children and label then
        local labelFrame = label:frame()
        labelFrame = labelFrame and geometry.new(label:frame()) or nil
        if labelFrame then
            children = childrenMatching(self:propertiesUI(), function(child)
                -- match the children who are right of the label element (and not the AXScrollBar)
                local childFrame = child and child:attributeValue("AXFrame")
                return childFrame ~= nil and labelFrame:intersect(childFrame).h > 0 and child:attributeValue("AXRole") ~= "AXScrollBar"
            end)
            if children then
                table.sort(children, axutils.compareLeftToRight)
            end
            self._children = children
        end
    end
    return children
end

function PropertyRow:__tostring()
    return self:label() or (self._labelKeys and type(self._labelKeys) == "function" and self._labelKeys() and self._labelKeys()[1]) or "Unnamed Property Row"
end

return PropertyRow
