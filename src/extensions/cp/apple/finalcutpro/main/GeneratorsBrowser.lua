--- === cp.apple.finalcutpro.main.GeneratorsBrowser ===
---
--- Generators Browser Module.

local require = require

-- local log								= require "hs.logger" .new "timline"

-- local inspect							= require "hs.inspect"

local just								= require "cp.just"
local prop								= require "cp.prop"
local axutils							= require "cp.ui.axutils"
local tools								= require "cp.tools"
local geometry							= require "hs.geometry"
local fnutils							= require "hs.fnutils"

local Group                             = require "cp.ui.Group"
local Table								= require "cp.ui.Table"
local ScrollArea						= require "cp.ui.ScrollArea"
local PopUpButton						= require "cp.ui.PopUpButton"
local TextField							= require "cp.ui.TextField"

local go                                = require "cp.rx.go"

local Do                                = go.Do
local WaitUntil                         = go.WaitUntil

local cache                             = axutils.cache
local childWithRole                     = axutils.childWithRole
local childMatching                     = axutils.childMatching

local ninjaDoubleClick                  = tools.ninjaDoubleClick

local GeneratorsBrowser = Group:subclass("cp.apple.finalcutpro.main.GeneratorsBrowser")

--- cp.apple.finalcutpro.main.GeneratorsBrowser.TITLE -> string
--- Constant
--- Titles & Generators Title.
GeneratorsBrowser.static.TITLE = "Titles and Generators"

--- cp.apple.finalcutpro.main.GeneratorsBrowser(parent) -> GeneratorsBrowser
--- Constructor
--- Creates a new `GeneratorsBrowser` instance.
---
--- Parameters:
---  * app - The `cp.apple.finalcutpro` object.
---
--- Returns:
---  * A new `GeneratorsBrowser` object.
function GeneratorsBrowser:initialize(parent)
    Group.initialize(self, parent, parent.UI:mutate(function(original)
        if self:isShowing() then
            return cache(self, "_ui", function()
                return original()
            end)
        end
        return nil
    end))
end

-----------------------------------------------------------------------
--
-- GENERATORSBROWSER UI:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.GeneratorsBrowser.isShowing <cp.prop: boolean>
--- Variable
--- Is the Generators Browser showing?
function GeneratorsBrowser.lazy.prop:isShowing()
    return prop.new(function()
        local parent = self:parent()
        return parent:isShowing() and parent.showGenerators:checked()
    end)
end

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
    local menuBar = self:app().menu
    -----------------------------------------------------------------------
    -- Go there direct:
    -----------------------------------------------------------------------
    menuBar:selectMenu({"Window", "Go To", GeneratorsBrowser.TITLE})
    just.doUntil(function() return self:isShowing() end)
    return self
end

function GeneratorsBrowser.lazy.method:doShow()
    local menuBar = self:app().menu

    return Do(menuBar:doSelectMenu({"Window", "Go To", GeneratorsBrowser.TITLE}))
    :Then(WaitUntil(self.isShowing))
    :ThenYield()
    :Label("GeneratorsBrowser:doShow")
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

function GeneratorsBrowser.lazy.method:doHide()
    return Do(self:parent():doHide())
    :Label("GeneratorsBrowser:doHide")
end

-----------------------------------------------------------------------------
--
-- SECTIONS:
--
-----------------------------------------------------------------------------

--- cp.apple.finalcutpro.main.GeneratorsBrowser.mainGroupUI <cp.prop: axuielementObject>
--- Field
--- Main Group UI.
function GeneratorsBrowser.lazy.prop:mainGroupUI()
    return self.UI:mutate(function(original)
        return cache(self, "_mainGroup",
        function()
            local ui = original()
            return ui and childWithRole(ui, "AXSplitGroup")
        end)
    end)
end

--- cp.apple.finalcutpro.main.GeneratorsBrowser.sidebar <cp.ui.Table>
--- Field
--- The sidebar object.
function GeneratorsBrowser.lazy.value:sidebar()
    return Table(self, function()
        return childWithRole(self:mainGroupUI(), "AXScrollArea")
    end)
end

--- cp.apple.finalcutpro.main.GeneratorsBrowser.contents <cp.ui.ScrollArea>
--- Field
--- The Generators Browser Contents.
function GeneratorsBrowser.lazy.value:contents()
    return ScrollArea(self, function()
        local group = childMatching(self:mainGroupUI(), function(child)
            return child:attributeValue("AXRole") == "AXGroup" and #child == 1
        end)
        return group and group[1]
    end)
end

--- cp.apple.finalcutpro.main.GeneratorsBrowser.group <cp.ui.PopUpButton>
--- Field
--- The group.
function GeneratorsBrowser.lazy.value:group()
    return PopUpButton(self, function()
        return childMatching(self:UI(), PopUpButton.matches)
    end)
end

--- cp.apple.finalcutpro.main.GeneratorsBrowser.search <cp.ui.TextField>
--- Field
--- Gets the Search TextField object.
function GeneratorsBrowser.lazy.value:search()
    return TextField(self, function()
        return childMatching(self:mainGroupUI(), TextField.matches)
    end)
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
    if not self.sidebar:isShowing() then
        self:app().menu:selectMenu({"Window", "Show in Workspace", 1})
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
    return self.sidebar:rowsUI(function(row)
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
    self.group:selectItem(1)
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
        self.sidebar:selectRow(topCategories[1])
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
    Table.selectRow(self.sidebar:rowsUI(), {self:getTitlesRowLabel(), name})
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
        self.sidebar:selectRow(topCategories[2])
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
    Table.selectRow(self.sidebar:rowsUI(), {self:getGeneratorsRowLabel(), name})
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
    return self.contents:childrenUI()
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
    return self.contents:selectedChildrenUI()
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
        self.contents:showChild(itemUI)
        local frame = itemUI:attributeValue("AXFrame")
        local targetPoint = geometry.rect(frame).center
        ninjaDoubleClick(targetPoint)
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
    local contents = self.contents:childrenUI()
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
        layout.sidebar = self.sidebar:saveLayout()
        layout.contents = self.contents:saveLayout()
        layout.search = self.search:saveLayout()
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
        self.search:loadLayout(layout.search)
        self.sidebar:loadLayout(layout.sidebar)
        self.contents:loadLayout(layout.contents)
    end
end

return GeneratorsBrowser
