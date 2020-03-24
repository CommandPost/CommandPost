--- === plugins.core.menu.menuaction ===
---
--- Add actions that allow you to trigger the menubar items from any application.
---
--- Specials thanks to @asmagill for his amazing work with `coroutine` support.

local require           = require

local log               = require "hs.logger".new "menuaction"

local application       = require "hs.application"
local fnutils           = require "hs.fnutils"
local timer             = require "hs.timer"

local tools             = require "cp.tools"

local ax                = require "hs._asm.axuielement"

local concat            = table.concat
local copy              = fnutils.copy
local doAfter           = timer.doAfter
local playErrorSound    = tools.playErrorSound
local watcher           = application.watcher

local mod = {}

mod._cache = {}

local kAXMenuItemModifierControl = (1 << 2)
local kAXMenuItemModifierNoCommand = (1 << 3)
local kAXMenuItemModifierOption = (1 << 1)
local kAXMenuItemModifierShift = (1 << 0)

-- SOURCE: https://github.com/Hammerspoon/hammerspoon/pull/2308#issuecomment-590246330
local function getMenuStructure(item)

    if not item then
        log.ef("No `item` in plugins.core.menu.menuaction.")
        return
    end

    local values = item:allAttributeValues()

    if not values then
        log.ef("No `values` in plugins.core.menu.menuaction.")
        return
    end

    local thisMenuItem = {
        AXTitle                = values["AXTitle"] or "",
        AXRole                 = values["AXRole"] or "",
        AXMenuItemMarkChar     = values["AXMenuItemMarkChar"] or "",
        AXMenuItemCmdChar      = values["AXMenuItemCmdChar"] or "",
        AXMenuItemCmdModifiers = values["AXMenuItemCmdModifiers"] or "",
        AXEnabled              = values["AXEnabled"] or "",
        AXMenuItemCmdGlyph     = values["AXMenuItemCmdGlyph"] or "",
    }

    if thisMenuItem["AXTitle"] == "Apple" then
        thisMenuItem = nil
    else
        local role = thisMenuItem["AXRole"]

        local modsDst = nil
        local modsVal = thisMenuItem["AXMenuItemCmdModifiers"]
        if type(modsVal) == "number" then
            modsDst = ((modsVal & kAXMenuItemModifierNoCommand) > 0) and {} or { "cmd" }
            if (modsVal & kAXMenuItemModifierShift)   > 0 then table.insert(modsDst, "shift") end
            if (modsVal & kAXMenuItemModifierOption)  > 0 then table.insert(modsDst, "alt") end
            if (modsVal & kAXMenuItemModifierControl) > 0 then table.insert(modsDst, "ctrl") end
        end
        thisMenuItem["AXMenuItemCmdModifiers"] = modsDst

        local children = {}
        for i = 1, #item, 1 do table.insert(children, getMenuStructure(item[i])) end
        if #children > 0 then thisMenuItem["AXChildren"] = children end

        if not (role == "AXMenuItem" or role == "AXMenuBarItem") then
            thisMenuItem = (#children > 0) and children or nil
        end
    end
    hs.coroutineApplicationYield()
    return thisMenuItem
end

local function getMenuItems(appObject, callback)
    hs.assert(getmetatable(appObject) == hs.getObjectMetatable("hs.application"), "expect hs.application for first parameter")
    hs.assert(type(callback) == "function" or (getmetatable(callback) or {}).__call, "expected function for second parameter")

    local app = ax.applicationElement(appObject)
    local menus

    local menuBar = app and app("menuBar")
    if menuBar then
        coroutine.wrap(function(m, c)
            local menus = getMenuStructure(m)
            c(menus)
        end)(menuBar, callback)
    else
        callback(menus)
    end
end

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
        if app and event == watcher.activated and app:pid() then
            mod._handler:reset(true)
            doAfter(0.1, function()
                if app and app:pid() then
                    getMenuItems(app, function(result)
                        local pid = app:pid()
                        if pid then
                            mod._cache[pid] = result
                            mod._handler:reset(true)
                        end
                    end)
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
                local menuItems = mod._cache[pid]
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
