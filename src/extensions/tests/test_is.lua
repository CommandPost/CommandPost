local test		= require("cp.test")
local log		= require("hs.logger").new("testis")

local is		= require("cp.is")

function run()
	test("Is new", function()
		local state = true
	
		local isState = is.new(function() return state end, function(newValue) state = newValue end)
		ok(isState())
		ok(isState(false) == false)
		ok(not isState())
		ok(not state)
	end)
	
	test("Is THIS", function()
		local isTrue = is.THIS(true)
		ok(isTrue() == true)
		ok(isTrue:toggle() == false)
		
		local isFalse = is.THIS(false)
		ok(isFalse() == false)
		ok(isFalse:toggle() == true)
	end)
	
	test("Is TRUE", function()
		local isTrue = is.TRUE()
		ok(isTrue() == true)
		ok(isTrue:toggle() == false)
	end)
	
	test("Is FALSE", function()
		local isFalse = is.FALSE()
		ok(isFalse() == false)
		ok(isFalse:toggle() == true)
	end)
	
	test("is IMMUTABLE", function()
		local isTrue = is.TRUE():IMMUTABLE()
		ok(isTrue() == true)
		ok(not isTrue:mutable())
		
		local check = spy(function() isTrue():toggle() end)
		check()
		ok(check.errors[1], "Can't toggle an immutable value.")
	end)

	test("Toggling", function()
		local state = true
	
		local isState = is.new(function() return state end, function(newValue) state = newValue end)
		ok(isState())
		ok(isState:toggle() == false)
		ok(not isState())
	end)
	
	test("Watcher", function()
		local state = true
		local count = 0
		local watchValue = nil
		local watcher = function(newValue)
			watchValue = newValue
			count = count + 1
		end
		
		local isState = is.new(function() return state end, function(newValue) state = newValue end)
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
	
	test("Is NOT", function()
		local state = true
	
		local isState		= is.new(function() return state end, function(newValue) state = newValue end)
		local isNotState	= is.NOT(isState)
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
	end)
	
	test("Is AND", function() 
		local leftState = true
		local rightState = true
		
		local isLeft	= is.new(function() return leftState end, function(value) leftState = value end)
		local isRight	= is.new(function() return rightState end, function(value) rightState = value end)
		
		local isLeftAndRight = is.AND(isLeft, isRight)
		
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
		local andOr = spy(function() isLeftAndRight:OR(is.new(function() return false end)) end)
		andOr()
		ok(andOr.errors[1], "Cannot combine AND and OR")
		
		-- Check that we can watch the combined `is` for changes from further down.
		local count = 0
		local watchValue = nil
		isLeftAndRight:watch(function(value) count = count+1; watchValue = value end, true)
		ok(eq(count, 1))
		ok(eq(watchValue, true))
		
		-- Toggle isLeft
		isLeft(false)
		ok(eq(count, 2))
		ok(eq(watchValue, false))
	end)
	
	test("Is OR", function() 
		local leftState = true
		local rightState = true
		
		local isLeft	= is.new(function() return leftState end, function(value) leftState = value end)
		local isRight	= is.new(function() return rightState end, function(value) rightState = value end)
		
		local isLeftOrRight = is.OR(isLeft, isRight)
		
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
		
		-- Use AND as a method
		ok(isLeft:OR(isRight):value() == true)
		
		-- Check we get an error when combining an OR and AND
		-- We have to wrap the execution in a 'spy' function to catch the error.
		local andOr = spy(function() isLeftOrRight:AND(is.new(function() return false end)) end)
		andOr()
		ok(andOr.errors[1], "Cannot combine OR and AND")
		
		-- Check that we can watch the combined `is` for changes from further down.
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
		
	end)
end

return run
