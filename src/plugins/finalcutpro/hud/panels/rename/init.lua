--- === plugins.finalcutpro.hud.panels.rename ===
---
--- Batch Rename Panel for the Final Cut Pro HUD.

local require                   = require

--local log                       = require "hs.logger".new "hudButton"

local base64                    = require "hs.base64"
local dialog                    = require "hs.dialog"
local image                     = require "hs.image"

local config                    = require "cp.config"
local fcp                       = require "cp.apple.finalcutpro"
local i18n                      = require "cp.i18n"
local tools                     = require "cp.tools"
local just                      = require "cp.just"

local doUntil                   = just.doUntil
local encode                    = base64.encode
local iconFallback              = tools.iconFallback
local imageFromPath             = image.imageFromPath
local replace                   = tools.replace
local webviewAlert              = dialog.webviewAlert

local mod = {}

local DEFAULT_CODE = [[return function(value)
    -- Do whatever you want to value here.
    -- For example:
    return "PREFIX" .. value .. "SUFFIX" .. os.date()
end]]

--- plugins.finalcutpro.hud.panels.rename.prefix <cp.prop: string>
--- Variable
--- Prefix Preference
mod.prefix = config.prop("hud.rename.prefix", "")

--- plugins.finalcutpro.hud.panels.rename.suffix <cp.prop: string>
--- Variable
--- Suffix Preference
mod.suffix = config.prop("hud.rename.suffix", "")

--- plugins.finalcutpro.hud.panels.rename.find <cp.prop: string>
--- Variable
--- Find Preference
mod.find = config.prop("hud.rename.find", "")

--- plugins.finalcutpro.hud.panels.rename.replace <cp.prop: string>
--- Variable
--- Replace Preference
mod.replace = config.prop("hud.rename.replace", "")

--- plugins.finalcutpro.hud.panels.rename.keepOriginal <cp.prop: boolean>
--- Variable
--- Keep Original Preference
mod.keepOriginal = config.prop("hud.rename.keepOriginal", true)

--- plugins.finalcutpro.hud.panels.rename.sequence <cp.prop: string>
--- Variable
--- Sequence mode
mod.sequence = config.prop("hud.rename.sequence", "disabled")

--- plugins.finalcutpro.hud.panels.rename.startWith <cp.prop: number>
--- Variable
--- Start with
mod.startWith = config.prop("hud.rename.startWith", 1)

--- plugins.finalcutpro.hud.panels.rename.stepValue <cp.prop: number>
--- Variable
--- Start with
mod.stepValue = config.prop("hud.rename.stepValue", 1)

--- plugins.finalcutpro.hud.panels.rename.padding <cp.prop: number>
--- Variable
--- Padding
mod.padding = config.prop("hud.rename.padding", 1)

--- plugins.finalcutpro.hud.panels.rename.codeProcessing <cp.prop: boolean>
--- Variable
--- Code Processing
mod.codeProcessing = config.prop("hud.rename.codeProcessing", false)

--- plugins.finalcutpro.hud.panels.rename.code <cp.prop: string>
--- Variable
--- Code
mod.code = config.prop("hud.rename.code", DEFAULT_CODE)

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

    script = script .. [[changeValueByID("sequence", "]] .. mod.sequence() .. [[");]] .. "\n"
    script = script .. [[changeValueByID("startWith", "]] .. mod.startWith() .. [[");]] .. "\n"
    script = script .. [[changeValueByID("stepValue", "]] .. mod.stepValue() .. [[");]] .. "\n"
    script = script .. [[changeValueByID("padding", "]] .. mod.padding() .. [[");]] .. "\n"
    script = script .. [[changeCheckedByID('codeProcessing', ]] .. tostring(mod.codeProcessing()) .. [[);]] .. "\n"

    script = script .. [[setCode("]] .. encode(mod.code()) .. [[");]] .. "\n"

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

    local sequence      = mod.sequence()
    local startWith     = mod.startWith()
    local stepValue     = mod.stepValue()
    local padding       = mod.padding()

    local code          = mod.code()
    local codeProcessing = mod.codeProcessing()

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
    local i = startWith
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
        -- Sequence Enabled:
        --------------------------------------------------------------------------------
        local sequenceValue = ""
        if sequence ~= "disabled" then
            sequenceValue = string.format("%0" .. padding .. "d", i)
            i = i + stepValue
        end

        --------------------------------------------------------------------------------
        -- Add Prefix & Suffix:
        --------------------------------------------------------------------------------
        if sequence == "beforePrefix" then
            newTitle = sequenceValue .. prefix .. newTitle .. suffix
        elseif sequence == "afterPrefix" then
            newTitle = prefix .. sequenceValue .. newTitle .. suffix
        elseif sequence == "afterSuffix" then
            newTitle = prefix .. newTitle .. suffix .. sequenceValue
        else
            newTitle = prefix .. newTitle .. suffix
        end

        --------------------------------------------------------------------------------
        -- Code:
        --------------------------------------------------------------------------------
        if codeProcessing then
            local successful, fn = pcall(load(code))
            if not successful then
                popupMessage(i18n("luaCodeCouldNotBeProcessed"), fn)
                return
            elseif successful and type(fn) ~= "function" then
                popupMessage(i18n("luaCodeCouldNotBeProcessed"), i18n("codeNeedsToReturnAFunction"))
                return
            end
            local success, result = pcall(function() return fn(newTitle) end)
            if not success then
                popupMessage(i18n("luaCodeCouldNotBeProcessed"), result)
                return
            end
            newTitle = result
        end

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
            height      = 570,
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
                mod.sequence(params["sequence"])
                mod.startWith(params["startWith"])
                mod.stepValue(params["stepValue"])
                mod.padding(params["padding"])
                mod.codeProcessing(params["codeProcessing"])
            elseif params["type"] == "rename" then
                batchRename()
            elseif params["type"] == "reset" then
                mod.prefix("")
                mod.suffix("")
                mod.find("")
                mod.replace("")
                mod.sequence("disabled")
                mod.startWith("1")
                mod.stepValue("1")
                mod.padding("1")
                mod.codeProcessing(false)
                mod.code(DEFAULT_CODE)
                mod.keepOriginal(true)
                updateInfo()
            elseif params["type"] == "updateCode" then
                mod.code(params["code"])
            end
        end
        deps.manager.addHandler("renameHandler", controllerCallback)
    end
end

return plugin
