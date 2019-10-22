--- === plugins.finalcutpro.browser.keywords ===
---
--- Browser Keywords Presets.

local require               = require

local pasteboard            = require "hs.pasteboard"

local config                = require "cp.config"
local dialog                = require "cp.dialog"
local fcp                   = require "cp.apple.finalcutpro"
local i18n                  = require "cp.i18n"
local tools                 = require "cp.tools"

local displayErrorMessage   = dialog.displayErrorMessage
local displayNotification   = dialog.displayNotification
local playErrorSound        = tools.playErrorSound

local mod = {}

--- plugins.finalcutpro.browser.keywords.NUMBER_OF_PRESETS -> number
--- Constant
--- The number of presets available.
mod.NUMBER_OF_PRESETS = 9

--- plugins.finalcutpro.browser.keywords.NUMBER_OF_SHORTCUTS -> number
--- Constant
--- The number of Keyword Keyboard shortcuts available.
mod.NUMBER_OF_SHORTCUTS = 9

--- plugins.finalcutpro.browser.keywords.save(preset) -> none
--- Function
--- Saves a Keyword preset.
---
--- Parameters:
---  * preset - A preset number between 1 and the value of `plugins.finalcutpro.browser.keywords.NUMBER_OF_PRESETS`.
---
--- Returns:
---  * None
function mod.save(preset)
    --------------------------------------------------------------------------------
    -- Get Keyword Shortcuts from Preferences & Save Them to Preset Group:
    --------------------------------------------------------------------------------
    local keywordGroups = fcp.preferences.FFKeywordGroups
    if keywordGroups and #keywordGroups == mod.NUMBER_OF_SHORTCUTS then
        local savedKeywords = {}
        for i=1, mod.NUMBER_OF_PRESETS do
            table.insert(savedKeywords, keywordGroups[i])
        end
        config.set("savedKeywords" .. tostring(preset), savedKeywords)

        --------------------------------------------------------------------------------
        -- Display Notification:
        --------------------------------------------------------------------------------
        displayNotification(i18n("keywordPresetsSaved") .. " " .. tostring(preset))
    else
        displayErrorMessage(i18n("noKeyboardShortcutsInKeywordEditor"))
    end

end

--- plugins.finalcutpro.browser.keywords.restore(preset) -> none
--- Function
--- Restores a Keyword preset.
---
--- Parameters:
---  * preset - A preset number between 1 and the value of `plugins.finalcutpro.browser.keywords.NUMBER_OF_PRESETS`.
---
--- Returns:
---  * None
function mod.restore(preset)
    --------------------------------------------------------------------------------
    -- Get Values from Settings:
    --------------------------------------------------------------------------------
    local savedKeywords = config.get("savedKeywords" .. tostring(preset))
    if type(savedKeywords) ~= "table" or #savedKeywords == 0 then
        dialog.displayMessage(i18n("noKeywordPresetsError"))
        return false
    end

    --------------------------------------------------------------------------------
    -- Open the Keyword Editor:
    --------------------------------------------------------------------------------
    local keywordEditor = fcp:keywordEditor()
    keywordEditor:show()
    if not keywordEditor:isShowing() then
        dialog.displayMessage(i18n("keywordEditorNotOpened"))
        return nil
    end

    --------------------------------------------------------------------------------
    -- Open the Keyboard Shortcuts section:
    --------------------------------------------------------------------------------
    local keyboardShortcuts = keywordEditor:keyboardShortcuts()
    keyboardShortcuts:show()
    if not keyboardShortcuts:isShowing() then
        dialog.displayMessage(i18n("keywordKeyboardShortcutsNotOpened"))
        return nil
    end

    --------------------------------------------------------------------------------
    -- Restore Values to Keyword Editor:
    --------------------------------------------------------------------------------
    for i=1, mod.NUMBER_OF_SHORTCUTS do
        keyboardShortcuts:keyword(i, savedKeywords[i])
    end

    --------------------------------------------------------------------------------
    -- Display Notification:
    --------------------------------------------------------------------------------
    displayNotification(i18n("keywordPresetsRestored") .. " " .. tostring(preset))
end

local plugin = {
    id              = "finalcutpro.browser.keywords",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]    = "fcpxCmds",
    }
}

function plugin.init(deps)
    local fcpxCmds = deps.fcpxCmds

    --------------------------------------------------------------------------------
    -- Save/Restore Keyword Presets:
    --------------------------------------------------------------------------------
    for i=1, mod.NUMBER_OF_PRESETS do
        fcpxCmds
            :add("cpRestoreKeywordPreset" .. tools.numberToWord(i))
            :titled(i18n("cpRestoreKeywordPreset_customTitle", {count = i}))
            :whenActivated(function() mod.restore(i) end)

        fcpxCmds
            :add("cpSaveKeywordPreset" .. tools.numberToWord(i))
            :titled(i18n("cpSaveKeywordPreset_customTitle", {count = i}))
            :whenActivated(function() mod.save(i) end)
    end

    --------------------------------------------------------------------------------
    -- Apply Keyword from Pasteboard:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("applyKeywordFromPasteboard")
        :titled(i18n("applyKeywordFromPasteboard"))
        :whenActivated(function()
            local value = pasteboard.readString()
            if value then
                local keywordEditor = fcp:keywordEditor()
                local wasShowing = keywordEditor:isShowing()
                keywordEditor:show()
                local keywords = keywordEditor:keyword() or {}
                table.insert(keywords, value)
                keywordEditor:keyword(keywords)
                if not wasShowing then
                    keywordEditor:hide()
                end
            end
        end)

    return mod
end

return plugin
