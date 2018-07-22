--- === cp.apple.finalcutpro.menu ===
---
--- Final Cut Pro Menu.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local require = require
-- local log                       = require("hs.logger").new("fcp_menu")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local fcpApp                    = require("cp.apple.finalcutpro.app")
local strings                   = require("cp.apple.finalcutpro.strings")
local destinations				= require("cp.apple.finalcutpro.export.destinations")

local axutils                   = require("cp.ui.axutils")

--------------------------------------------------------------------------------
-- 3rd Party Extensions:
--------------------------------------------------------------------------------
local isEqual                   = require("moses").isEqual

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
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
    { path = {"Final Cut Pro"},					child = "Commands",			key = "CommandSubmenu" },
    { path = {"Final Cut Pro", "Commands"},		child = "Customize…",		key = "Customize" },
    { path = {"Clip"},							child = "Open Clip",		key = "FFOpenInTimeline" },
    { path = {"Window", "Show in Workspace"},	child = "Sidebar",			key = "PEEventsLibrary" },
    { path = {"Window", "Show in Workspace"},	child = "Timeline",			key = "PETimeline" },
}

menu:addMenuFinder(function(parentItem, path, childName)
    for _,item in ipairs(missingMenuMap) do
        if isEqual(path, item.path) and childName == item.child then
            local currentValue = strings:find(item.key)
            return axutils.childWith(parentItem, "AXTitle", currentValue)
        end
    end
    return nil
end)

return menu
