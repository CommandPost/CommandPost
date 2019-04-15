--- === plugins.core.setup.panel ===
---
--- CommandPost Setup Window Panel.

local require = require

local host    = require("hs.host")

local html    = require("cp.web.html")
local ui      = require("cp.web.ui")

local uuid    = host.uuid


local panel = {}

--- plugins.core.setup.panel.WEBVIEW_LABEL -> string
--- Constant
--- The ID for the Webview
panel.WEBVIEW_LABEL = "setup"

--- plugins.core.setup.panel.new(id, priority) -> plugins.core.setup.panel
--- Constructor
--- Constructs a new panel with the specified priority and ID.
---
--- Parameters:
---  * priority - Defines the order in which the panel appears.
---  * id       - The unique ID for the panel.
function panel.new(id, priority)
    local o = {
        id          =   id,
        priority    =   priority,
        _handlers   =   {},
        _content    =   html.div {class = "content"},
        _buttons    =   html.div {class = "buttons"},
        _footer     =   html.div {class = "footer"},
    }
    o._panel = html.div {class = "panel"} (o._content .. o._buttons .. o._footer)
    return setmetatable(o, {__index = panel, __tostring = panel.__tostring})
end

-- plugins.core.setup.panel:__tostring() -> none
-- Method
-- Outputs the panel as HTML.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function panel:__tostring()
    return tostring(self._panel)
end

-- getClass(params) -> string
-- Function
-- Gets the class value from a parameters table
--
-- Parameters:
--  * params - The parameters in a table
--
-- Returns:
--  * Class as string
local function getClass(params)
    local class = "uiItem"
    if params.class then
        class = class .. " " .. params.class
    end
    return class
end

--- plugins.core.setup.panel:addContent(content[, escaped]) -> panel
--- Method
--- Adds the specified `content` to the panel.
---
--- Parameters:
--- * `content` - a value that can be converted to a string.
--- * `escaped` - if `true`, the content will not be escaped. Defaults to true.
---
--- Returns:
--- * The panel.
function panel:addContent(content, escaped)
    self._content(content, escaped)
    return self
end

--- plugins.core.setup.panel:addFooter(content, unescaped) -> panel
--- Method
--- Adds the specified `content` to the panel's footer.
---
--- Parameters:
--- * `content` - a value that can be converted to a string.
--- * `unescaped` - if `true`, the content will not be escaped. Defaults to true.
---
--- Returns:
--- * The panel.
function panel:addFooter(content, unescaped)
    self._footer(content, unescaped)
    return self
end

--- plugins.core.setup.panel:getHandler(id) -> handler
--- Method
--- Gets a handler from an Handler ID
---
--- Parameters:
--- * `id` - the Handler ID
---
--- Returns:
--- * A handler.
function panel:getHandler(id)
    return self._handlers[id]
end

--- plugins.core.setup.panel:addHandler(event, id, handlerFn, keys) -> none
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
    ]], { event=event, id=id, keys=keys, name=panel.WEBVIEW_LABEL })

    --------------------------------------------------------------------------------
    -- Add the script to the panel:
    --------------------------------------------------------------------------------
    self:addFooter(script)

    --------------------------------------------------------------------------------
    -- Register the handler function:
    --------------------------------------------------------------------------------
    self._handlers[id] = handlerFn
end

--- plugins.core.setup.panel:addParagraph(content[, escaped[, class]]) -> panel
--- Method
--- Adds a Paragraph to the panel
---
--- Parameters:
---  * content - The content as a string
---  * escaped - Whether or not the HTML should be escaped as a boolean
---  * class - The class as a string
---
--- Returns:
--- * The panel object.
function panel:addParagraph(content, escaped, class)
    return self:addContent(html.p { class=getClass({class=class}) } (content, escaped))
end

--- plugins.core.setup.panel:addCheckbox(params) -> panel
--- Method
--- Adds a checkbox to the panel with the specified `priority` and `params`.
---
--- Parameters:
---  * `priority`   - The priority number for the checkbox.
---  * `params`     - The set of parameters for the checkbox.
---
--- Returns:
--- * The panel object.
---
--- Notes:
---  * The `params` can contain the following fields:
---  ** `id`        - (optional) The unique ID. If none is provided, one will be generated.
---  ** `name`      - (optional) The name of the checkbox field.
---  ** `label`     - (optional) The text label to display after the checkbox.
---  ** `onchange`  - (optional) a function that will get called when the checkbox value changes. It will be passed two parameters, `id` and `params`, the latter of which is a table containing the `value` and `checked` values of the checkbox.
---  ** `class`     - (optional) the CSS class list to apply to the checkbox.
function panel:addCheckbox(params)

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

    return self:addContent(content)

end

--- plugins.core.setup.panel:addHeading(text) -> panel
--- Method
--- Adds a heading to the panel
---
--- Parameters:
---  * text - The text of the heading as a string
---
--- Returns:
--- * The panel object.
function panel:addHeading(text)
    return self:addContent(ui.heading({text=text, level=1}))
end

--- plugins.core.setup.panel:addSubHeading(text) -> panel
--- Method
--- Adds a sub-heading to the panel
---
--- Parameters:
---  * text - The text of the sub-heading as a string
---
--- Returns:
--- * The panel object.
function panel:addSubHeading(text)
    return self:addContent(ui.heading({text=text, level=2}))
end

--- plugins.core.setup.panel:addTextbox(params) -> panel
--- Method
--- Adds a text-box to the panel
---
--- Parameters:
---  * params - A table of parameters
---
--- Returns:
--- * The panel object.
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

--- plugins.core.setup.panel:addPassword(params) -> panel
--- Method
--- Adds a password text-box to the panel.
---
--- Parameters:
---  * params - A table of parameters
---
--- Returns:
--- * The panel object.
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

--- plugins.core.setup.panel:addSelect(params) -> panel
--- Method
--- Adds a select to the panel.
---
--- Parameters:
---  * params - A table of parameters
---
--- Returns:
--- * The panel object.
function panel:addSelect(params)

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

    return self:addContent(select)

end

--- plugins.core.setup.panel:addIcon(src) -> panel
--- Method
--- Adds an icon to the panel.
---
--- Parameters:
---  * src - Location of the icon.
---
--- Returns:
--- * The panel object.
function panel:addIcon(src)
    --------------------------------------------------------------------------------
    -- Set up default values:
    --------------------------------------------------------------------------------
    local params = {}
    params.id = uuid()
    params.class = "icon"
    params.class = getClass(params)
    params.src = src
    return self:addContent(ui.img(params))
end

--- plugins.core.setup.panel:addButton(params) -> panel
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
function panel:addButton(params)
    params.id = params.id or uuid()

    if params.onclick then
        self:addHandler("onclick", params.id, function(id, fnParams) return params.onclick(id, fnParams.value) end, { "value" })
    end

    self._buttons(ui.button(params))

    return self

end

return panel
