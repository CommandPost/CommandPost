--- === plugins.core.helpandsupport.donate ===
---
--- Donate Menu Item.

local require = require

local i18n = require "cp.i18n"

local plugin = {
    id              = "core.helpandsupport.donate",
    group           = "core",
    dependencies    = {
        ["core.menu.manager"] = "menu",
    }
}

function plugin.init(deps)
    deps.menu.bottom
        :addItem(9999998.1, function()
            return {
                title = i18n("sponsorCommandPost"),
                fn = function() os.execute('open "https://commandpost.io/#sponsor"') end,
            }
        end)
        :addSeparator(9999998.2)
end

return plugin