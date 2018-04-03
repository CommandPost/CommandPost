--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--              P R O T E C T     S U P P O R T     L I B R A R Y             --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Utility function for protecting a table from being modified.
--
-- Module created by David Peterson (https://github.com/randomeizer).
--
--------------------------------------------------------------------------------
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