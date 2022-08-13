--- === cp.apple.finalcutpro.workflowextensions.CommandPostWindow ===
---
--- The CommandPost Workflow Extension Window.

local require = require

-- local log							= require "hs.logger" .new("CommandPostWindow")

-- local inspect						= require "hs.inspect"

local axutils						= require "cp.ui.axutils"
local just							= require "cp.just"
local go                            = require "cp.rx.go"

local Group                         = require "cp.ui.Group"
local Button                        = require "cp.ui.Button"
local Window                        = require "cp.ui.Window"

local cache                         = axutils.cache
local childMatching                 = axutils.childMatching

local If                            = go.If
local WaitUntil                     = go.WaitUntil

local CommandPostWindow = Window:subclass("cp.apple.finalcutpro.workflowextensions.CommandPostWindow")

--- cp.apple.finalcutpro.workflowextensions.CommandPostWindow.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function CommandPostWindow.static.matches(element)
    return Window.matches(element)
        and element:attributeValue("AXTitle") == "CommandPost"
end

--- cp.apple.finalcutpro.workflowextensions.CommandPostWindow(app) -> CommandPostWindow
--- Constructor
--- Creates a new CommandPost Workflow Extension window object.
---
--- Parameters:
---  * app - The `cp.apple.finalcutpro` object.
---
--- Returns:
---  * A new `CommandPostWindow` object.
function CommandPostWindow:initialize(app)
    local UI = app.windowsUI:mutate(function(original)
        return cache(self, "_ui", function()
            return childMatching(original(), CommandPostWindow.matches)
        end)
    end)

    Window.initialize(self, app, UI)
end

--- cp.apple.finalcutpro.workflowextensions.CommandPostWindow.reloadButton <cp.ui.Button>
--- Field
--- The Reload Button within a stalled Workflow Extension.
function CommandPostWindow.lazy.value:reloadButton()
    return Button(self, self.UI:mutate(function(original)
        local group = childMatching(original(), Group.matches)
        local button = group and childMatching(group, Button.matches)
        return button and button:attributeValue("AXTitle") == self:app():string("FFExternalProviderReloadString") and button
    end))
end

--- cp.apple.finalcutpro.prefs.CommandPostWindow:reload() -> none
--- Method
--- Press the Reload Button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function CommandPostWindow:reload()
    if self:hasStalled() then
        self.reloadButton:press()
    end
end

--- cp.apple.finalcutpro.prefs.CommandPostWindow:hasStalled() -> boolean
--- Method
--- Has the Workflow Extension stalled?
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if stalled, otherwise `false`
function CommandPostWindow:hasStalled()
    return self.reloadButton:isShowing()
end

--- cp.apple.finalcutpro.prefs.CommandPostWindow:show() -> CommandPostWindow
--- Method
--- Attempts to show the CommandPost Workflow Extension window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The same `CommandPostWindow`, for chaining.
---
--- Notes:
---  * If the Workflow Extension has stalled, this method will restart it.
function CommandPostWindow:show()
    if self:isShowing() and self:hasStalled() then
        self:reload()
    end
    if not self:isShowing() then
        -- open the window
        if self:app().menu:isEnabled({"Window", "Extensions", "CommandPost"}) then
            self:app().menu:selectMenu({"Window", "Extensions", "CommandPost"})
            -- wait for it to open.
            just.doUntil(function() return self:UI() end)
        end
    end
    return self
end

--- cp.apple.finalcutpro.prefs.CommandPostWindow:doShow() -> cp.rx.go.Statement
--- Method
--- A `Statement` that attempts to show the CommandPost Workflow Extension window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement`.
function CommandPostWindow.lazy.method:doShow()
    return If(self.isShowing):Is(false):Then(
        self:app().menu:doSelectMenu({"Window", "Extensions", "CommandPost"})
    ):Then(
        WaitUntil(self.isShowing)
    )
end

--- cp.apple.finalcutpro.prefs.CommandPostWindow:hide() -> CommandPostWindow
--- Method
--- Attempts to hide the CommandPost Workflow Extension window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The same `CommandPostWindow`, for chaining.
function CommandPostWindow:hide()
    local hsWindow = self:hsWindow()
    if hsWindow then
        hsWindow:close()
        -- wait for it to close, up to 5 seconds
        just.doWhile(function() return self:isShowing() end, 5)
    end
    return self
end

--- cp.apple.finalcutpro.prefs.CommandPostWindow:doHide() -> cp.rx.go.Statement
--- Method
--- A `Statement` that attempts to hide the CommandPost Workflow Extension window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement`.
function CommandPostWindow.lazy.method:doHide()
    return If(self.isShowing)
    :Then(function()
        self:hsWindow():close()
    end)
    :Then(
        WaitUntil(self.isShowing):Is(false)
    )
end

return CommandPostWindow
