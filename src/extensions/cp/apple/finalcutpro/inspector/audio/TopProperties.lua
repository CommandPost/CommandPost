--- === cp.apple.finalcutpro.inspector.audio.TopProperties ===
---
--- The `TopProperties` class is used to represent the top properties group of the Audio Inspector.

local require               = require

-- local log                   = require "hs.logger".new "TopProperties"

local fn                    = require "cp.fn"
local ax                    = require "cp.fn.ax"
local Group                 = require "cp.ui.Group"

local IP                    = require "cp.apple.finalcutpro.inspector.InspectorProperty"

local chain                 = fn.chain
local get                   = fn.table.get

local hasProperties, slider = IP.hasProperties, IP.slider


local TopProperties = Group:subclass("cp.apple.finalcutpro.inspector.audio.TopProperties")

--- cp.apple.finalcutpro.inspector.audio.TopProperties.matches(element) -> boolean
--- Function
--- Checks if the element matches the TopProperties.
---
--- Parameters:
---  * element - The element to check.
---
--- Returns:
---  * `true` if the element matches, `false` otherwise.
TopProperties.static.matches = Group.matches

--- cp.apple.finalcutpro.inspector.audio.TopProperties(parent, uiFinder) -> TopProperties
--- Constructor
--- Creates a new TopProperties.
---
--- Parameters:
---  * parent		- The parent object.
---  * uiFinder	- The `axuielement` object that represents this element.
function TopProperties:initialize(parent, uiFinder)
    Group.initialize(self, parent, uiFinder)

    hasProperties(self, self.contentUI) {
        volume              = slider "FFAudioVolumeToolName",
    }
end

--- cp.apple.finalcutpro.inspector.audio.TopProperties.contentUI <cp.prop: hs.axuielement; read-only; live>
--- Field
--- The `axuielement` object that represents the content of the TopProperties group.
function TopProperties.lazy.prop:contentUI()
    return self.UI:mutate(chain // ax.children >> get(1))
end

return TopProperties