--- Tests the plist library

local log = require("hs.logger").new("plist.test")
local plister = require("hs.plist")
local inspect = require("hs.inspect")
local fcp = require("hs.finalcutpro")

local function runTest()
	local plistFile = "hs/fcpxhacks/plist/10-3/old/NSProCommandGroups.plist"
	--local plistFile = "hs/plist/example.commandset"
	--local plistFile = fcp.getActiveCommandSetPath()

	log.d("TEST: Reading "..inspect(plistFile))

	local nsProCmds = plister.fileToTable(plistFile)

	log.d("TEST: "..inspect(nsProCmds))
	
	
end

return runTest	