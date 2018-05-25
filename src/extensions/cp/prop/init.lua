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
--- propValue() == true     -- `value` is still true
--- propValue(false) == false   -- now `value` is false
--- ```
---
--- ### 2. Togglable
--- A `prop` comes with toggling built in - as long as the it has a `set` function. Continuing from the last example:
---
--- ```lua
--- propValue:toggle()  -- `value` went from `false` to `true`.
--- ```
---
---  **Note:** Toggling a non-boolean value will flip it to `nil` and a subsequent toggle will make it `true`. See the [toggle method](#toggle) for more details.
---
--- ### 3. Watchable
--- Interested parties can 'watch' the `prop` value to be notified of changes. Again, continuing on:
---
--- ```lua
--- propValue:watch(function(newValue) print "New Value: "...newValue) end) -- prints "New Value: true" immediately
--- propValue(false)    -- prints "New Value: false"
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
--- isImmutable:toggle()    -- results in an `error` being thrown
--- isImmutable:watch(function(newValue) print "isImmutable changed to "..newValue end)
--- propValue:toggle()      -- prints "isImmutable changed to false"
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
--- owner:isMethod()                -- success!
--- owner.isMethod()                -- also works - will still pass in the bound owner.
--- owner.isMethod:owner() == owner -- is true~
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
--- johnDoe:name()          -- Throws an error because `person` is the owner, not `johnDoe`.
--- johnDoe.name() == nil   -- Works, but will return `nil` because "John Doe" is applied to the new table, not `person`
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
---
--- # Tables
---
--- Because tables are copied by reference rather than by value, changes made inside a table will not necessarily trigger an update when setting a value with an updated table value. By default, tables are simply passed in and out without modification. You can nominate for a property to make copies of tables (not userdata) when getting or setting, which effectively isolates the value being stored from outside modification. This can be done with the [deepTable](#deepTable) and[shallowTable](#shallowTable) methods. Below is an example of them in action:
---
--- ```lua
--- local value = { a = 1, b = { c = 1 } }
--- local valueProp = prop.THIS(value)
--- local deepProp = prop.THIS(value):deepTable()
--- local shallowProp = prop.THIS(value):shallowTable()
---
--- -- print a message when the prop value is updated
--- valueProp:watch(function(v) print("value: a = " .. v.a ..", b.c = ".. v.b.c ) end)
--- deepProp:watch(function(v) print("deep: a = " .. v.a ..", b.c = ".. v.b.c ) end)
--- shallowProp:watch(function(v) print("shallow: a = " .. v.a ..", b.c = ".. v.b.c ) end)
---
--- -- change the original table:
--- value.a             = 2
--- value.b.c           = 2
---
--- valueProp().a       == 2    -- modified
--- valueProp().b.c     == 2    -- modified
--- shallowProp().a     == 1    -- top level is copied
--- shallowProp().b.c   == 2    -- child tables are referenced
--- deepProp().a        == 1    -- top level is copied
--- deepProp().b.c      == 1    -- child tables are copied as well
---
--- -- get the 'value' property
--- value = valueProp()         -- returns the original value table
---
--- value.a             = 3     -- updates the original value table `a` value
--- value.b.c           = 3     -- updates the original `b` table's `c` value
---
--- valueProp(value)            -- nothing is printed, since it's still the same table
---
--- valueProp().a       == 3    -- still referencing the original table
--- valueProp().b.c     == 3    -- the child is still referenced too
--- shallowProp().a     == 1    -- still unmodified after the initial copy
--- shallowProp().b.c   == 3    -- still updated, since `b` was copied by reference
--- deepProp().a        == 1    -- still unmodified after initial copy
--- deepProp().b.c      == 1    -- still unmodified after initial copy
---
--- -- get the 'deep copy' property
--- value = deepProp()          -- returns a new table, with all child tables also copied.
---
--- value.a             = 4     -- updates the new table's `a` value
--- value.b.c           = 4     -- updates the new `b` table's `c` value
---
--- deepProp(value)             -- prints "deep: a = 4, b.c = 4"
---
--- valueProp().a       == 3    -- still referencing the original table
--- valueProp().b.c     == 3    -- the child is still referenced too
--- shallowProp().a     == 1    -- still unmodified after the initial copy
--- shallowProp().b.c   == 3    -- still referencing the original `b` table.
--- deepProp().a        == 4    -- updated to the new value
--- deepProp().b.c      == 4    -- updated to the new value
---
--- -- get the 'shallow' property
--- value = shallowProp()       -- returns a new table with top-level keys copied.
---
--- value.a             = 5     -- updates the new table's `a` value
--- value.b.c           = 5     -- updates the original `b` table's `c` value.
---
--- shallowProp(value)          -- prints "shallow: a = 5, b.c = 5"
---
--- valueProp().a       == 3    -- still referencing the original table
--- valueProp().b.c     == 5    -- still referencing the original `b` table
--- shallowProp().a     == 5    -- updated to the new value
--- shallowProp().b.c   == 5    -- referencing the original `b` table, which was updated
--- deepProp().a        == 4    -- unmodified after the last update
--- deepProp().b.c      == 4    -- unmodified after the last update
--- ```
---
--- So, a little bit tricky. The general rule of thumb is:
--- 1. If working with immutable objects, use the default 'value' value copy, which preserves the original.
--- 2. If working with an array of immutible objects, use the 'shallow' table copy.
--- 3. In most other cases, use a 'deep' table copy.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log             = require("hs.logger").new("prop")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local inspect           = require("hs.inspect")
local fnutils           = require("hs.fnutils")

local format            = string.format
local insert            = table.insert

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local prop = {}

-- The metatable
prop.mt = {}
prop.mt.__index = prop.mt

local ids = 0

local DEEP_TABLE = "deep"
local SHALLOW_TABLE = "shallow"

local function nextId()
    ids = ids + 1
    return ids
end

-- Returns `true` if the value is `truthy` - either `true` or not `nil`.
local function isTruthy(value)
    return value ~= nil and value ~= false
end

-- prepareValue(value[, tableCopy[, skipMetatable]]) -> table
-- Function
-- Clones a provided table
--
-- Parameters:
-- * `value`            - The value to clone
-- * `tableCopy`        - Either `nil`, `DEEP_TABLE` or `SHALLOW_TABLE`.
-- * `skipMetatable`    - If `true`, any metatable on the original value will be skipped. Defaults to `false`.
local function prepareValue(value, tableCopy, skipMetatable)
    if tableCopy == nil or value == nil or type(value) ~= "table" then
        return value
    end

    local result = {}
    for k,v in pairs(value) do
        if tableCopy == DEEP_TABLE and type(v) == "table" then
            v = prepareValue(v, tableCopy, skipMetatable)
        end
        result[k] = v
    end

    if not skipMetatable then
        result = setmetatable(result, getmetatable(value))
    end

    return result
end

local function monitorProps(watcher, ...)
    -- loop through the other props
    for _, p in ipairs(table.pack(...)) do
        if prop.is(p) then
            watcher:monitor(p)
        end
    end
end

-- private export for testing.
prop._prepareValue = prepareValue

--- cp.prop.is(value) -> boolean
--- Function
--- Checks if the `value` is an instance of a `cp.prop`.
---
--- Parameters:
---  * `value`  - The value to check.
---
--- Returns:
---  * `true` if the value is an instance of `cp.prop`.
function prop.is(value)
    if value and type(value) == "table" then
        local mt = getmetatable(value)
        return mt == prop.mt
    end
    return false
end

--- cp.prop:id() -> number
--- Method
--- Returns the current ID.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The ID value.
function prop.mt:id()
    return self._id
end

--- cp.prop:label([newLabel]) -> string | cp.prop
--- Method
--- Gets and sets the property label. This is human-readable text describing the `cp.prop`.
--- It is used when converting the prop to a string, for example.
---
--- Parameters:
--- * newLabel      - (optional) if provided, this will be the new label.
---
--- Returns:
--- * Either the existing label, or the `cp.prop` itself if a new label was provided.
function prop.mt:label(newLabel)
    if newLabel then
        self._label = newLabel
        return self
    else
        return self._label
    end
end

--- cp.prop:deepTable([skipMetatable]) -> prop
--- Method
--- This can be called once to enable deep copying of `table` values. By default,
--- `table`s are simply passed in and out. If a sub-key of a table changes, no change
--- will be registered when setting.
---
--- Parameters:
---  * `skipMetatable`  - If set to `true`, copies will _not_ copy the metatable into the new tables.
---
--- Returns:
---  * The `cp.prop` instance.
---
--- Notes:
---  * See [shallowTable](#shallowTable).
function prop.mt:deepTable(skipMetatable)
    if not self:mutable() then
        error("This property is immutable.")
    end
    if self._tableCopy then
        error("Already set to "..self._tableCopy.." clone.")
    end
    local value = self:get()
    self._tableCopy = DEEP_TABLE
    self._skipMetatable = skipMetatable
    self:set(value)
    return self
end

--- cp.prop:shallowTable(skipMetatable) -> prop
--- Method
--- This can be called once to enable shallow cloning of `table` values. By default,
--- `table`s are simply passed in and out. If a sub-key of a table changes, no change
--- will be registered when setting.
---
--- Parameters:
---  * `skipMetatable`  - If set to `true`, the metatable will _not_ be copied to the new table.
---
--- Returns:
---  * The `cp.prop` instance.
---
--- Notes:
---  * See [deepTable](#deepTable).
-- TODO: David - skipMetatable is currently unused?
function prop.mt:shallowTable(skipMetatable) -- luacheck: ignore
    if not self:mutable() then
        error("This property is immutable.")
    end
    if self._tableCopy then
        error("Already set to "..self._tableCopy.." clone.")
    end
    local value = self:get()
    self._tableCopy = SHALLOW_TABLE
    self:set(value)
    return self
end

local UNCACHED = {}

--- cp.prop:cached() -> prop
--- Method
--- This can be called once to enable caching of the result inside the `prop`.
--- This can help with performance, but if there are other ways of modifying
--- the original value outside the prop, it will potentially return stale values.
---
--- You can force a reload via the [update](#update) method.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.prop` instance.
function prop.mt:cached()
    self._cached = true
    self._cachedValue = UNCACHED
    return self
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
---  * `newValue`   - The new value to set the instance to.
---
--- Returns:
---  * The current boolean value.
---
--- Notes:
---  * If you need to set the property to `nil`, use the [set method](#set), otherwise it will be ignored.
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
---  * None
---
--- Returns
---  * The current value.
function prop.mt:get()
    local value = self._cachedValue
    if not self._cached or self._cachedValue == UNCACHED then
        value = prepareValue(self._get(self._owner, self), self._tableCopy, self._skipMetatable)
        self._cachedValue = value
    end
    return value
end

--- cp.prop:set(newValue) -> value
--- Method
--- Sets the property to the specified value. Watchers will be notified if the value has changed.
---
--- Parameters:
---  * `newValue`   - The new value to set. May be `nil`.
---
--- Returns:
---  * The current value of the prop. May not be the same as `newValue`.
function prop.mt:set(newValue)
    if not self._set then
        error(format("The '%s' property cannot be modified.", self))
    end
    newValue = prepareValue(newValue, self._tableCopy, self._skipMetatable)
    if self._notifying then -- defer the update
        self._doSet = true
        self._newValue = newValue
        return newValue
    else -- update now
        if self._cached then
            self._cachedValue = newValue
        end
        self._set(newValue, self._owner, self)
        local actualValue = self:get()
        self:_notify(actualValue)
        return actualValue
    end
end

--- cp.prop:clear() -> nil
--- Method
--- Clears the property. Watchers will be notified if the value has changed.
---
--- Parameters:
---  * None
---
--- Returns:
---  * nil
function prop.mt:clear()
    return self:set(nil)
end

--- cp.prop:bind(owner, [key]) -> cp.prop
--- Method
--- Binds the property to the specified owner. Once bound, it cannot be changed.
--- Optionally, a key can be provided which will assign the `cp.prop` to the owner using that key.
--- If the `cp.prop` does not have a label, the key will be used as the label.
---
--- Parameters:
---  * `owner`  - The owner to attach to.
---  * `key`    - If provided, the property will be bound to the specified key.
---
--- Returns:
---  * the `cp.prop`
---
--- Notes:
---  * Throws an `error` if the new owner is `nil`.
---  * Throws an `error` if the owner already has a property with the name provided in `key`.
---  * Throws an `error` if the `key` is not a string value.
function prop.mt:bind(owner, key)
    assert(owner ~= nil, "The owner must not be nil.")
    self._owner = owner

    if key then
        if type(key) ~= "string" then
            error(format("The key must be a string: %s", inspect(key)))
        end
        local existing = owner[key]
        if not existing then
            owner[key] = self
        elseif existing ~= self then
            error(format("The owner already has a property named '%s'", key))
        end

        if not self._label then
            self._label = key
        end
        if not self._aliases then
            self._aliases = {}
        end
        insert(self._aliases, key)
    end
    return self
end

--- cp.prop:owner() -> table
--- Method
--- If this is a 'method', return the table instance the method is attached to.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The owner table, or `nil`.
function prop.mt:owner()
    return self._owner
end

--- cp.prop:mutable() -> boolean
--- Method
--- Checks if the `cp.prop` can be modified.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if the value can be modified.
function prop.mt:mutable()
    return self._set ~= nil
end

-- negate(value) -> boolean | nil
-- Private Function
-- Negates the current value. Values are modified as follows:
--
-- * `boolean`  - Switch between `true` and `false`
-- * `nil`      - Switches to `true`
-- * <other>    - Switches to `nil`.
-- Parameters:
-- * `value`    - The value to negate.
--
-- Returns:
--
local function negate(value)
    if value == nil then                    -- `nil` gets toggled to `true`
        value = true
    elseif type(value) ~= "boolean" then    -- non-booleans get toggle to nil
        value = nil
    else                                    -- flip the boolean
        value = not value
    end
    return value
end

--- cp.prop:toggle() -> boolean | nil
--- Method
--- Toggles the current value. Values are modified as follows:
---
---  * `boolean`    - Switch between `true` and `false`
---  * `nil`        - Switches to `true`
---  * <other>  - Switches to `nil`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The new value.
---
--- Notes:
---  * If the value is immutable, an error will be thrown.
---  * If you toggle a non-boolean parameter twice, it will end up set to `true`.
function prop.mt:toggle()
    return self:set(negate(self:get()))
end

-- private unique marker for the 'lastValue' of new watchers.
local NOTHING = {}

--- cp.prop:watch(watchFn[, notifyNow]) -> cp.prop, function
--- Method
--- Adds the watch function to the value. When the value changes, watchers are notified by calling the function. The function should have the following signature:
---
--- ```lua
--- function(value, owner, prop)
--- ```
---  * `value`  - The new value of the property
---  * `owner`  - The property owner. May be `nil`.
---  * `prop`   - The property itself.
---
--- Parameters:
---  * `watchFn`        - The watch function, with the signature `function(newValue, owner)`.
---  * `notifyNow`  - The function will be triggered immediately with the current state.  Defaults to `false`.
---  * `uncloned`   - If `true`, the watch function will not be attached to any clones of this prop.
---
--- Returns:
---  * `cp.prop`        - The same `cp.prop` instance
---  * `function`   - The watch function, which can be passed to [unwatch](#unwatch) to stop watching.
---
--- Notes:
---  * You can watch immutable values. Wrapped `cp.prop` instances may not be immutable, and any changes to them will cause watchers to be notified up the chain.
function prop.mt:watch(watchFn, notifyNow, uncloned)
    if not self._watchers then
        self._watchers = {}
    end
    local watchers = self._watchers

    watchers[#watchers + 1] = {fn = watchFn, uncloned = uncloned, lastValue = NOTHING}

    -- run any prewatch functions
    self:_preWatch()

    if notifyNow then -- do an immediate update.
        self:update()
    end
    return self, watchFn
end

--- cp.prop:hasWatchers() -> boolean
--- Method
--- Returns `true` if the property has any watchers.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if any watchers have been registered.
function prop.mt:hasWatchers()
    local watchers = self._watchers
    return watchers ~= nil and #watchers > 0
end

--- cp.prop:preWatch(preWatchFn) -> nil
--- Method
--- Adds a function which will be called once if any watchers are added to this prop.
--- This allows configuration, typically for watching other events, but only if
--- anything is actually watching this property value.
---
--- If the prop already has watchers, this function will be called imediately.
---
--- Parameters:
---  * `preWatchFn`     - The function to call once when the prop is watched. Has the signature `function(owner, prop)`.
---
--- Returns:
---  * Nothing
function prop.mt:preWatch(preWatchFn)
    if self:hasWatchers() then -- already watchers - just run it
        preWatchFn(self:owner())
    else -- cache them for later.
        if not self._preWatchers then
            self._preWatchers = {}
        end
        self._preWatchers[#self._preWatchers+1] = preWatchFn
    end
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
---  * `watchFn`        - The original watch function to remove. Must be the same instance that was added.
---
--- Returns:
---  * `true` if the function was watching and successfully removed, otherwise `false`.
function prop.mt:unwatch(watchFn)
    return _unwatch(self._watchers, watchFn)
end

local function _monitorOther(thisProp, otherProp)
    otherProp:watch(function() thisProp:update() end, false, true)
end

-- _monitored(hasWatchers) -> table
-- Private Function
-- Returns the list of monitored properties. If `hasWatchers` is false and
-- this is the first time this has been called, a `preWatch` function is added
-- to propogate new watch methods to props being monitored.
function prop.mt:_monitored(hasWatchers)
    local monitored = self.__monitored
    if not monitored then
        monitored = {}
        self.__monitored = monitored
        -- if no watchers have already been added, add a `preWatch` function
        --- to propogate the existing monitors once a real `watch` is added.
        if not hasWatchers then
            self:preWatch(function()
                for _,otherProp in pairs(monitored) do
                    _monitorOther(self, otherProp)
                end
            end)
        end
    end
    return monitored
end

--- cp.prop:monitor(...) -> cp.prop
--- Method
--- Adds an uncloned watch to the `otherProp` which will trigger an [update](#update) check in this property.
---
--- Parameters:
---  * `...`  - a list of other `cp.prop` values to monitor.
---
--- Returns:
---  * `cp.prop`    - This prop value.
function prop.mt:monitor(...)
    for i = 1,select("#", ...) do
        local otherProp = select(i, ...)
        if not prop.is(otherProp) then
            error("Item "..i.." is not a `cp.prop` instance: "..type(otherProp))
        end

        local hasWatchers = self:hasWatchers()
        local monitored = self:_monitored(hasWatchers)

        if not monitored[otherProp:id()] then
            -- log it as being monitored
            monitored[otherProp:id()] = otherProp
            if hasWatchers then
                _monitorOther(self, otherProp)
            end
        end
    end

    return self
end

--- cp.prop:update() -> value
--- Method
--- Forces an update of the property and notifies any watchers if it has changed.
---
--- Parameters:
---  * None
---
--- Returns
---  * The current value of the property.
function prop.mt:update()
    self._cachedValue = UNCACHED
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
    clone._mutated = self._mutated
    clone._original = self._original

    -- copy the watchers, if present
    if self._watchers then
        clone._watchers = fnutils.ifilter(self._watchers, function(watcher) return not watcher.uncloned end)
    end
    -- copy the pre-watchers, if present
    if self._preWatchers then
        clone._preWatchers = fnutils.copy(self._preWatchers)
    end

    return clone
end

--- cp.prop:clone() -> cp.prop
--- Method
--- Returns a new copy of the property.
---
--- Parameters:
---  * None
---
--- Returns:
---  * New `cp.prop`.
function prop.mt:clone()
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

--- cp.prop:mutate(getFn[, setFn]) -> cp.prop <anything; read-only>, function
--- Method
--- Returns a new property that is a mutation of the current one.
--- Watchers of the mutant will be if a change in the current prop causes
--- the mutation to be a new value.
---
--- The `getFn` is a function with the following signature:
---
--- ```lua
--- function(original, owner, prop) --> mutantValue
--- ```
---
---  * `originalProp`   - The original `cp.prop` being mutated.
---  * `owner`          - The owner of the mutator property, if it has been bound.
---  * `mutantProp`     - The mutant property.
---  * `mutantValue`    - The new value based off the original.
---
--- You can ignore any parameters that you don't need. Most simply use the `original` prop.
---
--- The `setFn` is optional, and is a function with the following signature:
---
--- ```lua
--- function(mutantValue, original, owner, prop) --> nil
--- ```
---
---  * `mutantValue`    - The new value being sent in.
---  * `originalProp`   - The original property being mutated.
---  * `owner`          - The owner of the mutant property, if it has been bound.
---  * `mutantProp`     - The mutant property.
---
--- Again, you can ignore any parameters that you don't need.
--- If you want to set a new value to the `original` property, you can do so.
--- It's recommended that you use `original:set(...)`, which will allow setting `nil` values.
---
--- For example:
---
--- ```lua
--- anyNumber   = prop.THIS(1)
--- isEven      = anyNumber:mutate(function(original) return original() % 2 == 0 end)
---     :watch(function(even)
---         if even() then
---             print "even"
---         else
---             print "odd"
---         end
---     end)
---
--- isEven:update()     -- prints "odd"
--- anyNumber(10)       -- prints "even"
--- isEven() == true    -- no printing
--- ```
---
--- Parameters:
---  * `mutateFn`   - The function which will mutate the value of the current property.
---
--- Returns:
---  * A new `cp.prop` which will return a mutation of the property value.
function prop.mt:mutate(getFn, setFn)
    -- create the mutant, which will pull from the original.
    local mutantGetFn = function(owner, mutant)
        local result = getFn(mutant._original, owner, mutant)
        return result
    end
    local mutantSetFn = nil
    if setFn then
        mutantSetFn = function(newValue, owner, mutant)
            setFn(newValue, mutant._original, owner, mutant)
        end
    end

    local mutant = prop.new(mutantGetFn, mutantSetFn)
    mutant._original = self
    self._mutated = true
    -- watch for changes and notify with the mutation
    mutant:monitor(self)

    return mutant
end

--- cp.prop:wrap([owner[, key]]) -> cp.prop <anything>
--- Method
--- Returns a new property that wraps this one. It will be able to get and set the same as this, and changes
--- to this property will trigger updates in the wrapper.
---
--- Parameters:
---  * `owner`  -    (optional) If provided, the wrapper will be bound to the specified owner.
---  * `key`    -    (optional) If provided, the wrapper will be assigned to the owner with the specified key.
---
--- Returns:
---  * A new `cp.prop` which wraps this property.
function prop.mt:wrap(owner, key)
    local wrapGetFn = function(_, wrapper) return wrapper._wrapped:get() end
    local wrapSetFn = self._set and function(newValue, _, wrapper) wrapper._wrapped:set(newValue) end or nil
    local wrapCloneFn = function(wrapper)
        local clone = prop.mt._clone(wrapper)
        clone._wrapped = wrapper._wrapped
        clone:monitor(clone._wrapped)
        return clone
    end

    -- Create the wrapper property
    local wrapper = prop.new(wrapGetFn, wrapSetFn, wrapCloneFn)
    wrapper._wrapped = self

    -- bind, if appropriate
    if owner then
        wrapper = wrapper:bind(owner, key)
    end

    -- watch the original
    wrapper:monitor(self)

    return wrapper
end

--- cp.prop:mirror(otherProp) -> self
--- Method
--- Configures this prop and the other prop to mirror each other's values.
--- When one changes the other will change with it. Only one prop needs to mirror.
---
--- Parameters:
--- * `otherProp`   - The other prop to mirror.
---
--- Returns:
--- The same property.
function prop.mt:mirror(otherProp)
    self:watch(function(value)
        otherProp:set(value)
    end)
    otherProp:watch(function(value)
        self:set(value)
    end)
end

--- cp.prop:IS(something) -> cp.prop <boolean; read-only>
--- Method
--- Returns a new property returning `true` if the value is equal to `something`.
---
--- Parameters:
---  * `something`  - A value, a function or a `cp.prop` to compare to.
---
--- Returns:
---  * New, read-only `cp.prop` which will be `true` if this property is equal to `something`.
function prop.mt:IS(something)
    local left = self

    -- create the property
    local result = prop.new(function()
        return evaluate(left) == evaluate(something)
    end)

    -- add watchers
    monitorProps(result, left, something)

    return result
end

--- cp.prop:EQ(something) -> cp.prop <boolean; read-only>
--- Method
--- Synonym for [IS](#is).
---
--- Parameters:
---  * `something`  - A value, a function or a `cp.prop` to compare to.
---
--- Returns:
---  * New, read-only `cp.prop` which will be `true` if this property is equal to `something`.
prop.mt.EQ = prop.mt.IS

--- cp.prop:ISNOT(something) -> cp.prop <boolean; read-only>
--- Method
--- Returns a new property returning `true` when this property is not equal to `something`.
---
--- Parameters:
---  * `something`  - A value, a function or a `cp.prop` to compare to.
---
--- Returns:
---  * New, read-only `cp.prop` which will be `true` if this property is NOT equal to `something`.
function prop.mt:ISNOT(something)
    local left = self

    -- create the property
    local result = prop.new(function()
        return evaluate(left) ~= evaluate(something)
    end)

    -- monitor the originals
    monitorProps(result, left, something)

    return result
end

--- cp.prop:NEQ(something) -> cp.prop <boolean; read-only>
--- Method
--- A synonym for [ISNOT](#isnot)
---
--- Parameters:
---  * `something`  - A value, a function or a `cp.prop` to compare to.
---
--- Returns:
---  * New, read-only `cp.prop` which will be `true` if this property is NOT equal to `something`.
prop.mt.NEQ = prop.mt.ISNOT

--- cp.prop:BELOW() -> cp.prop <boolean; read-only>
--- Method
--- Returns a new property comparing this property to `something`.
---
--- Parameters:
---  * `something`  - A value, a function or a `cp.prop` to compare to.
---
--- Returns:
---  * New, read-only `cp.prop` which will be `true` if this property is less than `something`.
function prop.mt:BELOW(something)
    local left = self

    -- create the property
    local result = prop.new(function()
        return evaluate(left) < evaluate(something)
    end)

    -- add watchers
    monitorProps(result, left, something)

    return result
end

--- cp.prop:ABOVE() -> cp.prop <boolean; read-only>
--- Method
--- Returns a new property comparing this property to `something`.
---
--- Parameters:
---  * `something`  - A value, a function or a `cp.prop` to compare to.
---
--- Returns:
---  * New, read-only `cp.prop` which will be `true` if this property is greater than `something`.
function prop.mt:ABOVE(something)
    local left = self

    -- create the property
    local result = prop.new(function()
        return evaluate(left) > evaluate(something)
    end)

    -- add watchers
    monitorProps(result, left, something)

    return result
end

--- cp.prop:ATMOST() -> cp.prop <boolean; read-only>
--- Method
--- Returns a new property comparing this property to `something`.
---
--- Parameters:
---  * `something`  - A value, a function or a `cp.prop` to compare to.
---
--- Returns:
---  * New, read-only `cp.prop` which will be `true` if this property is less than or equal to `something`.
function prop.mt:ATMOST(something)
    local left = self

    -- create the property
    local result = prop.new(function()
        return evaluate(left) <= evaluate(something)
    end)

    -- add watchers
    monitorProps(result, left, something)

    return result
end

--- cp.prop:ATLEAST() -> cp.prop <boolean; read-only>
--- Method
--- Returns a new property comparing this property to `something`.
---
--- Parameters:
---  * `something`  - A value, a function or a `cp.prop` to compare to.
---
--- Returns:
---  * New, read-only `cp.prop` which will be `true` if this property is less than or equal to `something`.
function prop.mt:ATLEAST(something)
    local left = self

    -- create the property
    local result = prop.new(function()
        return evaluate(left) >= evaluate(something)
    end)

    -- add watchers
    monitorProps(result, left, something)

    return result
end

-- Notifies registered watchers in the array if the value has changed since last notification.
local function _notifyWatchers(watchers, value, owner, theProp)
    if watchers then
        for _,watcher in ipairs(watchers) do
            if watcher.lastValue ~= value then
                watcher.lastValue = value
                local ok, result = xpcall(function() watcher.fn(value, owner, theProp) end, debug.traceback)
                if not ok then
                    log.ef("Error while notifying a watcher: %s", result)
                end
            end
        end
    end
end

-- cp.prop:_preWatch() -> nil
-- Method
-- This will run any functions added as `pre-watchers` one time, then
-- the list gets cleared. This allows some setup functions to happen
-- if/when someone is actually watching the property.
function prop.mt:_preWatch()
    if self._preWatchers then
        local preWatchers = self._preWatchers
        self._preWatchers = nil
        local owner = self:owner()
        for _,preWatcher in ipairs(preWatchers) do
            preWatcher(owner, self)
        end
    end
end

-- cp.prop:_notify(value) -> nil
-- Method
-- Notifies all watchers of the current value if it has changed since the last notification.
--
-- Parameters:
-- * `value`    - The current value of the property.
--
-- Returns:
-- * Nothing
function prop.mt:_notify(value)
    -- make sure we aren't already notifying
    if self._notifying then
        self._doUpdate = true
        return
    end

    if self._watchers then
        self._notifying = true
        local owner = self:owner()
        _notifyWatchers(self._watchers, value, owner, self)
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
    local label = self._label or format("id #%d", self._id)
    return format("%s: %s", label, self:value())
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

--- cp.prop.new(getFn, setFn, cloneFn) --> cp.prop
--- Constructor
--- Creates a new `prop` value, with the provided `get` and `set` functions.
---
--- Parameters:
---  * `getFn`      - The function that will get called to retrieve the current value.
---  * `setFn`      - (optional) The function that will get called to set the new value.
---  * `cloneFn`        - (optional) The function that will get called when cloning the property.
---
--- Returns:
---  * The new `cp.prop` instance.
---
--- Notes:
---  * `getFn` signature: `function([owner]) -> anything`
---  ** `owner`     - If this is attached as a method, the owner table is passed in.
---  * `setFn` signature: `function(newValue[, owner])`
---  ** `newValue`  - The new value to store.
---  ** `owner`     - If this is attached as a method, the owner table is passed in.
---  * `cloneFn` signature: `function(prop) -> new cp.prop`
---  * This can also be executed by calling the module directly. E.g. `require('cp.prop')(myGetFunction)`
function prop.new(getFn, setFn, cloneFn)
    assert(getFn ~= nil and type(getFn) == "function", "The 'getFn' must be a function.")
    assert(setFn == nil or type(setFn) == "function", "The 'setFn' must be a function if provided.")
    assert(cloneFn == nil or type(cloneFn) == "function", "The 'cloneFn' must be a function if provided.")
    local o = {
        _id         = nextId(),
        _get        = getFn,
        _set        = setFn,
        _clone      = cloneFn,
    }
    return setmetatable(o, prop.mt)
end

--- cp.prop.THIS([initialValue]) -> cp.prop
--- Function
--- Returns a new `cp.prop` instance which will cache a value internally. It will default to the value of the `initialValue`, if provided.
---
--- Parameters:
---  * `initialValue`   - The initial value to set it to (optional).
---
--- Returns:
---  * a new `cp.prop` instance.
function prop.THIS(initialValue)
    local get = function(_, Prop) return Prop._value end
    local set = function(newValue, _, Prop) Prop._value = newValue end
    local clone = function(self)
        local clone = prop.mt._clone(self)
        clone._value = self._value
        return clone
    end
    local result = prop.new(get, set, clone)
    result._value = initialValue
    return result
end

--- cp.prop.IMMUTABLE(propValue) -- cp.prop
--- Function
--- Returns a new `cp.prop` instance which will not allow the wrapped value to be modified.
---
--- Parameters:
---  * `propValue`      - The `cp.prop` value to wrap.
---
--- Returns:
---  * a new `cp.prop` instance which cannot be modified.
---
--- Note:
---  * The original `propValue` can still be modified (if appropriate) and watchers of the immutable value will be notified when it changes.
function prop.IMMUTABLE(propValue)
    local immutable = prop.new(function() return propValue:get() end):monitor(propValue)
    return immutable
end


--- cp.prop.NIL -> cp.prop
--- Constant
--- Returns a `cp.prop` which will always be `nil`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * a new `cp.prop` instance with a value of `nil`.
prop.NIL = prop.new(function() return nil end)

--- cp.prop:IMMUTABLE() -- cp.prop
--- Method
--- Returns a new `cp.prop` instance wrapping this property which will not allow it to be modified.
---
--- Parameters:
---  * `propValue`      - The `cp.prop` value to wrap.
---
--- Returns:
---  * a new `cp.prop` instance which cannot be modified.
---
--- Note:
---  * The original property can still be modified (if appropriate) and watchers of the immutable value will be notified when it changes.
prop.mt.IMMUTABLE = prop.IMMUTABLE

--- cp.prop.TRUE() -> cp.prop
--- Function
--- Returns a new `cp.prop` which will cache internally, initially set to `true`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * a `cp.prop` instance defaulting to `true`.
function prop.TRUE()
    return prop.THIS(true)
end


--- cp.prop.FALSE() -> cp.prop
--- Function
--- Returns a new `cp.prop` which will cache internally, initially set to `false`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * a `cp.prop` instance defaulting to `false`.
function prop.FALSE()
    return prop.THIS(false)
end

-- TODO: David, deepTable is currently not being used?
function prop.TABLE(initialValue, deepTable) -- luacheck: ignore
    local get = function(_, Prop) return Prop._value end
    local set = function(newValue, _, Prop) Prop._value = newValue end
    local clone = function(self)
        local clone = prop.mt._clone(self)
        clone._value = self._value
        return clone
    end
    local result = prop.new(get, set, clone)
    result._value = initialValue
    return result
end

--- cp.prop.NOT(propValue) -> cp.prop
--- Function
--- Returns a new `cp.prop` which negates the provided `propValue`. Values are negated as follows:
---
---  * `boolean`    - Switch between `true` and `false`
---  * `nil`        - Switches to `true`
---  * <other>  - Switches to `nil`.
---
--- Parameters:
---  * `propValue`      - Another `cp.prop` instance.
---
--- Returns:
---  * a `cp.prop` instance negating the `propValue`.
---
--- Notes:
---  * If the `propValue` is mutable, you can set the `NOT` property value and the underlying value will be set to the negated value. Be aware that the same negation rules apply when setting as when getting.
function prop.NOT(propValue)
    if not prop.is(propValue) then error "Expected a `cp.prop` at argument #1" end
    local notProp = prop.new(
        function() return negate(propValue:get()) end,
        function(newValue) return propValue:set(negate(newValue)) end
    )
    -- notify the 'not' watchers if the original value changes.
    :monitor(propValue)
    return notProp
end

--- cp.prop:NOT() -> cp.prop
--- Method
--- Returns a new `cp.prop` which negates the current value. Values are negated as follows:
---
---  * `boolean`    - Switch between `true` and `false`
---  * `nil`        - Switches to `true`
---  * <other>  - Switches to `nil`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * a `cp.prop` instance negating the current instance.
---
--- Notes:
---  * If this property is mutable, you can set the `NOT` property value and this property will be set to the negated value. Be aware that the same negation rules apply when setting as when getting.
prop.mt.NOT = prop.NOT

-- cp.prop._watchAndOr(andOrProp, props) -> cp.prop
-- Private Function
-- Private function which will watch all props in `...` and update the `andOrProp` when they change.
--
-- Parameters:
-- * `andOrProp`    - The property that will get updated
-- * `props`        - The list of properties being watched.
--
-- Returns:
-- * The `andOrProp`.
local function _watchAndOr(andOrProp, props)
    for i,p in ipairs(props) do
        if not prop.is(p) then error(format("Expected a `cp.prop` at argument #%d: %s", i, inspect(p))) end
        andOrProp:monitor(p)
    end
    return andOrProp
end

--- cp.prop.AND(...) -> cp.prop
--- Function
--- Returns a new `cp.prop` which will be `true` if all `cp.prop` instances passed into the function return a `truthy` value.
---
--- Parameters:
---  * `...`        - The list of `cp.prop` instances to 'AND' together.
---
--- Returns:
---  * a `cp.prop` instance.
---
--- Notes:
---  * The value of this instance will resolve by lazily checking the `value` of the contained `cp.prop` instances in the order provided. The first `falsy` value will be returned. Otherwise the last `truthy` value is returned.
---  * The instance is **immutable**.
---  * Once you have created an 'AND', you cannot 'OR' as a method. Eg, this will fail: `prop.TRUE():AND(prop:FALSE()):OR(prop.TRUE())`. This is to avoid ambiguity as to whether the 'AND' or 'OR' takes precedence. Is it `(true and false) or true` or `true and (false or true)`?.
---  * To combine 'AND' and 'OR' values, group them together when combining. Eg:
---  ** `(true and false) or true`: `prop.OR( prop.TRUE():AND(prop.FALSE()), prop.TRUE() )`
---  ** `true and (false or true)`: `prop.TRUE():AND( prop.FALSE():OR(prop.TRUE()) )`
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
---  * `...`        - The list of `cp.prop` instances to 'AND' together.
---
--- Returns:
---  * a `cp.prop` instance.
---
--- Notes:
---  * See the [AND Function](#and) for more details
prop.mt.AND = prop.AND

--- cp.prop.OR(...) -> cp.prop
--- Function
--- Returns a new `cp.prop` which will return the first 'truthy' value provided by one of the provided properties. Otherwise, returns the last 'falsy' value.
---
--- Parameters:
---  * `...`        - The list of `cp.prop` instances to 'OR' together.
---
--- Returns:
---  * a `cp.prop` instance.
---
--- Notes:
---  * The value of this instance will resolve by lazily checking the `value` of the contained `cp.prop` instances in the order provided. If any return `true`, no further instances will be checked.
---  * The instance is immutable, since there is no realy way to flip the component values of an 'OR' in a way that makes sense.
---  * Once you have created an 'OR', you cannot 'AND' as a method. Eg, this will fail: `prop.TRUE():OR(prop:FALSE()):AND(prop.TRUE())`. This is to avoid ambiguity as to whether the 'OR' or 'AND' takes precedence. Is it `(true or false) and true` or `true or (false and true)`?.
---  * To combine 'AND' and 'OR' values, group them together when combining. Eg:
---  ** `(true or false) and true`: `prop.AND( prop.TRUE():OR(prop.FALSE()), prop.TRUE() )`
---  ** `true or (false and true)`: `prop.TRUE():OR( prop.FALSE():AND(prop.TRUE()) )`
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
---  * `...`        - The list of `cp.prop` instances to 'OR' together.
---
--- Returns:
---  * a `cp.prop` instance.
---
--- Notes:
---  * See [OR Function](#or) for more details.
prop.mt.OR = prop.OR

-- rebind(target, source) -> table
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
-- The original `prop` methods on the source will be rebound to the target.
--
-- Parameters:
-- * `target`   - The target table to copy the methods into.
-- * `source`   - The list of source tables to copy and bind methods from
--
-- Returns:
-- * The target
local function rebind(target, source)
    local mutated = {}
    local mutants = {}
    -- rebind bound properties
    for k,v in pairs(source) do
        if target[k] == nil and prop.is(v) then
            if v:owner() == source then
                -- it's a bound method. Clone and rebind to the new target.
                local rebound = v:clone():bind(target)
                target[k] = rebound
                if v._mutated then -- it will need to be reconnected
                    mutated[v._id] = rebound
                end
                if v._original then -- it's a mutant
                    rebound._original = v._original
                    mutants[#mutants+1] = rebound
                end
            end
        end
    end
    -- reconnect mutants
    for _,mutant in ipairs(mutants) do
        local original = mutant._original
        if not original then
            error("Unable to find original of mutated property: %s", mutant)
        end
        mutant._original = mutated[original._id] or original
    end
    return target
end

--- cp.prop.extend(target, source) -> table
--- Function
--- Makes the `target` extend the `source`. It will copy all bound properties on the source table into the target, rebinding it to the target table. Other keys are inherited via the metatable.
---
--- Parameters:
---  * `target` - The target to extend
---  * `source` - The source to extend from
---
--- Returns:
---  * The `target`, now extending the `source`.
function prop.extend(target, source)
    -- bind any props to itself
    prop.bind(target, true)(target)
    -- rebind any props in the source to the target
    rebind(target, source)
    if source.__index == nil then
        source.__index = source
    end
    return setmetatable(target, source)
end

--- cp.prop.bind(owner[, relaxed]) -> function
--- Function
--- This provides a utility function for binding multiple properties to a single owner in
--- a simple way. To use, do something like this:
---
--- ```lua
--- local o = {}
--- prop.bind(o) {
---     foo = prop.TRUE(),
---     bar = prop.THIS("Hello world"),
--- }
--- ```
---
--- This is equivalent to the following:
---
--- ```lua
--- local o = {}
--- o.foo = prop.TRUE():bind(o):label("foo")
--- -- alternately...
--- prop.THIS("Hello world"):bind(o, "bar")
--- ```
---
--- It has the added benefit of checking that the target properties ('foo' and 'bar' in this case)
--- have not already been assigned a value.
---
--- Parameters:
--- * owner     - The owner table to bind the properties to.
--- * relaxed   - If `true`, then non-`cp.prop` fields will be ignored. Otherwise they generate an error.
---
--- Returns:
--- * A function which should be called, passing in a table of key/value pairs which are `string`/`cp.prop` value.
---
--- Notes:
--- * If you are binding multiple `cp.prop` values that are dependent on other `cp.prop` values on the same owner (e.g. via `mutate` or a boolean join), you
---   will have to break it up into multiple `prop.bind(...) {...}` calls, so that the dependent property can access the bound property.
--- * If a `cp.prop` provided as bindings already has a bound owner, it will be wrapped instead of bound directly.
function prop.bind(owner, relaxed)
    return function(bindings)
        for k,v in pairs(bindings) do
            if prop.is(v) then
                local vOwner = v:owner()
                if vOwner == nil or vOwner == owner then -- it's unowned/owned by the owner already.
                    v:bind(owner, k)
                elseif vOwner ~= owner then -- it's owned by someone else. wrap instead.
                    v:wrap(owner, k)
                end
            elseif not relaxed then
                error(format("The binding value must be a `cp.prop`, but was a `%s`.", type(v)))
            end
        end
        return owner
    end
end

return setmetatable(prop, { __call = function(_, ...) return prop.new(...) end })
