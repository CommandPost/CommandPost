--- === plugins.core.preferences.updates ===
---
--- Updates Module.

local require = require
local hs = hs

local i18n = require "cp.i18n"

local mod = {}

--- plugins.core.preferences.updates.toggleCheckForUpdates() -> nil
--- Function
--- Toggles 'Check For Updates'
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.toggleCheckForUpdates()
    local automaticallyCheckForUpdates = hs.automaticallyCheckForUpdates()
    hs.automaticallyCheckForUpdates(not automaticallyCheckForUpdates)
    mod.automaticallyCheckForUpdates = not automaticallyCheckForUpdates
    if not automaticallyCheckForUpdates then
        hs.checkForUpdates(true)
    end
end

--- plugins.core.preferences.updates.checkForUpdates() -> boolean
--- Function
--- Returns the 'Check for Updates' status
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` or `false`
function mod.checkForUpdates()
    hs.focus()
    hs.checkForUpdates()
end


local plugin = {
    id              = "core.preferences.updates",
    group           = "core",
    dependencies    = {
        ["core.menu.manager"]               = "menu",
        ["core.preferences.panels.general"] = "general",
    }
}

function plugin.init(deps)

    mod.automaticallyCheckForUpdates = hs.automaticallyCheckForUpdates()

    if hs.automaticallyCheckForUpdates() then
        hs.checkForUpdates(true)
    end

    deps.menu.top:addItem(0.00000000000000000000000000001, function()
        if hs.updateAvailable() and hs.automaticallyCheckForUpdates() then
            local version, build = hs.updateAvailable()
            return { title = i18n("updateAvailable") .. ": " .. version .. " (" .. build .. ")",    fn = mod.checkForUpdates }
        end
    end)
    :addSeparator(2)

    deps.general:addCheckbox(4,
        {
            label = i18n("automaticallyCheckForUpdates"),
            onchange = mod.toggleCheckForUpdates,
            checked = hs.automaticallyCheckForUpdates,
            disabled = function() return not hs.canCheckForUpdates() end,
        }
    )

    deps.general:addButton(5,
        {
            label   = i18n("checkForUpdatesNow"),
            width       = 200,
            onclick = function() hs.checkForUpdates() end,
        }
    )


end

return plugin
