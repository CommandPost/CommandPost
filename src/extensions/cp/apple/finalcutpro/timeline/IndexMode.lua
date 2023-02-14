--- === cp.apple.finalcutpro.timeline.IndexMode ===
---
--- Timeline Index Mode Radio Group Module.

local strings                   = require "cp.apple.finalcutpro.strings"
local axutils                   = require "cp.ui.axutils"
local RadioGroup                = require "cp.ui.RadioGroup"
local RadioButton               = require "cp.ui.RadioButton"

local childMatching, cache      = axutils.childMatching, axutils.cache

local IndexMode = RadioGroup:subclass("cp.apple.finalcutpro.index.IndexMode")

local function clipsString()
    return strings:find("PEDataListClips")
end

local function tagsString()
    return strings:find("PEDataListTags")
end

local function rolesString()
    return strings:find("PEDataListRoles")
end

local function captionsString()
    return strings:find("PEDataListCaptions")
end

--- cp.apple.finalcutpro.timeline.IndexMode.matches(element) -> boolean
--- Function
--- Checks if the element is the `IndexMode`.
---
--- Parameters:
--- * element - The `axuielement` to check.
---
--- Returns:
--- * `true` if it matches, otherwise `false`.
function IndexMode.static.matches(element)
    return RadioGroup.matches(element) and #element >= 3 and element[1]:attributeValue("AXTitle") == clipsString()
end

--- cp.apple.finalcutpro.timeline.IndexMode(index) -> cp.apple.finalcutpro.timeline.IndexMode
--- Constructor
--- Creates a new `IndexMode` instance.
---
--- Parameters:
--- * index - The [Index](cp.apple.finalcutpro.timeline.Index.md) that contains the `mode`.
---
--- Returns:
--- * The new `IndexMode` instance.
function IndexMode:initialize(index)
    local UI = index.UI:mutate(function(original)
        return cache(self, "_ui", function()
            return childMatching(original(), IndexMode.matches), IndexMode.matches
        end)
    end)

    RadioGroup.initialize(self, index, UI)
end

--- cp.apple.finalcutpro.timeline.IndexMode.clips <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.ui) for the "Clips" mode.
function IndexMode.lazy.value:clips()
    return RadioButton(self, self.UI:mutate(function(original)
        return cache(self, "_clips", function()
            local ui = original()
            return ui and childMatching(ui, function(child) return child:attributeValue("AXTitle") == clipsString() end)
        end, RadioButton.matches)
    end))
end

--- cp.apple.finalcutpro.timeline.IndexMode.tags <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.ui) for the "Tags" mode.
function IndexMode.lazy.value:tags()
    return RadioButton(self, self.UI:mutate(function(original)
        return cache(self, "_tags", function()
            local ui = original()
            return ui and childMatching(ui, function(child) return child:attributeValue("AXTitle") == tagsString() end)
        end, RadioButton.matches)
    end))
end

--- cp.apple.finalcutpro.timeline.IndexMode.roles <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.ui) for the "Roles" mode.
function IndexMode.lazy.value:roles()
    return RadioButton(self, self.UI:mutate(function(original)
        return cache(self, "_roles", function()
            local ui = original()
            return ui and childMatching(ui, function(child) return child:attributeValue("AXTitle") == rolesString() end)
        end, RadioButton.matches)
    end))
end

--- cp.apple.finalcutpro.timeline.IndexMode.captions <cp.ui.RadioButton>
--- Field
--- The [RadioButton](cp.ui.RadioButton.ui) for the "Captions" mode.
function IndexMode.lazy.value:captions()
    return RadioButton(self, self.UI:mutate(function(original)
        return cache(self, "_captions", function()
            local ui = original()
            return ui and childMatching(ui, function(child) return child:attributeValue("AXTitle") == captionsString() end)
        end, RadioButton.matches)
    end))
end

return IndexMode
