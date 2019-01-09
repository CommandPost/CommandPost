local axutils                           = require("cp.ui.axutils")
local Element                           = require("cp.ui.Element")
local RadioGroup                        = require("cp.ui.RadioGroup")
local SplitGroup                        = require("cp.ui.SplitGroup")
local TextField                         = require("cp.ui.TextField")

local strings                           = require("cp.apple.finalcutpro.strings")

local childMatching, childFromLeft      = axutils.childMatching, axutils.childFromLeft
local cache                             = axutils.cache

local TimelineIndex = Element:subclass("cp.apple.finalcutpro.main.TimelineIndex")

function TimelineIndex.static.matches(element)
    if Element.matches(element) and SplitGroup.matches(element) then
        if childMatching(element, function(child) return TextField.matches(child, "AXSearchField") end) == nil then
            return false
        end

        local rg = childMatching(element, RadioGroup.matches)
        if rg and #rg >= 3 then
            local title = strings:find("PEDataListClips")
            local clips = childFromLeft(rg, 1)
            return clips and clips:attributeValue("AXTitle") == title
        end
    end
    return false
end

function TimelineIndex:initialize(timeline)
    local UI = timeline.UI:mutate(function(original)
        return cache(self, "_ui", function()
            return childMatching(original(), TimelineIndex.matches)
        end, TimelineIndex.matches)
    end)

    Element:initialize(self, timeline, UI)
end