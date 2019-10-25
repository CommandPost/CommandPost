--- === plugins.finalcutpro.hud.panels.rename ===
---
--- Batch Rename Panel for the Final Cut Pro HUD.

local require                   = require

--local log                       = require "hs.logger".new "hudButton"

local dialog                    = require "hs.dialog"
local image                     = require "hs.image"

local config                    = require "cp.config"
local fcp                       = require "cp.apple.finalcutpro"
local i18n                      = require "cp.i18n"
local tools                     = require "cp.tools"
local just                      = require "cp.just"

local doUntil                   = just.doUntil
local iconFallback              = tools.iconFallback
local imageFromPath             = image.imageFromPath
local replace                   = tools.replace
local webviewAlert              = dialog.webviewAlert

local mod = {}

--- plugins.finalcutpro.hud.panels.rename.prefix <cp.prop: string>
--- Variable
--- Last Value
mod.prefix = config.prop("hud.rename.prefix", "")

--- plugins.finalcutpro.hud.panels.rename.suffix <cp.prop: string>
--- Variable
--- Last Value
mod.suffix = config.prop("hud.rename.suffix", "")

--- plugins.finalcutpro.hud.panels.rename.find <cp.prop: string>
--- Variable
--- Last Value
mod.find = config.prop("hud.rename.find", "")

--- plugins.finalcutpro.hud.panels.rename.replace <cp.prop: string>
--- Variable
--- Last Value
mod.replace = config.prop("hud.rename.replace", "")

--- plugins.finalcutpro.hud.panels.rename.keepOriginal <cp.prop: boolean>
--- Variable
--- Match Case
mod.keepOriginal = config.prop("hud.rename.keepOriginal", true)

-- popupMessage(a, b) -> none
-- Function
-- Popup a message on the HUD webview.
--
-- Parameters:
--  * a - Main message as string.
--  * b - Secondary message as string.
--
-- Returns:
--  * None
local function popupMessage(a, b)
    local webview = mod._manager._webview
    if webview then
        webviewAlert(webview, function() end, a, b, i18n("ok"))
    end
end

--- plugins.finalcutpro.hud.panels.rename.updateInfo() -> none
--- Function
--- Update the Buttons Panel HTML content.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
local function updateInfo()
    local script = [[changeValueByID("prefix", "]] .. mod.prefix() .. [[");]] .. "\n"
    script = script .. [[changeValueByID("suffix", "]] .. mod.suffix() .. [[");]] .. "\n"
    script = script .. [[changeValueByID("find", "]] .. mod.find() .. [[");]] .. "\n"
    script = script .. [[changeValueByID("replace", "]] .. mod.replace() .. [[");]] .. "\n"
    script = script .. [[changeCheckedByID('keepOriginal', ]] .. tostring(mod.keepOriginal()) .. [[);]] .. "\n"
    mod._manager.injectScript(script)
end

-- batchRename() -> none
-- Function
-- Batch Rename
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function batchRename()
    --------------------------------------------------------------------------------
    -- Get Preferences:
    --------------------------------------------------------------------------------
    local prefix        = mod.prefix()
    local suffix        = mod.suffix()
    local f             = mod.find()
    local r             = mod.replace()
    local keepOriginal  = mod.keepOriginal()

    --------------------------------------------------------------------------------
    -- Make sure we're in list view:
    --------------------------------------------------------------------------------
    local libraries = fcp:libraries()
    if not doUntil(function()
        libraries:show()
        return libraries:isShowing()
    end) then
        popupMessage(i18n("batchRenameFailed"), i18n("batchRenameBrowserFail"))
        return
    end

    --------------------------------------------------------------------------------
    -- Make sure at least one clip is selected:
    --------------------------------------------------------------------------------
    local selectedClips = libraries:selectedClips()
    if #selectedClips == 0 then
        popupMessage(i18n("batchRenameFailed"), i18n("noSelectedClipsInBrowser"))
        return
    end

    --------------------------------------------------------------------------------
    -- Batch Rename:
    --------------------------------------------------------------------------------
    for _, clip in pairs(selectedClips) do
        --------------------------------------------------------------------------------
        -- Get original title:
        --------------------------------------------------------------------------------
        local originalTitle = clip:getTitle()

        --------------------------------------------------------------------------------
        -- Keep original?
        --------------------------------------------------------------------------------
        local newTitle = ""
        if keepOriginal then
            newTitle = originalTitle
        end

        --------------------------------------------------------------------------------
        -- Find & Replace:
        --------------------------------------------------------------------------------
        if f and r and f ~= "" then
            newTitle = replace(newTitle, f, r)
        end

        --------------------------------------------------------------------------------
        -- Add Prefix & Suffix:
        --------------------------------------------------------------------------------
        newTitle = prefix .. newTitle .. suffix

        --------------------------------------------------------------------------------
        -- Set Title:
        --------------------------------------------------------------------------------
        clip:setTitle(newTitle)
    end

end

local plugin = {
    id              = "finalcutpro.hud.panels.rename",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.hud.manager"]     = "manager",
        ["core.action.manager"]         = "actionManager",
    }
}

function plugin.init(deps, env)
    if fcp:isSupported() then

        mod._manager = deps.manager
        mod._actionManager = deps.actionManager

        local panel = deps.manager.addPanel({
            priority    = 1,
            id          = "rename",
            label       = i18n("batchRename"),
            tooltip     = i18n("batchRename"),
            image       = imageFromPath(iconFallback(env:pathToAbsolute("/images/rename.png"))),
            height      = 300,
            loadedFn    = updateInfo,
        })

        --------------------------------------------------------------------------------
        -- Generate HTML for Panel:
        --------------------------------------------------------------------------------
        local e = {}
        e.i18n = i18n
        local renderPanel = env:compileTemplate("html/panel.html")
        panel:addContent(1, function() return renderPanel(e) end, false)

        --------------------------------------------------------------------------------
        -- Setup Controller Callback:
        --------------------------------------------------------------------------------
        local controllerCallback = function(_, params)
            if params["type"] == "update" then
                mod.prefix(params["prefix"])
                mod.suffix(params["suffix"])
                mod.find(params["find"])
                mod.replace(params["replace"])
                mod.keepOriginal(params["keepOriginal"])
            elseif params["type"] == "rename" then
                batchRename()
            elseif params["type"] == "reset" then
                mod.prefix("")
                mod.suffix("")
                mod.find("")
                mod.replace("")
                mod.keepOriginal(true)
                updateInfo()
            end
        end
        deps.manager.addHandler("renameHandler", controllerCallback)
    end
end

return plugin
