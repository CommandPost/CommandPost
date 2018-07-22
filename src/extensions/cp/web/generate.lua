--- === cp.web.generate ===
---
--- Functions for Generating HTML UI Items

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require
-- local log										= require("hs.logger").new("prefsGenerate")
local mimetypes									= require("mimetypes")
local base64									= require("hs.base64")
local fs										= require("hs.fs")
local template									= require("resty.template")
local html										= require("cp.web.html")

local compile									= template.compile

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--------------------------------------------------------------------------------
-- CONSTANTS:
--------------------------------------------------------------------------------
mod.UI_CHECKBOX								= 1
mod.UI_HEADING								= 2
mod.UI_BUTTON								= 3
mod.UI_DROPDOWN								= 4
mod.UI_TEXT									= 5

--------------------------------------------------------------------------------
-- RANDOM STRING GENERATOR:
--------------------------------------------------------------------------------
local function randomLetter()
    local str="abcdefghijklmnopqrstuvwxyz"
    return string.char(str:byte(math.random(1, #str)))
end

--------------------------------------------------------------------------------
-- RANDOM WORD GENERATOR:
--------------------------------------------------------------------------------
local function randomWord(length)
    local result = ""
    for _ = 1,length do
        result = result .. randomLetter()
    end
    return result
end

--- cp.web.generate.setWebviewLabel() -> none
--- Function
--- Sets the WebView Label
---
--- Parameters:
---  * value - WebView Label as string
---
--- Returns:
---  * None
function mod.setWebviewLabel(value)
    mod._webviewLabel = value
end

--- cp.web.generate.checkbox() -> string
--- Function
--- Generates a HTML Checkbox
---
--- Parameters:
---  * data - Table containing the data you want to display on the Checkbox
---  * customTrigger - Custom label used for JavaScript Callback
---  * customID - Custom ID used for the HTML objects
---
--- Returns:
---  * String containing the HTML
function mod.checkbox(data, customTrigger, customID)

    local value = customTrigger or data.title

    local isChecked = data.checked and "checked" or ""

    local id = "checkbox" .. randomWord(20)
    if customID then id = customID end

    local result = html.p { class = "uiItem" } (
        html.input { type = "checkbox", id = id, value = "", isChecked } .. data.title
    ) .. mod.javascript([[
        var checkbox = document.getElementById("{{ id }}");
        checkbox.onchange = function (){
            try {
                var checked = checkbox.checked;
                var result = ["{{ value }}", checked];
                webkit.messageHandlers.{{ name }}.postMessage(result);
            } catch(err) {
                alert('An error has occurred. Does the controller exist yet?');
            }
        }
    ]], { id = id, value = value, name = mod._webviewLabel })

    return result

end

--- cp.web.generate.javascript(script, context) -> cp.web.html
--- Function
--- Generates a HTML Heading
---
--- Parameters:
---  * data - Table containing the data you want to display on the Checkbox
---
--- Returns:
---  * String containing the HTML
---
function mod.javascript(script, context)
    local t = compile(script, "no-cache", true)
    return html.script { type = "text/javascript" } (
        "(function(){\n" .. t(context) .. "\n})();", false
    )
end

--- cp.web.generate.heading() -> string
--- Function
--- Generates a HTML Heading
---
--- Parameters:
---  * data - Table containing the data you want to display on the Checkbox
---
--- Returns:
---  * String containing the HTML
function mod.heading(data)
    return html.h3 {} ( data.title )
end

--- cp.web.generate.text() -> string
--- Function
--- Generates a blank HTML
---
--- Parameters:
---  * data - Table containing the data you want to display.
---
--- Returns:
---  * String containing the HTML
function mod.text(data)

    return html(data.title) .. "\n"

end

--- cp.web.generate.button() -> string
--- Function
--- Generates a HTML Button
---
--- Parameters:
---  * data - Table containing the data you want to display on the Checkbox
---  * customTrigger - Custom label used for JavaScript Callback
---  * customWidth - Number to set the width of the button to
---  * customID - Overrides the random HTML ID
---
--- Returns:
---  * String containing the HTML
function mod.button(data, customTrigger, customWidth, customID)

    local value = customTrigger or data.title

    local id = "button" .. randomWord(20)
    if customID then id = customID end

    local style = nil
    if customWidth then
        style = "width: " .. customWidth .. "px;"
    end

    local result = html.p { class="uiItem" } (
        html.a { id=id, style=style, class="button", href="#" } (data.title)
    ) .. mod.javascript([[
        var button = document.getElementById("{{ id }}");
        button.onclick = function (){
            try {
                var result = ["{{ value }}"];
                webkit.messageHandlers.{{ name }}.postMessage(result);
            } catch(err) {
                alert('An error has occurred. Does the controller exist yet?');
            }
        }
    ]], { id=id, value=value, name=mod._webviewLabel})

    return result

end

--- cp.web.generate.dropdown() -> string
--- Function
--- Generates a HTML Dropdown
---
--- Parameters:
---  * title - Title to put in front of the Dropdown. Can be "".
---  * data - Table containing the data you want to display on the Checkbox
---  * customTrigger - Custom label used for JavaScript Callback
---
--- Returns:
---  * String containing the HTML
function mod.dropdown(title, data, customTrigger)

    local value = customTrigger or title

    if title ~= "" then title = title .. ": " end

    local id = "dropdown" .. randomWord(20)

    local options = ""

    for _,v in ipairs(data) do
        local selected = nil
        if v.checked then selected = "selected" end

        options = options .. html.option { value=v.title, selected } (v.title)
    end

    local result = html.p { class="uiItem" } (
        title .. html.select { id=id } (options)
    ) .. mod.javascript([[
        var dropdown = document.getElementById("{{ id }}");
        dropdown.onchange = function (){
            try {
                var dropdownResult = document.getElementById("{{ id }}").value;
                var result = ["{{ value }}", dropdownResult];
                webkit.messageHandlers.{{ name }}.postMessage(result);
            } catch(err) {
                alert('An error has occurred. Does the controller exist yet?');
            }
        }
    ]], { id=id, value=value, name=mod._webviewLabel })

    return result

end

function mod.imageBase64(pathToImage)
    local type = mimetypes.guess(pathToImage)
    if type and type:sub(1,6) == "image/" then
        local f, err = io.open(fs.pathToAbsolute(pathToImage), "rb")
        if not f then
            return nil, err
        end
        local data = f:read("*all")
        f:close()

        return "data:image/jpeg;base64, "..base64.encode(data)
    end
    return ""
end

return mod
