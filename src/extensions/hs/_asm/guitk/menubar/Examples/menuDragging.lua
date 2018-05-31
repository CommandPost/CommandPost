local module = {}

local menubar    = require("hs._asm.guitk.menubar")
local image      = require("hs.image")
local pasteboard = require "hs.pasteboard"
local inspect    = require "hs.inspect"
local timer      = require "hs.timer"
local console    = require "hs.console"
local canvas     = require "hs.canvas"

module.restingImage   = image.imageFromName("NSStatusAvailable")
module.receivingImage = image.imageFromName("NSStatusPartiallyAvailable")

module.menu = menubar.statusitem.new(true):image(module.restingImage):draggingCallback(function(si, msg, details)
    hs.printf("%s:%s - %s", timestamp(), msg, (inspect(details):gsub("%s+", " ")))

-- the drag entered our view frame
    if msg == "enter" then
        si:image(module.receivingImage)
        -- could inspect details and reject with `return false`
        -- but we're going with the default of true

-- the drag exited our view domain without a release (or we returned false for "enter")
    elseif msg == "exit" or msg == "exited" then
        -- return type ignored
        si:image(module.restingImage)

-- the drag finished -- it was released on us!
    elseif msg == "receive" then
        si:image(module.restingImage)

        local name = details.pasteboard
        local types = pasteboard.typesAvailable(name)
        hs.printf("\n\t%s\n%s\n%s\n", name, (inspect(types):gsub("%s+", " ")), inspect(pasteboard.allContentTypes()))

        if types.string then
            local stuffs = pasteboard.readString(name, true) or {} -- sometimes they lie
            hs.printf("strings: %d", #stuffs)
            for i, v in ipairs(stuffs) do
                print(i, v)
            end
        end

        if types.styledText then
            local stuffs = pasteboard.readStyledText(name, true) or {} -- sometimes they lie
            hs.printf("styledText: %d", #stuffs)
            for i, v in ipairs(stuffs) do
                console.printStyledtext(i, v)
            end
        end

        if types.URL then
            local stuffs = pasteboard.readURL(name, true) or {} -- sometimes they lie
            hs.printf("URL: %d", #stuffs)
            for i, v in ipairs(stuffs) do
                print(i, (inspect(v):gsub("%s+", " ")))
            end
        end

        -- try dragging an image from Safari
        if types.image then
            local stuffs = pasteboard.readImage(name, true) or {} -- sometimes they lie
            hs.printf("image: %d", #stuffs)
            module.imageHolder = {}
            for i, v in ipairs(stuffs) do
                local holder = canvas.new{ x = 100 * i, y = 100, h = 100, w = 100 }:show()
                holder[#holder + 1] = {
                    type = "image",
                    image = v,
                }
                table.insert(module.imageHolder, holder)
            end
            module.clear = timer.doAfter(5, function()
                for k,v in ipairs(module.imageHolder) do
                    v:delete()
                end
                module.clear = nil
            end)
        end

        print("")
        -- could inspect details and reject with `return false`
        -- but we're going with the default of true
    end
end)

return module
