--- === cp.apple.finalcutpro.main.KeywordField ===
---
--- Keyword Text Field Module.

local require                       = require

-- local log                           = require "hs.logger" .new "KeywordField"

local axutils                       = require "cp.ui.axutils"
local TextField                     = require "cp.ui.TextField"

local children                      = axutils.children
local insert                        = table.insert

local KeywordField = TextField:subclass("cp.apple.finalcutpro.main.KeywordField")

--- cp.apple.finalcutpro.main.KeywordField(parent, uiFinder) -> KeywordField
--- Constructor
--- Constructs a new KeywordField.
---
--- Parameters:
---  * parent - the parent object.
---  * uiFinder - The `function` or `cp.prop` that provides the axuielement.
---
--- Returns:
---  * The new `KeywordField`.
function KeywordField:initialize(parent, uiFinder)
    TextField.initialize(self, parent, uiFinder,
        function()
            local result = {}
            local words = children(self:UI())
            if words then
                for _,word in ipairs(words) do
                    insert(result, word:attributeValue("AXValue"))
                end
            end

            return result
        end,
        function(newValue)
            local valueString = ""
            if type(newValue) == "string" then
                valueString = newValue
            elseif type(newValue) == "table" and #newValue >= 1 then
                valueString = table.concat(newValue, ", ")
            end

            return valueString
        end
    )
end

--- cp.apple.finalcutpro.main.KeywordField:addKeyword(keyword) -> boolean
--- Method
--- Attempts to add the specified keyword.
---
--- Parameters:
---  * keyword - The keyword string to add.
---
--- Returns:
---  * `true` if the keyword was not present and added, otherwise false.
function KeywordField:addKeyword(keyword)
    local keywords = self:value() or {}

    for _,word in ipairs(keywords) do
        if word == keyword then
            return false
        end
    end

    insert(keywords, keyword)

    self:value(keywords)
    return true
end

--- cp.apple.finalcutpro.main.KeywordField:removeKeyword(keyword) -> boolean
--- Method
--- Attempts to remove the specified keyword.
---
--- Parameters:
---  * keyword - The keyword string to remove.
---
--- Returns:
---  * `true` if the keyword was present and removed, otherwise false.
function KeywordField:removeKeyword(keyword)
    local keywords = self:value()
    local result = {}

    for _,value in ipairs(keywords) do
        if value ~= keyword then
            insert(result, value)
        end
    end

    self:value(result)
    return #result ~= #keywords
end

return KeywordField
