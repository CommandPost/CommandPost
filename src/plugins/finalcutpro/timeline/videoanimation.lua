--- === plugins.finalcutpro.timeline.videoanimation ===
---
--- Video Animation Actions

local require               = require

--local log                   = require "hs.logger".new "videoanimation"

local fcp                   = require "cp.apple.finalcutpro"
local i18n                  = require "cp.i18n"
local tools                 = require "cp.tools"
local axutils               = require "cp.ui.axutils"

local childWithRole         = axutils.childWithRole
local childrenWithRole      = axutils.childrenWithRole

local playErrorSound        = tools.playErrorSound

local plugin = {
    id = "finalcutpro.timeline.videoanimation",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"] = "fcpxCmds",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Toggle Opacity Fade Handles in Video Animation Popup on Selected Clips:
    --------------------------------------------------------------------------------
    deps.fcpxCmds
        :add("toggleOpacityFadeHandlesInVideoAnimationPopupOnSelectedClips")
        :whenActivated(function()
            local contents = fcp.timeline.contents
            local selectedClips = contents:selectedClipsUI()
            if selectedClips and #selectedClips >= 1 then
                for i, selectedClip in pairs(selectedClips) do
                    if selectedClip:attributeValue("AXRole") == "AXLayoutItem" then
                        if not fcp:selectMenu({"Clip", "Show Video Animation"}) then
                            playErrorSound()
                            return
                        end
                        selectedClip = contents:selectedClipsUI()[i]
                    end

                    if selectedClip and selectedClip:attributeValue("AXRole") == "AXLayoutItem" then
                        selectedClip = selectedClip:attributeValue("AXParent")
                    end

                    local children = selectedClip and selectedClip:attributeValue("AXChildren")
                    local group = children and childWithRole(children, "AXGroup")
                    local subgroups = group and childrenWithRole(group, "AXGroup")

                    if subgroups then
                        for _, subgroup in pairs(subgroups) do
                            local buttons = childrenWithRole(subgroup, "AXButton")
                            for _, button in pairs(buttons) do
                                if button and button:attributeValue("AXTitle") == "Disclosure" then
                                    button:performAction("AXPress")
                                end
                            end
                        end
                    end
                end
            else
                playErrorSound()
            end
        end)
        :titled(i18n("toggleOpacityFadeHandlesInVideoAnimationPopupOnSelectedClips"))
        :subtitled(i18n("toggleOpacityFadeHandlesInVideoAnimationPopupOnSelectedClipsDescription"))
end

return plugin
