--- === cp.blackmagic.resolve.color.Tracker ===
---
--- Tracker

local require = require

--local log                   = require "hs.logger".new "Tracker"

local axutils               = require "cp.ui.axutils"
local CheckBox              = require "cp.ui.CheckBox"
local Group                 = require "cp.ui.Group"
local MenuButton            = require "cp.ui.MenuButton"
local StaticText            = require "cp.ui.StaticText"

local cache                 = axutils.cache
local childFromTop          = axutils.childFromTop
local childMatching         = axutils.childMatching
local childrenMatching      = axutils.childrenMatching
local childWithDescription  = axutils.childWithDescription
local childWithTitle        = axutils.childWithTitle

local Tracker = Group:subclass("cp.blackmagic.resolve.color.Tracker")

Tracker.static.TITLE = "Tracker"

function Tracker.static.matches(element)
    if Group.matches(element) then
        local title = childFromTop(element, 1, StaticText.matches)
        return title and title:attributeValue("AXTitle") == Tracker.TITLE
    end
    return false
end

--- cp.apple.finalcutpro.main.Color(app) -> Color
--- Constructor
--- Creates a new `Color` instance.
---
--- Parameters:
---  * app - The Final Cut Pro app instance.
---
--- Returns:
---  * The new `Color`.
function Tracker:initialize(parent)
    local UI = parent.UI:mutate(function(original)
        return cache(self, "_ui", function()
            return childMatching(original(), Tracker.matches)
        end)
    end)
    Group.initialize(self, parent, UI)
end

function Tracker.lazy.value:active()
    return CheckBox(self, function()
        return childWithDescription(childrenMatching(self:parent():UI(), CheckBox.matches), Tracker.TITLE)
    end)
end

function Tracker:show()
    if not self:isShowing() then
        self.active:checked(true)
    end
    return self
end

function Tracker.lazy.value:pan()
    return CheckBox(self, function()
        local ui = self:UI()
        return ui and childWithTitle(ui, "Pan")
    end)
end

function Tracker.lazy.value:tilt()
    return CheckBox(self, function()
        local ui = self:UI()
        return ui and childWithTitle(ui, "Tilt")
    end)
end

function Tracker.lazy.value:zoom()
    return CheckBox(self, function()
        local ui = self:UI()
        return ui and childWithTitle(ui, "Zoom")
    end)
end

function Tracker.lazy.value:perspective3D()
    return CheckBox(self, function()
        local ui = self:UI()
        return ui and childWithTitle(ui, "Perspective 3D")
    end)
end

function Tracker.lazy.value:menuButton()
    return MenuButton(self, function()
        local ui = self:UI()
        local menus = childrenMatching(ui, MenuButton.matches)
        return ui and childWithTitle(menus, "")
    end)
end

return Tracker
