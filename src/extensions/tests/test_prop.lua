local test		= require("cp.test")
local log		= require("hs.logger").new("testprop")
local inspect	= require("hs.inspect")

local prop		= require("cp.prop")

function run()
	test("Prop new", function()
		local state = true
	
		local isState = prop.new(function() return state end, function(newValue) state = newValue end)
		ok(isState())
		ok(isState(false) == false)
		ok(not isState())
		ok(not state)
	end)
	
	test("Prop Call", function()
		local state = true
	
		local isState = prop(function() return state end)
		ok(isState())
		ok(isState:mutable() == false)
	end)
	
	test("Prop THIS", function()
		local isTrue = prop.THIS(true)
		ok(isTrue() == true)
		ok(isTrue:toggle() == false)
		
		local isFalse = prop.THIS(false)
		ok(isFalse() == false)
		ok(isFalse:toggle() == true)
		
		local isHello = prop.THIS("Hello world")
		ok(isHello() == "Hello world")
		ok(isHello("Hello universe") == "Hello universe")
		ok(isHello(nil) == "Hello universe")
		ok(isHello:set(nil) == nil)
	end)
	
	test("Prop TRUE", function()
		local isTrue = prop.TRUE()
		ok(isTrue() == true)
		ok(isTrue:toggle() == false)
	end)
	
	test("Prop FALSE", function()
		local isFalse = prop.FALSE()
		ok(isFalse() == false)
		ok(isFalse:toggle() == true)
	end)
	
	test("is IMMUTABLE", function()
		local isTrue = prop.TRUE():IMMUTABLE()
		ok(isTrue() == true)
		ok(not isTrue:mutable())
		
		local check = spy(function() isTrue():toggle() end)
		check()
		ok(check.errors[1], "Can't toggle an immutable value.")
	end)

	test("Toggling", function()
		local state = true
	
		local isState = prop.new(function() return state end, function(newValue) state = newValue end)
		ok(isState())
		ok(isState:toggle() == false)
		ok(not isState())
		
		-- Toggling a non-boolean will `nil` it, then toggling the `nil` will make it `true`
		local hello = prop.THIS("Hello world")
		ok(hello() == "Hello world")
		ok(hello:toggle() == nil)
		ok(hello:toggle() == true)
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
		ok(isState())
		isState:watch(watcher, true)
		ok(eq(count, 1))
		ok(watchValue == true)

		-- Toggle once
		ok(isState:toggle() == false)
		ok(eq(count, 2))
		ok(watchValue == false)
		
		-- Toggle twice
		ok(isState:toggle() == true)
		ok(eq(count, 3))
		ok(watchValue == true)
	end)
	
	test("Prop Unwatch", function()
		local log = {}
		-- watch the property, keep the watcher instance
		local prop, watcher = prop.TRUE():watch(function(value) log[#log+1] = value end)
		ok(eq(log, {}))
		
		prop:update()
		ok(eq(log, {true}))
		
		ok(prop(false) == false)
		ok(eq(log, {true, false}))
		
		prop:unwatch(watcher)
		ok(prop(true) == true)
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
		ok(isState())
		ok(not isNotState())
		
		ok(isState:NOT():value() == false)
		
		-- Test watching
		local count = 0
		local watchValue = nil
		isNotState:watch(function(value) watchValue = value; count = count+1 end, true)
		ok(eq(count, 1))
		ok(watchValue == false)
		
		-- Toggle the original value to 'false'
		ok(isState:toggle() == false)
		ok(isNotState:value() == true)
		ok(eq(count, 2))
		ok(watchValue == true)
		
		-- Toggle the 'not' value, switching original to 'true'
		ok(isNotState:toggle() == false)
		ok(isNotState:value() == false)
		ok(isState:value() == true)
		ok(eq(count, 3))
		ok(watchValue == false)
		
		-- Check that non-booleans work as expected
		ok(prop.THIS("Hello"):NOT():value() == nil)
		ok(prop.THIS(nil):NOT():value() == true)
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
		ok(prop.THIS("Hello"):AND(prop.THIS("world")):value() == "world")
		ok(prop.THIS("Hello"):AND(prop.THIS(nil)):value() == nil)
		ok(prop.THIS("Hello"):AND(prop.FALSE()):value() == false)
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
		ok(prop.THIS("Hello"):OR(prop.THIS("world")):value() == "Hello")
		ok(prop.THIS(nil):OR(prop.THIS("world")):value() == "world")
		ok(prop.THIS(nil):OR(prop.FALSE()):value() == false)
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
		ok(aProp() == false)
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
		ok(aProp() == true)
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
		
		ok(cProp() == true)
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
		
		ok(preWatched == 0)
		
		a:toggle()
		ok(a() == false)
		ok(preWatched == 0)
		
		local watched = 0
		a:watch(function(value, self) watched = watched + 1 end)
		
		a:toggle()
		ok(a() == true)
		ok(preWatched == 1)
		ok(watched == 1)
		
		-- happens after a watcher has been added. Better late than never!
		local instantPreWatch = 0
		a:preWatch(function(self) instantPreWatch = instantPreWatch + 1 end)
		ok(instantPreWatch == 1)
		
		a:toggle()
		ok(a() == false)
		ok(preWatched == 1)
		ok(instantPreWatch == 1)
		ok(watched == 2)		
	end)
end

return run
