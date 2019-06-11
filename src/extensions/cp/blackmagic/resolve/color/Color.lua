--- === cp.blackmagic.resolve.Color ===
---
--- Color Module.

local require = require

local log                   = require "hs.logger".new "Color"

local axutils               = require "cp.ui.axutils"
local Element               = require "cp.ui.Element"
local CheckBox              = require "cp.ui.CheckBox"
local prop                  = require "cp.prop"

local Tracker			    = require("cp.blackmagic.resolve.color.Tracker")

local Do                    = require "cp.rx.go.Do"
local If                    = require "cp.rx.go.If"

local childrenWithRole      = axutils.childrenWithRole
local childWithDescription  = axutils.childWithDescription

local Color = Element:subclass "cp.blackmagic.resolve.Color"

--- cp.apple.finalcutpro.main.Color(app) -> Color
--- Constructor
--- Creates a new `Color` instance.
---
--- Parameters:
---  * app - The Final Cut Pro app instance.
---
--- Returns:
---  * The new `Color`.
function Color:initialize(app)
    self._app = app
end

--- cp.blackmagic.resolve.main.Color:app() -> cp.blackmagic.resolve
--- Method
--- Returns the application object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The app instance.
function Color:app()
    return self._app
end

function Color.lazy.method:checkBox()
    return CheckBox(self, function()
        local primaryWindow = self:app():primaryWindow():UI()
        local children = primaryWindow and childrenWithRole(primaryWindow, "AXCheckBox")
        return childWithDescription(children, "Color")
    end)
end

function Color:isShowing()
    return self:checkBox():checked() or false
end

function Color:show()
    if not self:isShowing() then
        self:checkBox():click()
    end
    return self
end

function Color:tracker()
    return Tracker(self)
end

return Color
