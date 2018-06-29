--- === plugins.finalcutpro.menu.proxyicon ===
---
--- Final Cut Pro Proxy Icon Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

-- local log               = require("hs.logger").new("proxyicon")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config            = require("cp.config")
local fcp               = require("cp.apple.finalcutpro")
local i18n              = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

-- PROXY_ICON -> string
-- Constant
-- Proxy Icon
mod.PROXY_ICON = "🔴"

-- ORIGINAL_ICON -> string
-- Constant
-- Original Icon
mod.ORIGINAL_ICON = "🔵"

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
        return mod.usingProxies() and " " .. mod.PROXY_ICON or " " .. mod.ORIGINAL_ICON
    end
    return ""
end


--- plugins.finalcutpro.menu.proxyicon.procyMenuIconEnabled <cp.prop: boolean>
--- Constant
--- Toggles the Enable Proxy Menu Icon
mod.enabled = config.prop("enableProxyMenuIcon", false)

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
        ["finalcutpro.preferences.app"]     = "prefs",
        ["core.menu.manager"]               = "menuManager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    mod.init(deps.menuManager)

    --------------------------------------------------------------------------------
    -- Setup Menubar Preferences Panel:
    --------------------------------------------------------------------------------
    if deps.prefs.panel then
        deps.prefs.panel:addHeading(30, i18n("menubarHeading"))

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
