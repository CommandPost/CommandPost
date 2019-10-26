--- === plugins.core.preferences.panels.snippets ===
---
--- Snippets Preferences Panel

local require           = require

--local log               = require "hs.logger".new "snippets"

local dialog            = require "hs.dialog"
local fs                = require "hs.fs"
local image             = require "hs.image"
local inspect           = require "hs.inspect"
local timer             = require "hs.timer"

local config            = require "cp.config"
local i18n              = require "cp.i18n"
local json              = require "cp.json"
local plugins           = require "cp.plugins"
local tools             = require "cp.tools"

local doAfter           = timer.doAfter
local webviewAlert      = dialog.webviewAlert
local tableCount        = tools.tableCount
local blockAlert        = dialog.blockAlert

local mod = {}

--- plugins.finalcutpro.hud.panels.snippets.snippets <cp.prop: table>
--- Field
--- Snippets
mod.snippets = json.prop(config.userConfigRootPath, "Snippets", "Snippets.cpSnippets", {}):watch(function()
    if mod._handler then
        --------------------------------------------------------------------------------
        -- Reset the Action Handler each time a Snippet is updated:
        --------------------------------------------------------------------------------
        mod._handler:reset(true)
    end
end)

-- getSelectedSnippet() -> string
-- Function
-- Gets the label of the selected snippet.
--
-- Parameters:
--  * None
--
-- Returns:
--  * A string
local function getSelectedSnippet()
    local snippets = mod.snippets()
    local count = 0
    local firstLabel
    for label, snippet in pairs(snippets) do
        if not firstLabel then
            firstLabel = label
        end
        count = count + 1
        if snippet.selected then
            return label
        end
    end

    if count ~= 0 then
        snippets[firstLabel].selected = true
        mod.snippets(snippets)
    end

    return firstLabel
end

-- getSnippetLabels() -> string
-- Function
-- Gets the HTML code for the Snippets select.
--
-- Parameters:
--  * None
--
-- Returns:
--  * A string
local function getSnippetLabels()
    local snippets = mod.snippets()

    local selectedSnippet = getSelectedSnippet()

    if not selectedSnippet then
        return [[<option selected value="">]] .. i18n("none") .. [[</option>]]
    end

    local labels = {}

    for label, _ in pairs(snippets) do
        table.insert(labels, label)
    end

    table.sort(labels)

    local result = ""
    for _, label in ipairs(labels) do

        local selected = ""
        if snippets[label].selected == true then
            selected = " selected "
        end
        result = result .. [[<option ]] .. selected .. [[ value="]] .. label .. [[">]] .. label .. [[</option>]] .. "\n"
    end

    return result
end

-- getCode() -> string
-- Function
-- Gets the selected code value from the JSON file.
--
-- Parameters:
--  * None
--
-- Returns:
--  * The code as as string
local function getCode()
    local snippets = mod.snippets()
    local snippet = getSelectedSnippet()
    return snippets and snippet and snippets[snippet].code or ""
end

local plugin = {
    id              = "core.preferences.panels.snippets",
    group           = "core",
    dependencies    = {
        ["core.preferences.manager"] = "manager",
        ["core.action.manager"] = "actionmanager",
    }
}

function plugin.init(deps, env)

    mod._manager = deps.manager

    local panel = deps.manager.addPanel({
        priority    = 2049,
        id          = "snippets",
        label       = i18n("snippets"),
        image       = image.imageFromPath(env:pathToAbsolute("/images/snippets.tiff")),
        tooltip     = i18n("snippets"),
        height      = 500,
    })

    --------------------------------------------------------------------------------
    -- Generate HTML for Panel:
    --------------------------------------------------------------------------------
    local e = {}
    e.i18n = i18n
    e.getSnippetLabels = getSnippetLabels
    e.getCode = getCode
    local renderPanel = env:compileTemplate("html/panel.html")
    panel:addContent(1, function() return renderPanel(e) end, false)

    --------------------------------------------------------------------------------
    -- Setup Controller Callback:
    --------------------------------------------------------------------------------
    local controllerCallback = function(_, params)
        if params["type"] == "examples" then
            os.execute('open "http://help.commandpost.io/advanced/snippets"')
        elseif params["type"] == "new" then
            --------------------------------------------------------------------------------
            -- New Snippet:
            --------------------------------------------------------------------------------
            local label = params["label"]
            if label and label ~= "" then
                local snippets = mod.snippets()
                if snippets[label] then
                    local webview = mod._manager._webview
                    if webview then
                        webviewAlert(webview, function() end, i18n("snippetAlreadyExists"), i18n("snippetUniqueName"), i18n("ok"))
                    end
                else
                    for _, v in pairs(snippets) do
                        v.selected = false
                    end
                    snippets[label] = {
                        ["code"] = "",
                        ["selected"] = true,
                    }
                    mod.snippets(snippets)
                    mod._manager.refresh()
                end
            end
        elseif params["type"] == "delete" then
            --------------------------------------------------------------------------------
            -- Delete Snippet:
            --------------------------------------------------------------------------------
            local snippet = params["snippet"]
            if snippet then
                local snippets = mod.snippets()
                snippets[snippet] = nil
                mod.snippets(snippets)
                mod._manager.refresh()
            end
        elseif params["type"] == "change" then
            --------------------------------------------------------------------------------
            -- Change Snippet via Dropdown Menu:
            --------------------------------------------------------------------------------
            local snippet = params["snippet"]
            if snippet then
                local snippets = mod.snippets()
                for label, v in pairs(snippets) do
                    if label == snippet then
                        snippets[label].selected = true
                    else
                        snippets[label].selected = false
                    end
                end
                mod.snippets(snippets)
            end
            mod._manager.refresh()
        elseif params["type"] == "update" then
            --------------------------------------------------------------------------------
            -- Updating Code:
            --------------------------------------------------------------------------------
            local code = params["code"]
            local snippet = params["snippet"]
            if code and snippet and snippet ~= "" then
                local snippets = mod.snippets()
                snippets[snippet] = { ["code"] = code }
                mod.snippets(snippets)
            end
        elseif params["type"] == "execute" then
            --------------------------------------------------------------------------------
            -- Execute Code:
            --------------------------------------------------------------------------------
            local snippet = params["snippet"]
            if snippet and snippet ~= "" then
                local snippets = mod.snippets()
                local code = snippets[snippet].code
                local successful, message = pcall(load(code))
                if not successful then
                    local webview = mod._manager._webview
                    if webview then
                        webviewAlert(webview, function() end, i18n("snippetError"), message, i18n("ok"))
                    end
                end
            else
                local webview = mod._manager._webview
                if webview then
                    webviewAlert(webview, function() end, i18n("noSnippetExists"), "", i18n("ok"))
                end
            end
        end
    end
    deps.manager.addHandler("snippets", controllerCallback)

    --------------------------------------------------------------------------------
    -- Action Handler:
    --------------------------------------------------------------------------------
    local actionmanager = deps.actionmanager
    mod._handler = actionmanager.addHandler("global_snippets", "global")
        :onChoices(function(choices)
            local snippets = mod.snippets()
            for label, item in pairs(snippets) do
                choices
                    :add(label)
                    :subText(i18n("executeLuaCodeSnippet"))
                    :params({
                        code = item.code,
                        id = label,
                    })
                    :id("global_snippets_" .. label)
            end
        end)
        :onExecute(function(action)
            local code = action.code
            local successful, message = pcall(load(code))
            if not successful then
                blockAlert(i18n("snippetExecuteError"), message, i18n("ok"))
            end
        end)
        :onActionId(function(params)
            return "global_snippets_" .. params.id
        end)

    return mod
end

return plugin
