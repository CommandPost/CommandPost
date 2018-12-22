--- === cp.web.html ===
---
--- Functions for Generating HTML markup.
---
--- This library allows the creation of 'safe' HTML using via code.
---
--- Examples:
---
--- ```lua
--- local html = require "cp.web.html"
--- print html.p "Hello world!"								-- "<p>Hello world!</p>"
--- print html.p { class = "custom" } "Hello world!"		-- "<p class='custom'>Hello world!</p>"
--- print html.p { class = "custom" } (
--- 	html.b "Bold" .. " and " .. html.i "italic" .. "."
--- )
--- -- "<p class='custom'><b>Bold</b> and <i>italic</i>.</p>"
--- print html("1 < 2")										-- "1 &lt; 2" (escaped)
--- print html("1 < 2", true)								-- "1 < 2" (unescaped)
--- print html.p ("<b>bold</b>", true)						-- "<p><b>bold</b></p>"
--- ```
---
--- Be aware that concatonating with ".." can behave unexpectedly in some cases. For example:
---
--- ```lua
--- local name = "world!"
--- print html.p "Hello " .. name					-- "<p>Hello </p>world!"
--- ```
---
--- The `"Hello"` gets inserted into the `p` tag, but the `name` gets concatonated after the closing tag.
--- To get the `name` inside the `p` tag, we need to put brackets around the content:
---
--- ```lua
--- print html.p ("Hello " .. name)					-- "<p>Hello world!</p>"
--- ```
---
--- Any tag name can be generated, along with any attribute. The results are correctly escaped.
--- There are two 'special' tag names:
---  * `CDATA`	- will generate a `&lt;![CDATA[ ... ]]&gt;` section with the content contained.
---  * `__`		- (double underscore) will generate a `&lt!-- ... --&gt` comment block.

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local require = require
-- local log				= require "hs.logger" .new "html"

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
-- local inspect			= require "hs.inspect"

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local block				= require "cp.web.block"

--------------------------------------------------------------------------------
-- 3rd Party Extensions:
--------------------------------------------------------------------------------
local template 			= require "resty.template"
local htmlEscape			= template.escape

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local html = {}

--- cp.web.html.is(value) -> boolean
--- Function
--- Checks if the `value` is an `cp.web.html` block.
---
--- Parameters:
--- * value		- the value to check
---
--- Returns:
--- * `true` if it is an HTML block, or `false` otherwise.
html.is = block.is

html.__index = function(_, name)
    return function(param, ...)
        local pType = type(param)
        if param ~= nil and (pType ~= "table" or block.is(param)) then
            -- it's content, not attributes
            return block.new(name, nil, htmlEscape)(param, ...)
        else
            return block.new(name, param, htmlEscape)
        end
    end
end

html.__call = function(_, content, ...)
    return block.is(content) and content or block.new("_", nil, htmlEscape)(content, ...)
end

return setmetatable(html, html)
