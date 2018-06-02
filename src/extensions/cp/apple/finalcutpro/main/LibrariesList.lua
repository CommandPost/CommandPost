--- === cp.apple.finalcutpro.main.LibrariesList ===
---
--- Libraries List Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils							= require("cp.ui.axutils")
local Clip								= require("cp.apple.finalcutpro.content.Clip")
local id								= require("cp.apple.finalcutpro.ids") "LibrariesList"
local Playhead							= require("cp.apple.finalcutpro.main.Playhead")
local prop								= require("cp.prop")
local Table								= require("cp.ui.Table")

--------------------------------------------------------------------------------
-- 3rd Party Extensions:
--------------------------------------------------------------------------------
local _									= require("moses")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local LibrariesList = {}

--- cp.apple.finalcutpro.main.CommandEditor.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function LibrariesList.matches(element)
    return element and element:attributeValue("AXRole") == "AXSplitGroup"
end

--- cp.apple.finalcutpro.main.LibrariesList.new(app) -> LibrariesList
--- Constructor
--- Creates a new `LibrariesList` instance.
---
--- Parameters:
---  * parent - The parent object.
---
--- Returns:
---  * A new `LibrariesList` object.
function LibrariesList.new(parent)
    local o = prop.extend({_parent = parent}, LibrariesList)

    local UI = parent.mainGroupUI:mutate(function(original)
        return axutils.cache(o, "_ui", function()
            local main = original()
            if main then
                for _,child in ipairs(main) do
                    if child:attributeValue("AXRole") == "AXGroup" and #child == 1 then
                        if LibrariesList.matches(child[1]) then
                            return child[1]
                        end
                    end
                end
            end
            return nil
        end, LibrariesList.matches)
    end)

    local playerUI = UI:mutate(function(original, self)
        return axutils.cache(self, "_player", function()
            return axutils.childFromTop(original(), id "Player")
        end)
    end)

    prop.bind(o) {
        --- cp.apple.finalcutpro.main.LibrariesList.UI <cp.prop: hs._asm.axuielement; read-only>
        --- Field
        --- The `axuielement` for the Libraries List, or `nil` if not available.
        UI = UI,

        --- cp.apple.finalcutpro.main.LibrariesList.playerUI <cp.prop: hs._asm.axuielement; read-only>
        --- Field
        --- The `axuielement` for the player section of the Libraries List UI.
        playerUI = playerUI,

        --- cp.apple.finalcutpro.main.LibrariesList.isShowing <cp.prop: boolean; read-only>
        --- Field
        --- Checks if the Libraries List is showing on screen.
        isShowing = parent.isShowing:AND(UI:ISNOT(nil)),

        --- cp.apple.finalcutpro.main.LibrariesList.isFocused <cp.prop: boolean; read-only>
        --- Field
        --- Checks if the Libraries List is currently focused within FCPX.
        isFocused = o:contents().isFocused:OR(playerUI:mutate(function(original)
            local ui = original()
            return ui ~= nil and ui:attributeValue("AXFocused") == true
        end)),
    }

    return o
end

--- cp.apple.finalcutpro.main.LibrariesList:parent() -> parent
--- Method
--- Returns the parent object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * parent
function LibrariesList:parent()
    return self._parent
end

--- cp.apple.finalcutpro.main.LibrariesList:app() -> App
--- Method
--- Returns the app instance representing Final Cut Pro.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function LibrariesList:app()
    return self:parent():app()
end

-----------------------------------------------------------------------
--
-- UI:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.LibrariesList:show() -> LibrariesList
--- Method
--- Show the Libraries List.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `LibrariesList` object
function LibrariesList:show()
    if not self:isShowing() and self:parent():show():isShowing() then
        self:parent():toggleViewMode():press()
    end
end

-----------------------------------------------------------------------
--
-- PREVIEW PLAYER:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.LibrariesList:playhead() -> Playhead
--- Method
--- Get the Libraries List Playhead.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `Playhead` object
function LibrariesList:playhead()
    if not self._playhead then
        self._playhead = Playhead.new(self, false, function()
            return self:playerUI()
        end)
    end
    return self._playhead
end

--- cp.apple.finalcutpro.main.LibrariesList:skimmingPlayhead() -> Playhead
--- Method
--- Get the Libraries List Skimming Playhead.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `Playhead` object
function LibrariesList:skimmingPlayhead()
    if not self._skimmingPlayhead then
        self._skimmingPlayhead = Playhead.new(self, true, function()
            return self:playerUI()
        end)
    end
    return self._skimmingPlayhead
end

-----------------------------------------------------------------------
--
-- LIBRARY CONTENT:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.LibrariesList:contents() -> Table
--- Method
--- Get the Libraries List Contents UI.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `Table` object
function LibrariesList:contents()
    if not self._content then
        self._content = Table.new(self, function()
            return axutils.childWithRole(self:UI(), "AXScrollArea")
        end)
    end
    return self._content
end

--- cp.apple.finalcutpro.main.LibrariesList:clipsUI(filterFn) -> table | nil
--- Function
--- Gets clip UIs using a custom filter.
---
--- Parameters:
---  * filterFn - A function to filter the UI results.
---
--- Returns:
---  * A table of `axuielementObject` objects or `nil` if no clip UI could be found.
function LibrariesList:clipsUI(filterFn)
    local rowsUI = self:contents():rowsUI()
    if rowsUI then
        local level = 0
        -- if the first row has no icon, it's a group
        local firstCell = self:contents():findCellUI(1, "filmlist name col")
        if firstCell and axutils.childWithID(firstCell, id "RowIcon") == nil then
            level = 1
        end
        return axutils.childrenMatching(rowsUI, function(row)
            return row:attributeValue("AXDisclosureLevel") == level
               and (filterFn == nil or filterFn(row))
        end)
    end
    return nil
end

-- cp.apple.finalcutpro.main.LibrariesList:uiToClips(clipsUI) -> none
-- Function
-- Converts a table of `axuielementObject` objects to `Clip` objects.
--
-- Parameters:
--  * clipsUI - Table of `axuielementObject` objects.
--
-- Returns:
--  * A table of `Clip` objects.
function LibrariesList:_uiToClips(clipsUI)
    local columnIndex = self:contents():findColumnIndex("filmlist name col")
    local options = {columnIndex = columnIndex}
    return _.map(clipsUI, function(_,clipUI)
        return Clip.new(clipUI, options)
    end)
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

--- cp.apple.finalcutpro.main.LibrariesList:clips(filterFn) -> table | nil
--- Function
--- Gets clips using a custom filter.
---
--- Parameters:
---  * filterFn - A function to filter the UI results.
---
--- Returns:
---  * A table of `Clip` objects or `nil` if no clip UI could be found.
function LibrariesList:clips(filterFn)
    local clips = self:_uiToClips(self:clipsUI())
    if filterFn then
        clips = _.filter(clips, function(_,clip) return filterFn(clip) end)
    end
    return clips

end

--- cp.apple.finalcutpro.main.LibrariesList:selectedClipsUI() -> table | nil
--- Function
--- Gets selected clips UI's.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of `axuielementObject` objects or `nil` if no clips are selected.
function LibrariesList:selectedClipsUI()
    return self:contents():selectedRowsUI()
end

--- cp.apple.finalcutpro.main.LibrariesList:selectedClips() -> table | nil
--- Function
--- Gets selected clips.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of `Clip` objects or `nil` if no clips are selected.
function LibrariesList:selectedClips()
    return self:_uiToClips(self:contents():selectedRowsUI())
end

--- cp.apple.finalcutpro.main.LibrariesList:showClip(clip) -> boolean
--- Function
--- Shows a clip.
---
--- Parameters:
---  * clip - The `Clip` you want to show.
---
--- Returns:
---  * `true` if successful otherwise `false`.
function LibrariesList:showClip(clip)
    if clip then
        local clipUI = clip:UI()
        if axutils.isValid(clipUI) then
            self:contents():showRow(clipUI)
            return true
        end
    end
    return false
end

--- cp.apple.finalcutpro.main.LibrariesList:selectClip(clip) -> boolean
--- Function
--- Selects a clip.
---
--- Parameters:
---  * clip - The `Clip` you want to select.
---
--- Returns:
---  * `true` if successful otherwise `false`.
function LibrariesList:selectClip(clip)
    if clip then
        local clipUI = clip:UI()
        if axutils.isValid(clipUI) then
            self:contents():selectRow(clip:UI())
            return true
        end
    end
    return false
end

--- cp.apple.finalcutpro.main.LibrariesList:selectClipAt(index) -> boolean
--- Function
--- Select clip at a specific index.
---
--- Parameters:
---  * index - A number of where the clip appears in the list.
---
--- Returns:
---  * `true` if successful otherwise `false`.
function LibrariesList:selectClipAt(index)
    local clips = self:clipsUI()
    if clips and #clips <= index then
        self:contents():selectRow(clips[index])
        return true
    end
    return false
end

--- cp.apple.finalcutpro.main.LibrariesList:selectClipTitled(title) -> boolean
--- Function
--- Select clip with a specific title.
---
--- Parameters:
---  * title - The title of a clip.
---
--- Returns:
---  * `true` if successful otherwise `false`.
function LibrariesList:selectClipTitled(title)
    local clips = self:clips()
    for _,clip in ipairs(clips) do
        if clip:getTitle() == title then
            return self:selectClip(clip)
        end
    end
    return false
end

--- cp.apple.finalcutpro.main.LibrariesList:selectAll([clips]) -> boolean
--- Function
--- Select all clips.
---
--- Parameters:
---  * clips - A optional table of `Clip` objects.
---
--- Returns:
---  * `true` if successful otherwise `false`.
function LibrariesList:selectAll(clips)
    clips = clips or self:clips()
    if clips then
        self:contents():selectAll(_clipsToUI(clips))
        return true
    end
    return false
end

--- cp.apple.finalcutpro.main.LibrariesList:deselectAll() -> boolean
--- Function
--- Deselect all clips.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if successful otherwise `false`.
function LibrariesList:deselectAll(clips)
    clips = clips or self:clips()
    if clips then
        self:contents():deselectAll(_clipsToUI(clips))
        return true
    end
    return false
end

return LibrariesList