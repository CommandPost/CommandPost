--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.ui.PropertyRow ===
---
--- Represents a single property row, typically in a Property Inspector.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log						= require("hs.logger").new("PropertyRow")
local inspect                   = require("hs.inspect")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local geometry					= require("hs.geometry")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local is                        = require("cp.is")
local axutils					= require("cp.ui.axutils")
local Button					= require("cp.ui.Button")
local prop						= require("cp.prop")

local format                    = string.format
local childMatching, childrenMatching           = axutils.childMatching, axutils.childrenMatching

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local PropertyRow = {}

local UI_FINDER = {}
local UI_FINDER_LABEL = "PropertyRow UI Finder"

function PropertyRow.findProperties(parent)
    local finder = parent[UI_FINDER]
    if finder then
        return finder(parent)
    else
        error(format("Unable to find properties with this parent: %s", inspect(parent)))
    end
end

--- cp.ui.PropertyRow.prepParent(parent, uiFinder) -> boolean
--- Function
--- Call this to make `parent` table ready to be a parent of `PropertyRow`s.
--- Essentially, this lets `PropertyRow` instances ask the parent for the
--- `hs._asm.axuielement` that contains the property row details.
---
--- Parameters:
--- * parent    - The parent table.
--- * uiFinder  - The function or cp.prop which will be called to find the parent UI element. Functions will be passed the `parent` when being executed.
---
--- Returns:
---
function PropertyRow.prepParent(parent, uiFinder)
    if is.nt.callable(uiFinder) then
        error(format("The `finder` must be callable: %s", type(uiFinder)))
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
--- Checks if the `parent` has been prepared via [prepParent](#prepParent).
---
--- Parameters:
--- * None
---
--- Returns:
--- * `true` if the parent is prepared.
function PropertyRow.isParent(parent)
    return parent[UI_FINDER] ~= nil
end

--- cp.ui.PropertyRow.matches(element) -> boolean
--- Function
--- Checks if the provided `axuielement` could be a property row.
--- Note: this does not guarantee that it *is* a property row element, just that it could be.
---
--- Parameters:
--- * element   - The element to check.
---
--- Returns:
--- * `true` if the element could be a property row.
function PropertyRow.matches(element)
    return element ~= nil
end

--- cp.ui.PropertyRow.new(parent, labelKey[, propertiesUI[, index]]) -> cp.ui.PropertyRow
--- Constructor
--- Creates a new `PropertyRow` with the specified parent and label key.
---
--- If you have more than one row with the same label, specify the `index` - specifying `2` will
--- match with the second instance, for example.
---
--- Parameters:
--- * parent        - The parent object.
--- * labelKey      - The key of the label that the row will map to.
--- * index         - The row number with the same label to get. Defaults to `1`.
---
--- Returns:
--- * The new `PropertyRow` instance.
function PropertyRow.new(parent, labelKey, index)
    local o
    local propUI = propertiesUI or "UI"
    -- first, check if we're referring to a local property...
    if is.string(propUI) then
        propUI = parent[propertiesFn]
        if is.nt.callable(propUI) then
            error(format("Expected `parent.%s` to be callable but was %s", type(propUI)))
        end
    end
    -- if it's a function, wrap it into a cp.prop...
    if is.fn(propertiesFn) then
        local fn = propUI
        propUI = prop(function() return fn(parent) end)
    end

    if not prop.is(propUI) then
        error(format("The `propertiesUI` is not appropriate: %s", type(propertiesUI)))
    end

    index = index or 1

    o = prop.extend({
        _parent = parent,
        _labelKeys = is.string(labelKey) and {labelKey} or labelKey,
        _index = index,
        _children = nil,

--- cp.ui.PropertyRow.propertiesUI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- The `axuielement` from the parent that contains the properties.
        propertiesUI = propUI,
    }, PropertyRow)

    prop.bind(o) {
--- cp.ui.PropertyRow.labelUI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- The `axuielement` containing the row label.
        labelUI = propUI:mutate(function(original)
            return axutils.cache(o, "_labelUI", function()
                local ui = original()
                if ui then
                    local label = o:label()
                    return childMatching(ui, function(child)
                        return child:attributeValue("AXRole") == "AXStaticText"
                            and child:attributeValue("AXValue") == label
                    end, index)
                end
                return nil
            end)
        end),

--- cp.ui.PropertyRow.label <cp.prop: string; read-only>
--- Field
--- The label of the property row, in the current langauge.
        label = prop(function(self)
            local app = self:app()
            for _,key in ipairs(self._labelKeys) do
                local label = app:string(key, true)
                if label then
                    return label
                end
            end
            log.wf("Unabled to find a label with these keys: %s", index, inspect(self._labelKeys))
            return nil
        end):cached():monitor(parent:app().currentLanguage),
    }

--- cp.ui.PropertyRow.UI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- Returns the `axuielement` for the row.
    o.UI = o.labelUI

    prop.bind(o) {
--- cp.ui.PropertyRow.isShowing <cp.prop: boolean; read-only>
--- Field
--- Checks if the row is showing.
        isShowing = o.UI:mutate(function(original)
            return original() ~= nil
        end)
    }

--- cp.ui.PropertyRow.reset <cp.ui.Button>
--- Field
--- The `reset` button for the row, which may or may not actually exist.
--- It can be triggered by calling `row:reset()`.
    o.reset = Button.new(o, function()
        local children = o:children()
        if children then
            local last = children[#children]
            return Button.matches(last) and last or nil
        end
        return nil
    end)

    return o
end

-- PropertyRow methods --

-- TODO: Add documentation
function PropertyRow:parent()
    return self._parent
end

-- TODO: Add documentation
function PropertyRow:app()
    return self:parent():app()
end

-- TODO: Add documentation
function PropertyRow:show()
    self:parent():show()
    return self
end

function PropertyRow:hide()
    local parent = self:parent()
    if parent.hide then
        parent:hide()
    end
    return self
end

-- TODO: Add documentation
function PropertyRow:labelKeys()
    return self._labelKeys()
end

-- TODO: Add documentation
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
                local childFrame = child and child:frame()
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
    return self:label() or self._labelKeys()[1]
end

return PropertyRow
