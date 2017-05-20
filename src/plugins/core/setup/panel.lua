--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                     P R E F E R E N C E S   M A N A G E R                  --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.setup.panel ===
---
--- CommandPost Setup Window Panel.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("prefPanel")

local uuid										= require("hs.host").uuid

local html										= require("cp.web.html")
local ui										= require("cp.web.ui")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local panel = {}

-- The ID for the webview
panel.WEBVIEW_LABEL								= "setup"

--- plugins.core.setup.panel.new(id, priority) -> plugins.core.setup.panel
--- Constructor
--- Constructs a new panel with the specified priority and ID.
---
--- Parameters:
---  * priority	- Defines the order in which the panel appears.
---  * id		- The unique ID for the panel.
function panel.new(id, priority)
	local o = {
		id			=	id,
		priority	=	priority,
		_handlers	=	{},
		_content	=	html.div {class = "content"},
		_buttons	=	html.div {class = "buttons"},
		_footer		=	html.div {class = "footer"},
	}
	o._panel = html.div {class = "panel"} (o._content .. o._buttons .. o._footer)
	return setmetatable(o, {__index = panel, __tostring = panel.__tostring})
end

-- outputs the panel as HTML.
function panel:__tostring()
	return tostring(self._panel)
end

local function getClass(params)
	local class = "uiItem"
	if params.class then
		class = class .. " " .. params.class
	end
	return class
end

--- plugins.core.setup.panel:addContent(content) -> panel
--- Method
--- Adds the specified `content` to the panel, with the specified `priority` order.
---
--- Parameters:
--- * `priority`		- the priority order of the content.
--- * `content`			- a value that can be converted to a string.
--- * `unescaped`		- if `true`, the content will not be escaped. Defaults to true.
---
--- Returns:
--- * The panel.
function panel:addContent(content, unescaped)
	self._content(content, unescaped)
	return self
end

function panel:addFooter(content, unescaped)
	self._footer(content, unescaped)
	return self
end

function panel:getHandler(id)
	return self._handlers[id]
end

function panel:addHandler(event, id, handlerFn, keys)
	-- initialise the keys
	keys = keys or {}

	-- create the script
	local script = ui.javascript([[
		var e = document.getElementById("{{ id }}");
		if (e == null) return;
		e.{{ event }} = function (){
			try {
				var p = {};
				{% for _,key in ipairs(keys) do %}
				var key = "{{ key }}";
				p[key] = e[key];
				p[key] = p[key] != undefined ? p[key] : e.getAttribute(key);
				p[key] = p[key] != undefined ? p[key] : e.dataset[key];
				{% end %}
				var result = { id: "{{ id }}", params: p };
				webkit.messageHandlers.{{ name }}.postMessage(result);
			} catch(err) {
				alert('An error has occurred. Does the controller exist yet?');
			}
		}
	]], { event=event, id=id, keys=keys, name=panel.WEBVIEW_LABEL })

	-- add the script to the panel.
	self:addFooter(script)

	-- register the handler function
	self._handlers[id] = handlerFn
end

function panel:addParagraph(content, unescaped, class)
	return self:addContent(html.p { class=getClass({class=class}) } (content, unescaped))
end

--- plugins.core.setup.panel:addCheckbox(params) -> panel
--- Method
--- Adds a checkbox to the panel with the specified `priority` and `params`.
---
--- Parameters:
---  * `priority`	- The priority number for the checkbox.
---  * `params`		- The set of parameters for the checkbox.
---
--- Returns:
---  * The panel.
--- Notes:
--- * The `params` can contain the following fields:
--- ** `id`			- (optional) The unique ID. If none is provided, one will be generated.
--- ** `name`		- (optional) The name of the checkbox field.
--- ** `label`		- (optional) The text label to display after the checkbox.
--- ** `onchange`	- (optional) a function that will get called when the checkbox value changes. It will be passed two parameters, `id` and `params`, the latter of which is a table containing the `value` and `checked` values of the checkbox.
--- ** `class`		- (optional) the CSS class list to apply to the checkbox.
function panel:addCheckbox(params)

	params.id = params.id or uuid()

	local checkbox = ui.checkbox(params)

	if params.label then
		local label = html (params.label)
		checkbox = html.label ( checkbox .. " " .. label )
	end

	local content = html.p { class=getClass(params) } (	checkbox )

	if params.onchange then
		self:addHandler("onchange", params.id, params.onchange, { "value", "checked" })
	end

	return self:addContent(content)

end

--------------------------------------------------------------------------------
-- ADD HEADING:
--------------------------------------------------------------------------------
function panel:addHeading(text)
	return self:addContent(ui.heading({text=text, level=1}))
end

function panel:addSubHeading(text)
	return self:addContent(ui.heading({text=text, level=2}))
end


function panel:addTextbox(params)
	params.id = params.id or uuid()

	local textbox = ui.textbox(params)
	if params.label then
		local label = html (params.label)
		textbox = html.label (label .. " " .. textbox)
	end

	local content = html.p { class=getClass(params) } ( textbox )

	if params.onchange then
		self:addHandler("onchange", params.id, params.onchange, { "value" })
	end

	return self:addContent(content)
end

function panel:addPassword(params)
	params.id = params.id or uuid()

	local textbox = ui.password(params)
	if params.label then
		local label = html (params.label)
		textbox = html.label (label .. " " .. textbox)
	end

	local content = html.p { class=getClass(params) } ( textbox )

	if params.onchange then
		self:addHandler("onchange", params.id, params.onchange, { "value" })
	end

	return self:addContent(content)
end

function panel:addSelect(params)

	-- set up default values
	params.id = params.id or uuid()

	-- created the select
	local select = html.p { class=getClass(params) } (
		html(params.label) .. ": " .. ui.select(params)
	)

	if params.onchange then
		self:addHandler("onchange", params.id, params.onchange, { "value" })
	end

	return self:addContent(select)

end

function panel:addIcon(src)
	local params = {}
	-- set up default values
	params.id = uuid()
	params.class = "icon"
	params.class = getClass(params)
	params.src = src

	return self:addContent(ui.img(params))

end

--- plugins.core.setup.panel:addButton(params) -> panel
--- Method
--- Adds a button with the specified priority and parameters.
---
--- Parameters:
---  * priority	- Defines the order in which the panel appears.
---  * params	- The list of parameters.
---
--- Returns:
---  * The same panel.
---
--- Notes:
---  * The `params` table may contain:
---  ** `id`		- (optional) the unique ID for the button. If none is provided, one is generated.
---  ** `value`		- The value of the button. This is sent to the `onclick` function.
---  ** `label`		- The text label for the button. Defaults to the `value` if not provided.
---  ** `width`		- The width of the button in pixels.
---  ** `onclick`	- the function to execute when the button is clicked. The function should have the signature of `function(id, value)`, where `id` is the id of the button that was clicked, and `value` is the value of the button.
function panel:addButton(params)
	params.id = params.id or uuid()

	if params.onclick then
		self:addHandler("onclick", params.id, function(id, fnParams) return params.onclick(id, fnParams.value) end, { "value" })
	end

	self._buttons(ui.button(params))

	return self
	
end


return panel