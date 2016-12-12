--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                          J U S T     L I B R A R Y                         --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Module created by David Peterson (https://github.com/randomeizer).
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- This module provides functions to help with performing tasks which may be
-- delayed, up to a finite number of loops.
--
--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------

local just = {}

local timer 					= require("hs.timer")

--- hs.fcpxhacks.modules.just.doWhile(actionFn, period, loops) -> UI
--- Function
--- Performs an 'action' function, looping while the result of the function evaluates to 'true'.
--- It will halt after 'loops' repetitions if the result is never 'false'.
---
--- Parameters:
---  * actionFn	- a fuction which is called on each loop. It should return a 'truthy' value.
---  * period	- (optional) the number of microseconds between each loop. Defaults to 10 microseconds.
---  * loops	- (optional) the number of loops to perform before giving up. Defaults to 100.
---
--- Returns:
---  * The last return value of the action function.
---
function just.doWhile(actionFn, period, loops)
	loops = loops or 100
	period = period or 10
	
	local count = 0
	local result = true
	while count <= loops and result do
		if count > 0 then
			timer.usleep(period)
		end
		result = actionFn()
		count = count + 1
	end
	return result
end

--- hs.fcpxhacks.modules.just.doUntil(actionFn, period, loops) -> UI
--- Function
--- Performs an 'action' function, looping until the result of the function evaluates to 'true'.
--- It will halt after 'loops' repetitions if the result is always 'false'.
---
--- Parameters:
---  * actionFn	- a fuction which is called on each loop. It should return a 'truthy' value.
---  * period	- (optional) the number of microseconds between each loop. Defaults to 1000 microseconds.
---  * loops	- (optional) the number of loops to perform before giving up. Defaults to 1000.
---
--- Returns:
---  * The last return value of the action function.
---
function just.doUntil(actionFn, period, loops)
	loops = loops or 1000
	period = period or 1000
	local count = 0
	local result = nil
	while count <= loops and not result do
		if count > 0 then
			timer.usleep(period)
		end
		result = actionFn()
		count = count + 1
	end
	return result
end

--- hs.fcpxhacks.modules.just.wait(periodInMicrosecs) -> UI
--- Function
--- Pauses the application for the specified number of microseconds.
---
--- Parameters:
---  * periodInMicrosecs - the number of microseconds to pause for.
---
--- Returns:
---  * N/A
---
function just.wait(periodInMicrosecs)
	timer.usleep(periodInMicrosecs)
end

return just