--- === cp.dev ===
---
--- A set of handy developer tools for CommandPost.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log           = require("hs.logger").new("dev")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local ax            = require("hs._asm.axuielement")
local drawing       = require("hs.drawing")
local geometry      = require("hs.geometry")
local hotkey        = require("hs.hotkey")
local inspect       = require("hs.inspect")
local json          = require("hs.json")
local mouse         = require("hs.mouse")
local timer         = require("hs.timer")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config        = require("cp.config")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- cp.dev.hotkey(fn) -> none
--- Function
--- Assigns a function to the CONTROL+OPTION+COMMAND+SHIFT+Q keyboard combination.
---
--- Parameters:
---  * fn - A function to execute when the hotkey is triggered.
---
--- Returns:
---  * None
function mod.hotkey(fn)
    mod._hotkey = hotkey.bind({"cmd", "alt", "ctrl", "shift"}, "q", fn)
end

--- cp.dev.findUnusedLanguageStrings() -> string
--- Function
--- Searches for any unused language strings in English.json.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A string with the results of the search.
function mod.findUnusedLanguageStrings()

    local path = config.languagePath .. "English.json"
    local data = io.open(path, "r")
    local content, decoded
    if data then
        content = data:read("*all")
        data:close()
    end
    if content then
        decoded = json.decode(content)
    end

    local translations = decoded["en"]

    local result = "\nUNUSED STRINGS IN English.json:\n"
    local stringCount = 0
    local ignoreStart = {"plugin_group_", "shareDetails_", "plugin_status_", "plugin_action_", "shortcut_group_"}
    local ignoreEnd = {"_action", "_label", "_title", "_customTitle", "_group"}
    for string, _ in pairs(translations) do
        local skip = false
        for _, ignoreFile in pairs(ignoreStart) do
            if string.sub(string, 1, string.len(ignoreFile)) == ignoreFile then
                skip = true
            end
        end
        for _, ignoreFile in pairs(ignoreEnd) do
            if string.sub(string, string.len(ignoreFile) * -1) == ignoreFile then
                skip = true
            end
        end
        if not skip then
            local executeString = [[grep -r --max-count=1 --exclude-dir=resources --include \*.html --include \*.htm --include \*.lua ']] .. string .. [[' ']] .. hs.processInfo.bundlePath .. [[/']]
            local _, status = hs.execute(executeString)
            if not status then
                result = result .. string .. "\n"
                stringCount = stringCount + 1
            end
        end
    end
    if stringCount == 0 then
        result = result .. "None"
    end
    log.df(result)
end

--- cp.dev.which(cmd) -> none
--- Function
--- The which utility takes a list of command names and searches the path for
--- each executable file that would be run had these commands actually been
--- invoked.
---
--- Parameters:
---  * cmd - The parameters to pass along to the `which` executable.
---
--- Returns:
---  * The path or `nil` and the error message if an error occurs.
local whiches = {}
function mod.which(cmd)
    local path = whiches[cmd]
    if not path then
        local output, ok = hs.execute(string.format("which %q", cmd))
        if ok then
            path = output:match("([^\r\n]*)")
            whiches[cmd] = path
        else
            return nil, output
        end
    end
    return path
end

--- cp.dev.elementAtMouse() -> axuielementObject
--- Function
--- Gets the AX element under the current mouse position.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.elementAtMouse()
    return ax.systemElementAtPosition(mouse.getAbsolutePosition())
end

--- cp.dev.inspectAtMouse(options) -> string
--- Function
--- Inspects an AX element under the current mouse position.
---
--- Parameters:
---  * options - Any additional options to pass along to `cp.dev.inspectElement`.
---
--- Returns:
---  * A string containing the results.
function mod.inspectAtMouse(options)
    options = options or {}
    local element = mod.elementAtMouse()
    if options.parents then
        for _=1,options.parents do
            element = element ~= nil and element:parent()
        end
    end

    if element then
        local result = ""
        if options.type == "path" then
            local path = element:path()
            for i,e in ipairs(path) do
                result = result .. mod.inspectElement(e, options, i)
            end
            return result
        else
            return inspect(element:buildTree(options.depth))
        end
    else
        return "<no element found>"
    end
end

--- cp.dev.inspect(item, options) -> string
--- Function
--- Inspect an item.
---
--- Parameters:
---  * item - The object to inspect.
---  * options - Any additional options to pass along to `cp.dev.inspectElement`.
---
--- Returns:
---  * A results as a string.
function mod.inspect(e, options)
    if e == nil then
        return "<nil>"
    elseif type(e) ~= "userdata" or not e.attributeValue then
        if type(e) == "table" and #e > 0 then
            local item
            local result = ""
            for i=1,#e do
                item = e[i]
                result = result ..
                         "\n= " .. string.format("%3d", i) ..
                         " ========================================" ..
                         mod.inspect(item, options)
            end
            return result
        else
            return inspect(e, options)
        end
    else
        return "\n==============================================" ..
               mod.inspectElement(e, options)
    end
end

--- cp.dev.inspectElement() -> string
--- Function
--- Inspect an AX element.
---
--- Parameters:
---  * element - The element to inspect.
---  * options - A table containing any optional values.
---
--- Returns:
---  * The results as a string.
---
--- Notes:
---  * The options table accepts the following parameters:
---   * depth - A number representing the maximum depth to recurse into variable.
function mod.inspectElement(e, options)
    mod._highlight(e)

    local depth = options and options.depth or 1
    local out = "\n      Role       = " .. inspect(e:attributeValue("AXRole"))

    local id = e:attributeValue("AXIdentifier")
    if id then
        out = out.. "\n      Identifier = " .. inspect(id)
    end

    out = out.. "\n      Children   = " .. inspect(#e)

    out = out.. "\n==============================================" ..
                "\n" .. inspect(e:buildTree(depth)) .. "\n"

    return out
end

--- cp.dev.highlight(element) -> axuielementObject
--- Function
--- Highlights an AX element on the screen.
---
--- Parameters:
---  * element - The AX element to highlight.
---
--- Returns:
---  * The element.
function mod.highlight(e)
    if not e or not e.frame then
        return e
    end

    local eFrame = e:frame()
    if eFrame then
        eFrame = geometry.rect(eFrame)
    else
        return e
    end

    --------------------------------------------------------------------------------
    -- Get Highlight Colour Preferences:
    --------------------------------------------------------------------------------
    local highlightColor = {["red"]=1,["blue"]=0,["green"]=0,["alpha"]=0.75}

    local highlight = drawing.rectangle(eFrame)
    highlight:setStrokeColor(highlightColor)
    highlight:setFill(false)
    highlight:setStrokeWidth(3)
    highlight:show()

    --------------------------------------------------------------------------------
    -- Set a timer to delete the highlight after 3 seconds:
    --------------------------------------------------------------------------------
    timer.doAfter(3,
    function()
        highlight:delete()
    end)
    return e
end

--- cp.dev.highlightPoint(point) -> none
--- Function
--- Highlights a point on the screen.
---
--- Parameters:
---  * point - A `hs.geometry` point object.
---
--- Returns:
---  * None
function mod.highlightPoint(point)

    local SIZE = 100

    --------------------------------------------------------------------------------
    -- Get Highlight Colour Preferences:
    --------------------------------------------------------------------------------
    local hColor = {red=1, blue=0, green=0, alpha=0.75}

    local vert = drawing.line({x=point.x, y=point.y-SIZE}, {x=point.x, y=point.y+SIZE})
    vert:setStrokeColor(hColor)
    vert:setFill(false)
    vert:setStrokeWidth(1)

    local horiz = drawing.line({x=point.x-SIZE, y=point.y}, {x=point.x+SIZE, y=point.y})
    horiz:setStrokeColor(hColor)
    horiz:setFill(false)
    horiz:setStrokeWidth(1)

    vert:show()
    horiz:show()

    --------------------------------------------------------------------------------
    -- Set a timer to delete the highlight after 10 seconds:
    --------------------------------------------------------------------------------
    timer.doAfter(10,
    function()
        vert:delete()
        horiz:delete()
    end)
end

--- cp.dev.inspectElementAtMousePath() -> none
--- Function
--- Inspects an AX element at the mouse path.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.inspectElementAtMousePath()
    return inspect(mod.elementAtMouse():path())
end

--- cp.dev.test(id) -> cp.test
--- Function
--- This function will return a [cp.test](cp.test.md) with either the
--- name `<id>_test` or `<id>._test` if the `<id>` is pointing at a folder.
---
--- For example, you have an extensions called
--- `foo.bar`, and you want to create a test for it.
---
--- Option 1: `<id>_test`
--- * File: `/src/tests/foo/bar_test.lua`
---
--- Option 2: `<id>._test`
--- * File: `/src/tests/foo/bar/_test.lua`
---
--- You could then run all the contained tests like so:
--- ```lua
--- _test("foo.bar")()
--- ```
---
--- Parameters:
---  * id - the `id` to test.
---
--- Returns:
---  * A [cp.test] to execute.
function mod.test(id)
    id = id or ""
    local testsRoot = config.testsPath
    if not testsRoot then
        error "Unable to locate the test scripts."
    end

    local testPath = testsRoot .. "/?.lua;" .. testsRoot .. "/?/init.lua"

    local testId = id .. "_test"

    if not package.searchpath(testId, testPath) then
        if package.searchpath(id .. "._test", testPath) then
            testId = id .. "._test"
        else
            error(string.format("Unable to find tests for '%s'", id))
        end
    end

    local originalPath = package.path
    local tempPath = testPath .. ";" .. originalPath

    package.path = tempPath

    local ok, result = xpcall(function() return require(testId) end, debug.traceback)

    package.path = originalPath

    if not ok then
        error(result)
    else
        return result
    end
end

return mod