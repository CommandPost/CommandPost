local module = {}
local ax      = require("hs._asm.axuielement")
local fnutils = require("hs.fnutils")
local inspect = require("hs.inspect")

local hierarchy
hierarchy = function(obj, indent, seen)
    indent = indent or 0
    seen = seen or {}
    if getmetatable(obj) == hs.getObjectMetatable("hs._asm.axuielement") then
        if fnutils.find(seen, function(_) return _ == obj end) then return end -- probably not necessary, but be safe
        table.insert(seen, obj)

        print(string.format("%s%s", string.rep(" ", indent), obj:role()))
        for _, attrName in ipairs(obj:attributeNames()) do
            if attrName == ax.attributes.general.parent then
                print(string.format("%s%s->%s: <parent>", string.rep(" ", indent), string.rep(" ", #obj:role()), attrName))
            elseif attrName == ax.attributes.general.topLevelUIElement then
                print(string.format("%s%s->%s: <topLevelUIElement>", string.rep(" ", indent), string.rep(" ", #obj:role()), attrName))
            else
                local attrValue = obj:attributeValue(attrName)
                if getmetatable(attrValue) == hs.getObjectMetatable("hs._asm.axuielement") then
                    if fnutils.find(seen, function(_) return _ == obj end) then
                        print(string.format("%s%s->%s: <seen before>", string.rep(" ", indent), string.rep(" ", #obj:role()), attrName))
                    else
                        print(string.format("%s%s->%s:", string.rep(" ", indent), string.rep(" ", #obj:role()), attrName))
                        hierarchy(attrValue, indent + #obj:role(), seen)
                    end
                elseif type(attrValue) == "table" then
                    if #attrValue == 0 then
                        print(string.format("%s%s->%s = %s", string.rep(" ", indent), string.rep(" ", #obj:role()), attrName, inspect(attrValue):gsub("[\r\n]"," "):gsub("%s+", " ")))
                    else
                        print(string.format("%s%s->%s {", string.rep(" ", indent), string.rep(" ", #obj:role()), attrName))
                        hierarchy(attrValue, indent + #obj:role() + #attrName + 6, seen)
                        print(string.format("%s%s}", string.rep(" ", indent), string.rep(" ", #obj:role()))) ;
                    end
                else
                    print(string.format("%s%s->%s = %s", string.rep(" ", indent), string.rep(" ", #obj:role()), attrName, inspect(attrValue)))
                end
            end
        end
    elseif type(obj) == "table" then
        for i, v in ipairs(obj) do hierarchy(v, indent, seen) end
    end
end

module.hierarchy = hierarchy
return module
