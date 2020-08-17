--- === cp.blackmagic.resolve.main.PrimaryWindow ===
---
--- Primary Window Module.

local require               = require

--local log                 = require "hs.logger".new "primaryWindow"

local axutils               = require "cp.ui.axutils"
local CheckBox              = require "cp.ui.CheckBox"
local Window                = require "cp.ui.Window"

local Do                    = require "cp.rx.go.Do"
local If                    = require "cp.rx.go.If"

local Color                 = require "cp.blackmagic.resolve.color.Color"

local childrenMatching      = axutils.childrenMatching
local childWithDescription  = axutils.childWithDescription

local PrimaryWindow = Window:subclass("cp.blackmagic.resolve.main.PrimaryWindow")

--- cp.blackmagic.resolve.main.PrimaryWindow.matches(w) -> boolean
--- Function
--- Checks to see if a window matches the PrimaryWindow requirements
---
--- Parameters:
---  * w - The window to check
---
--- Returns:
---  * `true` if matched otherwise `false`
function PrimaryWindow.static.matches(element)
    if Window.matches(element) then
        local children = childrenMatching(element, CheckBox.matches)
        return children and #children >= 6
    end
    return false
end

--- cp.blackmagic.resolve.main.PrimaryWindow(app) -> PrimaryWindow object
--- Constructor
--- Creates a new PrimaryWindow.
---
--- Parameters:
---  * None
---
--- Returns:
---  * PrimaryWindow
function PrimaryWindow:initialize(resolve)

--- cp.blackmagic.resolve.main.PrimaryWindow.resolve -> cp.blackmagic.resolve
--- Field
--- The main `Resolve` application root.
    self.resolve = resolve

    local UI = resolve.windowsUI:mutate(function(original)
        return axutils.cache(self, "_ui", function()
            return axutils.childMatching(original(), PrimaryWindow.matches)
        end,
        PrimaryWindow.matches)
    end)
    Window.initialize(self, resolve.app, UI)
end

function PrimaryWindow.lazy.value:colorActive()
    return CheckBox(self, self.UI:mutate(function(original)
        return childWithDescription(childrenMatching(original(), CheckBox.matches), Color.DESCRIPTION)
    end))
end

function PrimaryWindow.lazy.value:color()
    return Color(self)
end

--- cp.blackmagic.resolve.main.PrimaryWindow:show() -> PrimaryWindow
--- Method
--- Shows the Primary Window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `PrimaryWindow` instance.
function PrimaryWindow:show()
    self.resolve:show()
    if not self:isShowing() then
        return self:focus()
    end
    return self
end

--- cp.blackmagic.resolve.main.PrimaryWindow:doShow() -> PrimaryWindow
--- Field
--- A [Statement](cp.rx.go.Statement.md) that attempts to show the Primary Window.
---
--- Returns:
--- * The `Statement`, which resolves as either `true` or sends an error.
function PrimaryWindow.lazy.method:doShow()
    return Do(self.resolve:doShow())
    :Then(
        If(self.isShowing):Is(false)
        :Then(self:doFocus())
    )
    :Label("PrimaryWindow:doShow")
end

return PrimaryWindow
