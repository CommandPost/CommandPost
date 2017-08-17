local test				= require("cp.test")
local log				= require("hs.logger").new("t_plugins")
local inspect			= require("hs.inspect")

local bench				= require("cp.bench")

local config			= require("cp.config")
local plugins		= require("cp.apple.finalcutpro.plugins")

local PLUGINS_PATH = config.scriptPath .. "/tests/fcp/plugins"
local EFFECTS_PATH = PLUGINS_PATH .. "/Effects.localized"

function run()
	local app = {
		getPath = function() return "/Applications/Final Cut Pro.app" end
	}
	
	test("Get Motion Theme", function()
		local testEffect = EFFECTS_PATH .. "/Test/Test Effect/Test Effect.moef"
		ok(eq(plugins.getMotionTheme(testEffect), nil))
		
		local themedTestEffect = EFFECTS_PATH .. "/Test/Test Theme/Themed Test Effect/Themed Test Effect.moef"
		ok(eq(plugins.getMotionTheme(themedTestEffect), "Test Theme"))
	end)
	
	test("Scan Theme", function()
		local testTheme = EFFECTS_PATH .. "/Test/Test Theme"
		local scanner = plugins.new(app)
		
		scanner:scanPluginThemeDirectory(testTheme, "Effect", {"moef"}, "Test", "Test Theme", "en")
		local plugin = {en = {Effect = {
			{
				path = testTheme .. "/Themed Test Effect",
				type = "Effect",
				category = "Test",
				theme = "Test Theme",
				name = "Themed Test Effect",
				language = "en",
			}
		}}}
		ok(eq(scanner._plugins, plugin))
	end)
	
	test("Scan Category", function()
		local testCategory = EFFECTS_PATH .. "/Test"
		local scanner = plugins.new(app)
		
		scanner:scanPluginCategoryDirectory(testCategory, "Effect", {"moef"}, "Test", "en")
		local plugin = {en = {Effect = {
			{
				path = testCategory .. "/Test Effect",
				type = "Effect",
				category = "Test",
				theme = nil,
				name = "Test Effect",
				language = "en",
			},
			{
				path = testCategory .. "/Test Theme/Themed Test Effect",
				type = "Effect",
				category = "Test",
				theme = "Test Theme",
				name = "Themed Test Effect",
				language = "en",
			},
		}}}
		ok(eq(scanner._plugins, plugin))
	end)
	
	test("Scan Effects", function()
		local path = EFFECTS_PATH
		local scanner = plugins.new(app)
		
		scanner:scanPluginTypeDirectory(path, "Effect", {"moef"}, "en")
		local plugin = {en = {Effect = {
			{
				path = path .. "/Local.localized/Local Effect.localized",
				type = "Effect",
				category = "Local EN",
				theme = nil,
				name = "Local Effect EN",
				language = "en",
			},
			{
				path = path .. "/Test/Test Effect",
				type = "Effect",
				category = "Test",
				theme = nil,
				name = "Test Effect",
				language = "en",
			},
			{
				path = path .. "/Test/Test Theme/Themed Test Effect",
				type = "Effect",
				category = "Test",
				theme = "Test Theme",
				name = "Themed Test Effect",
				language = "en",
			},
		}}}
		ok(eq(scanner._plugins, plugin))
	end)
	
end

return run
