--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.inspector.audio.AudioInspector ===
---
--- Audio Inspector Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
--local log                               = require("hs.logger").new("audioInspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local prop                              = require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local AudioInspector = {}

--- cp.apple.finalcutpro.inspector.audio.AudioInspector:new(parent) -> AudioInspector object
--- Method
--- Creates a new AudioInspector object
---
--- Parameters:
---  * `parent`     - The parent
---
--- Returns:
---  * A AudioInspector object
-- TODO: Replace Method with Function.
function AudioInspector:new(parent) -- luacheck: ignore
    local o = {
        _parent = parent,
        _child = {}
    }
    return prop.extend(o, AudioInspector)
end

--- cp.apple.finalcutpro.inspector.audio.AudioInspector:parent() -> table
--- Method
--- Returns the AudioInspector's parent table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function AudioInspector:parent()
    return self._parent
end

--- cp.apple.finalcutpro.inspector.audio.AudioInspector:app() -> table
--- Method
--- Returns the `cp.apple.finalcutpro` app table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application object as a table
function AudioInspector:app()
    return self:parent():app()
end

--------------------------------------------------------------------------------
--
-- AUDIO INSPECTOR:
--
--------------------------------------------------------------------------------

return AudioInspector
