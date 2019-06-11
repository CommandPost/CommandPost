--- === cp.blackmagic.resolve.color.Tracker ===
---
--- Tracker

local require = require

local log                   = require "hs.logger".new "Tracker"

local axutils               = require "cp.ui.axutils"
local CheckBox              = require "cp.ui.CheckBox"
local Element               = require "cp.ui.Element"
local Group                 = require "cp.ui.Group"
local MenuButton            = require "cp.ui.MenuButton"
local prop                  = require "cp.prop"

local Do                    = require "cp.rx.go.Do"
local If                    = require "cp.rx.go.If"

local childrenWithRole      = axutils.childrenWithRole
local childWithDescription  = axutils.childWithDescription
local childWithTitle        = axutils.childWithTitle

local Tracker = Element:subclass "cp.blackmagic.resolve.color.Tracker"

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
    self._parent = parent
end

--- cp.blackmagic.resolve.color.Tracker:parent() -> parent
--- Method
--- Returns the parent object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object.
function Tracker:parent()
    return self._parent
end

function Tracker:app()
    return self:parent():app()
end

function Tracker.lazy.method:checkBox()
    return CheckBox(self, function()
        local primaryWindow = self:app():primaryWindow():UI()
        local group = childrenWithRole(primaryWindow, "AXGroup")
        local children = group and group[1] childrenWithRole(group[1], "AXCheckBox")
        return childWithDescription(children, "Tracker")
    end)
end

function Tracker:isShowing()
    return self:checkBox():checked() or false
end

function Tracker:show()
    if not self:isShowing() then
        self:checkBox():click()
    end
    return self
end

function Tracker.lazy.method:group()
    return Group(self, function()
        local primaryWindow = self:app():primaryWindow():UI()
        local group = childrenWithRole(primaryWindow, "AXGroup")
        local groups = group and group[1] and childrenWithRole(group[1], "AXGroup")
        for _, child in pairs(groups) do
            local staticText = childrenWithRole(child, "AXStaticText")
            if staticText and staticText[1] and staticText[1]:attributeValue("AXTitle") == "Tracker" then
                return child
            end
        end
    end)
end

function Tracker.lazy.method:pan()
    return CheckBox(self, function()
        local groupUI = self:group():UI()
        return groupUI and childWithTitle(groupUI, "Pan")
    end)
end

function Tracker.lazy.method:tilt()
    return CheckBox(self, function()
        local groupUI = self:group():UI()
        return groupUI and childWithTitle(groupUI, "Tilt")
    end)
end

function Tracker.lazy.method:zoom()
    return CheckBox(self, function()
        local groupUI = self:group():UI()
        return groupUI and childWithTitle(groupUI, "Zoom")
    end)
end

function Tracker.lazy.method:perspective3D()
    return CheckBox(self, function()
        local groupUI = self:group():UI()
        return groupUI and childWithTitle(groupUI, "Perspective 3D")
    end)
end

function Tracker.lazy.method:menuButton()
    return MenuButton(self, function()
        local groupUI = self:group():UI()
        local menus = childrenWithRole(groupUI, "AXMenuButton")
        return groupUI and childWithTitle(menus, "")
    end)
end

return Tracker