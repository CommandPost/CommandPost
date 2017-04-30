--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                 M E N U     M A N A G E R    P L U G I N                   --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.menu.manager ===
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
local fcp										= require("cp.apple.finalcutpro")

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
	manager.menubar:setTooltip(config.appName .. " " .. i18n("version") .. " " .. config.appVersion)

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
	for i, v in ipairs(manager.titleSuffix) do

		if type(v) == "function" then
			titleSuffix = titleSuffix .. v()
		end

	end

	title = title .. titleSuffix

	manager.menubar:setIcon(icon)
	-- HACK for #406: For some reason setting the title to " " temporarily fixes El Capitan
	manager.menubar:setTitle(" ")
	manager.menubar:setTitle(title)

end

--- plugins.core.menu.manager.displayMenubarAsIcon <cp.prop: boolean>
--- Field
--- If `true`, the menubar item will be the app icon. If not, it will be the app name.
manager.displayMenubarAsIcon = config.prop("displayMenubarAsIcon", DEFAULT_DISPLAY_MENUBAR_AS_ICON):watch(manager.updateMenubarIcon)


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

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id			= "core.menu.manager",
	group		= "core",
	required	= true,
	dependencies	= {
		["core.welcome.manager"] 			= "welcome",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)

	local welcome = deps.welcome

	welcome.enableInterfaceCallback:new("menumanager", function()
		if manager.menubar then
			manager.enable()
		else
			manager.init()
		end
	end)

	welcome.disableInterfaceCallback:new("menumanager", function()
		manager.disable()
	end)

	return manager
end

return plugin