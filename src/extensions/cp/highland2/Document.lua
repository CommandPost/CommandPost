--- === cp.highland2.Document ===
---
--- Highland 2 Document.

local axutils                                   = require "cp.ui.axutils"
local Group                                     = require "cp.ui.Group"
local ScrollArea                                = require "cp.ui.ScrollArea"
local SplitGroup                                = require "cp.ui.SplitGroup"
local TextArea                                  = require "cp.ui.TextArea"
local Window                                    = require "cp.ui.Window"

local Sidebar                                   = require "cp.highland2.Sidebar"

local go                                        = require "cp.rx.go"
local Do                                        = go.Do

local childMatching                             = axutils.childMatching
local childFromRight                            = axutils.childFromRight

local Document = Window:subclass("cp.highland2.Document")

function Document.static.matches(e)
    return Window.matches(e) and e:attributeValue("AXDocument") ~= nil
end

--- cp.highland2.Document:documentPath() -> cp.prop <string; live>
--- Field
--- The current path for the document.
function Document.lazy.prop:documentPath()
    return axutils.prop(self.UI, "AXDocument")
end

function Document.lazy.value:_splitGroup()
    return SplitGroup(self, self.UI:mutate(function(ui)
        return childMatching(ui(), SplitGroup.matches)
    end))
end

function Document.lazy.value:_textGroup()
    return Group(self, self._splitGroup.UI:mutate(function(ui)
        return childFromRight(ui(), 1, Group.matches)
    end))
end

function Document.lazy.value:_textScrollArea()
    return ScrollArea(self, self._textGroup.UI:mutate(function(ui)
        return childMatching(ui(), ScrollArea.matches)
    end))
end

function Document.lazy.value:text()
    return TextArea(self, self._textScrollArea.UI:mutate(function(ui)
        return childMatching(ui(), TextArea.matches)
    end))
end

function Document.lazy.value:sidebar()
    return Sidebar(self, self._splitGroup.UI:mutate(function(ui)
        return childFromRight(ui(), 2, Group.matches)
    end))
end

function Document.lazy.value:doShow()
    return Do(self:doFocus()):Label("Document.show")
end

return Document