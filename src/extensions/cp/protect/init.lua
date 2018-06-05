--- === cp.protect ===
---
--- Utility function for protecting a table from being modified.

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local function protect(tbl)
    return setmetatable({}, {
        __index			= tbl,
        __newindex		= function(_, key, value)
            error(string.format("unable to modify read-only value for '%s' to %s", key, value), 2)
        end,
        __len			= function() return #tbl end,
    })
end

return protect