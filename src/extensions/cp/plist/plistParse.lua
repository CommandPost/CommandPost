--- === cp.plist.plistParser ===
---
--- plistParser (https://codea.io/talk/discussion/1269/code-plist-parser)
--- version 1.01
---
--- based on an XML parser by Roberto Ierusalimschy at:
--- lua-users.org/wiki/LuaXml
---
--- Takes a string-ified .plist file as input, and outputs
--- a table. Nested dictionaries and arrays are parsed into
--- subtables. Table structure will match the structure of
--- the .plist file
---
--- Usage:
--- ```lua
--- local plistStr = <string-ified plist file>
--- local plistTable = plistParse(plistStr)
--- ```

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local plp = {}

function plp.nextTag(s, i)
    return string.find(s, "<(%/?)([%w:]+)(%/?)>", i)
end

function plp.array(s, i)
    local arr, nextTag, array, dictionary = {}, plp.nextTag, plp.array, plp.dictionary
    local ni, j, c, label, empty

    while true do
        ni, j, c, label, empty = nextTag(s, i)
        assert(ni)

        if c == "" then
            local _
            if empty == "/" then
                if label == "dict" or label == "array" then
                    arr[#arr+1] = {}
                else
                    arr[#arr+1] = (label == "true") and true or false
                end
            elseif label == "array" then
                arr[#arr+1], _, j = array(s, j+1)
            elseif label == "dict" then
                arr[#arr+1], _, j = dictionary(s, j+1)
            else
                i = j + 1
                ni, j, _, label, _ = nextTag(s, i)

                local val = string.sub(s, i, ni-1)
                if label == "integer" or label == "real" then
                    arr[#arr+1] = tonumber(val)
                else
                    arr[#arr+1] = val
                end
            end
        elseif c == "/" then
            assert(label == "array")
            return arr, j+1, j
        end

        i = j + 1
    end
end

function plp.dictionary(s, i)
    local dict, nextTag, array, dictionary = {}, plp.nextTag, plp.array, plp.dictionary
    local ni, j, c, label, empty, _

    while true do
        ni, j, c, label = nextTag(s, i)
        assert(ni)

        if c == "" then
            if label == "key" then
                i = j + 1
                ni, j, c, label = nextTag(s, i)
                assert(c == "/" and label == "key")

                local key = string.sub(s, i, ni-1)

                i = j + 1
                _, j, _, label, empty = nextTag(s, i)

                if empty == "/" then
                    if label == "dict" or label == "array" then
                        dict[key] = {}
                    else
                        dict[key] = (label == "true") and true or false
                    end
                else
                    if label == "dict" then
                        dict[key], _, j = dictionary(s, j+1)
                    elseif label == "array" then
                        dict[key], _, j = array(s, j+1)
                    else
                        i = j + 1
                        ni, j, _, label, _ = nextTag(s, i)

                        local val = string.sub(s, i, ni-1)
                        if label == "integer" or label == "real" then
                            dict[key] = tonumber(val)
                        else
                            dict[key] = val
                        end
                    end
                end
            end
        elseif c == "/" then
            assert(label == "dict")
            return dict, j+1, j
        end

        i = j + 1
    end
end

local function plistParse(s)
    if type(s) == "nil" then
        return nil
    end

    local i = 0
    local ni, label, empty, _

    while label ~= "plist" do
        local lastIndex = i
        ni, i, label, _ = string.find(s, "<([%w:]+)(.-)>", i+1)


        -- BUG: Something is going funky here with complex plist's:

        if ni == nil then
            print(string.format("Fatal Error: Something has gone wrong in plistParse at #%s: %s", lastIndex+1, s))
            return nil
        else
            assert(ni)
        end

    end

    _, i, _, label, empty = plp.nextTag(s, i)

    if empty == "/" then
        return {}
    elseif label == "dict" then
        return plp.dictionary(s, i+1)
    elseif label == "array" then
        return plp.array(s, i+1)
    end
end

return plistParse