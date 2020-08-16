--- === cp.apple.finalcutpro.main.MediaBrowser ===
---
--- Media Browser Module.

local require = require

-- local log								= require "hs.logger" .new "mediaBrowser"

local just								= require "cp.just"
local axutils							= require "cp.ui.axutils"

local Group                             = require "cp.ui.Group"
local Table								= require "cp.ui.Table"
local PopUpButton				        = require "cp.ui.PopUpButton"
local ScrollArea                        = require "cp.ui.ScrollArea"
local SplitGroup                        = require "cp.ui.SplitGroup"
local TextField						    = require "cp.ui.TextField"

local cache                             = axutils.cache
local childMatching                     = axutils.childMatching


local MediaBrowser = Group:subclass("cp.apple.finalcutpro.main.MediaBrowser")

--- cp.apple.finalcutpro.main.MediaBrowser.TITLE -> string
--- Constant
--- Photos & Audio Title.
MediaBrowser.static.TITLE = "Photos and Audio"

--- cp.apple.finalcutpro.main.MediaBrowser.MAX_SECTIONS -> number
--- Constant
--- Maximum Sections.
MediaBrowser.static.MAX_SECTIONS = 4

--- cp.apple.finalcutpro.main.MediaBrowser.PHOTOS -> number
--- Constant
--- Photos ID.
MediaBrowser.static.PHOTOS = 1

--- cp.apple.finalcutpro.main.MediaBrowser.GARAGE_BAND -> number
--- Constant
--- Garage Band ID.
MediaBrowser.static.GARAGE_BAND = 2

--- cp.apple.finalcutpro.main.MediaBrowser.ITUNES -> number
--- Constant
--- iTunes ID.
MediaBrowser.static.ITUNES = 3

--- cp.apple.finalcutpro.main.MediaBrowser.SOUND_EFFECTS -> number
--- Constant
--- Sound Effects ID.
MediaBrowser.static.SOUND_EFFECTS = 4

--- cp.apple.finalcutpro.main.MediaBrowser(parent) -> MediaBrowser
--- Constructor
--- Creates a new `Browser` instance.
---
--- Parameters:
---  * parent - The parent object.
---
--- Returns:
---  * A new `MediaBrowser` object.
function MediaBrowser:initialize(parent)
    Group.initialize(self, parent, parent.UI:mutate(function(original)
        if self:isShowing() then
            return original()
        else
            return nil
        end
    end))
end

--- cp.apple.finalcutpro.main.MediaBrowser.isShowing <cp.prop: boolean; read-only>
--- Field
--- Checks if the Media Browser is showing.
function MediaBrowser.lazy.prop:isShowing()
    local parent = self:parent()
    return parent.isShowing:AND(parent.mediaShowing)
end

--- cp.apple.finalcutpro.main.MediaBrowser.mainGroupUI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- Returns the main group UI for the Media Browser, or `nil` if not available.
function MediaBrowser.lazy.prop:mainGroupUI()
    return self.UI:mutate(function(original)
        return cache(self, "_mainGroup", function()
            local ui = original()
            return ui and childMatching(ui, SplitGroup.matches)
        end)
    end)
end

-----------------------------------------------------------------------
--
-- MEDIABROWSER UI:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.MediaBrowser:show() -> MediaBrowser
--- Method
--- Show the Media Browser.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `MediaBrowser` object.
function MediaBrowser:show()
    local menuBar = self:app().menu
    -----------------------------------------------------------------------
    -- Go there direct:
    -----------------------------------------------------------------------
    menuBar:selectMenu({"Window", "Go To", MediaBrowser.TITLE})
    just.doUntil(function() return self:isShowing() end)
    return self
end

--- cp.apple.finalcutpro.main.MediaBrowser:hide() -> MediaBrowser
--- Method
--- Hide the Media Browser.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `MediaBrowser` object.
function MediaBrowser:hide()
    self:parent():hide()
    return self
end

-----------------------------------------------------------------------------
--
-- SECTIONS:
--
-----------------------------------------------------------------------------

--- cp.apple.finalcutpro.main.MediaBrowser.sidebar <cp.ui.Table>
--- Field
--- The Sidebar `Table`.
function MediaBrowser.lazy.value:sidebar()
    return Table(self, function()
        return childMatching(self:mainGroupUI(), ScrollArea.matches)
    end)
end

--- cp.apple.finalcutpro.main.MediaBrowser.group <cp.ui.PopUpButton>
--- Field
--- The group PopUpButton.
function MediaBrowser.lazy.value:group()
    return PopUpButton(self, function()
        return childMatching(self:UI(), PopUpButton.matches)
    end)
end

--- cp.apple.finalcutpro.main.MediaBrowser.search <cp.ui.TextField>
--- Field
--- The search TextField.
function MediaBrowser.lazy.value:search()
    return TextField(self, function()
        return childMatching(self:mainGroupUI(), TextField.matches)
    end)
end

--- cp.apple.finalcutpro.main.MediaBrowser:showSidebar() -> MediaBrowser
--- Method
--- Show the Media Browser Sidebar.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `MediaBrowser` object.
function MediaBrowser:showSidebar()
    self:app().menu:selectMenu({"Window", "Show in Workspace", "Sidebar"})
    return self
end

--- cp.apple.finalcutpro.main.MediaBrowser:topCategoriesUI() -> axuielementObject
--- Method
--- Get the Top Categories UI.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `axuielementObject` object.
function MediaBrowser:topCategoriesUI()
    return self.sidebar:rowsUI(function(row)
        return row:attributeValue("AXDisclosureLevel") == 0
    end)
end

--- cp.apple.finalcutpro.main.MediaBrowser:showSection(index) -> MediaBrowser
--- Method
--- Show a specific section.
---
--- Parameters:
---  * index - The index ID of the section you want to show as a number.
---
--- Returns:
---  * `MediaBrowser` object.
function MediaBrowser:showSection(index)
    self:showSidebar()
    local topCategories = self:topCategoriesUI()
    if topCategories and #topCategories == MediaBrowser.MAX_SECTIONS then
        self.sidebar:selectRow(topCategories[index])
    end
    return self
end

--- cp.apple.finalcutpro.main.MediaBrowser:showPhotos() -> MediaBrowser
--- Method
--- Show Photos Section.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `MediaBrowser` object.
function MediaBrowser:showPhotos()
    return self:showSection(MediaBrowser.PHOTOS)
end

--- cp.apple.finalcutpro.main.MediaBrowser:showGarageBand() -> MediaBrowser
--- Method
--- Show Garage Band Section.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `MediaBrowser` object.
function MediaBrowser:showGarageBand()
    return self:showSection(MediaBrowser.GARAGE_BAND)
end

--- cp.apple.finalcutpro.main.MediaBrowser:showITunes() -> MediaBrowser
--- Method
--- Show iTunes Section.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `MediaBrowser` object.
function MediaBrowser:showITunes()
    return self:showSection(MediaBrowser.ITUNES)
end

--- cp.apple.finalcutpro.main.MediaBrowser:showSoundEffects() -> MediaBrowser
--- Method
--- Show Sound Effects Section.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `MediaBrowser` object.
function MediaBrowser:showSoundEffects()
    return self:showSection(MediaBrowser.SOUND_EFFECTS)
end

--- cp.apple.finalcutpro.main.MediaBrowser:saveLayout() -> table
--- Method
--- Saves the current Media Browser layout to a table.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table containing the current Media Browser Layout.
function MediaBrowser:saveLayout()
    local layout = {}
    if self:isShowing() then
        layout.showing = true
        layout.sidebar = self.sidebar:saveLayout()
        layout.search = self.search:saveLayout()
    end
    return layout
end

--- cp.apple.finalcutpro.main.MediaBrowser:loadLayout(layout) -> none
--- Method
--- Loads a Media Browser layout.
---
--- Parameters:
---  * layout - A table containing the Media Browser layout settings - created using `cp.apple.finalcutpro.main.MediaBrowser:saveLayout()`.
---
--- Returns:
---  * None
function MediaBrowser:loadLayout(layout)
    if layout and layout.showing then
        self:show()
        self.sidebar:loadLayout(layout.sidebar)
        self.search:loadLayout(layout.sidebar)
    end
end

return MediaBrowser
