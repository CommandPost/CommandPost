--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                 M E N U     M A N A G E R    P L U G I N                   --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === core.menu.manager ===
---
--- Menu Manager Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("menumgr")

local image										= require("hs.image")
local inspect									= require("hs.inspect")
local menubar									= require("hs.menubar")

local config									= require("cp.config")
local fcp										= require("cp.finalcutpro")

local section									= require("section")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local DEFAULT_DISPLAY_MENUBAR_AS_ICON 			= true

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local manager = {}

manager.rootSection = section:new()

manager.titleSuffix	= {}

--- core.menu.manager.init() -> none
--- Initialises the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
---
function manager.init()
	-------------------------------------------------------------------------------
	-- Set up Menubar:
	--------------------------------------------------------------------------------
	manager.menubar = menubar.newWithPriority(1)

	--------------------------------------------------------------------------------
	-- Set Tool Tip:
	--------------------------------------------------------------------------------
	manager.menubar:setTooltip(config.scriptName .. " " .. i18n("version") .. " " .. config.scriptVersion)

	--------------------------------------------------------------------------------
	-- Work out Menubar Display Mode:
	--------------------------------------------------------------------------------
	manager.updateMenubarIcon()

	manager.menubar:setMenu(manager.generateMenuTable)

	return manager
end

--- core.menu.manager.updateMenubarIcon(priority) -> none
--- Updates the Menubar Icon
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
---
function manager.updateMenubarIcon()

	local displayMenubarAsIcon = config.get("displayMenubarAsIcon", DEFAULT_DISPLAY_MENUBAR_AS_ICON)

	local title = config.scriptName
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
	for i, v in ipairs(manager.titleSuffix) do

		if type(v) == "function" then
			titleSuffix = titleSuffix .. v()
		end

	end

	title = title .. titleSuffix

	manager.menubar:setIcon(icon)
	manager.menubar:setTitle(title)

end

--- core.menu.manager.addSection(priority) -> section
--- Creates a new menu section, which can have items and sub-menus added to it.
---
--- Parameters:
---  * priority - The priority order of menu items created in the section relative to other sections.
---
--- Returns:
---  * section - The section that was created.
---
function manager.addSection(priority)
	return manager.rootSection:addSection(priority)
end

--- core.menu.manager.addTitleSuffix(fnTitleSuffix)
--- Allows you to add a custom Suffix to the Menubar Title
---
--- Parameters:
---  * fnTitleSuffix - A function that returns a single string
---
--- Returns:
---  * None
---
function manager.addTitleSuffix(fnTitleSuffix)

	manager.titleSuffix[#manager.titleSuffix + 1] = fnTitleSuffix

end

--- core.menu.manager.generateMenuTable()
--- Generates the Menu Table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Menu Table
---
function manager.generateMenuTable()
	return manager.rootSection:generateMenuTable()
end

--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
--
--------------------------------------------------------------------------------
local plugin = {
	id			= "core.menu.manager",
	group		= "core",
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init()
	return manager
end

return plugin