--- === plugins.core.menu.manager.section ===
---
--- Controls sections for the CommandPost menu.

local require = require

local config = require("cp.config")

local fnutils = require("hs.fnutils")


local section = {}

--- plugins.core.menu.manager.section.DEFAULT_PRIORITY -> number
--- Constant
--- The default priority
section.DEFAULT_PRIORITY = 1

--- plugins.core.menu.manager.section.SECTION_DISABLED_PREFERENCES_KEY_PREFIX -> string
--- Constant
--- The preferences key prefix for a disabled section.
section.SECTION_DISABLED_PREFERENCES_KEY_PREFIX = "menubar.sectionDisabled."

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

--- plugins.core.menu.manager.section:setDisabledPreferenceKey(key) -> self
--- Method
--- Sets the Disabled Preferences Key.
---
--- Parameters:
---  * key - A string which contains the unique preferences key.
---
--- Returns:
---  * Self
function section:setDisabledPreferenceKey(key)
    self._key = key
    return self
end

--- plugins.core.menu.manager.section:setDisabledFn(disabledFn) -> self
--- Method
--- Sets the Disabled Function
---
--- Parameters:
---  * disabledFn - The disabled function.
---
--- Returns:
---  * Self
function section:setDisabledFn(disabledFn)
    self._disabledFn = disabledFn
    return self
end

--- plugins.core.menu.manager.section:getDisabledPreferenceKey() -> string
--- Method
--- Gets the disabled preferences key.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if the section has a disabled preferences key defined, otherwise `false`.
function section:getDisabledPreferenceKey()
    return self._key
end

--- plugins.core.menu.manager.section:isDisabled() -> boolean
--- Method
--- Gets the disabled status
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if the section is disabled, otherwise `false`
function section:isDisabled()
    return (self._key and config.get(section.SECTION_DISABLED_PREFERENCES_KEY_PREFIX .. self._key, false)) or (self._disabledFn and self._disabledFn())
end

-- plugins.core.menu.manager.section:_addGenerator() -> section
-- Method
-- A private method for registering a generator. This should not be called directly.
--
-- Parameters:
--  * `generator`	- The generator being added.
--
-- Returns:
--  * section - The section.
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

--- plugins.core.menu.manager.section:addHeading(title) -> section
--- Method
--- Adds a heading to the top of a section.
---
--- Parameters:
---  * title - The title of the heading.
---
--- Returns:
---  * section - The new section that was created.
function section:addHeading(title)
    title = title and string.upper(title) or "TITLE MISSING"
    self
        :addSeparator(0.1)
        :addItem(0.2, function()
            if config.get("showSectionHeadingsInMenubar", false) then
                return {
                    title = title,
                    disabled = true,
                }
            end
        end)
    return self
end

--- plugins.core.menu.manager.section:addApplicationHeading(title) -> section
--- Method
--- Adds a heading to the top of the section.
---
--- Parameters:
---  * title - The title of the Application Heading.
---
--- Returns:
---  * section - The new section that was created.
function section:addApplicationHeading(title)
    self._isApplicationHeading = true
    title = title or "APPLICATION TITLE MISSING"
    self
        :addItem(0.00001, function()
            return {
                title = title,
                disabled = true,
            }
        end)
        :addSeparator(0.00002)
    return self
end

--- plugins.core.menu.manager.section:isApplicationHeading() -> boolean
--- Method
--- Does this section contain an application heading?
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if it does contain an application heading, otherwise `false`.
function section:isApplicationHeading()
    return self._isApplicationHeading
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
