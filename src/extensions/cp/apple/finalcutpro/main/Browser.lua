--- === cp.apple.finalcutpro.main.Browser ===
---
--- Browser Module.

local require = require

-- local log                             = require "hs.logger".new("browser")

--local inspect                         = require "hs.inspect"

local axutils                           = require "cp.ui.axutils"
local Element                           = require "cp.ui.Element"
local CheckBox                          = require "cp.ui.CheckBox"
local GeneratorsBrowser                 = require "cp.apple.finalcutpro.main.GeneratorsBrowser"
local LibrariesBrowser                  = require "cp.apple.finalcutpro.main.LibrariesBrowser"
local MediaBrowser                      = require "cp.apple.finalcutpro.main.MediaBrowser"
local PrimaryWindow                     = require "cp.apple.finalcutpro.main.PrimaryWindow"
local prop                              = require "cp.prop"
local SecondaryWindow                   = require "cp.apple.finalcutpro.main.SecondaryWindow"
local BrowserMarkerPopover              = require "cp.apple.finalcutpro.main.BrowserMarkerPopover"

local Do                                = require "cp.rx.go.Do"
local If                                = require "cp.rx.go.If"


local Browser = Element:subclass "cp.apple.finalcutpro.main.Browser"

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
function Browser.static.matches(element)
    if Element.matches(element) then
        local checkBoxes = axutils.childrenWithRole(element, "AXCheckBox")
        return checkBoxes and #checkBoxes >= 3
    end
    return false
end

--- cp.apple.finalcutpro.main.Browser(app) -> Browser
--- Constructor
--- Creates a new `Browser` instance.
---
--- Parameters:
---  * app - The Final Cut Pro app instance.
---
--- Returns:
---  * The new `Browser`.
function Browser:initialize(app)
    local UI = prop(function()
        return axutils.cache(self, "_ui", function()
            return _findBrowser(app.secondaryWindow, app.primaryWindow)
        end,
        Browser.matches)
    end):monitor(app.toolbar.browserShowing)

    Element.initialize(self, app, UI)

    -- wire up the libraries/media/generators buttons up to listen for updates from the app
    app:notifier():watchFor("AXValueChanged", function(element)
        if element:attributeValue("AXRole") == "AXImage" then
            local parent = element:attributeValue("AXParent")
            local ui = self:UI()
            if parent ~= nil and parent == ui then -- it's from inside the Browser UI
                self:showLibraries().checked:update()
                self:showMedia().checked:update()
                self:showGenerators().checked:update()
            end
        end
    end)

end

function Browser:app()
    return self:parent()
end

--- cp.apple.finalcutpro.main.Browser.isOnSecondary <cp.prop: boolean; read-only>
--- Field
--- Is the Browser on the Secondary Window?
function Browser.lazy.prop:isOnSecondary()
    return self.UI:mutate(function(original)
        local ui = original()
        return ui and SecondaryWindow.matches(ui:window())
    end)
end

--- cp.apple.finalcutpro.main.Browser.isOnPrimary <cp.prop: boolean; read-only>
--- Field
--- Is the Browser on the Primary Window?
function Browser.lazy.prop:isOnPrimary()
    return self.UI:mutate(function(uiProp)
        local ui = uiProp()
        return ui and PrimaryWindow.matches(ui:window())
    end)
end

--- cp.apple.finalcutpro.main.Browser.librariesShowing <cp.prop: boolean; read-only>
--- Field
--- Is the 'Libraries' button active, and thus showing?
function Browser.lazy.prop:librariesShowing()
    return self:showLibraries().checked
end

--- cp.apple.finalcutpro.main.Browser.mediaShowing <cp.prop: boolean; read-only>
--- Field
--- Is the 'Media' button active, and thus showing?
function Browser.lazy.prop:mediaShowing()
    return self:showMedia().checked
end

--- cp.apple.finalcutpro.main.Browser.generatorsShowing <cp.prop: boolean; read-only>
--- Field
--- Is the 'Generators' button active, and thus showing?
function Browser.lazy.prop:generatorsShowing()
    return self:showGenerators().checked
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

--- cp.apple.finalcutpro.main.Browser:doShowOnPrimary() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will show the Browser on Primary Screen.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement` to execute.
function Browser.lazy.method:doShowOnPrimary()
    local menuBar = self:app():menu()

    return Do(
        If(self.isOnSecondary):Then(
            menuBar:doSelectMenu({"Window", "Show in Secondary Display", "Browser"})
        )
    ):Then(
        If(self.isShowing):IsNot(true):Then(
            menuBar:doSelectMenu({"Window", "Show in Workspace", "Browser"})
        ):Otherwise(true)
    )
    :Label("Browser:doShowOnPrimary")
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

--- cp.apple.finalcutpro.main.Browser:doShowOnSecondary() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will show the Browser on Secondary Screen.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement` to execute.
function Browser.lazy.method:doShowOnSecondary()
    local menuBar = self:app():menu()

    return Do(
        self:parent():doShow()
    ):Then(
        If(self.isOnSecondary):IsNot(true):Then(
            menuBar:doSelectMenu({"Window", "Show in Secondary Display", "Browser"})
        ):Otherwise(true)
    )
    :Label("Browser:doShowOnSecondary")
end

--- cp.apple.finalcutpro.main.Browser:doShow() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will ensure the Browser is showing.
--- If it's currently showing on the Secondary Screen it will stay there, otherwise
--- it will get shown on the Primary Screen.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement` to execute.
function Browser.lazy.method:doShow()
    return If(self.isShowing):IsNot(true):Then(
        self:doShowOnPrimary()
    )
    :Label("Browser:doShow")
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

--- cp.apple.finalcutpro.main.Browser:doHide() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will hide the Browser.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement` to execute.
function Browser.lazy.method:doHide()
    return If(self.isShowing):Then(
        self:app():menu():doSelectMenu({"Window", "Show in Workspace", "Browser"})
    ):Label("Browser:doHide")
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
function Browser.lazy.method:showLibraries()
    return CheckBox(self, function()
        local ui = self:UI()
        if ui and #ui > 3 then
            -- The library toggle is always the last element.
            return ui[#ui]
        end
        return nil
    end)
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
function Browser.lazy.method:showMedia()
    return CheckBox(self, function()
        local ui = self:UI()
        if ui and #ui > 3 then
            -- The media toggle is always the second-last element.
            return ui[#ui-1]
        end
        return nil
    end)
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
function Browser.lazy.method:showGenerators()
    return CheckBox(self, function()
        local ui = self:UI()
        if ui and #ui > 3 then
            -- The generators toggle is always the third-last element.
            return ui[#ui-2]
        end
        return nil
    end)
end

--- cp.apple.finalcutpro.main.Browser.libraries <cp.apple.finalcutpro.main.LibrariesBrowser>
--- Field
--- The [module](package.module.md) object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `LibrariesBrowser` object.
function Browser.lazy.value:libraries()
    return LibrariesBrowser(self)
end

--- cp.apple.finalcutpro.main.Browser.media <cp.apple.finalcutpro.main.MediaBrowser>
--- Field
--- The Media Browser object.
function Browser.lazy.value:media()
    return MediaBrowser(self)
end

--- cp.apple.finalcutpro.main.Browser.generators <cp.apple.finalcutpro.main.GeneratorsBrowser>
--- Field
--- Generators Browser object.
function Browser.lazy.value:generators()
    return GeneratorsBrowser(self)
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
function Browser.lazy.method:markerPopover()
    return BrowserMarkerPopover(self)
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
