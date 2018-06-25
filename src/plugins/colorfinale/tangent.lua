--- === plugins.colorfinale.tangent ===
---
--- This plugin basically just disables CP's Tangent Manager when ColorFinale is running.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
--local log                   = require("hs.logger").new("cf_tangent")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local application           = require("hs.application")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local fcp                   = require("cp.apple.finalcutpro")
local prop                  = require("cp.prop")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- APP_BUNDLE_ID -> string
-- Constant
-- ColorFinale Bundle ID
local APP_BUNDLE_ID = "com.colorfinale.LUTManager"

-- WINDOW_TITLE -> string
-- Constant
-- ColorFinale Window Title
local WINDOW_TITLE = "Color Finale"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod ={}

-- startsWith(value, startValue) -> boolean
-- Function
-- Checks to see if a string starts with a value.
--
-- Parameters:
--  * value - The value to check
--  * startValue - The value to look for
--
-- Returns:
--  * `true` if value starts with the startValue, otherwise `false`
local function startsWith(value, startValue)
    if value and startValue then
        local len = startValue:len()
        if value:len() >= len then
            local sub = value:sub(1, len)
            return sub == startValue
        end
    end
    return false
end

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
        local windows = original()
        if windows then
            for _,w in ipairs(windows) do
                if startsWith(w:attributeValue("AXTitle"), WINDOW_TITLE) then
                    return true
                end
            end
        end
        return false
    end),

--- plugins.colorfinale.tangent.colorFinaleInstalled <cp.prop: boolean; read-only; live>
--- Variable
--- Checks to see if ColorFinale is installed.
    colorFinaleInstalled = prop(function()
        local info = application.infoForBundleID(APP_BUNDLE_ID)
        return info ~= nil
    end),
}

prop.bind(mod) {
--- plugins.colorfinale.tangent.colorFinaleActive <cp.prop: boolean; read-only; live>
--- Variable
--- Checks to see if ColorFinale is active.
    colorFinaleActive = mod.colorFinaleInstalled:AND(mod.colorFinaleVisible),
}

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "colorfinale.tangent",
    group = "colorfinale",
    dependencies = {
        ["core.tangent.manager"] = "tangentManager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    return mod.init(deps.tangentManager)
end

return plugin