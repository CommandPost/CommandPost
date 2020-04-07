--- === plugins.core.menu.manager ===
---
--- Menu Manager Plugin.

local require = require

local image     = require "hs.image"
local menubar   = require "hs.menubar"

local config    = require "cp.config"
local i18n      = require "cp.i18n"

local section   = require "section"

local manager = {}

--- plugins.core.menu.manager.rootSection() -> section
--- Variable
--- A new Root Section
manager.rootSection = section:new()

--- plugins.core.menu.manager.titleSuffix() -> table
--- Variable
--- Table of Title Suffix's
manager.titleSuffix = {}

--- plugins.core.menu.manager.init() -> none
--- Function
--- Initialises the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function manager.init()
    -------------------------------------------------------------------------------
    -- Set up Menubar:
    --------------------------------------------------------------------------------
    manager.menubar = menubar.new()

    --------------------------------------------------------------------------------
    -- Set Tool Tip:
    --------------------------------------------------------------------------------
    manager.menubar:setTooltip(config.appName .. " " .. config.appVersion .. " (" .. config.appBuild .. ")")

    --------------------------------------------------------------------------------
    -- Work out Menubar Display Mode:
    --------------------------------------------------------------------------------
    manager.updateMenubarIcon()

    manager.menubar:setMenu(manager.generateMenuTable)

    return manager
end

--- plugins.core.menu.manager.disable(priority) -> menubaritem
--- Function
--- Removes the menu from the system menu bar.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the menubaritem
function manager.disable()
    if manager.menubar then
        return manager.menubar:removeFromMenuBar()
    end
end

--- plugins.core.menu.manager.enable(priority) -> menubaritem
--- Function
--- Returns the previously removed menu back to the system menu bar.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the menubaritem
function manager.enable()
    if manager.menubar then
        return manager.menubar:returnToMenuBar()
    end
end

--- plugins.core.menu.manager.updateMenubarIcon(priority) -> none
--- Function
--- Updates the Menubar Icon
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function manager.updateMenubarIcon()
    if not manager.menubar then
        return
    end

    local displayMenubarAsIcon = manager.displayMenubarAsIcon()

    local title = config.appName
    local icon = nil

    if displayMenubarAsIcon then
        local iconImage = image.imageFromPath(config.menubarIconPath)
        icon = iconImage:setSize({w=18,h=18})
        title = ""
    end

    --------------------------------------------------------------------------------
    -- Add any Title Suffix's:
    --------------------------------------------------------------------------------
    local titleSuffix = ""
    for _,v in ipairs(manager.titleSuffix) do

        if type(v) == "function" then
            titleSuffix = titleSuffix .. v()
        end

    end

    title = title .. titleSuffix

    manager.menubar:setIcon(icon)
    --------------------------------------------------------------------------------
    -- Issue #406:
    -- For some reason setting the title to " " temporarily fixes El Capitan.
    --------------------------------------------------------------------------------
    manager.menubar:setTitle(" ")
    manager.menubar:setTitle(title)

end

--- plugins.core.menu.manager.displayMenubarAsIcon <cp.prop: boolean>
--- Field
--- If `true`, the menubar item will be the app icon. If not, it will be the app name.
manager.displayMenubarAsIcon = config.prop("displayMenubarAsIcon", true):watch(manager.updateMenubarIcon)

--- plugins.core.menu.manager.addSection(priority) -> section
--- Function
--- Creates a new menu section, which can have items and sub-menus added to it.
---
--- Parameters:
---  * priority - The priority order of menu items created in the section relative to other sections.
---
--- Returns:
---  * section - The section that was created.
function manager.addSection(priority)
    return manager.rootSection:addSection(priority)
end

--- plugins.core.menu.manager.addTitleSuffix(fnTitleSuffix)
--- Function
--- Allows you to add a custom Suffix to the Menubar Title
---
--- Parameters:
---  * fnTitleSuffix - A function that returns a single string
---
--- Returns:
---  * None
function manager.addTitleSuffix(fnTitleSuffix)
    manager.titleSuffix[#manager.titleSuffix + 1] = fnTitleSuffix
    manager.updateMenubarIcon()
end

--- plugins.core.menu.manager.generateMenuTable()
--- Function
--- Generates the Menu Table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Menu Table
function manager.generateMenuTable()
    return manager.rootSection:generateMenuTable()
end


local plugin = {
    id          = "core.menu.manager",
    group       = "core",
    required    = true,
    dependencies    = {
        ["core.preferences.panels.menubar"]     = "prefs",
        ["core.preferences.manager"]            = "prefsManager",
        ["core.controlsurfaces.manager"]        = "controlSurfaces",
        ["core.toolbox.manager"]              = "toolbox",
    }
}

function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Plugin Dependancies:
    --------------------------------------------------------------------------------
    local prefs = deps.prefs
    local prefsManager = deps.prefsManager
    local controlSurfaces = deps.controlSurfaces
    local toolbox = deps.toolbox

    --------------------------------------------------------------------------------
    -- Setup Menubar Manager:
    --------------------------------------------------------------------------------
    manager.init()
    manager.enable()

    --------------------------------------------------------------------------------
    -- Top Section:
    --------------------------------------------------------------------------------
    manager.top = manager.addSection(1)

    --------------------------------------------------------------------------------
    -- Bottom Section:
    --------------------------------------------------------------------------------
    manager.bottom = manager.addSection(9999999)
        :addItem(0, function()
            return { title = "-" }
        end)

    --------------------------------------------------------------------------------
    -- Tools Section:
    --------------------------------------------------------------------------------
    local tools = manager.addSection(7777777)
    local toolsEnabled = config.prop("menubarToolsEnabled", true)
    tools:setDisabledFn(function() return not toolsEnabled() end)
    tools:addHeading(i18n("tools"))
    prefs:addCheckbox(105,
        {
            label = i18n("show") .. " " .. i18n("tools"),
            onchange = function(_, params) toolsEnabled(params.checked) end,
            checked = toolsEnabled,
        }
    )
    manager.tools = tools

    --------------------------------------------------------------------------------
    -- Help & Support Section:
    --------------------------------------------------------------------------------
    local helpAndSupport = manager.addSection(8888888)
    local helpAndSupportEnabled = config.prop("menubarHelpEnabled", true)
    helpAndSupport:setDisabledFn(function() return not helpAndSupportEnabled() end)
    helpAndSupport:addHeading(i18n("helpAndSupport"))
    prefs:addCheckbox(104,
        {
            label = i18n("show") .. " " .. i18n("helpAndSupport"),
            onchange = function(_, params) helpAndSupportEnabled(params.checked) end,
            checked = helpAndSupportEnabled,
        }
    )
    manager.helpAndSupport = helpAndSupport

    --------------------------------------------------------------------------------
    -- Help & Support > CommandPost Section:
    --------------------------------------------------------------------------------
    manager.commandPostHelpAndSupport = helpAndSupport:addMenu(10, function() return i18n("appName") end)

    --------------------------------------------------------------------------------
    -- Help & Support > Apple Section:
    --------------------------------------------------------------------------------
    manager.appleHelpAndSupport = helpAndSupport:addMenu(20, function() return i18n("apple") end)

    --------------------------------------------------------------------------------
    -- Settings Section:
    --------------------------------------------------------------------------------
    manager.settings = manager.bottom
        :addHeading(i18n("settings"))
        :addItem(10.1, function()
            return { title = i18n("preferences"), fn = prefsManager.show }
        end)
        :addItem(10.2, function()
            return { title = i18n("controlSurfaces"), fn = controlSurfaces.show }
        end)
        :addItem(10.3, function()
            return { title = "-" }
        end)
        :addItem(10.4, function()
            return { title = i18n("toolbox"), fn = toolbox.show }
        end)
        :addItem(11, function()
            return { title = "-" }
        end)

    --------------------------------------------------------------------------------
    -- Restart Menu Item:
    --------------------------------------------------------------------------------
    manager.bottom:addSeparator(9999999):addItem(10000000, function()
        return { title = i18n("restart"),  fn = hs.reload }
    end)

    --------------------------------------------------------------------------------
    -- Quit Menu Item:
    --------------------------------------------------------------------------------
    manager.bottom:addItem(99999999, function()
        return { title = i18n("quit"),  fn = function() config.application():kill() end }
    end)

    --------------------------------------------------------------------------------
    -- Version Info:
    --------------------------------------------------------------------------------
    manager.bottom:addItem(99999999.1, function()
            return { title = "-" }
        end)
    :addItem(99999999.2, function()
        return { title = i18n("version") .. ": " .. config.appVersion .. " (" .. config.appBuild .. ")", disabled = true }
    end)

    return manager
end

return plugin
