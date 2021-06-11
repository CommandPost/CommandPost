local require = require
local AudioConfiguration = require "AudioConfiguration"
local SearchField = require "SearchField"

local menus                 = require "menus"
local OverlayLayer          = require "OverlayLayer"

local config                = require "cp.config"
local i18n                  = require "cp.i18n"

local insert                = table.insert

local GridLayer = OverlayLayer:subclass("finalcutpro.viewer.overlays.Overlay")

GridLayer.static.sizes = { 2, 3, 4, 5, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100 }

function GridLayer:initialize(overlay)
    OverlayLayer.initialize(self, overlay)
end

function GridLayer.lazy.prop:isEnabled()
    config.prop("finalcutpro.viewer.overlays.GridLayer.enabled")
    :watch(function() self.overlay:update() end)
end

function GridLayer.lazy.prop:color()
    return config.prop("finalcutpro.viewer.overlays.GridLayer.color")
    :watch(function() self.overlay:update() end)
end

function GridLayer.lazy.prop:alpha()
    return config.prop("finalcutpro.viewer.overlays.GridLayer.alpha")
end

function GridLayer.lazy.prop:spacing()
    return config.prop("finalcutpro.viewer.overlays.GridLayer.spacing")
end

local function generateSpacingMenu(title, spacingProp)
    local currentSpacing = spacingProp()
    local menu = {}

    for i = 5,100,5 do
        insert(menu, {
            title = tostring(i),
            checked = currentSpacing == i,
            fn = function() spacingProp(i) end
        })
    end

    return { title = title, menu = menu }
end

function GridLayer:generateAppearanceMenu(menu)
    -- colors
    menu:addItem(menus.generateColorMenu("  ".. i18n("color"), self.color))
    menu:addItem(menus.generateAlphaMenu("  "..i18n("opacity"), self.alpha))
    menu:addItem(generateSpacingMenu("  "..i18n("segments"), self.spacing))

    return menu
end

function GridLayer:buildMenu(section)

    section:addHeading(i18n("gridOverlay"))

    section:addItem(function()
        return { title = "  " .. i18n("enable"), checked = self:isEnabled(), fn = function() self.isEnabled:toggle() end }
    end)

    self:generateAppearanceMenu(section:addMenu("  "..i18n("appearance")))

    section:addSeparator()

    section:addItem(function()
        return { title = i18n("reset") .. " " .. i18n("overlays"), fn = function() self:resetOverlays() end }
    end)
end

return GridLayer