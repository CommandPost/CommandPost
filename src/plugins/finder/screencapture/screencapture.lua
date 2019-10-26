--- === plugins.core.pasteboard.history ===
---
--- Adds text pasteboard history actions to the Search Console.

local require           = require

--local log               = require "hs.logger".new "pbHistory"

local fs                = require "hs.fs"
local task              = require "hs.task"

local i18n              = require "cp.i18n"

local pathToAbsolute    = fs.pathToAbsolute

local mod = {}

local plugin = {
    id              = "finder.screencapture",
    group           = "finder",
    dependencies    = {
        ["core.action.manager"] = "actionmanager",
    }
}

function plugin.init(deps)
    local actionmanager = deps.actionmanager
    mod._handler = actionmanager.addHandler("global_screencapture", "global")
        :onChoices(function(choices)
            local options = {
                {
                    text = i18n("captureMenu"),
                    subText = i18n("captureMenuDescription"),
                    mode = "captureMenu"
                },
                {
                    text = i18n("captureScreen"),
                    subText = i18n("captureScreenDescription"),
                    mode = "captureScreen"
                },
                {
                    text = i18n("captureScreenToClipboard"),
                    subText = i18n("captureScreenToClipboardDescription"),
                    mode = "captureScreenToClipboard"
                },
                {
                    text = i18n("captureInteractive"),
                    subText = i18n("captureInteractiveDescription"),
                    mode = "captureInteractive"
                },
                {
                    text = i18n("captureInteractiveToClipboard"),
                    subText = i18n("captureInteractiveToClipboardDescription"),
                    mode = "captureInteractiveToClipboard"
                }
            }
            for _, item in pairs(options) do
                choices
                    :add(item.text)
                    :subText(item.subText)
                    :params({
                        mode = item.mode,
                    })
                    :id("global_screencapture_" .. item.mode)
            end
        end)
        :onExecute(function(action)
            local filename = pathToAbsolute("~").."/Desktop/Screen Capture at "..os.date("!%Y-%m-%d-%T")..".png"
            local args = ""
            local mode = action.mode

            if mode == "captureScreenToClipboard" then
                args = "-c"
            elseif mode == "captureInteractive" then
                args = "-i"
            elseif mode == "captureMenu" then
                args = "-iU"
            elseif mode == "captureInteractiveToClipboard" then
                args = "-ci"
            end

            -- Show the screen capture UI:
            args = args .. "u"

            task.new("/usr/sbin/screencapture", nil, {args, filename}):start()
        end)
        :onActionId(function(params)
            return "global_screencapture_" .. params.mode
        end)

    return mod
end

return plugin
