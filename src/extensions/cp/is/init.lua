--- === cp.is ===
---
--- This is a utility library for helping keep track of `true`/`false` states.
--- They can be combined with other `is` values as an `OR` or `AND` operation.
--- They can be watched for changes, so that updates happen as needed.

local log				= require("hs.logger").new("is")

local is = {}
is.__index = is

local ids = 0

local function nextId()
	ids = ids + 1
	return ids
end

--- cp.is.new(getFn, setFn) --> cp.is
--- Constructor
--- Creates a new `is` instance, with the provided `get` and `set` functions.
---
--- Parameters:
--- * `getFn`	- The function that will get called to retrieve the current value.
--- * `setFn`	- The function that will get called to set the new value. It will be passed the new value.
---
--- Returns:
--- * The new `cp.is` instance.
function is.new(getFn, setFn)
	assert(getFn ~= nil and type(getFn) == "function")
	assert(setFn == nil or type(setFn) == "function")
	local o = {
		_id		= nextId(),
		_get	= getFn,
		_set	= setFn,
	}
	setmetatable(o, is)
	return o
end

--- cp.is.THIS([initialValue]) -> cp.is
--- Function
--- Returns a new `cp.is` instance which will cache a value internally. It will default to the 'truthy' value of the `initialValue`, if provided.
---
--- Parameters:
--- * `initialValue`	- The initial value to set it to (optional).
---
--- Returns:
--- * a new `cp.is` instance.
function is.THIS(initialValue)
	local value = initialValue ~= nil and initialValue ~= false
	local get = function() return value end
	local set = function(newValue) value = newValue end
	return is.new(get, set)
end

--- cp.is.IMMUTABLE(isValue) -- cp.is
--- Function
--- Returns a new `cp.is` instance which will not allow the wrapped value to be modified.
---
--- Parameters:
--- * `isValue`		- The `cp.is` value to wrap.
---
--- Returns:
--- * a new `cp.is` instance which cannot be modified.
---
--- Note:
--- * The original `isValue` can still be modified (if appropriate) and watchers of the immutable instance will be notified when it changes.
--- * This can also be called as a method of a `cp.is` instance. Eg `cp.is.TRUE():IMMUTABLE()`.
function is.IMMUTABLE(isValue)
	local immutable = is.new(function() return isValue:value() end)
	isValue:watch(function() immutable:notify() end)
	return immutable
end

--- cp.is.TRUE() -> cp.is
--- Function
--- Returns a new `cp.is` which will cache internally, initially set to `true`.
---
--- Parameters:
--- * None
---
--- Returns:
--- * a `cp.is` instance defaulting to `true`.
function is.TRUE()
	return is.THIS(true)
end


--- cp.is.FALSE() -> cp.is
--- Function
--- Returns a new `cp.is` which will cache internally, initially set to `false`.
---
--- Parameters:
--- * None
---
--- Returns:
--- * a `cp.is` instance defaulting to `false`.
function is.FALSE()
	return is.THIS(false)
end

--- cp.is.NOT(isValue) -> cp.is
--- Function
--- Returns a new `cp.is` which negates the provided `isValue`.
---
--- Parameters:
--- * `isValue`		- Another `cp.is` instance.
---
--- Returns:
--- * a `cp.is` instance negating the `isValue`.
function is.NOT(isValue)
	local isNot = is.new(
		function() return not isValue:value() end,
		function(newValue) return isValue:value(not newValue, true) end
	)
	-- notify the 'not' watchers if the original value changes.
	isValue:watch(function(value) isNot:notify() end)
	return isNot
end

--- cp.is.AND(...) -> cp.is
--- Function
--- Returns a new `cp.is` which will be `true` if all `cp.is` instances passed into the function return `true`.
---
--- Parameters:
--- * `...`		- The list of `cp.is` instances to 'AND' together.
---
--- Returns:
--- * a `cp.is` instance.
---
--- Notes:
--- * The value of this instance will resolve by lazily checking the `value` of the contained `cp.is` instances in the order provided. If any return `false`, no further instances will be checked.
--- * The instance is immutable, since there is no realy way to flip the component values of an 'AND' in a way that makes sense.
--- * You can also use this as a method. Eg: `is.TRUE():AND(is.FALSE()):value() == false`.
--- * Once you have created an 'AND', you cannot 'OR' as a method. Eg, this will fail: `is.TRUE():AND(is:FALSE()):OR(is.TRUE())`. This is to avoid ambiguity as to whether the 'AND' or 'OR' takes precedence. Is it `(true and false) or true` or `true and (false or true)`?.
--- * To combine 'AND' and 'OR' values, group them together when combining. Eg:
--- ** `(true and false) or true`: `is.OR( is.TRUE():AND(is.FALSE()), is.TRUE() )`
--- ** `true and (false or true)`: `is.TRUE():AND( is.FALSE():OR(is.TRUE()) )`
function is.AND(...)
	local values = table.pack(...)
	local isAnd = is.new(
		function()
			for _,value in ipairs(values) do
				if not value() then
					return false
				end
			end
			return true
		end
	)
	local watcher = function(value) isAnd:notify() end
	for _,value in ipairs(values) do
		value:watch(watcher)
	end
	isAnd.OR = function() error("Unable to 'OR' an 'AND'.") end
	return isAnd
end

--- cp.is.OR(...) -> cp.is
--- Function
--- Returns a new `cp.is` which will be `true` if any `cp.is` instance passed into the function returns `true`.
---
--- Parameters:
--- * `...`		- The list of `cp.is` instances to 'OR' together.
---
--- Returns:
--- * a `cp.is` instance.
---
--- Notes:
--- * The value of this instance will resolve by lazily checking the `value` of the contained `cp.is` instances in the order provided. If any return `true`, no further instances will be checked.
--- * The instance is immutable, since there is no realy way to flip the component values of an 'OR' in a way that makes sense.
--- * You can also use this as a method. Eg: `is.TRUE():OR(is.FALSE()):value() == true`.
--- * Once you have created an 'OR', you cannot 'AND' as a method. Eg, this will fail: `is.TRUE():OR(is:FALSE()):AND(is.TRUE())`. This is to avoid ambiguity as to whether the 'OR' or 'AND' takes precedence. Is it `(true or false) and true` or `true or (false and true)`?.
--- * To combine 'AND' and 'OR' values, group them together when combining. Eg:
--- ** `(true or false) and true`: `is.AND( is.TRUE():OR(is.FALSE()), is.TRUE() )`
--- ** `true or (false and true)`: `is.TRUE():OR( is.FALSE():AND(is.TRUE()) )`
function is.OR(...)
	local values = table.pack(...)
	local isOr = is.new(
		function()
			for _,value in ipairs(values) do
				if value() then
					return true
				end
			end
			return false
		end
	)
	local watcher = function(value) isOr:notify() end
	for _,value in ipairs(values) do
		value:watch(watcher)
	end
	isOr.AND = function() error("Unable to 'AND' an 'OR'.") end
	return isOr
end

--- cp.is:value([newValue[, quiet]]) -> boolean
--- Method
--- Returns the current value of the `cp.is` instance. If a `newValue` is provided, and the instance is mutable, the value will be updated and the new value is returned. If it is not mutable, an error will be thrown.
--- 
--- Parameters:
--- * `newValue`	- The new value to set the instance to.
--- * `quiet`		- If `true`, no notifications will be sent to watchers. Defaults to `false`.
---
--- Returns:
--- * The current boolean value.
function is:value(newValue, quiet)
	local value = self._get()
	value = value ~= nil and value ~= false
	if newValue ~= nil then
		if not self._set then
			error("This 'is' value cannot be modified.")
		end
		newValue = newValue ~= false
		if value ~= newValue then
			self._set(newValue)
			if not quiet then
				self:notify()
			end
			return newValue
		end
	end
	return value
end

--- cp.is:mutable() -> boolean
--- Method
--- Checks if the `cp.is` instance can be modified.
---
--- Parameters:
--- * None
---
--- Returns:
--- * `true` if the instance can be modified.
function is:mutable()
	return self._set ~= nil
end

--- cp.is:toggle() -> boolean
--- Method
--- Toggles the current value of the instance.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The new value of the instance.
---
--- Notes:
--- * If the instance is immutable, an error will be thrown.
function is:toggle()
	return self:value(not self._get())
end

--- cp.is:watch(watchFn) -> nil
--- Method
--- Adds the watch function to the instance. When the value changes, watchers are notified by calling the function, passing in the current value as the first parameter.
---
--- Parameters:
--- * `watchFn`	- The watch function.
---
--- Returns:
--- * Nothing
---
--- Notes:
--- * You can watch immutable instances. Wrapped `cp.is` instances may not be immutable, and any changes to them will cause watchers to be notified up the chain.
--- * New watchers will be notified immediately of the current value.
function is:watch(watchFn)
	if not self._watchers then
		self._watchers = {}
	end
	self._watchers[#self._watchers + 1] = watchFn
	watchFn(self:value())
end

--- cp.is:notify() -> nil
--- Method
--- Notifies all watchers of the current value, regardless of whether it has changed.
---
--- Parameters:
--- * None
---
--- Returns:
--- * Nothing
function is:notify()
	if self._watchers then
		local value = self:value()
		for _,watcher in ipairs(self._watchers) do
			watcher(value)
		end
	end
end

-- Displays the `cp.is` instance as a string.
function is:__tostring()
	return string.format("is #%d: %s", self._id, self:value())
end

is.__call = is.value

return is