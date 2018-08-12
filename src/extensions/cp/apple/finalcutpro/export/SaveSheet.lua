--- === cp.apple.finalcutpro.export.SaveSheet ===
---
--- Save Sheet

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
--local log                         = require("hs.logger").new("PrefsDlg")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils                       = require("cp.ui.axutils")
local GoToPrompt                    = require("cp.apple.finalcutpro.export.GoToPrompt")
local prop                          = require("cp.prop")
local ReplaceAlert                  = require("cp.apple.finalcutpro.export.ReplaceAlert")
local TextField                     = require("cp.ui.TextField")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local SaveSheet = {}

--- cp.apple.finalcutpro.export.SaveSheet.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function SaveSheet.matches(element)
    if element then
        return element:attributeValue("AXRole") == "AXSheet"
    end
    return false
end

--- cp.apple.finalcutpro.export.SaveSheet.new(app) -> SaveSheet
--- Function
--- Creates a new SaveSheet object.
---
--- Parameters:
---  * app - The `cp.apple.finalcutpro` object.
---
--- Returns:
---  * A new SaveSheet object.
function SaveSheet.new(parent)
    local o = {_parent = parent}
    return prop.extend(o, SaveSheet)
end

--- cp.apple.finalcutpro.export.SaveSheet:parent() -> object
--- Method
--- Returns the Parent object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object.
function SaveSheet:parent()
    return self._parent
end

--- cp.apple.finalcutpro.export.SaveSheet:app() -> App
--- Method
--- Returns the App instance representing Final Cut Pro.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function SaveSheet:app()
    return self:parent():app()
end

--- cp.apple.finalcutpro.export.SaveSheet:UI() -> axuielementObject
--- Method
--- Returns the Save Sheet Accessibility Object
---
--- Parameters:
---  * None
---
--- Returns:
---  * An `axuielementObject` or `nil`
function SaveSheet:UI()
    return axutils.cache(self, "_ui", function()
        return axutils.childMatching(self:parent():UI(), SaveSheet.matches)
    end,
    SaveSheet.matches)
end

--- cp.apple.finalcutpro.export.SaveSheet <cp.prop: boolean; read-only>
--- Field
--- Is the Save Sheet showing?
SaveSheet.isShowing = prop.new(function(self)
    return self:UI() ~= nil or self:replaceAlert():isShowing()
end):bind(SaveSheet)

--- cp.apple.finalcutpro.export.SaveSheet:hide() -> none
--- Method
--- Hides the Save Sheet
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function SaveSheet:hide()
    self:pressCancel()
end

--- cp.apple.finalcutpro.export.SaveSheet:pressCancel() -> cp.apple.finalcutpro.export.SaveSheet
--- Method
--- Presses the Cancel Button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.apple.finalcutpro.export.SaveSheet` object for method chaining.
function SaveSheet:pressCancel()
    local ui = self:UI()
    if ui then
        local btn = ui:cancelButton()
        if btn then
            btn:doPress()
        end
    end
    return self
end

--- cp.apple.finalcutpro.export.SaveSheet:pressSave() -> cp.apple.finalcutpro.export.SaveSheet
--- Method
--- Presses the Save Button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.apple.finalcutpro.export.SaveSheet` object for method chaining.
function SaveSheet:pressSave()
    local ui = self:UI()
    if ui then
        local btn = ui:defaultButton()
        if btn and btn:enabled() then
            btn:doPress()
        end
    end
    return self
end

--- cp.apple.finalcutpro.export.SaveSheet:getTitle() -> string | nil
--- Method
--- The title of the Save Sheet window or `nil`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The title of the Save Sheet window as a string or `nil`.
function SaveSheet:getTitle()
    local ui = self:UI()
    return ui and ui:title()
end

--- cp.apple.finalcutpro.export.SaveSheet:filename() -> TextField
--- Method
--- Returns the Save Sheet Filename Text Field.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The title of the Save Sheet window as a string or `nil`.
function SaveSheet:filename()
    if not self._filename then
        self._filename = TextField.new(self, function()
            return axutils.childWithRole(self:UI(), "AXTextField")
        end)
    end
    return self._filename
end

--- cp.apple.finalcutpro.export.SaveSheet:setPath(path) -> cp.apple.finalcutpro.export.SaveSheet
--- Method
--- Sets the path.
---
--- Parameters:
---  * path - The path as a string.
---
--- Returns:
---  * The `cp.apple.finalcutpro.export.SaveSheet` object for method chaining.
function SaveSheet:setPath(path)
    if self:isShowing() then
        --------------------------------------------------------------------------------
        -- Display the 'Go To' prompt:
        --------------------------------------------------------------------------------
        self:goToPrompt():show():setValue(path):pressDefault()
    end
    return self
end

--- cp.apple.finalcutpro.export.SaveSheet:setPath() -> ReplaceAlert
--- Method
--- Gets the Replace Alert object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `ReplaceAlert` object.
function SaveSheet:replaceAlert()
    if not self._replaceAlert then
        self._replaceAlert = ReplaceAlert.new(self)
    end
    return self._replaceAlert
end

--- cp.apple.finalcutpro.export.SaveSheet:goToPrompt() -> GoToPrompt
--- Method
--- Gets the Go To Prompt object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `GoToPrompt` object.
function SaveSheet:goToPrompt()
    if not self._goToPrompt then
        self._goToPrompt = GoToPrompt.new(self)
    end
    return self._goToPrompt
end

return SaveSheet
