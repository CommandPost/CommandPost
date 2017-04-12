--- Source: https://john.nachtimwald.com/2014/08/06/using-lua-as-a-templating-engine/

--- Template renderer.
--
-- Takes a string with embedded Lua code and renders
-- it based on the Lua code.
--
--  All template blocks are surrounded by `{{ }}`.
--
-- Supports:
--  * `{{ var }}` for printing variables.
--  * `{{% func }}` for running Lua functions.
--
-- Use `\{` to use a literal `{` in the template. This
-- should only be required if you are attempting to
-- output a '{' directly in front of an template block.
-- 
-- For example:
--
-- ```
-- This is \{{{ 1 + 2 }}}.
-- ```
--
-- ...will output:
--
-- ```
-- This is {3}.
-- ```
-- 
-- Multi-line strings in Lua blocks are supported but
-- [[ is not allowed. Use [=[ or some other variation.
--
-- Both compile and compileFile can take an optional
-- env table which when provided will be used as the
-- env for the Lua code in the template. This allows
-- a level of sandboxing. Note that any globals including
-- libraries that the template needs to access must be
-- provided by env if used.
 
local mod = {}
 
-- Append text or code to the builder.
local function appender(builder, text)
	builder[#builder+1] = text
end

local function appendText(builder, text)
	-- [[ has a \n immediately after it. Lua will strip
	-- the first \n so we add one knowing it will be
	-- removed to ensure that if text starts with a \n
	-- it won't be lost.
	appender(builder, "_ret[#_ret+1] = [[\n" .. text .. "]]")
end

local function appendLuaOutput(builder, code)
	appender(builder, ('_ret[#_ret+1] = %s'):format(code))
end

local function appendLuaCode(builder, code)
	appender(builder, code)
end
 
--- Takes a string and determines what kind of block it
-- is and takes the appropriate action.
--
-- The text should be something like:
-- "{{ ... }}"
-- 
-- If the block is supported the begin and end tags will
-- be stripped and the associated action will be taken.
-- If the tag isn't supported the block will be output
-- as is.
local function runBlock(builder, text)
    local func
    local tag
 
    tag = text:sub(1, 2)
 
    if tag == "{{" then
		if text:sub(3,3) == "%" then
			text = text:sub(4, #text-4)
			appendLuaCode(builder, text)
		else
			text = text:sub(3, #text-3)
			appendLuaOutput(builder, text)
		end
	else
		appendText(builder, text)
    end
end
 
--- Compile a Lua template into a string.
--
-- @param      tmpl The template.
-- @param[opt] env  Environment table to use for sandboxing.
--
-- return Compiled template.
function mod.compile(tmpl, env)
    -- Turn the template into a string that can be run though
    -- Lua. Builder will be used to efficiently build the string
    -- we'll run. The string will use it's own builder (_ret). Each
    -- part that comprises _ret will be the various pieces of the
    -- template. Strings, variables that should be printed and
    -- functions that should be run.
    local builder = { "_ret = {}\n" }
    local pos     = 1
    local b
    local func
    local err
 
    if #tmpl == 0 then
        return ""
    end
 
    while pos < #tmpl do
        -- Look for start of a Lua block.
        b = tmpl:find("{{", pos)
        if not b then
            break
        end
 
        -- Check if this is a block or escaped {.
        if tmpl:sub(b-1, b-1) == "\\" then
            appendText(builder, tmpl:sub(pos, b-2))
            appendText(builder, "{")
            pos = b+1
        else
            -- Add all text up until this block.
            appendText(builder, tmpl:sub(pos, b-1))
            -- Find the end of the block.
            pos = tmpl:find("}}", b)
            if not pos then
                appendText(builder, "End tag ('}}') missing")
                break
            end
            runBlock(builder, tmpl:sub(b, pos+2))
            -- Skip back the }} (pos points to the start of }}).
            pos = pos+2
        end
    end
    -- Add any text after the last block. Or all of it if there
    -- are no blocks.
    if pos then
        appendText(builder, tmpl:sub(pos, #tmpl-1))
    end
 
    builder[#builder+1] = "return table.concat(_ret)"
    -- Run the Lua code we built though Lua and get the result.
    func, err = load(table.concat(builder, "\n"), "template", "t", env)
    if not func then
        return err
    end
    return func()
end
 
function mod.compileFile(name, env)
    local f, err = io.open(name, "rb")
    if not f then
        return err
    end
    local t = f:read("*all")
    f:close()
    return mod.compile(t, env)
end

function mod.defaultEnv()
	return {
	    pairs  = pairs,
	    ipairs = ipairs,
	    type   = type,
	    table  = table,
	    string = string,
	    os     = {
			date   = os.date,
		},
	    math   = math,
	    adder  = adder,
	    count  = count,
	}
end
 
return mod