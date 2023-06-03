--- === cp.rx.go.SetProp ===
---
--- A `Statement` that will update a `cp.prop` value, then optionally execute other `resolvables`, and optionally reset the `cp.prop` to its previous value.
--- This is useful for simply changing a `cp.prop` value without requiring a custom `function()`, but is extra useful when you only want to temporarily change
--- the value.

local require = require

-- local log                   = require("hs.logger").new("go_SetProp")
-- local inspect               = require "hs.inspect"

local Observable            = require "cp.rx.Observable"
local Statement             = require "cp.rx.go.Statement"

local prop                  = require "cp.prop"

local toObservable          = Statement.toObservable
local toObservables         = Statement.toObservables

local insert                = table.insert
local pack                  = table.pack
local unpack                = table.unpack

--- cp.rx.go.SetProp(theProp) -> SetProp
--- Constructor
--- Creates a new `SetProp` `Statement` which will update the provided `cp.prop` value to the specified `To` `value`.
--- It can then optionally execute some other statements and finally, reset the property to its original value.
---
--- Example:
---
--- ```lua
--- local myProp = prop.VALUE("foo")
--- SetProp(myProp):To("bar"):Then(
---     function() ... end
--- ):ThenReset()
--- ```
---
--- Parameters:
---  * theProp - The `cp.prop` which will be updated.
---
--- Returns:
---  * The `SetProp` `Statement`.
local SetProp = Statement.named("SetProp")
:onInit(function(context, theProp)
    assert(prop.is(theProp), "The 'SetProp' value must be a `cp.prop`.")
    context.prop = theProp
    context.thens = {}
end)
:onObservable(function(context)
    local toValue = context.toValue
    assert(toValue ~= nil, "Please specify a 'To' value.")

    local theProp = context.prop
    local thens = context.thens

    local reset = context.reset
    local resetValue = nil

    local o = toObservable(toValue)

    o = o:flatMap(function(value)
        if reset then
            resetValue = theProp:get()
        end
        theProp:set(value)

        if thens and #thens > 0 then
            -- loop through the `thens`, passing the results to the next via zip/flatMap
            local o2 = Observable.zip(unpack(toObservables(thens[1], pack(value))))
            for i = 2, #thens do
                -- log.df("If:Then: processing 'Then' #%d", i)
                o2 = o2:flatMap(function(...)
                    return Observable.zip(unpack(toObservables(thens[i], pack(...))))
                end)
            end

            if reset then
                o2 = o2:finalize(function()
                    theProp:set(resetValue)
                end)
            end

            return o2
        else
            return Observable.of(value)
        end
    end)

    return o
end)
:define()

--- === cp.rx.go.SetProp.To ===
---
--- A `Statement.Modifier` that defines what value to set a `cp.prop` to.

--- cp.rx.go.SetProp.To <cp.rx.go.Statement.Modifier>
--- Constant
--- This is a configuration of `SetProp`, which should be created via `SetProp:To(value)`

--- cp.rx.go.SetProp:To(value) -> SetProp.To
--- Method
--- Call this to define what value to set the property to. If it is a `function` or other "callable" `table`,
--- it will be called with no parameters to get the actual stored value. If it is any other value, it will be set
--- as is.
---
--- For example:
---
--- ```lua
--- SetProp(foo):To("bar") -- will always set to "bar"
--- SetProp(modDate):To(os.time) -- will set to the current value returned by `os.time()` every time it's executed.
--- ```
---
--- Parameters:
---  * value - The value or "callable" to update the prop to.
---
--- Returns:
---  * The `SetProp.To` `Statement.Modifier`.
SetProp.modifier("To")
:onInit(function(context, value)
    context.toValue = value
end)
:define()

--- === cp.rx.go.SetProp.To.Then ===
---
--- A `Statement.Modifier` that defines what happens when after `SetProp.To` is executed.

--- cp.rx.go.SetProp.To.Then <cp.rx.go.Statement.Modifier>
--- Constant
--- This is a configuration of `SetProp.To`, which should be created via `SetProp:To(...):Then(...)`.

--- cp.rx.go.SetProp.To:Then(...) -> SetProp.To.Then
--- Method
--- Call this to define what will happen if the value is updated.
--- The parameters can be any `resolvable` type.
---
--- For example:
--- ```lua
--- SetProp(foo):To("bar")
--- :Then(function(aResult)
---     doSomethingWith(aResult, anotherResult)
---     return true
--- end)
--- ```
---
--- Parameters:
---  * ...  - The list of `resolveable` values to process for the successful `If` result.
---
--- Returns:
---  * The `Then` `Statement.Modifier`.
SetProp.To.modifier("Then")
:onInit(function(context, ...)
    insert(context.thens, pack(...))
end)
:define()

--- cp.rx.go.SetProp.Then:Then(...) -> SetProp.To.Then
--- Method
--- Each [Then](cp.rx.go.SetProp.To.Then.md) can have a subsequent `Then` which will be executed after the previous one resolves.
---
--- Parameters:
---  * ...  - The list of `resolvable` values to process for the `SetProp.To` result.
---
--- Returns:
---  * A new [SetProp.To.Then](cp.rx.go.SetProp.To.Then.md) instance.
SetProp.To.Then.allow(SetProp.To.Then)

--- === cp.rx.go.SetProp.To.Then.ThenReset ===
---
--- A `Statement.Modifier` that specifies that the `cp.prop` is reset to its original value once execution completes.

--- cp.rx.go.SetProp.To.Then.ThenReset <cp.rx.go.Statement.Modifier>
--- Constant
--- This is a configuration of `SetProp.To.Then`, which should be created via `SetProp:To(...):Then(...):ThenReset()`.

--- cp.rx.go.SetProp.To.Then:ThenReset(...) -> SetProp.To.Then.ThenReset
--- Method
--- Call this to have the `cp.prop` get reset to its original value after the `Then` `resolvables` have resolved.
---
--- For example:
--- ```lua
--- local foo = prop.THIS("foo")
--- SetProp(foo):To("bar") -- `foo` is updated to "bar"
--- :Then(function(aResult)
---     doSomethingWith(aResult, anotherResult)
---     return true
--- end)
--- :ThenReset() -- `foo` is back to "foo" now
--- ```
---
--- Parameters:
---  * ...  - The list of `resolveable` values to process for the successful `If` result.
---
--- Returns:
---  * The `Then` `Statement.Modifier`.
SetProp.To.Then.modifier("ThenReset")
:onInit(function(context)
    context.reset = true
end)
:define()

return SetProp