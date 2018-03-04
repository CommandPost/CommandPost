--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.main.Browser ===
---
--- Browser Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                             = require("hs.logger").new("browser")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
--local inspect                         = require("hs.inspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils                           = require("cp.ui.axutils")
local CheckBox                          = require("cp.ui.CheckBox")
local GeneratorsBrowser                 = require("cp.apple.finalcutpro.main.GeneratorsBrowser")
local LibrariesBrowser                  = require("cp.apple.finalcutpro.main.LibrariesBrowser")
local MediaBrowser                      = require("cp.apple.finalcutpro.main.MediaBrowser")
local PrimaryWindow                     = require("cp.apple.finalcutpro.main.PrimaryWindow")
local prop                              = require("cp.prop")
local SecondaryWindow                   = require("cp.apple.finalcutpro.main.SecondaryWindow")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Browser = {}

-- TODO: Add documentation
function Browser.matches(element)
    local checkBoxes = axutils.childrenWithRole(element, "AXCheckBox")
    return checkBoxes and #checkBoxes >= 3
end

-- TODO: Add documentation
-- TODO: Use a function instead of a method.
function Browser:new(app) -- luacheck: ignore
    local o = prop.extend({_app = app}, Browser)

--- cp.apple.finalcutpro.main.Browser.UI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- The `axuielement` for the browser, or `nil` if not available.
    o.UI = prop(function()
        return axutils.cache(self, "_ui", function()
            return Browser._findBrowser(app:secondaryWindow(), app:primaryWindow())
        end,
        Browser.matches)
    end):bind(o)

    -- monitor the 'Browser' button in the toolbar to track if the browser is visible.
    o.UI:monitor(app:toolbar().browserShowing)

--- cp.apple.finalcutpro.main.Browser.isOnSecondary <cp.prop: boolean; read-only>
--- Field
--- Is the Browser on the Secondary Window?
    o.isOnSecondary = o.UI:mutate(function(uiProp)
        local ui = uiProp()
        return ui and SecondaryWindow.matches(ui:window())
    end):bind(o)

--- cp.apple.finalcutpro.main.Browser.isOnPrimary <cp.prop: boolean; read-only>
--- Field
--- Is the Browser on the Primary Window?
    o.isOnPrimary = o.UI:mutate(function(uiProp)
        local ui = uiProp()
        return ui and PrimaryWindow.matches(ui:window())
    end):bind(o)

--- cp.apple.finalcutpro.main.Browser.isShowing <cp.prop: boolean; read-only>
--- Field
--- Is the Browser showing somewhere?
    o.isShowing = o.UI:mutate(function(uiProp)
        return uiProp() ~= nil
    end):bind(o)

    return o
end

-- TODO: Add documentation
function Browser:app()
    return self._app
end

-----------------------------------------------------------------------
--
-- BROWSER UI:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function Browser._findBrowser(...)
    for i = 1,select("#", ...) do
        local window = select(i, ...)
        if window then
            local ui = window:browserGroupUI()
            if ui then
                local browser = axutils.childMatching(ui, Browser.matches)
                if browser then return browser end
            end
        end
    end
    return nil
end

-- TODO: Add documentation
function Browser:showOnPrimary()
    -- show the parent.
    local menuBar = self:app():menuBar()

    -- if the browser is on the secondary, we need to turn it off before enabling in primary
    if self:isOnSecondary() then
        menuBar:checkMenu({"Window", "Show in Secondary Display", "Browser"})
    end
    -- Then enable it in the primary
    if not self:isShowing() then
        menuBar:checkMenu({"Window", "Show in Workspace", "Browser"})
    end
    return self
end

-- TODO: Add documentation
function Browser:showOnSecondary()
    -- show the parent.
    local menuBar = self:app():menuBar()

    if not self:isOnSecondary() then
        menuBar:selectMenu({"Window", "Show in Secondary Display", "Browser"})
    end
    return self
end

-- TODO: Add documentation
function Browser:hide()
    if self:isShowing() then
        -- Uncheck it from the workspace
        self:app():menuBar():selectMenu({"Window", "Show in Workspace", "Browser"})
    end
    return self
end

-----------------------------------------------------------------------
--
-- SECTIONS:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function Browser:showLibraries()
    if not self._showLibraries then
        self._showLibraries = CheckBox:new(self, function()
            local ui = self:UI()
            if ui and #ui > 3 then
                -- The library toggle is always the last element.
                return ui[#ui]
            end
            return nil
        end)
    end
    return self._showLibraries
end

-- TODO: Add documentation
function Browser:showMedia()
    if not self._showMedia then
        self._showMedia = CheckBox:new(self, function()
            local ui = self:UI()
            if ui and #ui > 3 then
                -- The media toggle is always the second-last element.
                return ui[#ui-1]
            end
            return nil
        end)
    end
    return self._showMedia
end

-- TODO: Add documentation
function Browser:showGenerators()
    if not self._showGenerators then
        self._showGenerators = CheckBox:new(self, function()
            local ui = self:UI()
            if ui and #ui > 3 then
                -- The generators toggle is always the third-last element.
                return ui[#ui-2]
            end
            return nil
        end)
    end
    return self._showGenerators
end

-- TODO: Add documentation
function Browser:libraries()
    if not self._libraries then
        self._libraries = LibrariesBrowser:new(self)
    end
    return self._libraries
end

-- TODO: Add documentation
function Browser:media()
    if not self._media then
        self._media = MediaBrowser:new(self)
    end
    return self._media
end

-- TODO: Add documentation
function Browser:generators()
    if not self._generators then
        self._generators = GeneratorsBrowser:new(self)
    end
    return self._generators
end

-- TODO: Add documentation
function Browser:saveLayout()
    local layout = {}
    if self:isShowing() then
        layout.showing = true
        layout.onPrimary = self:isOnPrimary()
        layout.onSecondary = self:isOnSecondary()

        layout.showLibraries = self:showLibraries():saveLayout()
        layout.showMedia = self:showMedia():saveLayout()
        layout.showGenerators = self:showGenerators():saveLayout()

        layout.libraries = self:libraries():saveLayout()
        layout.media = self:media():saveLayout()
        layout.generators = self:generators():saveLayout()
    end
    return layout
end

-- TODO: Add documentation
function Browser:loadLayout(layout)
    if layout and layout.showing then
        if layout.onPrimary then self:showOnPrimary() end
        if layout.onSecondary then self:showOnSecondary() end

        self:generators():loadLayout(layout.generators)
        self:media():loadLayout(layout.media)
        self:libraries():loadLayout(layout.libraries)

        self:showGenerators():loadLayout(layout.showGenerators)
        self:showMedia():loadLayout(layout.showMedia)
        self:showLibraries():loadLayout(layout.showLibraries)
    end
end

return Browser