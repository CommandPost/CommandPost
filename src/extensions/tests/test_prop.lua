local test		= require("cp.test")
local log		= require("hs.logger").new("testprop")
local inspect	= require("hs.inspect")

local prop		= require("cp.prop")

function run()
	test("Prop Prepare Value", function()
		local prep = prop._prepareValue

		-- basic types
		ok(eq(prep(nil), nil))
		ok(eq(prep(1), 1))
		ok(eq(prep("foo"), "foo"))
		ok(eq(prep(true), true))
		ok(eq(prep(false), false))

		-- tables
		local value = { a = 1, b = { c = 1 } }
		local prepped = prep(value, nil)

		-- 'value' prep
		ok(prepped == value, "prepped is the value")

		-- 'deep' prep
		prepped = prep(value, "deep")
		ok(prepped ~= value, "prepped is not the value")
		ok(prepped.b ~= value.b, "prepped.b is not the value.b")

		-- 'shallow' prep
		prepped = prep(value, "shallow")
		ok(prepped ~= value, "prepped is not the value")
		ok(prepped.b == value.b, "prepped.b is the value.b")
	end)

	test("Prop new", function()
		local state = true

		local isState = prop.new(function() return state end, function(newValue) state = newValue end)
		ok(isState())
		ok(eq(isState(false), false))
		ok(eq(isState(), false))
		ok(eq(state, false))
	end)

	test("Prop Call", function()
		local state = true

		local isState = prop(function() return state end)
		ok(isState())
		ok(eq(isState:mutable(), false))
	end)

	test("Prop THIS", function()
		local isTrue = prop.THIS(true)
		ok(eq(isTrue(), true))
		ok(eq(isTrue:toggle(), false))

		local isFalse = prop.THIS(false)
		ok(eq(isFalse(), false))
		ok(eq(isFalse:toggle(), true))

		local isHello = prop.THIS("Hello world")
		ok(eq(isHello(), "Hello world"))
		ok(eq(isHello("Hello universe"), "Hello universe"))
		ok(eq(isHello(nil), "Hello universe"))
		ok(eq(isHello:set(nil), nil))
	end)

	test("Prop TRUE", function()
		local isTrue = prop.TRUE()
		ok(eq(isTrue(), true))
		ok(eq(isTrue:toggle(), false))
	end)

	test("Prop FALSE", function()
		local isFalse = prop.FALSE()
		ok(eq(isFalse(), false))
		ok(eq(isFalse:toggle(), true))
	end)

	test("is IMMUTABLE", function()
		local isTrue = prop.TRUE():IMMUTABLE()
		ok(eq(isTrue(), true))
		ok(eq(isTrue:mutable(), false))

		local check = spy(function() isTrue():toggle() end)
		check()
		ok(check.errors[1], "Can't toggle an immutable value.")
	end)

	test("Toggling", function()
		local state = true

		local isState = prop.new(function() return state end, function(newValue) state = newValue end)
		ok(eq(isState(), true))
		ok(eq(isState:toggle(), false))
		ok(eq(isState(), false))

		-- Toggling a non-boolean will `nil` it, then toggling the `nil` will make it `true`
		local hello = prop.THIS("Hello world")
		ok(eq(hello(), "Hello world"))
		ok(eq(hello:toggle(), nil))
		ok(eq(hello:toggle(), true))
	end)

	test("Prop Watch", function()
		local state = true
		local count = 0
		local watchValue = nil
		local watcher = function(newValue)
			watchValue = newValue
			count = count + 1
		end

		local isState = prop.new(function() return state end, function(newValue) state = newValue end)
		ok(eq(isState(), true))
		isState:watch(watcher, true)
		ok(eq(count, 1))
		ok(eq(watchValue, true))

		-- Toggle once
		ok(eq(isState:toggle(), false))
		ok(eq(count, 2))
		ok(eq(watchValue, false))

		-- Toggle twice
		ok(eq(isState:toggle(), true))
		ok(eq(count, 3))
		ok(eq(watchValue, true))
	end)

	test("Prop Unwatch", function()
		local log = {}
		-- watch the property, keep the watcher instance
		local prop, watcher = prop.TRUE():watch(function(value) log[#log+1] = value end)
		ok(eq(log, {}))

		prop:update()
		ok(eq(log, {true}))

		ok(eq(prop(false), false))
		ok(eq(log, {true, false}))

		prop:unwatch(watcher)
		ok(eq(prop(true), true))
		ok(eq(log, {true, false}))
	end)

	test("Prop Watch Bound", function()
		local owner = {}
		owner.prop = prop.TRUE():watch(function(value, self) ok(eq(self, owner)) end):bind(owner)
		owner.prop:update()
	end)

	test("Prop NOT", function()
		local state = true

		local isState		= prop.new(function() return state end, function(newValue) state = newValue end)
		local isNotState	= prop.NOT(isState)
		ok(eq(isState(), true))
		ok(eq(isNotState(), false))

		ok(eq(isState:NOT():value(), false))

		-- Test watching
		local count = 0
		local watchValue = nil
		isNotState:watch(function(value) watchValue = value; count = count+1 end, true)
		ok(eq(count, 1))
		ok(eq(watchValue, false))

		-- Toggle the original value to 'false'
		ok(eq(isState:toggle(), false))
		ok(eq(isNotState:value(), true))
		ok(eq(count, 2))
		ok(eq(watchValue, true))

		-- Toggle the 'not' value, switching original to 'true'
		ok(eq(isNotState:toggle(), false))
		ok(eq(isNotState:value(), false))
		ok(eq(isState:value(), true))
		ok(eq(count, 3))
		ok(eq(watchValue, false))

		-- Check that non-booleans work as expected
		ok(eq(prop.THIS("Hello"):NOT():value(), nil))
		ok(eq(prop.THIS(nil):NOT():value(), true))
	end)

	test("Prop AND", function()
		local leftState = true
		local rightState = true

		local isLeft	= prop.new(function() return leftState end, function(value) leftState = value end)
		local isRight	= prop.new(function() return rightState end, function(value) rightState = value end)

		local isLeftAndRight = prop.AND(isLeft, isRight)

		ok(isLeftAndRight() == true)
		-- isLeft false
		isLeft(false)
		ok(isLeftAndRight() == false)

		-- isRight false
		isRight(false)
		ok(isLeftAndRight() == false)

		-- isLeft back to true
		isLeft(true)
		ok(isLeftAndRight() == false)

		-- isRight back to true
		isRight(true)
		ok(isLeftAndRight() == true)

		-- Use AND as a method
		isLeftAndRightAgain = isLeft:AND(isRight)
		ok(isLeftAndRightAgain:value() == true)

		-- Check we get an error when combining an AND and OR
		-- We have to wrap the execution in a 'spy' function to catch the error.
		local andOr = spy(function() isLeftAndRight:OR(prop.new(function() return false end)) end)
		andOr()
		ok(andOr.errors[1], "Cannot combine AND and OR")

		-- Check that we can watch the combined `prop` for changes from further down.
		local count = 0
		local watchValue = nil
		isLeftAndRight:watch(function(value) count = count+1; watchValue = value end, true)
		ok(eq(count, 1))
		ok(eq(watchValue, true))

		-- Toggle isLeft
		isLeft(false)
		ok(eq(count, 2))
		ok(eq(watchValue, false))

		-- Toggle isLeft
		isLeft(true)
		ok(eq(count, 3))
		ok(eq(watchValue, true))

		-- Toggle isRight
		isRight(false)
		ok(eq(count, 4))
		ok(eq(watchValue, false))

		-- Test non-boolean properties.
		ok(eq(prop.THIS("Hello"):AND(prop.THIS("world")):value(), "world"))
		ok(eq(prop.THIS("Hello"):AND(prop.THIS(nil)):value(), nil))
		ok(eq(prop.THIS("Hello"):AND(prop.FALSE()):value(), false))
	end)

	test("Prop OR", function()
		local isLeft	= prop.TRUE()
		local isRight	= prop.TRUE()

		local isLeftOrRight = prop.OR(isLeft, isRight)

		ok(isLeftOrRight() == true)
		-- isLeft false
		isLeft(false)
		ok(isLeftOrRight() == true)

		-- isRight false as well
		isRight(false)
		ok(isLeftOrRight() == false)

		-- isLeft back to true
		isLeft(true)
		ok(isLeftOrRight() == true)

		-- isRight back to true
		isRight(true)
		ok(isLeftOrRight() == true)

		-- Use OR as a method
		ok(isLeft:OR(isRight):value() == true)

		-- Check we get an error when combining an OR and AND
		-- We have to wrap the execution in a 'spy' function to catch the error.
		local andOr = spy(function() isLeftOrRight:AND(prop.new(function() return false end)) end)
		andOr()
		ok(andOr.errors[1], "Cannot combine OR and AND")

		-- Check that we can watch the combined `prop` for changes from further down.
		local count = 0
		local watchValue = nil
		isLeftOrRight:watch(function(value) count = count+1; watchValue = value end)
		ok(eq(count, 0))
		ok(eq(watchValue, nil))

		-- Toggle isLeft
		isLeft(false)
		ok(eq(count, 1))
		ok(eq(watchValue, true))

		-- ...and isRight
		isRight(false)
		ok(eq(count, 2))
		ok(eq(watchValue, false))

		-- Test non-boolean properties.
		ok(eq(prop.THIS("Hello"):OR(prop.THIS("world")):value(), "Hello"))
		ok(eq(prop.THIS(nil):OR(prop.THIS("world")):value(), "world"))
		ok(eq(prop.THIS(nil):OR(prop.FALSE()):value(), false))
	end)

	test("Prop Bind", function()
		local instance = {
			value = true,
		}

		instance.isMethod = prop.new(
			function(owner)
				return owner.value
			end,
			function(newValue, owner)
				owner.value = newValue
			end):bind(instance)

		ok(instance:isMethod() == true)
		ok(instance:isMethod(false) == false)
		ok(instance.value == false)
		ok(instance.isMethod:toggle() == true)
		ok(instance.value == true)

		instance.isSimple = prop.TRUE():bind(instance)
		ok(instance:isSimple())
		ok(instance.isSimple:toggle() == false)
		ok(not instance:isSimple())

		instance.isNot = prop.NOT(instance.isSimple):bind(instance)
		instance:isSimple(true)
		ok(instance:isNot() == false)
		ok(instance.isNot:toggle() == true)
		ok(instance:isSimple() == false)

		instance.isAndMethod = instance.isMethod:AND(instance.isSimple):bind(instance)
		instance:isMethod(true)
		instance:isSimple(true)
		ok(instance:isAndMethod() == true)
		ok(instance:isMethod(false) == false)
		ok(instance:isAndMethod() == false)

		instance.isOrMethod = instance.isMethod:OR(instance.isSimple):bind(instance)
		instance:isMethod(true)
		instance:isSimple(true)
		ok(instance:isOrMethod() == true)
		ok(instance:isMethod(false) == false)
		ok(instance:isOrMethod() == true)
		ok(instance:isSimple(false) == false)
		ok(instance:isOrMethod() == false)
	end)

	test("Prop Extend", function()
		local source, target = {}, {}

		source.isMethod = prop.TRUE():bind(source)
		source.isFunction = prop.TRUE()
		source.isRealFunction = function() return true end

		prop.extend(target, source)

		ok(target.isMethod:owner() == target)
		ok(target.isMethod ~= source.isMethod)
		ok(target.isFunction:owner() == nil)
		ok(target.isFunction == source.isFunction)
		ok(target.isRealFunction == source.isRealFunction)
	end)

	test("Prop Notify Loop", function()
		local aProp = prop.TRUE()
		local log = {}

		-- logs
		aProp:watch(function(value) log[#log+1] = 1 end)

		-- modifies then logs
		aProp:watch(function(value)
			aProp:set(false)
			log[#log+1] = 2
		end)
		-- logs
		aProp:watch(function(value) log[#log+1] = 3 end)

		aProp:update()

		-- should be two sets of logs, one after the other.
		ok(eq(aProp(), false))
		ok(eq(log, {1, 2, 3, 1, 2, 3}))
	end)

	test("Prop Notify On/Off", function()
		local aProp = prop.TRUE()
		local log = {}

		-- logs
		aProp:watch(function(value) log[#log+1] = 1 end)

		-- modifies to false then logs
		aProp:watch(function(value)
			aProp:set(false)
			log[#log+1] = 2
		end)
		-- modifes back to true then logs
		aProp:watch(function(value)
			aProp:set(true)
			log[#log+1] = 3
		end)

		aProp:update()

		-- The value was reset before the notification loop finished, so no change occurs.
		ok(eq(aProp(), true))
		ok(eq(log, {1, 2, 3}))
	end)

	test("Prop Parent Notify Loop", function()
		local aProp = prop.TRUE()
		local bProp = prop.FALSE()
		local cProp = aProp:AND(bProp)

		local log = {}

		ok(cProp() == false)

		cProp:watch(function(value)
			log[#log+1] = {one = value}
			if not value then
				bProp(true)
			end
		end)

		cProp:watch(function(value)
			log[#log+1] = {two = value}
		end)

		cProp:update()

		ok(eq(cProp(), true))
		ok(eq(log, {{one = false}, {two = false}, {one = true}, {two = true}}))
	end)

	test("Prop Clone", function()
		local owner = {}

		local aProp = prop.TRUE()
		local bProp = aProp:bind(owner)

		local aClone = aProp:clone()
		local bClone = bProp:clone()

		ok(eq(bClone:owner(), bProp:owner()))

		ok(aProp() == true)
		ok(bProp() == true)
		ok(aClone() == true)
		ok(bClone() == true)

		aProp(false)
		ok(aProp() == false)
		ok(bProp() == true)
		ok(aClone() == true)
		ok(bClone() == true)
	end)

	test("Prop Bind AND Watch", function()
		local owner = {}

		local aProp = prop.TRUE()
		local bProp = prop.TRUE()

		-- the base AND
		local andProp = aProp:AND(bProp)
		-- watch is
		local propCount, propValue = 0, nil
		local propWatch = function(value) propCount = propCount + 1; propValue = value end
		andProp:watch(propWatch, false, true)

		-- the bound AND
		local andBound = andProp:bind(owner)
		local boundCount, boundValue = 0, nil
		local boundWatch = function(value) boundCount = boundCount + 1; boundValue = value end
		andBound:watch(boundWatch)

		ok(#andProp._watchers == 1)
		ok(andProp._watchers[1].fn == propWatch)

		ok(#andBound._watchers == 1)
		ok(andBound._watchers[1].fn == boundWatch)
	end)

	test("Prop Binary Functions", function()
		local one, two, three = prop.THIS(1), prop.THIS(2), prop.THIS(3)

		ok(one:EQUALS(1):value() == true)
		ok(one:EQUALS(one):value() == true)
		ok(one:EQUALS(two):value() == false)

		ok(two:BELOW(one):value() == false)
		ok(two:ABOVE(one):value() == true)
		ok(two:BELOW(three):value() == true)
		ok(two:ABOVE(three):value() == false)

		ok(two:ATLEAST(3):value() == false)
		ok(two:ATMOST(3):value() == true)
		ok(two:ATLEAST(1):value() == true)
		ok(two:ATMOST(1):value() == false)
		ok(two:ATLEAST(2):value() == true)
		ok(two:ATMOST(2):value() == true)

		local something = prop.THIS(1)
		local comp = one:EQUALS(something)

		ok(comp:value() == true)
		something(0)
		ok(comp:value() == false)
	end)

	test("Prop Notify/Update Same Value", function()
		local report = {}
		-- do a 'notifyNow' watch
		local value = prop.TRUE():watch(function(value) report[#report+1] = value end, true)
		-- force an update without changing the value
		value:update()
		-- should only be one log entry since the value didn't change.
		ok(eq(report, {true}))
	end)

	test("Prop Monitoring", function()
		local report = {}

		local a = prop.TRUE()

		local b = prop.new(function() return a() and "true" or "false" end)
			:monitor(a)
			:watch(function(value) report[#report+1] = value end)

		ok(eq(report, {}))

		a(false)

		ok(eq(report, {"false"}))

	end)

	test("Prop Mutation", function()
		local report = {}

		-- take any number
		local anyNumber = prop.THIS(1)

		-- mutate to check if it's odd or even
		local isEven	= anyNumber:mutate(function(value) return value % 2 == 0 end)
			:watch(function(value) report[#report+1] = value end)

		ok(isEven() == false)
		ok(eq(report, {}))

		anyNumber(10)
		ok(isEven() == true)
		ok(eq(report, {true}))

		anyNumber(4)
		ok(isEven() == true)
		ok(eq(report, {true}))

		anyNumber(7)
		ok(isEven() == false)
		ok(eq(report, {true, false}))
	end)

	test("Prop Wrapping", function()
		local a = prop.TRUE()
		local b = a:wrap(b)
		local c = b:clone()

		local aReport = {}
		local bReport = {}
		local cReport = {}

		a:watch(function(value) aReport[#aReport+1] = value end)
		b:watch(function(value) bReport[#bReport+1] = value end)
		c:watch(function(value) cReport[#cReport+1] = value end)

		ok(a() == true)
		ok(b() == true)
		ok(c() == true)
		ok(eq(aReport, {}))
		ok(eq(bReport, {}))
		ok(eq(cReport, {}))

		-- change a
		a(false)
		ok(a() == false)
		ok(b() == false)
		ok(c() == false)
		ok(eq(aReport, {false}))
		ok(eq(bReport, {false}))
		ok(eq(cReport, {false}))

		-- change b
		b(true)
		ok(a() == true)
		ok(b() == true)
		ok(c() == true)
		ok(eq(aReport, {false, true}))
		ok(eq(bReport, {false, true}))
		ok(eq(cReport, {false, true}))
	end)

	test("Prop Pre-Watch", function()
		local preWatched = 0

		local a = prop.TRUE()
		a:preWatch(function(self) preWatched = preWatched + 1 end)

		ok(eq(preWatched, 0))

		a:toggle()
		ok(eq(a(), false))
		ok(eq(preWatched, 0))

		local watched = 0
		a:watch(function(value, self) watched = watched + 1 end)

		a:toggle()
		ok(eq(a(), true))
		ok(eq(preWatched, 1))
		ok(eq(watched, 1))

		-- happens after a watcher has been added. Better late than never!
		local instantPreWatch = 0
		a:preWatch(function(self) instantPreWatch = instantPreWatch + 1 end)
		ok(eq(instantPreWatch, 1))

		a:toggle()
		ok(eq(a(), false))
		ok(eq(preWatched, 1))
		ok(eq(instantPreWatch, 1))
		ok(eq(watched, 2))
	end)

	test("Prop Table Copying", function()
		local originalValue = { a = 1, b = { c = 1 } }
		local value = originalValue

		local valueProp = prop.THIS(originalValue)
		local deepProp = prop.THIS(originalValue):deepTable()
		local shallowProp = prop.THIS(originalValue):shallowTable()

		local valueCount, deepCount, shallowCount = 0, 0, 0

		-- print a message when the prop value is updated
		valueProp:watch(function(v) valueCount = valueCount + 1 end)
		deepProp:watch(function(v) deepCount = deepCount + 1 end)
		shallowProp:watch(function(v) shallowCount = shallowCount + 1 end)

		-- change the original table:
		value.a				= 2
		value.b.c			= 2

		-- still referencing the original
		ok(eq(valueProp(),		{ a = 2, b = { c = 2 } }))
		-- top level is copied, child tables referenced
		ok(eq(shallowProp(),	{ a = 1, b = { c = 2 } }))
		-- top level is copied, child tables copied also
		ok(eq(deepProp(),  		{ a = 1, b = { c = 1 } }))

		-- get the 'value' property
		value = valueProp()			-- returns the original value table
		value.a				= 3		-- updates the original value table `a` value
		value.b.c			= 3		-- updates the original `b` table's `c` value
		valueProp(value)
		ok(eq(valueCount, 1))		-- the first update triggers
		valueProp(value)
		ok(eq(valueCount, 1))		-- no further updates.

		-- still referencing the original
		ok(eq(valueProp(),		{ a = 3, b = { c = 3 } }))
		-- top level was copied, child tables referenced
		ok(eq(shallowProp(),	{ a = 1, b = { c = 3 } }))
		-- top level is copied, child tables copied also
		ok(eq(deepProp(),  		{ a = 1, b = { c = 1 } }))

		-- get the 'deep copy' property
		value = deepProp()			-- returns a new table, with all child tables also copied.
		value.a				= 4		-- updates the new table's `a` value
		value.b.c			= 4		-- updates the new `b` table's `c` value
		deepProp(value)
		ok(eq(deepCount, 1))		-- the watcher was notified.
		deepProp(value)
		ok(eq(deepCount, 2))		-- the watcher was notified again.

		-- still referencing the original
		ok(eq(valueProp(),		{ a = 3, b = { c = 3 } }))
		-- top level is copied, child tables referenced
		ok(eq(shallowProp(),	{ a = 1, b = { c = 3 } }))
		-- updated to the new values
		ok(eq(deepProp(),  		{ a = 4, b = { c = 4 } }))

		-- get the 'shallow' property
		value = shallowProp()		-- returns a new table with top-level keys copied.
		value.a				= 5		-- updates the new table's `a` value
		value.b.c			= 5		-- updates the original `b` table's `c` value.
		shallowProp(value)
		ok(eq(shallowCount, 1))		-- the watcher was notified.
		shallowProp(value)
		ok(eq(shallowCount, 2))		-- the watcher was notified again.

		-- still referencing the original, b updated via the shallow copy
		ok(eq(valueProp(),		{ a = 3, b = { c = 5 } }))
		-- top level is copied, child tables referenced
		ok(eq(shallowProp(),	{ a = 5, b = { c = 5 } }))
		-- unmodified after the last update
		ok(eq(deepProp(),  		{ a = 4, b = { c = 4 } }))
	end)

	test("Cached Props", function()
		local value = 1

		local p = prop(function() return value end, function(newValue) value = newValue end):cached()

		ok(eq(p(), 1))

		p(2)
		ok(eq(value, 2), "value is updated to 2")
		ok(eq(p(), 2), "p result is updated to 2")

		value = 3
		ok(eq(p(), 2), "p result has not updated to 3.")

		p:update()
		ok(eq(p(), 3), "p result has now updated to 3")
	end)
end

return run
