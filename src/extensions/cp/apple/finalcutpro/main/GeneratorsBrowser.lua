--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.main.GeneratorsBrowser ===
---
--- Generators Browser Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
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

local id								= require("cp.apple.finalcutpro.ids") "GeneratorsBrowser"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local GeneratorsBrowser = {}

GeneratorsBrowser.TITLE = "Titles and Generators"

-- TODO: Add documentation
function GeneratorsBrowser.new(parent)
    local o = {_parent = parent}
    return prop.extend(o, GeneratorsBrowser)
end

-- TODO: Add documentation
function GeneratorsBrowser:parent()
    return self._parent
end

-- TODO: Add documentation
function GeneratorsBrowser:app()
    return self:parent():app()
end

-----------------------------------------------------------------------
--
-- GENERATORSBROWSER UI:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function GeneratorsBrowser:UI()
    if self:isShowing() then
        return axutils.cache(self, "_ui", function()
            return self:parent():UI()
        end)
    end
    return nil
end

-- TODO: Add documentation
GeneratorsBrowser.isShowing = prop.new(function(self)
    local parent = self:parent()
    return parent:isShowing() and parent:showGenerators():checked()
end):bind(GeneratorsBrowser)

-- TODO: Add documentation
function GeneratorsBrowser:show()
    local menuBar = self:app():menu()
    -- Go there direct
    menuBar:selectMenu({"Window", "Go To", GeneratorsBrowser.TITLE})
    just.doUntil(function() return self:isShowing() end)
    return self
end

-- TODO: Add documentation
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

-- TODO: Add documentation
function GeneratorsBrowser:mainGroupUI()
    return axutils.cache(self, "_mainGroup",
    function()
        local ui = self:UI()
        return ui and axutils.childWithRole(ui, "AXSplitGroup")
    end)
end

-- TODO: Add documentation
function GeneratorsBrowser:sidebar()
    if not self._sidebar then
        self._sidebar = Table.new(self, function()
            return axutils.childWithID(self:mainGroupUI(), id "Sidebar")
        end):uncached()
    end
    return self._sidebar
end

-- TODO: Add documentation
function GeneratorsBrowser:contents()
    if not self._contents then
        self._contents = ScrollArea:new(self, function()
            local group = axutils.childMatching(self:mainGroupUI(), function(child)
                return child:role() == "AXGroup" and #child == 1
            end)
            return group and group[1]
        end)
    end
    return self._contents
end

-- TODO: Add documentation
function GeneratorsBrowser:group()
    if not self._group then
        self._group = PopUpButton.new(self, function()
            return axutils.childWithRole(self:UI(), "AXPopUpButton")
        end)
    end
    return self._group
end

-- TODO: Add documentation
function GeneratorsBrowser:search()
    if not self._search then
        self._search = TextField.new(self, function()
            return axutils.childWithRole(self:mainGroupUI(), "AXTextField")
        end)
    end
    return self._search
end

--- cp.apple.finalcutpro.main.GeneratorsBrowser:showSidebar() -> self
--- Method
--- Ensures the sidebar is showing in the Generators & Titles panel.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The Generators Browser.
function GeneratorsBrowser:showSidebar()
    if not self:sidebar():isShowing() then
        self:app():menu():selectMenu({"Window", "Show in Workspace", 1})
    end
end

--- cp.apple.finalcutpro.main.GeneratorsBrowser:topCategoriesUI() -> table of axuielements
--- Method
--- Returns an array of the top-level categories in the sidebar.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The array of category rows.
function GeneratorsBrowser:topCategoriesUI()
    return self:sidebar():rowsUI(function(row)
        return row:attributeValue("AXDisclosureLevel") == 0
    end)
end

--- cp.apple.finalcutpro.main.GeneratorsBrowser:showInstalledTitles() -> self
--- Method
--- Ensures that the browser is showing 'Installed Titles'.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The Generators Browser.
function GeneratorsBrowser:showInstalledTitles()
    self:group():selectItem(1)
    return self
end

--- cp.apple.finalcutpro.main.GeneratorsBrowser:showInstalledGenerators() -> self
--- Method
--- Ensures that the browser is showing 'Installed Generators'.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The Generators Browser.
function GeneratorsBrowser:showInstalledGenerators()
    self:showInstalledTitles()
    return self
end

--- cp.apple.finalcutpro.main.GeneratorsBrowser:getTitlesRowLabel() -> string
--- Method
--- Returns the label of the 'Titles' row in the current language.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The 'Titles' label.
function GeneratorsBrowser:getTitlesRowLabel()
    return self:app():string("project media sidebar titles row")
end

--- cp.apple.finalcutpro.main.GeneratorsBrowser:showAllTitles() -> self
--- Method
--- Ensures the sidebar is showing in the Generators & Titles panel, focused on all 'Titles'.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The Generators Browser.
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
--- * `name`		- The category name, in the current language.
---
--- Returns:
--- * The Generators Browser.
function GeneratorsBrowser:showTitlesCategory(name)
    self:showSidebar()
    Table.selectRow(self:sidebar():rowsUI(), {self:getTitlesRowLabel(), name})
    return self
end

function GeneratorsBrowser:getGeneratorsRowLabel()
    return self:app():string("project media sidebar generators row")
end

-- TODO: Add documentation
function GeneratorsBrowser:showAllGenerators()
    self:showSidebar()
    local topCategories = self:topCategoriesUI()
    if topCategories and #topCategories == 2 then
        self:sidebar():selectRow(topCategories[2])
    end
    return self
end

function GeneratorsBrowser:showGeneratorsCategory(name)
    self:showSidebar()
    Table.selectRow(self:sidebar():rowsUI(), {self:getGeneratorsRowLabel(), name})
    return self
end

-- TODO: Add documentation
function GeneratorsBrowser:currentItemsUI()
    return self:contents():childrenUI()
end

-- TODO: Add documentation
function GeneratorsBrowser:selectedItemsUI()
    return self:contents():selectedChildrenUI()
end

-- TODO: Add documentation
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

-- TODO: Add documentation
function GeneratorsBrowser:applyItem(itemUI)
    if itemUI then
        self:contents():showChild(itemUI)
        local targetPoint = geometry.rect(itemUI:frame()).center
        tools.ninjaDoubleClick(targetPoint)
    end
    return self
end

-- TODO: Add documentation
-- Returns the list of titles for all effects/transitions currently visible
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

-- TODO: Add documentation
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

-- TODO: Add documentation
function GeneratorsBrowser:loadLayout(layout)
    if layout and layout.showing then
        self:show()
        self:search():loadLayout(layout.search)
        self:sidebar():loadLayout(layout.sidebar)
        self:contents():loadLayout(layout.contents)
    end
end

return GeneratorsBrowser