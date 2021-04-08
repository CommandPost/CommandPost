-- maybe save some pain, if the shim is installed; otherwise, expect an objc dump to console when this loads on stock Hammerspoon without pull #2308 applied

--- === hs.text ===
---
--- This module provides functions and methods for converting text between the various encodings supported by macOS.
---
--- This module allows the import and export of text conforming to any of the encodings supported by macOS. Additionally, this module provides methods foc converting between encodings and attempting to identify the encoding of raw data when the original encoding may be unknown.
---
--- Because the macOS natively treats all textual data as UTF-16, additional support is provided in the `hs.text.utf16` submodule for working with textual data that has been converted to UTF16.
---
--- For performance reasons, the text objects are maintained as macOS native objects unless explicitely converted to a lua string with [hs.text:rawData](#rawData) or [hs.text:tostring](#tostring).


local USERDATA_TAG = "hs.text"
local module       = require(USERDATA_TAG..".internal")

local basePath = package.searchpath(USERDATA_TAG, package.path)
if basePath then
    basePath = basePath:match("^(.+)/init.lua$")
    if require"hs.fs".attributes(basePath .. "/docs.json") then
        require"hs.doc".registerJSONFile(basePath .. "/docs.json")
    end
end

local textMT  = hs.getObjectMetatable(USERDATA_TAG)
local utf16MT = hs.getObjectMetatable(USERDATA_TAG..".utf16")
local regexMT = hs.getObjectMetatable(USERDATA_TAG..".regex")

require("hs.http") -- load some conversion functions that may be useful with hs.text.http, not certain yet

-- private variables and methods -----------------------------------------

-- Public interface ------------------------------------------------------

-- pragma - mark - hs.text functions, methods, and constants

--- hs.text:tostring([lossy]) -> string
--- Method
--- Returns the textObject as a UTF8 string that can be printed and manipulated directly by lua.
---
--- Parameters:
---  * `lossy`    - a boolean, defailt false, specifying whether or not characters can be removed or altered in the conversion to UTF8.
---
--- Returns:
---  * a lua string containing the UTF8 representation of the textObject. The string will be empty (i.e. "") if the conversion to UTF8 could not be performed.
---
--- Notes:
---  * this method is basically a wrapper for `textObject:asEncoding(hs.text.encodingTypes.UTF8, [lossy]):rawData()`
textMT.tostring = function(self, ...)
    return self:asEncoding(module.encodingTypes.UTF8, ...):rawData() or ""
end

--- hs.text:toUTF16([lossy]) -> utf16TextObject | nil
--- Method
--- Returns a new hs.text.utf16 object representing the textObject for use with the `hs.text.utf16` submodule and its methods.
---
--- Parameters:
---  * `lossy`    - a boolean, defailt false, specifying whether or not characters can be removed or altered in the conversion to UTF16.
---
--- Returns:
---  * a new `hs.text.utf16` object or nil if the conversion could not be performed.
textMT.toUTF16 = function(self, ...)
    return module.utf16.new(self, ...)
end

-- string.byte (s [, i [, j]])
--
-- Returns the internal numeric codes of the characters s[i], s[i+1], ..., s[j]. The default value for i is 1; the default value for j is i. These indices are corrected following the same rules of function string.sub.
-- Numeric codes are not necessarily portable across platforms.

--- hs.text:byte([i, [j]]) -> 0 or more integeres
--- Method
--- Get the actual bytes of data present between the specified indices of the textObject
---
--- Paramaters:
---  * `i` - an optional integer, default 1, specifying the starting index. Negative numbers start from the end of the texObject.
---  * `j` - an optional integer, defaults to the value of `i`, specifying the ending index. Negative numbers start from the end of the texObject.
---
--- Returns:
---  * 0 or more integers representing the bytes within the range specified by the indicies.
---
--- Notes:
---  * This is syntactic sugar for `string.bytes(hs.text:rawData() [, i [, j]])`
---  * This method returns the byte values of the actual data present in the textObject. Depending upon the encoding of the textObject, these bytes may or may not represent individual or complete characters within the text itself.
textMT.byte = function(self, ...)
    return self:rawData():byte(...)
end

module.encodingTypes           = ls.makeConstantsTable(module.encodingTypes)

-- pragma - mark - hs.text.http functions, methods, and constants

--- hs.text.http.get(url, headers) -> int, textObject, table
--- Function
--- Sends an HTTP GET request to a URL
---
--- Parameters
---  * `url`     - A string containing the URL to retrieve
---  * `headers` - A table containing string keys and values representing the request headers, or nil to add no headers
---
--- Returns:
---  * A number containing the HTTP response status
---  * A textObject containing the response body
---  * A table containing the response headers
---
--- Notes:
---  * If authentication is required in order to download the request, the required credentials must be specified as part of the URL (e.g. "http://user:password@host.com/"). If authentication fails, or credentials are missing, the connection will attempt to continue without credentials.
---
---  * This function is synchronous and will therefore block all other Lua execution while the request is in progress, you are encouraged to use the asynchronous functions
---  * If you attempt to connect to a local Hammerspoon server created with `hs.httpserver`, then Hammerspoon will block until the connection times out (60 seconds), return a failed result due to the timeout, and then the `hs.httpserver` callback function will be invoked (so any side effects of the function will occur, but it's results will be lost).  Use [hs.text.http.asyncGet](#asyncGet) to avoid this.
module.http.get = function(url, headers)
    return module.http.doRequest(url, "GET", nil, headers)
end

--- hs.text.http.post(url, data, headers) -> int, textObject, table
--- Function
--- Sends an HTTP POST request to a URL
---
--- Parameters
---  * `url`     - A string containing the URL to submit to
---  * `data`    - A string or hs.text object containing the request body, or nil to send no body
---  * `headers` - A table containing string keys and values representing the request headers, or nil to add no headers
---
--- Returns:
---  * A number containing the HTTP response status
---  * A textObject containing the response body
---  * A table containing the response headers
---
--- Notes:
---  * If authentication is required in order to download the request, the required credentials must be specified as part of the URL (e.g. "http://user:password@host.com/"). If authentication fails, or credentials are missing, the connection will attempt to continue without credentials.
---
---  * This function is synchronous and will therefore block all other Lua execution while the request is in progress, you are encouraged to use the asynchronous functions
---  * If you attempt to connect to a local Hammerspoon server created with `hs.httpserver`, then Hammerspoon will block until the connection times out (60 seconds), return a failed result due to the timeout, and then the `hs.httpserver` callback function will be invoked (so any side effects of the function will occur, but it's results will be lost).  Use [hs.text.http.asyncPost](#asyncPost) to avoid this.
module.http.post = function(url, data, headers)
    return module.http.doRequest(url, "POST", data,headers)
end

--- hs.text.http.asyncGet(url, headers, callback)
--- Function
--- Sends an HTTP GET request asynchronously
---
--- Parameters:
---  * `url`      - A string containing the URL to retrieve
---  * `headers`  - A table containing string keys and values representing the request headers, or nil to add no headers
---  * `callback` - A function to be called when the request succeeds or fails. The function will be passed three parameters:
---   * A number containing the HTTP response status
---   * A textObject containing the response body
---   * A table containing the response headers
---
--- Notes:
---  * If authentication is required in order to download the request, the required credentials must be specified as part of the URL (e.g. "http://user:password@host.com/"). If authentication fails, or credentials are missing, the connection will attempt to continue without credentials.
---
---  * If the request fails, the callback function's first parameter will be negative and the second parameter will contain an error message. The third parameter will be nil
module.http.asyncGet = function(url, headers, callback)
    module.http.doAsyncRequest(url, "GET", nil, headers, callback)
end

--- hs.text.http.asyncPost(url, data, headers, callback)
--- Function
--- Sends an HTTP POST request asynchronously
---
--- Parameters:
---  * `url`      - A string containing the URL to submit to
---  * `data`     - A string or hs.text object containing the request body, or nil to send no body
---  * `headers`  - A table containing string keys and values representing the request headers, or nil to add no headers
---  * `callback` - A function to be called when the request succeeds or fails. The function will be passed three parameters:
---   * A number containing the HTTP response status
---   * A textObject containing the response body
---   * A table containing the response headers
---
--- Notes:
---  * If authentication is required in order to download the request, the required credentials must be specified as part of the URL (e.g. "http://user:password@host.com/"). If authentication fails, or credentials are missing, the connection will attempt to continue without credentials.
---
---  * If the request fails, the callback function's first parameter will be negative and the second parameter will contain an error message. The third parameter will be nil
module.http.asyncPost = function(url, data, headers, callback)
    module.http.doAsyncRequest(url, "POST", data, headers, callback)
end

-- pragma - mark - hs.text.utf16 functions, methods, and constants

--- hs.text.utf16:gmatch(pattern, [i]) -> iteratorFunction
--- Method
--- Returns an iterator function that iteratively returns the captures (if specified) or the entire match (if no captures are specified) of the pattern over the utf16TextObject.
---
--- Paramters:
---  * `pattern` - a lua string or utf16TextObject specifying the regular expression to iteratively match over the utf16TextObject.
---  * `i`       - an optional integer, default 1, specifying the starting character within the object for the search; negative indicies are counted from the end of the object.
---
--- Returns:
---  * an iterator function which can be used with the lua `for` command as an iterator.
---
--- Notes:
---  * This method is the utf16 equivalent of lua's `string.gmatch`.
---  * This method uses the `hs.text.regex:gmatchIn` method with a copy of the original string, so it is safe to modify the original object within a loop.
---
---  * The following examples are from the Lua documentation for `string.gmatch` modified with the proper syntax:
---
---      ~~~
---      -- print each word on a separate line
---      s = hs.text.utf16.new("hello world from Lua")
---      for w in s:gmatch([[\p{Alphabetic}+]]) do
---        print(w)
---      end
---
---      -- collect all pairs key=value from the given string into a table:
---      t = {}
---      s = hs.text.utf16.new("from=world, to=Lua")
---      for k, v in s:gmatch([[(\w+)=(\w+)]]) do
---        t[tostring(k)] = tostring(v)
---      end
---      ~~~
-- utf16MT.gmatch = function(self, pattern)
--     local pos, selfCopy = 1, self:copy()
--     return function()
--         local results = table.pack(selfCopy:find(pattern, pos))
--         if results.n < 2 then return end
--         pos = results[2] + 1
--         if results.n == 2 then
--             return selfCopy:sub(results[1], results[2])
--         else
--             table.remove(results, 1)
--             table.remove(results, 1)
--             return table.unpack(results)
--         end
--     end
-- end
utf16MT.gmatch = function(self, pattern, i)
    local re = module.regex.new(pattern)
    return re:gmatchIn(self, i)
end

--- hs.text.utf16:find(pattern, [i], [plain]) -> start, end, [captures...] | nil
--- Method
--- Looks for the first match of a pattern within the utf16TextObject and returns the indicies of the match
---
--- Paramters:
---  * `pattern` - a lua string or utf16TextObject specifying the pattern for the match. See *Notes*.
---  * `i`       - an optional integer, default 1, specifying the index of the utf16TextObject where the search for the pattern should begin; negative indicies are counted from the end of the object.
---  * `plain`   - an optional boolean, default `false`, specifying that the pattern should be matched *exactly* (true) instead of treated as a regular expression (false).
---
--- Returns:
---  * If a match is found, returns the starting and ending indicies of the match (as integers); if captures are specified in the pattern, also returns a new utf16TextObjects for each capture after the indicies. If no match is found, returns nil.
---
--- Notes:
---  * This method is the utf16 equivalent of lua's `string.find` with one important caveat:
---    * This method utilizes regular expressions as described at http://userguide.icu-project.org/strings/regexp, not the Lua pattern matching syntax.
---    * Again, ***Lua pattern matching syntax will not work with this method.***
utf16MT.find = function(self, pattern, i, plain)
    local re = module.regex.new(pattern, (plain and module.regex.expressionOptions.ignoreMetacharacters or 0))
    return re:findIn(self, i)
end

--- hs.text.utf16:match(pattern, [i]) -> match(es) | nil
--- Method
--- Looks for the first match of a pattern within the utf16TextObject and returns it
---
--- Paramters:
---  * `pattern` - a lua string or utf16TextObject specifying the pattern for the match. See *Notes*.
---  * `i`       - an optional integer, default 1, specifying the index of the utf16TextObject where the search for the pattern should begin; negative indicies are counted from the end of the object.
---
--- Returns:
---  * If a match is found and the pattern specifies captures, returns a new utf16TextObjects for each capture; if no captures are specified, returns the entire match as a new utf16TextObject. If no matche is found, returns nil.
---
--- Notes:
---  * This method is the utf16 equivalent of lua's `string.match` with one important caveat:
---    * This method utilizes regular expressions as described at http://userguide.icu-project.org/strings/regexp, not the Lua pattern matching syntax.
---    * Again, ***Lua pattern matching syntax will not work with this method.***
utf16MT.match = function(self, pattern, i)
    local re = module.regex.new(pattern)
    return re:matchIn(self, i)
end

--- hs.text.utf16:codes() -> iteratorFunction
--- Method
--- Returns an iterator function that returns the index position (in UTF16 characters) and codepoint of each character in the utf16TextObject.
---
--- Paramters:
---  * None
---
--- Returns:
---  * an iterator function which can be used with the lua `for` command as an iterator.
---
--- Notes:
---  * This method is the utf16 equivalent of lua's `utf8.codes`.
---  * Example usage:
---
---      ~~~
---      s = hs.text.utf16.new("Test 🙂 123")
---      for p,c in s:codes() do print(p, string.format("U+%04x", c)) end
---      ~~~
utf16MT.codes = function(self)
    return function(iterSelf, index)
        if index > 0 and module.utf16.isHighSurrogate(iterSelf:unitCharacter(index)) then
            index = index + 2
        else
            index = index + 1
        end
        if index > #iterSelf then
            return nil
        else
            return index, iterSelf:codepoint(index)
        end
    end, self, 0
end

--- hs.text.utf16:composedCharacters() -> iteratorFunction
--- Method
--- Returns an iterator function that returns the indicies of each character in the utf16TextObject, treating surrogate pairs and composed character sequences as single characters.
---
--- Paramters:
---  * None
---
--- Returns:
---  * an iterator function which can be used with the lua `for` command as an iterator.
---
--- Notes:
---  * Example usage:
---
---      ~~~
---      s = hs.text.utf16.new("abc🙂123") .. hs.text.utf16.char(0x073, 0x0323, 0x0307) .. "xyz"
---      for i,j in s:composedCharacters() do print(i, j, s:sub(i,j)) end
---      ~~~
utf16MT.composedCharacters = function(self)
    return function(iterSelf, index)
        if index > 0 then
            local i, j = iterSelf:composedCharacterRange(index)
            index = j
        end
        index = index + 1
        if index > #iterSelf then
            return nil
        else
            local i, j = iterSelf:composedCharacterRange(index)
            return index, j
        end
    end, self, 0
end

--- hs.text.utf16:compare(text, [options], [locale]) -> -1 | 0 | 1
--- Method
--- Compare the utf16TextObject to a string or another utf16TextObject and return the order
---
--- Paramters:
---  * `text`    - a lua string or another utf16TextObject specifying the value to compare this object to
---  * `options` - an optional integer or table of integers and strings corresponding to values in the [hs.text.utf16.compareOptions](#compareOptions) constant.
---    * if `options` is an integer, it should a combination of 1 or more of the numeric values in the [hs.text.utf16.compareOptions](#compareOptions) constant logically OR'ed together (e.g. `hs.text.utf16.compareOptions.caseInsensitive | hs.text.utf16.compareOptions.numeric`)
---    * if `options` is a table, each element of the array table should be a number value from the [hs.text.utf16.compareOptions](#compareOptions) constant or a string matching one of the constant's keys. This method will logically OR the appropriate values together for you (e.g. `{"caseInsensitive", "numeric"}`)
---  * `locale`  - an optional string, booleam, or nil value specifying the locale to use when comparing.
---    * if this parameter is ommitted, is an explicit `nil` or is the boolean value `false`, the system locale is used
---    * if this parameter is a boolean value of `true`, the users current locale is used
---    * if this paramter is a string, the locale specified by the string is used. (See `hs.host.locale.availableLocales()` for valid locale identifiers)
---
--- Returns:
---  * -1 if `text` is ordered *after* the object (i.e. they are presented in ascending order)
---  *  0 if `text` is ordered the same as the object (i.e. they are equal or equivalent, given the options)
---  *  1 if `text` is ordered *before* the object (i.e. they are presented in descending order)
---
--- Notes:
---  * The locale argument affects both equality and ordering algorithms. For example, in some locales, accented characters are ordered immediately after the base; other locales order them after “z”.
---  * This method does *not* consider characters with composed character equivalences as identical or similar; if this is a concern, make sure to normalize the source and `text` as appropriate for your purposes with [hs.text.utf16.unicodeDecomposition](#unicodeDecomposition) or [hs.text.utf16.unicodeComposition](#unicodeComposition) before utilizing this method.
utf16MT.compare = function(self, ...)
    local args = table.pack(...)
    if args.n > 1 and type(args[2]) == "table" then
        local options = 0
        for _,v in ipairs(args[2]) do
            if type(v) == "number" then
                options = options | v
            elseif type(v) == "string" then
                local value = module.utf16.compareOptions[v]
                if value then
                    options = options | value
                else
                    error("expected integer or string from hs.utf16.compareOptions in argument 2 table", 2)
                end
            else
                error("expected integer or string from hs.utf16.compareOptions in argument 2 table", 2)
            end
        end
        args[2] = options
    end
    return self:_compare(table.unpack(args))
end

module.utf16.builtinTransforms = ls.makeConstantsTable(module.utf16.builtinTransforms)
module.utf16.compareOptions    = ls.makeConstantsTable(module.utf16.compareOptions)

-- pragma - mark - hs.text.regex functions, methods, and constants

--- hs.text.regex.new(pattern, [options]) -> regexObject
--- Constructor
--- Create a new `hs.text.regex` object with the specified regular expression
---
--- Parameters:
---  * `pattern` - a lua string specifying the regular expression
---  * `options` - an optional integer or table of integers and strings corresponding to values in the [hs.text.regex.expressionOptions](#expressionOptions) constant.
---    * if `options` is an integer, it should a combination of 1 or more of the numeric values in the [hs.text.regex.expressionOptions](#expressionOptions) constant logically OR'ed together (e.g. `hs.text.regex.expressionOptions.caseInsensitive | hs.text.regex.expressionOptions.ignoreMetacharacters`)
---    * if `options` is a table, each element of the array table should be a number value from the [hs.text.regex.expressionOptions](#expressionOptions) constant or a string matching one of the constant's keys. This method will logically OR the appropriate values together for you (e.g. `{"caseInsensitive", "ignoreMetacharacters"}`)
---
--- Returns:
---  * a new regexObject, or nil if there is an error in the regular expression
---
--- Notes:
---  * The regular expression syntax supported by this module is described in detail at http://userguide.icu-project.org/strings/regexp
---  * Any error encountered when creating the regular expression object will be logged to the Hammerspoon console and this method will return nil.
module.regex.new = function(...)
    local args = table.pack(...)
    if type(args[2]) == "table" then
        local options = 0
        for _,v in ipairs(args[2]) do
            if type(v) == "number" then
                options = options | v
            elseif type(v) == "string" then
                local value = module.regex.expressionOptions[v]
                if value then
                    options = options | value
                else
                    error("expected integer or string from hs.regex.expressionOptions in argument 2 table", 2)
                end
            else
                error("expected integer or string from hs.regex.expressionOptions in argument 2 table", 2)
            end
        end
        args[2] = options
    end
    return module.regex._new(table.unpack(args))
end

module.regex.expressionOptions = ls.makeConstantsTable(module.regex.expressionOptions)
module.regex.matchOptions      = ls.makeConstantsTable(module.regex.matchOptions)

--- hs.text.regex:gmatchIn(text, [i]) -> function
--- Method
--- Apply the regular expression to the provided text and return an iterator function for use like `string.gmatch`.
---
--- Parameters:
---  * `text`  - the text to apply the regular expression to, provided as a lua string or `hs.text.utf16` object.
---  * `i`     - an optional integer, default 1, specifying the starting index within `text` that the regular expression should be applied to; negative indicies are counted from the end of the text.
---
--- Returns:
---  * an iterator function
---
--- Notes:
---  * The iterator function is defined such that each time it is called, it will return the next captures from the pattern over the object. If the pattern specifies no captures, then the whole match is produced in each call.
---  * Most commonly this will be used as the iterator in a `for` loop, e.g.
---
---     ```
---     t = {}
---     r = hs.text.regex.new([[(\w+)=(\w+)]])
---     for k, v in r:gmatchIn("from=world, to=Lua") do
---       t[k] = v
---     end
---     ```
---
---  * if `text` is a lua string:
---    * `i` should be specified in terms of byte positions within the string.
---    * if `i` falls within the middle of a composite UTF8 byte sequence, it will be internally adjusted to the beginning of the *next* proper UTF8 byte sequence. If you need to perform a match on raw binary data, you should use the `string` library instead to avoid this internal adjustment.
---  * if `text` is an `hs.text.utf16` object:
---    * a copy is made before creating the iterator so it is safe to modify the original object from within a loop using the iterator function.
---    * `i` should be specified in terms of UTF16 "character" positions within the string and, depending upon the pattern, may break surrogate pairs or composed characters. See `hs.text.utf16:composedCharacterRange` to verify match and indicies if this might be an issue for your purposes.
regexMT.gmatchIn = function(self, text, init)
    assert(
        type(text) == "string" or getmetatable(text) == utf16MT,
        string.format("expected string or %s object", (USERDATA_TAG..".utf16"))
    )
    -- if used within a loop, this allows changes to the original object
    if getmetatable(text) == utf16MT then text = text:copy() end

    local pos = init or 1
    return function()
        if pos > #text then return end
        local results = self:firstMatch(text, pos)
        if not results then return end

        local answers = {}
        if results[0] then -- has captures
            pos = results[0][2] + 1
            for i = 1, #results, 1 do
                local vRange = results[i]
                answers[i] = vRange and text:sub(table.unpack(vRange)) or nil
            end
        else -- doesn't have captures
            pos = results[2] + 1
            answers[1] = text:sub(table.unpack(results))
        end

        return table.unpack(answers)
    end
end

--- hs.text.regex:findIn(pattern, [i]) -> start, end, [captures...] | nil
--- Method
--- Apply the regular expression to the provided text and returns the indicies first match for use like `string.find`.
---
--- Parameters:
---  * `text`  - the text to apply the regular expression to, provided as a lua string or `hs.text.utf16` object.
---  * `i`     - an optional integer, default 1, specifying the starting index within `text` that the regular expression should be applied to; negative indicies are counted from the end of the text.
---
--- Returns:
---  * If a match is found, returns the starting and ending indicies of the match (as integers); if captures are specified in the pattern, also returns each capture after the indicies. If no match is found, returns nil.
---
--- Notes:
---  * Unlike `string.find`, this method does not have a `plain` parameter. If you wish to perform a "plain" find operation, use the [hs.text.regex.expressionOptions.ignoreMetacharacters](#expressionOptions) option when creating the regular expression.
---
---  * if `text` is a lua string:
---    * captures (if any) will be returned as lua strings
---    * `i` should be specified in terms of byte positions within the string.
---    * if `i` falls within the middle of a composite UTF8 byte sequence, it will be internally adjusted to the beginning of the *next* proper UTF8 byte sequence. If you need to perform a match on raw binary data, you should use the `string` library instead to avoid this internal adjustment.
---  * if `text` is an `hs.text.utf16` object:
---    * captures (if any) will be returned as `hs.text.utf16` objects
---    * `i` should be specified in terms of UTF16 "character" positions within the string and, depending upon the pattern, may break surrogate pairs or composed characters. See `hs.text.utf16:composedCharacterRange` to verify match and indicies if this might be an issue for your purposes.
regexMT.findIn = function(self, text, init)
    assert(
        type(text) == "string" or getmetatable(text) == utf16MT,
        string.format("expected string or %s object", (USERDATA_TAG..".utf16"))
    )

    local pos = init or 1

    local results = self:firstMatch(text, pos, -1)
    if not results then return nil end

    local answers = results[0] and results[0] or results
    if results[0] then -- also has captures
        for i = 1, #results, 1 do
            local vRange = results[i]
            answers[2 + i] = vRange and text:sub(table.unpack(vRange)) or nil
        end
    end

    return table.unpack(answers)
end


--- hs.text.regex:matchIn(text, [i]) -> match(es) | nil
--- Method
--- Apply the regular expression to the provided text and returns the first match for use like `string.match`.
---
--- Parameters:
---  * `text`  - the text to apply the regular expression to, provided as a lua string or `hs.text.utf16` object.
---  * `i`     - an optional integer, default 1, specifying the starting index within `text` that the regular expression should be applied to; negative indicies are counted from the end of the text.
---
--- Returns:
---  * If a match is found and the pattern specifies captures, returns each capture; if no captures are specified, returns the entire match. If no matche is found, returns nil.
---
--- Notes:
---  * if `text` is a lua string:
---    * the returned match or captures will be returned as lua strings
---    * `i` should be specified in terms of byte positions within the string.
---    * if `i` falls within the middle of a composite UTF8 byte sequence, it will be internally adjusted to the beginning of the *next* proper UTF8 byte sequence. If you need to perform a match on raw binary data, you should use the `string` library instead to avoid this internal adjustment.
---  * if `text` is an `hs.text.utf16` object:
---    * the returned match or captures will be returned as `hs.text.utf16` objects
---    * `i` should be specified in terms of UTF16 "character" positions within the string and, depending upon the pattern, may break surrogate pairs or composed characters. See `hs.text.utf16:composedCharacterRange` to verify match and indicies if this might be an issue for your purposes.
regexMT.matchIn = function(self, text, init)
    assert(
        type(text) == "string" or getmetatable(text) == utf16MT,
        string.format("expected string or %s object", (USERDATA_TAG..".utf16"))
    )

    local pos = init or 1

    local results = self:firstMatch(text, pos, -1)
    if not results then return nil end

    local answers = {}
    if results[0] then -- has captures
        for i = 1, #results, 1 do
            local vRange = results[i]
            answers[i] = vRange and text:sub(table.unpack(vRange)) or nil
        end
    else -- doesn't have captures
        answers[1] = text:sub(table.unpack(results))
    end

    return table.unpack(answers)
end

-- regexMT.gsubIn

-- Return Module Object --------------------------------------------------

return module
