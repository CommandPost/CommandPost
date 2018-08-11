--- === plugins.core.helpandsupport.errorlog ===
---
--- Error Log Menu Item.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local i18n                  = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.core.helpandsupport.errorlog.open() -> nil
--- Function
--- Opens the CommandPost Error Log,
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.open()
    hs.openConsole()
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "core.helpandsupport.errorlog",
    group           = "core",
    dependencies    = {
        ["core.menu.helpandsupport.commandpost"]    = "helpandsupport",
        ["core.commands.global"]                    = "global",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Commands:
    --------------------------------------------------------------------------------
    local global = deps.global
    if global then
        global:add("cpOpenErrorLog")
            :whenActivated(mod.open)
            :groupedBy("commandPost")
    end

    --------------------------------------------------------------------------------
    -- Menubar:
    --------------------------------------------------------------------------------
    local helpandsupport = deps.helpandsupport
    if helpandsupport then
        helpandsupport
            :addItem(1, function() return { title = i18n("openErrorLog"), fn = mod.open } end)
            :addSeparator(2)
    end

    return mod
end

return plugin
