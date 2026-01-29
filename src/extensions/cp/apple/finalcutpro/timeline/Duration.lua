--- === cp.apple.finalcutpro.timeline.Duration ===
---
--- Represents the duration field in the Final Cut Pro timeline's toolbar.
---
--- The `value` will be a `string` with one of the two patterns:
---
--- * `"<total>"` - A single timecode string, with the total duration of the current timeline.
--- * `"<selection> / <total>"` - Two timecodes, separated by a forward slash.
---
--- The timecode pattern will vary, depending on the current timecode format (as specified in FCP Preferences).
---
--- To make life easier, this element adds two properties:
---
--- * `total` - The total duration of the current timeline (may be `nil`).
--- * `selection` - The total duration of selected clips.
---
--- Extends: [cp.ui.StaticText](cp.ui.StaticText.md)

local require = require

local StaticText = require "cp.ui.StaticText"

local Duration = StaticText:subclass("cp.apple.finalcutpro.timeline.Duration")

local DURATION_PATTERN = "^([^/ ]+)$"
local RANGE_DURATION_PATTERN = "^([^/ ]+) ?/ ?([^/ ]+)$"

--- cp.apple.finalcutpro.timeline.Duration.total <cp.prop: string; live; read-only>
--- Field
--- The current duration of the timeline, as a `string`.
function Duration.lazy.prop:total()
    return self.value:mutate(function(original)
        local value = original()
        if not value then return nil end

        local _, duration = value:match(RANGE_DURATION_PATTERN)
        if not duration then
            duration = value:match(DURATION_PATTERN)
        end
        return duration
    end)
end

--- cp.apple.finalcutpro.timeline.Duration.selection <cp.prop: string; live; read-only>
--- Field
--- The current duration of selected range, as a `string`.
function Duration.lazy.prop:selection()
    return self.value:mutate(function(original)
        local value = original()
        if not value then return nil end

        local duration, _ = value:match(RANGE_DURATION_PATTERN)
        return duration
    end)
end

return Duration