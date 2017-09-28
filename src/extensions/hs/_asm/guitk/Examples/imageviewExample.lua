local guitk  = require("hs._asm.guitk")
local image  = require("hs.image")
local stext  = require("hs.styledtext")
local canvas = require("hs.canvas")

local module = {}

local gui = guitk.new{ x = 100, y = 100, h = 500, w = 500 }:show()
local mgr = guitk.manager.new()
gui:contentManager(mgr)

mgr[#mgr + 1] = {
    _element = guitk.element.textfield.newLabel(stext.new(
                    "Drag an image file into the box or\npaste one from the clipboard",
                    { paragraphStyle = { alignment = "center" } }
    )),
    frameDetails = {
        cX = "50%",
        y  = 5,
    }
}

local placeholder = canvas.new{ x = 0, y = 0, h = 500, w = 500 }:appendElements{
    {
        type  = "image",
        image = image.imageFromName(image.systemImageNames.ExitFullScreenTemplate)
    }, {
        type  = "image",
        image = image.imageFromName(image.systemImageNames.ExitFullScreenTemplate),
        transformation = canvas.matrix.translate(250,250):rotate(90):translate(-250,-250),
    }
}:imageFromCanvas()

local imageElement = guitk.element.image.new():image(placeholder)
                                              :allowsCutCopyPaste(true)
                                              :editable(true)
                                              :imageAlignment("center")
                                              :imageFrameStyle("bezel")
                                              :imageScaling("proportionallyUpOrDown")
                                              :callback(function(o)
                                                  if module.canvas then module.canvas:delete() end
                                                  module.canvas = canvas.new{ x = 700, y = 100, h = 100, w = 100 }:show()
                                                  module.canvas[1] = {
                                                      type = "image",
                                                      image = o:image()
                                                  }
                                              end)

mgr:insert(imageElement, { w = 450, h = 450 })
imageElement:moveBelow(mgr(1), 5, "centered")

module.manager = mgr

return module
