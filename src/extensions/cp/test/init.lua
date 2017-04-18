local test = require("gambiarra")

local log		= require("hs.logger").new("test")

local passed = 0
local failed = 0
local clock = 0

test(function(event, testfunc, msg)
    if event == 'begin' then
        log.f(' [START] %s', testfunc)
        passed = 0
        failed = 0
        clock = os.clock()
    elseif event == 'end' then
        log.f('   [END] %s', testfunc)
		log.f("[RESULT] Passed: %d; Failed: %d; Time: %.4f\n", passed, failed, os.clock() - clock)
    elseif event == 'pass' then
        passed = passed + 1
    elseif event == 'fail' then
        log.f('  [FAIL] %s', msg)
        failed = failed + 1
    elseif event == 'except' then
        log.f(' [ERROR] "%s": %s', testfunc, msg)
    end
end)

return test