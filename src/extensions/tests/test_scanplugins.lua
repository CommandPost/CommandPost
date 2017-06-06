local test				= require("cp.test")
local log				= require("hs.logger").new("testscanplugins")
local inspect			= require("hs.inspect")

local bench				= require("cp.bench")

local config			= require("cp.config")
local scanplugins		= require("cp.apple.finalcutpro.scanplugins")

local PLUGINS_PATH = config.scriptPath .. "/tests/fcp/plugins"
local EFFECTS_PATH = PLUGINS_PATH .. "/Effects.local/Test"

function run()
	test("Get Motion Theme", function()
		local testEffect = EFFECTS_PATH .. "/Test Effect/Test Effect.moef"
		ok(scanplugins.getMotionTheme(testEffect) == nil)
		
		local themedTestEffect = EFFECTS_PATH .. "/Test Theme/Themed Test Effect/Themed Test Effect.moef"
		ok(scanplugins.getMotionTheme(themedTestEffect) == "Test Theme")
	end)
end

return run
