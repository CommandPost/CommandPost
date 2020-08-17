--- === cp.blackmagic.resolve.color.Color ===
---
--- Color Module.

local require = require

--local log                   = require "hs.logger".new "Color"

local axutils               = require "cp.ui.axutils"
local Group                 = require "cp.ui.Group"

local Tracker               = require "cp.blackmagic.resolve.color.Tracker"

local childMatching         = axutils.childMatching

local Color = Group:subclass("cp.blackmagic.resolve.color.Color")

Color.static.DESCRIPTION = "Color"

--- cp.blackmagic.resolve.color.Color(app) -> Color
--- Constructor
--- Creates a new `Color` instance.
---
--- Parameters:
---  * app - The Final Cut Pro app instance.
---
--- Returns:
---  * The new `Color`.
function Color:initialize(primaryWindow)
    local UI = primaryWindow.UI:mutate(function(original)
        if self:isShowing() then
            return childMatching(original(), Group.matches)
        end
    end)
    Group.initialize(self, primaryWindow, UI)
end

function Color.lazy.value:active()
    return self:parent().colorActive
end

function Color.lazy.prop:isShowing()
    return self.active.checked
end

function Color:show()
    if not self:isShowing() then
        self.active:click()
    end
    return self
end

function Color.lazy.value:tracker()
    return Tracker(self)
end

return Color
