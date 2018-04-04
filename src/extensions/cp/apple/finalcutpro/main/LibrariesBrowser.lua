--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.main.LibrariesBrowser ===
---
--- Libraries Browser Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("librariesBrowser")

local just								= require("cp.just")
local prop								= require("cp.prop")
local axutils							= require("cp.ui.axutils")

local LibrariesList						= require("cp.apple.finalcutpro.main.LibrariesList")
local LibrariesFilmstrip				= require("cp.apple.finalcutpro.main.LibrariesFilmstrip")

local Button							= require("cp.ui.Button")
local Table								= require("cp.ui.Table")
local TextField							= require("cp.ui.TextField")

local id								= require("cp.apple.finalcutpro.ids") "LibrariesBrowser"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Libraries = {}

-- TODO: Add documentation
function Libraries:new(parent)
    local o = prop.extend({_parent = parent}, Libraries)

    -- checks if the Libraries Browser is showing
    local isShowing = parent.isShowing:AND(parent.librariesShowing)

    -- returns the UI for the Libraries Browser.
    local UI = prop.OR(isShowing:AND(parent.UI), prop.NIL)

    prop.bind(o) {
        --- cp.apple.finalcutpro.main.LibrariesBrowser.isShowing <cp.prop: boolean; read-only>
        --- Field
        --- Indicates if the Libraries Browser is showing.
        isShowing = isShowing,

        --- cp.apple.finalcutpro.main.LibrariesBrowser.UI <cp.prop: hs._asm.axuielement; read-only>
        --- Field
        --- The `axuielement` for the Library Browser, or `nil` if not available.
        UI = UI,

        --- cp.apple.finalcutpro.main.LibrariesBrowser.mainGroupUI <cp.prop: hs._asm.axuielement; read-only>
        --- Field
        --- Returns the main group within the Libraries Browser, or `nil` if not available..
        mainGroupUI = UI:mutate(function(original)
            return axutils.cache(self, "_mainGroup", function()
                local ui = original()
                return ui and axutils.childWithRole(ui, "AXSplitGroup")
            end)
        end),

        --- cp.apple.finalcutpro.main.LibrariesBrowser.isFocused <cp.prop: boolean; read-only>
        --- Field
        --- Indicates if the Libraries Browser is the current focus.
        isFocused = UI:mutate(function(original)
            local ui = original()
            return ui and ui:attributeValue("AXFocused") or axutils.childWith(ui, "AXFocused", true) ~= nil
        end),
    }

    -- because we are referencing list/filmstrip classes which in turn reference our UI/etc
    -- we need a separate prop.bind to avoid a circular reference.
    prop.bind(o) {
        --- cp.apple.finalcutpro.main.LibrariesBrowser.isListView <cp.prop: boolean; read-only>
        --- Field
        --- Indicates if the Library Browser is in 'list view' mode.
        isListView = o:list().isShowing:wrap(),

        --- cp.apple.finalcutpro.main.LibrariesBrowser.isFilmstripView <cp.prop: boolean; read-only>
        --- Field
        --- Indicates if the Library Browser is in 'filmstrip view' mode.
        isFilmstripView = o:filmstrip().isShowing:wrap(),
    }

    return o
end

-- TODO: Add documentation
function Libraries:parent()
    return self._parent
end

-- TODO: Add documentation
function Libraries:app()
    return self:parent():app()
end

-----------------------------------------------------------------------
--
-- BROWSER UI:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function Libraries:show()
    local browser = self:parent()
    if browser then
        if not browser:isShowing() then
            browser:showOnPrimary()
        end
        browser:showLibraries():checked(true)
    end
    return self
end

-- TODO: Add documentation
function Libraries:hide()
    self:parent():hide()
    return self
end

-----------------------------------------------------------------------------
--
-- PLAYHEADS:
--
-----------------------------------------------------------------------------

-- TODO: Add documentation
function Libraries:playhead()
    if self:list():isShowing() then
        return self:list():playhead()
    else
        return self:filmstrip():playhead()
    end
end

-- TODO: Add documentation
function Libraries:skimmingPlayhead()
    if self:list():isShowing() then
        return self:list():skimmingPlayhead()
    else
        return self:filmstrip():skimmingPlayhead()
    end
end

-----------------------------------------------------------------------------
--
-- BUTTONS:
--
-----------------------------------------------------------------------------

-- TODO: Add documentation
function Libraries:toggleViewMode()
    if not self._viewMode then
        self._viewMode = Button.new(self, function()
            return axutils.childFromRight(axutils.childrenWithRole(self:UI(), "AXButton"), 3)
        end)
    end
    return self._viewMode
end

-- TODO: Add documentation
function Libraries:appearanceAndFiltering()
    if not self._appearanceAndFiltering then
        self._appearanceAndFiltering = Button.new(self, function()
            return axutils.childFromRight(axutils.childrenWithRole(self:UI(), "AXButton"), 2)
        end)
    end
    return self._appearanceAndFiltering
end

-- TODO: Add documentation
function Libraries:searchToggle()
    if not self._searchToggle then
        self._searchToggle = Button.new(self, function()
            return axutils.childFromRight(axutils.childrenWithRole(self:UI(), "AXButton"), 1)
        end)
    end
    return self._searchToggle
end

-- TODO: Add documentation
function Libraries:search()
    if not self._search then
        self._search = TextField.new(self, function()
            return axutils.childWithID(self:mainGroupUI(), id "Search")
        end)
    end
    return self._search
end

-- TODO: Add documentation
function Libraries:filterToggle()
    if not self._filterToggle then
        self._filterToggle = Button.new(self, function()
            return axutils.childWithRole(self:mainGroupUI(), "AXButton")
        end)
    end
    return self._filterToggle
end

-- TODO: Add documentation
Libraries.ALL_CLIPS = 1
Libraries.HIDE_REJECTED = 2
Libraries.NO_RATINGS_OR_KEYWORDS = 3
Libraries.FAVORITES = 4
Libraries.REJECTED = 5
Libraries.UNUSED = 6

-- TODO: Add documentation
function Libraries:selectClipFiltering(filterType)
    local ui = self:UI()
    if ui then
        local button = axutils.childWithID(ui, id "FilterButton")
        if button then
            local menu = button[1]
            if not menu then
                button:doPress()
                menu = button[1]
            end
            local menuItem = menu[filterType]
            if menuItem then
                menuItem:doPress()
            end
        end
    end
    return self
end

-- TODO: Add documentation
function Libraries:filmstrip()
    if not self._filmstrip then
        self._filmstrip = LibrariesFilmstrip:new(self)
    end
    return self._filmstrip
end

-- TODO: Add documentation
function Libraries:list()
    if not self._list then
        self._list = LibrariesList:new(self)
    end
    return self._list
end

-- TODO: Add documentation
function Libraries:sidebar()
    if not self._sidebar then
        self._sidebar = Table.new(self, function()
            return axutils.childMatching(self:mainGroupUI(), Libraries.matchesSidebar)
        end):uncached()
    end
    return self._sidebar
end

-- TODO: Add documentation
function Libraries.matchesSidebar(element)
    return element and element:attributeValue("AXRole") == "AXScrollArea"
        and element:attributeValue("AXIdentifier") == id "Sidebar"
end

function Libraries:selectLibrary(...)
    return Table.selectRow(self:sidebar():topRowsUI(), table.pack(...))
end

function Libraries:openClipTitled(name)
    if self:selectClipTitled(name) then
        self:app():launch()
        local menuBar = self:app():menuBar()

        -- ensure the Libraries browser is focused
        menuBar:selectMenu({"Window", "Go To", "Libraries"})
        -- open the clip.
        local openClip = menuBar:findMenuUI({"Clip", "Open Clip"})
        if openClip then
            just.doUntil(function() return openClip:enabled() end)
            menuBar:selectMenu({"Clip", "Open Clip"})
            return true
        end
    end
    return false
end

-- TODO: Add documentation
function Libraries:clipsUI(filterFn)
    if self:isListView() then
        return self:list():clipsUI(filterFn)
    elseif self:isFilmstripView() then
        return self:filmstrip():clipsUI(filterFn)
    else
        return nil
    end
end

function Libraries:clips(filterFn)
    if self:isListView() then
        return self:list():clips(filterFn)
    elseif self:isFilmstripView() then
        return self:filmstrip():clips(filterFn)
    else
        return nil
    end
end

-- TODO: Add documentation
function Libraries:selectedClipsUI()
    if self:isListView() then
        return self:list():selectedClipsUI()
    elseif self:isFilmstripView() then
        return self:filmstrip():selectedClipsUI()
    else
        return nil
    end
end

function Libraries:selectedClips()
    if self:isListView() then
        return self:list():selectedClips()
    elseif self:isFilmstripView() then
        return self:filmstrip():selectedClips()
    else
        return nil
    end
end

-- TODO: Add documentation
function Libraries:showClip(clip)
    if self:isListView() then
        return self:list():showClip(clip)
    else
        return self:filmstrip():showClip(clip)
    end
end

-- TODO: Add documentation
function Libraries:selectClip(clip)
    if self:isListView() then
        return self:list():selectClip(clip)
    elseif self:isFilmstripView() then
        return self:filmstrip():selectClip(clip)
    else
        log.df("ERROR: cannot find either list or filmstrip UI")
        return false
    end
end

-- TODO: Add documentation
function Libraries:selectClipAt(index)
    if self:isListView() then
        return self:list():selectClipAt(index)
    else
        return self:filmstrip():selectClipAt(index)
    end
end

function Libraries:selectClipTitled(title)
    local clips = self:clips()
    if clips then
        for _,clip in ipairs(clips) do
            if clip:getTitle() == title then
                self:selectClip(clip)
                return true
            end
        end
    end
    return false
end

-- TODO: Add documentation
function Libraries:selectAll(clips)
    if self:isListView() then
        return self:list():selectAll(clips)
    else
        return self:filmstrip():selectAll(clips)
    end
end

-- TODO: Add documentation
function Libraries:deselectAll()
    if self:isListView() then
        return self:list():deselectAll()
    else
        return self:filmstrip():deselectAll()
    end
end

-- TODO: Add documentation
function Libraries:saveLayout()
    local layout = {}
    if self:isShowing() then
        layout.showing = true
        layout.sidebar = self:sidebar():saveLayout()
        layout.selectedClips = self:selectedClips()
    end
    return layout
end

-- TODO: Add documentation
function Libraries:loadLayout(layout)
    if layout and layout.showing then
        self:show()
        self:sidebar():loadLayout(layout.sidebar)
        self:selectAll(layout.selectedClips)
    end
end

return Libraries