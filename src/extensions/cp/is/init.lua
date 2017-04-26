--- === cp.is ===
---
--- This is a utility library for helping keep track of `true`/`false` states. It works by creating a table which has a `get` and (optionally) a `set` function which are called when changing the state.
---
--- ## Features
--- ### 1. Callable
--- An `is` can be called like a function once created. Eg:
---
--- ```lua
--- local value = true
--- local isValue = is.new(function() return value end, function(newValue) value = newValue end)
--- isValue() == true		-- `value` is still true
--- isValue(false) == false	-- now `value` is false
--- ```
---
--- ### 2. Togglable
--- An `is` comes with toggling built in - as long as the it has a `set` function. Continuing from the last example:
---
--- ```lua
--- isValue:toggle()	-- `value` went from `false` to `true`.
--- ```
---
--- ### 3. Watchable
--- Interested parties can 'watch' the `is` value to be notified of changes. Again, continuing on:
---
--- ```lua
--- isValue:watch(function(newValue) print "New Value: "...newValue) end)	-- prints "New Value: true" immediately
--- isValue(false)	-- prints "New Value: false"
--- ```
---
--- ### 4. Combinable
--- Because all values are booleans, we can combine or modify them with AND/OR and NOT operations. The resulting values will be a live combination of the underlying `is` values. They can also be watched, and will be notified when the underlying `is` values change. For example:
---
--- ```lua
--- local watered   = is.TRUE()               -- a simple `is` which stores the current value internally, defaults to `true`
--- local fed       = is.FALSE()              -- same as above, defautls to `false`
--- local rested    = is.FALSE()              -- as above.
--- local satisfied = watered:AND(fed)        -- will be true if both `watered` and `fed` are true.
--- local happy     = satisfied:AND(rested)   -- will be true if both `satisfied` and `happy`.
--- local sleepy    = fed:AND(is.NOT(rested)) -- will be sleepy if `fed`, but not `rested`.
---
--- -- These statements all evaluate to `true`
--- satisfied()     == false
--- happy()         == false
--- sleepy()        == false
--- 
--- -- Get fed
--- fed(true)       == true
--- satisfied()     == true
--- happy()         == false
--- sleepy()        == true
---
--- -- Get rest
--- rested:toggle() == true
--- satisfied()     == true
--- happy()         == true
--- sleepy()        == false
---
--- -- These will produce an error, because you can't modify an AND or OR:
--- happy(true)
--- happy:toggle()
--- ```
---
--- ## 5. Immutable
--- If appropriate, an `is` may be immutable. Any `is` with no `set` function defined is immutable. Examples are the `is.AND` and `is.OR` instances, since modifying combinations of values doesn't really make sense. Additionally, an immutable wrapper can be made from any `is` value via either `is.IMMUTABLE(...)` or calling the `myValue:IMMUTABLE()` method.
---
--- Note that the underlying `is` value(s) are still potentially modifyable, and any watchers on the immutable wrapper will be notified of changes. You just can't make any changes directly to the immutable value.
---
--- For example:
---
--- ```lua
--- local isImmutable = isValue:IMMUTABLE()
--- isImmutable:toggle()	-- results in an `error` being thrown
--- isImmutable:watch(function(newValue) print "isImmutable changed to "..newValue end)
--- isValue:toggle()		-- prints "isImmutable changed to false"
--- ```
---
--- ## 6. Attachable
--- By default, an `is` acts like a function. It does not expect to receive a table as the first parameter. So, this will fail:
---
--- ```lua
--- local owner = {}
--- owner.isMethod = is.TRUE()
--- owner:isMethod() -- error!
--- ```
---
--- To use an `is` as a method, you need to `attach` it to the owning table, like so:
---
--- ```lua
--- local owner = {}
--- owner.isMethod = is.TRUE():bind(owner)
--- owner:isMethod() -- success!
--- ```
---
--- **NOTE:** An `is` should only be attached to a true instance, not to a metatable.
	
local log				= require("hs.logger").new("is")
local inspect			= require("hs.inspect")

local is = {}
is.__index = is

local ids = 0

local function nextId()
	ids = ids + 1
	return ids
end

local function isInstance(something)
	if something and type(something) == "table" then
		local mt = getmetatable(something)
		return mt and (mt.__index == is or isInstance(mt.__index))
	end
	return false
end

--- cp.is.new(getFn, setFn) --> cp.is
--- Constructor
--- Creates a new `is` value, with the provided `get` and `set` functions.
---
--- Parameters:
--- * `getFn`		- The function that will get called to retrieve the current value.
--- * `setFn`		- The function that will get called to set the new value.
---
--- Returns:
--- * The new `cp.is` instance.
---
--- Notes:
--- * `getFn` signature: `function([owner])`
--- ** `owner`		- If this is attached as a method, the owner table is passed in.
--- * `setFn` signature: `function(newValue[, owner])`
--- ** `newValue`	- The new value to store.
--- ** `owner`		- If this is attached as a method, the owner table is passed in.
function is.new(getFn, setFn)
	assert(getFn ~= nil and type(getFn) == "function")
	assert(setFn == nil or type(setFn) == "function")
	local o = {
		_id			= nextId(),
		_get		= getFn,
		_set		= setFn,
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
--- * The original `isValue` can still be modified (if appropriate) and watchers of the immutable value will be notified when it changes.
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
				if not value:value() then
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
				if value:value() then
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

--- cp.is.applyAll(target, ...) -> table
--- Function
--- Copies and binds all 'method' properties on the source tables passed in to the `target` table. E.g.:
---
--- ```lua
--- local source, target = {}, {}
--- source.isMethod = is.TRUE():bind(source)
--- source.isFunction = is.TRUE()
--- is.bindAll(target, source)
--- target:isMethod() == true
--- target.isFunction() -- error. The function was not copied.
--- ```
---
--- The original `is` methods on the source 
--- 
--- Parameters:
--- * `target`	- The target table to copy the methods into.
--- * `...`		- The list of source tables to copy and bind methods from
---
--- Returns:
--- * The target
function is.applyAll(target, ...)
	local sources = table.pack(...)
	for i,source in ipairs(sources) do
		for k,v in pairs(source) do
			if target[k] == nil and isInstance(v) then
				if v:owner() == source then
					-- it's a bound method. rebind.
					target[k] = v:bind(target)
				else
					-- it's an unbound function
					target[k] = v
				end
			end
		end
	end
end

function is.extend(target, source)
	is.applyAll(target, source)
	return setmetatable(target, {__index = source})
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
	local value = self._get(self._owner)
	value = value ~= nil and value ~= false
	if newValue ~= nil then
		if not self._set then
			error("This value cannot be modified.")
		end
		newValue = newValue ~= false
		if value ~= newValue then
			self._set(newValue, self._owner)
			if not quiet then
				self:notify()
			end
			return newValue
		end
	end
	return value
end

--- cp.is:bind(owner) -> cp.is
--- Method
--- Creates a new instance of the is which is bound to the specified owner.
---
--- Parameters:
--- * `owner`	- The owner to attach to.
---
--- Returns:
--- * the `cp.is`
---
--- Notes:
--- * Throws an `error` if this is already attached to an owner.
function is:bind(owner)
	local o = {_owner = owner}
	return setmetatable(o, {__index = self, __call = is.__call, __tostring = is.__tostring})
end

--- cp.is:owner() -> table
--- Method
--- If this is a 'method', return the table instance the method is attached to.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The owner table, or `nil`.
function is:owner()
	return self._owner
end

--- cp.is:mutable() -> boolean
--- Method
--- Checks if the `cp.is` owner can be modified.
---
--- Parameters:
--- * None
---
--- Returns:
--- * `true` if the value can be modified.
function is:mutable()
	return self._set ~= nil
end

--- cp.is:toggle() -> boolean
--- Method
--- Toggles the current value.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The new value.
---
--- Notes:
--- * If the value is immutable, an error will be thrown.
function is:toggle()
	return self:value(not self._get(self._owner))
end

--- cp.is:watch(watchFn[, notifyNow]) -> cp.is
--- Method
--- Adds the watch function to the value. When the value changes, watchers are notified by calling the function, passing in the current value as the first parameter.
---
--- Parameters:
--- * `watchFn`		- The watch function.
--- * `notifyNow`	- The function will be triggered immediately with the current state.  Defaults to `false`.
---
--- Returns:
--- * The same `cp.is` instance.
---
--- Notes:
--- * You can watch immutable values. Wrapped `cp.is` instances may not be immutable, and any changes to them will cause watchers to be notified up the chain.
function is:watch(watchFn, notifyNow)
	if not self._watchers then
		self._watchers = {}
	end
	self._watchers[#self._watchers + 1] = watchFn
	if notifyNow then
		watchFn(self:value())
	end
	return self
end

--- cp.is:notify() -> nil
--- Method
--- Notifies all watchers of the current value if it has changed since the last notification.
---
--- Parameters:
--- * None
---
--- Returns:
--- * Nothing
function is:notify()
	if self._watchers then
		local value = self:value()
		if self._lastValue ~= value then
			for _,watcher in ipairs(self._watchers) do
				watcher(value)
			end
		end
		self._lastValue = value
	end
end

-- Displays the `cp.is` instance as a string.
function is:__tostring()
	return string.format("is #%d: %s", self._id, self:value())
end

is.__call = function(target, owner, newValue, quiet)
	if not target._owner or target._owner ~= owner then
		-- no owner provided, so shift the parameters across
		quiet = newValue
		newValue = owner
	end
	return is.value(target, newValue, quiet)
end

return is