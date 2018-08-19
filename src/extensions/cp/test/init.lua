--- === cp.test ===
---
--- CommandPost Test Scripts.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require		= require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
--local log			= require("hs.logger").new("test")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local inspect		= require("hs.inspect")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local suites = {}

local format = string.format
local insert, remove = table.insert, table.remove
local unpack = _G.unpack or table.unpack

local function topSuite()
    return #suites > 0 and suites[#suites] or nil
end

local function pushSuite(suite)
    insert(suites, suite)
end

local function popSuite()
    return remove(suites)
end

local function addResult(newResult)
    local top = topSuite()
    if top then
        return top:addResult(newResult)
    end
    return false
end

local verbose = false

local function printf(msg, ...)
    print(format(msg, ...))
end

local function fullName(child)
    local parentNames = ""
    for _,parent in ipairs(suites) do
        parentNames = parentNames .. parent.name .. " > "
    end
    return parentNames .. child.name
end

local DEFAULT_HANDLER = {
    start 	= function(case) if verbose then print(); printf("[START] %s", fullName(case)) end end,
    stop	= function(case) if verbose then printf(" [STOP] %s", fullName(case)) end end,
    pass	= function(case, msg) if verbose then printf(" [PASS] %s: %s", fullName(case), msg) end end,
    fail	= function(case, msg) print(); printf(" [FAIL] %s: %s", fullName(case), msg) end,
    error	= function(case, msg) print(); printf("[ERROR] %s: %s", fullName(case), msg) end,
    filter	= function(case, msg) print(); printf("[FILTER] %s: %s", fullName(case), msg) end,
    summary	= function(case) print(); printf("[RESULT] %s: %s", fullName(case), case.result) end,
}

local handler = DEFAULT_HANDLER

local function notequal(a, b, msg)
    return false, format("%s%s ~= %s", (msg and msg ..": " or ""), inspect(a), inspect(b))
end

local function deepeq(a, b, msg)
    -- Different types: false
    if type(a) ~= type(b) then return notequal(type(a), type(b), msg) end
    -- Functions
    if type(a) == 'function' then
        return string.dump(a) == string.dump(b) or notequal(a, b, msg)
    end
    -- Primitives and equal pointers
    if a == b then return true end
    -- Only equal tables could have passed previous tests
    if type(a) ~= 'table' then return notequal(a, b, msg) end
    -- Compare tables field by field
    for k,v in pairs(a) do
        if b[k] == nil or not deepeq(v, b[k]) then
            -- check for special `n` key for table length
            if k ~= "n" or b.n ~= nil or a.n ~= #b then
                return notequal(a, b, msg)
            end
        end
    end
    for k,v in pairs(b) do
        if a[k] == nil or not deepeq(v, a[k]) then
            -- check for special `n` key for table length
            if k ~= "n" or a.n ~= nil or b.n ~= #a then
                return notequal(a, b, msg)
            end
        end
    end
    return true
end

local function deepneq(a, b, msg)
    local ok, _ = deepeq(a, b)
    if ok then
        return false, format("%s%s == %s", (msg and msg ..": " or ""), inspect(a), inspect(b))
    else
        return true
    end
end

-- Compatibility for Lua 5.1 and Lua 5.2
local function args(...)
    return {n=select('#', ...), ...}
end

local function spy(f)
    local s = {}
    setmetatable(s, {__call = function(ss, ...)
        ss.called = ss.called or {}
        local a = args(...)
        table.insert(ss.called, {...})
        if f then
            local r
            r = args(xpcall(function() f(unpack(a, 1, a.n)) end, debug.traceback))
            if not r[1] then
                s.errors = s.errors or {}
                s.errors[#s.called] = r[2]
            else
                return unpack(r, 2, r.n)
            end
        end
    end})
    return s
end

local test = {}
test.case = {}
test.suite = {}
test.result = {}

test.case.mt = {}
test.case.mt.__index = test.case.mt

test.suite.mt = {}
test.suite.mt.__index = test.suite.mt

test.result.mt = {}
test.result.mt.__index = test.result.mt

test.okDepth = 1

function test.incOkDepth(amount)
    amount = amount or 1
    test.okDepth = test.okDepth + amount
end

function test.decOkDepth(amount)
    amount = amount or 1
    test.okDepth = test.okDepth - amount
end

function test.result.new()
    local o = {
        passes = 0,
        failures = 0,
        errors = 0,
        time = nil,
    }

    return setmetatable(o, test.result.mt)
end

function test.result.mt:start()
    self.start = os.clock()
    self.time = nil
end

function test.result.mt:stop()
    self.stop = os.clock()
    self.time = self.stop - self.start
end

function test.result.mt:add(otherResult)
    self.passes = self.passes + otherResult.passes
    self.failures = self.failures + otherResult.failures
    self.errors = self.errors + otherResult.errors
end

function test.result.mt:__tostring()
    return format("passed: %s; failed: %s; errors: %s; time: %.4fs", self.passes, self.failures, self.errors, self.time or 0)
end

local function newCase(name, executeFn)
    if name == nil or #name == 0 then
        error "Please provide a name"
    end
    if executeFn == nil or type(executeFn) ~= "function" then
        error "Please provide a function to execute the test."
    end

    local o = {
        name		= name,
        executeFn	= executeFn,
    }
    setmetatable(o, test.case.mt)

    return o
end

-- disables 'test.case.new' when already running inside a test case.
local function noCase(name, _)
    error(format("Use a suite to group multiple test cases: %s", name))
end

function test.case.mt:__call(...)
    return self:run(...)
end

function test.case.mt:__tostring()
    return "test: " .. self.name
end

function test.case.mt:run()
    self.result = test.result.new()
    local result = self.result

    -- store current values
    local old = {
        ok = _G.ok,
        eq = _G.eq,
        spy = _G.spy,
    }

    _ENV.ok = function(cond, ...)
        local msg = ""
        for n=1,select('#',...) do
            local m = select(n,...)
            if m then
                msg = msg .. (msg:len() > 0 and " " or "") .. tostring(m)
            end
        end
        local depth = 1 + test.okDepth
        msg = "["..debug.getinfo(depth, 'S').short_src..":"..debug.getinfo(depth, 'l').currentline.."] " .. msg
        if cond then
            if handler.pass then
                handler.pass(self, msg)
            end
            result.passes = result.passes + 1
        else
            if handler.fail then
                handler.fail(self, msg)
            end
            result.failures = result.failures + 1
        end
    end
    _ENV.eq = deepeq
    _ENV.neq = deepneq
    _ENV.spy = spy
    -- prevent internal 'test' creations.
    test.new = noCase

    -- run the test
    if handler.start then handler.start(self) end
    result:start()
    local ok, err = xpcall(function() self.executeFn() end, debug.traceback)
    result:stop()

    if not ok then
        if handler.error then
            handler.error(self, err)
        end
        result.errors = result.errors + 1
    end

    -- only output the summary if there is no parent suite, or if 'verbose' is enabled.
    if (not addResult(result) or verbose) and handler.summary then
        handler.summary(self)
    end

    -- reset internal changes
    _G.eq = old.eq
    _G.ok = old.ok
    _G.spy = old.spy
    test.new = newCase

    return self
end

test.new = newCase

function test.suite.new(name, ...)
    if name == nil or #name == 0 then
        error "Please provide a name"
    end

    local o = {
        name = name,
        tests = {},
    }

    setmetatable(o, test.suite.mt)

    -- add any initial tests.
    o:with(...)

    return o
end

function test.suite.is(thing)
    return thing ~= nil and getmetatable(thing) == test.suite.mt
end

function test.suite.current()
    return topSuite()
end

setmetatable(test.suite, {
    __call = function(_,...)
        return test.suite.new(...)
    end,
})

function test.suite.mt:with(...)
    for i = 1,select("#", ...) do
        local t = select(i, ...)
        local tt = type(t)
        if tt == "string" then -- require it
            t = require(t)
            tt = type(t)
        end

        if test.case.is(t) or test.suite.is(t) then
            insert(self.tests, t)
        elseif type(t) == "table" and #t > 0 then
            for _,x in ipairs(t) do
                insert(self.tests, x)
            end
        else
            error(format("Unsupported test type: %s", tt))
        end
    end
    return self
end

local function matchesFilter(t, i, count, filter)
    if filter == nil or filter == true then
        return true
    end

    local ft = type(filter)
    local result = false

    if ft == "string" then
        result = string.find(t.name, filter)
    elseif ft == "number" then
        if filter < 0 then
            result = i == count+1+filter
        else
            result = i == filter
        end
    elseif ft == "function" then
        result = filter(t.name)
    else
        error(format("Unsupported filter type: %s", ft))
    end

    result = result ~= nil and result ~= false

    if result and handler.filter then
        handler.filter(t, "Running...")
    end

    return result
end

-- this function will run before each test is executed.
function test.suite.mt:beforeEach(beforeFn)
    assert(type(beforeFn) == "function", "Please provide a function to execute.")
    self._beforeEach = beforeFn
    return self
end

-- this function will run after each test is executed.
function test.suite.mt:afterEach(afterFn)
    assert(type(afterFn) == "function", "Please provide a function to execute.")
    self._afterEach = afterFn
    return self
end

-- allows the default 'run' function to get overridden. Passes in a function
function test.suite.mt:onRun(onRunFn)
    self._run = onRunFn
    return self
end

-- Default _run function, that just passes on the filters
function test.suite.mt:_run(runFn, ...)
    runFn(self, ...)
end

function test.suite.mt:run(...)
    local result = test.result.new()
    self.result = result

    pushSuite(self)
    result:start()

    self:_run(function(suite, filter, ...)
        local count = #suite.tests
        for i,t in ipairs(suite.tests) do
            if matchesFilter(t, i, count, filter) then
                local ok, err = true, nil
                if suite._beforeEach then
                    ok, err = xpcall(function() return suite._beforeEach(t) end, debug.traceback)
                end
                if ok then
                    t(...)
                    if suite._afterEach then
                        ok, err = xpcall(function() return suite._afterEach(t) end, debug.traceback)
                        if not ok then
                            if handler.error then
                                handler.error(t, format("Error occurred after test '%s': %s", t.name, err))
                            end
                            result.errors = result.errors + 1
                        end
                    end
                else
                    if handler.error then
                        handler.error(t, format("Error occurred before test '%s': %s", t.name, err))
                    end
                    result.errors = result.errors + 1
                end
            end
        end
    end, ...)
    self.result:stop()
    popSuite()

    -- only output the summary if there is no parent suite, or if 'verbose' is enabled.
    if (not addResult(self.result) or verbose) and handler.summary then
        handler.summary(self)
    end
end

function test.suite.mt:addResult(newResult)
    if self.result then
        self.result:add(newResult)
        return true
    else
        return false
    end
end

function test.suite.mt:__call(...)
    return self:run(...)
end

function test.config(newHandler, isVerbose)
    if newHandler then
        self.handler(newHandler) -- luacheck: ignore
    end
    if verbose ~= nil then
        verbose = isVerbose
    end
    return test
end

function test.verbose(isVerbose)
    verbose = isVerbose == nil and true or isVerbose
    return test
end

function test.handler(newHandler)
    handler = newHandler or DEFAULT_HANDLER
    return test
end

function test.case.is(value)
    return type(value) == "table" and getmetatable(value) == test.case.mt
end

test.is = test.case.is

return setmetatable(test, {
    __call = function(_,...) return test.new(...) end,
})
