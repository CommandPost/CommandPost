--- === cp.apple.finalcutpro.content.Clip ===
---
--- Represents a clip of media inside FCP.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local require           = require
local class	            = require "middleclass"
local lazy              = require "cp.lazy"
local prop	            = require "cp.prop"
local Element           = require "cp.ui.Element"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------

local Clip = class("cp.apple.finalcutpro.content.Clip"):include(lazy)

function Clip.static.matches(element)
    return Element.matches(element)
end

--- cp.apple.finalcutpro.content.Clip(element[, options]) -> Clip
--- Constructor
--- Creates a new `Clip` pointing at the specified element, with the specified options.
---
--- Parameters:
---  * `element`        - The [Element](cp.ui.Element.md) the clip represents.
---  * `options`        - A table containing the options for the clip.
---
--- Returns:
---  * The new `Clip`.
---
--- Notes:
---  * The options may be:
---  ** `columnIndex`   - A number which will be used to specify the column number to find the title in, if relevant.
function Clip:initialize(element, options)
    self._element = element
    self._options = options or {}
end

--- cp.apple.finalcutpro.content.Clip.UI <cp.prop: axuielement; read-only; live?>
--- Field
--- The `axuielement` for the clip.
function Clip.lazy.prop:UI()
    return prop.THIS(self._element.UI)
end


--- cp.apple.finalcutpro.content.Clip.title <cp.prop: string; read-only>
--- Field
--- The title of the clip. Must be overridden by subclasses.
function Clip.lazy.prop.title()
    error "Subclasses must implement `title`."
end

return Clip
