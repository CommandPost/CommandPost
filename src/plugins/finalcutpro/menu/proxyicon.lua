--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                    P R O X Y    I C O N    P L U G I N                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.menu.proxyicon ===
---
--- Final Cut Pro Proxy Icon Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config            = require("cp.config")
local fcp               = require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- ENABLED_DEFAULT -> boolean
-- Constant
-- Whether or not the Proxy Icon is enabled by default.
local ENABLED_DEFAULT = false

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

--- plugins.finalcutpro.menu.proxyicon.procyMenuIconEnabled <cp.prop: boolean>
--- Constant
--- Toggles the Enable Proxy Menu Icon
mod.enabled = config.prop("enableProxyMenuIcon", ENABLED_DEFAULT):watch(function(enabled)
    if enabled then
        --------------------------------------------------------------------------------
        -- Update Menubar Icon on Final Cut Pro Preferences Update:
        --------------------------------------------------------------------------------
        mod._fcpWatchID = fcp.app.preferences:watch(function()
            mod.menuManager:updateMenubarIcon()
        end)
    else
        --------------------------------------------------------------------------------
        -- Destroy Watchers:
        --------------------------------------------------------------------------------
        if mod._fcpWatchID and mod._fcpWatchID.id then
            fcp:unwatch(mod._fcpWatchID.id)
            mod._fcpWatchID = nil
        end
    end
    mod.menuManager:updateMenubarIcon()
end)

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
        local FFPlayerQuality = fcp:getPreference("FFPlayerQuality")
        if FFPlayerQuality == fcp.PLAYER_QUALITY.PROXY then
            return " " .. mod.PROXY_ICON
        else
            return " " .. mod.ORIGINAL_ICON
        end
    end
    return ""
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
        ["finalcutpro.preferences.app"] = "prefs",
        ["core.menu.manager"]                           = "menuManager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Add Title Suffix Function:
    --------------------------------------------------------------------------------
    mod.menuManager = deps.menuManager
    mod.menuManager.addTitleSuffix(mod.generateProxyTitle)

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
