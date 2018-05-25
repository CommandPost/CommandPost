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

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local fcp           = require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- DEVELOPER SHORTCUTS FOR USE IN ERROR LOG:
--------------------------------------------------------------------------------
_plugins            = require("cp.plugins")                 -- luacheck: ignore
_fcp                = require("cp.apple.finalcutpro")       -- luacheck: ignore

--------------------------------------------------------------------------------
-- FIND UNUSED LANGUAGES STRINGS:
--------------------------------------------------------------------------------
function _findUnusedLanguageStrings() -- luacheck: ignore
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
function _findString(string) -- luacheck: ignore
    local output, status = hs.execute([[grep -r ']] .. string .. [[' ']] .. fcp:getPath() .. [[/']])
    if status then
        log.df("Output: %s", output)
    else
        log.ef("An error occurred in _findString")
    end
end

--------------------------------------------------------------------------------
-- ELEMENT AT MOUSE:
--------------------------------------------------------------------------------
function _elementAtMouse() -- luacheck: ignore
    return ax.systemElementAtPosition(mouse.getAbsolutePosition())
end

--------------------------------------------------------------------------------
-- INSPECT ELEMENT AT MOUSE:
--------------------------------------------------------------------------------
function _inspectAtMouse(options) -- luacheck: ignore
    options = options or {}
    local element = _elementAtMouse() -- luacheck: ignore
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
                result = result .._inspectElement(e, options, i) -- luacheck: ignore
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
function _inspect(e, options) -- luacheck: ignore
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
                         _inspect(item, options) -- luacheck: ignore
            end
            return result
        else
            return inspect(e, options)
        end
    else
        return "\n==============================================" ..
               _inspectElement(e, options) -- luacheck: ignore
    end
end

--------------------------------------------------------------------------------
-- INSPECT ELEMENT:
--------------------------------------------------------------------------------
function _inspectElement(e, options) -- luacheck: ignore
    _highlight(e) -- luacheck: ignore

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
function _highlight(e) -- luacheck: ignore
    if not e or not e.frame then
        return e
    end

    local eFrame = geometry.rect(e:frame())

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
function _highlightPoint(point) -- luacheck: ignore
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
function _inspectElementAtMousePath() -- luacheck: ignore
    return inspect(_elementAtMouse():path()) -- luacheck: ignore
end
