--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.main.KeywordEditor ===
---
--- Keyword Editor Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log                               = require("hs.logger").new("keywordEditor")

local axutils                           = require("cp.ui.axutils")
local prop                              = require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local KeywordEditor = {}

--- cp.apple.finalcutpro.main.KeywordEditor:new(parent) -> KeywordEditor object
--- Method
--- Creates a new KeywordEditor object
---
--- Parameters:
---  * `parent`     - The parent
---
--- Returns:
---  * A KeywordEditor object
function KeywordEditor:new(parent)
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
        return windowsUI and self:_findWindowUI(windowsUI)
    end,
    KeywordEditor.matches)
end

-- cp.apple.finalcutpro.main.KeywordEditor_findWindowUI(windows) -> hs._asm.axuielement object | nil
-- Method
-- Finds the Keyword Editor window.
--
-- Parameters:
--  * windows - a table of `hs._asm.axuielement` object to search
--
-- Returns:
--  * A `hs._asm.axuielement` object if succesful otherwise `nil`
function KeywordEditor:_findWindowUI(windows)
    for i,window in ipairs(windows) do
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
---  * `true` if successful otherwise `false`
function KeywordEditor:show()
    local checkBox = self:toolbarCheckBoxUI()
    if checkBox and checkBox:attributeValue("AXValue") == 0 then
        local result = checkBox:performAction("AXPress")
        if result then return true end
    end
    return false
end

--- cp.apple.finalcutpro.main.KeywordEditor:hide() -> boolean
--- Method
--- Hides the Keyword Editor.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if successful otherwise `false`
function KeywordEditor:hide()
    local checkBox = self:toolbarCheckBoxUI()
    if checkBox and checkBox:attributeValue("AXValue") == 1 then
        if checkBox:performAction("AXPress") then
            return true
        end
    end
    return false
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
        if ui and ui[1] and #ui[1]:attributeValue("AXChildren") > 0 then
            local children = ui[1]:attributeValue("AXChildren")
            for _, child in ipairs(children) do
                table.insert(result, child:attributeValue("AXValue"))
            end
            return result
        end
        log.ef("Could not get Keyword.")
        return false
    else
        --------------------------------------------------------------------------------
        -- Setter:
        --------------------------------------------------------------------------------
        if ui and ui[1] then
            if type(value) == "string" then
                if ui[1]:setAttributeValue("AXValue", value) then
                    if ui[1]:performAction("AXConfirm") then
                        return value
                    end
                end
            elseif type(value) == "table" and #value >= 1 then
                local result = ""
                for i, v in pairs(value) do
                    result = result .. v .. ", "
                end
                if ui[1]:setAttributeValue("AXValue", result) then
                    if ui[1]:performAction("AXConfirm") then
                        return value
                    end
                end
            end
        end
        log.ef("Could not set Keyword.")
        return false
    end
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
    return KeyboardShortcuts:new(self)
end

--- cp.apple.finalcutpro.main.KeywordEditor.KeyboardShortcuts:new(parent) -> KeyboardShortcuts object
--- Method
--- Creates a new KeyboardShortcuts object
---
--- Parameters:
---  * `parent` - The parent
---
--- Returns:
---  * A KeyboardShortcuts object
function KeyboardShortcuts:new(parent)
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
                if textfields[item]:setAttributeValue("AXValue", value) then
                    if textfields[item]:performAction("AXConfirm") then
                        return value
                    end
                end
            elseif type(value) == "table" then
                --------------------------------------------------------------------------------
                -- String Setter:
                --------------------------------------------------------------------------------
                local result = ""
                for i, v in pairs(value) do
                    result = result .. v .. ", "
                end
                if textfields[item]:setAttributeValue("AXValue", result) then
                    if textfields[item]:performAction("AXConfirm") then
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