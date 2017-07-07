local test				= require("cp.test")
local log				= require("hs.logger").new("testlocalized")
local inspect			= require("hs.inspect")

local bench				= require("cp.bench")

local config			= require("cp.config")
local localized			= require("cp.localized")

local PLUGINS_PATH = config.scriptPath .. "/tests/fcp/plugins"
local EFFECTS_PATH = PLUGINS_PATH .. "/Effects.localized"

function run()
	test("Read Localized Strings", function()
		local result = localized.readLocalizedStrings(EFFECTS_PATH.."/.localized/French.strings", "Effects")
		ok(eq(result, "Effets"))
		
	end)
	
	test("Read Localized Name", function()
		local result = localized.readLocalizedName(PLUGINS_PATH.."/Effects.localized", "Effects", "fr")
		ok(eq(result, "Effets"))
	end)
	
	test("Get Localized Name", function()
		local l, o = localized.getLocalizedName(EFFECTS_PATH, "en")
		ok(eq(l, "Effects"))
		ok(eq(o, "Effects"))
		l, o = localized.getLocalizedName(EFFECTS_PATH, "ja")
		ok(eq(l, "エフェクト"))
		ok(eq(o, "Effects"))
		
		local l, o = localized.getLocalizedName(EFFECTS_PATH.."/Local.localized", "en")
		ok(eq(l, "Local EN"))
		ok(eq(o, "Local"))
	end)
end

return run
