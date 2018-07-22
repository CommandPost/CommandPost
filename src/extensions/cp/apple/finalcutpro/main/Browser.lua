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
local require = require
-- local log                             = require("hs.logger").new("browser")

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
local BrowserMarkerPopover              = require("cp.apple.finalcutpro.main.BrowserMarkerPopover")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Browser = {}


-- _findBrowser(...) -> window | nil
-- Function
-- Gets the Browser UI.
--
-- Parameters:
--  * ... - Table of windows.
--
-- Returns:
--  * An `axuielementObject` or `nil`
local function _findBrowser(...)
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

--- cp.apple.finalcutpro.main.Browser.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function Browser.matches(element)
    local checkBoxes = axutils.childrenWithRole(element, "AXCheckBox")
    return checkBoxes and #checkBoxes >= 3
end

--- cp.apple.finalcutpro.main.Browser.new(app) -> Browser
--- Constructor
--- Creates a new `Browser` instance.
---
--- Parameters:
---  * app - The Final Cut Pro app instance.
---
--- Returns:
---  * The new `Browser`.
function Browser.new(app)
    local o = prop.extend({_app = app}, Browser)

    local UI = prop(function(self)
        return axutils.cache(self, "_ui", function()
            return _findBrowser(app:secondaryWindow(), app:primaryWindow())
        end,
        Browser.matches)
    end):monitor(app:toolbar().browserShowing)

    prop.bind(o) {

        --- cp.apple.finalcutpro.main.Browser.UI <cp.prop: hs._asm.axuielement; read-only>
        --- Field
        --- The `axuielement` for the browser, or `nil` if not available.
        UI = UI,

        --- cp.apple.finalcutpro.main.Browser.isOnSecondary <cp.prop: boolean; read-only>
        --- Field
        --- Is the Browser on the Secondary Window?
        isOnSecondary = UI:mutate(function(original)
            local ui = original()
            return ui and SecondaryWindow.matches(ui:window())
        end),

        --- cp.apple.finalcutpro.main.Browser.isOnPrimary <cp.prop: boolean; read-only>
        --- Field
        --- Is the Browser on the Primary Window?
        isOnPrimary = UI:mutate(function(uiProp)
            local ui = uiProp()
            return ui and PrimaryWindow.matches(ui:window())
        end),

        --- cp.apple.finalcutpro.main.Browser.isShowing <cp.prop: boolean; read-only>
        --- Field
        --- Is the Browser showing somewhere?
        isShowing = UI:mutate(function(original)
            return original() ~= nil
        end),

        --- cp.apple.finalcutpro.main.Browser.librariesShowing <cp.prop: boolean; read-only>
        --- Field
        --- Is the 'Libraries' button active, and thus showing?
        librariesShowing = o:showLibraries().checked,

        --- cp.apple.finalcutpro.main.Browser.mediaShowing <cp.prop: boolean; read-only>
        --- Field
        --- Is the 'Media' button active, and thus showing?
        mediaShowing = o:showMedia().checked,

        --- cp.apple.finalcutpro.main.Browser.generatorsShowing <cp.prop: boolean; read-only>
        --- Field
        --- Is the 'Generators' button active, and thus showing?
        generatorsShowing = o:showGenerators().checked,
    }

    -- wire up the libraries/media/generators buttons up to listen for updates from the app
    app:notifier():watchFor("AXValueChanged", function(element)
        if element:attributeValue("AXRole") == "AXImage" then
            local parent = element:attributeValue("AXParent")
            local ui = o:UI()
            if parent ~= nil and parent == ui then -- it's from inside the Browser UI
                o:showLibraries().checked:update()
                o:showMedia().checked:update()
                o:showGenerators().checked:update()
            end
        end
    end)

    return o
end

--- cp.apple.finalcutpro.main.Browser:app() -> App
--- Method
--- Returns the app instance representing Final Cut Pro.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function Browser:app()
    return self._app
end

-----------------------------------------------------------------------
--
-- BROWSER UI:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Browser:showOnPrimary() -> Browser
--- Method
--- Show Browser on Primary Screen.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Browser` object.
function Browser:showOnPrimary()
    -- show the parent.
    local menuBar = self:app():menu()

    -- if the browser is on the secondary, we need to turn it off before enabling in primary
    if self:isOnSecondary() then
        menuBar:selectMenu({"Window", "Show in Secondary Display", "Browser"})
    end
    -- Then enable it in the primary
    if not self:isShowing() then
        menuBar:selectMenu({"Window", "Show in Workspace", "Browser"})
    end
    return self
end

--- cp.apple.finalcutpro.main.Browser:showOnSecondary() -> Browser
--- Method
--- Show Browser on Secondary Screen.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Browser` object.
function Browser:showOnSecondary()
    -- show the parent.
    local menuBar = self:app():menu()

    if not self:isOnSecondary() then
        menuBar:selectMenu({"Window", "Show in Secondary Display", "Browser"})
    end
    return self
end

--- cp.apple.finalcutpro.main.Browser:hide() -> Browser
--- Method
--- Hides the Browser.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Browser` object.
function Browser:hide()
    if self:isShowing() then
        -- Uncheck it from the workspace
        self:app():menu():selectMenu({"Window", "Show in Workspace", "Browser"})
    end
    return self
end

-----------------------------------------------------------------------
--
-- SECTIONS:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Browser:showLibraries() -> CheckBox
--- Method
--- Shows Libraries.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `CheckBox` object.
function Browser:showLibraries()
    if not self._showLibraries then
        self._showLibraries = CheckBox.new(self, function()
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

--- cp.apple.finalcutpro.main.Browser:showMedia() -> CheckBox
--- Method
--- Show Media.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `CheckBox` object.
function Browser:showMedia()
    if not self._showMedia then
        self._showMedia = CheckBox.new(self, function()
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

--- cp.apple.finalcutpro.main.Browser:showGenerators() -> CheckBox
--- Method
--- Show Media.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `CheckBox` object.
function Browser:showGenerators()
    if not self._showGenerators then
        self._showGenerators = CheckBox.new(self, function()
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

--- cp.apple.finalcutpro.main.Browser:libraries() -> LibrariesBrowser
--- Method
--- Get Libraries Browser object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `LibrariesBrowser` object.
function Browser:libraries()
    if not self._libraries then
        self._libraries = LibrariesBrowser.new(self)
    end
    return self._libraries
end

--- cp.apple.finalcutpro.main.Browser:media() -> MediaBrowser
--- Method
--- Get Media Browser object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `MediaBrowser` object.
function Browser:media()
    if not self._media then
        self._media = MediaBrowser.new(self)
    end
    return self._media
end

--- cp.apple.finalcutpro.main.Browser:generators() -> GeneratorsBrowser
--- Method
--- Get Generators Browser object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `GeneratorsBrowser` object.
function Browser:generators()
    if not self._generators then
        self._generators = GeneratorsBrowser.new(self)
    end
    return self._generators
end

--- cp.apple.finalcutpro.main.Browser:markerPopover() -> BrowserMarkerPopover
--- Method
--- Get Browser Marker Popover object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `BrowserMarkerPopover` object.
function Browser:markerPopover()
    if not self._browserMarkerPopover then
        self._browserMarkerPopover = BrowserMarkerPopover.new(self)
    end
    return self._browserMarkerPopover
end

--- cp.apple.finalcutpro.main.Browser:saveLayout() -> table
--- Method
--- Saves the current Browser layout to a table.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table containing the current Browser Layout.
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

--- cp.apple.finalcutpro.main.Browser:loadLayout(layout) -> none
--- Method
--- Loads a Browser layout.
---
--- Parameters:
---  * layout - A table containing the Browser layout settings - created using `cp.apple.finalcutpro.main.Browser:saveLayout()`.
---
--- Returns:
---  * None
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
