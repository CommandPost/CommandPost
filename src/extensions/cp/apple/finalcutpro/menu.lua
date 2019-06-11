--- === cp.apple.finalcutpro.menu ===
---
--- Final Cut Pro Menu.

local require = require

--local log               = require "hs.logger".new "fcpMenu"

local axutils       = require "cp.ui.axutils"
local destinations  = require "cp.apple.finalcutpro.export.destinations"
local fcpApp        = require "cp.apple.finalcutpro.app"
local strings       = require "cp.apple.finalcutpro.strings"

local moses         = require "moses"

local childWith     = axutils.childWith
local isEqual       = moses.isEqual

local menu = fcpApp:menu()

----------------------------------------------------------------------------------------
-- Add a finder for Share Destinations:
----------------------------------------------------------------------------------------
menu:addMenuFinder(function(parentItem, path, childName)
    if isEqual(path, {"File", "Share"}) then
        childName = childName:match("(.*)…$") or childName
        local index = destinations.indexOf(childName)
        if index then
            local children = parentItem:attributeValue("AXChildren")
            return children[index]
        end
    end
    return nil
end)

----------------------------------------------------------------------------------------
-- Add a finder for missing menus:
----------------------------------------------------------------------------------------
local missingMenuMap = {
    { path = {"Final Cut Pro"},                 child = "Commands",                 key = "CommandSubmenu" },
    { path = {"Final Cut Pro", "Commands"},     child = "Customize…",               key = "Customize" },
    { path = {"Clip"},                          child = "Open Clip",                key = "FFOpenInTimeline" },
    { path = {"Clip"},                          child = "Open in Angle Editor",     key = "FFOpenInAngleEditor" },
    { path = {"Window", "Show in Workspace"},   child = "Sidebar",                  key = "PEEventsLibrary" },
    { path = {"Window", "Show in Workspace"},   child = "Timeline",                 key = "PETimeline" },
    { path = {"Window", "Show in Workspace"},   child = "Event Viewer",             key = "PEEventViewer" },
    { path = {"Window", "Show in Workspace"},   child = "Timeline Index",           key = "PEDataList" },
    { path = {"Window"},                        child = "Extensions",               key = "FFExternalProviderMenuItemTitle" },
}
menu:addMenuFinder(function(parentItem, path, childName)
    for _,item in ipairs(missingMenuMap) do
        if isEqual(path, item.path) and childName == item.child then
            local currentValue = strings:find(item.key)
            return childWith(parentItem, "AXTitle", currentValue)
        end
    end
    return nil
end)

----------------------------------------------------------------------------------------
-- Add a finder for Custom Workspaces:
----------------------------------------------------------------------------------------
menu:addMenuFinder(function(parentItem, path, childName)
    if isEqual(path, {"Window", "Workspaces"}) then
        return childWith(parentItem, "AXTitle", childName)
    end
    return nil
end)

----------------------------------------------------------------------------------------
-- Add a finder for Commands:
----------------------------------------------------------------------------------------
menu:addMenuFinder(function(parentItem, path, childName)
    if isEqual(path, {"Final Cut Pro", "Commands"}) then
        return childWith(parentItem, "AXTitle", childName)
    end
    return nil
end)

----------------------------------------------------------------------------------------
-- Add a finder for Extensions:
----------------------------------------------------------------------------------------
menu:addMenuFinder(function(parentItem, path, childName)
    if isEqual(path, {"Window", "Extensions"}) then
        return childWith(parentItem, "AXTitle", childName)
    end
    return nil
end)

return menu