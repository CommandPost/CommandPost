--- === plugins.finalcutpro.hud.panels.fcpxml ===
---
--- FCPXML Panel for the Final Cut Pro HUD.

local require           = require

--local log               = require("hs.logger").new("fcpxmlHud")

local base64            = require("hs.base64")
local dialog            = require("hs.dialog")
local image             = require("hs.image")

local config            = require("cp.config")
local fcp               = require("cp.apple.finalcutpro")
local i18n              = require("cp.i18n")
local json              = require("cp.json")
local tools             = require("cp.tools")

local encode            = base64.encode
local webviewAlert      = dialog.webviewAlert


local mod = {}

--- plugins.finalcutpro.hud.panels.fcpxml.lastValue <cp.prop: table>
--- Field
--- Last value in FCPXML HUD.
mod.lastValue = json.prop(config.userConfigRootPath, "HUD", "FCPXML.cpHUD", {})

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

-- updateInfo() -> none
-- Function
-- Update the Info Panel HTML content.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function updateInfo()
    local lastValue = mod.lastValue()
    local value = lastValue and lastValue.lastValue
    if value then
        mod._manager.injectScript([[setCode("]] .. encode(value) .. [[");]])
    end
end


local plugin = {
    id              = "finalcutpro.hud.panels.fcpxml",
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
            priority    = 7,
            id          = "fcpxml",
            label       = i18n("fcpxmlEditor"),
            image       = image.imageFromPath(tools.iconFallback(env:pathToAbsolute("/images/fcpxml.png"))),
            tooltip     = i18n("fcpxmlEditor"),
            loadedFn    = updateInfo,
            height      = 600,
        })

        --------------------------------------------------------------------------------
        -- Generate HTML for Panel:
        --------------------------------------------------------------------------------
        local renderPanel = env:compileTemplate("html/panel.html")
        panel:addContent(1, function() return renderPanel(getEnv()) end, false)

        --------------------------------------------------------------------------------
        -- Setup Controller Callback:
        --------------------------------------------------------------------------------
        local controllerCallback = function(_, params)
            if params["type"] == "dropbox" then
                local value = params["value"]
                if value then
                    if string.find(value, "<!DOCTYPE fcpxml>") ~= nil then
                        mod.lastValue({lastValue = value})
                        mod._manager.injectScript([[setCode("]] .. encode(value) .. [[");]])
                    else
                        local webview = mod._manager._webview
                        if webview then
                            webviewAlert(webview, function() end, "There was an error processing the incoming FCPXML.", "Are you sure the FCPXML is valid?", i18n("ok"))
                        end
                        mod._manager.injectScript([[setCode("]] .. encode("") .. [[");]])
                    end
                end
            elseif params["type"] == "update" then
                local value = params["value"]
                if value then
                    mod.lastValue({lastValue = value})
                end
            elseif params["type"] == "sendToFCP" then
                local value = params["value"]
                if value then
                    if string.find(value, "<!DOCTYPE fcpxml>") ~= nil then
                        local tempFile = os.tmpname() .. ".fcpxml"

                        local file = io.open(tempFile, "w")
                        file:write(value)
                        file:close()

                        fcp:importXML(tempFile)
                    else
                        local webview = mod._manager._webview
                        if webview then
                            webviewAlert(webview, function() end, "There was an error processing the outgoing FCPXML.", "Are you sure the FCPXML is valid?", i18n("ok"))
                        end
                    end
                end
            end
        end
        deps.manager.addHandler("fcpxmlHUD", controllerCallback)
    end
end

return plugin
