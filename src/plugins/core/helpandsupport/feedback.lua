--- === plugins.core.helpandsupport.feedback ===
---
--- Feedback Menu Item.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local feedback          = require("cp.feedback")
local i18n              = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.core.helpandsupport.feedback.show() -> nil
--- Function
--- Opens CommandPost Credits Window
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.show()
    feedback.showFeedback()
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "core.helpandsupport.feedback",
    group           = "core",
    dependencies    = {
        ["core.menu.helpandsupport.commandpost"]    = "helpandsupport",
        ["core.commands.global"]        = "global",
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
        global:add("cpFeedback")
            :whenActivated(mod.show)
            :groupedBy("helpandsupport")
    end

    --------------------------------------------------------------------------------
    -- Menubar:
    --------------------------------------------------------------------------------
    local helpandsupport = deps.helpandsupport
    if helpandsupport then
        deps.helpandsupport
            :addItem(3, function() return { title = i18n("provideFeedback") .. "...",  fn = mod.show } end)
            :addSeparator(4)
    end

    return mod
end

return plugin
