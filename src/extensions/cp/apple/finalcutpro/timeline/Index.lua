--- === cp.apple.finalcutpro.timeline.Index ===
---
--- Timeline Index Module.

-- local log                               = require("hs.logger").new "Index"

local go                                = require("cp.rx.go")
local axutils                           = require("cp.ui.axutils")
local SplitGroup                        = require("cp.ui.SplitGroup")
local SearchField                       = require("cp.ui.SearchField")

local IndexCaptions	                    = require("cp.apple.finalcutpro.timeline.IndexCaptions")
local IndexClips                        = require("cp.apple.finalcutpro.timeline.IndexClips")
local IndexMode                         = require("cp.apple.finalcutpro.timeline.IndexMode")
local IndexRoles	                    = require("cp.apple.finalcutpro.timeline.IndexRoles")
local IndexTags	                        = require("cp.apple.finalcutpro.timeline.IndexTags")

local childMatching, hasChild           = axutils.childMatching, axutils.hasChild
local cache                             = axutils.cache

local If, Do                            = go.If, go.Do

-- The Index class
local Index = SplitGroup:subclass("cp.apple.finalcutpro.timeline.Index")

--- cp.apple.finalcutpro.timeline.Index.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function Index.static.matches(element)
    return SplitGroup.matches(element)
       and hasChild(element, SearchField.matches)
       and hasChild(element, IndexMode.matches)
end

--- cp.apple.finalcutpro.timeline.Index(parent, uiFinder) -> cp.apple.finalcutpro.timeline.Index
--- Constructor
--- Creates a new Timeline Index.
---
--- Parameters:
---  * timeline		- [Timeline](cp.apple.finalcutpro.timeline.Timeline.md).
---
--- Returns:
---  * A new `Index` instance.
function Index:initialize(timeline)
    local UI = timeline.UI:mutate(function(original)
        return cache(self, "_ui", function()
            return childMatching(original(), Index.matches)
        end, Index.matches)
    end)

    SplitGroup.initialize(self, timeline, UI)
end

--- cp.apple.finalcutpro.timeline.Index.search <cp.ui.SearchField>
--- Field
--- The [SearchField](cp.ui.SearchField.md) for the Timeline Index.
function Index.lazy.value:search()
    return SearchField(self, self.UI:mutate(function(original)
        return childMatching(original(), SearchField.matches)
    end))
end

--- cp.apple.finalcutpro.timeline.Index:mode() -> cp.apple.finalcutpro.timeline.IndexMode
--- Method
--- The [IndexMode](cp.apple.finalcutpro.timeline.IndexMode.md) for the Index.
---
--- Returns:
---  * The `IndexMode`.
function Index.lazy.method:mode()
    return IndexMode(self)
end

--- cp.apple.finalcutpro.timeline.Index:doShow() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) which will show the Index if possible.
function Index.lazy.method:doShow()
    return self:parent().toolbar.index:doCheck()
end

--- cp.apple.finalcutpro.timeline.Index:doHide() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) which will hide the Index if possible.
function Index.lazy.method:doHide()
    return self:parent().toolbar.index:doUncheck()
end

--- cp.apple.finalcutpro.timeline.Index:clips() -> cp.apple.finalcutpro.timeline.IndexClips
--- Method
--- The [IndexClips](cp.apple.finalcutpro.timeline.IndexClips.md).
function Index.lazy.method:clips()
    return IndexClips(self)
end

--- cp.apple.finalcutpro.timeline.Index:tags() -> cp.apple.finalcutpro.timeline.IndexTags
--- Method
--- The [IndexTags](cp.apple.finalcutpro.timeline.IndexTags.md).
function Index.lazy.method:tags()
    return IndexTags(self)
end

--- cp.apple.finalcutpro.timeline.Index:roles() -> cp.apple.finalcutpro.timeline.IndexRoles
--- Method
--- The [IndexRoles](cp.apple.finalcutpro.timeline.IndexRoles.md).
function Index.lazy.method:roles()
    return IndexRoles(self)
end

--- cp.apple.finalcutpro.timeline.Index:captions() -> cp.apple.finalcutpro.timeline.IndexCaptions
--- Method
--- The [IndexCaptions](cp.apple.finalcutpro.timeline.IndexCaptions.md).
function Index.lazy.method:captions()
    return IndexCaptions(self)
end

--- cp.apple.finalcutpro.timeline.Index:activeTab() -> object
--- Method
--- Gets the active tab.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The active tab or `nil`.
function Index:activeTab()
    if self:clips():isShowing() then
        return self:clips()
    elseif self:tags():isShowing() then
        return self:tags()
    elseif self:roles():isShowing() then
        return self:roles()
    elseif self:captions():isShowing() then
        return self:captions()
    end
end

--- cp.apple.finalcutpro.timeline.Index:saveLayout() -> table
--- Method
--- Returns a `table` containing the layout configuration for this class.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The layout configuration `table`.
function Index:saveLayout()
    local layout = SplitGroup.saveLayout(self)

    layout.showing = self:isShowing()
    layout.clips = self:clips():saveLayout()
    layout.tags = self:tags():saveLayout()
    layout.roles = self:roles():saveLayout()
    layout.captions = self:captions():saveLayout()

    layout.search = self.search:saveLayout()

    return layout
end

--- cp.apple.finalcutpro.timeline.Index:doLayout(layout) -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will apply the layout provided, if possible.
---
--- Parameters:
---  * layout - the `table` containing the layout configuration. Usually created via the [#saveLayout] method.
---
--- Returns:
---  * The [Statement](cp.rx.go.Statement.md).
function Index:doLayout(layout)
    layout = layout or {}
    return Do(
        SplitGroup.doLayout(self, layout)
    ):Then(
        If(layout.showing == true)
        :Then(self:doShow())
        :Otherwise(self:doHide())
    )
    :Then(self:clips():doLayout(layout.clips))
    :Then(self:tags():doLayout(layout.tags))
    :Then(self:roles():doLayout(layout.roles))
    :Then(self:captions():doLayout(layout.captions))
    :Then(self.search:doLayout(layout.search))
    :Label("Index:doLayout")
end

return Index