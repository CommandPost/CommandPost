--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                      K E Y W O R D S     P L U G I N                       --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.browser.keywords ===
---
--- Browser Keywords Presets.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                               = require("hs.logger").new("keywords")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local dialog                            = require("cp.dialog")
local fcp                               = require("cp.apple.finalcutpro")
local config                            = require("cp.config")
local tools                             = require("cp.tools")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.browser.keywords.NUMBER_OF_PRESETS -> number
--- Constant
--- The number of presets available.
mod.NUMBER_OF_PRESETS = 9

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
    -- Save Values to Settings:
    --------------------------------------------------------------------------------
    local savedKeywords = {}
    for i=1, mod.NUMBER_OF_PRESETS do
        local keywords = keyboardShortcuts:keyword(i) or {}
        table.insert(savedKeywords, keywords)
    end
    config.set("savedKeywords" .. tostring(preset), savedKeywords)

    --------------------------------------------------------------------------------
    -- Display Notification:
    --------------------------------------------------------------------------------
    dialog.displayNotification(i18n("keywordPresetsSaved") .. " " .. tostring(preset))

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
        dialog.displayMessage(i18("keywordKeyboardShortcutsNotOpened"))
        return nil
    end

    --------------------------------------------------------------------------------
    -- Restore Values to Keyword Editor:
    --------------------------------------------------------------------------------
    for i=1, mod.NUMBER_OF_PRESETS do
        keyboardShortcuts:keyword(i, savedKeywords[i])
    end

    --------------------------------------------------------------------------------
    -- Display Notification:
    --------------------------------------------------------------------------------
    dialog.displayNotification(i18n("keywordPresetsRestored") .. " " .. tostring(preset))

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.browser.keywords",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]    = "fcpxCmds",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    for i=1, mod.NUMBER_OF_PRESETS do
        deps.fcpxCmds:add("cpRestoreKeywordPreset" .. tools.numberToWord(i))
            :activatedBy():ctrl():option():cmd(tostring(i))
            :titled(i18n("cpRestoreKeywordPreset_customTitle", {count = i}))
            :whenActivated(function() mod.restore(i) end)

        deps.fcpxCmds:add("cpSaveKeywordPreset" .. tools.numberToWord(i))
            :activatedBy():ctrl():option():shift():cmd(tostring(i))
            :titled(i18n("cpSaveKeywordPreset_customTitle", {count = i}))
            :whenActivated(function() mod.save(i) end)
    end
    return mod
end

return plugin