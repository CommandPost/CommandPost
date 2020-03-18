--- === cp.apple.finalcutpro.main.KeywordEditor ===
---
--- Keyword Editor Module.

local require       = require

local log           = require "hs.logger".new "keywordEditor"

local axutils       = require "cp.ui.axutils"
local just          = require "cp.just"
local prop          = require "cp.prop"

local KeywordEditor = {}

--- cp.apple.finalcutpro.main.KeywordEditor.new(parent) -> KeywordEditor object
--- Constructor
--- Creates a new KeywordEditor object
---
--- Parameters:
---  * `parent`     - The parent
---
--- Returns:
---  * A KeywordEditor object
function KeywordEditor.new(parent)
    local o = {
        _parent = parent,
        _child = {}
    }
    return prop.extend(o, KeywordEditor)
end

--- cp.apple.finalcutpro.main.KeywordEditor:parent() -> table
--- Method
--- Returns the KeywordEditor's parent table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function KeywordEditor:parent()
    return self._parent
end

--- cp.apple.finalcutpro.main.KeywordEditor:app() -> table
--- Method
--- Returns the `cp.apple.finalcutpro` app table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application object as a table
function KeywordEditor:app()
    return self:parent():app()
end

--- cp.apple.finalcutpro.main.KeywordEditor:toolbarCheckBoxUI() -> hs._asm.axuielement object
--- Method
--- Returns the `hs._asm.axuielement` object for the Keyword Editor button in the toolbar
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `hs._asm.axuielement` object
function KeywordEditor:toolbarCheckBoxUI()
    return axutils.cache(self, "_toolbarCheckBoxUI", function()
        local primaryWindowUI = self:parent():primaryWindow():UI()
        if not primaryWindowUI then return nil end

        local toolbar = axutils.childWithRole(primaryWindowUI, "AXToolbar")
        if not toolbar then return nil end

        local group = axutils.childWithRole(toolbar, "AXGroup")
        if not group then return nil end

        local checkBox = axutils.childWithRole(group, "AXCheckBox")
        return checkBox
    end)
end

--- cp.apple.finalcutpro.main.KeywordEditor.matches(element) -> boolean
--- Function
--- Checks to see if an `hs._asm.axuielement` object matches a Keyword Editor window
---
--- Parameters:
---  * element - the `hs._asm.axuielement` object you want to check
---
--- Returns:
---  * `true` if a match otherwise `false`
function KeywordEditor.matches(element)
    if element then
        return element:attributeValue("AXSubrole") == "AXDialog"
           and element:attributeValueCount("AXChildren") == 6 or element:attributeValueCount("AXChildren") == 26
    end
    return false
end

--- cp.apple.finalcutpro.main.KeywordEditor:UI() -> hs._asm.axuielement object
--- Method
--- Returns the `hs._asm.axuielement` object for the Keyword Editor window
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `hs._asm.axuielement` object
function KeywordEditor:UI()
    return axutils.cache(self, "_ui", function()
        local windowsUI = self:parent():windowsUI()
        return windowsUI and self._findWindowUI(windowsUI)
    end,
    KeywordEditor.matches)
end

-- cp.apple.finalcutpro.main.KeywordEditor_findWindowUI(windows) -> hs._asm.axuielement object | nil
-- Function
-- Finds the Keyword Editor window.
--
-- Parameters:
--  * windows - a table of `hs._asm.axuielement` object to search
--
-- Returns:
--  * A `hs._asm.axuielement` object if succesful otherwise `nil`
function KeywordEditor._findWindowUI(windows)
    for _,window in ipairs(windows) do
        if KeywordEditor.matches(window) then return window end
    end
    return nil
end

--- cp.apple.finalcutpro.main.KeywordEditor:isShowing() -> boolean
--- Method
--- Gets whether or not the Keyword Editor is currently showing.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if showing otherwise `false`
function KeywordEditor:isShowing()
    local checkBox = self:toolbarCheckBoxUI()
    return checkBox and checkBox:attributeValue("AXValue") == 1
end

--- cp.apple.finalcutpro.main.KeywordEditor:show() -> boolean
--- Method
--- Shows the Keyword Editor.
---
--- Parameters:
---  * None
---
--- Returns:
---  * KeywordEditor object
---  * `true` if successful otherwise `false`
function KeywordEditor:show()
    local checkBox = self:toolbarCheckBoxUI()
    if checkBox and checkBox:attributeValue("AXValue") == 0 then
        local result = checkBox:performAction("AXPress")
        if result then
            return self, true
        end
    end
    return self, false
end

--- cp.apple.finalcutpro.main.KeywordEditor:hide() -> boolean
--- Method
--- Hides the Keyword Editor.
---
--- Parameters:
---  * None
---
--- Returns:
---  * KeywordEditor object
---  * `true` if successful otherwise `false`
function KeywordEditor:hide()
    local checkBox = self:toolbarCheckBoxUI()
    if checkBox and checkBox:attributeValue("AXValue") == 1 then
        if checkBox:performAction("AXPress") then
            return self, true
        end
    end
    return self, false
end

--- cp.apple.finalcutpro.main.KeywordEditor:keyword(value) -> string | table | nil
--- Method
--- Sets or gets the main Keyword Textbox value.
---
--- Parameters:
---  * value - The value you want to set the keyword textbox to. This can either be a string, with the tags separated by a comma, or a table of tags.
---
--- Returns:
---  * `value` if successful otherwise `false`
function KeywordEditor:keyword(value)
    local ui = self:UI()
    if type(value) == "nil" then
        --------------------------------------------------------------------------------
        -- Getter:
        --------------------------------------------------------------------------------
        local result = {}
        if ui then
            local textbox = axutils.childWithRole(ui, "AXTextField")
            if textbox then
                local children = textbox:attributeValue("AXChildren")
                for _, child in ipairs(children) do
                    table.insert(result, child:attributeValue("AXValue"))
                end
                return result
            end
        end
        log.ef("Could not get Keyword.")
        return false
    else
        --------------------------------------------------------------------------------
        -- Setter:
        --------------------------------------------------------------------------------
        if ui then
            local textbox = axutils.childWithRole(ui, "AXTextField")
            if textbox then
                if type(value) == "string" then
                    if textbox:setAttributeValue("AXValue", value) then
                        if textbox:performAction("AXConfirm") then
                            return value
                        end
                    end
                elseif type(value) == "table" and #value >= 1 then
                    local result = table.concat(value, ", ")
                    if result and textbox:setAttributeValue("AXValue", result) then
                        if textbox:performAction("AXConfirm") then
                            return value
                        end
                    end
                end
            end
        end
        log.ef("Could not set Keyword.")
        return false
    end
end

--- cp.apple.finalcutpro.main.KeywordEditor:removeKeyword(keyword) -> boolean
--- Method
--- Removes a keyword from the main Keyword Textbox.
---
--- Parameters:
---  * keyword - The keyword you want to remove as a string.
---
--- Returns:
---  * `true` if successful otherwise `false`
function KeywordEditor:removeKeyword(keyword)
    if type(keyword) ~= "string" then
        log.ef("Keyword is invalid.")
        return false
    end
    local ui = self:UI()
    local result = {}
    if ui then
        local textbox = axutils.childWithRole(ui, "AXTextField")
        if textbox then
            local children = textbox:attributeValue("AXChildren")
            local found = false
            for _, child in ipairs(children) do
                local value = child:attributeValue("AXValue")
                if keyword ~= value then
                    table.insert(result, value)
                else
                    found = true
                end
            end
            if not found then
                log.ef("Could not find keyword to remove: %s", keyword)
                return false
            end
            local resultString = table.concat(result, ", ")
            if resultString and textbox:setAttributeValue("AXValue", resultString) then
                if textbox:performAction("AXConfirm") then
                    return true
                end
            end
        end
    end
    log.ef("Could not find UI.")
    return false
end

--------------------------------------------------------------------------------
--
-- KEYBOARD SHORTCUTS:
--
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.main.KeywordEditor.KeyboardShortcuts ===
---
--- Keyboard Shortcuts

local KeyboardShortcuts = {}

function KeywordEditor:keyboardShortcuts()
    return KeyboardShortcuts.new(self)
end

--- cp.apple.finalcutpro.main.KeywordEditor.KeyboardShortcuts.new(parent) -> KeyboardShortcuts
--- Constructor
--- Creates a new `KeyboardShortcuts` object
---
--- Parameters:
---  * parent - The parent object.
---
--- Returns:
---  * A `KeyboardShortcuts` object
function KeyboardShortcuts.new(parent)
    local o = {
        _parent = parent,
        _child = {}
    }
    return prop.extend(o, KeyboardShortcuts)
end

--- cp.apple.finalcutpro.main.KeywordEditor.KeyboardShortcuts:parent() -> table
--- Method
--- Returns the KeywordShortcuts's parent table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function KeyboardShortcuts:parent()
    return self._parent
end

--- cp.apple.finalcutpro.main.KeywordEditor.KeyboardShortcuts:isShowing() -> boolean
--- Method
--- Gets whether or not the Keyword Editor's Keyboard Shortcuts section is currently showing.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if showing otherwise `false`
function KeyboardShortcuts:isShowing()
    local ui = self:parent():UI()
    local disclosureTriangle = axutils.childWithRole(ui, "AXDisclosureTriangle")
    return disclosureTriangle and disclosureTriangle:attributeValue("AXValue") == 1
end

--- cp.apple.finalcutpro.main.KeywordEditor.KeyboardShortcuts:show() -> boolean
--- Method
--- Shows the Keyword Editor's Keyboard Shortcuts section.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if successful otherwise `false`
function KeyboardShortcuts:show()
    local ui = self:parent():UI()
    local disclosureTriangle = axutils.childWithRole(ui, "AXDisclosureTriangle")
    if disclosureTriangle:attributeValue("AXValue") == 0 then
        if disclosureTriangle:performAction("AXPress") then
            return true
        end
    end
    return false
end

--- cp.apple.finalcutpro.main.KeywordEditor.KeyboardShortcuts:hide() -> boolean
--- Method
--- Hides the Keyword Editor's Keyboard Shortcuts section.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if successful otherwise `false`
function KeyboardShortcuts:hide()
    local ui = self:parent():UI()
    local disclosureTriangle = axutils.childWithRole(ui, "AXDisclosureTriangle")
    if disclosureTriangle:attributeValue("AXValue") == 1 then
        if disclosureTriangle:performAction("AXPress") then
            return true
        end
    end
    return false
end

--- cp.apple.finalcutpro.main.KeywordEditor.KeyboardShortcuts:keyword(item, value) -> string | table | nil
--- Method
--- Sets or gets a specific Keyboard Shortcut Keyword Textbox value.
---
--- Parameters:
---  * item - The textbox you want to update. This can be a number between 1 and 9.
---  * value - The value you want to set the keyword textbox to. This can either be a string, with the tags separated by a comma, or a table of tags.
---
--- Returns:
---  * `value` if successful otherwise `false`
function KeyboardShortcuts:keyword(item, value)
    if not item or type(item) ~= "number" or item < 1 or item > 9 then
        log.ef("The keyboard shortcuts item must be between 1 and 9.")
        return nil
    end
    item = item + 1
    if not self:isShowing() then
        self:show()
    end
    local ui = self:parent():UI()
    if ui then
        local textfields = axutils.childrenWith(ui, "AXRole", "AXTextField")
        if textfields and #textfields == 10 then
            if type(value) == "nil" then
                --------------------------------------------------------------------------------
                -- Getter:
                --------------------------------------------------------------------------------
                local result = {}
                if #textfields[item]:attributeValue("AXChildren") > 0 then
                    local children = textfields[item]:attributeValue("AXChildren")
                    for _, child in ipairs(children) do
                        table.insert(result, child:attributeValue("AXValue"))
                    end
                    return result
                end
                return {}
            elseif type(value) == "string" then
                --------------------------------------------------------------------------------
                -- String Setter:
                --------------------------------------------------------------------------------
                textfields[1]:setAttributeValue("AXFocused", true)
                just.doUntil(function() return textfields[1]:attributeValue("AXFocused") == true end)

                textfields[item]:setAttributeValue("AXFocused", true)
                just.doUntil(function() return textfields[item]:attributeValue("AXFocused") == true end)

                if textfields[item]:setAttributeValue("AXValue", value) then
                    if textfields[item]:performAction("AXConfirm") then
                        textfields[1]:setAttributeValue("AXFocused", true)
                        just.doUntil(function() return textfields[1]:attributeValue("AXFocused") == true end)

                        return value
                    end
                end
            elseif type(value) == "table" then
                --------------------------------------------------------------------------------
                -- Table Setter:
                --------------------------------------------------------------------------------
                local result = ""
                for _, v in pairs(value) do
                    result = result .. v .. ", "
                end

                textfields[1]:setAttributeValue("AXFocused", true)
                just.doUntil(function() return textfields[1]:attributeValue("AXFocused") == true end)

                textfields[item]:setAttributeValue("AXFocused", true)
                just.doUntil(function() return textfields[item]:attributeValue("AXFocused") == true end)

                if textfields[item]:setAttributeValue("AXValue", result) then
                    if textfields[item]:performAction("AXConfirm") then
                        textfields[1]:setAttributeValue("AXFocused", true)
                        just.doUntil(function() return textfields[1]:attributeValue("AXFocused") == true end)
                        return value
                    end
                end
            end
            log.ef("Failed to set Keyword.")
            return false
        end
    end
    return false
end

--- cp.apple.finalcutpro.main.KeywordEditor.KeyboardShortcuts:apply(item) -> boolean
--- Method
--- Applies a Keyword Shortcut.
---
--- Parameters:
---  * item - The textbox you want to update. This can be a number between 1 and 9.
---
--- Returns:
---  * `true` if successful otherwise `false`
function KeyboardShortcuts:apply(item)
    if not item or type(item) ~= "number" or item < 1 or item > 9 then
        log.ef("The keyboard shortcuts item must be between 1 and 9.")
        return false
    end
    if not self:isShowing() then
        self:show()
    end
    local ui = self:parent():UI()
    if ui then
        local buttons = axutils.childrenWith(ui, "AXRole", "AXButton")
        if buttons and #buttons == 11 then
            if buttons[item]:performAction("AXPress") then
                return true
            end
        end
    end
    log.ef("Failed to Apply Keyword.")
    return false
end

--- cp.apple.finalcutpro.main.KeywordEditor.KeyboardShortcuts:removeAllKeywords() -> boolean
--- Method
--- Triggers the "Remove all Keywords" button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if successful otherwise `false`
function KeyboardShortcuts:removeAllKeywords()
    if not self:isShowing() then
        self:show()
    end
    local ui = self:parent():UI()
    if ui then
        local buttons = axutils.childrenWith(ui, "AXRole", "AXButton")
        if buttons and #buttons == 11 then
            if buttons[10]:performAction("AXPress") then
                return true
            end
        end
    end
    log.ef("Could not remove all keywords.")
    return false
end

return KeywordEditor
