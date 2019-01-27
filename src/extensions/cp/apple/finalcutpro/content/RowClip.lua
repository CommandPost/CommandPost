local prop	                = require "cp.prop"
local Clip	                = require "cp.apple.finalcutpro.content.Clip"
local Row                   = require "cp.ui.Row"

local RowClip = Clip:subclass("cp.apple.finalcutpro.content.RowClip")

function RowClip.static.matches(element)
    return Clip.matches(element) and Row.matches(element)
end

--- cp.apple.finalcutpro.content.Clip.title <cp.prop: string; read-only>
--- Field
--- The title of the clip.
function RowClip.lazy.prop:title()
    return prop(function()
        local colIndex = self._options.columnIndex
        local cell = self._element:cells()[colIndex]
        return cell:textValue()
    end)
end

return RowClip