--- === plugins.finalcutpro.hud.panels.notes ===
---
--- Notes Panel for the Final Cut Pro HUD.

local require           = require

local log               = require("hs.logger").new("info")

local image             = require("hs.image")

local fcp               = require("cp.apple.finalcutpro")
local tools             = require("cp.tools")
local i18n              = require("cp.i18n")

local imageFromPath     = image.imageFromPath
local iconFallback      = tools.iconFallback

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

--- plugins.finalcutpro.hud.panels.notes.updateInfo() -> none
--- Function
--- Update the Info Panel HTML content.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.updateInfo()

end

--- plugins.finalcutpro.hud.panels.notes.updateWatchers(enabled) -> none
--- Function
--- Sets up or destroys the Info Panel watchers.
---
--- Parameters:
---  * enabled - `true` to setup, `false` to destroy
---
--- Returns:
---  * None
function mod.updateWatchers(enabled)
    if enabled then
        --------------------------------------------------------------------------------
        -- Setup Watchers:
        --------------------------------------------------------------------------------
    else
        --------------------------------------------------------------------------------
        -- Destroy Watchers:
        --------------------------------------------------------------------------------
    end
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.hud.panels.notes",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.hud.manager"] = "manager",
    }
}

function plugin.init(deps, env)
    if fcp:isSupported() then
        --------------------------------------------------------------------------------
        -- Create new Panel:
        --------------------------------------------------------------------------------
        mod._manager = deps.manager
        local panel = deps.manager.addPanel({
            priority    = 3,
            id          = "notes",
            label       = "Notes Panel",
            image       = imageFromPath(iconFallback("/Applications/Notes.app/Contents/Resources/AppIcon.icns")),
            tooltip     = "Notes Panel",
            openFn      = function() mod.updateWatchers(true) end,
            closeFn     = function() mod.updateWatchers(false) end,
            loadedFn    = mod.updateInfo,
            height      = 300,
        })

        --------------------------------------------------------------------------------
        -- Generate HTML for Panel:
        --------------------------------------------------------------------------------
        local renderPanel = env:compileTemplate("html/panel.html")
        panel:addContent(1, function() return renderPanel(getEnv()) end, false)
    end
end

return plugin
