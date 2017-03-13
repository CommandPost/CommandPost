-- Imports
local builder = {}

--- cp.chooser.choices.builder.new(choiceType) -> builder
--- Function
--- Creates a new choice builder instance.
---
--- Parameters:
--- * `choice`	- The choice instance to configure.
---
--- Returns:
--- * The new choice builder.
function builder.new(choice)
	o = {
		_choice 		= choice,
	}
	setmetatable(o, builder)
	builder.__index = builder
	return o
end

--- cp.chooser.choices.builder:text(value) -> builder
--- Method
--- Specifies the text value for the choice being built.
---
--- Parameters:
--- * `value`	- The text title for the choice.
---
--- Returns:
--- * The choice builder, added to the choices set.
function builder:text(value)
	self._choice.text = value
	return self
end

--- cp.chooser.choices.builder:subText(value) -> builder
--- Method
--- Specifies the `subText` value for the choice being built.
---
--- Parameters:
--- * `value`	- The subText title for the choice.
---
--- Returns:
--- * The choice builder.
function builder:subText(value)
	self._choice.subText = value
	return self
end

--- cp.chooser.choices.builder:favorite(value) -> builder
--- Method
--- Indicates the choice is a favorite.
---
--- Parameters:
--- * `value`	- True or false.
---
--- Returns:
--- * The choice builder.
function builder:favorite(value)
	self._choice.favorite = value
	return self
end

--- cp.chooser.choices.builder:priority(value) -> builder
--- Method
--- Indicates the priority of the choice. The higher the number, the higher the priority.
---
--- Parameters:
--- * `value`	- The numeric priority..
---
--- Returns:
--- * The choice builder.
function builder:popularity(value)
	self._choice.popularity = value
	return self
end

--- cp.chooser.choices.builder:params(value) -> builder
--- Method
--- Specifies a table of parameter values for the choice. These
--- values need to be simple - text, numbers, booleans, or tables.
---
--- Parameters:
--- * `value`	- The table of parameters.
---
--- Returns:
--- * The choice builder, added to the choices set.
function builder:params(value)
	self._choice.params = value
	return self
end

local mod = {}

mod.builder = builder

--- cp.chooser.choices.new(choiceType) -> choices
--- Function
--- Creates a new `cp.plugin.chooser.choices` instance for the specified type.
---
--- Parameters:
--- * `type`	- The unique ID for the type.
---
--- Returns:
--- * The new `choices` instance.
function mod.new(type)
	o = {
		_type 		= type,
		_choices	= {},
	}
	setmetatable(o, mod)
	mod.__index = mod
	return o
end

--- cp.chooser.choices:new(choiceType) -> choices.builder
--- Method
--- Adds a new choice with the specified. Additional settings
--- can be set using the returned builder instance. E.g.:
---
--- ```
--- choices:add("Do Something")
--- 	:subText("Cool Actions")
---		:params({
--- 		one = "foo",
--- 		two = "bar",
--- 	})
--- ```
---
--- Parameters:
--- * `text`	- The text title for the choice.
---
--- Returns:
--- * The choice builder, added to the choices set.
function mod:add(text)
	local choice = {
		type	= self._type
	}
	local bldr = builder.new(choice):text(text)
	self._choices[#self._choices + 1] = choice
	return bldr
end

--- cp.chooser.choices:setStatic(value) -> choices
--- Method
--- By default, choices are considered to be dynamic, and should be
--- reloaded each time the list is required. If the options are not
--- going to change, this can be indicated by calling this method
--- and the results can be cached for future calls.
---
--- Parameters:
--- * N/A
---
--- Returns:
--- * The `choices` instance.
function mod:makeStatic()
	self._static = true
	return self
end

--- cp.chooser.choices:isStatic() -> boolean
--- Method
--- Returns `true` if the choices set is static.
---
--- Parameters:
--- * N/A
---
--- Returns:
--- * `true` if the choices set is static.
function mod:isStatic()
	return self._static == true
end

--- cp.chooser.choices:getChoices() -> array of choices
--- Method
--- Returns the array of choices that have been added to this instance.
---
--- Parameters:
--- * N/A
---
--- Returns:
--- * The array of choices.
function mod:getChoices()
	return self._choices
end

return mod