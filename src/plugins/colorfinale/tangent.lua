--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

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
local windowfilter          = require("cp.apple.finalcutpro.windowfilter")
local prop                  = require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod ={}

-- APP_BUNDLE_ID -> string
-- Constant
-- ColorFinale Bundle ID
local APP_BUNDLE_ID = "com.colorfinale.LUTManager"

-- WINDOW_TITLE -> string
-- Constant
-- ColorFinale Window Title
local WINDOW_TITLE = "Color Finale"

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
            mod.colorFinaleWindow:update()
        end
    end)

    local function updateWindow(w)
        if w and (w == mod._cfWindow or startsWith(w:title(), WINDOW_TITLE)) then
            mod.colorFinaleWindow:update()
            mod._cfWindow = w
        end
    end

    windowfilter:subscribe(
        {"windowVisible","windowNotVisible"},
        updateWindow, true
    )

    --------------------------------------------------------------------------------
    -- Add an interruption to Tangent Manager:
    --------------------------------------------------------------------------------
    mod._tangentManager.interruptWhen(mod.colorFinaleActive)

    return mod
end

--- plugins.colorfinale.tangent.colorFinaleWindow <cp.prop: boolean>
--- Variable
--- Checks to see if an object is a Color Finale window.
mod.colorFinaleWindow = prop(function()
    local windows = fcp:windowsUI()
    if windows then
        for _,w in ipairs(fcp:windowsUI()) do
            if startsWith(w:attributeValue("AXTitle"), WINDOW_TITLE) then
                return true
            end
        end
    end
    return false
end)

--- plugins.colorfinale.tangent.colorFinaleInstalled <cp.prop: boolean>
--- Variable
--- Checks to see if ColorFinale is installed.
mod.colorFinaleInstalled = prop(function()
    local info = application.infoForBundleID(APP_BUNDLE_ID)
    return info ~= nil
end)

--- plugins.colorfinale.tangent.colorFinaleActive <cp.prop: boolean>
--- Variable
--- Checks to see if ColorFinale is active.
mod.colorFinaleActive = mod.colorFinaleInstalled:AND(mod.colorFinaleWindow)

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