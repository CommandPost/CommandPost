--- === cp.apple.finalcutpro.timeline.IndexRoles ===
---
--- Provides access to the 'Roles' section of the [Timeline Index](cp.apple.finalcutpro.timeline.Index.md)

-- local log	                = require "hs.logger" .new "IndexRoles"

local class                 = require "middleclass"
local lazy                  = require "cp.lazy"
local prop	                = require "cp.prop"
local go                    = require "cp.rx.go"

local axutils               = require "cp.ui.axutils"
local Button                = require "cp.ui.Button"
local Group                 = require "cp.ui.Group"

local strings	            = require "cp.apple.finalcutpro.strings"

local cache                 = axutils.cache
local childMatching         = axutils.childMatching
local childrenMatching	    = axutils.childrenMatching

local Do, If                = go.Do, go.If

local IndexRoles = class("cp.apple.finalcutpro.timeline.IndexRoles"):include(lazy)

--- cp.apple.finalcutpro.timeline.IndexRoles(index) -> IndexRoles
--- Constructor
--- Creates the `IndexRoles` instance.
---
--- Parameters:
--- * index - The [Index](cp.apple.finalcutpro.timeline.Index.md) instance.
function IndexRoles:initialize(index)
    self._index = index
end

--- cp.apple.finalcutpro.timeline.IndexRoles:parent() -> cp.apple.finalcutpro.timeline.Index
--- Method
--- The parent index.
function IndexRoles:parent()
    return self:index()
end

--- cp.apple.finalcutpro.timeline.IndexRoles:app() -> cp.apple.finalcutpro
--- Method
--- The [Final Cut Pro](cp.apple.finalcutpro.md) instance.
function IndexRoles:app()
    return self:parent():app()
end

function IndexRoles:index()
    return self._index
end

--- cp.apple.finalcutpro.timeline.IndexRoles:activate() -> cp.ui.RadioButton
--- Method
--- The [RadioButton](cp.ui.RadioButton.md) that activates the 'Roles' section.
function IndexRoles.lazy.method:activate()
    return self:index():mode():roles()
end

--- cp.apple.finalcutpro.timeline.IndexRoles.UI <cp.prop: axuielement; read-only; live?>
--- Field
--- The `axuielement` that represents the item.
function IndexRoles.lazy.prop:UI()
    return self:index().UI:mutate(function(original)
        return self:activate():checked() and original()
    end)
end

--- cp.apple.finalcutpro.timeline.IndexRoles.isShowing <cp.prop: boolean; read-only; live?>
--- Field
--- Indicates if the Roles section is currently showing.
function IndexRoles.lazy.prop:isShowing()
    return self:activate().checked
end

--- cp.apple.finalcutpro.timeline.IndexRoles:doShow() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will show the Roles section in the Timeline Index, if possible.
---
--- Returns:
--- * The [Statement](cp.rx.go.Statement.md)
function IndexRoles.lazy.method:doShow()
    local index = self:index()
    return Do(index.doShow)
    :Then(
        If(index.isShowing)
        :Then(self:activate().doPress)
        :Otherwise(false)
    )
    :ThenYield()
    :Label("IndexRoles:doShow")
end

local function _findGroupedButtonUI(ui, title)
    local groups = childrenMatching(ui, Group.matches)
    for _,group in ipairs(groups) do
        local buttonUI = childMatching(group, function(child)
            return Button.matches(child) and child:attributeValue("AXTitle") == title
        end)
        if buttonUI then
            return buttonUI
        end
    end
end

--- cp.apple.finalcutpro.timeline.IndexRoles:ediRoles() -> cp.ui.Button
--- Method
--- The `Edit Roles...` [Button](cp.ui.Button.md).
function IndexRoles.lazy.method:editRoles()
    return Button(self, self.UI:mutate(function(original)
        return cache(self, "_editRoles", function()
            return _findGroupedButtonUI(original(), strings:find("FFEditRolesMenuTitle"))
        end)
    end))
end

--- cp.apple.finalcutpro.timeline.IndexRoles:showAudioLanes() -> cp.ui.Button
--- Method
--- The `Show Audio Lanes` [Button](cp.ui.Button.md).
function IndexRoles.lazy.method:showAudioLanes()
    return Button(self, self.UI:mutate(function(original)
        return _findGroupedButtonUI(original(), strings:find("FFOrganizeAudio"))
    end))
end

--- cp.apple.finalcutpro.timeline.IndexRoles:hideAudioLanes() -> cp.ui.Button
--- Method
--- The `Hide Audio Lanes` [Button](cp.ui.Button.md).
function IndexRoles.lazy.method:hideAudioLanes()
    return Button(self, self.UI:mutate(function(original)
        return _findGroupedButtonUI(original(), strings:find("FFUnorganizeAudio"))
    end))
end

--- cp.apple.finalcutpro.timeline.IndexRoles:collapseSubroles() -> cp.ui.Button
--- Method
--- The `Collapse Subroles` [Button](cp.ui.Button.md).
function IndexRoles.lazy.method:collapseSubroles()
    return Button(self, self.UI:mutate(function(original)
        return _findGroupedButtonUI(original(), strings:find("FFCollapseAllAudioLanes"))
    end))
end

--- cp.apple.finalcutpro.timeline.audioLanes <cp.prop: boolean>
--- Field
--- Indicates if audio lanes are currently showing. May be set to ensure it is showing or hidden.
function IndexRoles.lazy.prop:audioLanes()
    return prop(
        function()
            return not self:showAudioLanes():isShowing()
        end,
        function(showing)
            If(showing)
            :Then(self.doShowAudioLanes)
            :Otherwise(self.doHideAudioLanes)
            :Now()
        end
    )
end

--- cp.apple.finalcutpro.timeline.IndexRoles:doShowAudioLanes() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will show the Audio Lanes when executed.
function IndexRoles.lazy.method:doShowAudioLanes()
    local show = self:showAudioLanes()
    return Do(self.doShow)
    :Then(If(show.isShowing):Then(show.doPress))
    :Label("IndexRoles:doShowAudioLanes")
end

--- cp.apple.finalcutpro.timeline.IndexRoles:doCollapseSubroles() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will collapse subroles, if they are currently expanded.
function IndexRoles.lazy.method:doCollapseSubroles()
    local collapse = self:collapseSubroles()
    return Do(self.doShow)
    :Then(If(collapse.isShowing):Then(collapse.doPress))
    :Label("IndexRoles:doCollapseSubroles")
end

--- cp.apple.finalcutpro.timeline.IndexRoles:doHideAudioLanes() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will collapse subroles (if necessary) and hide the audio lanes.
function IndexRoles.lazy.method:doHideAudioLanes()
    local hide = self:hideAudioLanes()
    return Do(self.doShow)
    :Then(self.doCollapseSubroles)
    :Then(If(hide.isShowing):Then(hide.doPress))
    :Label("IndexRoles:doHideAudioLanes")
end

return IndexRoles