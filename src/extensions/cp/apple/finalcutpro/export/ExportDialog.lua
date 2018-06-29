--- === cp.apple.finalcutpro.export.ExportDialog ===
---
--- Export Dialog Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log                           = require("hs.logger").new("PrefsDlg")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
--local inspect                       = require("hs.inspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils                       = require("cp.ui.axutils")
local id                            = require("cp.apple.finalcutpro.ids") "ExportDialog"
local dialog                        = require("cp.dialog")
local just                          = require("cp.just")
local prop                          = require("cp.prop")
local SaveSheet                     = require("cp.apple.finalcutpro.export.SaveSheet")
local i18n                          = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local ExportDialog = {}

--- cp.apple.finalcutpro.export.ExportDialog.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function ExportDialog.matches(element)
    if element then
        return element:attributeValue("AXSubrole") == "AXDialog"
           and element:attributeValue("AXModal")
           and axutils.childWithID(element, id "BackgroundImage") ~= nil
    end
    return false
end

--- cp.apple.finalcutpro.export.ExportDialog.new(app) -> ExportDialog
--- Constructor
--- Creates a new Export Dialog object.
---
--- Parameters:
---  * app - The `cp.apple.finalcutpro` object.
---
--- Returns:
---  * A new ExportDialog object.
function ExportDialog.new(app)
    local o = prop.extend({_app = app}, ExportDialog)

    local UI = app.windowsUI:mutate(function(original, self)
        return axutils.cache(self, "_ui", function()
            return axutils.childMatching(original(), ExportDialog.matches)
        end,
        ExportDialog.matches)
    end)

    prop.bind(o) {
--- cp.apple.finalcutpro.export.ExportDialog.UI <cp.prop: hs._asm.axuielement: read-only; live>
--- Field
--- Returns the Export Dialog `axuielement`.
        UI = UI,

--- cp.apple.finalcutpro.export.ExportDialog.isShowing <cp.prop: boolean; read-only; live>
--- Field
--- Is the window showing?
        isShowing = UI:ISNOT(nil),

--- cp.apple.finalcutpro.export.ExportDialog.title <cp.prop: string; read-only; live>
--- Field
--- The window title, or `nil` if not available.
        title = UI:mutate(function(original)
            local ui = original()
            return ui and ui:attributeValue("AXTitle")
        end),
    }

    return o
end

--- cp.apple.finalcutpro.export.ExportDialog:app() -> App
--- Method
--- Returns the app instance representing Final Cut Pro.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function ExportDialog:app()
    return self._app
end

local function isDefaultItem(menuItem)
    return menuItem:attributeValue("AXMenuItemCmdChar") ~= nil
end

local destinationFormat = "(.+)…"

--- cp.apple.finalcutpro.export.ExportDialog:show(destinationSelect, ignoreProxyWarning, ignoreMissingMedia, quiet) -> cp.apple.finalcutpro.export.ExportDialog, string
--- Method
--- Shows the Export Dialog with the Destination that matches the `destinationSelect`.
---
--- Parameters:
---  * destinationSelect    - The name, number or match function of the destination to export with.
---  * ignoreProxyWarning   - if `true`, the warning regarding exporting Proxies will be ignored.
---  * ignoreMissingMedia   - if `true`, the warning regarding exporting with missing media will be ignored.
---  * quiet                - if `true`, no dialogs will be shown if there is an error.
---
--- Returns:
---  * The `cp.apple.finalcutpro.export.ExportDialog` object for method chaining.
---  * If an error occurred, the message is returned as the second value
---
--- Notes:
--- * If providing a function, it will be passed one item - the name of the destination, and should return `true` to indicate a match. The name will not contain " (default)" if present.
function ExportDialog:show(destinationSelect, ignoreProxyWarning, ignoreMissingMedia, quiet)
    if not self:isShowing() then
        if destinationSelect == nil then
            destinationSelect = isDefaultItem
        elseif type(destinationSelect) ~= "number" then
            local defaultFormat = self:app().strings:find("FFShareDefaultApplicationFormat")
            defaultFormat = defaultFormat:gsub("([()])", "%%%1"):gsub("%%@", "(.+)") .. "…"
            local dest = destinationSelect
            -- this function will match based on the destination title, minus "(default)" and "…" if present.
            destinationSelect = function(menuItem)
                local title = menuItem:attributeValue("AXTitle")
                if title == nil then
                    return false
                elseif isDefaultItem(menuItem) then
                    title = title:match(defaultFormat)
                else
                    title = title:match(destinationFormat)
                end
                return type(dest) == "function" and dest(title) or title == tostring(dest)
            end
        end
        --------------------------------------------------------------------------------
        -- Open the window:
        --------------------------------------------------------------------------------
        local fcp = self:app()
        local menuItem = fcp:menu():findMenuUI({"File", "Share", destinationSelect})
        if not menuItem then
            return self, i18n("batchExportNoDestination")
        elseif menuItem:attributeValue("AXEnabled") then
            menuItem:doPress()

            local alert = fcp:alert()

            local counter = 0
            local proxyPlaybackEnabled = fcp:string("FFShareProxyPlaybackEnabledMessageText")
            local missingMedia = string.gsub(fcp:string("FFMissingMediaMessageText"), "%%@", ".*")
            while not self:isShowing() and counter < 100 do
                if alert:isShowing() then
                    if alert:containsText(proxyPlaybackEnabled, true) then
                        if ignoreProxyWarning then
                            alert:pressDefault()
                        else
                            alert:pressCancel()
                            local msg = i18n("batchExportProxyFilesDetected")
                            if not quiet then dialog.displayMessage(msg) end
                            return self, msg
                        end
                    elseif alert:containsText(missingMedia) then
                        if ignoreMissingMedia then
                            alert:pressDefault()
                        else
                            alert:pressCancel()
                            local msg = i18n("batchExportMissingFilesDetected")
                            if not quiet then dialog.displayMessage(msg) end
                            return self, msg
                        end
                    else
                        local msg = i18n("batchExportUnexpectedAlert")
                        return self, msg
                    end
                else
                    just.wait(0.1)
                end
                counter = counter + 1
            end
            if not self:isShowing() then
                return self, i18n("batchExportNotShowing")
            end
        else
            return self, i18n("batchExportDestinationDisabled")
        end
    end
    return self
end

--- cp.apple.finalcutpro.export.ExportDialog:hide() -> cp.apple.finalcutpro.export.ExportDialog
--- Method
--- Hides the Export Dialog
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.apple.finalcutpro.export.ExportDialog` object for method chaining.
function ExportDialog:hide()
    self:pressCancel()
    return self
end

--- cp.apple.finalcutpro.export.ExportDialog:pressCancel() -> cp.apple.finalcutpro.export.ExportDialog
--- Method
--- Presses the Cancel Button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.apple.finalcutpro.export.ExportDialog` object for method chaining.
function ExportDialog:pressCancel()
    local ui = self:UI()
    if ui then
        local btn = ui:cancelButton()
        if btn then
            btn:doPress()
        end
    end
    return self
end

--- cp.apple.finalcutpro.export.ExportDialog:pressNext() -> cp.apple.finalcutpro.export.ExportDialog
--- Method
--- Presses the Next Button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.apple.finalcutpro.export.ExportDialog` object for method chaining.
function ExportDialog:pressNext()
    local ui = self:UI()
    if ui then
        local nextBtn = ui:defaultButton()
        if nextBtn then
            nextBtn:doPress()
        end
    end
    return self
end

--- cp.apple.finalcutpro.export.ExportDialog:saveSheet() -> SaveSheet
--- Method
--- Creates a new Save Sheet.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The SaveSheet.
function ExportDialog:saveSheet()
    if not self._saveSheet then
        self._saveSheet = SaveSheet.new(self)
    end
    return self._saveSheet
end

return ExportDialog
