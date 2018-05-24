--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.font ===
---
--- Font Tools

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
--local log           = require("hs.logger").new("font")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config        = require("cp.config")
local tools         = require("cp.tools")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

-- cp.font.getFontFamilyFromFile(path) -> string | nil
-- Function
-- Gets the Font Family Name from a file.
--
-- Parameters:
--  * path - Path to a font file.
--
-- Returns:
--  * The Font Family Name as string or `nil`.
function mod.getFontFamilyFromFile(path)
    if path then
        local scriptPath = config.basePath .. "/extensions/cp/font/python/getFontFamilyName.py"
        local o, s, t, r = hs.execute("python " .. scriptPath .. [[ "]] .. path .. [["]])
        if o and s and t == "exit" and r == 0 then
            return tools.trim(o)
        end
    end
    return nil
end

return mod
