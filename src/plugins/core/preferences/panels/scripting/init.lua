--- === plugins.core.preferences.panels.scripting ===
---
--- Snippets Preferences Panel

local require           = require

--local log               = require "hs.logger".new "snippets"

local hs                = hs

local dialog            = require "hs.dialog"
local image             = require "hs.image"
local ipc				= require "hs.ipc"
local timer             = require "hs.timer"

local config            = require "cp.config"
local i18n              = require "cp.i18n"
local json              = require "cp.json"

local execute           = hs.execute
local allowAppleScript  = hs.allowAppleScript

local blockAlert        = dialog.blockAlert
local imageFromPath     = image.imageFromPath
local webviewAlert      = dialog.webviewAlert

local mod = {}

--- plugins.core.preferences.panels.scripting.snippets <cp.prop: table>
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

-- updatePreferences() -> none
-- Function
-- Updates the Preferences Panel UI.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function updatePreferences()
    mod._manager.injectScript([[changeCheckedByID('commandLineTool', ]] .. tostring(ipc.cliStatus(nil, true)) .. [[);]])
    --------------------------------------------------------------------------------
    -- Sometimes it takes a little while to uninstall the CLI:
    --------------------------------------------------------------------------------
    timer.doAfter(0.5, function()
        mod._manager.injectScript([[changeCheckedByID('commandLineTool', ]] .. tostring(ipc.cliStatus(nil, true)) .. [[);]])
    end)
end

-- toggleCommandLineTool() -> none
-- Function
-- Toggles the Command Line Tool
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function toggleCommandLineTool()
    local cliStatus = ipc.cliStatus()
    if cliStatus then
        ipc.cliUninstall()
    else
        ipc.cliInstall()
    end
    local newCliStatus = ipc.cliStatus()
    if cliStatus == newCliStatus then
        if cliStatus then
            dialog.webviewAlert(mod._manager.getWebview(), function()
                updatePreferences()
            end, i18n("cliUninstallError"), "", i18n("ok"), nil, "informational")
        else
            dialog.webviewAlert(mod._manager.getWebview(), function()
                updatePreferences()
            end, i18n("cliInstallError"), "", i18n("ok"), nil, "informational")
        end
    else
        updatePreferences()
    end
end

local plugin = {
    id              = "core.preferences.panels.scripting",
    group           = "core",
    dependencies    = {
        ["core.preferences.manager"] = "manager",
        ["core.action.manager"] = "actionmanager",
    }
}

function plugin.init(deps, env)

    mod._manager = deps.manager

    local actionmanager = deps.actionmanager

    local panel = deps.manager.addPanel({
        priority    = 2049,
        id          = "scripting",
        label       = i18n("scripting"),
        image       = imageFromPath(config.bundledPluginsPath .. "/core/preferences/panels/images/SEScriptEditorX.icns"),
        tooltip     = i18n("scripting"),
        height      = 660,
    })

    --------------------------------------------------------------------------------
    -- Command Line Tool:
    --------------------------------------------------------------------------------
    panel
        :addHeading(1, i18n("scriptingTools"))
        :addCheckbox(2,
            {
                label		= i18n("enableCommandLineSupport"),
                checked		= function() return ipc.cliStatus() end,
                onchange	= toggleCommandLineTool,
                id		    = "commandLineTool",
            }
        )

    --------------------------------------------------------------------------------
    -- AppleScript:
    --------------------------------------------------------------------------------
    panel
        :addCheckbox(3,
            {
                label		= i18n("enableAppleScriptSupport"),
                checked		= function() return allowAppleScript() end,
                onchange	= function()
                                local value = allowAppleScript()
                                allowAppleScript(not value)
                            end,
            }
        )

    --------------------------------------------------------------------------------
    -- Learn More Button:
    --------------------------------------------------------------------------------
    panel
        :addContent(4, [[<br />]], false)
        :addButton(5,
            {
                label 	    = "Learn More...",
                width       = 100,
                onclick	    = function() execute("open 'https://help.commandpost.io/advanced/controlling_commandpost'") end,
            }
        )

    --------------------------------------------------------------------------------
    -- Generate HTML for Panel:
    --------------------------------------------------------------------------------
    local e = {}
    e.i18n = i18n
    e.getSnippetLabels = getSnippetLabels
    e.getCode = getCode
    local renderPanel = env:compileTemplate("html/panel.html")
    panel:addContent(100, function() return renderPanel(e) end, false)

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
            if snippet ~= "" then
                webviewAlert(mod._manager._webview, function(result)
                    if result == i18n("yes") then
                        local snippets = mod.snippets()
                        snippets[snippet] = nil
                        mod.snippets(snippets)
                        mod._manager.refresh()
                    end
                end, i18n("deleteSnippetConfirmation"), "", i18n("yes"), i18n("no"))
            end
        elseif params["type"] == "change" then
            --------------------------------------------------------------------------------
            -- Change Snippet via Dropdown Menu:
            --------------------------------------------------------------------------------
            local snippet = params["snippet"]
            if snippet then
                local snippets = mod.snippets()
                for label, _ in pairs(snippets) do
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
        elseif params["type"] == "insertAction" then
            --------------------------------------------------------------------------------
            -- Insert Action:
            --------------------------------------------------------------------------------
            actionmanager.getActivator("snippetsAddAction"):onActivate(function(handler, action, text)
                local result = [[local handler = cp.plugins("core.action.manager").getHandler("]] .. handler:id()  .. [[")]] .. "\n"
                result = result .. "local action = " .. "\n"
                result = result .. hs.inspect(action) .. "\n"
                result = result .. [[handler:execute(action)]]
                mod._manager.injectScript("insertTextAtCursor(`" .. result .. "`);")
            end):show()
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
            local snippets = mod.snippets()
            local code = snippets[action.id] and snippets[action.id].code
            if code then
                local successful, message = pcall(load(code))
                if not successful then
                    blockAlert(i18n("snippetExecuteError"), message, i18n("ok"))
                end
            end
        end)
        :onActionId(function(params)
            return "global_snippets_" .. params.id
        end)

    return mod
end

return plugin
