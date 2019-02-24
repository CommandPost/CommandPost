--- === cp.apple.finalcutpro.main.MediaBrowser ===
---
--- Media Browser Module.

local require = require

-- local log								= require("hs.logger").new("mediaBrowser")

local just								= require("cp.just")
local prop								= require("cp.prop")
local go                                = require("cp.rx.go")

local axutils							= require("cp.ui.axutils")

local Group                             = require("cp.ui.Group")
local Outline                           = require("cp.ui.Outline")
local ScrollArea                        = require("cp.ui.ScrollArea")
local SplitGroup                        = require("cp.ui.SplitGroup")
local PopUpButton				        = require("cp.ui.PopUpButton")
local TextField						    = require("cp.ui.TextField")

local strings                           = require("cp.apple.finalcutpro.strings")

local cache                             = axutils.cache
local childMatching                     = axutils.childMatching
local childWithTitle                    = axutils.childWithTitle

local Do, WaitUntil, Done, If           = go.Do, go.WaitUntil, go.Done, go.If

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local MediaBrowser = Group:subclass("cp.apple.finalcutpro.main.MediaBrowser")

--- cp.apple.finalcutpro.main.MediaBrowser.TITLE -> string
--- Constant
--- Photos & Audio Menu Title.
MediaBrowser.static.TITLE = "Photos and Audio"

MediaBrowser.static.SECTION = {
    PHOTOS = "media sidebar Photos library row",
    APERTURE = "media sidebar Aperture library row",
    GARAGEBAND = "project media sidebar garage band row",
    LOGIC_PRO_X = "project media sidebar logic pro row",
    ITUNES = "project media sidebar itunes row",
    SOUND_EFFECTS = "project media sidebar sound effects row",
}

-- rowWithTitle(row) -> function
-- Function
-- Creates a function which will check if a row contains an element with the specified title key, as per fcp.strings.
--
-- Parameters:
-- * The row to check
--
-- Returns:
-- * The matcher `function`
local function rowWithTitle(titleKey)
    return function(row)
        return childWithTitle(row, strings:find(titleKey)) ~= nil
    end
end

-- soundEffectsRow(row) -> boolean
-- Function
-- Checks if the row is the "Sound Effects" row.
local soundEffectsRow = rowWithTitle(MediaBrowser.SECTION.SOUND_EFFECTS)

function MediaBrowser.static.matches(element)
    if Group.matches(element) then
        local splitGroup = childMatching(element, SplitGroup.matches)
        if splitGroup then
            local scrollArea = childMatching(splitGroup, SplitGroup.matches)
            if scrollArea then
                local outline = childMatching(scrollArea, Outline.matches)
                if outline then
                    return childMatching(outline, soundEffectsRow) ~= nil
                end
            end
        end
    end
    return false
end

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
    local UI = prop.OR(parent.isShowing:AND(parent.mediaShowing):AND(parent.UI), prop.NIL)
    Group.initialize(self, parent, UI)
end

--- cp.apple.finalcutpro.main.MediaBrowser.isShowing <cp.prop: boolean; read-only; live?>
--- Field
--- Indicates if the media browser is currently showing.
function MediaBrowser.lazy.prop:isShowing()
    local parent = self:parent()
    return parent.isShowing:AND(parent.mediaShowing)
end

--- cp.finalcutpro.main.MediaBrowser.mainGroupUI <cp.prop: hs._asm.axuielement; read-only>
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

--- cp.finalcutpro.main.MediaBrowser:mainGroup() -> SplitGroup
--- Method
--- The [SplitGroup](cp.ui.SplitGroup.md) that contains the core elements of the `MediaBrowser`.
---
--- Returns:
--- * The main [SplitGroup](cp.ui.SplitGroup.md)
function MediaBrowser.lazy.method:mainGroup()
    return SplitGroup(self, self:mainGroupUI())
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
    local menuBar = self:app():menu()
    -----------------------------------------------------------------------
    -- Go there direct:
    -----------------------------------------------------------------------
    menuBar:selectMenu({"Window", "Go To", MediaBrowser.TITLE})
    just.doUntil(function() return self:isShowing() end)
    return self
end

--- cp.apple.finalcutpro.main.MediaBrowser:doShow() -> Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will show the `MediaBrowser`.
---
--- Returns:
--- * The [Statement](cp.rx.go.Statement.md).
function MediaBrowser.lazy.method:doShow()
    local menuBar = self:app():menu()
    return Do(menuBar:doSelectMenu({"Window", "Go To", MediaBrowser.TITLE}))
    :Then(WaitUntil(self.isShowing))
    :Label("MediaBrowser:doShow")
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

--- cp.apple.finalcutpro.main.MediaBrowser:doHide() -> Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will hide the `MediaBrowser`.
---
--- Returns:
--- * The [Statement](cp.rx.go.Statement.md).
function MediaBrowser.lazy.method:doHide()
    return self:parent():doHide()
end

-----------------------------------------------------------------------------
--
-- SECTIONS:
--
-----------------------------------------------------------------------------

--- cp.apple.finalcutpro.main.MediaBrowser:sidebar() -> ScrollArea<Outline>
--- Method
--- Get the Sidebar Table. It will be a [ScrollArea](cp.ui.ScrollArea.md) with an
--- [Outline](cp.ui.Outline.md) for it's `contents` value.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `ScrollArea` object.
function MediaBrowser.lazy.method:sidebar()
    return ScrollArea(self, self.mainGroupUI:mutate(function(original)
        return childMatching(original(), ScrollArea.matches)
    end), Outline)
end

--- cp.apple.finalcutpro.main.MediaBrowser:group() -> PopUpButton
--- Method
--- Get the group PopUpButton.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `PopUpButton` object.
function MediaBrowser.lazy.method:group()
    return PopUpButton(self, function()
        return childMatching(self:UI(), PopUpButton.matches)
    end)
end

--- cp.apple.finalcutpro.main.MediaBrowser:search() -> TextField
--- Method
--- Get the search TextField.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `TextField` object.
function MediaBrowser.lazy.method:search()
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
    self:show()
    if self:isShowing() and not self:sidebar():isShowing() then
        self:app():menu():selectMenu({"Window", "Show in Workspace", "Sidebar"})
    end
    return self
end

--- cp.apple.finalcutpro.main.MediaBrowser:doShowSidebar() -> Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will show the Media Browser Sidebar.
---
--- Returns:
---  * The [Statement](cp.rx.go.Statement.md).
function MediaBrowser.lazy.method:doShowSidebar()
    return If(self:doShow())
    :Then(
        If(self:sidebar().isShowing):Is(false)
        :Then(self:app():menu():doSelectMenu({"Window", "Show in Workspace", "Sidebar"}))
        :Otherwise(true)
    ):Otherwise(false)
    :Label("MediaBrowser:doShowSidebar")
end

--- cp.apple.finalcutpro.main.MediaBrowser:sections() -> table of Rows
--- Method
--- Get the sections as [Row](cp.ui.Row.md)s.
---
--- Parameters:
---  * None
---
--- Returns:
---  * a table of [Row](cp.ui.Row.md)s.
function MediaBrowser:sections()
    return self:sidebar():contents():filterRows(function(row)
        return row:disclosureLevel() == 0
    end)
end

function MediaBrowser:findSection(key)
    local keyValue = strings:find(key)
    return self:sidebar():contents():findRow(function(row)
        return row:disclosureLevel() == 0 and row:hasValue(keyValue)
    end)
end

--- cp.apple.finalcutpro.main.MediaBrowser:photos() -> cp.ui.Row or nil
--- Method
--- Finds the 'Photos' section as a [Row](cp.ui.Row.md)
---
--- Returns:
--- * The [Row](cp.ui.Row.md) or `nil` if not available.
function MediaBrowser:photos()
    return self:findSection(MediaBrowser.SECTION.PHOTOS)
end

--- cp.apple.finalcutpro.main.MediaBrowser:aperture() -> cp.ui.Row or nil
--- Method
--- Finds the 'Aperture' section as a [Row](cp.ui.Row.md)
---
--- Returns:
--- * The [Row](cp.ui.Row.md) or `nil` if not available.
function MediaBrowser:aperture()
    return self:findSection(MediaBrowser.SECTION.APERTURE)
end

--- cp.apple.finalcutpro.main.MediaBrowser:iTunes() -> cp.ui.Row or nil
--- Method
--- Finds the 'iTunes' section as a [Row](cp.ui.Row.md)
---
--- Returns:
--- * The [Row](cp.ui.Row.md) or `nil` if not available.
function MediaBrowser:iTunes()
    return self:findSection(MediaBrowser.SECTION.ITUNES)
end

--- cp.apple.finalcutpro.main.MediaBrowser:garageBand() -> cp.ui.Row or nil
--- Method
--- Finds the 'GarageBand' section as a [Row](cp.ui.Row.md)
---
--- Returns:
--- * The [Row](cp.ui.Row.md) or `nil` if not available.
function MediaBrowser:garageBand()
    return self:findSection(MediaBrowser.SECTION.GARAGEBAND)
end

--- cp.apple.finalcutpro.main.MediaBrowser:logicProX() -> cp.ui.Row or nil
--- Method
--- Finds the 'Logic Pro X' section as a [Row](cp.ui.Row.md)
---
--- Returns:
--- * The [Row](cp.ui.Row.md) or `nil` if not available.
function MediaBrowser:logicProX()
    return self:findSection(MediaBrowser.SECTION.LOGIC_PRO_X)
end

--- cp.apple.finalcutpro.main.MediaBrowser:soundEffects() -> cp.ui.Row or nil
--- Method
--- Finds the 'SoundEffects' section as a [Row](cp.ui.Row.md)
---
--- Returns:
--- * The [Row](cp.ui.Row.md) or `nil` if not available.
function MediaBrowser:soundEffects()
    return self:findSection(MediaBrowser.SECTION.SOUND_EFFECTS)
end

--- cp.apple.finalcutpro.main.MediaBrowser:doShowSection(key) -> Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will show a specific section.
---
--- Parameters:
---  * key - The index ID of the section you want to show as a number.
---
--- Returns:
---  * The [Statement](cp.rx.go.Statement.md)
function MediaBrowser:doShowSection(key)
    return Do(self:doShowSidebar())
    :Then(function()
        local section = self:findSection(key)
        if section then
            return section:doSelect()
        else
            return Done()
        end
    end)
    :Label("MediaBrowser:doShowSection")
end

--- cp.apple.finalcutpro.main.MediaBrowser:doShowPhotos() -> Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will show Photos Section.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The [Statement](cp.rx.go.Statement.md)
function MediaBrowser.lazy.method:doShowPhotos()
    return self:doShowSection(MediaBrowser.SECTION.PHOTOS):Label("MediaBrowser:doShowPhotos")
end

--- cp.apple.finalcutpro.main.MediaBrowser:doShowAperture() -> Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will show Aperture Section.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The [Statement](cp.rx.go.Statement.md)
function MediaBrowser.lazy.method:doShowAperture()
    return self:doShowSection(MediaBrowser.SECTION.PHOTOS):Label("MediaBrowser:doShowAperture")
end

--- cp.apple.finalcutpro.main.MediaBrowser:doShowGarageBand() -> Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will show Garage Band Section.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The [Statement](cp.rx.go.Statement.md)
function MediaBrowser.lazy.method:doShowGarageBand()
    return self:doShowSection(MediaBrowser.SECTION.GARAGEBAND):Label("MediaBrowser:doShowGarageBand")
end

--- cp.apple.finalcutpro.main.MediaBrowser:doShowLogicProX() -> Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will show Logic Pro X Section.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The [Statement](cp.rx.go.Statement.md)
function MediaBrowser.lazy.method:doShowLogicProX()
    return self:doShowSection(MediaBrowser.SECTION.LOGIC_PRO_X):Label("MediaBrowser:doShowLogicProX")
end

--- cp.apple.finalcutpro.main.MediaBrowser:doShowITunes() -> Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will show iTunes Section.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The [Statement](cp.rx.go.Statement.md)
function MediaBrowser.lazy.method:doShowITunes()
    return self:doShowSection(MediaBrowser.SECTION.ITUNES):Label("MediaBrowser:doShowITunes")
end

--- cp.apple.finalcutpro.main.MediaBrowser:doShowSoundEffects() -> Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will show the Sound Effects Section.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The cp.rx.go.Statement
function MediaBrowser.lazy.method:doShowSoundEffects()
    return self:doShowSection(MediaBrowser.SECTION.SOUND_EFFECTS):Label("MediaBrowser:doShowSoundEffects")
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
        layout.sidebar = self:sidebar():saveLayout()
        layout.search = self:search():saveLayout()
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
        self:sidebar():loadLayout(layout.sidebar)
        self:search():loadLayout(layout.sidebar)
    end
end

return MediaBrowser
