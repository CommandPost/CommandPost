--- === plugins.finalcutpro.hud.panels.pasteboard ===
---
--- FCPXML Panel for the Final Cut Pro HUD.

local require           = require

local hs                = hs

local log               = require("hs.logger").new("fcpxmlHud")

local base64            = require("hs.base64")
local dialog            = require("hs.dialog")
local image             = require("hs.image")
local pasteboard        = require("hs.pasteboard")

local config            = require("cp.config")
local fcp               = require("cp.apple.finalcutpro")
local i18n              = require("cp.i18n")
local json              = require("cp.json")
local plist             = require("cp.plist")
local tools             = require("cp.tools")

local encode            = base64.encode
local execute           = hs.execute
local webviewAlert      = dialog.webviewAlert

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

local PASTEBOARD_UTI = fcp.PASTEBOARD_UTI

--- plugins.finalcutpro.hud.panels.pasteboard.lastValue <cp.prop: table>
--- Field
--- Last value in FCPXML HUD.
mod.lastValue = json.prop(config.userConfigRootPath, "HUD", "Pasteboard.cpHUD", {})

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
    local value = lastValue and lastValue.xmlData
    if value then
        mod._manager.injectScript([[setCode("]] .. encode(value) .. [[");]])
    end
end

local function getPasteboard()
    local pbData = pasteboard.readPListForUTI(nil, PASTEBOARD_UTI)
    if pbData and pbData.ffpasteboardobject then

        ------------------------------------------------
        -- Write ffpasteboardobject to disk:
        ------------------------------------------------
        local tempFile = os.tmpname()
        local file = io.open(tempFile, "w")
        file:write(pbData.ffpasteboardobject)
        file:close()

        ------------------------------------------------
        -- Convert Binary into XML:
        ------------------------------------------------
        local plainXML, executeStatus = hs.execute('plutil -convert xml1 "' .. tempFile .. '"')
        if not executeStatus then return end

        ------------------------------------------------
        -- Read data from disk:
        ------------------------------------------------
        file = io.open(tempFile, "r")
        local xmlData = file:read("*a")
        file:close()

        if xmlData then
            return pbData, xmlData
        end
    end
end

local function convertXMLtoBinary(xml)

    ------------------------------------------------
    -- Write data to disk:
    ------------------------------------------------
    local tempFile = os.tmpname()
    file = io.open(tempFile, "w")
    file:write(xml)
    file:close()

    ------------------------------------------------
    --- Convert XML into Binary:
    ------------------------------------------------
    local _, executeStatus = hs.execute('plutil -convert binary1 "' .. tempFile .. '"')
    if not executeStatus then return end

    ------------------------------------------------
    -- Read data from disk:
    ------------------------------------------------
    file = io.open(tempFile, "r")
    local binaryData = file:read("*a")
    file:close()

    return binaryData

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.hud.panels.pasteboard",
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
            id          = "pasteboard",
            label       = i18n("pasteboard"),
            image       = image.imageFromPath(tools.iconFallback(env:pathToAbsolute("/images/pasteboard.png"))),
            tooltip     = i18n("pasteboard"),
            loadedFn    = updateInfo,
            height      = 540,
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
            if params["type"] == "loadFromPasteboard" then
                --------------------------------------------------------------------------------
                -- Load from Pasteboard:
                --------------------------------------------------------------------------------
                local pbData, xmlData = getPasteboard()
                if xmlData then
                    mod.lastValue({
                        pbData = pbData,
                        xmlData = xmlData,
                    })
                    mod._manager.injectScript([[setCode("]] .. encode(xmlData) .. [[");]])
                else
                    local webview = mod._manager._webview
                    if webview then
                        webviewAlert(webview, function() end, "There was an error processing the Pasteboard.", "Are you sure there's Final Cut Pro copied?", i18n("ok"))
                    end
                    mod._manager.injectScript([[setCode("]] .. encode("") .. [[");]])
                end

            elseif params["type"] == "sendToPasteboard" then
                --------------------------------------------------------------------------------
                -- Send to Pasteboard:
                --------------------------------------------------------------------------------
                local value = params["value"]
                if value then
                    if string.find(value, [[<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">]], 1, true) ~= nil then
                        local lastValue = mod.lastValue()
                        local pbData = lastValue.pbData
                        if pbData then
                            local binaryData = convertXMLtoBinary(value)
                            if binaryData then
                                pbData.ffpasteboardobject = binaryData
                                pasteboard.writePListForUTI(nil, PASTEBOARD_UTI, pbData)
                                return
                            end
                        end
                    end
                end
                local webview = mod._manager._webview
                if webview then
                    webviewAlert(webview, function() end, "There was an error writing to the Pasteboard.", "Are you sure the XML is valid?", i18n("ok"))
                end
            elseif params["type"] == "update" then
                --------------------------------------------------------------------------------
                -- Update:
                --------------------------------------------------------------------------------
                local value = params["value"]
                if value then
                    local lastValue = mod.lastValue()
                    mod.lastValue({
                        pbData = lastValue.pbData,
                        xmlData = value,
                    })
                end
            end
        end
        deps.manager.addHandler("pasteboardHUD", controllerCallback)
    end
end

return plugin
