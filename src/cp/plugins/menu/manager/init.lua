--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--               M E N U     M A N A G E R    L I B R A R Y                   --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Module created by David Peterson (https://github.com/randomeizer).
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

local menubar									= require("hs.menubar")
local image										= require("hs.image")
local inspect									= require("hs.inspect")

local metadata									= require("cp.metadata")
local fcp										= require("cp.finalcutpro")

local section									= require("cp.plugins.menu.manager.section")

local log										= require("hs.logger").new("menumanager")

local manager = {}

manager.rootSection = section:new()

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
manager.PROXY_QUALITY		= 4
manager.PROXY_ICON			= "🔴"
manager.ORIGINAL_QUALITY	= 5
manager.ORIGINAL_ICON		= "🔵"

function manager.updateMenubarIcon()
	local displayMenubarAsIcon = metadata.get("displayMenubarAsIcon", false)
	local enableProxyMenuIcon = metadata.get("enableProxyMenuIcon", false)

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

--- hs.fcpxhacks.plugins.menu.manager.addSection(prioroty) -> section
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

function manager.generateMenuTable()
	return manager.rootSection:generateMenuTable()
end

--- The Plugin
local plugin = {}

function plugin.init()
	return manager.init()
end

return plugin