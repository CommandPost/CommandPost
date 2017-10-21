local test		= require("gambiarra")
local log		= require("hs.logger").new("test")

local format, insert	= string.format, table.insert

local passed = 0
local failed = 0
local clock = 0

local messages = nil

local function f(message, ...)
	if not messages then
		messages = {}
	end
	insert(messages, format(message, ...))
end

local function dumpMessages()
	if messages then
		for _,message in ipairs(messages) do
			log.f(message)
		end
	end
end

test(function(event, testfunc, msg)
	if event == 'begin' then
		messages = nil
        -- f(' [START] %s', testfunc)
        passed = 0
        failed = 0
        clock = os.clock()
    elseif event == 'end' then
		-- f('   [END] %s', testfunc)
		if failed > 0 then
			dumpMessages()
			log.f('[RESULT] "%s": Passed: %d; Failed: %d; Time: %.4f\n', testfunc, passed, failed, os.clock() - clock)
		end
    elseif event == 'pass' then
        passed = passed + 1
    elseif event == 'fail' then
        f('  [FAIL] "%s": %s', testfunc, msg)
        failed = failed + 1
    elseif event == 'except' then
		f(' [ERROR] "%s": %s', testfunc, msg)
		failed = failed + 1
    end
end)

return test