--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.ui.Alert ===
---
--- Alert UI Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
--local log                           = require("hs.logger").new("alert")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils                       = require("cp.ui.axutils")
local Button                        = require("cp.ui.Button")
local prop                          = require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Alert = {}

-- TODO: Add documentation
function Alert.matches(element)
    if element then
        return element:attributeValue("AXRole") == "AXSheet"
    end
    return false
end

-- TODO: Add documentation
function Alert.new(parent)
    return prop.extend({_parent = parent}, Alert)
end

-- TODO: Add documentation
function Alert:parent()
    return self._parent
end

-- TODO: Add documentation
function Alert:app()
    return self:parent():app()
end

-- TODO: Add documentation
function Alert:UI()
    return axutils.cache(self, "_ui", function()
        return axutils.childMatching(self:parent():UI(), Alert.matches)
    end,
    Alert.matches)
end

-- TODO: Add documentation
Alert.isShowing = prop(
    function(self)
        return self:UI() ~= nil
    end
):bind(Alert)

-- TODO: Add documentation
function Alert:hide()
    self:pressCancel()
end

function Alert:cancel()
    if not self._cancel then
        self._cancel = Button.new(self, function()
            local ui = self:UI()
            return ui and ui:cancelButton()
        end)
    end
    return self._cancel
end

function Alert:default()
    if not self._default then
        self._default = Button.new(self, function()
            local ui = self:UI()
            return ui and ui:defaultButton()
        end)
    end
    return self._default
end

-- TODO: Add documentation
function Alert:pressCancel()
    self:cancel():press()
    return self
end

-- TODO: Add documentation
function Alert:pressDefault()
    self:default():press()
    return self
end

--- cp.ui.Alert:containsText(value[, plain]) -> boolean
--- Method
--- Checks if there are any child text elements containing the exact text or pattern, from beginning to end.
---
--- Parameters:
--- * textPattern   - The text pattern to check.
--- * plain         - If `true`, the text will be compared exactly, otherwise it will be considered to be a pattern. Defaults to `false`.
---
--- Returns:
--- * `true` if an element's `AXValue` matches the text pattern exactly.
function Alert:containsText(value, plain)
    local textUI = axutils.childMatching(self:UI(), function(element)
        local eValue = element:attributeValue("AXValue")
        if type(eValue) == "string" then
            if plain then
                return eValue == value
            else
                local s,e = eValue:find(value)
                return s == 1 and e == eValue:len()
            end
        end
        return false
    end)
    return textUI ~= nil
end

-- TODO: Add documentation
Alert.title = prop(
    function(self)
        local ui = self:UI()
        return ui and ui:attributeValue("AXTitle")
    end
):bind(Alert)

return Alert
