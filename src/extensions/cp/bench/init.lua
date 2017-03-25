
--------------------------------------------------------------------------------
-- TIME FUNCTION EXECUTION:
-- Use this to benchmark sections of code. Wrap them in a function inside this
-- function call. Eg:
--
-- local _bench = require("hs.bench")
--
-- local foo = _bench("Foo Test", function()
--     return do.somethingHere()
-- end) --_bench
--
-- You can also benchmark all (or some) of the functions on a table in one hit
-- by using the 'bench.press' function:
--
-- local mod = { ... }
-- -- All functions are benchmarked
-- mod = _bench.press("mymod", mod)
-- -- Just the "foo" and "bar" functions are benchmarked.
-- mod = _bench.press("mymod", mod, {"foo", "bar"})
--------------------------------------------------------------------------------
-- local clock = os.clock
local log = require("hs.logger").new("bench")
local clock = require("hs.timer").secondsSinceEpoch
local _timeindent = 0
local _timelog = {}

local mod = {}

function mod.mark(label, fn, ...)
	loops = loops or 1
	local result = nil
	local t = _timelog

	t[#t+1] = {label = label, indent = _timeindent}
	_timeindent = _timeindent + 2
	local start = clock()
	for i=1,loops do result = fn(...) end
	local stop = clock()
	local total = stop - start
	_timeindent = _timeindent - 2
	t[#t+1] = {label = label, indent = _timeindent, value = total}

	if _timeindent == 0 then
		-- print when we are back at zero indents.
		local text = nil
		for i,v in ipairs(_timelog) do
			text = v.value and string.format("%0.3fms", v.value*1000) or "START"
			inOut = v.value and "<" or ">"
			log.df(string.format("%"..v.indent.."s%40s %s %"..(30-v.indent).."s", "", v.label, inOut, text))
		end
		-- clear the log
		_timelog = {}
	end

	return result
end

local function set(list)
	if list then
		local set = {}
		for _, l in ipairs(list) do set[l] = true end
		return set
	else
		return nil
	end
end

function mod.press(label, value, names)
	if not value.___benched then
		names = set(names)
		for k,v in pairs(value) do
			if type(v) == "function" and (names == nil or names[k]) then
				value[k] = function(...)
					return mod.mark(label.."."..k, v, ...)
				end
			end
		end
		value.___benched = true
		local mt = getmetatable(value)
		if mt then
			mod.press(label, mt)
		end
	end
	return value
end

setmetatable(mod, {__call = function(_, ...) return mod.mark(...) end})

return mod