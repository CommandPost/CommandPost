--- === cp.apple.finalcutpro.main.KeywordEditor ===
---
--- Keyword Editor Module.

local require               = require

-- local log                   = require "hs.logger".new "keywordEditor"

local axutils               = require "cp.ui.axutils"
local Button                = require "cp.ui.Button"
local Dialog                = require "cp.ui.Dialog"
local DisclosureTriangle    = require "cp.ui.DisclosureTriangle"

local KeywordField          = require "cp.apple.finalcutpro.main.KeywordField"

local cache                 = axutils.cache
local childFromTop          = axutils.childFromTop
local childMatching         = axutils.childMatching
local childrenBelow         = axutils.childrenBelow
local childrenMatching      = axutils.childrenMatching

local insert                = table.insert

local KeywordEditor = Dialog:subclass("cp.apple.finalcutpro.main.KeywordEditor")

--- cp.apple.finalcutpro.main.KeywordEditor.NUMBER_OF_SHORTCUTS -> number
--- Constant
--- The number of Keyword Keyboard shortcuts available.
KeywordEditor.static.NUMBER_OF_SHORTCUTS = 9

--- cp.apple.finalcutpro.main.KeywordEditor.matches(element) -> boolean
--- Function
--- Checks to see if an `hs.axuielement` object matches a Keyword Editor window
---
--- Parameters:
---  * element - the `hs.axuielement` object you want to check
---
--- Returns:
---  * `true` if a match otherwise `false`
function KeywordEditor.static.matches(element)
    if Dialog.matches(element) then
        local childCount = element:attributeValueCount("AXChildren")
        return childCount == 6 or childCount == 26
    end
    return false
end

-- cp.apple.finalcutpro.main.KeywordEditor_findWindowUI(windows) -> hs.axuielement object | nil
-- Function
-- Finds the Keyword Editor window.
--
-- Parameters:
--  * windows - a table of `hs.axuielement` object to search
--
-- Returns:
--  * A `hs.axuielement` object if succesful otherwise `nil`
local function _findWindowUI(windows)
    for _,window in ipairs(windows) do
        if KeywordEditor.matches(window) then return window end
    end
    return nil
end

--- cp.apple.finalcutpro.main.KeywordEditor(parent) -> KeywordEditor object
--- Constructor
--- Creates a new KeywordEditor object
---
--- Parameters:
---  * `parent`     - The parent
---
--- Returns:
---  * A KeywordEditor object
function KeywordEditor:initialize(parent)
    self._child = {}

    self._parent = parent

    local UI = parent.windowsUI:mutate(function(original)
        return cache(self, "_ui", function()
            local windowsUI = original()
            return windowsUI and _findWindowUI(windowsUI)
        end,
        KeywordEditor.matches)
    end)

    Dialog.initialize(self, parent.app, UI)
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

-- Access to the `PrimaryToolbar`
function KeywordEditor.lazy.value:_toolbar()
    return self:parent().primaryWindow.toolbar
end

-- Access to the Keyword Editor CheckBox on the PrimaryToolbar
function KeywordEditor.lazy.value:_keywordEditor()
    return self._toolbar.keywordEditor
end

--- cp.apple.finalcutpro.main.KeywordEditor.isShowing <cp.prop: boolean; live?>
--- Field
--- Indicates whether or not the Keyword Editor is currently showing.
function KeywordEditor.lazy.prop:isShowing()
    return self._keywordEditor.checked
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
    return self, self:isShowing(true)
end

--- cp.apple.finalcutpro.main.KeywordEditor:doShow() -> cp.rx.go.Statement
--- Method
--- A `Statement` that shows the Keyword Editor.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement`
function KeywordEditor.lazy.method:doShow()
    return self._keywordEditor:doCheck()
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
    return self, not self:isShowing(false)
end

--- cp.apple.finalcutpro.main.KeywordEditor:doHide() -> cp.rx.go.Statement
--- Method
--- A `Statement` that hides the Keyword Editor.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement`
function KeywordEditor.lazy.method:doHide()
    return self._keywordEditor:doUncheck()
end

--- cp.apple.finalcutpro.main.KeywordEditor.keywords <cp.ui.TextField>
--- Field
--- A `TextField` that contains the current keywords. The value is a `table` of `string` values for each individual keyword.
function KeywordEditor.lazy.value:keywords()
    return KeywordField(self, self.UI:mutate(function(original)
        return childFromTop(original(), 1, KeywordField.matches)
    end))
end


--- cp.apple.finalcutpro.main.KeywordEditor.keyboardShortcuts <cp.ui.DisclosureWindow>
--- Field
--- The `DisclosureTriangle` that shows/hides the keyboard shortcuts configuration.
function KeywordEditor.lazy.value:keyboardShortcuts()
    return DisclosureTriangle(self, self.UI:mutate(function(original)
        return childMatching(original(), DisclosureTriangle.matches)
    end))
end

function KeywordEditor.lazy.prop:_shortcutsUI()
    return self.UI:mutate(function(original)
        return childrenBelow(original(), self.keyboardShortcuts:UI())
    end)
end

--- cp.apple.finalcutpro.main.KeywordEditor.shortcutFields <table of KeywordField>
--- Field
--- The list of keyboard shortcut `KeywordField`s. The field for `Cmd+1` is accessed via `shortcutFields[1]`, and so on.
function KeywordEditor.lazy.value:shortcutFields()
    local result = {}

    local shortcutsUI = self._shortcutsUI

    for i=1,9 do
        insert(result, KeywordField(self, shortcutsUI:mutate(function(original)
            local fields = childrenMatching(original(), KeywordField.matches)
            if fields and #fields >= KeywordEditor.NUMBER_OF_SHORTCUTS then
                return fields[i]
            end
        end)):forceFocus())
    end

    return result
end

--- cp.apple.finalcutpro.main.KeywordEditor.shortcutButtons <table of cp.ui.Button>
--- Field
--- The list of keyboard shortcut `Button`s. The button for `Cmd+1` is accessed via `shortcutButtons[1]`, and so on.
function KeywordEditor.lazy.value:shortcutButtons()
    local result = {}

    local shortcutsUI = self._shortcutsUI

    for i=1,9 do
        insert(result, Button(self, shortcutsUI:mutate(function(original)
            local buttons = childrenMatching(original(), Button.matches)
            if buttons and #buttons >= KeywordEditor.NUMBER_OF_SHORTCUTS then
                return buttons[i]
            end
        end)))
    end

    return result
end

--- cp.apple.finalcutpro.main.KeywordEditor.resetButton <cp.ui.Button>
--- Field
--- The `Button` that resets the current keywords to blank.
function KeywordEditor.lazy.value:resetButton()
    return Button(self, self.UI:mutate(function(original)
        return cache(self, "_resetButton", function()
            local buttonsUI = childrenMatching(childrenBelow(original(), self.keyboardShortcuts:UI()), Button.matches)
            if buttonsUI and #buttonsUI > KeywordEditor.NUMBER_OF_SHORTCUTS then
                return buttonsUI[10]
            end
        end, Button.matches)
    end))
end

function KeywordEditor:saveShortcuts()
    local fcp = self:parent()
    local result = {}
    local keywordGroups = fcp.preferences.FFKeywordGroups
    if keywordGroups and #keywordGroups == KeywordEditor.NUMBER_OF_SHORTCUTS then
        for _,value in ipairs(keywordGroups) do
            insert(result, value)
        end
    end
    return result
end

function KeywordEditor:loadShortcuts(data)
    local wasShowing = self:isShowing()

    self:show()

    if self:isShowing() then
        local wasShortcutsOpened = self.keyboardShortcuts:opened()

        self.keyboardShortcuts:opened(true)

        if self.keyboardShortcuts:opened() then
            for i=1,KeywordEditor.NUMBER_OF_SHORTCUTS do
                self.shortcutFields[i].value:set(data[i])
            end
        end

        if not wasShortcutsOpened then
            self.keyboardShortcuts:opened(false)
        end
    end

    if not wasShowing then
        self:hide()
    end
end

return KeywordEditor
