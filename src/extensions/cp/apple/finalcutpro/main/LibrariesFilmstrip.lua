--- === cp.apple.finalcutpro.main.LibrariesFilmstrip ===
---
--- Libraries Filmstrip Module.

local require = require

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local FilmClip                          = require("cp.apple.finalcutpro.content.FilmClip")
local Playhead                          = require("cp.apple.finalcutpro.main.Playhead")

local go                                = require("cp.rx.go")
local axutils                           = require("cp.ui.axutils")
local ScrollArea	                    = require("cp.ui.ScrollArea")

local If                                = go.If

--------------------------------------------------------------------------------
-- 3rd Party Extensions:
--------------------------------------------------------------------------------
local _                                    = require("moses")

local cache                             = axutils.cache
local isValid                           = axutils.isValid
local childrenMatching                  = axutils.childrenMatching

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local LibrariesFilmstrip = ScrollArea:subclass("cp.apple.finalcutpro.main.LibrariesFilmstrip")

--- cp.apple.finalcutpro.main.LibrariesFilmstrip(app) -> LibrariesFilmstrip
--- Constructor
--- Creates a new `LibrariesFilmstrip` instance.
---
--- Parameters:
---  * parent - The parent object
---
--- Returns:
---  * A new `LibrariesFilmstrip` object.
function LibrariesFilmstrip:initialize(parent)
    local UI = parent.mainGroupUI:mutate(function(original) -- mainGroupUI is an AXSplitGroup (_NS:296)
        return cache(self, "_ui", function()
            local main = original()
            if main then
                for _,child in ipairs(main) do
                    if child:attributeValue("AXRole") == "AXGroup" and #child == 1 then
                        if LibrariesFilmstrip.matches(child[1]) then
                            return child[1]
                        end
                    end
                end
            end
            return nil
        end,
        LibrariesFilmstrip.matches)
    end)

    ScrollArea.initialize(self, parent, UI)
end

--- cp.apple.finalcutpro.main.LibrariesFilmstrip.isShowing <cp.prop: boolean; read-only>
--- Field
--- Checks if the Libraries Filmstrip is showing on screen.
function LibrariesFilmstrip.lazy.prop:isShowing()
    return self:parent().isShowing:AND(self.UI:ISNOT(nil))
end

--- cp.apple.finalcutpro.main.LibrariesFilmstrip.contentsUI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- Returns the `axuielement` representing the 'content', or `nil` if not available.
function LibrariesFilmstrip.lazy.prop:contentsUI()
    return self.UI:mutate(function(original)
        local ui = original()
        return ui and ui:contents()[1]
    end)
end

-----------------------------------------------------------------------
--
-- TIMELINE CONTENT UI:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.LibrariesFilmstrip:show() -> LibrariesFilmstrip
--- Method
--- Show the Libraries Filmstrip.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `LibrariesFilmstrip` object
function LibrariesFilmstrip:show()
    if not self:isShowing() and self:parent():show():isShowing() then
        self:parent():toggleViewMode():press()
    end
    return self
end

--- cp.apple.finalcutpro.main.LibrariesFilmstrip:doShow() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will attempt to show the Libraries Browser in filmstrip mode.
function LibrariesFilmstrip.lazy.method:doShow()
    return If(self.isShowing):Is(false)
    :Then(
        If(self:parent():doShow())
        :Then(self:parent():toggleViewMode():doPress())
        :Otherwise(false)
    )
    :Otherwise(true)
    :Label("LibrariesFilmstrip:doShow")
end

-----------------------------------------------------------------------
--
-- PLAYHEADS:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.LibrariesFilmstrip:playhead() -> Playhead
--- Method
--- Get the Libraries Filmstrip Playhead.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `Playhead` object
function LibrariesFilmstrip.lazy.method:playhead()
    return Playhead(self, false, self.contentsUI, true)
end

--- cp.apple.finalcutpro.main.LibrariesFilmstrip:skimmingPlayhead() -> Playhead
--- Method
--- Get the Libraries Filmstrip Skimming Playhead.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `Playhead` object
function LibrariesFilmstrip.lazy.method:skimmingPlayhead()
    return Playhead(self, true, self.contentsUI, true)
end

-----------------------------------------------------------------------
--
-- CLIPS:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.LibrariesFilmstrip.sortClips(a,b) -> boolean
--- Function
--- Determines if clip A is above clip B or not.
---
--- Parameters:
---  * a - Clip A
---  * b - Clip B
---
--- Returns:
---  * `true` if clip A is above clip B, otherwise `false`.
function LibrariesFilmstrip.static.sortClips(a, b)
    local aFrame = a:frame()
    local bFrame = b:frame()
    if aFrame.y < bFrame.y then -- a is above b
        return true
    elseif aFrame.y == bFrame.y then
        if aFrame.x < bFrame.x then -- a is left of b
            return true
        elseif aFrame.x == bFrame.x
           and aFrame.w < bFrame.w then -- a starts with but finishes before b, so b must be multi-line
            return true
        end
    end
    return false -- b is first
end

-- _uiToClips(clipsUI) -> none
-- Function
-- Converts a table of `axuielementObject` objects to `Clip` objects.
--
-- Parameters:
--  * clipsUI - Table of `axuielementObject` objects.
--
-- Returns:
--  * A table of `Clip` objects.
local function _uiToClips(clipsUI)
    return _.map(clipsUI, function(_,clipUI) return FilmClip(clipUI) end)
end

-- _clipsToUI(clips) -> none
-- Function
-- Converts a table of `Clip` objects to `axuielementObject` objects.
--
-- Parameters:
--  * clips - Table of `Clip` objects
--
-- Returns:
--  * A table of `axuielementObject` objects.
local function _clipsToUI(clips)
    return _.map(clips, function(_,clip) return clip:UI() end)
end

--- cp.apple.finalcutpro.main.LibrariesFilmstrip:clipsUI(filterFn) -> table | nil
--- Function
--- Gets clip UIs using a custom filter.
---
--- Parameters:
---  * filterFn - A function to filter the UI results.
---
--- Returns:
---  * A table of `axuielementObject` objects or `nil` if no clip UI could be found.
function LibrariesFilmstrip:clipsUI(filterFn)
    local ui = self:contentsUI()
    if ui then
        local clips = childrenMatching(ui, function(child)
            return child:attributeValue("AXRole") == "AXGroup"
               and (filterFn == nil or filterFn(child))
        end)
        if clips then
            table.sort(clips, LibrariesFilmstrip.sortClips)
            return clips
        end
    end
    return nil
end

--- cp.apple.finalcutpro.main.LibrariesFilmstrip:clips(filterFn) -> table | nil
--- Function
--- Gets clips using a custom filter.
---
--- Parameters:
---  * filterFn - A function to filter the UI results.
---
--- Returns:
---  * A table of `Clip` objects or `nil` if no clip UI could be found.
function LibrariesFilmstrip:clips(filterFn)
    local clipsUI = self:clipsUI()
    if clipsUI then
        local clips = _uiToClips(clipsUI)
        if filterFn then
            clips = _.filter(clips, function(_,clip) return filterFn(clip) end)
        end
        return clips
    end
end

--- cp.apple.finalcutpro.main.LibrariesFilmstrip:selectedClipsUI() -> table | nil
--- Function
--- Gets selected clips UI's.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of `axuielementObject` objects or `nil` if no clips are selected.
function LibrariesFilmstrip:selectedClipsUI()
    local ui = self:contentsUI()
    if ui then
        local children = ui:selectedChildren()
        local clips = {}
        for i,child in ipairs(children) do
            clips[i] = child
        end
        table.sort(clips, LibrariesFilmstrip.sortClips)
        return clips
    end
    return nil
end

--- cp.apple.finalcutpro.main.LibrariesFilmstrip:selectedClips() -> table | nil
--- Function
--- Gets selected clips.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of `Clip` objects or `nil` if no clips are selected.
function LibrariesFilmstrip:selectedClips()
    return _uiToClips(self:selectedClipsUI())
end

--- cp.apple.finalcutpro.main.LibrariesFilmstrip:showClip(clip) -> boolean
--- Function
--- Shows a clip.
---
--- Parameters:
---  * clip - The `Clip` you want to show.
---
--- Returns:
---  * `true` if successful otherwise `false`.
function LibrariesFilmstrip:showClip(clip)
    return self:showChild(clip:UI())
end

--- cp.apple.finalcutpro.main.LibrariesFilmstrip:showClipAt(index) -> boolean
--- Function
--- Shows a clip at a specific index.
---
--- Parameters:
---  * index - The index of the clip you want to show.
---
--- Returns:
---  * `true` if successful otherwise `false`.
function LibrariesFilmstrip:showClipAt(index)
    local ui = self:clips()
    if ui and #ui >= index then
        return self:showClip(ui[index])
    end
    return false
end

--- cp.apple.finalcutpro.main.LibrariesFilmstrip.selectClip(clip) -> boolean
--- Function
--- Selects a clip.
---
--- Parameters:
---  * clip - The `Clip` you want to select.
---
--- Returns:
---  * `true` if successful otherwise `false`.
function LibrariesFilmstrip:selectClip(clip) -- luacheck:ignore
    if clip then
        local clipUI = clip:UI()
        if isValid(clipUI) then
            clipUI:parent():setSelectedChildren( { clipUI } )
            return true
        end
    end
    return false
end

--- cp.apple.finalcutpro.main.LibrariesFilmstrip:selectClipAt(index) -> boolean
--- Function
--- Select clip at a specific index.
---
--- Parameters:
---  * index - A number of where the clip appears in the list.
---
--- Returns:
---  * `true` if successful otherwise `false`.
function LibrariesFilmstrip:selectClipAt(index)
    local ui = self:clips()
    if ui and #ui >= index then
        return self:selectClip(ui[index])
    end
    return false
end

--- cp.apple.finalcutpro.main.LibrariesFilmstrip:selectClipTitled(title) -> boolean
--- Function
--- Select clip with a specific title.
---
--- Parameters:
---  * title - The title of a clip.
---
--- Returns:
---  * `true` if successful otherwise `false`.
function LibrariesFilmstrip:selectClipTitled(title)
    local clips = self:clips()
    for _,clip in ipairs(clips) do
        if clip:title() == title then
            return self:selectClip(clip)
        end
    end
    return false
end

--- cp.apple.finalcutpro.main.LibrariesFilmstrip:selectAll([clips]) -> boolean
--- Function
--- Select all clips.
---
--- Parameters:
---  * clips - A optional table of `Clip` objects.
---
--- Returns:
---  * `true` if successful otherwise `false`.
function LibrariesFilmstrip:selectAll(clips)
    clips = clips or self:clips()
    local contents = self:contentsUI()
    if clips and contents then
        local clipsUI = _clipsToUI(clips)
        contents:setSelectedChildren(clipsUI)
        return true
    end
    return false
end

--- cp.apple.finalcutpro.main.LibrariesFilmstrip:deselectAll() -> boolean
--- Function
--- Deselect all clips.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if successful otherwise `false`.
function LibrariesFilmstrip:deselectAll()
    local contents = self:contentsUI()
    if contents then
        contents:setSelectedChildren({})
        return true
    end
    return false
end

return LibrariesFilmstrip
