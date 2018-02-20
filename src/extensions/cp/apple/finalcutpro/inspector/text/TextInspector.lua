--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.inspector.text.TextInspector ===
---
--- Text Inspector Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
--local log                             = require("hs.logger").new("textInspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local prop                              = require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local TextInspector = {}

--- cp.apple.finalcutpro.inspector.text.TextInspector:new(parent) -> TextInspector object
--- Method
--- Creates a new TextInspector object
---
--- Parameters:
---  * `parent`     - The parent
---
--- Returns:
---  * A TextInspector object
-- TODO: Use a function instead of a method.
function TextInspector:new(parent) -- luacheck: ignore
    local o = {
        _parent = parent,
        _child = {}
    }
    return prop.extend(o, TextInspector)
end

--- cp.apple.finalcutpro.inspector.text.TextInspector:parent() -> table
--- Method
--- Returns the TextInspector's parent table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function TextInspector:parent()
    return self._parent
end

--- cp.apple.finalcutpro.inspector.text.TextInspector:app() -> table
--- Method
--- Returns the `cp.apple.finalcutpro` app table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application object as a table
function TextInspector:app()
    return self:parent():app()
end

--------------------------------------------------------------------------------
--
-- TEXT INSPECTOR:
--
--------------------------------------------------------------------------------

return TextInspector