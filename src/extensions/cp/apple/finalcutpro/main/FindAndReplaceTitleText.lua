--- === cp.apple.finalcutpro.main.FindAndReplaceTitleText ===
---
--- Represents a "Find and Replace Title Text" dialogue box.

local log	            = require "hs.logger" .new "FindAndReplace"

local tools	            = require "cp.tools"
local go	            = require "cp.rx.go"
local axutils	        = require "cp.ui.axutils"
local Button	        = require "cp.ui.Button"
local CheckBox	        = require "cp.ui.CheckBox"
local Dialog	        = require "cp.ui.Dialog"
local PopUpButton	    = require "cp.ui.PopUpButton"
local TextField	        = require "cp.ui.TextField"

local strings           = require "cp.apple.finalcutpro.strings"

local Do                = go.Do
local Given             = go.Given
local If                = go.If

local ninjaMouseClick	= tools.ninjaMouseClick

local cache             = axutils.cache
local childFromLeft     = axutils.childFromLeft
local childFromRight    = axutils.childFromRight
local childFromTop      = axutils.childFromTop
local childMatching	    = axutils.childMatching
local childrenBelow	    = axutils.childrenBelow

local FindAndReplace = Dialog:subclass("cp.apple.finalcutpro.main.FindAndReplaceTitleText")

function FindAndReplace.static.matches(element)
    return Dialog.matches(element) and element:attributeValue("AXTitle") == strings:find("FFFindAndReplaceWindowTitle")
end

--- cp.apple.finalcutpro.main.FindAndReplaceTitleText(cpApp)
--- Constructor
--- Creates a new "Find and Replace Title Text" [Dialog](cp.ui.Dialog.md)
---
--- Parameters:
---  * cpApp - The cpApp
---
--- Returns:
---  * None
function FindAndReplace:initialize(cpApp)
    Dialog.initialize(self, cpApp, cpApp.UI:mutate(function(original)
        return cache(self, "_window", function()
            return childMatching(original(), FindAndReplace.matches)
        end, FindAndReplace.matches)
    end))
end

--- cp.apple.finalcutpro.main.FindAndReplaceTitleText.findText <cp.ui.TextField>
--- Field
--- The "Find" search field, as a [TextField](cp.ui.TextField.md)
function FindAndReplace.lazy.value:findText()
    return TextField(self, self.UI:mutate(function(original)
        return cache(self, "_findText", function()
            return childFromTop(original(), 1, TextField.matches)
        end, TextField.matches)
    end))
end

--- cp.apple.finalcutpro.main.FindAndReplaceTitleText.replaceText <cp.ui.TextField>
--- Field
--- The "Replace" search field, as a [TextField](cp.ui.TextField.md)
function FindAndReplace.lazy.value:replaceText()
    return TextField(self, self.UI:mutate(function(original)
        return cache(self, "_replaceText", function()
            return childFromTop(original(), 2, TextField.matches)
        end, TextField.matches)
    end))
end

--- cp.apple.finalcutpro.main.FindAndReplaceTitleText.searchIn <cp.ui.PopUpButton>
--- Field
--- The "Search In" [PopUpButton](cp.ui.PopUpButton.md).
function FindAndReplace.lazy.value:searchIn()
    return PopUpButton(self, self.UI:mutate(function(original)
        return cache(self, "_searchIn", function()
            return childMatching(original(), PopUpButton.matches)
        end, PopUpButton.matches)
    end))
end

--- cp.apple.finalcutpro.main.FindAndReplaceTitleText.matchCase <cp.ui.CheckBox>
--- Field
--- The "Match case" [CheckBox](cp.ui.CheckBox.md).
function FindAndReplace.lazy.value:matchCase()
    return CheckBox(self, self.UI:mutate(function(original)
        return cache(self, "_matchCase", function()
            return childFromTop(original(), 1, CheckBox.matches)
        end, CheckBox.matches)
    end))
end

--- cp.apple.finalcutpro.main.FindAndReplaceTitleText.wholeWords <cp.ui.CheckBox>
--- Field
--- The "Whole words" [CheckBox](cp.ui.CheckBox.md).
function FindAndReplace.lazy.value:wholeWords()
    return CheckBox(self, self.UI:mutate(function(original)
        return cache(self, "_wholeWords", function()
            return childFromTop(original(), 2, CheckBox.matches)
        end, CheckBox.matches)
    end))
end

--- cp.apple.finalcutpro.main.FindAndReplaceTitleText.loopSearch <cp.ui.CheckBox>
--- Field
--- The "Loop search" [CheckBox](cp.ui.CheckBox.md).
function FindAndReplace.lazy.value:loopSearch()
    return CheckBox(self, self.UI:mutate(function(original)
        return cache(self, "_loopSearch", function()
            return childFromTop(original(), 3, CheckBox.matches)
        end, CheckBox.matches)
    end))
end

--- cp.apple.finalcutpro.main.FindAndReplaceTitleText.replaceAll <cp.ui.Button>
--- Field
--- The "Replace All" [Button](cp.ui.Button.md).
function FindAndReplace.lazy.value:replaceAll()
    return Button(self, self.UI:mutate(function(original)
        return cache(self, "_replaceAll", function()
            return childFromLeft(childrenBelow(original(), self.findText:UI()), 1, Button.matches)
        end, Button.matches)
    end))
end

--- cp.apple.finalcutpro.main.FindAndReplaceTitleText.replace <cp.ui.Button>
--- Field
--- The "Replace" [Button](cp.ui.Button.md).
function FindAndReplace.lazy.value:replace()
    return Button(self, self.UI:mutate(function(original)
        return cache(self, "_replace", function()
            return childFromLeft(childrenBelow(original(), self.findText:UI()), 2, Button.matches)
        end, Button.matches)
    end))
end

--- cp.apple.finalcutpro.main.FindAndReplaceTitleText.replaceAndFind <cp.ui.Button>
--- Field
--- The "Replace & Find" [Button](cp.ui.Button.md).
function FindAndReplace.lazy.value:replaceAndFind()
    return Button(self, self.UI:mutate(function(original)
        return cache(self, "_replaceAndFind", function()
            return childFromLeft(childrenBelow(original(), self.findText:UI()), 3, Button.matches)
        end, Button.matches)
    end))
end

--- cp.apple.finalcutpro.main.FindAndReplaceTitleText.previous <cp.ui.Button>
--- Field
--- The "Previous" [Button](cp.ui.Button.md).
function FindAndReplace.lazy.value:previous()
    return Button(self, self.UI:mutate(function(original)
        return cache(self, "_previous", function()
            return childFromRight(childrenBelow(original(), self.findText:UI()), 2, Button.matches)
        end, Button.matches)
    end))
end

--- cp.apple.finalcutpro.main.FindAndReplaceTitleText.next <cp.ui.Button>
--- Field
--- The "Next" [Button](cp.ui.Button.md).
function FindAndReplace.lazy.value:next()
    return Button(self, self.UI:mutate(function(original)
        return cache(self, "_next", function()
            return childFromRight(childrenBelow(original(), self.findText:UI()), 1, Button.matches)
        end, Button.matches)
    end))
end

--- cp.apple.finalcutpro.main.FindAndReplaceTitleText:doShow() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will attempt to show the "Find And Replace Title Text" dialog.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function FindAndReplace.lazy.method:doShow()
    return If(self.isShowing):Is(false)
    :Then(self:app():doLaunch())
    :Then(self:app().menu:doSelectMenu({"Edit", "Find and Replace Title Text..."}))
    :Otherwise(false)
    :ThenYield()
end

--- cp.apple.finalcutpro.main.FindAndReplaceTitleText:doHide() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will attempt to hide the "Find And Replace Title Text" dialog.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function FindAndReplace.lazy.method:doHide()
    return If(self.isShowing)
    :Then(self:doClose())
    :Otherwise(true)
    :ThenYield()
end

local function centre(frame)
    return {x = frame.x + frame.w/2, y = frame.y + frame.h/2}
end

local function doNinjaPress(button)
    return If(button.frame)
    :Then(function(frame)
        return Do(function()
            ninjaMouseClick(centre(frame))
            return true
        end)
    end)
    :Otherwise(false)
end

function FindAndReplace.lazy.method:doReplaceAll()
    -- TODO: Figure out why 'doPress' doesn't work for these buttons.
    return doNinjaPress(self.replaceAll)
end

function FindAndReplace.lazy.method:doReplace()
    -- TODO: Figure out why 'doPress' doesn't work for these buttons.
    return doNinjaPress(self.replaceAll)
end

function FindAndReplace.lazy.method:doReplaceAndFind()
    -- TODO: Figure out why 'doPress' doesn't work for these buttons.
    return doNinjaPress(self.replaceAndFind)
end

function FindAndReplace.lazy.method:doPrevious()
    -- TODO: Figure out why 'doPress' doesn't work for these buttons.
    return doNinjaPress(self.previous)
end

function FindAndReplace.lazy.method:doNext()
    -- TODO: Figure out why 'doPress' doesn't work for these buttons.
    return doNinjaPress(self.next)
end

--- cp.apple.finalcutpro.main.FindAndReplaceTitleText:doFindAndReplaceAll(find, replace) -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will attempt to find all titles containing `find` and replace them with `replace`.
---
--- Parameters:
---  * find - what to find
---  * replace - what to replace
---
--- Returns:
---  * None
function FindAndReplace:doFindAndReplaceAll(find, replace)
    return Do(self:app():doLaunch())
    :Then(
        Given(
            self.isShowing,
            self:doShow())
        :Then(function(wasShowing)
            self.findText.value:set(find)
            self.replaceText.value:set(replace)

            log.df("About to replaceAll():doPress()...")
            local result = self:doReplaceAll()
            if not wasShowing then
                log.df("Wasn't showing, so will 'doHide()' after replacing.'")
                result = Do(
                    Do(result):ThenDelay(1000)
                ):Then(self:doHide())
            end
            log.df("Returning the result")
            return result
        end)
    )
    :Label("cp.apple.finalcutpro.main.FindAndReplaceTitleText:doFindAndReplaceAll(find, replace)")
end

return FindAndReplace