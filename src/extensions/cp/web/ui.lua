--- === cp.web.ui ===
---
--- This extension contains functions which simplify the creation of standard UI events
--- using `cp.web.html` as the basis. Most functions return a `html` element which is
--- potentially dynamically updatable. Most values can be set using a value or a function,
--- and if functions are provided, they are re-evaluated every time the element is generated.

local log										= require("hs.logger").new("webui")

local base64									= require("hs.base64")
local fs										= require("hs.fs")
local image										= require("hs.image")

local html										= require("cp.web.html")
local tools										= require("cp.tools")

local _											= require("moses")
local mimetypes									= require("mimetypes")
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

--- cp.web.ui.javascript(script, context) -> cp.web.html
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
---  * a `cp.web.html` element representing the JavaScript block.
---
function ui.javascript(script, context)
	local t = compile(script, "no-cache", true)
	return html.script { type = "text/javascript" } (
		"(function(){\n" .. t(context) .. "\n})();", true
	)
end

--- cp.web.ui.heading(params) -> cp.web.html
--- Function
--- Creates a `cp.web.html` element for a heading with a specific level
---
--- Parameters:
---  * `params`	- The parameters table. Details below.
---
--- Returns:
---  * `cp.web.html` element representing the heading.
---
--- Notes:
---  * The `params` table has the following fields:
---  ** `text`		- The string (or function) containing the text of the heading.
---  ** `level` 		- The heading level (or function) (1-7). Defaults to 3.
---  ** `class`		- The CSS class (or function) for the heading tag.
function ui.heading(params)
	-- the level must be a number between 1 and 7.
	local level = evaluate(params.level) or 3
	assert(type(level) == "number" and level >= 1 and level <= 7)
	local tag = "h" .. level

	return html[tag] { class=params.class } (params.text)
end

--- cp.web.ui.template(params) -> hs.web.html
--- Function
--- Creates a `html` element that will execute a Resty Template.
---
--- Parameters:
---  * `params`	- The parameters table. Details below.
---
--- Returns:
---  * `cp.web.html` containing the template.
---
--- Notes:
---  * The `params` table has the following supported fields:
---  ** `view`		- The file path to the template, or the template content itself. Required.
---  ** `context`	- The table containing the context to execute the template in.
---  ** `unescaped`	- If true, the template will not be escaped before outputting.
function ui.template(params)
	local renderer = compile(params.view)
	return html(function() return renderer(params.context) end, params.unescaped)
end

--- cp.web.ui.textbox(params) -> hs.web.html
--- Function
--- Creates an `html` element that will output a text box.
---
--- Parameters:
---  * `params`	- The parameters table. Details below.
---
--- Returns:
---  * `cp.web.html` containing the textbox.
---
--- Notes:
---  * The `params` table has the following supported fields:
---  ** `id`				- The unique ID for the textbox.
---  ** `name`			- The name of the textbox field.
---  ** `class`			- The CSS classname.
---  ** `placeholder`	- Placeholder text.
---  ** `value`			- The default value of the textbox.
function ui.textbox(params)
	return html.input { type = "text", id = params.id, name = params.name, class = params.class, placeholder = params.placeholder, value = params.value }
end

--- cp.web.ui.password(params) -> hs.web.html
--- Function
--- Creates an `html` element that will output a password text box.
---
--- Parameters:
---  * `params`	- The parameters table. Details below.
---
--- Returns:
---  * `cp.web.html` containing the textbox.
---
--- Notes:
---  * The `params` table has the following supported fields:
---  ** `id`				- The unique ID for the textbox.
---  ** `name`			- The name of the textbox field.
---  ** `class`			- The CSS classname.
---  ** `placeholder`	- Placeholder text
function ui.password(params)
	return html.input { type = "password", id = params.id, name = params.name, class = params.class, placeholder = params.placeholder }
end

--- cp.web.ui.checkbox(params) -> cp.web.html
--- Constructor
--- Generates a HTML Checkbox element.
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
			value = params.value,
			checked,
			class = params.class,
		}
	else
		return ""
	end

end

--- cp.web.ui.button(params) -> cp.web.html
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
---  * The `params` can contain the following fields:
---  ** `value`		- The value of the button.
---  ** `label`		- The text label for the button. Defaults to the `value` if not provided.
---  ** `width`		- The width of the button in pixels.
function ui.button(params)
	params.label = params.label or params.value

	local style = nil
	if params.width then
		style = "width: " .. params.width .. "px;"
	end
	local class = "button"
	if params.class then
		class = class .. " " .. params.class
	end

	local result = html.a {
		id=params.id,
		style=style,
		class=class,
		href="#",
		value=params.value
	} (params.label)

	return result
end

--- cp.web.ui.select(params) -> cp.web.html
--- Function
--- Generates a `cp.web.html` `select` element. The `data` should be a table or a function returning a table
--- that matches the details in the notes below.
---
--- Parameters:
---  * `params`		- A table or function returning a table with the checkbox data.
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
	return html.select {
		id 		= params.id,
		name	= params.name or params.id,
		class	= params.class,
	} (optionGenerator, true)
end

-- Reads the file at the specified path as binary and returns it as a BASE64 stream of text.
local function imageToBase64(pathToImage)
	
	if not tools.doesFileExist(pathToImage) then
		log.ef("imageToBase64 failed - could not find file: %s", pathToImage)
		return ""				
	end

	local tempImage = image.imageFromPath(pathToImage)
	if tempImage then
		return tempImage:encodeAsURLString(false, "PNG")
	end
	
	return ""
	
end

--- cp.web.ui.img(params) -> cp.web.html
--- Function
--- Generates a `cp.web.html` `img` element.
---
--- Parameters:
---  * `params`		- A table or function returning a table with the checkbox data.
---
--- Returns:
---  * A `cp.web.html` with the select defined.
---
--- Notes:
---  * The `params` table has the following supported fields:
---  ** `src`		- The source of the image. If this points to a local file, it will be encoded as Base64.
---  ** `class`		- A string, (or function returning a string) with the CSS class for the element.
---  ** `width`		- The width of the image.
---  ** `height`	- The height of the image.
function ui.img(params)
	-- if the src is a local file path, load it as BASE64:
	assert(params.src ~= nil, "`ui.image` requires `params.src` to have a value.")
	local srcFile = fs.pathToAbsolute(params.src)
	if srcFile then
		params.src = imageToBase64(srcFile)
	end
	
	return html.img(params)
end

return ui