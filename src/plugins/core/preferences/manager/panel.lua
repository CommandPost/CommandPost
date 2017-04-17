--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                     P R E F E R E N C E S   M A N A G E R                  --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === core.preferences.manager.panel ===
---
--- CommandPost Preferences Panel.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("prefPanel")

local html										= require("cp.web.html")
local ui										= require("cp.web.ui")
local uuid										= require("cp.uuid")

--- core.preferences.manager.panel.DEFAULT_PRIORITY
--- Constant
--- The default priority for panels.
local DEFAULT_PRIORITY 							= 0

--- core.preferences.manager.panel.HANDLER_PRIORITY
--- Constant
--- The default priority for handler scripts.
local HANDLER_PRIORITY							= 1000000

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local panel = {}

--- cp.core.preferences.manager.panel.new(priority, id) -> cp.core.preferences.manager.panel
--- Constructor
--- Constructs a new panel with the specified priority and ID.
---
--- Parameters:
--- * priority	- Defines the order in which the panel appears.
--- * id		- The unique ID for the panel.
--- * webview	- The webview the panel is attached to.
function panel.new(params, manager)
	local o = {
		id			=	params.id,
		priority	=	params.priority,
		label		=	params.label,
		image		=	params.image,
		tooltip		=	params.tooltip,
		manager		=	manager,
		_handlers	=	{},
		_uiItems	=	{},
	}
	setmetatable(o, panel)
	panel.__index = panel
	return o
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

--------------------------------------------------------------------------------
-- GENERATE CONTENT:
--------------------------------------------------------------------------------
function panel:generateContent()
	-- log.df("generating panel: %s", self.id)

	local result = ""

	table.sort(self._uiItems, function(a, b) return a.priority < b.priority end)
	for i,item in ipairs(self._uiItems) do
		-- log.df("generating item %d:\n%s", i, item.html)
		if item.html then
			result = result .. "\n" .. tostring(item.html)
		end
	end

	return result
end

--- core.preferences.manager.panel:addContent(priority, content) -> panel
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
	-- log.df("addContent to '%s': %s", self.id, hs.inspect(content))
	priority = priority or DEFAULT_PRIORITY
	
	local items = self._uiItems
	items[#items+1] = {
		priority = priority,
		html = html(content, unescaped),
	}
	return self
end

function panel:addHandler(event, id, handlerFn, keys)
	-- initialise the keys
	keys = keys or {}
	
	-- create the script
	local script = ui.javascript([[
		var element = document.getElementById("{{ id }}");
		if (element == null) return;
		element.{{ event }} = function (){
			try {
				var params = {};
				{% for _,key in ipairs(keys) do %}
				params["{{ key }}"] = element.getAttribute("{{ key }}") || element.dataset["{{ key }}"];
				{% end %} 
				var result = { id: "{{ id }}", params: params };
				webkit.messageHandlers.{{ name }}.postMessage(result);
			} catch(err) {
				alert('An error has occurred. Does the controller exist yet?');
			}
		}
	]], { event=event, id=id, keys=keys, name=self.manager:getLabel() })
	
	-- add the script to the panel.
	self:addContent(HANDLER_PRIORITY, script)
	
	-- register the handler function
	self.manager.addHandler(id, handlerFn)
end

function panel:addParagraph(priority, content, unescaped)
	return self:addContent(priority, html.p { class="uiItem" } (content, unescaped))
end

--- core.preferences.manager.panel:addCheckbox(priority, params) -> panel
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

	params.id = evaluate(params.id) or uuid()
	
	local checkbox = ui.checkbox(params)
	
	if params.label then
		local label = html (params.label)
		checkbox = html.label ( checkbox .. " " .. label )
	end
	
	local content = html.p { class="uiItem" } (	checkbox )
	
	if params.onchange then
		self:addHandler("onchange", params.id, params.onchange, { "value", "checked" })
	end
	
	return self:addContent(priority, content)

end

--------------------------------------------------------------------------------
-- ADD HEADING:
--------------------------------------------------------------------------------
function panel:addHeading(priority, text, level)
	return self:addContent(priority, ui.heading({text=text, level=level, class="uiItem"}))
end

--------------------------------------------------------------------------------
-- ADD BUTTON:
--------------------------------------------------------------------------------
function panel:addButton(priority, params, itemFn, customWidth)
	params.id = params.id or uuid()
	
	if params.onclick then
		self:addHandler("onclick", params.id, params.onclick, { "value" })
	end
	
	local content = html.p { class="uiItem" } (ui.button(params))

	return self:addContent( priority, content )
end

function panel:addSelect(priority, params)

	-- set up default values
	params.id = params.id or uuid()
	
	-- created the select
	local select = html.p { class="uiItem" } (
		html(params.label) .. ": " .. ui.select(params)
	)
	
	if params.onchange then
		self:addHandler("onchange", params.id, params.onchange, { "value" })
	end

	return self:addContent(priority, select)
	
end

return panel