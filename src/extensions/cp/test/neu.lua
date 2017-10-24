local timer			= require("hs.timer")
local inspect		= require("hs.inspect")
local format		= string.format

local verbose = false

local function printf(msg, ...)
	print(format(msg, ...))
end

local DEFAULT_HANDLER = {
	start 	= function(case) if verbose then printf("[START] %s", case.name) end end,
	stop	= function(case) if verbose then printf(" [STOP] %s", case.name) end end,
	pass	= function(case) if verbose then printf(" [PASS] %s", case.name) end end,
	fail	= function(case, msg) print(); printf(" [FAIL] %s: %s", case.name, msg) end,
	error	= function(case, msg) print(); printf("[ERROR] %s: %s", case.name, msg) end,
	summary	= function(case) print(); printf("[RESULT] %s: passed: %s; failed: %s; errors: %s; time: %.4fs", case.name, case.result.passes, case.result.failures, case.result.errors, os.clock() - case.result.clock) end,
}

local handler = DEFAULT_HANDLER

local function notequal(a, b)
	return false, string.format("%s ~= %s", inspect(a), inspect(b))
end

local function deepeq(a, b)
	-- Different types: false
	if type(a) ~= type(b) then return notequal(type(a), type(b)) end
	-- Functions
	if type(a) == 'function' then
		return string.dump(a) == string.dump(b) or notequal(a, b)
	end
	-- Primitives and equal pointers
	if a == b then return true end
	-- Only equal tables could have passed previous tests
	if type(a) ~= 'table' then return notequal(a, b) end
	-- Compare tables field by field
	for k,v in pairs(a) do
		if b[k] == nil or not deepeq(v, b[k]) then return notequal(a, b) end
	end
	for k,v in pairs(b) do
		if a[k] == nil or not deepeq(v, a[k]) then return notequal(a, b) end
	end
	return true
end

local test = {}
test.mt = {}
test.mt.__index = test.mt

function test.mt:__call(...)
	return self:run(...)
end

function test.mt:__tostring()
	return "test: " .. self.name
end

function test.mt:run(quiet)
	self._autorunning = false
	self.result = {
		passes = 0,
		failures = 0,
		errors = 0,
		clock = os.clock(),
	}

	local old = {
		case = test.case,
		ok = _G.ok,
		eq = _G.eq,
	}

	local oldCase = test.case
	test.case = function(name, ...)
		local case = old.case(self.name .. " > " .. name, ...)
		local caseResult = case:run(true).result
		self.result.passes		= self.result.passes + caseResult.passes
		self.result.failures	= self.result.failures + caseResult.failures
		self.result.errors		= self.result.errors + caseResult.errors
	end

	_ENV.ok = function(cond, ...)
		local msg = ""
		for n=1,select('#',...) do
			local m = select(n,...)
			if m then
				msg = msg .. (msg:len() > 0 and " " or "") .. tostring(m)
			end
		end
		msg = "["..debug.getinfo(2, 'S').short_src..":"..debug.getinfo(2, 'l').currentline.."] " .. msg
		if cond then
			if handler.pass then
				handler.pass(self, msg)
			end
			self.result.passes = self.result.passes + 1
		else
			if handler.fail then
				handler.fail(self, msg)
			end
			self.result.passes = self.result.passes + 1
		end
	end
	_ENV.eq = deepeq

	-- run the test
	if handler.start then handler.start(self) end
	local ok, err = xpcall(function() self.executeFn(restore) end, debug.traceback)
	if not ok then
		if handler.error then
			handler.error(self, err)
		end
		self.result.errors = self.result.errors + 1
	end

	if (not quiet or verbose) and handler.summary then
		handler.summary(self)
	end

	test.case = old.case
	_G.eq = old.eq
	_G.ok = old.ok

	return self
end

function test.mt:autorun()
	self._autorunning = true
	timer.doAfter(0.01, function()
		if self._autorunning then
			self:run()
		end
	end)
end

function test.case(name, executeFn)
	if name == nil or #name == 0 then
		error "Please provide a name"
	end

	local o = {
		name = name,
		executeFn = executeFn,
	}
	setmetatable(o, test.mt)
	o:autorun()
	return o
end

function test.config(newHandler, isVerbose)
	if newHandler then
		self.handler(newHandler)
	end
	if verbose ~= nil then
		verbose = isVerbose
	end
end

function test.handler(newHandler)
	handler = newHandler or DEFAULT_HANDLER
end

function test.is(value)
	return type(value) == "table" and getmetatable(value) == test.mt
end

return setmetatable(test, {
	__call = function(_,...) return test.case(...) end,
})