local axutils	            = require "cp.ui.axutils"
local Clip	                = require "cp.apple.finalcutpro.content.Clip"

local FilmClip = Clip:subclass("cp.apple.finalcutpro.content.FilmClip")

function FilmClip.static.matches(element)
    return Clip.matches(element) and element:attributeValue("AXRole") == "AXGroup"
end

--- cp.apple.finalcutpro.content.Clip.title <cp.prop: string; read-only>
--- Field
--- The title of the clip. Must be overridden by subclasses.
function FilmClip.lazy.prop:title()
    return axutils.prop(self.UI, "AXDescription")
end

return FilmClip