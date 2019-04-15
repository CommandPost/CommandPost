--- === cp.apple.finalcutpro.export.ExportDialog ===
---
--- Export Dialog Module.

local require                       = require

--local log                           = require("hs.logger").new("ExportDialog")

local axutils                       = require("cp.ui.axutils")
local dialog                        = require("cp.dialog")
local i18n                          = require("cp.i18n")
local just                          = require("cp.just")
local prop                          = require("cp.prop")
local SaveSheet                     = require("cp.apple.finalcutpro.export.SaveSheet")

local v                             = require("semver")

local displayMessage                = dialog.displayMessage
local wait                          = just.wait


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
           and axutils.childWithDescription(element, "PE Share WindowBackground") ~= nil
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

--- cp.apple.finalcutpro.export.ExportDialog:show(destinationSelect, ignoreProxyWarning, ignoreMissingMedia, ignoreInvalidCaptions, quiet) -> cp.apple.finalcutpro.export.ExportDialog, string
--- Method
--- Shows the Export Dialog with the Destination that matches the `destinationSelect`.
---
--- Parameters:
---  * destinationSelect        - The name, number or match function of the destination to export with.
---  * ignoreProxyWarning       - if `true`, the warning regarding exporting Proxies will be ignored.
---  * ignoreMissingMedia       - if `true`, the warning regarding exporting with missing media will be ignored.
---  * ignoreInvalidCaptions    - if `true`, the warning regarding exporting with Bad Captions will be ignored.
---  * quiet                    - if `true`, no dialogs will be shown if there is an error.
---
--- Returns:
---  * The `cp.apple.finalcutpro.export.ExportDialog` object for method chaining.
---  * If an error occurred, the message is returned as the second value
---
--- Notes:
--- * If providing a function, it will be passed one item - the name of the destination, and should return `true` to indicate a match. The name will not contain " (default)" if present.
function ExportDialog:show(destinationSelect, ignoreProxyWarning, ignoreMissingMedia, ignoreInvalidCaptions, quiet)
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

        --------------------------------------------------------------------------------
        -- Wait for Final Cut Pro to catch up:
        --------------------------------------------------------------------------------
        wait(0.1)

        if not menuItem then
            --------------------------------------------------------------------------------
            -- No destination selected:
            --------------------------------------------------------------------------------
            local msg = i18n("batchExportNoDestination")
            if not quiet then displayMessage(msg) end
            return self, msg
        elseif menuItem:attributeValue("AXEnabled") then
            menuItem:doPress()

            local alert = fcp:alert()

            local missingMediaString = fcp:string("FFMissingMediaMessageText")
            local missingMedia = missingMediaString and string.gsub(missingMediaString, "%%@", ".*")

            local proxyPlaybackEnabled, missingMediaAndInvalidCaptionsString, missingMediaAndInvalidCaptions, invalidCaptionsString, invalidCaptions
            if fcp:version() >= v("10.4.0") then
                --------------------------------------------------------------------------------
                -- These alerts are only available in Final Cut Pro 10.4 and later:
                --------------------------------------------------------------------------------
                proxyPlaybackEnabled = fcp:string("FFShareProxyPlaybackEnabledMessageText")

                missingMediaAndInvalidCaptionsString = fcp:string("FFMissingMediaAndBrokenCaptionsMessageText")
                missingMediaAndInvalidCaptions = missingMediaAndInvalidCaptionsString and string.gsub(missingMediaAndInvalidCaptionsString, "%%@", ".*")

                invalidCaptionsString = fcp:string("FFBrokenCaptionsMessageText")
                invalidCaptions = invalidCaptionsString and string.gsub(invalidCaptionsString, "%%@", ".*")
            end

            local counter = 0
            while not self:isShowing() and counter < 100 do
                if alert:isShowing() then
                    if proxyPlaybackEnabled and alert:containsText(proxyPlaybackEnabled, true) then
                        --------------------------------------------------------------------------------
                        -- Proxy Warning:
                        --------------------------------------------------------------------------------
                        if ignoreProxyWarning then
                            alert:pressDefault()
                        else
                            alert:pressCancel()
                            local msg = i18n("batchExportProxyFilesDetected")
                            if not quiet then displayMessage(msg) end
                            return self, msg
                        end
                    elseif missingMedia and alert:containsText(missingMedia) then
                        --------------------------------------------------------------------------------
                        -- Missing Media Warning:
                        --------------------------------------------------------------------------------
                        if ignoreMissingMedia then
                            alert:pressDefault()
                        else
                            alert:pressCancel()
                            local msg = i18n("batchExportMissingFilesDetected")
                            if not quiet then displayMessage(msg) end
                            return self, msg
                        end
                    elseif missingMediaAndInvalidCaptions and alert:containsText(missingMediaAndInvalidCaptions) then
                        --------------------------------------------------------------------------------
                        -- Missing Media & Invalid Captions Warning:
                        --------------------------------------------------------------------------------
                        if ignoreMissingMedia and ignoreInvalidCaptions then
                            alert:pressDefault()
                        else
                            alert:pressCancel()
                            local msg = i18n("batchExportMissingFilesAndBadCaptionsDetected")
                            if not quiet then displayMessage(msg) end
                            return self, msg
                        end
                    elseif invalidCaptions and alert:containsText(invalidCaptions) then
                        --------------------------------------------------------------------------------
                        -- Invalid Captions Warning:
                        --------------------------------------------------------------------------------
                        if ignoreInvalidCaptions then
                            alert:pressDefault()
                        else
                            alert:pressCancel()
                            local msg = i18n("batchExportInvalidCaptionsDetected")
                            if not quiet then displayMessage(msg) end
                            return self, msg
                        end
                    else
                        --------------------------------------------------------------------------------
                        -- Unknown Error Message:
                        --------------------------------------------------------------------------------
                        local msg = i18n("batchExportUnexpectedAlert")
                        if not quiet then displayMessage(msg) end
                        return self, msg
                    end
                else
                    wait(0.1)
                end
                counter = counter + 1
            end
            if not self:isShowing() then
                --------------------------------------------------------------------------------
                -- Batch Export is not showing:
                --------------------------------------------------------------------------------
                local msg = i18n("batchExportNotShowing")
                if not quiet then displayMessage(msg) end
                return self, msg
            end
        else
            --------------------------------------------------------------------------------
            -- Batch Export Destination is disabled:
            --------------------------------------------------------------------------------
            local msg = i18n("batchExportDestinationDisabled")
            if not quiet then displayMessage(msg) end
            return self, msg
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
