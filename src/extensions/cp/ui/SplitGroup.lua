--- === cp.ui.SplitGroup ===
---
--- Split Group UI. A SplitGroup is a container that can be split into multiple sections.
--- Each section is an [Element](cp.ui.Element.md), and they are divided by a [Splitter](cp.ui.Splitter.md),
--- resulting in something like `{ Element, Splitter, Element }`.
local require               = require

-- local log                   = require "hs.logger".new "SplitGroup"

local fn                    = require "cp.fn"
local ax                    = require "cp.fn.ax"
local Element               = require "cp.ui.Element"
local Splitter              = require "cp.ui.Splitter"

local chain                 = fn.chain
local get, ifilter, sort    = fn.table.get, fn.table.ifilter, fn.table.sort

local SplitGroup = Element:subclass("cp.ui.SplitGroup")

--- cp.ui.SplitGroup.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
SplitGroup.static.matches = ax.matchesIf(Element.matches, ax.hasRole "AXSplitGroup")

--- cp.ui.SplitGroup(parent, uiFinder[, childInits]) -> cp.ui.SplitGroup
--- Constructor
--- Creates a new Split Group.
---
--- Parameters:
---  * parent		- The parent object.
---  * uiFinder		- The `function` or `cp.prop` which returns an `hs.axuielement` for the Split Group, or `nil`.
---  * childInits   - A `table` of section-creating functions, in order, including the `Splitter`s.
---
--- Returns:
---  * A new `SplitGroup` instance.
---
--- Notes:
---  * Example: `SplitGroup(parent, uiFinder) { cp.fn.ax.init(ScrollArea, cp.ui.List), cp.fn.ax.init(ScrollArea, cp.ui.TextArea) }
function SplitGroup:initialize(parent, uiFinder, childInits)
    self.childInits = childInits or {}
    Element.initialize(self, parent, uiFinder)
end

--- cp.ui.SplitGroup.childrenUI <cp.prop: table of axuielementObject, read-only>
--- Field
--- The list of `axuielementObject`s for the sections.
function SplitGroup.lazy.prop:childrenUI()
    return self.UI:mutate(ax.children)
end

--- cp.ui.SplitGroup.children <table: cp.ui.Element, read-only>
--- Field
--- All children of the Split Group, based on the `childInits` passed to the constructor.
function SplitGroup.lazy.value:children()
    return fn.table.imap(function(init, index)
        return init(self, self.childrenUI:mutate(chain // ax.children  >> get(index)))
    end, self.childInits)
end

--- cp.ui.SplitGroup.splittersUI <cp.prop: table of axuielementObject, read-only>
--- Field
--- The list of `axuielementObject`s for the splitters.
function SplitGroup.lazy.prop:splittersUI()
    return ax.prop(self.UI, "AXSplitters")
end

--- cp.ui.SplitGroup.splitters <table: cp.ui.Splitter, read-only>
--- Field
--- The `Splitters` of the `SplitGroup`. There will be one less splitter than there are sections.
SplitGroup.lazy.value.splitters = chain // get "children" >> ifilter(Splitter.matches)

--- cp.ui.SplitGroup.sections <table: table of cp.ui.Element, read-only>
--- Field
--- The `Sections` of the `SplitGroup`. Each section will be a `table` of `cp.ui.Element`s.
SplitGroup.lazy.value.sections = chain // get "children" >> fn.table.split(Splitter.matches)

return SplitGroup
