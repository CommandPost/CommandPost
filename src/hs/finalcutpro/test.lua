---
--- Tests hs.finalcutpro
---

local fcpx 			= require("hs.finalcutpro")
local inspect 		= require("hs.inspect")
local log 			= require("hs.logger").new("fcptest")

local function test()
	local menuBar = fcpx.findMenuBar()
	log.d("MenuBar: \n"..inspect(menuBar:buildTree()))
end

return test