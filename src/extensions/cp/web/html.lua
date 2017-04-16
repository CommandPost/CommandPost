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

local log			= require "hs.logger" .new "html"
local template 		= require "resty.template"
local setmetatable	= setmetatable
local escape		= template.escape
local concat		= table.concat
local pairs			= pairs
local type			= type

local block = {}
block.__index = block

-- Evalutates the content, converting it to a string.
local function evaluate(content)
	local contentType = type(content)
	if contentType == "table" then
		if #content > 0 then
			local result = ""
			for _,item in ipairs(content) do
				result = result .. evaluate(item)
			end
			return result
		elseif getmetatable(content) == block then
			return tostring(content)
		end
	elseif contentType == "function" then
		return evaluate(content())
	end
	
	if content then
		return escape(tostring(content))
	else
		return ""
	end
end

-- Implements the 'tostring' metamethod, converting the block to a string.
function block:__tostring()
	local metadata = self._metadata
	local name, content, attr = metadata.name, metadata.content, metadata.attr
	local r, a = {}, {}

	if #metadata.pre > 0 then
		r[#r + 1] = evaluate(metadata.pre)
	end

	if name then
	    r[#r + 1] = "<"
	    r[#r + 1] = name
	    if attr then
	        for k, v in pairs(attr) do
	            if type(k) == "number" then
					local value = evaluate(v)
					if value and value ~= "" then
						a[#a + 1] = value
					end
	            else
	                a[#a + 1] = k .. '="' .. evaluate(v) .. '"'
	            end
	        end
	        if #a > 0 then
	            r[#r + 1] = " "
	            r[#r + 1] = concat(a, " ")
	        end
	    end
	end
    if content then
		if name then
			r[#r + 1] = ">"
		end
		
		r[#r + 1] = evaluate(content)
		
		if name then
	        r[#r + 1] = "</"
	        r[#r + 1] = name
	        r[#r + 1] = ">"
		end
	elseif name then
        r[#r + 1] = " />"
    end
	
	if #metadata.post > 0 then
		r[#r + 1] = evaluate(metadata.post)
	end
	
    return concat(r)
end

-- Prepends the content inside the block.
function block:prepend(newContent)
	local content = self._metadata.content
	if not content then
		content = {}
		self._metadata.content = content
	end
	table.insert(content, 1, newContent)
	return self
end

-- Appends the content inside the block.
function block:append(newContent)
	local content = self._metadata.content
	if not content then
		content = {}
		self._metadata.content = content
	end
	table.insert(content, newContent)
	return self
end

-- Concatonates the block with another chunk of content.
function block.__concat(left, right)
	if type(left) == "table" and getmetatable(left) == block then
		local post = left._metadata.post
		post[#post+1] = right
		return left
	else
		local pre = right._metadata.pre
		pre[#pre+1] = left
		return right
	end
end

block.__call = block.append

-- Creates a new block.
function block.new(name, attr)
	local o = {
		_metadata	= {
			name	=	name,
			attr	=	attr,
			pre		=	{},
			post	=	{},
		}
	}
	return setmetatable(o, block)
end

local html = { __index = function(_, name)
    return function(param)
		local pType = type(param)
        if pType ~= "table" or type(param) == "table" and getmetatable(param) == block then
			-- it's content, not attributes
			return block.new(name)(param)
		else
            return block.new(name, param)
        end
    end
end }

return setmetatable(html, html)
