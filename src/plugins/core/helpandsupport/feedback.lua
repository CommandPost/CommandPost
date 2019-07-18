--- === plugins.core.helpandsupport.feedback ===
---
--- Feedback Menu Item.

local require = require

local feedback  = require("cp.feedback")
local i18n      = require("cp.i18n")

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

local plugin = {
    id              = "core.helpandsupport.feedback",
    group           = "core",
    dependencies    = {
        ["core.menu.manager"] = "menuManager",
        ["core.commands.global"] = "global",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Commands:
    --------------------------------------------------------------------------------
    deps.global
        :add("cpFeedback")
        :whenActivated(mod.show)
        :groupedBy("helpandsupport")

    --------------------------------------------------------------------------------
    -- Menubar:
    --------------------------------------------------------------------------------
    deps.menuManager.bottom
        :addItem(9999998, function() return { title = i18n("provideFeedbackOrReportBug"),  fn = mod.show } end)

    return mod
end

return plugin
