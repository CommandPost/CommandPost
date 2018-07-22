--- === cp.ui.Group ===
---
--- UI Group.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

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
local Group = {}

--- cp.ui.Group.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function Group.matches(element)
    return element ~= nil and element:attributeValue("AXRole") == "AXGroup"
end

--- cp.ui.Group.new(parent, finderFn) -> Alert
--- Constructor
--- Creates a new `Group` instance.
---
--- Parameters:
---  * parent - The parent object.
---  * finderFn - A function which will return the `hs._asm.axuielement` when available.
---
--- Returns:
---  * A new `Group` object.
function Group.new(parent, finderFn)
    local o = prop.extend({
        _parent = parent,
        _finder = finderFn,
    }, Group)

    local UI = prop(function(self)
        return axutils.cache(self, "_ui", function()
            return self._finder()
        end, Group.matches)
    end)

    prop.bind(o) {
        --- cp.ui.Group:UI() -> hs._asm.axuielement | nil
        --- Method
        --- Returns the `axuielement` representing the Group, or `nil` if not available.
        ---
        --- Parameters:
        ---  * None
        ---
        --- Return:
        ---  * The `axuielement` or `nil`.
        UI = UI,

        --- cp.ui.Group.isShowing <cp.prop: boolean; read-only>
        --- Field
        --- If `true`, it is visible on screen.
        isShowing = UI:ISNOT(nil),
    }

    return o
end

--- cp.ui.Group:parent() -> parent
--- Method
--- Returns the parent object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * parent
function Group:parent()
    return self._parent
end

--- cp.ui.Group:app() -> App
--- Method
--- Returns the app instance.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function Group:app()
    return self:parent():app()
end

return Group
