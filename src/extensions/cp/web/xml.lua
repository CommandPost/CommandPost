--- === cp.web.xml ===
---
--- Functions for Generating XML markup.
---
--- This library allows the creation of 'safe' XML using via code.
---
--- Examples:
---
--- ```lua
--- local xml = require "cp.web.xml"
--- print xml.Root "Hello world!"						-- "<Root>Hello world!</Root>"
--- print xml.Root { class = "custom" } "Hello world!"	-- "<Root class='custom'>Hello world!</Root>"
--- print xml.Root { class = "custom" } (
--- 	xml.Child "One" .. " and " .. xml.Child "Two" .. "."
--- )
--- -- "<Root class='custom'><Child>One</Child> and <Child>Two</Child>.</Root>"
--- print xml("1 < 2")										-- "1 &lt; 2" (escaped)
--- print xml("1 < 2", true)								-- "1 < 2" (unescaped)
--- print xml.Root ("<Child>One</Child>", true)				-- "<Root><Child>One</Child></Root>"
--- ```
---
--- Be aware that concatonating with ".." can behave unexpectedly in some cases. For example:
---
--- ```lua
--- local name = "world!"
--- print xml.Root "Hello " .. name					-- "<Root>Hello </Root>world!"
--- ```
---
--- The `"Hello"` gets inserted into the `Root` tag, but the `name` gets concatonated after the closing tag.
--- To get the `name` inside the `Root` tag, we need to put brackets around the content:
---
--- ```lua
--- print xml.Root ("Hello " .. name)					-- "<Root>Hello world!</Root>"
--- ```
---
--- Any tag name can be generated, along with any attribute. The results are correctly escaped.
--- There are two 'special' tag names:
---  * `CDATA`	- will generate a `&lt;![CDATA[ ... ]]&gt;` section with the content contained.
---  * `__`		- (double underscore) will generate a `&lt!-- ... --&gt` comment block.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log				= require "hs.logger" .new "xml"

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
-- local inspect			= require "hs.inspect"

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local block				= require "cp.web.block"

--------------------------------------------------------------------------------
-- Local Lua Functions:
--------------------------------------------------------------------------------
local gsub              = string.gsub

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- XML_ENTITIES -> table
-- Constant
-- XML Entities.
local XML_ENTITIES = {
    ["&"] = "&amp;",
    ["<"] = "&lt;",
    [">"] = "&gt;",
    ['"'] = "&quot;",
    ["'"] = "&apos;",
}

-- DEFAULT_ENCODING -> string
-- Constant
-- Default Encoding.
local DEFAULT_ENCODING = "UTF-8"

-- DEFAULT_STANDALONE -> string
-- Constant
-- Default Standalone.
local DEFAULT_STANDALONE = "yes"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local xml = {}

local function xmlEscape(s)
    return gsub(s, "[\"><'&]", XML_ENTITIES)
end

--- cp.web.xml.is(value) -> boolean
--- Function
--- Checks if the `value` is an `cp.web.xml` block.
---
--- Parameters:
--- * value		- the value to check
---
--- Returns:
--- * `true` if it is an HTML block, or `false` otherwise.
xml.is = block.is

xml.__index = function(_, name)
    return function(param, ...)
        local pType = type(param)
        if param ~= nil and (pType ~= "table" or block.is(param)) then
            -- it's content, not attributes
            return block.new(name, nil, xmlEscape)(param, ...)
        else
            return block.new(name, param, xmlEscape)
        end
    end
end

xml.__call = function(_, content, ...)
    return block.is(content) and content or block.new("_", nil, xmlEscape)(content, ...)
end

xml._xml = function(attrs)
    attrs = attrs or {}

    local result = [[<?xml version="1.0"]]

    result = result .. ' encoding="' ..xmlEscape( attrs.encoding or DEFAULT_ENCODING )..'"'
    result = result .. ' standalone="'..xmlEscape( attrs.standalone or DEFAULT_STANDALONE )..'"'

    result = result .. [[?>]]
    return xml(result, false)
end

return setmetatable(xml, xml)