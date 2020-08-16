--- === cp.apple.finalcutpro.export.ExportDialog ===
---
--- Export Dialog Module.

local require               = require

--local log                   = require("hs.logger").new("ExportDialog")

local axutils               = require "cp.ui.axutils"
local dialog                = require "cp.dialog"
local Dialog                = require "cp.ui.Dialog"
local i18n                  = require "cp.i18n"
local just                  = require "cp.just"
local SaveSheet             = require "cp.apple.finalcutpro.export.SaveSheet"

local Button                = require "cp.ui.Button"
local StaticText            = require "cp.ui.StaticText"

local cache                 = axutils.cache
local childFromRight        = axutils.childFromRight
local childMatching         = axutils.childMatching
local childWithDescription  = axutils.childWithDescription

local displayMessage        = dialog.displayMessage

local doUntil               = just.doUntil
local wait                  = just.wait

local ExportDialog = Dialog:subclass("cp.apple.finalcutpro.export.ExportDialog")

function ExportDialog.static.matches(element)
    return element:attributeValue("AXSubrole") == "AXDialog"
        and element:attributeValue("AXModal")
        and childWithDescription(element, "PE Share WindowBackground") ~= nil
end

--- cp.apple.finalcutpro.export.ExportDialogTitleText(parent)
--- Constructor
--- Creates a new Export [Dialog](cp.ui.Dialog.md)
function ExportDialog:initialize(parent)
    Dialog.initialize(self, parent, parent.windowsUI:mutate(function(original)
        return cache(self, "_window", function()
            return childMatching(original(), ExportDialog.matches)
        end, ExportDialog.matches)
    end))
end

-- isDefaultItem(menuItem) -> boolean
-- Function
-- Is an element the default item?
--
-- Parameters
--  * element - The UI of the AXMenuItem to check.
--
-- Returns:
--  * `true` if the element is the default item, otherwise `false`
local function isDefaultItem(element)
    return element and element:attributeValue("AXMenuItemCmdChar") ~= nil
end

-- destinationFormat -> string
-- Constant
-- Destination Format.
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
        local menuItem = fcp.menu:findMenuUI({"File", "Share", destinationSelect})

        --------------------------------------------------------------------------------
        -- No destination selected:
        --------------------------------------------------------------------------------
        if not menuItem then
            local msg = i18n("batchExportNoDestination")
            if not quiet then displayMessage(msg) end
            return self, msg
        end

        --------------------------------------------------------------------------------
        -- Keep trying to press the menu item until we timeout:
        --------------------------------------------------------------------------------
        if not doUntil(function()
            local path = {"File", "Share", destinationSelect}
            local options = {["pressAll"] = true}
            return fcp:selectMenu(path, options)
        end) then
            --------------------------------------------------------------------------------
            -- Unsuccessfully selected the share menu item:
            --------------------------------------------------------------------------------
            local msg = i18n("batchExportDestinationDisabled")
            if not quiet then displayMessage(msg) end
            return self, msg
        else
            --------------------------------------------------------------------------------
            -- Successfully selected the share menu item:
            --------------------------------------------------------------------------------
            local alert = fcp.alert

            local missingMediaString = fcp:string("FFMissingMediaMessageText")
            local missingMedia = missingMediaString and string.gsub(missingMediaString, "%%@", ".*")

            local proxyPlaybackEnabled = fcp:string("FFShareProxyPlaybackEnabledMessageText")

            local missingMediaAndInvalidCaptionsString = fcp:string("FFMissingMediaAndBrokenCaptionsMessageText")
            local missingMediaAndInvalidCaptions = missingMediaAndInvalidCaptionsString and string.gsub(missingMediaAndInvalidCaptionsString, "%%@", ".*")

            local invalidCaptionsString = fcp:string("FFBrokenCaptionsMessageText")
            local invalidCaptions = invalidCaptionsString and string.gsub(invalidCaptionsString, "%%@", ".*")

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

function ExportDialog.lazy.value:cancelButton()
    return Button(self, self.UI:mutate(function(original)
        local ui = original()
        return ui and ui:attributeValue("AXCancelButton")
    end))
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
    self.cancelButton:press()
end

function ExportDialog.lazy.value:defaultButton()
    return Button(self, self.UI:mutate(function(original)
        local ui = original()
        return ui and ui:attributeValue("AXDefaultButton")
    end))
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
    self.defaultButton:press()
end

--- cp.apple.finalcutpro.export.ExportDialog.fileExtension <cp.ui.StaticText>
--- Field
--- The "File Extension" [StaticText](cp.ui.StaticText.md).
function ExportDialog.lazy.value:fileExtension()
    return StaticText(self, self.UI:mutate(function(original)
        return cache(self, "_next", function()
            return childFromRight(original(), 2, StaticText.matches)
        end, StaticText.matches)
    end))
end

--- cp.apple.finalcutpro.export.ExportDialog.saveSheet <SaveSheet>
--- Field
--- The `SaveSheet`.
function ExportDialog.lazy.value:saveSheet()
    return SaveSheet.new(self)
end

return ExportDialog
