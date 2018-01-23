--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                      K E Y W O R D S     P L U G I N                       --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.browser.keywords ===
---
--- Browser Keywords

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("addnote")

local ax 								= require("hs._asm.axuielement")
local eventtap                          = require("hs.eventtap")

local dialog 							= require("cp.dialog")
local fcp								= require("cp.apple.finalcutpro")
local config							= require("cp.config")
local tools 							= require("cp.tools")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

function mod.save(preset)

    --------------------------------------------------------------------------------
    -- Open the Keyword Editor:
    --------------------------------------------------------------------------------
    local keywordEditor = fcp:keywordEditor()
    keywordEditor:show()
    if not keywordEditor:isShowing() then
        dialog.displayMessage("The Keyword Editor could not be opened.")
        return nil
    end

    --------------------------------------------------------------------------------
    -- Open the Keyboard Shortcuts dropdown:
    --------------------------------------------------------------------------------
    local keyboardShortcuts = keywordEditor:keyboardShortcuts()
    keyboardShortcuts:show()
    if not keyboardShortcuts:isShowing() then
        dialog.displayMessage("The Keyword Editor's Keyboard Shortcuts dropdown could not be opened.")
        return nil
    end

	--------------------------------------------------------------------------------
	-- Save Values to Settings:
	--------------------------------------------------------------------------------
	local savedKeywords = config.get("savedKeywords", {})
	if not savedKeywords[preset] then
	    savedKeywords[preset] = {}
	end
	for i=1, 9 do
	    savedKeywords[preset][i] = keyboardShortcuts:keyword(i)
	end
	config.set("savedKeywords", savedKeywords)

	--------------------------------------------------------------------------------
	-- Saved:
	--------------------------------------------------------------------------------
	dialog.displayNotification(i18n("keywordPresetsSaved") .. " " .. tostring(preset))

end

function mod.restore(preset)

	--------------------------------------------------------------------------------
	-- Get Values from Settings:
	--------------------------------------------------------------------------------
	local savedKeywords = config.get("savedKeywords")

	if savedKeywords == nil then
		dialog.displayMessage(i18n("noKeywordPresetsError"))
		return "Fail"
	end

	if savedKeywords[preset] == nil then
		dialog.displayMessage(i18n("noKeywordPresetError"))
		return "Fail"
	end

    --------------------------------------------------------------------------------
    -- Open the Keyword Editor:
    --------------------------------------------------------------------------------
    local keywordEditor = fcp:keywordEditor()
    keywordEditor:show()
    if not keywordEditor:isShowing() then
        dialog.displayMessage("The Keyword Editor could not be opened.")
        return nil
    end

    --------------------------------------------------------------------------------
    -- Open the Keyboard Shortcuts dropdown:
    --------------------------------------------------------------------------------
    local keyboardShortcuts = keywordEditor:keyboardShortcuts()
    keyboardShortcuts:show()
    if not keyboardShortcuts:isShowing() then
        dialog.displayMessage("The Keyword Editor's Keyboard Shortcuts dropdown could not be opened.")
        return nil
    end

	--------------------------------------------------------------------------------
	-- Restore Values to Keyword Editor:
	--------------------------------------------------------------------------------
	for i=1, 9 do
		keyboardShortcuts:keyword(i, savedKeywords[preset][i])
	end

	--------------------------------------------------------------------------------
	-- Successfully Restored:
	--------------------------------------------------------------------------------
	dialog.displayNotification(i18n("keywordPresetsRestored") .. " " .. tostring(preset))

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.browser.keywords",
	group			= "finalcutpro",
	dependencies	= {
		["finalcutpro.commands"]	= "fcpxCmds",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

	for i=1, 9 do
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