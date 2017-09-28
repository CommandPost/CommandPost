local guitk   = require("hs._asm.guitk")
local image   = require("hs.image")
local inspect = require("hs.inspect")

local finspect = function(...) return (inspect({...}):gsub("%s+", " ")) end

local module = {}

local display = guitk.new{ x = 100, y = 100, h = 100, w = 100 }:show():passthroughCallback(function(...) print(finspect(...)) end)
local manager = guitk.manager.new()
display:contentManager(manager)

-- TODO:
-- need to add code to display bezel types as well and code to display those in their best form
-- e.g. the disclosure bezels only make sense with the onOff or pushOnPushOff types
local types = {
    "momentaryLight",
    "toggle",
    "switch",
    "radio",
    "momentaryChange",
    "multiLevelAccelerator",
    "onOff",
    "pushOnPushOff",
    "accelerator",
    "momentaryPushIn"
}

for i, v in ipairs(types) do
    manager[#manager + 1] = guitk.element.button.buttonType(v):title(v):alternateTitle("not " .. v):tooltip("button type " .. v)
end

local lastFrame = manager[#manager].frameDetails._effective

-- 10.12 constructors; approximations are used if 10.11 or 10.10 detected; included here so I can determine what to mimic
manager[#manager + 1] = {
    _element     = guitk.element.button.buttonWithImage(image.imageFromName(image.systemImageNames.ApplicationIcon)),
    frameDetails = { y = lastFrame.y + 2 * lastFrame.h }
}
manager[#manager + 1] = guitk.element.button.buttonWithTitle("buttonWithTitle")
manager[#manager + 1] = guitk.element.button.buttonWithTitleAndImage("buttonWithTitleAndImage", image.imageFromName(image.systemImageNames.ApplicationIcon))
manager[#manager + 1] = guitk.element.button.checkbox("checkbox")
manager[#manager + 1] = guitk.element.button.radioButton("radioButton")

-- radio buttons within the same manager only allow one at a time to be selected (they automatically unselect the others)
-- to have multiple sets of radio buttons they need to be in different managers (views)
local radio = guitk.manager.new():tooltip("grouped radiobuttons")
radio:insert(guitk.element.button.radioButton("A"):tooltip("A"))
radio:insert(guitk.element.button.radioButton("B"):tooltip("not A"))
radio:insert(guitk.element.button.radioButton("C"):tooltip("also not A"))
-- then add the new manager to the main one just like any other element
manager:insert(radio, { x = 200, y = 200 })
manager:sizeToFit(20, 10)

-- returning only the manager; usually we can ignore the window once it's created because
--   (a) usually we're primarily interested in the window's content and not the window itself
--   (b) the window will not auto-collect; it requires an explicit delete to completely remove it
--   (c) methods not recognized by the element/manager will pass up the responder chain so methods like
--       frame, size, show, hide, delete, etc. will reach the window object anyways
module.manager  = manager

return module
