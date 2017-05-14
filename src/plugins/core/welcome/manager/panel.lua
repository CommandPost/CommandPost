--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                     P R E F E R E N C E S   M A N A G E R                  --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.welcome.manager.panel ===
---
--- CommandPost Welcome Window Panel.

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
-- CONSTANTS:
--
--------------------------------------------------------------------------------

--- plugins.core.welcome.manager.panel.DEFAULT_PRIORITY
--- Constant
--- The default priority for panels.
local DEFAULT_PRIORITY 							= 0

--- plugins.core.welcome.manager.panel.HANDLER_PRIORITY
--- Constant
--- The default priority for handler scripts.
local HANDLER_PRIORITY							= 1000000

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local panel = {}

-- The ID for the webview
panel.WEBVIEW_LABEL								= "welcome"

--- plugins.core.welcome.manager.panel.new(id, priority) -> plugins.core.welcome.manager.panel
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
		_content	=	{},
		_buttons	=	{},
		_footer		=	{},
	}
	return setmetatable(o, {__index = panel, __tostring = panel.__tostring})
end

-- outputs the panel as HTML.
function panel:__tostring()
	return tostring(self:generatePanel())
end

function panel:getToolbarItem()
	return {
		id			= self.id,
		priority	= self.priority,
		image		= self.image,
		label		= self.label,
		selectable	= true,
		tooltip		= self.tooltip,
	}
end

local function generateItems(items, class)
	local result = html.div {class = class}

	for i,item in ipairs(items) do
		-- log.df("generating item %d:\n%s", i, item.html)
		if item.html then
			result:append ("\n" .. item.html)
		end
	end

	return result
end

function panel:generatePanel()
	return html.div {class = "panel"} (
		self:generateContent() .. self:generateButtons() .. self:generateFooter()
	)
end

--------------------------------------------------------------------------------
-- GENERATE CONTENT:
--------------------------------------------------------------------------------
function panel:generateContent()
	return generateItems(self._content, "content")
end

--------------------------------------------------------------------------------
-- GENERATE CONTENT:
--------------------------------------------------------------------------------
function panel:generateButtons()
	return generateItems(self._buttons, "buttons")
end

function panel:generateFooter()
	return generateItems(self._footer, "footer")
end

local function getClass(params)
	local class = "uiItem"
	if params.class then
		class = class .. " " .. params.class
	end
	return class
end

local function addItem(items, priority, content, unescaped)
	priority = priority or DEFAULT_PRIORITY
	items[#items+1] = {
		priority = priority,
		html = html(content, unescaped),
	}
	table.sort(items, function(a, b) return a.priority < b.priority end)
end

--- plugins.core.welcome.manager.panel:addContent(priority, content) -> panel
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
function panel:addContent(priority, content, unescaped)
	addItem(self._content, priority, content, unescaped)
	return self
end

function panel:addFooter(priority, content, unescaped)
	addItem(self._footer, priority, content, unescaped)
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
	self:addFooter(HANDLER_PRIORITY, script)

	-- register the handler function
	self._handlers[id] = handlerFn
end

function panel:addParagraph(priority, content, unescaped, class)
	return self:addContent(priority, html.p { class=getClass({class=class}) } (content, unescaped))
end

--- plugins.core.welcome.manager.panel:addCheckbox(priority, params) -> panel
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
function panel:addCheckbox(priority, params)

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

	return self:addContent(priority, content)

end

--------------------------------------------------------------------------------
-- ADD HEADING:
--------------------------------------------------------------------------------
function panel:addHeading(priority, text)
	return self:addContent(priority, ui.heading({text=text, level=1}))
end

function panel:addSubHeading(priority, text)
	return self:addContent(priority, ui.heading({text=text, level=2}))
end


function panel:addTextbox(priority, params)
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

	return self:addContent(priority, content)
end

function panel:addPassword(priority, params)
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

	return self:addContent(priority, content)
end

function panel:addSelect(priority, params)

	-- set up default values
	params.id = params.id or uuid()

	-- created the select
	local select = html.p { class=getClass(params) } (
		html(params.label) .. ": " .. ui.select(params)
	)

	if params.onchange then
		self:addHandler("onchange", params.id, params.onchange, { "value" })
	end

	return self:addContent(priority, select)

end

function panel:addIcon(priority, params)

	-- set up default values
	params.id = params.id or uuid()
	params.class = params.class or "icon"
	params.class = getClass(params)

	return self:addContent(priority, ui.img(params))

end

--- plugins.core.welcome.manager.panel:addButton(priority, params) -> panel
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
function panel:addButton(priority, params)
	params.id = params.id or uuid()

	if params.onclick then
		self:addHandler("onclick", params.id, function(id, fnParams) return params.onclick(id, params.value) end, { "value" })
	end

	local content = ui.button(params)

	priority = priority or DEFAULT_PRIORITY

	addItem(self._buttons, priority, content, unescaped)

	return self
	
end


return panel