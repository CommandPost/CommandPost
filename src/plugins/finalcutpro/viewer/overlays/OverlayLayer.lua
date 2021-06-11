local require = require

local class             = require "metaclass"
local lazy              = require "cp.lazy"

local OverlayLayer = class("finalcutpro.viewer.overlays.OverlayLayer"):include(lazy)

-- finalcutpro.viewer.overlays.OverlayLayer(overlay) -> OverlayLayer
-- Constructor
-- Should not be called directly, but called by implementing classes.
--
-- Parameters:
--  * overlay  - the `Overlay` the layer belongs to.
--
-- Returns:
--  * The initialized `OverlayLayer`.
function OverlayLayer:initialize(overlay)
    self.overlay = overlay
end

-- finalcutpro.viewer.overlays.OverlayLayer:buildMenu(section)
-- Method
-- Passed a `core.menu.manager.section` into which any addtional menu
-- items/sections/menus should be added into to allow configuration of the layer.
--
-- Parameters:
--  * section - The `core.menu.manager.section`.
function OverlayLayer.buildMenu(_)
end

-- finalcutpro.viewer.overlays.OverlayLayer:drawOn(overlay)
-- Method
-- Draws on the provided `overlay` `hs.canvas` instance.
--
-- Parameters:
--  * overlay - The `hs.canvas` to draw on.
--
-- Returns:
--  * None
function OverlayLayer.drawOn(_)
    error("Unimplemented `drawOn` method.")
end

return OverlayLayer