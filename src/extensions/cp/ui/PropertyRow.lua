--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.ui.PropertyRow ===
---
--- Represents a list of property rows, typically in a Property Inspector.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log						= require("hs.logger").new("propertyRow")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local geometry					= require("hs.geometry")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils					= require("cp.ui.axutils")
local Button					= require("cp.ui.Button")
local prop						= require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local PropertyRow = {}

-- TODO: Add documentation
function PropertyRow.matches(element)
    return element ~= nil
end

-- TODO: Add documentation
-- TODO: Use a function instead of a method.
function PropertyRow:new(parent, labelKey, propertiesUI) -- luacheck: ignore
    local o = prop.extend({
        _parent = parent,
        _labelKeys = type(labelKey) == "string" and {labelKey} or labelKey,
        _propertiesUI = propertiesUI or "UI",
        _children = nil,
    }, PropertyRow)

    o.label = prop(function(Self)
        local app = Self:app()
        for _,key in ipairs(Self._labelKeys) do
            local label = app:string(key, true)
            if label then
                return label
            end
        end
        log.wf("Unabled to find a string for property row titles: %s", string.join(self._labelKeys, ", ")) -- luacheck: ignore
        return nil
    end):bind(o)

    return o
end

-- TODO: Add documentation
function PropertyRow:parent()
    return self._parent
end

-- TODO: Add documentation
function PropertyRow:app()
    return self:parent():app()
end

-- TODO: Add documentation
function PropertyRow:UI()
    return self:labelUI()
end

-- TODO: Add documentation
PropertyRow.isShowing = prop(function(self)
    return self:UI() ~= nil
end):bind(PropertyRow)

-- TODO: Add documentation
function PropertyRow:show()
    self:parent():show()
end

-- TODO: Add documentation
function PropertyRow:labelKeys()
    return self._labelKeys()
end

-- TODO: Add documentation
function PropertyRow:propertiesUI()
    local parent = self:parent()
    local propFn = parent[self._propertiesUI]
    return propFn and propFn(parent) or nil
end

-- TODO: Add documentation
function PropertyRow:labelUI()
    return axutils.cache(self, "_labelUI", function()
        local ui = self:propertiesUI()
        if ui then
            local label = self:label()
            return axutils.childMatching(ui, function(child)
                return child:attributeValue("AXRole") == "AXStaticText"
                    and child:attributeValue("AXValue") == label
            end)
        end
        return nil
    end)
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
            children = axutils.childrenMatching(self:propertiesUI(), function(child)
                -- match the children who are right of the label element (and not the AXScrollBar)
                local childFrame = child:frame()
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

-- TODO: Add documentation
function PropertyRow:resetButton()
    if not self._resetButton then
        self._resetButton = Button:new(self, function()
            local children = self:children()
            if children then
                local last = children[#children]
                return Button.matches(last) and last or nil
            end
            return nil
        end)
    end
    return self._resetButton
end

-- TODO: Add documentation
function PropertyRow:reset()
    self:resetButton():press()
    return self
end

return PropertyRow
