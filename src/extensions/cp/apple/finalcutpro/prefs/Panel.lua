--- === cp.apple.finalcutpro.prefs.Panel ===
---
--- Preferences Panel.

local require           = require

local strings           = require "cp.apple.finalcutpro.strings"

local axutils           = require "cp.ui.axutils"
local Button            = require "cp.ui.Button"
local Group             = require "cp.ui.Group"

local If                = require "cp.rx.go".If

local childMatching     = axutils.childMatching
local childWith         = axutils.childWith

local Panel = Group:subclass("cp.apple.finalcutpro.prefs.Panel")

function Panel:initialize(parent, titleKey)
    self._titleKey = titleKey

    local UI = parent.UI:mutate(function(original)
        if self:isShowing() then
            local group = childMatching(original(), Group.matches)
            -- The group conains another single group that contains the actual checkboxes, etc.
            return group and #group == 1 and group[1] or nil
        end
    end)

    Group.initialize(self, parent, UI)
end

function Panel.lazy.prop:isShowing()
    return self.toolbar.selectedTitle:mutate(function(original)
        return original() == self:title()
    end)
end

function Panel.lazy.value:toolbar()
    return self:parent().toolbar
end

function Panel.lazy.value:toolbarItem()
    return Button(self, self.toolbar.UI:mutate(function(original)
        local ui = original()
        return ui and childWith(ui, "AXTitle", self:title())
    end))
end

function Panel:title()
    return strings:find(self._titleKey)
end

--- cp.apple.finalcutpro.prefs.Panel:show() -> self
--- Function
--- Shows the Panel.
---
--- Parameters:
---  * None
---
--- Returns:
---  * self
function Panel:show()
    local parent = self:parent()
    -- show the parent.
    if parent:show():isShowing() then
        self.toolbarItem:press()
    end
    return self
end

--- cp.apple.finalcutpro.prefs.Panel:hide() -> self
--- Function
--- Hides the General Preferences Panel.
---
--- Parameters:
---  * None
---
--- Returns:
---  * self
function Panel:hide()
    return self:parent():hide()
end

function Panel.lazy.method:doShow()
    return If(self.isShowing):Is(false)
    :Then(self:parent():doShow())
    :Then(self.button:doPress())
end

function Panel.lazy.method:doHide()
    return If(self.isShowing)
    :Then(self:parent():doHide())
end

return Panel
