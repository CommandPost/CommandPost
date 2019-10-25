--- === cp.apple.finalcutpro.content.Clip ===
---
--- Represents a clip of media inside FCP.

local require           = require

--local log               = require "hs.logger".new "Clip"

local axutils           = require "cp.ui.axutils"
local Table             = require "cp.ui.Table"

local childWithRole     = axutils.childWithRole

local Clip = {}
Clip.mt = {}
Clip.type = {}

--- cp.apple.finalcutpro.content.Clip.type.filmstrip
--- Constant
--- A constant for clips which are represented by a filmstrip.
Clip.type.filmstrip = "filmstrip"

--- cp.apple.finalcutpro.content.Clip.type.row
--- Constant
--- A constant for clips which are represented by a table row.
Clip.type.row = "row"

--- cp.apple.finalcutpro.content.Clip:UI() -> axuielement
--- Method
--- Returns the `axuielement` for the clip.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `axuielement` for the clip.
function Clip.mt:UI()
    return self._element
end

--- cp.apple.finalcutpro.content.Clip:getType() -> Clip.type
--- Method
--- Returns the type of clip (one of the `Clip.type` values)
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Clip.type` value (e.g. `Clip.type.row` or Clip.type.filmstrip`)
function Clip.mt:getType()
    return self._type
end

--- cp.apple.finalcutpro.content.Clip:getTitle() -> String
--- Method
--- Returns the title of the clip.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The clip title.
function Clip.mt:getTitle()
    if self:getType() == Clip.type.row then
        local colIndex = self._options.columnIndex
        local cell = self._element[colIndex]
        return Table.cellTextValue(cell)
    else
        return self._element:attributeValue("AXDescription")
    end
end

--- cp.apple.finalcutpro.content.Clip:setTitle(title) -> none
--- Method
--- Sets the title of a clip.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function Clip.mt:setTitle(title)
    if self:getType() == Clip.type.row then
        local colIndex = self._options.columnIndex
        local cell = self._element[colIndex]
        local textfield = cell and childWithRole(cell, "AXTextField")
        if textfield then
            textfield:setAttributeValue("AXValue", title)
        end
    else
        local textfield = self._element and childWithRole(self._element, "AXTextField")
        if textfield then
            textfield:setAttributeValue("AXValue", title)
        end
    end
end

--- cp.apple.finalcutpro.content.Clip.new(element[, options]) -> Clip
--- Constructor
--- Creates a new `Clip` pointing at the specified element, with the specified options.
---
--- Parameters:
---  * `element`        - The `axuielement` the clip represents.
---  * `options`        - A table containing the options for the clip.
---
--- Returns:
---  * The new `Clip`.
---
--- Notes:
---  * The options may be:
---  ** `columnIndex`   - A number which will be used to specify the column number to find the title in, if relevant.
function Clip.new(element, options)
    local o = {
        _element    = element,
        _options    = options or {},
        _type       = element:attributeValue("AXRole") == "AXRow" and Clip.type.row or Clip.type.filmstrip,
    }
    return setmetatable(o, {__index = Clip.mt})
end

--- cp.apple.finalcutpro.content.Clip.is(thing) -> boolean
--- Function
--- Checks if the specified `thing` is a `Clip` instance.
---
--- Parameters:
---  * `thing`  - The thing to check.
---
--- Returns:
---  * `true` if the `thing` is a `Clip`, otherwise returns `false`.
function Clip.is(thing)
    return thing and getmetatable(thing) == Clip.mt
end

return Clip
