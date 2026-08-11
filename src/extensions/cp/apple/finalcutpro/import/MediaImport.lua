--- === cp.apple.finalcutpro.import.MediaImport ===
---
--- Media Import

local require = require

local just                          = require "cp.just"
local strings                       = require "cp.apple.finalcutpro.strings"

local axutils                       = require "cp.ui.axutils"
local Button                        = require "cp.ui.Button"
local Dialog                        = require "cp.ui.Dialog"
local GoToPrompt                    = require "cp.apple.finalcutpro.export.GoToPrompt"

local cache                         = axutils.cache
local childWith                     = axutils.childWith

local GO_TO_PROMPT_TIMEOUT          = 5
local IMPORT_WINDOW_TIMEOUT         = 5
local IMPORT_BUTTON_TIMEOUT         = 5
local IMPORT_START_TIMEOUT          = 15

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

--- cp.apple.finalcutpro.import.MediaImport:setPath(path) -> boolean, string
--- Method
--- Uses the "Go to Folder" prompt to select a file or folder path in the Media Import window.
---
--- Parameters:
---  * path - The file or folder path.
---
--- Returns:
---  * `true` if the path was selected.
---  * An error message when the path could not be selected.
function MediaImport:setPath(path)
    if not self:isShowing() then
        return false, "Media Import window is not showing"
    end

    local prompt = self.goToPrompt
    prompt:show()
    if not just.doUntil(function() return prompt:isShowing() end, GO_TO_PROMPT_TIMEOUT) then
        return false, "Go to Folder prompt did not appear"
    end

    prompt:value(path)
    if prompt:isShowing() then
        local _, success = prompt.go:press()
        if not success then
            return false, "Unable to confirm Go to Folder prompt"
        end
    end

    if not just.doUntil(function() return not prompt:isShowing() end, GO_TO_PROMPT_TIMEOUT) then
        return false, "Go to Folder prompt did not close"
    end

    return true
end

--- cp.apple.finalcutpro.import.MediaImport:importPath(path) -> boolean, string
--- Method
--- Opens the Media Import window, selects the supplied path, and presses "Import All".
---
--- Parameters:
---  * path - The file or folder path to import.
---
--- Returns:
---  * `true` if the import started successfully.
---  * An error message when the import could not be started.
function MediaImport:importPath(path)
    self:show()
    if not just.doUntil(function() return self:isShowing() end, IMPORT_WINDOW_TIMEOUT) then
        return false, "Unable to open Media Import window"
    end

    local pathSelected, message = self:setPath(path)
    if not pathSelected then
        return false, message
    end

    local importAll = self.importAll
    local importAllUI = just.doUntil(function()
        local ui = importAll:UI()
        if ui and ui:attributeValue("AXEnabled") == true then
            return ui
        end
        return false
    end, IMPORT_BUTTON_TIMEOUT)
    if not importAllUI then
        return false, "Import All button is unavailable for the selected path"
    end

    local _, success = importAll:press()
    if not success then
        return false, "Unable to press Import All"
    end

    local importStarted = just.doUntil(function()
        return not self:isShowing() or self.stopImport:UI() ~= nil
    end, IMPORT_START_TIMEOUT)
    if not importStarted then
        return false, "Import did not appear to start"
    end

    return true
end

--- cp.apple.finalcutpro.import.MediaImport.goToPrompt <GoToPrompt>
--- Field
--- The Go To Prompt object for the Media Import window.
function MediaImport.lazy.value:goToPrompt()
    return GoToPrompt(self)
end

return MediaImport
