--- === plugins.core.helpandsupport.facebook ===
---
--- Facebook Group Menu Item.

local require = require

local i18n = require("cp.i18n")


local plugin = {
    id              = "core.helpandsupport.facebook",
    group           = "core",
    dependencies    = {
        ["core.menu.manager"] = "menuManager",
        ["core.commands.global"] = "global",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Open Facebook Group:
    --------------------------------------------------------------------------------
    local show = function()
        os.execute('open "https://www.facebook.com/groups/commandpost/"')
    end

    --------------------------------------------------------------------------------
    -- Commands:
    --------------------------------------------------------------------------------
    deps.global
        :add("cpFacebookGroup")
        :whenActivated(show)
        :groupedBy("helpandsupport")

    --------------------------------------------------------------------------------
    -- Menubar:
    --------------------------------------------------------------------------------
    deps.menuManager.commandPostHelpAndSupport
        :addItem(8, function() return { title = i18n("cpFacebookGroup_title"), fn = show } end)
        :addSeparator(9)

end

return plugin
