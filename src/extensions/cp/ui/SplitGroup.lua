local prop              = require("cp.prop")

local axutils           = require("cp.ui.axutils")

local SplitGroup = {}

function SplitGroup.matches(element)
    return element ~= nil and element:attributeValue("AXRole") == "AXSplitGroup"
end

function SplitGroup.new(parent, finderFn)
    local o = prop.extend({
        _parent = parent,
        _finder = finderFn,
    }, SplitGroup)

    local UI = prop(function(self)
        return axutils.cache(self, "_ui", function()
            return self._finder()
        end, SplitGroup.matches)
    end)

    prop.bind(o) {
        UI = UI,

        isShowing = UI:ISNOT(nil),
    }

    return o
end

function SplitGroup:parent()
    return self._parent
end

function SplitGroup:app()
    return self:parent():app()
end

return SplitGroup