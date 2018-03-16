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

-- local log				= require "hs.logger" .new "html"
-- local inspect			= require "hs.inspect"

local template 			= require "resty.template"
local is				= require "cp.is"

local setmetatable		= setmetatable
local escape			= template.escape
local concat, insert	= table.concat, table.insert
local pairs				= pairs
local type				= type

local isFunction, isList	= is.fn, is.list

local block = {}
block.__index = block

local function isBlock(value)
	return value and type(value) == "table" and getmetatable(value) == block
end

-- isEscaped(newContent, escaped)
-- Private Function
-- Determines if the content is escaped by default, based on the content type and the `escaped` value
local function isEscaped(newContent, escaped)
	if escaped ~= nil then
		return escaped
	else
		return not isBlock(newContent)
	end
end

local function nilContent() return "" end

-- prepareContent(content, escaped) -> function
-- Local Function
-- Returns a function that can be executed to return the `string` value for the content,
-- taking into account the `escaped` value. See `block:append(...)` for details.
--
-- Parameters:
-- * content	- The content
-- * escaped	- (optional) whether the content should be escaped.
--
-- Returns:
-- * A `function` that can be called to get the current `string` value of the content.
local function prepareContent(content, escaped)
	if isFunction(content) then
		return function()
			-- recursively prepare the function results and execute
			local value = content()
			return prepareContent(value, escaped)()
		end
	elseif isList(content) then
		return function()
			-- recursively concatonate the results
			local result = ""
			for _,item in ipairs(content) do
				result = result .. prepareContent(item, escaped)()
			end
			return result
		end
	elseif content ~= nil then
		return function()
			local result = tostring(content)
			if isEscaped(content, escaped) then
				result = escape(result)
			end
			return result
		end
	else
		return nilContent
	end
end

function block:tostring()
	return self:__tostring()
end

-- Implements the 'tostring' metamethod, converting the block to a string.
function block:__tostring()
	local metadata = self._metadata
	local name = escape(metadata.name)
	local content, attr = metadata.content, metadata.attr
	local r, a = {}, {}

	if #metadata.pre > 0 then
		for _,pre in ipairs(metadata.pre) do
			r[#r + 1] = pre()
		end
	end

	if metadata.open then
		r[#r + 1] = metadata.open
	else
	    r[#r + 1] = "<"
	    r[#r + 1] = name
	    if attr then
			for k, v in pairs(attr) do
				local value = v()
	            if type(k) == "number" then
					if value and value ~= "" then
						a[#a + 1] = value
					end
	            else
	                a[#a + 1] = escape(k) .. '="' .. value .. '"'
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
			r[#r + 1] = "/>"
		end
	end
	if content then
		for _,v in ipairs(content) do
			r[#r + 1] = v()
		end

		if metadata.close then
			r[#r + 1] = metadata.close
		else
	        r[#r + 1] = "</"
	        r[#r + 1] = name
	        r[#r + 1] = ">"
		end
    end

	if #metadata.post > 0 then
		for _,post in ipairs(metadata.post) do
			r[#r + 1] = post()
		end
	end

    return concat(r)
end

function block:_content()
	local content = self._metadata.content
	if not content then
		content = {}
		self._metadata.content = content
	end
	return content
end

--- cp.web.html:prepend(newContent[, escaped]) -> self
--- Method
--- Prepends the content. If specified, the `escaped` value will override any default escaping for the content type.
---
--- Parameters:
--- * newContent		- The content to prepend to the contents of the HTML block.
--- * escaped			- May be set to override default escaping for the content.
---
--- Returns:
--- * The same HTML block instance.
---
--- Notes:
--- * The `newContent` may be almost any value. The default handling is below:
--- ** `cp.web.html` instance: Any other HTML block can be added. Default escaping: `false`.
--- ** `function`: Functions will be executed every time the HTML block is converted to a string. Default escaping: whatever the default is for the returned value.
--- ** `list`: Tables which are lists will be iterrated and each item will be evaluated each time the HTML block is converted to a string. Default escaping: the default for each item.
--- ** _everything else_: Converted to a string via the `tostring` function. Default escaping: `true`.
function block:prepend(newContent, escaped)
	local content = self:_content()

	newContent = prepareContent(newContent, escaped)
	insert(content, 1, newContent)

	return self
end

--- cp.web.html:append(newContent[, escaped]) -> self
--- Method
--- Appends the content. If specified, the `escaped` value will override any default escaping for the content type.
---
--- Parameters:
--- * newContent		- The content to append to the contents of the HTML block.
--- * escaped			- May be set to override default escaping for the content.
---
--- Returns:
--- * The same HTML block instance.
---
--- Notes:
--- * The `newContent` may be almost any value. The default handling is below:
--- ** `cp.web.html` instance: Any other HTML block can be added. Default escaping: `false`.
--- ** `function`: Functions will be executed every time the HTML block is converted to a string. Default escaping: whatever the default is for the returned value.
--- ** `list`: Tables which are lists will be iterrated and each item will be evaluated each time the HTML block is converted to a string. Default escaping: the default for each item.
--- ** _everything else_: Converted to a string via the `tostring` function. Default escaping: `true`.
function block:append(newContent, escaped)
	local content = self:_content()

	newContent = prepareContent(newContent, escaped)
	insert(content, newContent)

	return self
end

-- Concatonates the block with another chunk of content.
function block.__concat(left, right)
	if isBlock(left) then
		local post = left._metadata.post
		post[#post+1] = prepareContent(right)
		return left
	else
		local pre = right._metadata.pre
		pre[#pre+1] = prepareContent(left)
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
			pre		=	{},
			post	=	{},
		}
	}

	if attr then
		local a = {}

		for k,v in pairs(attr) do
			a[k] = prepareContent(v, true) -- always escape attributes
		end

		o._metadata.attr = a
	end
	return setmetatable(o, block)
end

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
html.is = isBlock

html.__index = function(_, name)
    return function(param, ...)
		local pType = type(param)
        if param ~= nil and (pType ~= "table" or isBlock(param)) then
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