-- Adapted from 'utf8.lua' (https://github.com/Stepets/utf8.lua)
--[[
Copyright (c) 2006-2007, Kyle Smith
All rights reserved.

Contributors:
	Alimov Stepan
	David Peterson

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the author nor the names of its contributors may be
      used to endorse or promote products derived from this software without
      specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]

local log				= require("hs.logger").new("matcher")

local text				= require("cp.text")

local utf8codepoint, utf8char = utf8.codepoint, utf8.char
local floor, tonumber = math.floor, tonumber
local unpack, pack, sort, insert, remove = table.unpack, table.pack, table.sort, table.insert, table.remove
local format = string.format

local charClasses = {}

local function uc(value)
	return type(value) == "number" and value or utf8codepoint(value)
end

-- appendAll(target, source) -> table
-- Function
-- Appends all items in `source` to the end of `target`.
--
-- Parameters:
--  * `target`	- The target table
--  * `source`	- The source table
--
-- Returns:
--  * The `target` table
local function appendAll(target, source)
	for _,v in ipairs(source) do
		insert(target, v)
	end
	return target
end

local function range(first, last)
	return {uc(first), uc(last)}
end

local function ranges(...)
	local result = {}
	
	local value
	for _,v in ipairs(pack(...)) do
		if type(v) == "table" then
			local len = #v
			if len > 1 then
				value = range(v[1], v[2])
			elseif len == 1 then
				value = range(v[1], v[1])
			end
		else
			value = range(v, v)
		end
		insert(result, value)
	end
	
	return result
end

-- compares two character range tables
local function rangeOrder(a, b)
	return a[1] < b[1] or a[1] == b[1] and a[2] < b[2]
end

-- charClass(id[, ...]) -> number | table
-- Function
-- Creates a new pattern 'character class' with the specified `id` character, or retrieves an existing one.
-- If just the `id` is provided, the existing class is returned, otherwise a new one is created. Eg:
--
-- ```lua
-- local a = charClass('a', {'a', 'z'})			-- create a new class
-- local b = charClass('b', 1, 'a', {'A', 'C'})	-- more complicated class
-- local ranges = charClass('a')				-- retrieves the 'a' class
-- charClass('c') == nil						-- no 'c' class, so returns nil.
--
-- Parameters:
--  * `id`		- The class ID
--  * `...`		- If provided should be a list individual codepoint or character values, or a table with a beginning and end range.
--
-- Returns:
--  * The new class ID value if no values are provided, or the existing character class table.
--
-- Notes:
--  * The class is defined: a) an integer for the Unicode Codepoint value, b) a UTF-8 string with a single character or c) a table with two integer or character values (e.g. `{'a', 'z'}`).
local function charClass(id, ...)
	id = uc(id)
	if select('#', ...) == 0 then
		return charClasses[id]
	else
		local cr = ranges(...)
		sort(cr, rangeOrder)
		charClasses[id] = cr
		return id
	end
end

-- pattern characters
local ESCAPE			= uc "%"
local ANY_GREEDY		= uc "*"
local ANY_LAZY			= uc "-"
local ONE_OR_MORE		= uc "+"
local ONE_OR_ZERO		= uc "?"
local ANY_CHAR			= uc "."

local CLASS_OPEN		= uc "["
local CLASS_CLOSE		= uc "]"
local CLASS_RANGE		= uc "-"
local CLASS_COMPLIMENT	= uc "^"

local GROUP_OPEN		= uc "("
local GROUP_CLOSE		= uc ")"

local PATTERN_FIRST		= uc "^"
local PATTERN_LAST		= uc "$"

local ZERO				= uc "0"													-- %0: The whole string
local ONE				= uc "1"													-- %1: The first capture group
local NINE				= uc "9"													-- %9: The last capture group
local BALANCED			= uc "b"													-- %bxy: balanced 'x'...'y' groups

local EOF				= -1

-- Character Classes
local DIGITS			= charClass('d', {'0', '9'})								-- %d: decimal digits
local HEXADECIMAL		= charClass('x', {'0', '9'}, {'a', 'f'}, {'A', 'F'})		-- %x: hexadecimal digits

local LOWER_ASCII		= charClass('l', {'a', 'z'})								-- %l: lower case (ASCII)
local UPPER_ASCII		= charClass('u', {'A', 'Z'})								-- %u: upper case (ASCII)

local ALL_ASCII			= charClass('a', {'A', 'Z'}, {'a', 'z'})					-- %a: alphabet, any case (ASCII)
local ALPHANUM_ASCII	= charClass('w', {'0', '9'}, {'A', 'Z'}, {'a', 'z'})		-- %w: alphanumeric (ASCII)
local PUNCTUATION		= charClass('p', {33, 47}, {58, 64}, {91, 96}, {123, 126})	-- %p: punctuation (ASCII)

local CONTROL_CHARS		= charClass('c', {0, 31}, 127)								-- %c: control characters (ASCII)
local NIL_CHAR			= charClass('z', 0)											-- %z: the zero character.

local SPACE				= charClass('s',											-- %s: whitespace characters
							{9, 13}, 32, 133, 160, 5760,
							{8192, 8202}, 8232, 8233, 8239, 8287,
							12288
						  )

local PRINTABLE			= charClass('g',											-- %g: printable characters
							{1, 8}, {14, 31}, {33, 132}, {134, 159},
							{161, 5759}, {5761, 8191},
							{8203, 8231}, {8234, 8238}, {8240, 8286}, {8288, 12287}
						  )

local function binsearch(sortedTable, item, comp)
	local head, tail = 1, #sortedTable
	local mid = floor((head + tail)/2)
	if not comp then
		while (tail - head) > 1 do
			if sortedTable[tonumber(mid)] > item then
				tail = mid
			else
				head = mid
			end
			mid = floor((head + tail)/2)
		end
	end
	if sortedTable[tonumber(head)] == item then
		return true, tonumber(head)
	elseif sortedTable[tonumber(tail)] == item then
		return true, tonumber(tail)
	else
		return false
	end
end

local function inRanges(ranges, charCode)
	for _,r in ipairs(ranges) do
		if r[1] <= charCode and charCode <= r[2] then
			return true
		end
	end
	return false
end

local function replace(repl, args)
	local ret = text ''
	if text.is(repl) or type(repl) == 'string' then
		repl = text.is(repl) and repl or text(tostring(repl))
		local ignore = false
		local chars = {}
		for _,c in ipairs(repl) do
			if not ignore then
				if c == ESCAPE then
					ignore = true
				else
					insert(chars, c)
				end
			else
				if ZERO <= c and c <= NINE then
					local num = c - ZERO -- shifts 'c' to an index from 0 to 9
					local value = args[num]
					if value then
						appendAll(chars, text.fromString(value))
					end
				else
					insert(chars, c)
				end
				ignore = false
			end
		end
		ret = ret .. text.fromCodepoints(chars)
	elseif type(repl) == 'table' then
		ret = ret .. (repl[args[1] or args[0]] or '')
	elseif type(repl) == 'function' then
		if #args > 0 then
			ret = ret .. (repl(unpack(args, 1)) or '')
		else
			ret = ret .. (repl(args[0]) or '')
		end
	end
	return ret
end

-- classMatchGenerator(pattern)
local function classMatchGenerator(pattern, pos, len, plain)
	local codes = {}
	local ranges = {}
	local ignore = false
	local inRange = false
	local firstletter = true
	local unmatch = false

	len = len or #pattern
	while pos <= len do
		local c = pattern[pos]
		if not ignore and not plain then
			if c == ESCAPE then
				ignore = true
			elseif c == CLASS_RANGE then
				insert(codes, c)
				inRange = true
			elseif c == CLASS_COMPLIMENT then
				if not firstletter then
					error(format("unexpected class compliment ('^') after '%s'", pattern:sub(1, pos)))
				else
					unmatch = true
				end
			elseif c == CLASS_CLOSE then
				pos = pos + 1
				break
			else
				if not inRange then
					insert(codes, c)
				else
					remove(codes) -- removing '-'
					insert(ranges, range(remove(codes), c))
					inRange = false
				end
			end
		elseif ignore and not plain then
			local cc = charClass(c)
			if cc then
				appendAll(ranges, cc)
			else -- it's a custom range
				if not inRange then
					insert(codes, c)
				else
					remove(codes) -- removing '-' from codes
					insert(ranges, range(remove(codes), c))
					inRange = false
				end
			end
			ignore = false
		else
			if not inRange then
				insert(codes, c)
			else
				remove(codes) -- removing '-'
				insert(ranges, range(remove(codes), c))
				inRange = false
			end
			ignore = false
		end
		
		firstletter = false
		pos = pos + 1
	end

	table.sort(codes)

	if not unmatch then
		return function(charCode)
			return binsearch(codes, charCode) or inRanges(ranges, charCode)
		end, pos-1
	else
		return function(charCode)
			return charCode ~= -1 and not (binsearch(codes, charCode) or inRanges(ranges, charCode))
		end, pos-1
	end
end

local cache = setmetatable({},{
	__mode = 'kv'
})
local cachePlain = setmetatable({},{
	__mode = 'kv'
})

-- The 'matcher' metatable
local matcher = {}
matcher.mt = {}
matcher.mt.__index = matcher.mt

matcher.mt.nextFunc = function(self)
	self.func = self.func + 1
	-- log.df("nextFunc: %s of %s", self.func, #self.functions)
end
matcher.mt.nextPos = function(self)
	self.textPos = self.textPos + 1
	-- log.df("nextPos: %s", self.textPos)
end
matcher.mt.resetPos = function(self)
	local oldReset = self.reset
	local textPos = self.textPos
	self.reset = function(s)
		s.textPos = textPos
		s.reset = oldReset
	end
	-- log.df("resetPos: %s", self.textPos)
end
matcher.mt.fullResetOnNextFunc = function(self)
	local oldReset = self.reset
	local func = self.func +1
	local textPos = self.textPos
	self.reset = function(s)
		s.func = func
		s.textPos = textPos
		s.reset = oldReset
	end
end
matcher.mt.fullResetOnNextStr = function(self)
	local oldReset = self.reset
	local textPos = self.textPos + 1
	local func = self.func
	self.reset = function(s)
		s.func = func
		s.textPos = textPos
		s.reset = oldReset
	end
end

--- cp.text.matcher:find(value[, start]) -> number, number, ...
--- Method
--- Processes the text, returning the start position, the end position, followed by any capture group values.
---
--- Parameters:
---  * `value`		- The `cp.text` value to process.
---  * `start`		- If specified, indicates the starting position to process from. Defaults to `1`.
---
--- Returns:
---  * The start position for the match, end position, and the list of capture group values.
matcher.mt.find = function(self, value, start)
	value = text.is(value) and value or text(tostring(value))

	self.func = 1
	start = start or 1
	self.textLen = #value + 1
	self.textStart = (start >= 0) and start or self.textLen + start
	self.seqStart = self.textStart
	self.textPos = self.textStart
	self.text = value
	self.stop = false

	self.reset = function(s)
		s.func = 1
	end

	local ch
	while not self.stop do
		if self.textPos < self.textLen then
			ch = value[self.textPos]
			self.functions[self.func](ch)
		else
			self.functions[self.func](EOF)
		end
	end

	if self.seqStart then
		local captures = {}
		for _,pair in pairs(self.captures) do
			if pair.empty then
				insert(captures, pair[1])
			else
				insert(captures, value:sub(pair[1], pair[2]))
			end
		end
		return self.seqStart, self.textPos-1, unpack(captures)
	end
end

--- cp.text.matcher:match(value[, start]) -> ...
--- Method
--- Looks for the first match of the pattern in the string `value`. If it finds one, then match returns the captures from the pattern; otherwise it returns `nil`. If pattern specifies no captures, then the whole match is returned. A third, optional numerical argument init specifies where to start the search; its default value is `1` and can be negative.
---
--- Parameters:
---  * `value`		- The `cp.text` value to process.
---  * `start`		- If specified, indicates the starting position to process from. Defaults to `1`.
---
--- Returns:
---  * The capture results, the whole match, or `nil`.
matcher.mt.match = function(self, value, start)
	value = text.is(value) and value or text(tostring(value))
	start = start or 1
	local found = {self:find(value, start)}
	if found[1] then
		if found[3] then
			return unpack(found, 3)
		end
		return value:sub(found[1], found[2])
	end
end

--- cp.text.matcher:gmatch(value) -> function
--- Method
--- Returns an iterator function that, each time it is called, returns the next captures from pattern over string s. If pattern specifies no captures, then the whole match is produced in each call.
---
--- Parameters:
---  * `value`		- The `cp.text` value to process.
---
--- Returns:
---  * The iterator function.
matcher.mt.gmatch = function(self, value, all)
	value = text.is(value) and value or text(tostring(value))
	local pattern = self.pattern
	local regex = (pattern:sub(1,1) ~= '^') and pattern or '%' .. pattern
	local lastChar = 1
	return function()
		local found = {self:find(value, lastChar)}
		if found[1] then
			lastChar = found[2] + 1
			if found[all and 1 or 3] then
				return unpack(found, all and 1 or 3)
			end
			return value:sub(found[1], found[2])
		end
	end
end

--- cp.text.match:gsub (value, repl [, n]) -> text, number
--- Returns a copy of `value` in which all (or the first `n`, if given) occurrences of the pattern have been replaced by a replacement string specified by `repl`, which can be text, a string, a table, or a function. gsub also returns, as its second value, the total number of matches that occurred.
---
--- If repl is text or a string, then its value is used for replacement. The character `%` works as an escape character: any sequence in repl of the form `%n`, with `n` between `1` and `9`, stands for the value of the `n`-th captured substring (see below). The sequence `%0` stands for the whole match. The sequence `%%` stands for a single `%`.
---
--- If `repl` is a table, then the table is queried for every match, using the first capture as the key; if the pattern specifies no captures, then the whole match is used as the key.
---
--- If `repl` is a function, then this function is called every time a match occurs, with all captured substrings passed as arguments, in order; if the pattern specifies no captures, then the whole match is passed as a sole argument.
---
--- If the value returned by the table query or by the function call is a string or a number, then it is used as the replacement string; otherwise, if it is `false` or `nil`, then there is no replacement (that is, the original match is kept in the string).
---
--- Parameters:
--- * `value`	- The text or string value to process.
--- * `repl`	- The replacement text/string/table/function
--- * `limit`	- The maximum number of times to do the replacement. Defaults to unlimited.
---
--- Returns:
--- * `text`	- The text value with replacements.
--- * `number`	- The number of matches that occurred.
matcher.mt.gsub = function(self, value, repl, limit)
	value = text.is(value) and value or text(tostring(value))
	limit = limit or -1
	local ret = ''
	local prevEnd = 1
	local it = self:gmatch(value, true)
	local found = {it()}
	local n = 0
	while #found > 0 and limit ~= n do
		local args = {[0] = value:sub(found[1], found[2]), unpack(found, 3)}
		ret = ret .. value:sub(prevEnd, found[1] - 1) .. replace(repl, args)
		prevEnd = found[2] + 1
		n = n + 1
		found = {it()}
	end
	return ret .. value:sub(prevEnd), n
end


-- cp.text.matcher.matcherGenerator(pattern, plain)
-- Constructor
-- Creates a new `matcher` instance.
--
-- Parameters:
--  * `pattern`	- The text containing the pattern. May be a UTF-8 `string` or a `cp.text`.
--  * `plain`	- If `true`, the text is plain, and will not be processed for pattern markup.
--
-- Returns:
--  * A new `cp.text.matcher` instance.
local function matcherGenerator(pattern, plain)
	local m = {
		functions = {},
		captures = {},
		pattern = pattern,
	}
	setmetatable(m, matcher.mt)
	
	if not plain then
		cache[pattern] = m
	else
		cachePlain[pattern] = m
	end
	
	local function simple(func)
		return function(cC)
			-- log.df("simple: %s", utf8char(cC))
			if func(cC) then
				m:nextFunc()
				m:nextPos()
			else
				m:reset()
			end
		end
	end
	local function star(func)
		return function(cC)
			-- log.df("star: %s", utf8char(cC))
			if func(cC) then
				m:fullResetOnNextFunc()
				m:nextPos()
			else
				m:nextFunc()
			end
		end
	end
	local function minus(func)
		return function(cC)
			-- log.df("minus: %s", utf8char(cC))
			if func(cC) then
				m:fullResetOnNextStr()
			end
			m:nextFunc()
		end
	end
	local function question(func)
		return function(cC)
			-- log.df("question: %s", utf8char(cC))
			if func(cC) then
				m:fullResetOnNextFunc()
				m:nextPos()
			end
			m:nextFunc()
		end
	end

	local function capture(id)
		return function(_)
			-- log.df("capture")
			local l = m.captures[id][2] - m.captures[id][1]
			local captured = m.text:sub(m.captures[id][1], m.captures[id][2])
			local check = m.text:sub(m.textPos, m.textPos + l)
			if captured == check then
				for _ = 0, l do
					m:nextPos()
				end
				m:nextFunc()
			else
				m:reset()
			end
		end
	end
	local function captureStart(id)
		return function(_)
			-- log.df("capture start")
			m.captures[id][1] = m.textPos
			m:nextFunc()
		end
	end
	local function captureStop(id)
		return function(_)
			-- log.df("capture stop")
			m.captures[id][2] = m.textPos - 1
			m:nextFunc()
		end
	end

	local function balancer(bc, ec)
		local sum = 0
		return function(cC)
			-- log.df("balancer", utf8char(cC))
			if cC == ec and sum > 0 then
				sum = sum - 1
				if sum == 0 then
					m:nextFunc()
				end
				m:nextPos()
			elseif cC == bc then
				sum = sum + 1
				m:nextPos()
			else
				if sum == 0 or cC == -1 then
					sum = 0
					m:reset()
				else
					m:nextPos()
				end
			end
		end
	end

	m.functions[1] = function(_)
		m:fullResetOnNextStr()
		m.seqStart = m.textPos
		m:nextFunc()
		if (m.textPos > m.textStart and m.fromStart) or m.textPos >= m.textLen then
			m.stop = true
			m.seqStart = nil
		end
	end

	local lastFunc
	local ignore = false
	local pos, len = 1, #pattern
	local cs = {}
	while pos <= len do
		local c = pattern[pos]
		if plain then
			insert(m.functions, simple(classMatchGenerator(pattern, pos, pos, plain)))
		else
			if c == ANY_GREEDY then									-- '*': grabs as many of the matching characters as possible
				if lastFunc then
					insert(m.functions, star(lastFunc))
					lastFunc = nil
				else
					error('invalid pattern after ' .. pattern:sub(1, pos))
				end
			elseif c == ONE_OR_MORE then							-- '+': grabs at least one matching character, more if possible.
				if lastFunc then
					insert(m.functions, simple(lastFunc))
					insert(m.functions, star(lastFunc))
					lastFunc = nil
				else
					error('invalid pattern after ' .. pattern:sub(1, pos))
				end
			elseif c == ANY_LAZY then								-- '-': grabs the fewest possible characters that match.
				if lastFunc then
					insert(m.functions, minus(lastFunc))
					lastFunc = nil
				else
					error('invalid pattern after ' .. pattern:sub(1, pos))
				end
			elseif c == ONE_OR_ZERO then							-- '?': One or zero instances of the character
				if lastFunc then
					insert(m.functions, question(lastFunc))
					lastFunc = nil
				else
					error('invalid pattern after ' .. pattern:sub(1, pos))
				end
			elseif c == PATTERN_FIRST then							-- '^': Matches the beginning of the text
				if pos == 1 then
					m.fromStart = true
				else
					error('invalid pattern after ' .. pattern:sub(1, pos))
				end
			elseif c == PATTERN_LAST then							-- '$': Matches the end of the text.
				if pos == len then
					m.toEnd = true
				else
					error('invalid pattern after ' .. pattern:sub(1, pos))
				end
			elseif c == CLASS_OPEN then								-- '[': opens a custom character class
				if lastFunc then
					insert(m.functions, simple(lastFunc))
				end
				lastFunc, pos = classMatchGenerator(pattern, pos+1)
			elseif c == GROUP_OPEN then								-- '(': opens a capture group.
				if lastFunc then
					insert(m.functions, simple(lastFunc))
					lastFunc = nil
				end
				insert(m.captures, {})
				insert(cs, #m.captures)
				insert(m.functions, captureStart(cs[#cs]))
				if pattern[pos+1] == GROUP_CLOSE then m.captures[#m.captures].empty = true end
			elseif c == GROUP_CLOSE then							-- ')': closes a capture group
				if lastFunc then
					insert(m.functions, simple(lastFunc))
					lastFunc = nil
				end
				local cap = remove(cs)
				if not cap then
					error('invalid capture: "(" missing')
				end
				insert(m.functions, captureStop(cap))
			elseif c == ANY_CHAR then
				if lastFunc then
					insert(m.functions, simple(lastFunc))
				end
				lastFunc = function(cC) return cC ~= -1 end
			elseif c == ESCAPE then
				if pos == len then
					error(format('dangling escape character "%" at "%s"', pattern:sub(1, pos)))
				end
				local cx = pattern[pos+1]
				-- log.df("Escape: %s", utf8char(cx))
				if ONE <= cx and cx <= NINE then							-- it's a capture group reference
					if lastFunc then
						insert(m.functions, simple(lastFunc))
						lastFunc = nil
					end
					insert(m.functions, capture(c - ONE + 1))
					pos = pos + 1
				elseif cx == BALANCED then								-- it's a 'balanced' pattern matcher
					if lastFunc then
						insert(m.functions, simple(lastFunc))
						lastFunc = nil
					end
					local b = balancer(pattern[pos+2], pattern[pos+3])
					insert(m.functions, b)
					pos = pos + 3
				else													-- it's a character class/escape value
					if lastFunc then
						insert(m.functions, simple(lastFunc))
					end
					lastFunc, pos = classMatchGenerator(pattern, pos, pos+1)
				end
			else
				if lastFunc then
					insert(m.functions, simple(lastFunc))
				end
				lastFunc, pos = classMatchGenerator(pattern, pos, pos)
			end
		end
		pos = pos + 1
	end
	if #cs > 0 then
		error('invalid capture: ")" missing')
	end
	if lastFunc then
		insert(m.functions, simple(lastFunc))
	end

	insert(m.functions, function()
		if m.toEnd and m.textPos ~= m.textLen then
			m:reset()
		else
			m.stop = true
		end
	end)

	return m
end

--- cp.text.matcher(pattern[, plain]) -> cp.text.matcher
--- Constructor
--- Returns a matcher for the specified pattern. This follows the conventions of the standard [LUA Patterns](https://www.lua.org/pil/20.2.html) API. This will return a reusable, compiled parser for the given pattern.
---
--- Parameters:
---  * `pattern`	- The pattern to parse
---  * `plain`		- If `true`, the pattern is not parsed and the provided text must match exactly.
local function newMatcher(pattern, plain)
	pattern = text.is(pattern) and pattern or text(tostring(pattern))
	local m = plain and cachePlain[pattern] or cache[pattern]
	return m or matcherGenerator(pattern, plain)
end

return newMatcher