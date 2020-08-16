--- === cp.highland2.Sidebar ===
---
--- Represents the sidebar for a document opened in Highland.

local Group                                     = require "cp.ui.Group"
local go                                        = require "cp.rx.go"
local If                                        = go.If

local Sidebar = Group:subclass("cp.highland2.Sidebar")

function Sidebar.static.matches(e)
    return Group.matches(e) and e:attributeValue("AXIdentifier") == "Sidebar View Controller"
end

function Sidebar:initialized(document, uiFinder)
    Group.initialized(self, document, uiFinder)
end

--- cp.highland2.Sidebar.document <cp.highland2.Document>
--- Field
--- The [Document](cp.highland2.Document.md) this `Sidebar` belongs to.
function Sidebar.lazy.value:document()
    return self:parent()
end

--- cp.highland2.Sidebar.doShow <cp.rx.go.Statement>
--- Field
--- A [Statement](cp.rx.go.Statement.md) that will attempt to show the Sidebar, if possible.
function Sidebar.lazy.value:doShow()
    return If(self.isShowing):Is(false)
    :Then(self.document.doShow)
    :Then(self:app().menu:doSelectMenu({"View", "Toggle Sidebar"}))
    :Label("Sidebar.show")
end

--- cp.highland2.Sidebar.doHide <cp.rx.go.Statement>
--- Field
--- A [Statement](cp.rx.go.Statement.md) that will attempt to hide the Sidebar, if possible.
function Sidebar.lazy.value:doHide()
    return If(self.isShowing)
    :Then(self.document.doShow)
    :Then(self:app().menu:doSelectMenu({"View", "Toggle Sidebar"}))
    :Label("Sidebar.hide")
end

return Sidebar
