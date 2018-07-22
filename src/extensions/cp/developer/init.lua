--- === cp.developer ===
---
--- Developer Tools
---

--[[

hs.hotkey.bind({"cmd", "alt", "ctrl", "shift"}, "q", function()
  require("cp.developer")
  print(_inspectAtMouse())
end)

--]]

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log           = require("hs.logger").new("develop")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local ax            = require("hs._asm.axuielement")
local drawing       = require("hs.drawing")
local geometry      = require("hs.geometry")
local inspect       = require("hs.inspect")
local mouse         = require("hs.mouse")
local timer         = require("hs.timer")

local config        = require("cp.config")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- DEVELOPER SHORTCUTS FOR USE IN ERROR LOG:
--------------------------------------------------------------------------------
_G._plugins            = require("cp.plugins")
_G._fcp                = require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
-- FIND UNUSED LANGUAGES STRINGS:
--------------------------------------------------------------------------------
function _G._findUnusedLanguageStrings()
    local translations = require("cp.resources.languages.en")["en"]
    local result = "\nUNUSED STRINGS IN EN.LUA:\n"
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

--------------------------------------------------------------------------------
-- FIND TEXT:
--------------------------------------------------------------------------------
local whiches = {}
function _G._which(cmd)
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

--------------------------------------------------------------------------------
-- ELEMENT AT MOUSE:
--------------------------------------------------------------------------------
function _G._elementAtMouse()
    return ax.systemElementAtPosition(mouse.getAbsolutePosition())
end

--------------------------------------------------------------------------------
-- INSPECT ELEMENT AT MOUSE:
--------------------------------------------------------------------------------
function _G._inspectAtMouse(options)
    options = options or {}
    local element = _G._elementAtMouse()
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
                result = result .. _G._inspectElement(e, options, i)
            end
            return result
        else
            return inspect(element:buildTree(options.depth))
        end
    else
        return "<no element found>"
    end
end

--------------------------------------------------------------------------------
-- INSPECT:
--------------------------------------------------------------------------------
function _G._inspect(e, options)
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
                         _G._inspect(item, options)
            end
            return result
        else
            return inspect(e, options)
        end
    else
        return "\n==============================================" ..
               _G._inspectElement(e, options)
    end
end

--------------------------------------------------------------------------------
-- INSPECT ELEMENT:
--------------------------------------------------------------------------------
function _G._inspectElement(e, options)
    _G._highlight(e)

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

--------------------------------------------------------------------------------
-- HIGHLIGHT ELEMENT:
--------------------------------------------------------------------------------
function _G._highlight(e)
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

local SIZE = 100
function _G._highlightPoint(point)
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

--------------------------------------------------------------------------------
-- INSPECT ELEMENT AT MOUSE PATH:
--------------------------------------------------------------------------------
function _G._inspectElementAtMousePath()
    return inspect(_G._elementAtMouse():path())
end

-- _test(id) -> cp.test
-- Function
-- This function will return a [cp.test](cp.test.md) with either the
-- name `<id>_test` or `<id>._test` if the `<id>` is pointing at a folder.
--
-- For example, you have an extensions called
-- `foo.bar`, and you want to create a test for it.
--
-- Option 1: `<id>_test`
-- * File: `/src/tests/foo/bar_test.lua`
--
-- Option 2: `<id>._test`
-- * File: `/src/tests/foo/bar/_test.lua`
--
-- You could then run all the contained tests like so:
-- ```lua
-- _test("foo.bar")()
-- ```
--
-- Parameters:
-- * id     - the `id` to test.
--
-- Returns:
-- * A [cp.test] to execute.
function _G._test(id)
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