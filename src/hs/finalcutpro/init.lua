--- === hs.finalcutpro ===
---
--- Controls for Final Cut Pro
---
--- Thrown together by:
---   Chris Hocking (https://github.com/latenitefilms)
---

local mod = {}

local plist = require("hs.plist")

local preferencesPlistPath = "~/Library/Preferences/com.apple.FinalCut.plist"

function mod.getPreferencesAsTable()
	local preferencesTable = plist.binaryFileToTable(preferencesPlistPath) or nil
	return preferencesTable
end

function mod.getPreference(value)
	local result = nil
	local preferencesTable = plist.binaryFileToTable(preferencesPlistPath) or nil

	if preferencesTable ~= nil then
		result = preferencesTable[value]
	end

	return result
end

function mod.getActiveCommandSetPath()
	local result = mod.getPreference("Active Command Set") or nil
	return result
end

function mod.getActiveCommandSetAsTable()
	local result = nil

	local activeCommandSetPath = mod.getActiveCommandSetPath()

	if activeCommandSetPath ~= nil then
		if fs.attributes(activeCommandSetPath) ~= nil then
			result = plist.xmlFileToTable(activeCommandSetPath) or nil
		end
	end

	return result
end


return mod