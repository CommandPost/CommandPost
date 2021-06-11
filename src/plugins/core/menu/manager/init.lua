--- === plugins.core.menu.manager ===
---
--- Menu Manager Plugin.

local require           = require

local hs                = _G.hs

local image             = require "hs.image"
local menubar           = require "hs.menubar"

local config            = require "cp.config"
local i18n              = require "cp.i18n"

local section           = require "section"

local imageFromURL      = image.imageFromURL

local mod = {}

--- plugins.core.menu.manager.rootSection() -> section
--- Variable
--- A new Root Section
mod.rootSection = section:new()

--- plugins.core.menu.manager.titleSuffix() -> table
--- Variable
--- Table of Title Suffix's
mod.titleSuffix = {}

--- plugins.core.menu.manager.init() -> none
--- Function
--- Initialises the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init()
    -------------------------------------------------------------------------------
    -- Set up Menubar:
    --------------------------------------------------------------------------------
    mod.menubar = menubar.new()

    --------------------------------------------------------------------------------
    -- Set Tool Tip:
    --------------------------------------------------------------------------------
    mod.menubar:setTooltip(config.appName .. " " .. config.appVersion .. " (" .. config.appBuild .. ")")

    --------------------------------------------------------------------------------
    -- Work out Menubar Display Mode:
    --------------------------------------------------------------------------------
    mod.updateMenubarIcon()

    mod.menubar:setMenu(mod.generateMenuTable)

    return mod
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
function mod.disable()
    if mod.menubar then
        return mod.menubar:removeFromMenuBar()
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
function mod.enable()
    if mod.menubar then
        return mod.menubar:returnToMenuBar()
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
function mod.updateMenubarIcon()
    if not mod.menubar then
        return
    end

    local displayMenubarAsIcon = mod.displayMenubarAsIcon()

    local title = mod._prefs.menubarLabel()
    local icon = nil

    if displayMenubarAsIcon then
        local encoded = mod._prefs.menubarIcon().encoded
        local iconImage = imageFromURL(encoded)
        icon = iconImage:setSize({w=18,h=18})
        title = ""
    end

    --------------------------------------------------------------------------------
    -- Add any Title Suffix's:
    --------------------------------------------------------------------------------
    local titleSuffix = ""
    for _,v in ipairs(mod.titleSuffix) do

        if type(v) == "function" then
            titleSuffix = titleSuffix .. v()
        end

    end

    title = title .. titleSuffix

    mod.menubar:setIcon(icon)
    --------------------------------------------------------------------------------
    -- Issue #406:
    -- For some reason setting the title to " " temporarily fixes El Capitan.
    --------------------------------------------------------------------------------
    mod.menubar:setTitle(" ")
    mod.menubar:setTitle(title)

end

--- plugins.core.menu.manager.displayMenubarAsIcon <cp.prop: boolean>
--- Field
--- If `true`, the menubar item will be the app icon. If not, it will be the app name.
mod.displayMenubarAsIcon = config.prop("displayMenubarAsIcon", true):watch(mod.updateMenubarIcon)

--- plugins.core.menu.manager.addSection(priority) -> section
--- Function
--- Creates a new menu section, which can have items and sub-menus added to it.
---
--- Parameters:
---  * priority - The priority order of menu items created in the section relative to other sections.
---
--- Returns:
---  * section - The section that was created.
function mod.addSection(priority)
    return mod.rootSection:addSection(priority)
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
function mod.addTitleSuffix(fnTitleSuffix)
    mod.titleSuffix[#mod.titleSuffix + 1] = fnTitleSuffix
    mod.updateMenubarIcon()
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
function mod.generateMenuTable()
    return mod.rootSection:generateMenuTable()
end

-- Makes the `section` API accessible outside the menu manger.
mod.section = section

local plugin = {
    id          = "core.menu.manager",
    group       = "core",
    required    = true,
    dependencies    = {
        ["core.preferences.panels.menubar"]     = "prefs",
        ["core.preferences.manager"]            = "prefsManager",
        ["core.controlsurfaces.manager"]        = "controlSurfaces",
        ["core.toolbox.manager"]                = "toolbox",
    }
}

function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Plugin Dependancies:
    --------------------------------------------------------------------------------
    local prefs = deps.prefs.panel
    local prefsManager = deps.prefsManager
    local controlSurfaces = deps.controlSurfaces
    local toolbox = deps.toolbox

    --------------------------------------------------------------------------------
    -- Watch for menubar label and icon changes in Preferences panel:
    --------------------------------------------------------------------------------
    mod._prefs = deps.prefs
    mod._prefs.menubarLabel:watch(mod.updateMenubarIcon)
    mod._prefs.menubarIcon:watch(mod.updateMenubarIcon)

    --------------------------------------------------------------------------------
    -- Setup Menubar Manager:
    --------------------------------------------------------------------------------
    mod.init()
    mod.enable()

    --------------------------------------------------------------------------------
    -- Top Section:
    --------------------------------------------------------------------------------
    mod.top = mod.addSection(1)

    --------------------------------------------------------------------------------
    -- Bottom Section:
    --------------------------------------------------------------------------------
    mod.bottom = mod.addSection(9999999)
        :addItem(0, function()
            return { title = "-" }
        end)

    --------------------------------------------------------------------------------
    -- Tools Section:
    --------------------------------------------------------------------------------
    local tools = mod.addSection(7777777)
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
    mod.tools = tools

    --------------------------------------------------------------------------------
    -- Help & Support Section:
    --------------------------------------------------------------------------------
    local helpAndSupport = mod.addSection(8888888)
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
    mod.helpAndSupport = helpAndSupport

    --------------------------------------------------------------------------------
    -- Help & Support > CommandPost Section:
    --------------------------------------------------------------------------------
    mod.commandPostHelpAndSupport = helpAndSupport:addMenu(10, function() return i18n("appName") end)

    --------------------------------------------------------------------------------
    -- Help & Support > Apple Section:
    --------------------------------------------------------------------------------
    mod.appleHelpAndSupport = helpAndSupport:addMenu(20, function() return i18n("apple") end)

    --------------------------------------------------------------------------------
    -- Settings Section:
    --------------------------------------------------------------------------------
    mod.settings = mod.bottom
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
    mod.bottom:addSeparator(9999999):addItem(10000000, function()
        return { title = i18n("restart"),  fn = hs.reload }
    end)

    --------------------------------------------------------------------------------
    -- Quit Menu Item:
    --------------------------------------------------------------------------------
    mod.bottom:addItem(99999999, function()
        return { title = i18n("quit"),  fn = function() config.application():kill() end }
    end)

    --------------------------------------------------------------------------------
    -- Version Info:
    --------------------------------------------------------------------------------
    mod.bottom:addItem(99999999.1, function()
            return { title = "-" }
        end)
    :addItem(99999999.2, function()
        return { title = i18n("version") .. ": " .. config.appVersion .. " (" .. config.appBuild .. ")", disabled = true }
    end)

    return mod
end

return plugin
