--- === cp.apple.finalcutpro.timeline.IndexRoles ===
---
--- Provides access to the 'Roles' section of the [Timeline Index](cp.apple.finalcutpro.timeline.Index.md)

-- local log	                = require "hs.logger" .new "IndexRoles"

local prop	                = require "cp.prop"
local go                    = require "cp.rx.go"

local axutils               = require "cp.ui.axutils"
local Button                = require "cp.ui.Button"
local Group                 = require "cp.ui.Group"

local strings	            = require "cp.apple.finalcutpro.strings"
local IndexRolesArea	    = require("cp.apple.finalcutpro.timeline.IndexRolesArea")
local IndexSection          = require "cp.apple.finalcutpro.timeline.IndexSection"

local cache                 = axutils.cache
local childMatching         = axutils.childMatching
local childrenMatching	    = axutils.childrenMatching

local Do, If                = go.Do, go.If

local IndexRoles = IndexSection:subclass("cp.apple.finalcutpro.timeline.IndexRoles")

--- cp.apple.finalcutpro.timeline.IndexRoles:activate() -> cp.ui.RadioButton
--- Method
--- The [RadioButton](cp.ui.RadioButton.md) that activates the 'Roles' section.
function IndexRoles.lazy.method:activate()
    return self:index():mode():roles()
end

local function _findGroupedButtonUI(ui, title)
    local groups = childrenMatching(ui, Group.matches)
    if groups then
        for _,group in ipairs(groups) do
            local buttonUI = childMatching(group, function(child)
                return Button.matches(child) and child:attributeValue("AXTitle") == title
            end)
            if buttonUI then
                return buttonUI
            end
        end
    end
end

--- cp.apple.finalcutpro.timeline.IndexRoles:area() -> cp.apple.finalcutpro.timeline.IndexRolesArea
--- Method
--- The [IndexRolesArea](cp.apple.finalcutpro.timeline.IndexRolesArea.md) containing the list of [Role](cp.apple.finalcutpro.timeline.Role.md).
function IndexRoles.lazy.method:area()
    return IndexRolesArea(self, self.UI:mutate(function(original)
        return cache(self, "_list", function()
            return childMatching(original(), IndexRolesArea.matches)
        end)
    end))
end

--- cp.apple.finalcutpro.timeline.IndexRoles:list() -> cp.apple.finalcutpro.timeline.IndexRolesList
--- Method
--- The [IndexRolesList](cp.apple.finalcutpro.timeline.IndexRolesList.md) for the roles.
function IndexRoles.lazy.method:list()
    return self:area():list()
end

--- cp.apple.finalcutpro.timeline.IndexRoles:editRoles() -> cp.ui.Button
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
    return Do(self:doShow())
    :Then(If(show.isShowing):Then(show:doPress()))
    :Label("IndexRoles:doShowAudioLanes")
end

--- cp.apple.finalcutpro.timeline.IndexRoles:doCollapseSubroles() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will collapse subroles, if they are currently expanded.
function IndexRoles.lazy.method:doCollapseSubroles()
    local collapse = self:collapseSubroles()
    return Do(self:doShow())
    :Then(If(collapse.isShowing):Then(collapse:doPress()))
    :Label("IndexRoles:doCollapseSubroles")
end

--- cp.apple.finalcutpro.timeline.IndexRoles:doHideAudioLanes() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will collapse subroles (if necessary) and hide the audio lanes.
function IndexRoles.lazy.method:doHideAudioLanes()
    local hide = self:hideAudioLanes()
    return Do(self:doShow())
    :Then(self:doCollapseSubroles())
    :Then(If(hide.isShowing):Then(hide:doPress()))
    :Label("IndexRoles:doHideAudioLanes")
end

--- cp.apple.finalcutpro.timeline.IndexRoles:saveLayout() -> table
--- Method
--- Returns a `table` containing the layout configuration for this class.
---
--- Returns:
--- * The layout configuration `table`.
function IndexRoles:saveLayout()
    return {
        showing = self:isShowing(),
        audioLanes = self:audioLanes(),
        area = self:area():saveLayout(),
    }
end

--- cp.apple.finalcutpro.timeline.IndexRoles:doLayout(layout) -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will apply the layout provided, if possible.
---
--- Parameters:
--- * layout - the `table` containing the layout configuration. Usually created via the [#saveLayout] method.
---
--- Returns:
--- * The [Statement](cp.rx.go.Statement.md).
function IndexRoles:doLayout(layout)
    layout = layout or {}
    return If(layout.showing == true)
    :Then(self:doShow())
    :Then(
        If(layout.audioLanes == true)
        :Then(self:doShowAudioLanes())
        :Otherwise(self:doHideAudioLanes())
    )
    :Then(self:area():doLayout(layout.area))
    :ThenYield()
    :Label("IndexRoles:doLayout")
end

--- cp.apple.finalcutpro.timeline.IndexRoles:allRoles([includeSubroles]) -> table of Roles
--- Method
--- Finds all Roles, optionally including all Subroles
---
--- Parameters:
--- * includeSubroles - (defaults to `false`) if `true` include subroles.
---
--- Returns:
--- * The table of [Role](cp.apple.finalcutpro.timeline.Role.md)s, or `nil` if no UI is available.
function IndexRoles:allRoles(includeSubroles)
    return self:list():allRoles(includeSubroles)
end

--- cp.apple.finalcutpro.timeline.IndexRoles:videoRoles([includeSubroles]) -> table of Roles
--- Method
--- Finds all Video Roles, optionally including all Subroles
---
--- Parameters:
--- * includeSubroles - (defaults to `false`) if `true` include subroles.
---
--- Returns:
--- * The table of [Role](cp.apple.finalcutpro.timeline.Role.md)s, or `nil` if no UI is available.
function IndexRoles:videoRoles(includeSubroles)
    return self:list():videoRoles(includeSubroles)
end

--- cp.apple.finalcutpro.timeline.IndexRoles:audioRoles([includeSubroles]) -> table of Roles
--- Method
--- Finds all Audio Roles, optionally including all Subroles
---
--- Parameters:
--- * includeSubroles - (defaults to `false`) if `true` include subroles.
---
--- Returns:
--- * The table of [Role](cp.apple.finalcutpro.timeline.Role.md)s, or `nil` if no UI is available.
function IndexRoles:audioRoles(includeSubroles)
    return self:list():audioRoles(includeSubroles)
end

--- cp.apple.finalcutpro.timeline.IndexRoles:captionRoles([includeSubroles]) -> table of Roles
--- Method
--- Finds all Caption Roles, optionally including all Subroles
---
--- Parameters:
--- * includeSubroles - (defaults to `false`) if `true` include subroles.
---
--- Returns:
--- * The table of [Role](cp.apple.finalcutpro.timeline.Role.md)s, or `nil` if no UI is available.
function IndexRoles:captionRoles(includeSubroles)
    return self:list():captionRoles(includeSubroles)
end

--- cp.apple.finalcutpro.timeline.IndexRoles:fineRoleTitled(title) -> Role or nil
--- Method
--- Finds the [Role](cp.apple.finalcutpro.timeline.Role.md) with the specified title.
---
--- Parameters:
--- * title - The title to match.
---
--- Returns:
--- * The [Role](cp.apple.finalcutpro.timeline.Role.md) with the title, or `nil`.
---
--- Notes:
--- * The title can be the English name (eg. "Video", "Titles", etc.) for default Roles, and it will find the correct role in the current FCPX language.
function IndexRoles:findRoleTitled(title)
    return self:list():findRoleTitled(title)
end

--- cp.apple.finalcutpro.timeline.IndexRoles:doActivate(title) -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will activate the provided role, if it is available.
--- This will automatically show and hide the Index if it is not currently visible.
---
--- Parameters:
--- * The title of the [Role](cp.apple.finalcutpro.timeline.Role.md) to activate.
---
--- Returns:
--- * The [Statement](cp.rx.go.Statement.md)
---
--- Notes:
--- * The title can be the English name (eg. "Video", "Titles", etc.) for default Roles, and it will find the correct role in the current FCPX language.
function IndexRoles:doActivate(title)
    return Do(self:index():doStoreLayout("doActivate"))
    :Then(self:doShow())
    :Then(self:list():doActivate(title))
    :Finally(self:index():doRecallLayout("doActivate"))
    :Label("IndexRoles:doActivate")
end

--- cp.apple.finalcutpro.timeline.IndexRoles:doDeactivate(title) -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will deactivate the provided role, if it is available.
--- This will automatically show and hide the Index if it is not currently visible.
---
--- Parameters:
--- * The title of the [Role](cp.apple.finalcutpro.timeline.Role.md) to activate.
---
--- Returns:
--- * The [Statement](cp.rx.go.Statement.md)
---
--- Notes:
--- * The title can be the English name (eg. "Video", "Titles", etc.) for default Roles, and it will find the correct role in the current FCPX language.
function IndexRoles:doDeactivate(title)
    return Do(self:index():doStoreLayout("doDeactivate"))
    :Then(self:doShow())
    :Then(self:list():doDeactivate(title))
    :Finally(self:index():doRecallLayout("doDeactivate"))
    :Label("IndexRoles:doDeactivate")
end

-- These help with caching the Statements for store/recall
function IndexRoles.lazy.method:_doStoreIndexLayout()
    return self:index():doStoreLayout("IndexRoles")
end

function IndexRoles.lazy.method:_doRecallIndexLayout()
    return self:index():doRecallLayout("IndexRoles")
end

--- cp.apple.finalcutpro.timeline.IndexRoles:doFocusInTimeline(title) -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will focus the listed role, if it is available and is an [AudioRole](cp.apple.finalcutpro.timeline.AudioRole.md).
--- This will automatically show and hide the Index if it is not currently visible.
---
--- Parameters:
--- * The title of the [Role](cp.apple.finalcutpro.timeline.Role.md) to activate.
---
--- Returns:
--- * The [Statement](cp.rx.go.Statement.md)
---
--- Notes:
--- * The title can be the English name (eg. "Dialogue", "Music", etc.) for default Roles, and it will find the correct role in the current FCPX language.
function IndexRoles:doFocusInTimeline(title)
    return Do(self:_doStoreIndexLayout())
    :Then(self:doShow())
    :Then(self:list():doFocusInTimeline(title))
    :Finally(self:_doRecallIndexLayout())
    :Label("IndexRoles:doFocusInTimeline")
end

--- cp.apple.finalcutpro.timeline.IndexRoles:doUnfocusInTimeline(title) -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will unfocus the listed role, if it is available and is an [AudioRole](cp.apple.finalcutpro.timeline.AudioRole.md).
--- This will automatically show and hide the Index if it is not currently visible.
---
--- Parameters:
--- * The title of the [Role](cp.apple.finalcutpro.timeline.Role.md) to activate.
---
--- Returns:
--- * The [Statement](cp.rx.go.Statement.md)
---
--- Notes:
--- * The title can be the English name (eg. "Dialogue", "Music", etc.) for default Roles, and it will find the correct role in the current FCPX language.
function IndexRoles:doUnfocusInTimeline(title)
    return Do(self:_doStoreIndexLayout())
    :Then(self:doShow())
    :Then(self:list():doUnfocusInTimeline(title))
    :Finally(self:_doRecallIndexLayout())
    :Label("IndexRoles:doUnfocusInTimeline")
end

--- cp.apple.finalcutpro.timeline.IndexRoles:doShowSubroleLanes(title) -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will show subrole lanes for the role, if it is available and is an [AudioRole](cp.apple.finalcutpro.timeline.AudioRole.md).
--- This will automatically show and hide the Index if it is not currently visible.
---
--- Parameters:
--- * The title of the [Role](cp.apple.finalcutpro.timeline.Role.md).
---
--- Returns:
--- * The [Statement](cp.rx.go.Statement.md)
---
--- Notes:
--- * The title can be the English name (eg. "Dialogue", "Music", etc.) for default Roles, and it will find the correct role in the current FCPX language.
function IndexRoles:doShowSubroleLanes(title)
    return Do(self:_doStoreIndexLayout())
    :Then(self:doShow())
    :Then(self:list():doShowSubroleLanes(title))
    :Finally(self:_doRecallIndexLayout())
    :Label("IndexRoles:doSubroleLanes")
end

--- cp.apple.finalcutpro.timeline.IndexRoles:doHideSubroleLanes(title) -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will hide the subrole lanes for the listed role, if it is available and is an [AudioRole](cp.apple.finalcutpro.timeline.AudioRole.md).
--- This will automatically show and hide the Index if it is not currently visible.
---
--- Parameters:
--- * The title of the [Role](cp.apple.finalcutpro.timeline.Role.md).
---
--- Returns:
--- * The [Statement](cp.rx.go.Statement.md)
---
--- Notes:
--- * The title can be the English name (eg. "Dialogue", "Music", etc.) for default Roles, and it will find the correct role in the current FCPX language.
function IndexRoles:doHideSubroleLanes(title)
    return Do(self:_doStoreIndexLayout())
    :Then(self:doShow())
    :Then(self:list():doHideSubroleLanes(title))
    :Finally(self:_doRecallIndexLayout())
    :Label("IndexRoles:doHideSubroleLanes")
end

return IndexRoles