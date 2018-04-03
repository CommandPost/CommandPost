--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                             S E C T I O N                                  --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.menu.manager.section ===
---
--- Controls sections for the CommandPost menu.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log									= require("hs.logger").new("section")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local fnutils 								= require("hs.fnutils")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local section = {}

--- plugins.core.menu.manager.section.DEFAULT_PRIORITY -> number
--- Constant
--- The default priority
section.DEFAULT_PRIORITY = 0

--- plugins.core.menu.manager.section.WARNING_LIMIT -> number
--- Constant
--- The limit of how much time a menu item takes to load before we post warnings to the Error Log
section.WARNING_LIMIT = 0.005

--- plugins.core.menu.manager.section:new() -> section
--- Method
--- Creates a new menu section, which can have items and sub-menus added to it.
---
--- Parameters:
---  * None
---
--- Returns:
---  * section - The section that was created.
function section:new()
    local o = {
        _generators = {}
    }
    setmetatable(o, self)
    self.__index = self

    return o
end

--- plugins.core.menu.manager.section:setDisabledFn(disabledFn) -> none
--- Method
--- Sets the Disabled Function
---
--- Parameters:
---  * disabledFn - The disabled function.
---
--- Returns:
---  * None
function section:setDisabledFn(disabledFn)
    self._disabledFn = disabledFn
end

--- plugins.core.menu.manager.section:isDisabled() -> voolean
--- Method
--- Gets the disabled status
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if the section is disabled, otherwise `false`
function section:isDisabled()
    return self._disabledFn and self._disabledFn()
end

--- plugins.core.menu.manager.section:_addGenerator() -> section
--- Method
--- A private method for registering a generator. This should not be called directly.
---
--- Parameters:
---  * `generator`	- The generator being added.
---
--- Returns:
---  * section - The section.
function section:_addGenerator(generator)
    self._generators[#self._generators + 1] = generator
    table.sort(self._generators, function(a, b) return a.priority < b.priority end)
    return self
end

--- plugins.core.menu.manager.section:addItem(priority, itemFn) -> section
--- Method
--- Registers a function which will generate a single table item.
---
--- Parameters:
---  * `priority`	- The priority of the item within the section. Lower numbers appear first.
---  * `itemFn`		- A function which will return a table representing a single menu item. See `hs.menubar` for details.
---
--- Returns:
---  * section - The section the item was added to.
function section:addItem(priority, itemFn)
    priority = priority or section.DEFAULT_PRIORITY
    self:_addGenerator({
        priority = priority,
        itemFn = itemFn
    })
    return self
end

--- plugins.core.menu.manager.section:addItems(priority, itemsFn) -> section
--- Method
--- Registers a function which will generate multiple table items.
---
--- Parameters:
---  * `priority`	- The priority of the items within the section. Lower numbers appear first.
---  * `itemsFn`	- A function which will return a table containing multiple table items. See `hs.menubar` for details.
---
--- Returns:
---  * section - The section the item was added to.
function section:addItems(priority, itemsFn)
    priority = priority or section.DEFAULT_PRIORITY
    self:_addGenerator({
        priority = priority,
        itemsFn = itemsFn
    })
    return self
end

--- plugins.core.menu.manager.section:addSeparator(priority) -> section
--- Method
--- Adds a new seperator with specified priority.
---
--- Parameters:
---  * `priority`	- The priority of the items within the section. Lower numbers appear first.
---
--- Returns:
---  * section - The new section that was created.
function section:addSeparator(priority)
    return self:addItem(priority, function()
        return { title = "-" }
    end)
end

--- plugins.core.menu.manager.section:addMenu(priority, titleFn) -> section
--- Method
--- Adds a new sub-menu with the specified priority. The section that will contain
--- the items in the menu is returned.
---
--- Parameters:
---  * `priority`	- The priority of the item within the section. Lower numbers appear first.
---  * `titleFn`	- The function which will return the menu title.
---
--- Returns:
---  * section - The new section that was created.
function section:addMenu(priority, titleFn)
    local menuSection = section:new()
    self:addItem(priority, function()
        local title = titleFn()
        local menuTable = menuSection:generateMenuTable()
        local disabled = menuTable == nil or #menuTable == 0
        return { title = title, menu = menuTable, disabled = disabled }
    end)
    return menuSection
end

--- plugins.core.menu.manager.section:addSection(priority, itemFn) -> section
--- Method
--- Adds a new sub-section with the specified priority. The new sub-section is returned.
---
--- Parameters:
---  * `priority`	- The priority of the item within the section. Lower numbers appear first.
---
--- Returns:
---  * section - The new section that was created.
function section:addSection(priority)
    priority = priority or section.DEFAULT_PRIORITY
    local newSection = section:new()
    self:_addGenerator({
        priority = priority,
        section = newSection
    })
    return newSection
end

--- plugins.core.menu.manager.section:generateTable() -> table
--- Method
--- Generates a new menu table based on the registered items and sections inside this section.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `table`	- The menu table for this section. See `hs.menubar` for details on the format.
function section:generateMenuTable()
    if self:isDisabled() then
        return nil
    end
    local menuTable = {}
    for _,generator in ipairs(self._generators) do
        if generator.itemFn then
            local item = generator.itemFn()
            if item then
                menuTable[#menuTable + 1] = item
            end
        elseif generator.section then
            local items = generator.section:generateMenuTable()
            if items then
                fnutils.concat(menuTable, items)
            end
        elseif generator.itemsFn then
            local items = generator.itemsFn()
            if items then
                fnutils.concat(menuTable, items)
            end
        end
    end
    return menuTable
end

return section