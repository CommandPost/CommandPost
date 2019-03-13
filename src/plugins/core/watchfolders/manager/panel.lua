--- === plugins.core.watchfolders.manager.panel ===
---
--- Watch Folder Panel Manager.

local require = require

local host      = require("hs.host")

local html      = require("cp.web.html")
local ui        = require("cp.web.ui")

local uuid      = host.uuid

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local panel = {}

-- DEFAULT_PRIORITY -> number
-- Constant
-- The default priority for panels.
local DEFAULT_PRIORITY = 0

-- HANDLER_PRIORITY -> number
-- Constant
-- The default priority for handler scripts.
local HANDLER_PRIORITY = 1000000

--- plugins.core.watchfolders.manager.panel.new(priority, id) -> panel object
--- Constructor
--- Constructs a new panel with the specified priority and ID.
---
--- Parameters:
---  * priority - Defines the order in which the panel appears.
---  * id       - The unique ID for the panel.
---  * webview  - The webview the panel is attached to.
---
--- Returns:
---  * A panel object
function panel.new(params, manager)
    local o = {
        id          =   params.id,
        priority    =   params.priority,
        label       =   params.label,
        image       =   params.image,
        tooltip     =   params.tooltip,
        height      =   params.height,
        loadFn      =   params.loadFn,
        manager     =   manager,
        _handlers   =   {},
        _uiItems    =   {},
    }
    setmetatable(o, panel)
    panel.__index = panel
    return o
end

--- plugins.core.watchfolders.manager.panel:getToolbarItem() -> table
--- Method
--- Returns a Toolbar Item
---
--- Parameters:
---  * None
---
--- Returns:
---  * Table of Toolbar Item Values
function panel:getToolbarItem()
    return {
        id          = self.id,
        priority    = self.priority,
        image       = self.image,
        label       = self.label,
        selectable  = true,
        tooltip     = self.tooltip,
    }
end

--- plugins.core.watchfolders.manager.panel:generateContent() -> string
--- Method
--- Gets generated toolbar content
---
--- Parameters:
---  * None
---
--- Returns:
---  * A string of generated content
function panel:generateContent()
    local result = ""
    table.sort(self._uiItems, function(a, b) return a.priority < b.priority end)
    for _,item in ipairs(self._uiItems) do
        if item.html then
            result = result .. "\n" .. tostring(item.html)
        end
    end
    return result
end

-- getClass(params) -> string
-- Function
-- Gets a class from the supplied parameters
--
-- Parameters:
--  * params - Table of parameters
--
-- Returns:
--  * A class as a string
local function getClass(params)
    local class = "uiItem"
    if params.class then
        class = class .. " " .. params.class
    end
    return class
end

--- plugins.core.watchfolders.manager.panel:addContent(priority, content[, escaped]) -> panel
--- Method
--- Adds the specified `content` to the panel, with the specified `priority` order.
---
--- Parameters:
---  * `priority` - the priority order of the content.
---  * `content` - a value that can be converted to a string.
---  * `escaped` - if `true`, the content will be escaped.
---
--- Returns:
---  * The panel object
function panel:addContent(priority, content, escaped)
    priority = priority or DEFAULT_PRIORITY
    local items = self._uiItems
    items[#items+1] = {
        priority = priority,
        html = html(content, escaped),
    }
    return self
end

--- plugins.core.watchfolders.manager.panel:addHandler(event, id, handlerFn, keys) -> none
--- Method
--- Adds a handler
---
--- Parameters:
---  * event - The JavaScript event as string
---  * id - The ID as string
---  * handlerFn - The handler function
---  * keys - Table of keys
---
--- Returns:
---  * The panel object
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

--- plugins.core.watchfolders.manager.panel:addParagraph(priority, content[, escaped[, class]]) -> panel
--- Method
--- Adds a paragraph to the panel with the specified `priority` and `content`.
---
--- Parameters:
---  * `priority` - The priority number for the paragraph.
---  * `content` - The content you want to include as a string.
---  * `escaped` - Whether or not the HTML is escaped as a boolean.
---  * `class` - The class name as a string.
---
--- Returns:
---  * The panel object
function panel:addParagraph(priority, content, escaped, class)
    return self:addContent(priority, html.p { class=getClass({class=class}) } (content, escaped))
end

--- plugins.core.watchfolders.manager.panel:addCheckbox(priority, params) -> panel
--- Method
--- Adds a checkbox to the panel with the specified `priority` and `params`.
---
--- Parameters:
---  * `priority`   - The priority number for the checkbox.
---  * `params`     - The set of parameters for the checkbox.
---
--- Returns:
---  * The panel.
---
--- Notes:
---  * The `params` can contain the following fields:
---  ** `id`        - (optional) The unique ID. If none is provided, one will be generated.
---  ** `name`      - (optional) The name of the checkbox field.
---  ** `label`     - (optional) The text label to display after the checkbox.
---  ** `onchange`  - (optional) a function that will get called when the checkbox value changes. It will be passed two parameters, `id` and `params`, the latter of which is a table containing the `value` and `checked` values of the checkbox.
---  ** `class`     - (optional) the CSS class list to apply to the checkbox.
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

--- plugins.core.watchfolders.manager.panel:addHeading(priority, text, level) -> panel
--- Method
--- Adds a heading to the panel with the specified `priority` and `text`.
---
--- Parameters:
---  * `priority` - The priority number for the heading.
---  * `text` - The content of the heading as a string.
---  * `level` - The level of the heading.
---
--- Returns:
---  * The panel object
function panel:addHeading(priority, text, level)
    return self:addContent(priority, ui.heading({text=text, level=level, class="uiItem"}))
end

--- plugins.core.watchfolders.manager.panel:addTextbox(priority, params) -> panel
--- Method
--- Adds a textbox to the panel with the specified `priority` and `params`.
---
--- Parameters:
---  * `priority`   - The priority number for the textbox.
---  * `params`     - The set of parameters for the textbox.
---
--- Returns:
---  * The panel.
function panel:addTextbox(priority, params)
    params.id = params.id or uuid()

    local textbox = ui.textbox(params)
    if params.label then
        local label = html (params.label)
        local result = html.label (label)
        textbox = result .. " " .. textbox
    end

    local content = html.p { class=getClass(params) } ( textbox )

    if params.onchange then
        self:addHandler("onchange", params.id, params.onchange, { "value" })
    end

    return self:addContent(priority, content)
end

--- plugins.core.watchfolders.manager.panel:addPassword(priority, params) -> panel
--- Method
--- Adds a password textbox to the panel with the specified `priority` and `params`.
---
--- Parameters:
---  * `priority`   - The priority number for the password.
---  * `params`     - The set of parameters for the password.
---
--- Returns:
---  * The panel.
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

--- plugins.core.watchfolders.manager.panel:addButton(priority, params, itemFn, customWidth) -> panel
--- Method
--- Adds a button to the panel with the specified `priority` and `params`.
---
--- Parameters:
---  * `priority` - The priority number for the button.
---  * `params` - The set of parameters for the button.
---
--- Returns:
---  * The panel.
function panel:addButton(priority, params)
    params.id = params.id or uuid()

    if params.onclick then
        self:addHandler("onclick", params.id, params.onclick, { "value" })
    end

    local content = html.p { class=getClass(params) } (ui.button(params))

    return self:addContent( priority, content )
end

--- plugins.core.watchfolders.manager.panel:addSelect(priority, params) -> panel
--- Method
--- Adds a select to the panel with the specified `priority` and `params`.
---
--- Parameters:
---  * `priority` - The priority number for the select.
---  * `params` - The set of parameters for the select.
---
--- Returns:
---  * The panel.
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
