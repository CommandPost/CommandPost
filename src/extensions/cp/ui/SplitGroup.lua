--- === cp.ui.SplitGroup ===
---
--- Split Group UI.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils           = require("cp.ui.axutils")
local prop              = require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local SplitGroup = {}

--- cp.ui.SplitGroup.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function SplitGroup.matches(element)
    return element ~= nil and element:attributeValue("AXRole") == "AXSplitGroup"
end

--- cp.ui.SplitGroup.new(parent, finderFn) -> cp.ui.SplitGroup
--- Constructor
--- Creates a new Split Group.
---
--- Parameters:
---  * parent		- The parent object.
---  * finderFn		- The function which returns an `hs._asm.axuielement` for the Split Group, or `nil`.
---
--- Returns:
---  * A new `SplitGroup` instance.
function SplitGroup.new(parent, finderFn)
    local o = prop.extend({
        _parent = parent,
        _finder = finderFn,
    }, SplitGroup)

    local UI = prop(function(self)
        return axutils.cache(self, "_ui", function()
            return self._finder()
        end, SplitGroup.matches)
    end)

    prop.bind(o) {

        --- cp.ui.SplitGroup.UI <cp.prop: hs._asm.axuielement; read-only>
        --- Field
        --- The `axuielement` representing the Split Group, or `nil` if not available.
        UI = UI,

        --- cp.ui.SplitGroup.isShowing <cp.prop: boolean; read-only>
        --- Field
        --- If `true`, it is visible on screen.
        isShowing = UI:ISNOT(nil),
    }

    return o
end

--- cp.ui.SplitGroup:parent() -> table
--- Method
--- The parent object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object.
function SplitGroup:parent()
    return self._parent
end

--- cp.ui.SplitGroup:app() -> App
--- Method
--- Returns the app instance.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function SplitGroup:app()
    return self:parent():app()
end

return SplitGroup