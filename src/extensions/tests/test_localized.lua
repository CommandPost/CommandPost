local test				= require("cp.test")
local log				= require("hs.logger").new("testlocalized")
local inspect			= require("hs.inspect")

local bench				= require("cp.bench")

local config			= require("cp.config")
local localized			= require("cp.localized")

local PLUGINS_PATH = config.scriptPath .. "/tests/fcp/plugins"
local EFFECTS_PATH = PLUGINS_PATH .. "/Effects.local"

function run()
	test("Read Localized Strings", function()
		local result = localized.readLocalizedStrings(EFFECTS_PATH .. "/.localized/German.strings", "Effects")
		log.df("result: %s", result)
		ok(result == "Effekte")
	end)
	
	test("Get Localized Name", function()
		ok(localized.getLocalizedName(EFFECTS_PATH, "en") == "Effects")
		log.df("ja: %s", localized.getLocalizedName(EFFECTS_PATH, "ja"))
		ok(localized.getLocalizedName(EFFECTS_PATH, "ja") == "")
	end)
end

return run
