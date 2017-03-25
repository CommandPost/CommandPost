local mouse			= require("hs.mouse")
local inspect		= require("hs.inspect")
local geometry		= require("hs.geometry")
local drawing		= require("hs.drawing")
local timer			= require("hs.timer")

--------------------------------------------------------------------------------
-- ELEMENT AT MOUSE:
--------------------------------------------------------------------------------
function _elementAtMouse()
    return ax.systemElementAtPosition(mouse.getAbsolutePosition())
end

--------------------------------------------------------------------------------
-- INSPECT ELEMENT AT MOUSE:
--------------------------------------------------------------------------------
function _inspectAtMouse(options)
    options = options or {}
    local element = _elementAtMouse()
    if options.parents then
        for i=1,options.parents do
            element = element ~= nil and element:parent()
        end
    end

    if element then
        local result = ""
        if options.type == "path" then
            local path = element:path()
            for i,e in ipairs(path) do
                result = result .._inspectElement(e, options, i)
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
function _inspect(e, options)
    if e == nil then
        return "<nil>"
    elseif type(e) ~= "userdata" or not e.attributeValue then
        if type(e) == "table" and #e > 0 then
            local item = nil
            local result = ""
            for i=1,#e do
                item = e[i]
                result = result ..
                         "\n= " .. string.format("%3d", i) ..
                         " ========================================" ..
                         _inspect(item, options)
            end
            return result
        else
            return inspect(e)
        end
    else
        return "\n==============================================" ..
               _inspectElement(e, options)
    end
end

--------------------------------------------------------------------------------
-- INSPECT ELEMENT:
--------------------------------------------------------------------------------
function _inspectElement(e, options, i)
    _highlightElement(e)

    i = i or 0
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
function _highlightElement(e)
    if not e.frame then
        return
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
    local highlightTimer = timer.doAfter(3,
    function()
        highlight:delete()
        highlightTimer = nil
    end)
end

--------------------------------------------------------------------------------
-- INSPECT ELEMENT AT MOUSE PATH:
--------------------------------------------------------------------------------
function _inspectElementAtMousePath()
    return inspect(_elementAtMouse():path())
end