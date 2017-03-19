--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                 M E N U     M A N A G E R    P L U G I N                   --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("menumanager")

local image										= require("hs.image")
local inspect									= require("hs.inspect")
local menubar									= require("hs.menubar")

local metadata									= require("cp.metadata")
local fcp										= require("cp.finalcutpro")

local section									= require("cp.plugins.core.menu.manager.section")

--------------------------------------------------------------------------------
-- CONSTANTS:
--------------------------------------------------------------------------------
local DEFAULT_DISPLAY_MENUBAR_AS_ICON 			= true
local DEFAULT_ENABLE_PROXY_MENU_ICON 			= false

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------
local manager = {}

	manager.rootSection = section:new()

	manager.PROXY_QUALITY		= 4
	manager.PROXY_ICON			= "🔴"
	manager.ORIGINAL_QUALITY	= 5
	manager.ORIGINAL_ICON		= "🔵"

	-------------------------------------------------------------------------------
	-- INITIALISE MODULE:
	-------------------------------------------------------------------------------
	function manager.init()
		-------------------------------------------------------------------------------
		-- Set up Menubar:
		--------------------------------------------------------------------------------
		manager.menubar = menubar.newWithPriority(1)

		--------------------------------------------------------------------------------
		-- Set Tool Tip:
		--------------------------------------------------------------------------------
		manager.menubar:setTooltip(metadata.scriptName .. " " .. i18n("version") .. " " .. metadata.scriptVersion)

		--------------------------------------------------------------------------------
		-- Work out Menubar Display Mode:
		--------------------------------------------------------------------------------
		manager.updateMenubarIcon()

		manager.menubar:setMenu(manager.generateMenuTable)

		return manager
	end

	--------------------------------------------------------------------------------
	-- UPDATE MENUBAR ICON:
	--------------------------------------------------------------------------------
	function manager.updateMenubarIcon()
		local displayMenubarAsIcon = metadata.get("displayMenubarAsIcon", DEFAULT_DISPLAY_MENUBAR_AS_ICON)
		local enableProxyMenuIcon = metadata.get("enableProxyMenuIcon", DEFAULT_ENABLE_PROXY_MENU_ICON)

		local title = metadata.scriptName
		local icon = nil

		if displayMenubarAsIcon then
			local iconImage = image.imageFromPath(metadata.menubarIconPath)
			icon = iconImage:setSize({w=18,h=18})
			title = ""
		end

		if enableProxyMenuIcon then
			local FFPlayerQuality = fcp:getPreference("FFPlayerQuality")
			if FFPlayerQuality == manager.PROXY_QUALITY then
				title = title .. " " .. manager.PROXY_ICON
			else
				title = title .. " " .. manager.ORIGINAL_ICON
			end
		end

		manager.menubar:setIcon(icon)
		manager.menubar:setTitle(title)
	end

	--- cp.plugins.core.menu.manager.addSection(priority) -> section
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

	--------------------------------------------------------------------------------
	-- GENERATE MENU TABLE:
	--------------------------------------------------------------------------------
	function manager.generateMenuTable()
		return manager.rootSection:generateMenuTable()
	end

--------------------------------------------------------------------------------
-- THE PLUGIN:
--------------------------------------------------------------------------------
local plugin = {}

	--------------------------------------------------------------------------------
	-- INITIALISE PLUGIN:
	--------------------------------------------------------------------------------
	function plugin.init()
		return manager.init()
	end

return plugin