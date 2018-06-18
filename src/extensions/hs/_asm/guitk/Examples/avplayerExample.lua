local guitk = require("hs._asm.guitk")

-- Note: this gets real annoying real fast if you have audio turned up... it's just a proof of concept example

local module = {}

local gui = guitk.new{x = 100, y = 100, h = 300, w = 300 }
local player = guitk.element.avplayer.new()

-- in this example we attach the element directly to the window, eschewing a content manager.  Since the AV view is
-- all we want in this window, it can be its "own" content manager.  If you want to be able to add additional buttons
-- or images or what-not in the window, use `hs._asm.guitk.manager` as the content manager and add the player
-- to it instead (see the button example).

gui:contentManager(player)
player:controlsStyle("inline")
      :load("http://devimages.apple.com/iphone/samples/bipbop/bipbopall.m3u8")
      :play()
      :show() -- actually a guitk method, but unrecognized methods pass through up the responder chain

-- returning only the player; usually we can ignore the window once it's created because
--   (a) usually we're primarily interested in the window's content and not the window itself
--   (b) the window will not auto-collect; it requires an explicit delete to completely remove it
--   (c) methods not recognized by the element/manager will pass up the responder chain so methods like
--       frame, size, show, hide, delete, etc. will reach the window object anyways
module.player = player
return module
