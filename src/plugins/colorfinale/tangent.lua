-- This plugin basically just disables CP's Tangent Manager when ColorFinale is running.
local log                   = require("hs.logger").new("cf_tangent")

local application           = require("hs.application")
local timer                  = require("hs.timer")

local fcp                   = require("cp.apple.finalcutpro")
local windowfilter          = require("cp.apple.finalcutpro.windowfilter")
local prop                  = require("cp.prop")

local mod ={}

local APP_BUNDLE_ID = "com.colorfinale.LUTManager"
local WINDOW_TITLE = "Color Finale"

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

function mod.init(tangentManager)
    mod._tangentManager = tangentManager

    -- watch for FCP opening or closing
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

    -- add an interruption to Tangent Manager
    mod._tangentManager.interruptWhen(mod.colorFinaleActive)

    return mod
end

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

mod.colorFinaleInstalled = prop(function()
    local info = application.infoForBundleID(APP_BUNDLE_ID)
    return info ~= nil
end)

mod.colorFinaleActive = mod.colorFinaleInstalled:AND(mod.colorFinaleWindow)

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