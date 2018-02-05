--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                     P R E F E R E N C E S   M A N A G E R                  --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.preferences.manager.panel ===
---
--- CommandPost Preferences Panel.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
--local log                                       = require("hs.logger").new("prefPanel")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local uuid                                      = require("hs.host").uuid

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local html                                      = require("cp.web.html")
local ui                                        = require("cp.web.ui")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

--- plugins.core.preferences.manager.panel.DEFAULT_PRIORITY -> number
--- Constant
--- The default priority for panels.
local DEFAULT_PRIORITY = 0

--- plugins.core.preferences.manager.panel.HANDLER_PRIORITY -> number
--- Constant
--- The default priority for handler scripts.
local HANDLER_PRIORITY = 1000000

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local panel = {}

--- plugins.core.preferences.manager.panel.new(priority, id) -> cp.core.preferences.manager.panel
--- Constructor
--- Constructs a new panel with the specified priority and ID.
---
--- Parameters:
--- * priority  - Defines the order in which the panel appears.
--- * id        - The unique ID for the panel.
--- * webview   - The webview the panel is attached to.
function panel.new(params, manager)
    local o = {
        id          =   params.id,
        priority    =   params.priority,
        label       =   params.label,
        image       =   params.image,
        tooltip     =   params.tooltip,
        height      =   params.height,
        closeFn     =   params.closeFn,
        manager     =   manager,
        _handlers   =   {},
        _uiItems    =   {},
    }
    setmetatable(o, panel)
    panel.__index = panel
    return o
end

--- plugins.core.preferences.manager.panel:getToolbarItem() -> table
--- Method
--- Gets the Tool Bar as a table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The toolbar item as a table.
function panel:getToolbarItem()
    return {
        id          = self.id,
        priority    = self.priority,
        default     = true,
        image       = self.image,
        label       = self.label,
        selectable  = true,
        tooltip     = self.tooltip,
    }
end

-- generateContent() -> string
-- Function
-- Generates HTML content.
--
-- Parameters:
--  * None
--
-- Returns:
--  * HTML Content as a string
function panel:generateContent()
    -- log.df("generating panel: %s", self.id)

    local result = ""

    table.sort(self._uiItems, function(a, b) return a.priority < b.priority end)
    for _,item in ipairs(self._uiItems) do
        -- log.df("generating item %d:\n%s", i, item.html)
        if item.html then
            result = result .. "\n" .. tostring(item.html)
        end
    end

    return result
end

-- getClass(params) -> string
-- Function
-- Gets the class name from a table of parameters.
--
-- Parameters:
--  * None
--
-- Returns:
--  * The class name as a string.
local function getClass(params)
    local class = "uiItem"
    if params.class then
        class = class .. " " .. params.class
    end
    return class
end

--- plugins.core.preferences.manager.panel:addContent(priority, content, unescaped) -> panel
--- Method
--- Adds the specified `content` to the panel, with the specified `priority` order.
---
--- Parameters:
--- * `priority`        - the priority order of the content.
--- * `content`         - a value that can be converted to a string.
--- * `unescaped`       - if `true`, the content will not be escaped. Defaults to `false`.
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

--- plugins.core.preferences.manager.panel:addHandler(event, id, handlerFn, keys) -> none
--- Method
--- Gets a handler from an Handler ID
---
--- Parameters:
---  * event - The event
---  * id - the Handler ID
---  * handlerFn - The Handler function
---  * keys - Keys
---
--- Returns:
---  * None
function panel:addHandler(event, id, handlerFn, keys)

    --------------------------------------------------------------------------------
    -- Initialise the keys:
    --------------------------------------------------------------------------------
    keys = keys or {}

    --------------------------------------------------------------------------------
    -- Create the script:
    --------------------------------------------------------------------------------
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
    ]], { event=event, id=id, keys=keys, name=self.manager:getLabel() })

    --------------------------------------------------------------------------------
    -- Add the script to the panel:
    --------------------------------------------------------------------------------
    self:addContent(HANDLER_PRIORITY, script)

    --------------------------------------------------------------------------------
    -- Register the handler function:
    --------------------------------------------------------------------------------
    self.manager.addHandler(id, handlerFn)
end

--- plugins.core.preferences.manager.panel:addParagraph(content, unescaped, class) -> panel
--- Method
--- Adds a Paragraph to the panel
---
--- Parameters:
---  * content - The content as a string
---  * unescaped - Whether or not the HTML should be escaped as a boolean
---  * class - The class as a string
---
--- Returns:
--- * The panel object.
function panel:addParagraph(priority, content, unescaped, class)
    return self:addContent(priority, html.p { class=getClass({class=class}) } (content, unescaped))
end

--- plugins.core.preferences.manager.panel:addCheckbox(priority, params) -> panel
--- Method
--- Adds a checkbox to the panel with the specified `priority` and `params`.
---
--- Parameters:
---  * `priority`   - The priority number for the checkbox.
---  * `params`     - The set of parameters for the checkbox.
---
--- Returns:
---  * The panel.
--- Notes:
---  * The `params` can contain the following fields:
---  ** `id`         - (optional) The unique ID. If none is provided, one will be generated.
---  ** `name`       - (optional) The name of the checkbox field.
---  ** `label`      - (optional) The text label to display after the checkbox.
---  ** `onchange`   - (optional) a function that will get called when the checkbox value changes. It will be passed two parameters, `id` and `params`, the latter of which is a table containing the `value` and `checked` values of the checkbox.
---  ** `class`      - (optional) the CSS class list to apply to the checkbox.
function panel:addCheckbox(priority, params)

    params.id = params.id or uuid()

    local checkbox = ui.checkbox(params)

    if params.label then
        local label = html (params.label)
        checkbox = html.label ( checkbox .. " " .. label )
    end

    local content = html.p { class=getClass(params) } ( checkbox )

    if params.onchange then
        self:addHandler("onchange", params.id, params.onchange, { "value", "checked" })
    end

    return self:addContent(priority, content)

end

--- plugins.core.preferences.manager.panel:addHeading(text) -> panel
--- Method
--- Adds a heading to the panel
---
--- Parameters:
---  * text - The text of the heading as a string
---
--- Returns:
--- * The panel object.
function panel:addHeading(priority, text, level)
    return self:addContent(priority, ui.heading({text=text, level=level, class="uiItem"}))
end

--- plugins.core.preferences.manager.panel:addTextbox(params) -> panel
--- Method
--- Adds a text-box to the panel
---
--- Parameters:
---  * params - A table of parameters
---
--- Returns:
--- * The panel object.
function panel:addTextbox(priority, params)
    params.id = params.id or uuid()

    local textbox = ui.textbox(params)
    if params.label then
        local label = html (params.label)
        textbox = html.label (label) .. " " .. textbox
    end

    local content = html.p { class=getClass(params) } ( textbox )

    if params.onchange then
        self:addHandler("onchange", params.id, params.onchange, { "value" })
    end

    return self:addContent(priority, content)
end

--- plugins.core.preferences.manager.panel:addPassword(params) -> panel
--- Method
--- Adds a password text-box to the panel.
---
--- Parameters:
---  * params - A table of parameters
---
--- Returns:
--- * The panel object.
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

--- plugins.core.preferences.manager.panel:addButton(params) -> panel
--- Method
--- Adds a button to the panel.
---
--- Parameters:
---  * params - The list of parameters.
---
--- Returns:
---  * The same panel.
---
--- Notes:
---  * The `params` table may contain:
---  ** `id`        - (optional) the unique ID for the button. If none is provided, one is generated.
---  ** `value`     - The value of the button. This is sent to the `onclick` function.
---  ** `label`     - The text label for the button. Defaults to the `value` if not provided.
---  ** `width`     - The width of the button in pixels.
---  ** `onclick`   - the function to execute when the button is clicked. The function should have the signature of `function(id, value)`, where `id` is the id of the button that was clicked, and `value` is the value of the button.
function panel:addButton(priority, params)
    params.id = params.id or uuid()

    if params.onclick then
        self:addHandler("onclick", params.id, params.onclick, { "value" })
    end

    local content = html.p { class=getClass(params) } (ui.button(params))

    return self:addContent( priority, content )
end

--- plugins.core.preferences.manager.panel:addSelect(params) -> panel
--- Method
--- Adds a select to the panel.
---
--- Parameters:
---  * params - A table of parameters
---
--- Returns:
--- * The panel object.
function panel:addSelect(priority, params)

    --------------------------------------------------------------------------------
    -- Set up default values:
    --------------------------------------------------------------------------------
    params.id = params.id or uuid()

    --------------------------------------------------------------------------------
    -- Create the select:
    --------------------------------------------------------------------------------
    local select = html.p { class=getClass(params) } (
        html(params.label) .. ": " .. ui.select(params)
    )

    if params.onchange then
        self:addHandler("onchange", params.id, params.onchange, { "value" })
    end

    return self:addContent(priority, select)

end

return panel
