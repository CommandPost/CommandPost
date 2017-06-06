--- === cp.web.text ===
---
--- Functions for managing text on the web.

local sbyte, schar = string.byte, string.char
local sfind, ssub, gsub = string.find, string.sub, string.gsub

local mod = {}

local function sub_hex_ent(s)
	return schar(tonumber(s, 16))
end

local function sub_dec_ent(s)
	return schar(tonumber(s))
end

--- cp.web.text.unescapeXML(s) -> string
--- Function
--- Unescapes a string from XML encoding.
---
--- Parameters:
---  * s - The string you want to unescape
---
--- Returns:
---  * The string, unescaped.
function mod.unescapeXML(s)
	s = gsub(s, "&lt;", "<")
	s = gsub(s, "&gt;", ">")
	s = gsub(s, "&apos;", "'")
	s = gsub(s, "&quot;", '"')
	s = gsub(s, "&#x(%x+);", sub_hex_ent)
	s = gsub(s, "&#(%d+);", sub_dec_ent)
	s = gsub(s, "&amp;", "&")
	return s
end

--- cp.web.text.escapeXML(s) -> string
--- Function
--- Escapes a string
---
--- Parameters:
---  * s - The string you want to escape
---
--- Returns:
---  * The string, escaped for XML.
function mod.escapeXML(s)
	s = gsub(s, "&", "&amp;")
	s = gsub(s, "<", "&lt;")
	s = gsub(s, ">", "&gt;")
	s = gsub(s, "'", "&apos;")
	s = gsub(s, '"', "&quot;")
	return s
end

return mod