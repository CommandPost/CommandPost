--- === plugins.finalcutpro.hud.panels.minimise ===
---
--- Minimise button for the Final Cut Pro HUD.

local require           = require

--local log               = require("hs.logger").new("info")

local image             = require("hs.image")

local fcp               = require("cp.apple.finalcutpro")
local tools             = require("cp.tools")


local plugin = {
    id              = "finalcutpro.hud.panels.minimise",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.hud.manager"]    = "manager",
    }
}

function plugin.init(deps, env)
    if fcp:isSupported() then

        local manager = deps.manager

        local calculateHeight = function()
            local toolbar = manager._toolbar
            local displayMode = toolbar and toolbar:displayMode()   --"default", "label", "icon", or "both".
            local sizeMode = toolbar and toolbar:sizeMode()         --"default", "regular", or "small".
            if displayMode == "icon" and sizeMode == "small" then
                return 53
            elseif displayMode == "icon" and sizeMode == "regular" then
                return 60
            elseif displayMode == "both" and sizeMode == "regular" then
                return 73
            elseif displayMode == "both" and sizeMode == "small" then
                return 63
            elseif displayMode == "label" and sizeMode == "regular" then
                return 38
            elseif displayMode == "label" and sizeMode == "small" then
                return 36
            else
                return 53
            end
        end

        --------------------------------------------------------------------------------
        -- Create new Panel:
        --------------------------------------------------------------------------------
        manager.addPanel({
            priority    = 1,
            id          = "minimise",
            label       = "Minimise",
            image       = image.imageFromPath(tools.iconFallback(env:pathToAbsolute("/images/minimise.png"))),
            tooltip     = "Minimise",
            height      = calculateHeight(),
            loadedFn    = function() manager.resize(calculateHeight()) end,
        })

    end
end

return plugin
