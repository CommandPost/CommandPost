--- === plugins.finalcutpro.menu.proxyicon ===
---
--- Final Cut Pro Proxy Icon Plugin.

local require = require

local config            = require("cp.config")
local fcp               = require("cp.apple.finalcutpro")
local i18n              = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.menu.proxyicon.usingProxies -> <cp.prop: boolean>
--- Field
--- Using Proxies?
mod.usingProxies = fcp:viewer().usingProxies

--- plugins.finalcutpro.menu.proxyicon.generateProxyTitle() -> string
--- Function
--- Generates the Proxy Title
---
--- Parameters:
---  * None
---
--- Returns:
---  * String containing the Proxy Title
function mod.generateProxyTitle()
    if mod.enabled() then
        return mod.usingProxies() and " " .. "🔴" or " " .. "🔵"
    end
    return ""
end

--- plugins.finalcutpro.menu.proxyicon.procyMenuIconEnabled <cp.prop: boolean>
--- Constant
--- Toggles the Enable Proxy Menu Icon
mod.enabled = config.prop("enableProxyMenuIcon", false)

--- plugins.finalcutpro.menu.proxyicon.init(menuManager) -> none
--- Function
--- Initalise the module.
---
--- Parameters:
---  * menuManager - The menu manager plugin
---
--- Returns:
---  * None
function mod.init(menuManager)
    --------------------------------------------------------------------------------
    -- Add Title Suffix Function:
    --------------------------------------------------------------------------------
    menuManager.addTitleSuffix(mod.generateProxyTitle)

    local function updateMenubarIcon()
        menuManager:updateMenubarIcon()
    end

    mod.enabled:watch(function(enabled)
        if enabled then
            mod.usingProxies:watch(updateMenubarIcon, true)
        else
            mod.usingProxies:unwatch(updateMenubarIcon)
        end
    end, true)

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.menu.proxyicon",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.preferences.manager"]     = "prefs",
        ["core.menu.manager"]               = "menuManager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Initalise the module:
    --------------------------------------------------------------------------------
    mod.init(deps.menuManager)

    --------------------------------------------------------------------------------
    -- Setup Menubar Preferences Panel:
    --------------------------------------------------------------------------------
    local panel = deps.prefs.panel
    if panel then
        panel
            :addHeading(30, i18n("menubarHeading"))
            :addCheckbox(31,
                {
                    label = i18n("displayProxyOriginalIcon"),
                    onchange = function(_, params) mod.enabled(params.checked) end,
                    checked = mod.enabled,
                }
            )
    end

    return mod
end

return plugin
