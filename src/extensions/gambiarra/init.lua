local inspect		= require("hs.inspect")

local function TERMINAL_HANDLER(e, test, msg)
	if e == 'pass' then
		print("[32m✔[0m "..test..': '..msg)
	elseif e == 'fail' then
		print("[31m✘[0m "..test..': '..msg)
	elseif e == 'except' then
		print("[31m✘[0m "..test..': '..msg)
	end
end

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

-- Compatibility for Lua 5.1 and Lua 5.2
local function args(...)
	return {n=select('#', ...), ...}
end

local function spy(f)
	local s = {}
	setmetatable(s, {__call = function(s, ...)
		s.called = s.called or {}
		local a = args(...)
		table.insert(s.called, {...})
		if f then
			local r
			r = args(xpcall(function() f((unpack or table.unpack)(a, 1, a.n)) end, debug.traceback))
			if not r[1] then
				s.errors = s.errors or {}
				s.errors[#s.called] = r[2]
			else
				return (unpack or table.unpack)(r, 2, r.n)
			end
		end
	end})
	return s
end

local pendingtests = {}
local env = _G
local gambiarrahandler = TERMINAL_HANDLER

local function runpending()
	if pendingtests[1] ~= nil then pendingtests[1](runpending) end
end

return function(name, f, async)
	if type(name) == 'function' then
		gambiarrahandler = name
		env = f or _G
		return
	end

	local testfn = function(next)

		local prev = {
			ok = env.ok,
			spy = env.spy,
			eq = env.eq
		}

		local restore = function()
			env.ok = prev.ok
			env.spy = prev.spy
			env.eq = prev.eq
			gambiarrahandler('end', name)
			table.remove(pendingtests, 1)
			if next then next() end
		end

		local handler = gambiarrahandler

		env.eq = deepeq
		env.spy = spy
		env.ok = function(cond, ...)
			local msg = ""
			for n=1,select('#',...) do
				local m = select(n,...)
				if m then
					msg = msg .. (msg:len() > 0 and " " or "") .. tostring(m)
				end
		  	end
			msg = "["..debug.getinfo(2, 'S').short_src..":"..debug.getinfo(2, 'l').currentline.."] " .. msg
			if cond then
				handler('pass', name, msg)
			else
				handler('fail', name, msg)
			end
		end

		handler('begin', name);
		local ok, err = xpcall(function() f(restore) end, debug.traceback)
		if not ok then
			handler('except', name, err)
		end

		if not async then
			handler('end', name);
			env.ok = prev.ok;
			env.spy = prev.spy;
			env.eq = prev.eq;
		end
	end

	if not async then
		testfn()
	else
		table.insert(pendingtests, testfn)
		if #pendingtests == 1 then
			runpending()
		end
	end
end
