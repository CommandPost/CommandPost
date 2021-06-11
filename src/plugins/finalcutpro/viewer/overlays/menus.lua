local require = require

local hs                = _G.hs

local i18n              = require "cp.i18n"

local dialog            = require "hs.dialog"
local color             = require "hs.drawing.color"

local insert            = table.insert
local format            = string.format

local menus = {}

function menus.generateSeparatorMenuItem()
    return { title = "-", disabled = true }
end

local colorOptions = {
    { title = i18n("black"),    color = color.asRGB({ hex = "#000000" }) },
    { title = i18n("white"),    color = color.asRGB({ hex = "#FFFFFF" }) },
    { title = i18n("yellow"),   color = color.asRGB({ hex = "#F4D03F" }) },
    { title = i18n("red"),      color = color.asRGB({ hex = "#FF5733" }) },
}

local function setCustomColor(colorProp)
    dialog.color.continuous(false)
    dialog.color.callback(function(color, closed)
        if closed then
            colorProp(color)
        end
    end)
    dialog.color.show()
    hs.focus()
end

local function colorsEqual(left, right)
    if left == nil then
        return right == nil
    elseif right == nil then
        return false
    end

    return left.red == right.red
        and left.green == right.green
        and left.blue == right.blue
end

function menus.generateColorMenu(title, colorProp)
    local currentColor = colorProp()
    local menu = {}

    local foundColor = false

    for _,option in ipairs(colorOptions) do
        local isOption = colorsEqual(currentColor, option.color)
        foundColor = foundColor or isOption
        insert(menu, { title = option.title, checked = isOption, fn = function() colorProp(option.color) end })
    end

    insert(menu, menus.generateSeparatorMenuItem() )
    insert(menu, { title = i18n("custom"), checked = not foundColor, fn = function() setCustomColor(colorProp) end })

    return { title = title, menu = menu }
end

function menus.generateAlphaMenu(title, alphaProp)
    local currentAlpha = alphaProp()
    local menu = {}

    for i = 10,100,10 do
        insert(menu, {
            title = format("%d%%", i),
            checked = currentAlpha == i,
            fn = function() alphaProp(i) end,
        })
    end

    return { title = title, menu = menu }
end

return menus