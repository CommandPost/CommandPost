--- === cp.apple.finalcutpro.main.LibrariesBrowser ===
---
--- Libraries Browser Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("librariesBrowser")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local i18n                              = require("cp.i18n")
local just								= require("cp.just")
local prop								= require("cp.prop")
local axutils							= require("cp.ui.axutils")

local LibrariesList						= require("cp.apple.finalcutpro.main.LibrariesList")
local LibrariesFilmstrip				= require("cp.apple.finalcutpro.main.LibrariesFilmstrip")

local Button							= require("cp.ui.Button")
local Table								= require("cp.ui.Table")
local TextField							= require("cp.ui.TextField")

local id								= require("cp.apple.finalcutpro.ids") "LibrariesBrowser"

local Observable                        = require("cp.rx").Observable
local Do                                = require("cp.rx.go.Do")
local Given                             = require("cp.rx.go.Given")
local First                             = require("cp.rx.go.First")
local If                                = require("cp.rx.go.If")
local Throw                             = require("cp.rx.go.Throw")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local LibrariesBrowser = {}

--- cp.apple.finalcutpro.main.LibrariesBrowser.new(app) -> LibrariesBrowser
--- Constructor
--- Creates a new `LibrariesBrowser` instance.
---
--- Parameters:
---  * parent - The parent object.
---
--- Returns:
---  * A new `LibrariesBrowser` object.
function LibrariesBrowser.new(parent)
    local o = prop.extend({_parent = parent}, LibrariesBrowser)

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
        mainGroupUI = UI:mutate(function(original, self)
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

--- cp.apple.finalcutpro.main.LibrariesBrowser:parent() -> parent
--- Method
--- Returns the parent object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * parent
function LibrariesBrowser:parent()
    return self._parent
end

--- cp.apple.finalcutpro.main.LibrariesBrowser:app() -> App
--- Method
--- Returns the app instance representing Final Cut Pro.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function LibrariesBrowser:app()
    return self:parent():app()
end

-----------------------------------------------------------------------
--
-- BROWSER UI:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.LibrariesBrowser:show() -> LibrariesBrowser
--- Method
--- Show the Libraries Browser.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `LibrariesBrowser` object.
function LibrariesBrowser:show()
    local browser = self:parent()
    if browser then
        if not browser:isShowing() then
            browser:showOnPrimary()
        end
        browser:showLibraries():checked(true)
    end
    return self
end

--- cp.apple.finalcutpro.main.LibrariesBrowser:doShow() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will show the Libraries Browser.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement` object.
function LibrariesBrowser:doShow()
    local browser = self:parent()
    return Given(browser:doShow())
    :Then(function()
        browser:librariesShowing(true)
    end)
    :ThenYield()
    :Label("LibrariesBrowser:doShow")
end

--- cp.apple.finalcutpro.main.LibrariesBrowser:hide() -> LibrariesBrowser
--- Method
--- Hide the Libraries Browser.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `LibrariesBrowser` object.
function LibrariesBrowser:hide()
    self:parent():hide()
    return self
end

--- cp.apple.finalcutpro.main.LibrariesBrowser:doHide() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will hide the Libraries Browser.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement`.
function LibrariesBrowser:doHide()
    return self:parent():doHide()
end

-----------------------------------------------------------------------------
--
-- PLAYHEADS:
--
-----------------------------------------------------------------------------

--- cp.apple.finalcutpro.main.LibrariesBrowser:playhead() -> Playhead
--- Method
--- Gets the Libraries Browser Playhead.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `Playhead` object.
function LibrariesBrowser:playhead()
    if self:list():isShowing() then
        return self:list():playhead()
    else
        return self:filmstrip():playhead()
    end
end

--- cp.apple.finalcutpro.main.LibrariesBrowser:skimmingPlayhead() -> Playhead
--- Method
--- Gets the Libraries Browser Skimming Playhead.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `Playhead` object.
function LibrariesBrowser:skimmingPlayhead()
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

--- cp.apple.finalcutpro.main.LibrariesBrowser:toggleViewMode() -> Button
--- Method
--- Get Toggle View Mode button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Button` object.
function LibrariesBrowser:toggleViewMode()
    if not self._viewMode then
        self._viewMode = Button(self, function()
            return axutils.childFromRight(axutils.childrenWithRole(self:UI(), "AXButton"), 3)
        end)
    end
    return self._viewMode
end

--- cp.apple.finalcutpro.main.LibrariesBrowser:appearanceAndFiltering() -> Button
--- Method
--- Get Appearance & Filtering Button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Button` object.
function LibrariesBrowser:appearanceAndFiltering()
    if not self._appearanceAndFiltering then
        self._appearanceAndFiltering = Button(self, function()
            return axutils.childFromRight(axutils.childrenWithRole(self:UI(), "AXButton"), 2)
        end)
    end
    return self._appearanceAndFiltering
end

--- cp.apple.finalcutpro.main.LibrariesBrowser:searchToggle() -> Button
--- Method
--- Get Search Toggle Button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Button` object.
function LibrariesBrowser:searchToggle()
    if not self._searchToggle then
        self._searchToggle = Button(self, function()
            return axutils.childFromRight(axutils.childrenWithRole(self:UI(), "AXButton"), 1)
        end)
    end
    return self._searchToggle
end

--- cp.apple.finalcutpro.main.LibrariesBrowser:search() -> TextField
--- Method
--- Get Search Text Field.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `TextField` object.
function LibrariesBrowser:search()
    if not self._search then
        self._search = TextField(self, function()
            return axutils.childWithID(self:mainGroupUI(), id "Search")
        end)
    end
    return self._search
end

--- cp.apple.finalcutpro.main.LibrariesBrowser:filterToggle() -> Button
--- Method
--- The Filter Toggle Button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Button` object.
function LibrariesBrowser:filterToggle()
    if not self._filterToggle then
        self._filterToggle = Button(self, function()
            return axutils.childWithRole(self:mainGroupUI(), "AXButton")
        end)
    end
    return self._filterToggle
end

--- cp.apple.finalcutpro.main.LibrariesBrowser.ALL_CLIPS -> number
--- Constant
--- All Clips ID.
LibrariesBrowser.ALL_CLIPS = 1

--- cp.apple.finalcutpro.main.LibrariesBrowser.HIDE_REJECTED -> number
--- Constant
--- Hide Rejected ID.
LibrariesBrowser.HIDE_REJECTED = 2

--- cp.apple.finalcutpro.main.LibrariesBrowser.NO_RATINGS_OR_KEYWORDS -> number
--- Constant
--- No Rating or Keywords ID.
LibrariesBrowser.NO_RATINGS_OR_KEYWORDS = 3

--- cp.apple.finalcutpro.main.LibrariesBrowser.FAVORITES -> number
--- Constant
--- Favourites ID.
LibrariesBrowser.FAVORITES = 4

--- cp.apple.finalcutpro.main.LibrariesBrowser.REJECTED -> number
--- Constant
--- Rejected ID.
LibrariesBrowser.REJECTED = 5

--- cp.apple.finalcutpro.main.LibrariesBrowser.UNUSED -> number
--- Constant
--- Unused ID.
LibrariesBrowser.UNUSED = 6

--- cp.apple.finalcutpro.main.LibrariesBrowser:selectClipFiltering(filterType) -> LibrariesBrowser
--- Method
--- Select Clip Filtering based on Filter Type.
---
--- Parameters:
---  * filterType - The filter type.
---
--- Returns:
---  * The `LibrariesBrowser` object.
function LibrariesBrowser:selectClipFiltering(filterType)
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

--- cp.apple.finalcutpro.main.LibrariesBrowser:filmstrip() -> LibrariesFilmstrip
--- Method
--- Get Libraries Film Strip object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `LibrariesBrowser` object.
function LibrariesBrowser:filmstrip()
    if not self._filmstrip then
        self._filmstrip = LibrariesFilmstrip.new(self)
    end
    return self._filmstrip
end

--- cp.apple.finalcutpro.main.LibrariesBrowser:filmstrip() -> LibrariesList
--- Method
--- Get Libraries List object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `LibrariesList` object.
function LibrariesBrowser:list()
    if not self._list then
        self._list = LibrariesList.new(self)
    end
    return self._list
end

--- cp.apple.finalcutpro.main.LibrariesBrowser:sidebar() -> Table
--- Method
--- Get Libraries sidebar object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `Table` object.
function LibrariesBrowser:sidebar()
    if not self._sidebar then
        self._sidebar = Table(self, function()
            return axutils.childMatching(self:mainGroupUI(), LibrariesBrowser.matchesSidebar)
        end):uncached()
    end
    return self._sidebar
end

--- cp.apple.finalcutpro.main.LibrariesBrowser.matchesSidebar(element) -> boolean
--- Function
--- Checks to see if an element matches the Sidebar type.
---
--- Parameters:
---  * element - The element to check.
---
--- Returns:
---  * `true` if there's a match, otherwise `false`.
function LibrariesBrowser.matchesSidebar(element)
    return element and element:attributeValue("AXRole") == "AXScrollArea"
        and element:attributeValue("AXIdentifier") == id "Sidebar"
end

--- cp.apple.finalcutpro.main.LibrariesBrowser:selectLibrary(...) -> Table
--- Method
--- Selects a Library.
---
--- Parameters:
---  * ... - Libraries as string.
---
--- Returns:
---  * A `Table` object.
function LibrariesBrowser:selectLibrary(...)
    return Table.selectRow(self:sidebar():topRowsUI(), table.pack(...))
end

--- cp.apple.finalcutpro.main.LibrariesBrowser:openClipTitled(name) -> boolean
--- Method
--- Open a clip with a specific title.
---
--- Parameters:
---  * name - The name of the clip you want to open.
---
--- Returns:
---  * `true` if successful, otherwise `false`.
function LibrariesBrowser:openClipTitled(name)
    if self:selectClipTitled(name) then
        self:app():launch()
        local menuBar = self:app():menu()

        --------------------------------------------------------------------------------
        -- Ensure the Libraries browser is focused:
        --------------------------------------------------------------------------------
        menuBar:selectMenu({"Window", "Go To", "Libraries"})
        --------------------------------------------------------------------------------
        -- Open the clip:
        --------------------------------------------------------------------------------
        local openClip = menuBar:findMenuUI({"Clip", "Open Clip"})
        if openClip then
            just.doUntil(function() return openClip:enabled() end)
            menuBar:selectMenu({"Clip", "Open Clip"})
            return true
        end
    end
    return false
end

--- cp.apple.finalcutpro.main.LibrariesBrowser:doOpenClipTitled(title) -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will attempt to open the named clip in the Libraries Browser in the Timeline.
---
--- Parameters:
--- * title      - The title of the clip to open.
---
--- Returns:
--- * The `Statement` to execute.
function LibrariesBrowser:doOpenClipTitled(title)
    local menuBar = self:app():menu()

    return Do(self:app():doLaunch())
    :Then(self:doSelectClipTitled(title))
    :Then(menuBar:doSelectMenu({"Window", "Go To", "Libraries"}))
    :Then(menuBar:doSelectMenu({"Clip", "Open Clip"}))
    :Catch(Throw("Unable to open clip: %s", title))
    :Label("LibrariesBrowser:doOpenClipTitled")
end

--- cp.apple.finalcutpro.main.LibrariesBrowser:clipsUI(filterFn) -> table | nil
--- Method
--- Gets clip UIs using a custom filter.
---
--- Parameters:
---  * filterFn - A function to filter the UI results.
---
--- Returns:
---  * A table of `axuielementObject` objects or `nil` if no clip UI could be found.
function LibrariesBrowser:clipsUI(filterFn)
    if self:isListView() then
        return self:list():clipsUI(filterFn)
    elseif self:isFilmstripView() then
        return self:filmstrip():clipsUI(filterFn)
    else
        return nil
    end
end

--- cp.apple.finalcutpro.main.LibrariesBrowser:clips(filterFn) -> table | nil
--- Method
--- Gets clips using a custom filter.
---
--- Parameters:
---  * filterFn - A function to filter the UI results.
---
--- Returns:
---  * A table of `Clip` objects or `nil` if no clip UI could be found.
function LibrariesBrowser:clips(filterFn)
    if self:isListView() then
        return self:list():clips(filterFn)
    elseif self:isFilmstripView() then
        return self:filmstrip():clips(filterFn)
    else
        return nil
    end
end

--- cp.apple.finalcutpro.main.LibrariesBrowser:selectedClipsUI() -> table | nil
--- Method
--- Gets selected clips UI's.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of `axuielementObject` objects or `nil` if no clips are selected.
function LibrariesBrowser:selectedClipsUI()
    if self:isListView() then
        return self:list():selectedClipsUI()
    elseif self:isFilmstripView() then
        return self:filmstrip():selectedClipsUI()
    else
        return nil
    end
end

--- cp.apple.finalcutpro.main.LibrariesBrowser:selectedClips() -> table | nil
--- Method
--- Gets selected clips.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of `Clip` objects or `nil` if no clips are selected.
function LibrariesBrowser:selectedClips()
    if self:isListView() then
        return self:list():selectedClips()
    elseif self:isFilmstripView() then
        return self:filmstrip():selectedClips()
    else
        return nil
    end
end

--- cp.apple.finalcutpro.main.LibrariesBrowser:showClip(clip) -> boolean
--- Method
--- Shows a clip.
---
--- Parameters:
---  * clip - The `Clip` you want to show.
---
--- Returns:
---  * `true` if successful otherwise `false`.
function LibrariesBrowser:showClip(clip)
    if self:isListView() then
        return self:list():showClip(clip)
    else
        return self:filmstrip():showClip(clip)
    end
end

--- cp.apple.finalcutpro.main.LibrariesBrowser:selectClip(clip) -> boolean
--- Method
--- Selects a clip.
---
--- Parameters:
---  * clip - The `Clip` you want to select.
---
--- Returns:
---  * `true` if successful otherwise `false`.
function LibrariesBrowser:selectClip(clip)
    if self:isListView() then
        return self:list():selectClip(clip)
    elseif self:isFilmstripView() then
        return self:filmstrip():selectClip(clip)
    else
        log.df("ERROR: cannot find either list or filmstrip UI")
        return false
    end
end

--- cp.apple.finalcutpro.main.LibrariesBrowser:selectClipAt(index) -> boolean
--- Method
--- Select clip at a specific index.
---
--- Parameters:
---  * index - A number of where the clip appears in the list.
---
--- Returns:
---  * `true` if successful otherwise `false`.
function LibrariesBrowser:selectClipAt(index)
    if self:isListView() then
        return self:list():selectClipAt(index)
    else
        return self:filmstrip():selectClipAt(index)
    end
end

--- cp.apple.finalcutpro.main.LibrariesBrowser:selectClipTitled(title) -> boolean
--- Method
--- Select clip with a specific title.
---
--- Parameters:
---  * title - The title of a clip.
---
--- Returns:
---  * `true` if successful otherwise `false`.
function LibrariesBrowser:selectClipTitled(title)
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

--- cp.apple.finalcutpro.main.LibrariesBrowser:doFindClips(filter) -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) which will send each clip in the Libraries Browser matching the `filter` as an `onNext` signal.
---
--- Parameters:
--- * filter    - a function which receives the [Clip](cp.apple.finalcutpro.content.Clip.md) to check and returns `true` or `false`.
---
--- Returns:
--- * The `Statement`.
function LibrariesBrowser:doFindClips(filter)
    return Do(function() return Observable.fromTable(self:clips(filter)) end)
end

--- cp.apple.finalcutpro.main.LibrariesBrowser:doFindClipsTitled(title) -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) which will send each clip in the Libraries Browser with the specified `title` as an `onNext` signal.
---
--- Parameters:
--- * title    - The title string to check for.
---
--- Returns:
--- * The `Statement`.
function LibrariesBrowser:doFindClipsTitled(title)
    return self:doFindClips(function(clip) return clip and clip:getTitle() == title end)
end

--- cp.apple.finalcutpro.main.LibrariesBrowser:doSelectClipTitled(title) -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) which will select the first clip with a matching `title`.
---
--- Parameters:
--- * title     - The title to select.
---
--- Returns:
--- * The `Statement` ready to execute.
function LibrariesBrowser:doSelectClipTitled(title)
    return If(
        First(self:doFindClipsTitled(title))
    ):Then(function(clip)
        return self:selectClip(clip)
    end)
    :Catch(Throw(i18n("LibrariesBrowser_NoClipTitled", {title = title})))
    :ThenYield()
    :Label("LibrariesBrowser:doSelectClipTitled")
end

--- cp.apple.finalcutpro.main.LibrariesBrowser:selectAll([clips]) -> boolean
--- Method
--- Select all clips.
---
--- Parameters:
---  * clips - A optional table of `Clip` objects.
---
--- Returns:
---  * `true` if successful otherwise `false`.
function LibrariesBrowser:selectAll(clips)
    if self:isListView() then
        return self:list():selectAll(clips)
    else
        return self:filmstrip():selectAll(clips)
    end
end

--- cp.apple.finalcutpro.main.LibrariesBrowser:deselectAll() -> boolean
--- Function
--- Deselect all clips.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if successful otherwise `false`.
function LibrariesBrowser:deselectAll()
    if self:isListView() then
        return self:list():deselectAll()
    else
        return self:filmstrip():deselectAll()
    end
end

--- cp.apple.finalcutpro.main.LibrariesBrowser:saveLayout() -> table
--- Method
--- Saves the current Libraries Browser layout to a table.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table containing the current Libraries Browser Layout.
function LibrariesBrowser:saveLayout()
    local layout = {}
    if self:isShowing() then
        layout.showing = true
        layout.sidebar = self:sidebar():saveLayout()
        layout.selectedClips = self:selectedClips()
    end
    return layout
end

--- cp.apple.finalcutpro.main.LibrariesBrowser:loadLayout(layout) -> none
--- Method
--- Loads a Libraries Browser layout.
---
--- Parameters:
---  * layout - A table containing the Libraries Browser layout settings - created using `cp.apple.finalcutpro.main.LibrariesBrowser:saveLayout()`.
---
--- Returns:
---  * None
function LibrariesBrowser:loadLayout(layout)
    if layout and layout.showing then
        self:show()
        self:sidebar():loadLayout(layout.sidebar)
        self:selectAll(layout.selectedClips)
    end
end

return LibrariesBrowser
