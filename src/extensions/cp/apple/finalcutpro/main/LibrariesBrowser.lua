--- === cp.apple.finalcutpro.main.LibrariesBrowser ===
---
--- Libraries Browser Module.

local require = require

local log                       = require "hs.logger".new "librariesBrowser"

local axutils                   = require "cp.ui.axutils"
local go                        = require "cp.rx.go"
local Group                     = require "cp.ui.Group"
local i18n                      = require "cp.i18n"
local just                      = require "cp.just"

local AppearanceAndFiltering    = require "cp.apple.finalcutpro.browser.AppearanceAndFiltering"
local LibrariesFilmstrip        = require "cp.apple.finalcutpro.main.LibrariesFilmstrip"
local LibrariesList             = require "cp.apple.finalcutpro.main.LibrariesList"
local LibrariesSidebar          = require "cp.apple.finalcutpro.main.LibrariesSidebar"

local Button                    = require "cp.ui.Button"
local PopUpButton               = require "cp.ui.PopUpButton"
local SplitGroup                = require "cp.ui.SplitGroup"
local Table                     = require "cp.ui.Table"
local TextField                 = require "cp.ui.TextField"

local Do                        = go.Do
local First                     = go.First
local Given                     = go.Given
local If                        = go.If
local Observable                = go.Observable
local Throw                     = go.Throw

local cache                     = axutils.cache
local childFromRight            = axutils.childFromRight
local childMatching             = axutils.childMatching
local childWith                 = axutils.childWith
local childWithRole             = axutils.childWithRole

local LibrariesBrowser = Group:subclass("cp.apple.finalcutpro.main.LibrariesBrowser")

function LibrariesBrowser.static.matches(element)
    return Group.matches(element)
end

--- cp.apple.finalcutpro.main.LibrariesBrowser(app) -> LibrariesBrowser
--- Constructor
--- Creates a new `LibrariesBrowser` instance.
---
--- Parameters:
---  * parent - The parent object.
---
--- Returns:
---  * A new `LibrariesBrowser` object.
function LibrariesBrowser:initialize(parent)
    -- checks if the Libraries Browser is showing
    local isShowing = parent.isShowing:AND(parent.librariesShowing)

    local UI = parent.UI:mutate(function(original)
        return isShowing() and original() or nil
    end)

    Group.initialize(self, parent, UI)
end

--- cp.apple.finalcutpro.main.LibrariesBrowser.mainGroupUI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- Returns the main group within the Libraries Browser, or `nil` if not available..
function LibrariesBrowser.lazy.prop:mainGroupUI()
    return self.UI:mutate(function(original)
        return cache(self, "_mainGroup", function()
            local ui = original()
            return ui and childWithRole(ui, "AXSplitGroup")
        end, SplitGroup.matches)
    end)
end

--- cp.apple.finalcutpro.main.LibrariesBrowser.isFocused <cp.prop: boolean; read-only>
--- Field
--- Indicates if the Libraries Browser is the current focus.
function LibrariesBrowser.lazy.prop:isFocused()
    return self.UI:mutate(function(original)
        local ui = original()
        return ui and ui:attributeValue("AXFocused") or childWith(ui, "AXFocused", true) ~= nil
    end)
end

--- cp.apple.finalcutpro.main.LibrariesBrowser.isListView <cp.prop: boolean; read-only>
--- Field
--- Indicates if the Library Browser is in 'list view' mode.
function LibrariesBrowser.lazy.prop:isListView()
    return self:list().isShowing
end

--- cp.apple.finalcutpro.main.LibrariesBrowser.isFilmstripView <cp.prop: boolean; read-only>
--- Field
--- Indicates if the Library Browser is in 'filmstrip view' mode.
function LibrariesBrowser.lazy.prop:isFilmstripView()
    return self:filmstrip().isShowing
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
function LibrariesBrowser.lazy.method:doShow()
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
function LibrariesBrowser.lazy.method:doHide()
    return self:parent():doHide()
    :Label("LibrariesBrowser:doHide")
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

--- cp.apple.finalcutpro.main.LibrariesBrowser.toggleViewMode <cp.ui.Button>
--- Field
--- The Toggle View Mode [Button](cp.ui.Button.md).
function LibrariesBrowser.lazy.value:toggleViewMode()
    return Button(self, self.UI:mutate(function(original)
        return childFromRight(original(), 3, Button.matches)
    end))
end

--- cp.apple.finalcutpro.main.LibrariesBrowser.searchToggle <cp.ui.Button>
--- Field
--- The Search Toggle [Button](cp.ui.Button.md).
function LibrariesBrowser.lazy.value:searchToggle()
    return Button(self, self.UI:mutate(function(original)
        return childFromRight(original(), 1, Button.matches)
    end))
end

--- cp.apple.finalcutpro.main.LibrariesBrowser.search <cp.ui.TextField>
--- Field
--- The Search [TextField](cp.ui.TextField.md).
function LibrariesBrowser.lazy.value:search()
    return TextField(self, self.mainGroupUI:mutate(function(original)
        return childMatching(original(), TextField.matches)
    end))
end

--- cp.apple.finalcutpro.main.LibrariesBrowser.clipFiltering <cp.ui.PopUpButton>
--- Field
--- The Clip Filtering [PopUpButton](cp.ui.PopUpButton.md).
function LibrariesBrowser.lazy.value:clipFiltering()
    return PopUpButton(self, self.UI:mutate(function(original)
        return childMatching(original(), PopUpButton.matches)
    end))
end

--- cp.apple.finalcutpro.main.Browser.appearanceAndFiltering <cp.apple.finalcutpro.main.AppearanceAndFiltering>
--- Method
--- The Clip [AppearanceAndFiltering](cp.apple.finalcutpro.main.AppearanceAndFiltering.md) Menu Popover
function LibrariesBrowser.lazy.value:appearanceAndFiltering()
    return AppearanceAndFiltering(self)
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
function LibrariesBrowser.lazy.method:filmstrip()
    return LibrariesFilmstrip.new(self)
end

--- cp.apple.finalcutpro.main.LibrariesBrowser:list() -> LibrariesList
--- Method
--- Get [LibrariesList](cp.apple.finalcutpro.main.LibrariesList.md) object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `LibrariesList` object.
function LibrariesBrowser.lazy.method:list()
    return LibrariesList.new(self)
end

--- cp.apple.finalcutpro.main.LibrariesBrowser.sidebar <cp.apple.finalcutpro.main.LibrariesSidebar>
--- Method
--- The  [LibrariesSidebar](cp.apple.finalcutpro.main.LibrariesSidebar.md) Table
function LibrariesBrowser.lazy.value:sidebar()
    return LibrariesSidebar(self)
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

--- cp.apple.finalcutpro.main.LibrariesBrowser:indexOfClip(clip) -> number | nil
--- Function
--- Gets the index of a specific clip.
---
--- Parameters:
---  * clip - The `Clip` you want to get the index of.
---
--- Returns:
---  * The index or `nil` if an error occurs.
function LibrariesBrowser:indexOfClip(clip)
    if self:isListView() then
        return self:list():indexOfClip(clip)
    else
        return self:filmstrip():indexOfClip(clip)
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
        layout.sidebar = self.sidebar:saveLayout()
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
        self.sidebar:loadLayout(layout.sidebar)
        self:selectAll(layout.selectedClips)
    end
end

return LibrariesBrowser
