--- === cp.apple.finalcutpro.main.EffectsBrowser ===
---
--- Effects Browser Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log								= require("hs.logger").new("EffectsBrowser")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local geometry							= require("hs.geometry")
local fnutils							= require("hs.fnutils")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils							= require("cp.ui.axutils")
local tools								= require("cp.tools")
local just								= require("cp.just")
local prop								= require("cp.prop")

local Table								= require("cp.ui.Table")
local ScrollArea						= require("cp.ui.ScrollArea")
local CheckBox							= require("cp.ui.CheckBox")
local PopUpButton						= require("cp.ui.PopUpButton")
local TextField							= require("cp.ui.TextField")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local EffectsBrowser = {}

--- cp.apple.finalcutpro.main.EffectsBrowser.EFFECTS -> string
--- Constant
--- Effects.
EffectsBrowser.EFFECTS = "Effects"

--- cp.apple.finalcutpro.main.EffectsBrowser.TRANSITIONS -> string
--- Constant
--- Transitions.
EffectsBrowser.TRANSITIONS = "Transitions"

--- cp.apple.finalcutpro.main.EffectsBrowser.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function EffectsBrowser.matches(element)
    return element and element:attributeValue("AXRole") == "AXGroup"
       and #element == 4
end

--- cp.apple.finalcutpro.main.EffectsBrowser.new(parent, type) -> EffectsBrowser
--- Constructor
--- Creates a new `EffectsBrowser` instance.
---
--- Parameters:
---  * parent - The parent object.
---  * type - A string determining whether the Effects Browser is for Effects (`cp.apple.finalcutpro.main.EffectsBrowser.EFFECTS`) or Transitions (`cp.apple.finalcutpro.main.EffectsBrowser.TRANSITIONS`).
---
--- Returns:
---  * A new `EffectsBrowser` object.
function EffectsBrowser.new(parent, type)
    local o = {_parent = parent, _type = type}
    return prop.extend(o, EffectsBrowser)
end

--- cp.apple.finalcutpro.main.EffectsBrowser:parent() -> parent
--- Method
--- Returns the parent object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * parent
function EffectsBrowser:parent()
    return self._parent
end

--- cp.apple.finalcutpro.main.EffectsBrowser:app() -> App
--- Method
--- Returns the app instance representing Final Cut Pro.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function EffectsBrowser:app()
    return self:parent():app()
end

--- cp.apple.finalcutpro.main.EffectsBrowser:type() -> App
--- Method
--- Type of Effects Browser.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function EffectsBrowser:type()
    return self._type
end

-----------------------------------------------------------------------
--
-- BROWSER UI:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.EffectsBrowser:UI() -> axuielementObject
--- Method
--- The Effects Browser UI.
---
--- Parameters:
---  * None
---
--- Returns:
---  * axuielementObject
function EffectsBrowser:UI()
    if self:isShowing() then
        return axutils.cache(self, "_ui", function()
            return axutils.childMatching(self:parent():mainUI(), EffectsBrowser.matches)
        end,
        EffectsBrowser.matches)
    end
end

--- cp.apple.finalcutpro.main.EffectsBrowser.isShowing <cp.prop: boolean>
--- Variable
--- Is the Effects Browser showing?
EffectsBrowser.isShowing = prop.new(function(self)
    return self:toggleButton():checked()
end):bind(EffectsBrowser)

--- cp.apple.finalcutpro.main.EffectsBrowser:toggleButton() -> RadioButton
--- Method
--- Returns the Effects Browser Toggle Button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `RadioButton` object.
function EffectsBrowser:toggleButton()
    if not self._toggleButton then
        local toolbar = self:app():timeline():toolbar()
        local button = nil
        local type = self:type()
        if type == EffectsBrowser.EFFECTS then
            button = toolbar:browser():effects()
        elseif type == EffectsBrowser.TRANSITIONS then
            button = toolbar:browser():transitions()
        end
        self._toggleButton = button
    end
    return self._toggleButton
end

--- cp.apple.finalcutpro.main.EffectsBrowser:show() -> EffectsBrowser
--- Method
--- Show the Effects Browser.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `EffectsBrowser` object.
function EffectsBrowser:show()
    self:app():timeline():show()
    self:toggleButton():checked(true)
    just.doUntil(function() return self:isShowing() end)
    return self
end

--- cp.apple.finalcutpro.main.EffectsBrowser:hide() -> EffectsBrowser
--- Method
--- Hide the Effects Browser.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `EffectsBrowser` object.
function EffectsBrowser:hide()
    if self:app():timeline():isShowing() then
        self:toggleButton():checked(false)
        just.doWhile(function() return self:isShowing() end)
    end
    return self
end

-----------------------------------------------------------------------------
--
-- ACTIONS:
--
-----------------------------------------------------------------------------

--- cp.apple.finalcutpro.main.EffectsBrowser:showSidebar() -> EffectsBrowser
--- Method
--- Show Sidebar.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `EffectsBrowser` object.
function EffectsBrowser:showSidebar()
    if not self:sidebar():isShowing() then
        self:sidebarToggle():toggle()
    end
    return self
end

--- cp.apple.finalcutpro.main.EffectsBrowser:hideSidebar() -> EffectsBrowser
--- Method
--- Hide Sidebar.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `EffectsBrowser` object.
function EffectsBrowser:hideSidebar()
    if self:sidebar():isShowing() then
        self:sidebarToggle():toggle()
    end
    return self
end

--- cp.apple.finalcutpro.main.EffectsBrowser:toggleSidebar() -> EffectsBrowser
--- Method
--- Toggle Sidebar.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `EffectsBrowser` object.
function EffectsBrowser:toggleSidebar()
    self:sidebarToggle():toggle()
    return self
end

--- cp.apple.finalcutpro.main.EffectsBrowser:showInstalledEffects() -> EffectsBrowser
--- Method
--- Show Installed Effects.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `EffectsBrowser` object.
function EffectsBrowser:showInstalledEffects()
    self:group():selectItem(1)
    return self
end

--- cp.apple.finalcutpro.main.EffectsBrowser:showInstalledTransitions() -> EffectsBrowser
--- Method
--- Show Installed Transitions.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `EffectsBrowser` object.
function EffectsBrowser:showInstalledTransitions()
    self:showInstalledEffects()
    return self
end

--- cp.apple.finalcutpro.main.EffectsBrowser:showAllEffects() -> EffectsBrowser
--- Method
--- Show All Effects.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `EffectsBrowser` object.
function EffectsBrowser:showAllEffects()
    self:showSidebar()
    self:sidebar():selectRowAt(1)
    return self
end

--- cp.apple.finalcutpro.main.EffectsBrowser:showAllTransitions() -> EffectsBrowser
--- Method
--- Show All Transitions.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `EffectsBrowser` object.
function EffectsBrowser:showAllTransitions()
    return self:showAllEffects()
end

--- cp.apple.finalcutpro.main.EffectsBrowser:showTransitionsCategory(name) -> EffectsBrowser
--- Method
--- Ensures the sidebar is showing and that the selected 'Transitions' category is selected, if available.
---
--- Parameters:
---  * name - The category name, in the current language.
---
--- Returns:
---  * The `EffectsBrowser` object.
function EffectsBrowser:showTransitionsCategory(name)
    self:showSidebar()
    Table.selectRow(self:sidebar():rowsUI(), {name})
    return self
end

-- cp.apple.finalcutpro.main.EffectsBrowser:_allRowsUI() -> axuielementObject
-- Method
-- Find the two 'All' rows (Video/Audio).
--
-- Parameters:
--  * None
--
-- Returns:
--  * `axuielementObject` object.
function EffectsBrowser:_allRowsUI()
    local all = self:app():string("FFEffectsAll")
    --------------------------------------------------------------------------------
    -- Find the two 'All' rows (Video/Audio)
    --------------------------------------------------------------------------------
    return self:sidebar():rowsUI(function(row)
        local label = row[1][1]
        local value = label and label:attributeValue("AXValue")
        return value == all
    end)
end

--- cp.apple.finalcutpro.main.EffectsBrowser:videoCategoryRowsUI() -> axuielementObject
--- Method
--- Gets the Video Category Rows UI.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `axuielementObject` object.
function EffectsBrowser:videoCategoryRowsUI()
    local video = self:app():string("FFVideo"):upper()
    local audio = self:app():string("FFAudio"):upper()

    return self:_startEndRowsUI(video, audio)
end

--- cp.apple.finalcutpro.main.EffectsBrowser:audioCategoryRowsUI() -> axuielementObject
--- Method
--- Gets the Audio Category Rows UI.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `axuielementObject` object.
function EffectsBrowser:audioCategoryRowsUI()
    local audio = self:app():string("FFAudio"):upper()
    return self:_startEndRowsUI(audio, nil)
end

-- cp.apple.finalcutpro.main.EffectsBrowser:_startEndRowsUI(startLabel, endLabel) -> axuielementObject
-- Method
-- Find the two 'All' rows (Video/Audio).
--
-- Parameters:
--  * startLabel - Start label as string.
--  * endLabel - End label as string.
--
-- Returns:
--  * `axuielementObject` object.
function EffectsBrowser:_startEndRowsUI(startLabel, endLabel)
    local started, ended = false, false
    --------------------------------------------------------------------------------
    -- Find the two 'All' rows (Video/Audio)
    --------------------------------------------------------------------------------
    return self:sidebar():rowsUI(function(row)
        local label = row[1][1]
        local value = label and label:attributeValue("AXValue")
        --log.df("checking row value: %s", value)

        local isStartLabel = value == startLabel
        if not started and isStartLabel then
            started = true
        end
        if started and value == endLabel then
            ended = true
        end
        return started and not isStartLabel and not ended
    end)

end

--- cp.apple.finalcutpro.main.EffectsBrowser:showAllVideoEffects() -> boolean
--- Method
--- Show All Video Effects.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if successful otherwise `false`.
function EffectsBrowser:showAllVideoEffects()
    local allRows = self:_allRowsUI()
    if allRows and #allRows == 3 then
        --------------------------------------------------------------------------------
        -- Click 'All Video':
        --------------------------------------------------------------------------------
        self:sidebar():selectRow(allRows[2])
        return true
    elseif allRows and #allRows == 2 then
        --------------------------------------------------------------------------------
        -- Click 'All Video':
        --------------------------------------------------------------------------------
        self:sidebar():selectRow(allRows[1])
        return true
    end
    return false
end

--- cp.apple.finalcutpro.main.EffectsBrowser:showVideoCategory(name) -> EffectsBrowser
--- Method
--- Ensures the sidebar is showing and that the selected 'Video' category is selected, if available.
---
--- Parameters:
---  * name - The category name, in the current language.
---
--- Returns:
---  * The `EffectsBrowser` object.
function EffectsBrowser:showVideoCategory(name)
    self:showSidebar()
    Table.selectRow(self:videoCategoryRowsUI(), {name})
    return self
end

--- cp.apple.finalcutpro.main.EffectsBrowser:showAllAudioEffects() -> boolean
--- Method
--- Show All Audio Effects.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if successful otherwise `false`.
function EffectsBrowser:showAllAudioEffects()
    local allRows = self:_allRowsUI()
    if allRows and #allRows == 3 then
        --------------------------------------------------------------------------------
        -- Click 'All Audio':
        --------------------------------------------------------------------------------
        self:sidebar():selectRow(allRows[3])
        return true
    elseif allRows and #allRows == 2 then
        --------------------------------------------------------------------------------
        -- Click 'All Audio':
        --------------------------------------------------------------------------------
        self:sidebar():selectRow(allRows[2])
        return true
    end
    return false
end

--- cp.apple.finalcutpro.main.EffectsBrowser:showAudioCategory(name) -> self
--- Method
--- Ensures the sidebar is showing and that the selected 'Audio' category is selected, if available.
---
--- Parameters:
--- * `name`		- The category name, in the current language.
---
--- Returns:
--- * The browser.
function EffectsBrowser:showAudioCategory(name)
    self:showSidebar()
    Table.selectRow(self:audioCategoryRowsUI(), {name})
    return self
end

--- cp.apple.finalcutpro.main.EffectsBrowser:currentItemsUI() -> axuielementObject
--- Method
--- Gets the current items UI.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `axuielementObject` object.
function EffectsBrowser:currentItemsUI()
    return self:contents():childrenUI()
end

--- cp.apple.finalcutpro.main.EffectsBrowser:selectedItemsUI() -> axuielementObject
--- Method
--- Gets the selected items UI.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `axuielementObject` object.
function EffectsBrowser:selectedItemsUI()
    return self:contents():selectedChildrenUI()
end

--- cp.apple.finalcutpro.main.EffectsBrowser:itemIsSelected(itemUI) -> boolean
--- Method
--- Checks to see if an item is selected.
---
--- Parameters:
---  * itemUI - A `axuielementObject` to check.
---
--- Returns:
---  * `true` if the item is selected, otherwise `false`.
function EffectsBrowser:itemIsSelected(itemUI)
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

--- cp.apple.finalcutpro.main.EffectsBrowser:applyItem(itemUI) -> EffectsBrowser
--- Method
--- Applies an item by double clicking on it.
---
--- Parameters:
---  * itemUI - The `axuielementObject` of the item you want to apply.
---
--- Returns:
---  * The `EffectsBrowser` object.
function EffectsBrowser:applyItem(itemUI)
    if itemUI then
        self:contents():showChild(itemUI)
        local uiFrame = itemUI:frame()
        if uiFrame then
            local rect = geometry.rect(uiFrame)
            local targetPoint = rect and rect.center
            if targetPoint then
                tools.ninjaDoubleClick(targetPoint)
            end
        end
    end
    return self
end

--- cp.apple.finalcutpro.main.EffectsBrowser:getCurrentTitles() -> table
--- Method
--- Returns the list of titles for all effects/transitions currently visible.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table
function EffectsBrowser:getCurrentTitles()
    local contents = self:contents():childrenUI()
    if contents ~= nil then
        return fnutils.map(contents, function(child)
            return child:attributeValue("AXTitle")
        end)
    end
    return nil
end

-----------------------------------------------------------------------------
--
-- UI SECTIONS:
--
-----------------------------------------------------------------------------

--- cp.apple.finalcutpro.main.EffectsBrowser:mainGroupUI() -> axuielementObject
--- Method
--- Main Group UI.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `axuielementObject` object.
function EffectsBrowser:mainGroupUI()
    return axutils.cache(self, "_mainGroup",
    function()
        local ui = self:UI()
        return ui and axutils.childWithRole(ui, "AXSplitGroup")
    end)
end

--- cp.apple.finalcutpro.main.EffectsBrowser:sidebar() -> Table
--- Method
--- Gets the sidebar object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `Table` object.
function EffectsBrowser:sidebar()
    if not self._sidebar then
        self._sidebar = Table(self, function()
            return axutils.childFromLeft(self:mainGroupUI(), 1, function(element)
                return element:attributeValue("AXRole") == "AXScrollArea"
            end)
        end):uncached()
    end
    return self._sidebar
end

--- cp.apple.finalcutpro.main.EffectsBrowser:mainGroupUI() -> ScrollArea
--- Method
--- Gets the Effects Browser Contents.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `ScrollArea` object.
function EffectsBrowser:contents()
    if not self._contents then
        self._contents = ScrollArea(self, function()
            return axutils.childFromRight(self:mainGroupUI(), 1, function(element)
                return element:attributeValue("AXRole") == "AXScrollArea"
            end)
        end)
    end
    return self._contents
end

--- cp.apple.finalcutpro.main.EffectsBrowser:sidebarToggle() -> CheckBox
--- Method
--- Gets the Sidebar Toggle.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `CheckBox` object.
function EffectsBrowser:sidebarToggle()
    if not self._sidebarToggle then
        self._sidebarToggle = CheckBox(self, function()
            return axutils.childWithRole(self:UI(), "AXCheckBox")
        end)
    end
    return self._sidebarToggle
end

--- cp.apple.finalcutpro.main.EffectsBrowser:group() -> PopUpButton
--- Method
--- Gets the group.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `PopUpButton` object.
function EffectsBrowser:group()
    if not self._group then
        self._group = PopUpButton(self, function()
            return axutils.childWithRole(self:mainGroupUI(), "AXPopUpButton")
        end)
    end
    return self._group
end

--- cp.apple.finalcutpro.main.EffectsBrowser:search() -> PopUpButton
--- Method
--- Gets the Search Popup Button object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `PopUpButton` object.
function EffectsBrowser:search()
    if not self._search then
        self._search = TextField(self, function()
            return axutils.childWithRole(self:UI(), "AXTextField")
        end)
    end
    return self._search
end

--- cp.apple.finalcutpro.main.EffectsBrowser:saveLayout() -> table
--- Method
--- Saves the current Effects Browser layout to a table.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table containing the current Effects Browser Layout.
function EffectsBrowser:saveLayout()
    local layout = {}
    if self:isShowing() then
        layout.showing = true
        layout.sidebarToggle = self:sidebarToggle():saveLayout()
        --------------------------------------------------------------------------------
        -- Reveal the sidebar temporarily so we can save it:
        --------------------------------------------------------------------------------
        self:showSidebar()
        layout.sidebar = self:sidebar():saveLayout()
        self:sidebarToggle():loadLayout(layout.sidebarToggle)

        layout.contents = self:contents():saveLayout()
        layout.group = self:group():saveLayout()
        layout.search = self:search():saveLayout()
    end
    return layout
end

--- cp.apple.finalcutpro.main.EffectsBrowser:loadLayout(layout) -> none
--- Method
--- Loads a Effects Browser layout.
---
--- Parameters:
---  * layout - A table containing the Effects Browser layout settings - created using `cp.apple.finalcutpro.main.Browser:saveLayout()`.
---
--- Returns:
---  * None
function EffectsBrowser:loadLayout(layout)
    if layout and layout.showing then
        self:show()

        self:showSidebar()
        self:sidebar():loadLayout(layout.sidebar)
        self:sidebarToggle():loadLayout(layout.sidebarToggle)

        self:group():loadLayout(layout.group)

        self:search():loadLayout(layout.search)
        self:contents():loadLayout(layout.contents)
    else
        self:hide()
    end
end

return EffectsBrowser
