--- === plugins.finalcutpro.hud.panels.info ===
---
--- Info Panel for the Final Cut Pro HUD.

local require           = require

--local log               = require "hs.logger".new "info"

local image             = require "hs.image"

local fcp               = require "cp.apple.finalcutpro"
local tools             = require "cp.tools"
local i18n              = require "cp.i18n"

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

--- plugins.finalcutpro.hud.panels.info.updateInfo() -> none
--- Function
--- Update the Info Panel HTML content.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.updateInfo()

    local viewer = fcp.viewer

    local mediaText, mediaClass
    local qualityText, qualityClass

    if viewer:usingProxies() then
        mediaText = i18n("proxy")
        mediaClass = "bad"
        qualityText = i18n("proxy")
        qualityClass = "bad"
    else
        mediaText = i18n("originalOptimised")
        mediaClass = "good"
        if viewer:betterQuality() then
            qualityText = i18n("betterQuality")
            qualityClass = "good"
        else
            qualityText = i18n("betterPerformance")
            qualityClass = "bad"
        end
    end

    local backgroundRender = fcp.preferences:prop("FFAutoStartBGRender", true)

    local backgroundRenderText, backgroundRenderClass

    if backgroundRender() then
        local autoRenderDelay = tonumber(fcp.preferences.FFAutoRenderDelay or "0.3")
        backgroundRenderText = string.format("%s (%s %s)", i18n("enabled"), tostring(autoRenderDelay), i18n("secs", {count=autoRenderDelay}))
        backgroundRenderClass = "good"
    else
        backgroundRenderText = i18n("disabled")
        backgroundRenderClass = "bad"
    end

    local script = [[
        changeInnerHTMLByID("backgroundRender", "]] .. backgroundRenderText .. [[");
        changeClassNameByID("backgroundRender", "]] .. backgroundRenderClass .. [[");
        changeInnerHTMLByID("media", "]] .. mediaText .. [[");
        changeClassNameByID("media", "]] .. mediaClass .. [[");
        changeInnerHTMLByID("quality", "]] .. qualityText .. [[");
        changeClassNameByID("quality", "]] .. qualityClass .. [[");
    ]]
    mod._manager.injectScript(script)

end

--- plugins.finalcutpro.hud.panels.info.updateWatchers(enabled) -> none
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
        fcp.app.preferences:prop("FFAutoStartBGRender"):watch(mod.updateInfo)
        fcp.app.preferences:prop("FFAutoRenderDelay"):watch(mod.updateInfo)
        fcp.app.preferences:prop("FFPlayerQuality"):watch(mod.updateInfo)
    else
        --------------------------------------------------------------------------------
        -- Destroy Watchers:
        --------------------------------------------------------------------------------
        fcp.app.preferences:prop("FFAutoStartBGRender"):unwatch(mod.updateInfo)
        fcp.app.preferences:prop("FFAutoRenderDelay"):unwatch(mod.updateInfo)
        fcp.app.preferences:prop("FFPlayerQuality"):unwatch(mod.updateInfo)
    end
end

local plugin = {
    id              = "finalcutpro.hud.panels.info",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.hud.manager"]    = "manager",
    }
}

function plugin.init(deps, env)
    if fcp:isSupported() then
        --------------------------------------------------------------------------------
        -- Create new Panel:
        --------------------------------------------------------------------------------
        mod._manager = deps.manager
        local panel = deps.manager.addPanel({
            priority    = 2,
            id          = "info",
            label       = i18n("info"),
            image       = image.imageFromPath(tools.iconFallback(env:pathToAbsolute("/images/info.png"))),
            tooltip     = i18n("info"),
            openFn      = function() mod.updateWatchers(true) end,
            closeFn     = function() mod.updateWatchers(false) end,
            loadedFn    = mod.updateInfo,
            height      = 130,
        })

        --------------------------------------------------------------------------------
        -- Generate HTML for Panel:
        --------------------------------------------------------------------------------
        local renderPanel = env:compileTemplate("html/panel.html")
        panel:addContent(1, function() return renderPanel(getEnv()) end, false)
    end
end

return plugin
