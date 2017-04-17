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
--- There are three 'special' tag names:
---  * `CDATA`	- will generate a `&lt;![CDATA[ ... ]]&gt;` section with the content
---  * `__`		- (double underscore) will generate a `&lt!-- ... --&gt` comment
---  * `_`		- (single underscore) will generate a plain text block.

local log			= require "hs.logger" .new "html"
local template 		= require "resty.template"
local setmetatable	= setmetatable
local escape		= template.escape
local concat		= table.concat
local pairs			= pairs
local type			= type

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
		end
	elseif contentType == "function" then
		content = evaluate(content())
	end
	
	if content then
		return tostring(content)
	else
		return ""
	end
end

local escaped = {}
escaped.__index = escaped

function escaped.new(content)
	local o = { content = content }
	return setmetatable(o, escaped)
end

function escaped:__tostring()
	return self.content and escape(evaluate(self.content)) or ""
end

local block = {}
block.__index = block

local function isBlock(value)
	return value and type(value) == "table" and getmetatable(value) == block
end

function block:tostring()
	return block:__tostring()
end

-- Implements the 'tostring' metamethod, converting the block to a string.
function block:__tostring()
	local metadata = self._metadata
	local name, content, attr = metadata.name, metadata.content, metadata.attr
	local r, a = {}, {}

	if #metadata.pre > 0 then
		r[#r + 1] = evaluate(metadata.pre)
	end

	if metadata.open then
		r[#r + 1] = metadata.open
	else
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
		if content then
			r[#r + 1] = ">"
		else
			r[#r + 1] = " />"
		end
	end
    if content then
		r[#r + 1] = evaluate(content)
		
		if metadata.close then
			r[#r + 1] = metadata.close
		else
	        r[#r + 1] = "</"
	        r[#r + 1] = name
	        r[#r + 1] = ">"
		end
    end
	
	if #metadata.post > 0 then
		r[#r + 1] = evaluate(metadata.post)
	end
	
    return concat(r)
end

-- Prepends the content inside the block.
function block:prepend(newContent, unescaped)
	local content = self._metadata.content
	if not content then
		content = {}
		self._metadata.content = content
	end
	if not isBlock(newContent) and not unescaped then
		newContent = escaped.new(newContent)
	end
	table.insert(content, 1, newContent)
	return self
end

-- Appends the content inside the block.
function block:append(newContent, unescaped)
	local content = self._metadata.content
	if not content then
		content = {}
		self._metadata.content = content
	end
	if not isBlock(newContent) and not unescaped then
		newContent = escaped.new(newContent)
	end
	table.insert(content, newContent)
	return self
end

-- Concatonates the block with another chunk of content.
function block.__concat(left, right)
	if isBlock(left) then
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

local function openTag(name)
	if name == "CDATA" then
		return "<![CDATA["
	elseif name == "__" then
		return "<!-- "
	elseif name == "_" then
		return ""
	else
		return nil
	end
end

local function closeTag(name)
	if name == "CDATA" then
		return "]]>"
	elseif name == "__" then
		return " -->"
	elseif name == "_" then
		return ""
	else
		return nil
	end
end

-- Creates a new block.
function block.new(name, attr)
	local o = {
		_metadata	= {
			name	=	name,
			open	=	openTag(name),
			close	=	closeTag(name),
			attr	=	attr,
			pre		=	{},
			post	=	{},
		}
	}
	return setmetatable(o, block)
end

local html = {}
html.__index = function(_, name)
    return function(param, ...)
		local pType = type(param)
        if pType ~= "table" or isBlock(param) then
			-- it's content, not attributes
			return block.new(name)(param, ...)
		else
            return block.new(name, param)
        end
    end
end

html.__call = function(_, content, ...)
	return isBlock(content) and content or block.new("_")(content, ...)
end

return setmetatable(html, html)