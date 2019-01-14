--- === plugins.core.helpandsupport.feedback ===
---
--- Feedback Menu Item.

local require = require

local feedback  = require("cp.feedback")
local i18n      = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
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
    -- Show Feedback Form:
    --------------------------------------------------------------------------------
    local show = function()
        feedback.showFeedback()
    end

    --------------------------------------------------------------------------------
    -- Commands:
    --------------------------------------------------------------------------------
    deps.global
        :add("cpFeedback")
        :whenActivated(show)
        :groupedBy("helpandsupport")

    --------------------------------------------------------------------------------
    -- Menubar:
    --------------------------------------------------------------------------------
    deps.menuManager.commandPostHelpAndSupport
        :addItem(3, function() return { title = i18n("provideFeedback") .. "...",  fn = show } end)
        :addSeparator(4)
end

return plugin
