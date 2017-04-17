local log				= require("hs.logger").new("webui")

local uuid				= require("cp.uuid")
local html				= require("cp.web.html")
local _					= require("moses")

local template									= require("resty.template")
local compile									= template.compile


local ui = {}
ui.__index = ui

function evaluate(value)
	if _.isCallable(value) then
		return value()
	else
		return value
	end
end

--- cp.web.ui.new(data, generateFn) -> cp.web.ui
--- Constructor
--- Generates an HTML element with the provided `data` and generator function.
--- The `generateFn` will be passed the current data value and will return the
--- generated HTML markup, either as a string or as `cp.web.html` elements.
---
--- Parameters:
---  * data		- the data table, or function returning a table, containing the 
function ui.new(data, generateFn, id)
	local o = {
		_data 		= data,
		_id			= id or uuid(),
		_generate	= generateFn,
	}
	return setmetatable(o, ui)
end

--- cp.web.ui.javascript(script, context) -> cp.web.ui
--- Function
--- Generates an HTML script element which will execute the provided
--- JavaScript immediately. The script is self-contained and only has
--- access to global variables. Any local `var` values will not be available
--- to other scripts.
---
--- The script will be evaluated as a `resty.template`, and variables can be
--- injected from the `context` table. For example, this will create a script
--- that will display an alert saying "Hello world!":
---
--- ```lua
--- ui.javascript([[ alert("{{ message }}") ]], { message = "Hello world!"})
--- ```
---
--- Parameters:
---  * script 	- String containing the JavaScript to execute.
---  * context	- Table containing any values to inject into the script.
---
--- Returns:
---  * a 
---
function ui.javascript(script, context)
	local t = compile(script, "no-cache", true)
	return html.script { type = "text/javascript" } (
		"(function(){\n" .. t(context) .. "\n})();", true
	)
end

function ui.heading(params)
	-- the level must be a number between 1 and 7.
	local level = evaluate(params.level) or 3
	assert(type(level) == "number" and level >= 1 and level <= 7)
	local tag = "h" .. level
	
	return html[tag] { class=params.class } (params.text)
end

function ui.template(view, context)
	return ui.new({
		render	=	compile(view),
		context	= 	context,
	}, function(data, id)
		return data.render(evaluate(data.context))
	end)
end

--- cp.web.ui.checkbox(title, value[, id]) -> cp.web.ui
--- Constructor
--- Generates a HTML Checkbox element. The `data` should be a table or a function returning a table
---
--- Parameters:
---  * data			- A table or function returning a table with the checkbox data.
---
--- Returns:
---  * The `cp.web.ui.element`.
---
--- Notes:
---  * The `params` table has the following supported fields:
---  ** `value`		- a string (or function) with the value of the checkbox. If not specified, the title is used.
---  ** `checked`	- a boolean (or function) set to `true` or `false`, depending on if the checkbox is checked.
---  ** `id`		- (optional) a string (or function) with the unique ID for the checkbox.
---  ** `name`		- (optional) a unique name for the checkbox field.
---  ** `class`		- (optional) the CSS class list.
function ui.checkbox(params)
	
	if params then
		local checked = function() return evaluate(params.checked) and "checked" or nil end
		return html.input {
			type = "checkbox", 
			name = params.name,
			id = params.id, 
			value = params.value, checked,
			class = params.class,
		}
	else
		return ""
	end

end

--- cp.web.ui.button(params) -> cp.web.ui
--- Constructor
--- Generates a HTML Button
---
--- Parameters:
---  * `params`		- Table containing the data you want to display on the button.
---
--- Returns:
---  * A `cp.web.ui` representing the button.
---
--- Notes:
--- * The `params` can contain the following fields:
--- ** `value`		- The value of th button.
--- ** `label`		- The text label for the button. Defaults to the `value` if not provided.
--- ** `width`		- The width of the button in pixels.
function ui.button(params)
	params.label = params.label or params.value

	local style = nil
	if params.width then
		style = "width: " .. params.width .. "px;"
	end

	local result = html.a { id=params.id, style=style, class="button", href="#", value=params.value } (params.label)

	return result
end

--- cp.web.ui.select(params) -> cp.web.html
--- Function
--- Generates a `cp.web.html` `select` element. The `data` should be a table or a function returning a table
--- that matches the details in the notes below.
---
--- Parameters:
---  * data			- A table or function returning a table with the checkbox data.
---
--- Returns:
---  * A `cp.web.html` with the select defined.
---
--- Notes:
---  * The `params` table has the following supported fields:
---  ** `id`		- a string (or function) the unique ID for the select.
---  ** `value`		- a string, number, or boolean (or function) with the value of the select. May be `nil`.
---  ** `options`	- an array (or function returning an array) of option tables, with the following keys:
---  *** `value`	- the value of the option.
---  *** `label`	- (optional) the label for the option. If not set, the `value` is used.
---  ** `required`	- (optional) if `true`, there will not be a 'blank' option at the top of the list.
---  ** `blankLabel`	- (optional) if specified, the value will be used for the 'blank' option label.
function ui.select(params)
	-- This will update the available/checked options every time the select is output.
	local optionGenerator = function()
		local options = ""
		local value = evaluate(params.value)
		
		if not params.required then
			options = options .. html.option { value = "" } (evaluate(params.blankLabel) or "")
		end
		
		local opts = evaluate(params.options)
		if opts then
			for _,opt in ipairs(opts) do
				local optValue = evaluate(opt.value)
				local label = evaluate(opt.label) or optValue
				local selected = optValue == value and "selected" or nil
				options = options .. html.option { value = optValue, selected } (label)
			end
		end
		return options
	end
	
	-- create the 
	return html.select { id = params.id, name = params.id } (optionGenerator, true)
end

function ui.dropdown(data, id)
	local generateFn = function(data, id)
		local title = evaluate(data.title) or ""
		local value = evaluate(data.value) or title
		
		local opts = evaluate(data.options) or {}

		if title ~= "" then title = title .. ": " end

		local options = ""

		for i, v in ipairs(opts) do
			local selected = v.value == value and "selected" or ""
			options = options .. html.option { value=v.value, selected } (v.title)
		end

		local result = title .. html.select { id=id } (options)
		
		if data.changeFn and data.handlerId then
			local handlerId = evaluate(data.handlerId)
			mod.javascript([[
				var dropdown = document.getElementById("{{ id }}");
				dropdown.onchange = function (){
					try {
						var dropdownResult = document.getElementById("{{ id }}").value;
						var result = ["{{ result }}", dropdownResult];
						webkit.messageHandlers.{{ name }}.postMessage(result);
					} catch(err) {
						alert('An error has occurred. Does the controller exist yet?');
					}
				}
			]], { id=id, result=result, name=handlerId })
		end

		return result	
	end
	
	return ui.new(data, generateFn, id)
end

function ui:id()
	return self._id
end

function ui:data()
	return evaluate(self._data)
end

function ui:generate()
	return self._generate(self:data(), self:id())
end

function ui:__tostring()
	return tostring(self:generate())
end

return ui