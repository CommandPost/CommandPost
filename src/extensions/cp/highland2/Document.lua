--- === cp.highland2.Document ===
---
--- Highland 2 Document [Window](cp.ui.Window.md) extension.

local ax                                        = require "cp.fn.ax"

local Button                                    = require "cp.ui.Button"
local Group                                     = require "cp.ui.Group"
local ScrollArea                                = require "cp.ui.ScrollArea"
local SplitGroup                                = require "cp.ui.SplitGroup"
local Splitter                                  = require "cp.ui.Splitter"
local TextArea                                  = require "cp.ui.TextArea"
local Window                                    = require "cp.ui.Window"

local Sidebar                                   = require "cp.highland2.Sidebar"

local go                                        = require "cp.rx.go"
local Do                                        = go.Do

local Document = Window:subclass("cp.highland2.Document")

--- cp.highland2.Document.matches(element) -> boolean
--- Function
--- Checks if the element is a Document.
---
--- Parameters:
---  * element - The element to check.
---
--- Returns:
---  * `true` if the element matches, `false` otherwise.
function Document.static.matches(e)
    return Window.matches(e) and e:attributeValue("AXSubrole") == "AXStandardWindow"
        and TextArea.matches(Window.findSectionUI(e, "AXContent"))
end

--- cp.highland2.Document:documentPath() -> cp.prop <string; live>
--- Field
--- The current path for the document.
function Document.lazy.prop:documentPath()
    return ax.prop(self.UI, "AXDocument")
end

function Document.lazy.value:_splitGroup()
    return SplitGroup(
        self, self.UI:mutate(ax.childMatching(SplitGroup.matches)),
        {
            Button, -- Template Picker
            Button, -- Theme Picker
            Button, -- Revision Mode
            Button, -- Sprint
            Sidebar,
            Splitter,
            Group,
        }
    )
end

--- cp.highland2.Document.templatePicker <cp.ui.Button>
--- Field
--- The Template Picker button.
function Document.lazy.value:templatePicker()
    return self._splitGroup.children[1]
end

--- cp.highland2.Document.themePicker <cp.ui.Button>
--- Field
--- The Theme Picker button.
function Document.lazy.value:themePicker()
    return self._splitGroup.children[2]
end

--- cp.highland2.Document.revisionMode <cp.ui.Button>
--- Field
--- The Revision Mode button.
function Document.lazy.value:revisionMode()
    return self._splitGroup.children[3]
end

--- cp.highland2.Document.sprint <cp.ui.Button>
--- Field
--- The Sprint button.
function Document.lazy.value:sprint()
    return self._splitGroup.children[4]
end

--- cp.highland2.Document.sidebar <cp.highland2.Sidebar>
--- Field
--- The [Sidebar](cp.highland2.Sidebar.md).
function Document.lazy.value:sidebar()
    return self._splitGroup.children[5]
end

--- cp.highland2.Document.splitter <cp.ui.Splitter>
--- Field
--- The Splitter.
function Document.lazy.value:splitter()
    return self._splitGroup.children[6]
end

-- cp.highland2.Document._textGroup <cp.ui.Group>
-- Field
-- The Text [Group](cp.ui.Group.md).
function Document.lazy.value:_textGroup()
    return self._splitGroup.children[7]
end

-- cp.highland2.Document._textScrollArea <cp.ui.ScrollArea>
-- Field
-- The Text [ScrollArea](cp.ui.ScrollArea.md).
function Document.lazy.value:_textScrollArea()
    return ScrollArea(self, self._textGroup.UI:mutate(ax.childMatching(ScrollArea.matches)))
end

--- cp.highland2.Document.text <cp.ui.TextArea>
--- Field
--- The [TextArea](cp.ui.TextArea.md) containing the document text.
function Document.lazy.value:text()
    return TextArea(self, self._textScrollArea.UI:mutate(ax.childMatching(TextArea.matches)))
end

--- cp.highland2.Document.doShow <cp.rx.go.Statement>
--- Field
--- A [Statement](cp.rx.go.Statement.md) that will show the `Document` when run.
function Document.lazy.value:doShow()
    return Do(self:doFocus())
end

return Document