--- === cp.ui.SplitGroup ===
---
--- Split Group UI. A SplitGroup is a container that can be split into multiple sections.
--- Each section is one or more [Elements](cp.ui.Element.md), and they are divided by a [Splitter](cp.ui.Splitter.md).
---
--- It's possible to have multiple elements in a single section, so if you wish to specify specific [Element](cp.ui.Element.md) subclasses
--- for each section, you can do so like so:
---
--- ```lua
--- local MySplitGroup = SplitGroup:subclass("MySplitGroup")
---
--- function MySplitGroup:initialize(parent, uiFinder)
---     SplitGroup.initialize(self, parent, uiFinder, {StaticText, Outline}, TextField)
--- end
--- ```
---
--- The above will create a `MySplitGroup` with two sections, the first with a [StaticText](cp.ui.StaticText.md) and an [Outline](cp.ui.Outline.md),
--- and the second with a [TextField](cp.ui.TextField.md).
---
--- The above is effectively the same as:
---
--- ```lua
--- local mySplitGroupBuilder = SplitGroup:with(
---     { StaticText, Outline },
---     TextField,
--- )
--- local mySplitGroup = mySplitGroupBuilder:build(parent, uiFinder)
--- ```
---
--- This provides a [Builder](cp.ui.Builder.md) that can be used to create a `SplitGroup` with the specified sections, and can be useful
--- if you don't need or want to create a custom subclass in a given circumstance.
---
--- Once you've defined your `SplitGroup` you can use it like so:
---
--- ```lua
--- local mySplitGroup = MySplitGroup(parent, uiFinder)
--- local sidebar = mySplitGroup.sections[1]
--- local label = mySplitGroup.sections[1][1]
--- local outline = sidebar[2]
--- local content = mySplitGroup.sections[2]
--- ```
---
--- And because `SplitGroup` delegates to [sections](#sections), you can just access the contents of it directly:
---
--- ```lua
--- local mySplitGroup = MySplitGroup(parent, uiFinder)
--- local sidebar = mySplitGroup[1]
--- local label = mySplitGroup[1][1]
--- local outline = sidebar[2]
--- local content = mySplitGroup[2]
--- ```
---
--- Of course, random indexes are a hassle to remember, so we can use the [cp.ui.has.alias](cp.ui.has.md#alias) API to make it easier to access:
---
--- ```lua
--- local alias = require "cp.ui.has" .alias
---
--- local mySplitGroup = SplitGroup:with(
---     alias "sidebar" {
---         alias "label" { StaticText },
---         alias "outline" { Outline },
---     },
---     alias "content" { TextField }
--- ):build(parent, uiFinder)
---
--- local sidebar = mySplitGroup.sidebar
--- local label = mySplitGroup.sidebar.label
--- local outline = sidebar.outline
--- local content = mySplitGroup.content
--- ```
---
--- Note: You can still access sections by their index, but the alias API is more readable.
---
--- Extends: [cp.ui.Element](cp.ui.Element.md)
--- Delegates To: [sections](#sections)

local require               = require

-- local log                   = require "hs.logger".new "SplitGroup"

local fn                    = require "cp.fn"
local ax                    = require "cp.fn.ax"
local Element               = require "cp.ui.Element"
local Splitter              = require "cp.ui.Splitter"
local has                   = require "cp.ui.has"

local chain                 = fn.chain
local split, imap, sort     = fn.table.split, fn.table.imap, fn.table.sort
local insert                = table.insert
local handler, list         = has.handler, has.list

local SplitGroup = Element:subclass("cp.ui.SplitGroup")
                        :delegateTo("sections")
                        :defineBuilder("with")

--- === cp.ui.SplitGroup.Builder ===
---
--- Defines a `SplitGroup` [Builder](cp.ui.Builder.md).

--- cp.ui.SplitGroup.Builder:with(...) -> cp.ui.SplitGroup.Builder
--- Method
--- Defines the provided [UIHandlers](cp.ui.has.UIHandler.md), one for each section, in the order they are specified.
---
--- Parameters:
---  * ... - The [Element](cp.ui.Element.md) initializers to use.
---
--- Returns:
---  * The `SplitGroup.Builder` instance.
---
--- Notes:
---  * Each section value can be anything compatible with [cp.ui.has.handler](cp.ui.has.md#handler).

--- cp.ui.SplitGroup.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `hs.axuielement` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
SplitGroup.static.matches = ax.matchesIf(Element.matches, ax.hasRole "AXSplitGroup")

--- cp.ui.SplitGroup(parent, uiFinder, [...]) -> cp.ui.SplitGroup
--- Constructor
--- Creates a new `SplitGroup`.
---
--- Parameters:
---  * parent		- The parent object.
---  * uiFinder		- The `function` or `cp.prop` which returns an `hs.axuielement` for the `SplitGroup`, or `nil`.
---  * ...          - An optional list of [UIHandlers](cp.ui.has.UIHandler.md), one per section.
---
--- Returns:
---  * A new `SplitGroup` instance.
---
--- Notes:
---  * The values passed for the list of [UIHandlers](cp.ui.has.UIHandler.md) can be any valid value that can be passed to [cp.ui.has.handler](cp.ui.has.md#handler).
---  * For example, `SplitGroup(parent, ui, TextField, has.list { StaticText, Table })` would create a `SplitGroup` with two sections, the first with a `TextField`, and the second with a `StaticText` and `Table`.
function SplitGroup:initialize(parent, uiFinder, ...)
    local sectionHandlers = {}
    local splitterHandlers = {}
    local childHandlers = {}

    for i = 1, select("#", ...) do
        if i ~= 1 then
            insert(splitterHandlers, Splitter)
            insert(childHandlers, Splitter)
        end
        local sectionHandler = handler(select(i, ...))
        insert(sectionHandlers, sectionHandler)
        insert(childHandlers, sectionHandler)
    end

    self.sectionHandlers = sectionHandlers
    self.splittersHandler = list(splitterHandlers)
    self.childrenHandler = list(childHandlers)

    Element.initialize(self, parent, uiFinder)
end

--- cp.ui.SplitGroup.childrenUI <cp.prop: table of hs.axuielement, read-only>
--- Field
--- The list of `axuielement`s for the sections, sorted in [top-down](cp.fn.ax.md#topDown) order.
function SplitGroup.lazy.prop:childrenUI()
    return ax.prop(self.UI, "AXChildren")
end

--- cp.ui.SplitGroup.children <cp.ui.has.ElementList, read-only>
--- Field
--- All children of the Split Group, including sections and splitters.
function SplitGroup.lazy.value:children()
    return self.childrenHandler:build(self, self.childrenUI)
end

--- cp.ui.SplitGroup.splittersUI <cp.prop: table of hs.axuielement, read-only>
--- Field
--- The list of `hs.axuielement`s for the splitters.
function SplitGroup.lazy.prop:splittersUI()
    return ax.prop(self.UI, "AXSplitters")
end

--- cp.ui.SplitGroup.splitters <cp.ui.has.ElementList, read-only>
--- Field
--- The `Splitters` of the `SplitGroup`. There will be one less splitter than there are sections.
function SplitGroup.lazy.value:splitters()
    return self.splittersHandler:build(self, self.splittersUI)
end

--- cp.ui.SplitGroup.sectionsUI <cp.prop: table of tables of hs.axuielement, read-only>
--- Field
--- The list of tables of `hs.axuielement`s for the each section, each sorted [top-down](cp.fn.ax.md#topDown).
function SplitGroup.lazy.prop:sectionsUI()
    return self.childrenUI:mutate(chain // fn.call
        >> split(Splitter.matches) >> fn.args.only(1)
        >> imap(sort(ax.topDown))
    )
end

--- cp.ui.SplitGroup.sections <table: any, read-only>
--- Field
--- The sections of the `SplitGroup`. Each section will the result of the matching [UIHandler](cp.ui.has.UIHandler.md) provided to the initializer.
--- Sections can be accessed via their number (1-based). If the handler provided an `alias`, then the alias will be added as well.
function SplitGroup.lazy.value:sections()
    local sectionHandlers = self.sectionHandlers
    local sections = {}

    for i, sectionHandler in ipairs(sectionHandlers) do
        local ui = self.sectionsUI:mutate(function(original)
            local sectionUI = original()
            if sectionUI then
                return sectionUI[i]
            end
        end)
        local section = sectionHandler:build(self, ui)
        sections[i] = section
        if sectionHandler.alias then
            sections[sectionHandler.alias] = section
        end
    end

    return sections
end

return SplitGroup
