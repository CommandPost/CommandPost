--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                    C L I P B O A R D     H I S T O R Y                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log 									= require("hs.logger").new("clipboardHistory")

local fcp									= require("cp.finalcutpro")
local config								= require("cp.config")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local TOOLS_PRIORITY						= 1000
local OPTIONS_PRIORITY						= 1000

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

	mod._historyMaximumSize 					= 5				-- Maximum Size of Clipboard History
	mod.log										= log

	function mod.isEnabled()
		return config.get("enableClipboardHistory", false)
	end

	function mod.setEnabled(value)
		config.set("enableClipboardHistory", value == true)
		mod.update()
	end

	function mod.toggleEnabled()
		mod.setEnabled(not mod.isEnabled())
	end

	function mod.getHistory()
		if not mod._history then
			mod._history = config.get("clipboardHistory", {})
		end
		return mod._history
	end

	function mod.setHistory(history)
		mod._history = history
		config.set("clipboardHistory", history)
	end

	function mod.clearHistory()
		mod.setHistory({})
	end

	function mod.addHistoryItem(data, label)
		local history = mod.getHistory()
		local item = {data, label}
		-- drop old history items
		while (#(history) >= mod._historyMaximumSize) do
			table.remove(history,1)
		end
		table.insert(history, item)
		mod.setHistory(history)
	end

	function mod.pasteHistoryItem(index)
		local item = mod.getHistory()[index]
		if item then
			--------------------------------------------------------------------------------
			-- Put item back in the clipboard quietly.
			--------------------------------------------------------------------------------
			mod._manager.writeFCPXData(item[1], true)

			--------------------------------------------------------------------------------
			-- Paste in FCPX:
			--------------------------------------------------------------------------------
			fcp:launch()
			if fcp:performShortcut("Paste") then
				return true
			else
				log.w("Failed to trigger the 'Paste' Shortcut.\n\nError occurred in clipboard.history.pasteHistoryItem().")
			end
		end
		return false
	end

	local function watchUpdate(data, name)
		log.df("Clipboard updated. Adding '%s' to history.", name)
		mod.addHistoryItem(data, name)
	end

	function mod.update()
		if mod.isEnabled() then
			if not mod._watcherId then
				mod._watcherId = mod._manager.watch({
					update	= watchUpdate,
				})
			end
		else
			if mod._watcherId then
				mod._manager.unwatch(mod._watcherId)
				mod._watcherId = nil
			end
		end
	end

	function mod.init(manager)
		mod._manager = manager
		mod.update()
		return self
	end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.clipboard.history",
	group			= "finalcutpro",
	dependencies	= {
		["finalcutpro.clipboard.manager"]	= "manager",
		["finalcutpro.menu.clipboard"]		= "menu",
		
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

	--------------------------------------------------------------------------------
	-- Initialise the module:
	--------------------------------------------------------------------------------
	mod.init(deps.manager)

	--------------------------------------------------------------------------------
	-- Add menu items:
	--------------------------------------------------------------------------------
	deps.menu:addMenu(TOOLS_PRIORITY, function() return i18n("localClipboardHistory") end)
		:addItem(OPTIONS_PRIORITY, function()
			return { title = i18n("enableClipboardHistory"),	fn = mod.toggleEnabled, checked = mod.isEnabled()}
		end)
		:addSeparator(2000)
		:addItems(3000, function()
			local historyItems = {}
			if mod.isEnabled() then
				local fcpxRunning = fcp:isRunning()
				local history = mod.getHistory()
				if #history > 0 then
					for i=#history, 1, -1 do
						local item = history[i]
						table.insert(historyItems, {title = item[2], fn = function() mod.pasteHistoryItem(i) end, disabled = not fcpxRunning})
					end
					table.insert(historyItems, { title = "-" })
					table.insert(historyItems, { title = i18n("clearClipboardHistory"), fn = mod.clearHistory })
				else
					table.insert(historyItems, { title = i18n("emptyClipboardHistory"), disabled = true })
				end
			end
			return historyItems
		end)

	return mod
end

return plugin