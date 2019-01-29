--- === plugins.finalcutpro.hud.panels.buttons ===
---
--- Button Panel for the Final Cut Pro HUD.

local require                   = require

local image                     = require("hs.image")

local fcp                       = require("cp.apple.finalcutpro")
local tools                     = require("cp.tools")
local i18n                      = require("cp.i18n")

local imageFromPath             = image.imageFromPath
local iconFallback              = tools.iconFallback

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

-- getEnv() -> table
-- Function
-- Set up the template environment.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function getEnv()
    local env = {}
    env.i18n = i18n
    return env
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.hud.panels.buttons",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.hud.manager"] = "manager",
    }
}

function plugin.init(deps, env)
    if fcp:isSupported() then
        local panel = deps.manager.addPanel({
            priority    = 2,
            id          = "buttons",
            label       = "Buttons",
            tooltip     = "Buttons",
            image       = imageFromPath(iconFallback("/System/Library/PreferencePanes/Keyboard.prefPane/Contents/Resources/Keyboard.icns")),
            height      = 220,
        })

        --------------------------------------------------------------------------------
        -- Generate HTML for Panel:
        --------------------------------------------------------------------------------
        local renderPanel = env:compileTemplate("html/panel.html")
        panel:addContent(1, function() return renderPanel(getEnv()) end, false)
    end
end

return plugin