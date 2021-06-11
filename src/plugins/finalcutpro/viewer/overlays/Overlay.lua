local require = require

local class             = require "metaclass"
local lazy              = require "cp.lazy"

local Overlay = class("finalcutpro.viewer.overlays.Overlay"):include(lazy)



return Overlay