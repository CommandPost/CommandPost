--- hs.finalcutpro.MenuBar
---
--- Represents the Final Cut Pro X menu bar, providing functions that allow different tasks to be accomplished.
---
--- Author: David Peterson (david@randombits.org)
---

--- Standard Modules
local log											= require("hs.logger").new("menubar")
local json											= require("hs.json")

local MenuBar = {}

MenuBar.MENU_MAP_FILE								= "hs/finalcutpro/menumap.json"
MenuBar.ROLE										= "AXMenuBar"

--- hs.finalcutpro.MenuBar:new(App) -> MenuBar
--- Function
--- Constructs a new MenuBar for the specified App.
---
--- Parameters:
---  * app - The App instance the MenuBar belongs to.
---
--- Returns:
---  * a new MenuBar instance
---
function MenuBar:new(app)
	o = {
	  _app 		= app
	}
	setmetatable(o, self)
	self.__index = self
	return o
end

function MenuBar:app()
	return self._app
end

function MenuBar:UI()
	if not self._ui then
		self._ui = self:app():UI():childWithRole(MenuBar.ROLE)
	end
	return self._ui
end

function MenuBar:getMenuMap()
	if not MenuBar._menuMap then
		local file = io.open(MenuBar.MENU_MAP_FILE, "r")
		if file then
			local content = file:read("*all")
			file:close()
			MenuBar._menuMap = json.decode(content)
			log.d("Loaded menu map from '" .. MenuBar.MENU_MAP_FILE .. "'")
		else
			MenuBar._menuMap = {}
		end
	end
	return MenuBar._menuMap
end

--- hs.finalcutpro.MenuBar:select(...) -> boolean
--- Function
--- Selects a Final Cut Pro Menu Item based on the list of menu titles in English.
---
--- Parameters:
---  * ... - The list of menu items you'd like to activate, for example: 
---            select("View", "Browser", "as List")
---
--- Returns:
---  * True is successful otherwise Nil
---
function MenuBar:select(...)

	-- Start at the top of the menu bar list
	local menuMap = self:getMenuMap()
	local menuUI = self:UI()
	
	for i=1,select('#', ...) do
		step = select(i, ...)
		if menuMap and menuMap[step] then
			-- We have the menu name in our list
			local item = menuMap[step]
			menuUI = menuUI:childAt(item.id)
			menuMap = item.items
		else
			-- We don't have it in our list, so look it up manually. Hopefully they are in English!
			menuUI = menuUI:childWithTitle(step)
		end
		
		if menuUI then
			menuUI:press()
			-- Assign the contained AXMenu to the menuUI - it contains the next set of AXMenuItems
			menuUI = menuUI:childAt(1)
			assert(not menuUI or menuUI:attribute("AXRole") == "AXMenu")
		else
			log.d("Unable to find a menu called '"..step.."'.")
			return nil
		end
	end
	
	return true
end

--- hs.finalcutpro.MenuBar:generateMenuMap() -> boolean
--- Function
--- Generates a map of the menu bar and saves it in the location specified
--- in MenuBar.MENU_MAP_FILE.
---
--- Parameters:
---  * N/A
---
--- Returns:
---  * True is successful otherwise Nil
---
function MenuBar:generateMenuMap()
	local menuMap = self:_processMenuItems(self:UI())
	
	-- Opens a file in append mode
	file = io.open(MenuBar.MENU_MAP_FILE, "w")

	if file then
		file:write(json.encode(menuMap))
		file:close()
		return true
	end

	return nil
end

function MenuBar:_processMenuItems(menu)
	local count = menu:childCount()
	-- log.d("Count: "..count)
	if count then
		local items = {}
		for i = 1,count do
			local child = menu:childAt(i)
			local title = child:attribute("AXTitle")
			-- log.d("Title: "..inspect(title))
			if title and title ~= "" then
				local item = {id = i}
				local submenu = child:childAt(1)
				if submenu and submenu:attribute("AXRole") == "AXMenu" then
					local children = self:_processMenuItems(submenu)
					if children then
						item.items = children
					end
				end
				items[title] = item
			end
		end
		return items
	else
		return nil
	end
end

return MenuBar