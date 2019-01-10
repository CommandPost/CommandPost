--- === cp.apple.finalcutpro.timeline.Index ===
---
--- Timeline Index Module.

-- local log                               = require("hs.logger").new "Index"

local go                                = require("cp.rx.go")
local axutils                           = require("cp.ui.axutils")
local SplitGroup                        = require("cp.ui.SplitGroup")
local SearchField                       = require("cp.ui.SearchField")

local strings                           = require("cp.apple.finalcutpro.strings")
local IndexClips                        = require("cp.apple.finalcutpro.timeline.IndexClips")
local IndexMode                         = require("cp.apple.finalcutpro.timeline.IndexMode")
local IndexTags	                        = require("cp.apple.finalcutpro.timeline.IndexTags")

local childMatching, hasChild           = axutils.childMatching, axutils.hasChild
local cache                             = axutils.cache

local If                                = go.If

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

--- cp.apple.finalcutpro.timeline.Index:search() -> cp.ui.SearchField
--- Method
--- The [SearchField](cp.ui.SearchField.md) for the Timeline Index.
---
--- Returns:
--- * The SearchField.
function Index.lazy.method:search()
    return SearchField(self, self.UI:mutate(function(original)
        return childMatching(original(), SearchField.matches)
    end))
end

--- cp.apple.finalcutpro.timeline.Index:mode() -> cp.apple.finalcutpro.timeline.IndexMode
--- Method
--- The [IndexMode](cp.apple.finalcutpro.timeline.IndexMode.md) for the Index.
---
--- Returns:
--- * The `IndexMode`.
function Index.lazy.method:mode()
    return IndexMode(self)
end

--- cp.apple.finalcutpro.timeline.Index:doShow() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) which will show the Index if possible.
function Index.lazy.method:doShow()
    return self:parent():toolbar():index().doCheck
end

--- cp.apple.finalcutpro.timeline.Index:doFindClipsContaining(text) -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.go.rx.Statement.md) that will use the index to search for clips containing the specified text.
---
--- Parameters:
--- * text - The text to search for.
---
--- Returns:
--- * The [Statement](cp.rx.go.Statement.md)
---
--- Notes:
--- * Because the `text` can change each time, this result is not cached automatically. However as long as you are searching for the same text the result can be safely cached. The [#toFindMissingMedia] method does this, for example.
function Index:doFindClipsContaining(text)
    return If(self.doShowClips)
    :Then(function()
        self:search():value(text)
        return true
    end)
    :Otherwise(false)
    :ThenYield()
    :Label("Index:doFindClipsContaining('"..text.."')")
end

--- cp.apple.finalcutpro.timeline.Index:doFindMissingMedia() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will use the index to search for all "Missing Media".
function Index.lazy.method:doFindMissingMedia()
    return self:doFindClipsContaining(strings:find("FFTimelineIndexMissingMediaSearch"))
    :Label("Index:doFindMissingMedia")
end

--- cp.apple.finalcutpro.timeline.Index:doFindAuditions() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will use the index to search for all "Auditions".
function Index.lazy.method:doFindAuditions()
    return self:doFindClipsContaining(strings:find("FFOrganizerFilterHUDClipTypeAudition"))
    :Label("Index:doFindAuditions")
end

--- cp.apple.finalcutpro.timeline.Index:doFindMulticams() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will use the index to search for all "Multicam" clips.
function Index.lazy.method:doFindMulticams()
    return self:doFindClipsContaining(strings:find("FFOrganizerFilterHUDClipTypeMultiCam"))
    :Label("Index:doFindMulticams")
end

--- cp.apple.finalcutpro.timeline.Index:doFindCompoundClips() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will use the index to search for all "Compound Clips".
function Index.lazy.method:doFindCompoundClips()
    return self:doFindClipsContaining(strings:find("FFOrganizerFilterHUDClipTypeCompound"))
    :Label("Index:doFindCompoundClips")
end

--- cp.apple.finalcutpro.timeline.Index:doFindSynchronized() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will use the index to search for all "Synchronized" Clips.
function Index.lazy.method:doFindSynchronized()
    return self:doFindClipsContaining(strings:find("FFOrganizerFilterHUDClipTypeSynchronized"))
    :Label("Index:doFindSynchronized")
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

return Index