--- === plugins.core.helpandsupport.donate ===
---
--- Donate Menu Item.

local require = require

local i18n = require("cp.i18n")


local plugin = {
    id              = "core.helpandsupport.donate",
    group           = "core",
    dependencies    = {
        ["core.menu.manager"]    = "menu",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Menubar:
    --------------------------------------------------------------------------------
    deps.menu.bottom
        :addItem(9999998, function()
            return { title = i18n("donateToDevelopers"), fn = function()
                os.execute('open "https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=HQK87KLKY8EVN"')
            end }
        end)
        :addSeparator(9999998.1)
end

return plugin
