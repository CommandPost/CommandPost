--- === plugins.core.menu.menuaction ===
---
--- Add actions that allow you to trigger the menubar items from any application.

local require           = require

--local log               = require "hs.logger".new "menuaction"

local application       = require "hs.application"
local fnutils           = require "hs.fnutils"

local tools             = require "cp.tools"

local concat            = table.concat
local copy              = fnutils.copy
local playErrorSound    = tools.playErrorSound
local watcher           = application.watcher

local mod = {}

mod._cache = {}

function mod._processMenuItems(items, choices, pid, path)
    path = path or {}
    for _,v in pairs(items) do
        if type(v) == "table" then
            local role = v.AXRole
            local children = v.AXChildren
            local title = v.AXTitle
            if role == "AXMenuBarItem" and type(children) == "table" then
                table.insert(path, title)
                mod._processMenuItems(children[1], choices, pid, path)
            elseif role == "AXMenuItem" and not children then
                if title and title ~= "" then
                    local menuPath = copy(path)
                    local menuPathString = concat(path, " > ")
                    table.insert(menuPath, title)
                    choices
                        :add(title)
                        :subText(menuPathString)
                        :params({
                            pid = pid,
                            path = menuPath,
                        })
                        :id(menuPathString)
                end
            end
        end
    end
end

local plugin = {
    id              = "core.menu.menuaction",
    group           = "core",
    dependencies    = {
        ["core.action.manager"] = "actionmanager",
    }
}

function plugin.init(deps)

    mod._appWatcher = watcher.new(function(_, event, app)
        if app and event == watcher.activated then
            mod._handler:reset(true)
            app:getMenuItems(function(result)
                local pid = app:pid()
                if pid then
                    mod._cache[pid] = result
                end
            end)
        elseif event == watcher.terminated then
            local pid = app:pid()
            if pid then
                mod._cache[pid] = nil
            end
        end
    end):start()

    local actionmanager = deps.actionmanager
    mod._handler = actionmanager.addHandler("global_menuactions", "global")
        :onChoices(function(choices)
            local app = application.frontmostApplication()
            local pid = app and app:pid()
            if pid then
                local menuItems = mod._cache[pid] or app:getMenuItems()
                if menuItems then
                    mod._processMenuItems(menuItems, choices, pid)
                end
            end
        end)
        :onExecute(function(action)
            local app = application.applicationForPID(action.pid)
            if app and app:selectMenuItem(action.path) then
                return
            end
            playErrorSound()
        end)
        :onActionId(function(params)
            return "global_menuactions: " .. concat(params.path, " > ")
        end)

    return mod
end

return plugin
