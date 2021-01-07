--- === cp.apple.finalcutpro.import.MediaImport ===
---
--- Media Import

local require = require

local just                          = require "cp.just"
local strings                       = require "cp.apple.finalcutpro.strings"

local axutils                       = require "cp.ui.axutils"
local Button                        = require "cp.ui.Button"
local Dialog                        = require "cp.ui.Dialog"

local cache                         = axutils.cache
local childWith                     = axutils.childWith

local MediaImport = Dialog:subclass("cp.apple.finalcutpro.import.MediaImport")

-- _findWindowUI(windows) -> hs.axuielementObject | nil
-- Method
-- Finds a matching window UI.
--
-- Parameters:
--  * windows - A table of `hs.window` objects
--
-- Returns:
--  * An `axuielement` or `nil`
local function _findWindowUI(windows)
    for _,window in ipairs(windows) do
        if MediaImport.matches(window) then return window end
    end
    return nil
end

--- cp.apple.finalcutpro.import.MediaImport.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function MediaImport.static.matches(element)
    local importAll = strings:find("PEImportAll_NoEllipsis")
    return Dialog.matches(element)
       and element:attributeValue("AXMain")
       and element:attributeValue("AXModal")
       and importAll
       and childWith(element, "AXTitle", importAll) ~= nil
end

--- cp.apple.finalcutpro.import.MediaImport(app) -> MediaImport
--- Constructor
--- Creates a new Media Import object.
---
--- Parameters:
---  * app - The `cp.apple.finalcutpro` object.
---
--- Returns:
---  * A new MediaImport object.
function MediaImport:initialize(app)
    local UI = app.windowsUI:mutate(function(original)
        return cache(self, "_ui", function()
            local windowsUI = original()
            return windowsUI and _findWindowUI(windowsUI)
        end,
        MediaImport.matches)
    end)

    Dialog.initialize(self, app.app, UI)
end

--- cp.apple.finalcutpro.import.MediaImport.importAll <cp.ui.Button>
--- Field
--- The Import All button.
function MediaImport.lazy.value:importAll()
    return Button(self, axutils.prop(self.UI, "AXDefaultButton"))
end

--- cp.apple.finalcutpro.import.MediaImport.stopImport <cp.ui.Button>
--- Field
--- The "Stop Import" button.
function MediaImport.lazy.value:stopImport()
    return Button(self, self.UI:mutate(function(original)
        return axutils.childFromRight(original(), 2, Button.matches)
    end))
end

--- cp.apple.finalcutpro.import.MediaImport:show() -> cp.apple.finalcutpro.import.MediaImport
--- Method
--- Shows the Media Import window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.apple.finalcutpro.import.MediaImport` object for method chaining.
function MediaImport:show()
    if not self:isShowing() then
        -- open the window
        if self:app().menu:isEnabled({"File", "Import", "Media…"}) then
            self:app().menu:selectMenu({"File", "Import", "Media…"})
            just.doUntil(function() return self:isShowing() end)
        end
    end
    return self
end

--- cp.apple.finalcutpro.import.MediaImport:hide() -> cp.apple.finalcutpro.import.MediaImport
--- Method
--- Hides the Media Import window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.apple.finalcutpro.import.MediaImport` object for method chaining.
function MediaImport:hide()
    self:close()
    return self
end

return MediaImport
