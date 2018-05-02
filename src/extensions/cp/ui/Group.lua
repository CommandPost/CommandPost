local prop              = require("cp.prop")

local axutils           = require("cp.ui.axutils")

local Group = {}

function Group.matches(element)
    return element ~= nil and element:attributeValue("AXRole") == "AXGroup"
end

function Group.new(parent, finderFn)
    local o = prop.extend({
        _parent = parent,
        _finder = finderFn,
    }, Group)

    local UI = prop(function(self)
        return axutils.cache(self, "_ui", function()
            return self._finder()
        end, Group.matches)
    end)

    prop.bind(o) {
        UI = UI,

        isShowing = UI:ISNOT(nil),
    }

    return o
end

function Group:parent()
    return self._parent
end

function Group:app()
    return self:parent():app()
end

return Group