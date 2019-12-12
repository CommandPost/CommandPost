--- === plugins.colorfinale.tangent ===
---
--- This plugin basically just disables CP's Tangent Manager when ColorFinale is running.

local require           = require

--local log               = require "hs.logger".new "ColorFinale"

local application       = require "hs.application"

local fcp               = require "cp.apple.finalcutpro"
local prop              = require "cp.prop"
local tools             = require "cp.tools"

local infoForBundleID   = application.infoForBundleID
local startsWith        = tools.startsWith

local mod = {}

-- APP_BUNDLE_ID -> string
-- Constant
-- ColorFinale Bundle ID
local APP_BUNDLE_IDS = {
    "com.colorfinale.LUTManager",   -- Color Finale
    "com.colorfinale.app",          -- Color Finale 2
}

-- WINDOW_TITLE -> string
-- Constant
-- ColorFinale Window Title
local WINDOW_TITLE = "Color Finale"

--- plugins.colorfinale.tangent.init(tangentManager) -> module
--- Function
--- Initialise the module.
---
--- Parameters:
---  * tangentManager - The Tangent Manager
---
--- Returns:
---  * The ColorFinale Tangent Module.
function mod.init(tangentManager)
    mod._tangentManager = tangentManager

    --------------------------------------------------------------------------------
    -- Watch for FCP opening or closing:
    --------------------------------------------------------------------------------
    fcp.isFrontmost:watch(function()
        if mod.colorFinaleInstalled() then
            mod.colorFinaleWindowUI:update()
        end
    end)

    --------------------------------------------------------------------------------
    -- Add an interruption to Tangent Manager:
    --------------------------------------------------------------------------------
    mod._tangentManager.interruptWhen(mod.colorFinaleActive)

    return mod
end

local colorFinaleWindowUI = fcp.windowsUI:mutate(function(original)
    local windows = original()
    if windows then
        for _,w in ipairs(fcp:windowsUI()) do
            if startsWith(w:attributeValue("AXTitle"), WINDOW_TITLE) then
                return w
            end
        end
    end
    return nil
end)

prop.bind(mod) {
--- plugins.colorfinale.tangent.colorFinaleWindowUI <cp.prop: hs._asm.axuielement; read-only>
--- Variable
--- Returns the `axuielement` for the ColorFinale window, if present.
    colorFinaleWindowUI = colorFinaleWindowUI,

--- plugins.colorfinale.tangent.colorFinaleVisible <cp.prop: boolean; read-only; live>
--- Variable
--- Checks to see if an object is a Color Finale window.
    colorFinaleVisible = colorFinaleWindowUI:mutate(function(original)
        local window = original()
        return window ~= nil and startsWith(window:attributeValue("AXTitle"), WINDOW_TITLE)
    end),

--- plugins.colorfinale.tangent.colorFinaleInstalled <cp.prop: boolean; read-only; cached>
--- Variable
--- Checks to see if ColorFinale is installed. This prop is cached to improve performance.
    colorFinaleInstalled = prop(function()
        for _, id in ipairs(APP_BUNDLE_IDS) do
            local info = infoForBundleID(id)
            if info then
                return true
            end
        end
        return false
    end):cached(),
}

prop.bind(mod) {
--- plugins.colorfinale.tangent.colorFinaleActive <cp.prop: boolean; read-only; live>
--- Variable
--- Checks to see if ColorFinale is active.
    colorFinaleActive = mod.colorFinaleInstalled:AND(mod.colorFinaleVisible),
}

local plugin = {
    id = "colorfinale.tangent",
    group = "colorfinale",
    dependencies = {
        ["core.tangent.manager"] = "tangentManager",
    }
}

function plugin.init(deps)
    return mod.init(deps.tangentManager)
end

return plugin
