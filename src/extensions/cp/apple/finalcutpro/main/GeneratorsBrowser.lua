--- === cp.apple.finalcutpro.main.GeneratorsBrowser ===
---
--- Generators Browser Module.

local require = require

-- local log								= require("hs.logger").new("timline")

-- local inspect							= require("hs.inspect")

local just								= require("cp.just")
local prop								= require("cp.prop")
local axutils							= require("cp.ui.axutils")
local tools								= require("cp.tools")
local geometry							= require("hs.geometry")
local fnutils							= require("hs.fnutils")

local Table								= require("cp.ui.Table")
local ScrollArea						= require("cp.ui.ScrollArea")
local PopUpButton						= require("cp.ui.PopUpButton")
local TextField							= require("cp.ui.TextField")

local cache                             = axutils.cache
local childWithRole, childMatching      = axutils.childWithRole, axutils.childMatching

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local GeneratorsBrowser = {}

--- cp.apple.finalcutpro.main.GeneratorsBrowser.TITLE -> string
--- Constant
--- Titles & Generators Title.
GeneratorsBrowser.TITLE = "Titles and Generators"

--- cp.apple.finalcutpro.main.GeneratorsBrowser.new(parent) -> GeneratorsBrowser
--- Constructor
--- Creates a new `GeneratorsBrowser` instance.
---
--- Parameters:
---  * app - The `cp.apple.finalcutpro` object.
---
--- Returns:
---  * A new `GeneratorsBrowser` object.
function GeneratorsBrowser.new(parent)
    local o = {_parent = parent}
    return prop.extend(o, GeneratorsBrowser)
end

--- cp.apple.finalcutpro.main.GeneratorsBrowser:parent() -> parent
--- Method
--- Returns the parent object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * parent
function GeneratorsBrowser:parent()
    return self._parent
end

--- cp.apple.finalcutpro.main.GeneratorsBrowser:app() -> App
--- Method
--- Returns the app instance representing Final Cut Pro.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function GeneratorsBrowser:app()
    return self:parent():app()
end

-----------------------------------------------------------------------
--
-- GENERATORSBROWSER UI:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.GeneratorsBrowser:UI() -> axuielementObject
--- Method
--- Gets the Generator Browser UI.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `axuielementObject`
function GeneratorsBrowser:UI()
    if self:isShowing() then
        return cache(self, "_ui", function()
            return self:parent():UI()
        end)
    end
    return nil
end

--- cp.apple.finalcutpro.main.GeneratorsBrowser.isShowing <cp.prop: boolean>
--- Variable
--- Is the Generators Browser showing?
GeneratorsBrowser.isShowing = prop.new(function(self)
    local parent = self:parent()
    return parent:isShowing() and parent:showGenerators():checked()
end):bind(GeneratorsBrowser)

--- cp.apple.finalcutpro.main.GeneratorsBrowser:show() -> GeneratorsBrowser
--- Method
--- Shows the Generators Browser.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `GeneratorsBrowser` instance.
function GeneratorsBrowser:show()
    local menuBar = self:app():menu()
    -----------------------------------------------------------------------
    -- Go there direct:
    -----------------------------------------------------------------------
    menuBar:selectMenu({"Window", "Go To", GeneratorsBrowser.TITLE})
    just.doUntil(function() return self:isShowing() end)
    return self
end

--- cp.apple.finalcutpro.main.GeneratorsBrowser:hide() -> GeneratorsBrowser
--- Method
--- Hides the Generators Browser.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `GeneratorsBrowser` instance.
function GeneratorsBrowser:hide()
    self:parent():hide()
    just.doWhile(function() return self:isShowing() end)
    return self
end

-----------------------------------------------------------------------------
--
-- SECTIONS:
--
-----------------------------------------------------------------------------

--- cp.apple.finalcutpro.main.GeneratorsBrowser:mainGroupUI() -> axuielementObject
--- Method
--- Main Group UI.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `axuielementObject` object.
function GeneratorsBrowser:mainGroupUI()
    return cache(self, "_mainGroup",
    function()
        local ui = self:UI()
        return ui and childWithRole(ui, "AXSplitGroup")
    end)
end

--- cp.apple.finalcutpro.main.GeneratorsBrowser:sidebar() -> Table
--- Method
--- Gets the sidebar object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `Table` object.
function GeneratorsBrowser:sidebar()
    if not self._sidebar then
        self._sidebar = Table(self, function()
            return childWithRole(self:mainGroupUI(), "AXScrollArea")
        end):uncached()
    end
    return self._sidebar
end

--- cp.apple.finalcutpro.main.GeneratorsBrowser:contents() -> ScrollArea
--- Method
--- Gets the Generators Browser Contents.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `ScrollArea` object.
function GeneratorsBrowser:contents()
    if not self._contents then
        self._contents = ScrollArea(self, function()
            local group = childMatching(self:mainGroupUI(), function(child)
                return child:role() == "AXGroup" and #child == 1
            end)
            return group and group[1]
        end)
    end
    return self._contents
end

--- cp.apple.finalcutpro.main.GeneratorsBrowser:group() -> PopUpButton
--- Method
--- Gets the group.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `PopUpButton` object.
function GeneratorsBrowser:group()
    if not self._group then
        self._group = PopUpButton(self, function()
            return childWithRole(self:UI(), "AXPopUpButton")
        end)
    end
    return self._group
end

--- cp.apple.finalcutpro.main.GeneratorsBrowser:search() -> PopUpButton
--- Method
--- Gets the Search Popup Button object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `PopUpButton` object.
function GeneratorsBrowser:search()
    if not self._search then
        self._search = TextField(self, function()
            return childWithRole(self:mainGroupUI(), "AXTextField")
        end)
    end
    return self._search
end

--- cp.apple.finalcutpro.main.GeneratorsBrowser:showSidebar() -> GeneratorsBrowser
--- Method
--- Ensures the sidebar is showing in the Generators & Titles panel.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `GeneratorsBrowser` object.
function GeneratorsBrowser:showSidebar()
    if not self:sidebar():isShowing() then
        self:app():menu():selectMenu({"Window", "Show in Workspace", 1})
    end
    return self
end

--- cp.apple.finalcutpro.main.GeneratorsBrowser:topCategoriesUI() -> table
--- Method
--- Returns an array of the top-level categories in the sidebar.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The array of category rows.
function GeneratorsBrowser:topCategoriesUI()
    return self:sidebar():rowsUI(function(row)
        return row:attributeValue("AXDisclosureLevel") == 0
    end)
end

--- cp.apple.finalcutpro.main.GeneratorsBrowser:showInstalledTitles() -> GeneratorsBrowser
--- Method
--- Ensures that the browser is showing 'Installed Titles'.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `GeneratorsBrowser` object.
function GeneratorsBrowser:showInstalledTitles()
    self:group():selectItem(1)
    return self
end

--- cp.apple.finalcutpro.main.GeneratorsBrowser:showInstalledGenerators() -> GeneratorsBrowser
--- Method
--- Ensures that the browser is showing 'Installed Generators'.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `GeneratorsBrowser` object.
function GeneratorsBrowser:showInstalledGenerators()
    self:showInstalledTitles()
    return self
end

--- cp.apple.finalcutpro.main.GeneratorsBrowser:getTitlesRowLabel() -> string
--- Method
--- Returns the label of the 'Titles' row in the current language.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The 'Titles' label.
function GeneratorsBrowser:getTitlesRowLabel()
    return self:app():string("project media sidebar titles row")
end

--- cp.apple.finalcutpro.main.GeneratorsBrowser:showAllTitles() -> GeneratorsBrowser
--- Method
--- Ensures the sidebar is showing in the Generators & Titles panel, focused on all 'Titles'.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `GeneratorsBrowser` object.
function GeneratorsBrowser:showAllTitles()
    self:showSidebar()
    local topCategories = self:topCategoriesUI()
    if topCategories and #topCategories == 2 then
        self:sidebar():selectRow(topCategories[1])
    end
    return self
end

--- cp.apple.finalcutpro.main.GeneratorsBrowser:showTitlesCategory(name) -> self
--- Method
--- Ensures the sidebar is showing and that the selected 'Titles' category is selected, if available.
---
--- Parameters:
---  * name - The category name, in the current language.
---
--- Returns:
---  * The Generators Browser.
function GeneratorsBrowser:showTitlesCategory(name)
    self:showSidebar()
    Table.selectRow(self:sidebar():rowsUI(), {self:getTitlesRowLabel(), name})
    return self
end

--- cp.apple.finalcutpro.main.GeneratorsBrowser:getGeneratorsRowLabel() -> string
--- Method
--- Gets a Generators Row Label.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Generators Row Label as string.
function GeneratorsBrowser:getGeneratorsRowLabel()
    return self:app():string("project media sidebar generators row")
end

--- cp.apple.finalcutpro.main.GeneratorsBrowser:showAllGenerators() -> GeneratorsBrowser
--- Method
--- Show All Generators.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `GeneratorsBrowser` object.
function GeneratorsBrowser:showAllGenerators()
    self:showSidebar()
    local topCategories = self:topCategoriesUI()
    if topCategories and #topCategories == 2 then
        self:sidebar():selectRow(topCategories[2])
    end
    return self
end

--- cp.apple.finalcutpro.main.GeneratorsBrowser:showGeneratorsCategory(name) -> GeneratorsBrowser
--- Method
--- Show a specific Generators Category.
---
--- Parameters:
---  * name - The name of the Generators Category to show.
---
--- Returns:
---  * The `GeneratorsBrowser` object.
function GeneratorsBrowser:showGeneratorsCategory(name)
    self:showSidebar()
    Table.selectRow(self:sidebar():rowsUI(), {self:getGeneratorsRowLabel(), name})
    return self
end

--- cp.apple.finalcutpro.main.GeneratorsBrowser:currentItemsUI() -> axuielementObject
--- Method
--- Gets the current items UI.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `axuielementObject` object.
function GeneratorsBrowser:currentItemsUI()
    return self:contents():childrenUI()
end

--- cp.apple.finalcutpro.main.GeneratorsBrowser:selectedItemsUI() -> axuielementObject
--- Method
--- Gets the selected items UI.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `axuielementObject` object.
function GeneratorsBrowser:selectedItemsUI()
    return self:contents():selectedChildrenUI()
end

--- cp.apple.finalcutpro.main.GeneratorsBrowser:itemIsSelected(itemUI) -> boolean
--- Method
--- Checks to see if an item is selected.
---
--- Parameters:
---  * itemUI - A `axuielementObject` to check.
---
--- Returns:
---  * `true` if the item is selected, otherwise `false`.
function GeneratorsBrowser:itemIsSelected(itemUI)
    local selectedItems = self:selectedItemsUI()
    if selectedItems and #selectedItems > 0 then
        for _,selected in ipairs(selectedItems) do
            if selected == itemUI then
                return true
            end
        end
    end
    return false
end

--- cp.apple.finalcutpro.main.GeneratorsBrowser:applyItem(itemUI) -> GeneratorsBrowser
--- Method
--- Applies an item by double clicking on it.
---
--- Parameters:
---  * itemUI - The `axuielementObject` of the item you want to apply.
---
--- Returns:
---  * The `GeneratorsBrowser` object.
function GeneratorsBrowser:applyItem(itemUI)
    if itemUI then
        self:contents():showChild(itemUI)
        local targetPoint = geometry.rect(itemUI:frame()).center
        tools.ninjaDoubleClick(targetPoint)
    end
    return self
end

--- cp.apple.finalcutpro.main.GeneratorsBrowser:getCurrentTitles() -> table
--- Method
--- Returns the list of titles for all generators currently visible.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table
function GeneratorsBrowser:getCurrentTitles()
    local contents = self:contents():childrenUI()
    if contents ~= nil then
        return fnutils.map(contents, function(child)
            return child:attributeValue("AXTitle")
        end)
    end
    return nil
end

--------------------------------------------------------------------------------
--
-- LAYOUTS:
--
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.main.GeneratorsBrowser:saveLayout() -> table
--- Method
--- Saves the current Generators Browser layout to a table.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table containing the current Effects Browser Layout.
function GeneratorsBrowser:saveLayout()
    local layout = {}
    if self:isShowing() then
        layout.showing = true
        layout.sidebar = self:sidebar():saveLayout()
        layout.contents = self:contents():saveLayout()
        layout.search = self:search():saveLayout()
    end
    return layout
end

--- cp.apple.finalcutpro.main.GeneratorsBrowser:loadLayout(layout) -> none
--- Method
--- Loads a Generators Browser layout.
---
--- Parameters:
---  * layout - A table containing the Generators Browser layout settings - created using `cp.apple.finalcutpro.main.GeneratorsBrowser:saveLayout()`.
---
--- Returns:
---  * None
function GeneratorsBrowser:loadLayout(layout)
    if layout and layout.showing then
        self:show()
        self:search():loadLayout(layout.search)
        self:sidebar():loadLayout(layout.sidebar)
        self:contents():loadLayout(layout.contents)
    end
end

return GeneratorsBrowser
