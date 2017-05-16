--- === cp.prop ===
---
--- This is a utility library for helping keep track of single-value property states. Each property provides access to a single value. Must be readable, but may be read-only. It works by creating a table which has a `get` and (optionally) a `set` function which are called when changing the state.
---
--- ## Features
--- ### 1. Callable
--- A `prop` can be called like a function once created. Eg:
---
--- ```lua
--- local value = true
--- local propValue = prop.new(function() return value end, function(newValue) value = newValue end)
--- propValue() == true		-- `value` is still true
--- propValue(false) == false	-- now `value` is false
--- ```
---
--- ### 2. Togglable
--- A `prop` comes with toggling built in - as long as the it has a `set` function. Continuing from the last example:
---
--- ```lua
--- propValue:toggle()	-- `value` went from `false` to `true`.
--- ```
---
--- **Note:** Toggling a non-boolean value will flip it to `nil` and a subsequent toggle will make it `true`. See the [toggle method](#toggle) for more details.
---
--- ### 3. Watchable
--- Interested parties can 'watch' the `prop` value to be notified of changes. Again, continuing on:
---
--- ```lua
--- propValue:watch(function(newValue) print "New Value: "...newValue) end)	-- prints "New Value: true" immediately
--- propValue(false)	-- prints "New Value: false"
--- ```
---
--- This will also work on [AND](#and) and [OR][#or] properties. Any changes from component properties will trigger a notification.
---
--- ### 4. Combinable
--- We can combine or modify properties with AND/OR and NOT operations. The resulting values will be a live combination of the underlying `prop` values. They can also be watched, and will be notified when the underlying `prop` values change. For example:
---
--- ```lua
--- local watered   = prop.TRUE()               -- a simple `prop` which stores the current value internally, defaults to `true`
--- local fed       = prop.FALSE()              -- same as above, defautls to `false`
--- local rested    = prop.FALSE()              -- as above.
--- local satisfied = watered:AND(fed)        -- will be true if both `watered` and `fed` are true.
--- local happy     = satisfied:AND(rested)   -- will be true if both `satisfied` and `happy`.
--- local sleepy    = fed:AND(prop.NOT(rested)) -- will be sleepy if `fed`, but not `rested`.
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
--- You can also use non-boolean properties. Any non-`nil` value is considered to be `true`.
---
--- ## 5. Immutable
--- If appropriate, a `prop` may be immutable. Any `prop` with no `set` function defined is immutable. Examples are the `prop.AND` and `prop.OR` instances, since modifying combinations of values doesn't really make sense. 
---
--- Additionally, an immutable wrapper can be made from any `prop` value via either `prop.IMMUTABLE(...)` or calling the `myValue:IMMUTABLE()` method.
---
--- Note that the underlying `prop` value(s) are still potentially modifiable, and any watchers on the immutable wrapper will be notified of changes. You just can't make any changes directly to the immutable property instance.
---
--- For example:
---
--- ```lua
--- local isImmutable = propValue:IMMUTABLE()
--- isImmutable:toggle()	-- results in an `error` being thrown
--- isImmutable:watch(function(newValue) print "isImmutable changed to "..newValue end)
--- propValue:toggle()		-- prints "isImmutable changed to false"
--- ```
---
--- ## 6. Bindable
--- A property can be bound to an 'owning' table. This table will be passed into the `get` and `set` functions for the property if present. This is mostly useful if your property depends on internal instance values of a table. For example, you might want to make a property work as a method instead of a function:
---
--- ```lua
--- local owner = {
---    _value = true
--- }
--- owner.value = prop(function() return owner._value end)
--- owner:isMethod() -- error!
--- ```
---
--- To use a `prop` as a method, you need to `attach` it to the owning table, like so:
---
--- ```lua
--- local owner = {
---     _value = true
--- }
--- owner.isMethod = prop(function(self) return self._value end, function(value, self) self._value = value end):bind(owner)
--- owner:isMethod()				-- success!
--- owner.isMethod()				-- also works - will still pass in the bound owner.
--- owner.isMethod:owner() == owner	-- is true~
--- ```
--- 
--- The bound `owner` is passed in as the last parameter of the `get` and `set` functions.
---
--- ## 7. Extendable
--- A common use case is using metatables to provide shared fields and methods across multiple instances. A typical example might be:
---
--- ```lua
--- local person = {}
--- function person:name(newValue)
---     if newValue then
---         self._name = newValue
---     end
---     return self._name
--- end
---
--- function person.new(name)
---     local o = { _name = name }
---     return setmetatable(o, { __index = person })
--- end
---
--- local johnDoe = person.new("John Doe")
--- johnDoe:name() == "John Doe"
--- ```
---
--- If we want to make the `name` a property, we might try creating a bound property like this:
---
--- ```lua
--- person.name = prop(function(self) return self._name end, function(value, self) self._name = value end):bind(person)
--- ```
--- Unfortunately, this doesn't work as expected:
---
--- ```lua
--- johnDoe:name() 			-- Throws an error because `person` is the owner, not `johnDoe`.
--- johnDoe.name() == nil	-- Works, but will return `nil` because "John Doe" is applied to the new table, not `person`
--- ```
---
--- The fix is to use `prop.extend` when creating the new person. Rewrite `person.new` like so:
---
--- ```lua
--- person.new(name)
---     local o = { _name = name }
---     return prop.extend(o, person)
--- end
--- ```
---
--- Now, this will work as expected:
---
--- ```lua
--- johnDoe:name() == "John Doe"
--- johnDoe.name() == "John Doe"
--- ```
---
--- The `prop.extend` function will set the `source` table as a metatable of the `target`, as well as binding any bound props that are in the `source` to `target`.

	
local log				= require("hs.logger").new("prop")
local inspect			= require("hs.inspect")
local fnutils			= require("hs.fnutils")

-- The module
local prop = {}

-- The metatable
prop.mt = {}
prop.mt.__index = prop.mt

local ids = 0

local function nextId()
	ids = ids + 1
	return ids
end

-- Returns `true` if the value is `truthy` - either `true` or not `nil`.
local function isTruthy(value)
	return value ~= nil and value ~= false
end

--- cp.prop.is(value) -> boolean
--- Function
--- Checks if the `value` is an instance of a `cp.prop`.
---
--- Parameters:
--- * `value`	- The value to check.
---
--- Returns:
--- * `true` if the value is an instance of `cp.prop`.
function prop.is(value)
	if value and type(value) == "table" then
		local mt = getmetatable(value)
		return mt and (mt.__index == prop.mt or prop.is(mt.__index))
	end
	return false
end

--- cp.prop:id(newId) -> string or cp.prop
--- Method
--- If `newId` is provided it is given a new ID and the `cp.prop` is returned.
--- Otherwise, it returns the current ID.
---
--- Parameters:
--- * `newId`	- (optional) The new ID to set.
---
--- Returns:
--- * The `cp.prop` if setting a new ID, or the current ID value if not.
function prop.mt:id(newId)
	if newId then
		self._id = newId
		return self
	else
		return self._id
	end
end

--- cp.prop:value([newValue]) -> value
--- Method
--- Returns the current value of the `cp.prop` instance. If a `newValue` is provided, and the instance is mutable, the value will be updated and the new value is returned. If it is not mutable, an error will be thrown.
---
--- This method can also be called directly on the property, like so:
---
--- ```lua
--- local foo = prop.TRUE()
--- foo() == foo:value()
--- ```
--- 
--- Parameters:
--- * `newValue`	- The new value to set the instance to.
---
--- Returns:
--- * The current boolean value.
---
--- Notes:
--- * If you need to set the property to `nil`, use the [set method](#set), otherwise it will be ignored.
function prop.mt:value(newValue)
	if newValue ~= nil then
		return self:set(newValue)
	else
		return self:get()
	end
end

--- cp.prop:get() -> value
--- Method
--- Returns the current value of the property.
---
--- Parameters:
--- * None
---
--- Returns
--- * The current value.
function prop.mt:get()
	return self._get(self._owner)
end

--- cp.prop:set(newValue) -> value
--- Method
--- Sets the property to the specified value. Watchers will be notified if the value has changed.
---
--- Parameters:
--- * `newValue`	- The new value to set. May be `nil`.
---
--- Returns:
--- * The new value.
function prop.mt:set(newValue)
	if not self._set then
		error("This property cannot be modified.")
	end
	-- if currently notifying, defer the update
	if self._notifying then
		self._doSet = true
		self._newValue = newValue
		return newValue
	else
		self._set(newValue, self._owner)
		self:_notify(newValue)
		return newValue
	end
end

--- cp.prop:clear() -> nil
--- Method
--- Clears the property. Watchers will be notified if the value has changed.
---
--- Parameters:
--- * None
---
--- Returns:
--- * nil
function prop.mt:clear()
	return self:set(nil)
end

--- cp.prop:bind(owner) -> cp.prop
--- Method
--- Creates a clone of this `cp.prop` which is bound to the specified owner.
---
--- Parameters:
--- * `owner`	- The owner to attach to.
---
--- Returns:
--- * the `cp.prop`
---
--- Notes:
--- * Throws an `error` if the new owner is `nil`.
function prop.mt:bind(owner)
	assert(owner ~= nil, "The owner must not be nil.")
	local o = self:clone()
	o._owner = owner
	return o
end

--- cp.prop:owner() -> table
--- Method
--- If this is a 'method', return the table instance the method is attached to.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The owner table, or `nil`.
function prop.mt:owner()
	return self._owner
end

--- cp.prop:mutable() -> boolean
--- Method
--- Checks if the `cp.prop` can be modified.
---
--- Parameters:
--- * None
---
--- Returns:
--- * `true` if the value can be modified.
function prop.mt:mutable()
	return self._set ~= nil
end

-- negate(value) -> boolean | nil
-- Private Function
-- Negates the current value. Values are modified as follows:
--
-- * `boolean`	- Switch between `true` and `false`
-- * `nil`		- Switches to `true`
-- * <other>	- Switches to `nil`.
-- Parameters:
-- * `value`	- The value to negate.
--
-- Returns:
--
local function negate(value)
	if value == nil then					-- `nil` gets toggled to `true`
		value = true
	elseif type(value) ~= "boolean" then	-- non-booleans get toggle to nil
		value = nil
	else									-- flip the boolean
		value = not value
	end
	return value
end

--- cp.prop:toggle() -> boolean | nil
--- Method
--- Toggles the current value. Values are modified as follows:
---
--- * `boolean`	- Switch between `true` and `false`
--- * `nil`		- Switches to `true`
--- * <other>	- Switches to `nil`.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The new value.
---
--- Notes:
--- * If the value is immutable, an error will be thrown.
--- * If you toggle a non-boolean parameter twice, it will end up set to `true`.
function prop.mt:toggle()
	return self:set(negate(self:get()))
end

--- cp.prop:watch(watchFn[, notifyNow]) -> cp.prop
--- Method
--- Adds the watch function to the value. When the value changes, watchers are notified by calling the function, passing in the current value as the first parameter. If property is bound to an owner, the owner is the second parameter.
---
--- Parameters:
--- * `watchFn`		- The watch function, with the signature `function(newValue, owner)`.
--- * `notifyNow`	- The function will be triggered immediately with the current state.  Defaults to `false`.
--- * `uncloned`	- If `true`, the watch function will not be attached to any clones of this prop.
---
--- Returns:
--- * `cp.prop`		- The same `cp.prop` instance
--- * `function`	- The watch function, which can be passed to [unwatch](#unwatch) to stop watching.
---
--- Notes:
--- * You can watch immutable values. Wrapped `cp.prop` instances may not be immutable, and any changes to them will cause watchers to be notified up the chain.
function prop.mt:watch(watchFn, notifyNow, uncloned)
	local watchers = nil
	if uncloned then
		if not self._watchersUncloned then
			self._watchersUncloned = {}
		end
		watchers = self._watchersUncloned
	else
		if not self._watchers then
			self._watchers = {}
		end
		watchers = self._watchers
	end
	watchers[#watchers + 1] = {fn = watchFn}
	if notifyNow then
		self:update()
	end
	return self, watchFn
end

local function _unwatch(watchers, watchFn)
	if watchers then
		for i,watcher in ipairs(watchers) do
			if watcher.fn == watchFn then
				table.remove(watchers, i)
				return true
			end
		end
	end
	return false
end

--- cp.prop:unwatch(watchFn) -> boolean
--- Method
--- Removes the specified watch method as a watcher, if present. An example of adding and removing a watch:
---
--- ```lua
--- local prop, watcher = prop.TRUE():watch(function(value) print tostring(value) end)
--- prop:unwatch(watcher) == true
--- ```
---
--- Parameters:
--- * `watchFn`		- The original watch function to remove. Must be the same instance that was added.
--- * `notifyNow`	- The function will be triggered immediately with the current state.  Defaults to `false`.
---
--- Returns:
--- * `cp.prop`		- The same `cp.prop` instance
--- * `function`	- The watch function, which can be passed to [unwatch](#unwatch) to stop watching.
---
--- Notes:
--- * You can watch immutable values. Wrapped `cp.prop` instances may not be immutable, and any changes to them will cause watchers to be notified up the chain.
function prop.mt:unwatch(watchFn)
	return _unwatch(self._watchers, watchFn) or _unwatch(self._watchersUncloned)
end

--- cp.prop:update() -> value
--- Method
--- Forces an update of the property and notifies any watchers if it has changed.
---
--- Parameters:
--- * None
---
--- Returns
--- * The current value of the property.
function prop.mt:update()
	local value = self:get()
	self:_notify(value)
	return value
end

-- cp.prop:_clone() -> cp.prop
-- Method
-- The default function performing a clone operation. This can be overridden by providing a `cloneFn` to `cp.prop.new(...)`.
function prop.mt:_clone()
	-- create a new instance
	local clone = prop.new(self._get, self._set, self._clone)

	-- copy the owner, if present
	clone._owner = self:owner()
	
	-- copy the watchers, if present
	if self._watchers then
		clone._watchers = fnutils.copy(self._watchers)
	end
	
	return clone
end

--- cp.prop:clone() -> cp.prop
--- Method
--- Returns a new copy of the property.
---
--- Parameters:
--- * None
---
--- Returns:
--- * New `cp.prop`.
function prop.mt:clone()
	local clone = nil
	if self._clone then
		return self:_clone()
	else
		error "No `_clone` method is available."
	end
end

local function evaluate(something)
	if type(something) == "function" or prop.is(something) then
		return something()
	else
		return something
	end
end

local function watchProps(watcher, ...)
	local watcherFn = function() watcher:update() end
	-- loop through the other props
	for _, p in ipairs(table.pack(...)) do
		if prop.is(p) then
			p:watch(watcherFn)
		end
	end
end

--- cp.prop:EQUALS() -> cp.prop <boolean; read-only>
--- Method
--- Returns a new property comparing this property to `something`.
---
--- Parameters:
--- * `something`	- A value, a function or a `cp.prop` to compare to.
---
--- Returns:
--- * New, read-only `cp.prop` which will be `true` if this property is equal to `something`.
function prop.mt:EQUALS(something)
	local left = self
	
	-- create the property
	local result = prop.new(function()
		return evaluate(left) == evaluate(something)
	end)
	
	-- add watchers
	watchProps(result, left, something)

	return result
end

--- cp.prop:EQ() -> cp.prop <boolean; read-only>
--- Method
--- Synonym for [EQUALS](#equals).
---
--- Parameters:
--- * `something`	- A value, a function or a `cp.prop` to compare to.
---
--- Returns:
--- * New, read-only `cp.prop` which will be `true` if this property is equal to `something`.
prop.mt.EQ = prop.mt.EQUALS

--- cp.prop:BELOW() -> cp.prop <boolean; read-only>
--- Method
--- Returns a new property comparing this property to `something`.
---
--- Parameters:
--- * `something`	- A value, a function or a `cp.prop` to compare to.
---
--- Returns:
--- * New, read-only `cp.prop` which will be `true` if this property is less than `something`.
function prop.mt:BELOW(something)
	local left = self
	
	-- create the property
	local result = prop.new(function()
		return evaluate(left) < evaluate(something)
	end)
	
	-- add watchers
	watchProps(result, left, something)
	
	return result
end

--- cp.prop:ABOVE() -> cp.prop <boolean; read-only>
--- Method
--- Returns a new property comparing this property to `something`.
---
--- Parameters:
--- * `something`	- A value, a function or a `cp.prop` to compare to.
---
--- Returns:
--- * New, read-only `cp.prop` which will be `true` if this property is greater than `something`.
function prop.mt:ABOVE(something)
	local left = self

	-- create the property
	local result = prop.new(function()
		return evaluate(left) > evaluate(something)
	end)

	-- add watchers
	watchProps(result, left, something)

	return result
end
	
--- cp.prop:ATMOST() -> cp.prop <boolean; read-only>
--- Method
--- Returns a new property comparing this property to `something`.
---
--- Parameters:
--- * `something`	- A value, a function or a `cp.prop` to compare to.
---
--- Returns:
--- * New, read-only `cp.prop` which will be `true` if this property is less than or equal to `something`.
function prop.mt:ATMOST(something)
	local left = self

	-- create the property
	local result = prop.new(function()
		return evaluate(left) <= evaluate(something)
	end)

	-- add watchers
	watchProps(result, left, something)

	return result
end

--- cp.prop:ATLEAST() -> cp.prop <boolean; read-only>
--- Method
--- Returns a new property comparing this property to `something`.
---
--- Parameters:
--- * `something`	- A value, a function or a `cp.prop` to compare to.
---
--- Returns:
--- * New, read-only `cp.prop` which will be `true` if this property is less than or equal to `something`.
function prop.mt:ATLEAST(something)
	local left = self

	-- create the property
	local result = prop.new(function()
		return evaluate(left) >= evaluate(something)
	end)

	-- add watchers
	watchProps(result, left, something)

	return result
end

-- Notifies registered watchers in the array if the value has changed since last notification.
local function _notifyWatchers(watchers, value, owner)
	if watchers then
		for _,watcher in ipairs(watchers) do
			if watcher.lastValue ~= value then
				watcher.lastValue = value
				watcher.fn(value, owner)
			end
		end
	end
end

-- cp.prop:_notify(value) -> nil
-- Method
-- Notifies all watchers of the current value if it has changed since the last notification.
--
-- Parameters:
-- * `value`	- The current value of the property.
--
-- Returns:
-- * Nothing
function prop.mt:_notify(value)
	-- make sure we aren't already notifying
	if self._notifying then
		self._doUpdate = true
		return
	end
	
	if self._watchers or self._watchersUncloned then
		self._notifying = true
		local owner = self:owner()
		_notifyWatchers(self._watchersUncloned, value, owner)
		_notifyWatchers(self._watchers, value, owner)
		self._notifying = nil
		-- check if a 'set' happened during the notification cycle.
		if self._doSet then
			self._doSet = nil
			self._doUpdate = nil
			self:set(self._newValue)
			self._newValue = nil
		elseif self._doUpdate then
			self._doUpdate = nil
			self:update()
		end
	end
end

-- Displays the `cp.prop` instance as a string.
function prop.mt:__tostring()
	return string.format("is #%d: %s", self._id, self:value())
end

-- Allows the prop to be called directly.
prop.mt.__call = function(target, owner, newValue, quiet)
	if not target._owner or target._owner ~= owner then
		-- no owner provided, so shift the parameters across
		quiet = newValue
		newValue = owner
	end
	return target:value(newValue, quiet)
end

--- cp.prop.new(getFn, setFn) --> cp.prop
--- Constructor
--- Creates a new `prop` value, with the provided `get` and `set` functions.
---
--- Parameters:
--- * `getFn`		- The function that will get called to retrieve the current value.
--- * `setFn`		- (optional) The function that will get called to set the new value.
--- * `cloneFn`		- (optional) The function that will get called when cloning the property. 
---
--- Returns:
--- * The new `cp.prop` instance.
---
--- Notes:
--- * `getFn` signature: `function([owner]) -> anything`
--- ** `owner`		- If this is attached as a method, the owner table is passed in.
--- * `setFn` signature: `function(newValue[, owner])`
--- ** `newValue`	- The new value to store.
--- ** `owner`		- If this is attached as a method, the owner table is passed in.
--- * `cloneFn` signature: `function(prop) -> new cp.prop`
--- * This can also be executed by calling the module directly. E.g. `require('cp.prop')(myGetFunction)`
function prop.new(getFn, setFn, cloneFn)
	assert(getFn ~= nil and type(getFn) == "function", "The 'getFn' must be a function.")
	assert(setFn == nil or type(setFn) == "function", "The 'setFn' must be a function if provided.")
	assert(cloneFn == nil or type(cloneFn) == "function", "The 'cloneFn' must be a function if provided.")
	local o = {
		_id			= nextId(),
		_get		= getFn,
		_set		= setFn,
		_clone		= cloneFn,
	}
	return setmetatable(o, prop.mt)
end

--- cp.prop.THIS([initialValue]) -> cp.prop
--- Function
--- Returns a new `cp.prop` instance which will cache a value internally. It will default to the value of the `initialValue`, if provided.
---
--- Parameters:
--- * `initialValue`	- The initial value to set it to (optional).
---
--- Returns:
--- * a new `cp.prop` instance.
function prop.THIS(initialValue)
	local value = initialValue
	local get = function() return value end
	local set = function(newValue) value = newValue end
	local clone = function(self)
		local result = prop.THIS(value)
		result._owner = self:owner()
		return result
	end
	return prop.new(get, set, clone)
end

--- cp.prop.IMMUTABLE(propValue) -- cp.prop
--- Function
--- Returns a new `cp.prop` instance which will not allow the wrapped value to be modified.
---
--- Parameters:
--- * `propValue`		- The `cp.prop` value to wrap.
---
--- Returns:
--- * a new `cp.prop` instance which cannot be modified.
---
--- Note:
--- * The original `propValue` can still be modified (if appropriate) and watchers of the immutable value will be notified when it changes.
function prop.IMMUTABLE(propValue)
	local immutable = prop.new(function() return propValue:get() end)
	propValue:watch(function() immutable:update() end)
	return immutable
end

--- cp.prop:IMMUTABLE() -- cp.prop
--- Method
--- Returns a new `cp.prop` instance wrapping this property which will not allow it to be modified.
---
--- Parameters:
--- * `propValue`		- The `cp.prop` value to wrap.
---
--- Returns:
--- * a new `cp.prop` instance which cannot be modified.
---
--- Note:
--- * The original property can still be modified (if appropriate) and watchers of the immutable value will be notified when it changes.
prop.mt.IMMUTABLE = prop.IMMUTABLE

--- cp.prop.TRUE() -> cp.prop
--- Function
--- Returns a new `cp.prop` which will cache internally, initially set to `true`.
---
--- Parameters:
--- * None
---
--- Returns:
--- * a `cp.prop` instance defaulting to `true`.
function prop.TRUE()
	return prop.THIS(true)
end


--- cp.prop.FALSE() -> cp.prop
--- Function
--- Returns a new `cp.prop` which will cache internally, initially set to `false`.
---
--- Parameters:
--- * None
---
--- Returns:
--- * a `cp.prop` instance defaulting to `false`.
function prop.FALSE()
	return prop.THIS(false)
end

--- cp.prop.NOT(propValue) -> cp.prop
--- Function
--- Returns a new `cp.prop` which negates the provided `propValue`. Values are negated as follows:
---
--- * `boolean`	- Switch between `true` and `false`
--- * `nil`		- Switches to `true`
--- * <other>	- Switches to `nil`.
---
--- Parameters:
--- * `propValue`		- Another `cp.prop` instance.
---
--- Returns:
--- * a `cp.prop` instance negating the `propValue`.
---
--- Notes:
--- * If the `propValue` is mutable, you can set the `NOT` property value and the underlying value will be set to the negated value. Be aware that the same negation rules apply when setting as when getting.
function prop.NOT(propValue)
	if not prop.is(propValue) then error "Expected a `cp.prop` at argument #1" end
	local notProp = prop.new(
		function() return negate(propValue:get()) end,
		function(newValue) propValue:set(negate(newValue)) end
	)
	-- notify the 'not' watchers if the original value changes.
	propValue:watch(function(value) notProp:update() end)
	return notProp
end

--- cp.prop:NOT() -> cp.prop
--- Method
--- Returns a new `cp.prop` which negates the current value. Values are negated as follows:
---
--- * `boolean`	- Switch between `true` and `false`
--- * `nil`		- Switches to `true`
--- * <other>	- Switches to `nil`.
---
--- Parameters:
--- * None
---
--- Returns:
--- * a `cp.prop` instance negating the current instance.
---
--- Notes:
--- * If this property is mutable, you can set the `NOT` property value and this property will be set to the negated value. Be aware that the same negation rules apply when setting as when getting.
prop.mt.NOT = prop.NOT

-- cp.prop._watchAndOr(andOrProp, props) -> cp.prop
-- Private Function
-- Private function which will watch all props in `...` and update the `andOrProp` when they change.
--
-- Parameters:
-- * `andOrProp`	- The property that will get updated
-- * `props`		- The list of properties being watched.
--
-- Returns:
-- * The `andOrProp`.
local function _watchAndOr(andOrProp, props)
	local watcher = function(value) andOrProp:update() end
	for i,p in ipairs(props) do
		if not prop.is(p) then error(string.format("Expected a `cp.prop` at argument #%d", i)) end
		p:watch(watcher, false, true)
	end
	return andOrProp
end

--- cp.prop.AND(...) -> cp.prop
--- Function
--- Returns a new `cp.prop` which will be `true` if all `cp.prop` instances passed into the function return a `truthy` value.
---
--- Parameters:
--- * `...`		- The list of `cp.prop` instances to 'AND' together.
---
--- Returns:
--- * a `cp.prop` instance.
---
--- Notes:
--- * The value of this instance will resolve by lazily checking the `value` of the contained `cp.prop` instances in the order provided. The first `falsy` value will be returned. Otherwise the last `truthy` value is returned.
--- * The instance is **immutable**.
--- * Once you have created an 'AND', you cannot 'OR' as a method. Eg, this will fail: `prop.TRUE():AND(prop:FALSE()):OR(prop.TRUE())`. This is to avoid ambiguity as to whether the 'AND' or 'OR' takes precedence. Is it `(true and false) or true` or `true and (false or true)`?.
--- * To combine 'AND' and 'OR' values, group them together when combining. Eg:
--- ** `(true and false) or true`: `prop.OR( prop.TRUE():AND(prop.FALSE()), prop.TRUE() )`
--- ** `true and (false or true)`: `prop.TRUE():AND( prop.FALSE():OR(prop.TRUE()) )`
function prop.AND(...)
	local props = table.pack(...)
	local andProp = prop.new(
		function()
			local value = false
			for _,p in ipairs(props) do
				value = p:get()
				if not isTruthy(value) then
					return value
				end
			end
			return value
		end,
		nil, -- no 'set' function
		function(self)
			local clone = prop.mt._clone(self)
			return _watchAndOr(clone, props)
		end
	)
	_watchAndOr(andProp, props)
	andProp.OR = function() error("Unable to 'OR' an 'AND'.") end
	return andProp
end

--- cp.prop:AND(...) -> cp.prop
--- Method
--- Returns a new `cp.prop` which will be `true` if this and all other `cp.prop` instances passed into the function return `true`.
---
--- Parameters:
--- * `...`		- The list of `cp.prop` instances to 'AND' together.
---
--- Returns:
--- * a `cp.prop` instance.
---
--- Notes:
--- * See the [AND Function](#and) for more details
prop.mt.AND = prop.AND

--- cp.prop.OR(...) -> cp.prop
--- Function
--- Returns a new `cp.prop` which will return the first 'truthy' value provided by one of the provided properties. Otherwise, returns the last 'falsy' value.
---
--- Parameters:
--- * `...`		- The list of `cp.prop` instances to 'OR' together.
---
--- Returns:
--- * a `cp.prop` instance.
---
--- Notes:
--- * The value of this instance will resolve by lazily checking the `value` of the contained `cp.prop` instances in the order provided. If any return `true`, no further instances will be checked.
--- * The instance is immutable, since there is no realy way to flip the component values of an 'OR' in a way that makes sense.
--- * Once you have created an 'OR', you cannot 'AND' as a method. Eg, this will fail: `prop.TRUE():OR(prop:FALSE()):AND(prop.TRUE())`. This is to avoid ambiguity as to whether the 'OR' or 'AND' takes precedence. Is it `(true or false) and true` or `true or (false and true)`?.
--- * To combine 'AND' and 'OR' values, group them together when combining. Eg:
--- ** `(true or false) and true`: `prop.AND( prop.TRUE():OR(prop.FALSE()), prop.TRUE() )`
--- ** `true or (false and true)`: `prop.TRUE():OR( prop.FALSE():AND(prop.TRUE()) )`
function prop.OR(...)
	local props = table.pack(...)
	local orProp = prop.new(
		function()
			local value = false
			for _,p in ipairs(props) do
				value = p:get()
				if isTruthy(value) then
					return value
				end
			end
			return value
		end,
		nil, -- no 'set' function
		function(self)
			local clone = prop.mt._clone(self)
			return _watchAndOr(clone, props)
		end
	)
	_watchAndOr(orProp, props)
	orProp.AND = function() error("Unable to 'AND' an 'OR'.") end
	return orProp
end

--- cp.prop:OR(...) -> cp.prop
--- Method
--- Returns a new `cp.prop` which will be `true` if this or any `cp.prop` instance passed into the function returns `true`.
---
--- Parameters:
--- * `...`		- The list of `cp.prop` instances to 'OR' together.
---
--- Returns:
--- * a `cp.prop` instance.
---
--- Notes:
--- * See [OR Function](#or) for more details.
prop.mt.OR = prop.OR

-- cp.prop.applyAll(target, ...) -> table
-- Function
-- Copies and binds all 'method' properties on the source tables passed in to the `target` table. E.g.:
--
-- ```lua
-- local source, target = {}, {}
-- source.isMethod = prop.TRUE():bind(source)
-- source.isFunction = prop.TRUE()
-- prop.bindAll(target, source)
-- target:isMethod() == true
-- target.isFunction() -- error. The function was not copied.
-- ```
--
-- The original `prop` methods on the source 
-- 
-- Parameters:
-- * `target`	- The target table to copy the methods into.
-- * `...`		- The list of source tables to copy and bind methods from
--
-- Returns:
-- * The target
local function rebind(target, ...)
	local sources = table.pack(...)
	for i,source in ipairs(sources) do
		for k,v in pairs(source) do
			if target[k] == nil and prop.is(v) then
				if v:owner() == source then
					-- it's a bound method. rebind.
					target[k] = v:bind(target)
				end
			end
		end
	end
end

--- cp.prop.extend(target, source) -> table
--- Function
--- Makes the `target` extend the `source`. It will copy all bound properties on the source table into the target, rebinding it to the target table. Other keys are inherited via the metatable.
---
--- Parameters:
--- * `target`	- The target to extend
--- * `source`	- The source to extend from
---
--- Returns:
--- * The `target`, now extending the `source`.
function prop.extend(target, source)
	rebind(target, source)
	return setmetatable(target, {__index = source})
end

return setmetatable(prop, { __call = function(_, ...) return prop.new(...) end })