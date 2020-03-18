--- === cp.app ===
---
--- This class assists with working with macOS apps. It provides functions for
--- finding, checking the running status, version number, path, and many other
--- values related to an application. It also provides support for launching,
--- quitting, and other activities related to applications.
---
--- This extension differs from the `hs.application` extension in several ways:
---  * `cp.app` instances are long-lived. You request it once and it will stay up-to-date even if the app quits.
---  * It makes extensive use of `cp.prop`, so you can `watch` many most properties of the app and get live notifications when they change.

local require                   = require

local hs                        = hs

local log                       = require "hs.logger".new "app"

local application               = require "hs.application"
local applicationwatcher        = require "hs.application.watcher"
local ax                        = require "hs._asm.axuielement"
local fs                        = require "hs.fs"
local inspect                   = require "hs.inspect"
local task                      = require "hs.task"
local timer                     = require "hs.timer"

local go                        = require "cp.rx.go"
local just                      = require "cp.just"
local languageID                = require "cp.i18n.languageID"
local lazy                      = require "cp.lazy"
local localeID                  = require "cp.i18n.localeID"
local menu                      = require "cp.app.menu"
local prefs                     = require "cp.app.prefs"
local prop                      = require "cp.prop"
local tools                     = require "cp.tools"

local axutils                   = require "cp.ui.axutils"
local notifier                  = require "cp.ui.notifier"
local Dialog                    = require "cp.ui.Dialog"
local Window                    = require "cp.ui.Window"

local v                         = require "semver"
local class                     = require "middleclass"

local childMatching             = axutils.childMatching
local doAfter                   = timer.doAfter
local format                    = string.format
local Given                     = go.Given
local If                        = go.If
local insert                    = table.insert
local keyStroke                 = tools.keyStroke
local printf                    = hs.printf
local processInfo               = hs.processInfo
local tableFilter               = tools.tableFilter
local Throw                     = go.Throw
local WaitUntil                 = go.WaitUntil

local app = class("cp.app"):include(lazy)

-- COMMANDPOST_BUNDLE_ID -> string
-- Constant
-- CommandPost's Bundle ID string.
local COMMANDPOST_BUNDLE_ID = processInfo.bundleID

-- BASE_LOCALE -> string
-- Constant
-- Base Locale.
local BASE_LOCALE = "Base"

-- apps -> table
-- Variable
-- Keeps a log of all apps that have been created.
local apps = {}

--- cp.app.is(thing) -> boolean
--- Function
--- Checks if the provided `thing` is a `cp.app` instance.
---
--- Parameters:
---  * thing        - The thing to check.
---
--- Returns:
---  * `true` if it is a `cp.app` instance, otherwise `false`.
function app.static.is(thing)
    return type(thing) == "table" and thing.isInstanceOf ~= nil and thing:isInstanceOf(app)
end

--- cp.app.bundleIDs() -> table
--- Function
--- Returns a list of Bundle IDs which have been requested via [forBundleID](#forBundleID).
---
--- Parameters:
---  * None
---
--- Returns:
---  * A list of Bundle IDs.
function app.static.bundleIDs()
    local ids = {}
    for id,_ in pairs(apps) do
        insert(ids, id)
    end
    return ids
end

--- cp.app.apps() -> table
--- Function
--- Returns a list of all apps that have been requested via [forBundleID](#forBundleID), in no particular order.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A list of `cp.app` instances.
function app.static.apps()
    local result = {}
    for _,a in pairs(apps) do
        insert(result, a)
    end
    return result
end

local frontmostApp = nil

--- cp.app.frontmostApp <cp.prop: cp.app; read-only; live>
--- Variable
--- Returns the most recent 'registered' app that was active, other than CommandPost itself.
app.static.frontmostApp = prop(function() return frontmostApp end):label("frontmostApp")

-- notifyWatch(cpProp, notifications) -> cp.prop
-- Function
-- Utility function to help set up watchers. Adds a watch for the specified notifications
-- and then updates the property.
--
-- Parameters:
-- * cpProp         - The [cp.prop](cp.prop.md) to update
-- * notifications  - The list of notification types to update the prop on.
--
-- Returns:
-- * The same `cp.prop`.
local function notifyWatch(cpProp, notifications)
    cpProp:preWatch(function(self)
        self:notifier():watchFor(
            notifications,
            function() cpProp:update() end
        )
    end)
    return cpProp
end

--- cp.app.forBundleID(bundleID)
--- Constructor
--- Returns the `cp.app` for the specified Bundle ID. If the app has already been created,
--- the same instance of `cp.app` will be returned on subsequent calls.
---
--- The Bundle ID
---
--- Parameters:
---  * bundleID      - The application bundle ID to find the app for.
---
--- Returns:
---  * The `cp.app` for the bundle.
function app.static.forBundleID(bundleID)
    assert(type(bundleID) == "string", "`bundleID` must be a string")
    local theApp = apps[bundleID]
    if not theApp then
        theApp = app:new(bundleID)
        apps[bundleID] = theApp
    end

    return theApp
end

--------------------------------------------------------------
-- cp.app instance configuration
--------------------------------------------------------------

-- cp.app:initialize(bundleID) -> cp.app
-- Constructor
-- Initializes new `cp.app` instances. This should not be called directly.
-- Rather, get them via the [forBundleID](#forBundleID) function.
--
-- Parameters:
-- * bundleID       - The BundleID for the app
--
-- Returns:
-- * The new `cp.app`.
function app:initialize(bundleID)
    self._bundleID = bundleID
    self._windowClasses = {}
    self._windowCache = {}

    self:registerWindowType(Window)
    self:registerWindowType(Dialog)

    app._initWatchers()
end

--- cp.app:bundleID() -> string
--- Method
--- Returns the Bundle ID for the app.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Bundle ID.
function app:bundleID()
    return self._bundleID
end

--- cp.app:keyStroke(modifiers, character) -> none
--- Method
--- Generates and emits a single keystroke event pair for the supplied keyboard
--- modifiers and character to the application.
---
--- Parameters:
---  * modifiers - A table containing the keyboard modifiers to apply ("fn", "ctrl", "alt", "cmd" or "shift")
---  * character - A string containing a character to be emitted
---
--- Returns:
---  * None
function app:keyStroke(modifiers, character)
    keyStroke(modifiers, character, self._hsApplication)
end

--- cp.app.preferences <cp.app.prefs>
--- Field
--- The current [preferences](cp.app.prefs.md) for the application.
function app.lazy.value:preferences()
    return prefs(self:bundleID())
end

--- cp.app.hsApplication <cp.prop: hs.application; read-only; live>
--- Field
--- Returns the running `hs.application` for the application, or `nil` if it's not running.
function app.lazy.prop:hsApplication()
    return notifyWatch(
        prop(function()
            local hsApp = self._hsApplication
            if not hsApp or hsApp:bundleID() == nil or not hsApp:isRunning() then
                local result = application.applicationsForBundleID(self._bundleID)
                if result and #result > 0 then
                    hsApp = result[1] -- If there is at least one copy running, return the first one
                else
                    hsApp = nil
                end
                self._hsApplication = hsApp
            end
            return hsApp
        end),
        {"AXApplicationActivated", "AXApplicationDeactivated"}
    )
end

--- cp.app.pid <cp.prop: number; read-only; live>
--- Field
--- Returns the PID for the currently-running application, or `nil` if it's not running.
function app.lazy.prop:pid()
    return self.hsApplication:mutate(function(original)
        local hsApp = original()
        return hsApp and hsApp:pid()
    end)
end

--- cp.app.running <cp.prop: boolean; read-only; live>
--- Field
--- Checks if the application currently is running.
function app.lazy.prop:running()
    return self.hsApplication:mutate(function(original)
        local hsApp = original()
        return hsApp ~= nil and hsApp:bundleID() ~= nil and hsApp:isRunning()
    end)
end

--- cp.app.UI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- Returns the application's `axuielement`, if available.
function app.lazy.prop:UI()
    return self.pid:mutate(function(original)
        return axutils.cache(self, "_ui", function()
            local thePid = original()
            return thePid and ax.applicationElementForPID(thePid)
        end)
    end)
end

--- cp.app.showing <cp.prop: boolean; read-only; live>
--- Field
--- Is the app visible on screen?
function app.lazy.prop:showing()
    return notifyWatch(
        self.UI:mutate(function(original)
            local ui = original()
            return ui ~= nil and not ui:attributeValue("AXHidden")
        end),
        {"AXApplicationHidden", "AXApplicationShown"}
    )
end

--- cp.app.frontmost <cp.prop: boolean; read-only; live>
--- Field
--- Is the application currently frontmost?
function app.lazy.prop:frontmost()
    return notifyWatch(
        self.UI:mutate(function(original)
            local ui = original()
            return ui ~= nil and ui:attributeValue("AXFrontmost")
        end),
        {"AXApplicationActivated", "AXApplicationDeactivated"}
    )
end

--- cp.app:registerWindowType(windowClass[, options]) -> cp.app
--- Method
--- Registers the specified class as one which will be used when accessing a specific `AXWindow` instance.
---
--- By default, it will use the `matches` function on the class itself to check. An alternate function can be
--- provided by putting it in the `{matches = <function>}` property of the `options` table.
---
--- By default, Windows instances are assumed to be short-lived, and will not persist beyond the window opening or closing.
--- To indicate that it should stick around, add `persistent = true` to the `options` table.
---
--- If the new `AXWindow` matches, this class will be used when requesting the set of windows via
--- the [#windows] method or the [#focusedWindow] or [#mainWindow] props.
---
--- Classes registered later will supersede those registered earlier, so ensure that matchers are specific enough to
--- not recognise more window UIs than they should.
---
--- Parameters:
--- * windowClass       - The class that will be used to create the window. It should be a subclass of [Window](cp.ui.Window.md)
--- * options           - (optional) if provided, it will be passed the `hs.asm.axuielement` being wrapped, and should return `true` or `false`.
---
--- Returns:
--- * the same instance of the `cp.app` for further configuration.
---
--- Notes:
--- * Options:
---     * `matches`: a `function` that will receive the AXWindow instance and should return `true` or `false`.
---     * `persistent`: if set to `true`, the Window instance will be cached and checked when windows appear and disappear.
function app:registerWindowType(windowClass, options)
    local matchesFn = options and  options.matches or windowClass.matches
    if type(matchesFn) ~= "function" then
        error("Unable to find a `matches` function from either the `matchesFn` parameter or the class `matches` static function.")
    end

    insert(self._windowClasses, {class = windowClass, matches = matchesFn, persistent = options and options.persistent or nil})
    -- reset the cache.
    self._windowCache = {}

    return self
end

-- cp.app:_createWindow(windowUI)
-- Function
-- Creates a new Window instance for the provided `windowUI`.
function app:_createWindow(windowUI)
    local windowClasses = self._windowClasses
    local count = #windowClasses
    for i = count,1,-1 do
        local factory = windowClasses[i]
        if factory.matches(windowUI) then
            local uiFinder
            if factory.persistent then
                uiFinder = prop(function()
                    return childMatching(self:windowsUI(), factory.matches)
                end)
            else
                uiFinder = prop.THIS(windowUI)
            end
            return factory.class(self, uiFinder), factory.persistent
        end
    end
    return nil
end

-- cp.app:_findWindow(windowUI) -> cp.ui.Window
-- Method
-- Finds the matching [Window](cp.ui.Window.md) for the `hs._asm.axuielement`.
-- If it is cached, return the cached instance, otherwise, create a new one.
function app:_findWindow(windowUI)
    -- first, check the cache
    local window

    -- both filters out old windows from the cache and checks for an existing window.
    tableFilter(self._windowCache, function(t, i)
        local item = t[i]
        local w = item.window
        local ui = w:UI()
        if ui == windowUI then
            window = w
        end
        return item.persistent or ui ~= nil
    end)

    if window then
        return window
    end

    local persistent
    -- otherwise, create a new window if appropriate
    window, persistent = self:_createWindow(windowUI)
    if window then
        insert(self._windowCache, {
            window = window,
            persistent = persistent
        })
    end

    return window
end

--- cp.app.windows <cp.prop: table of cp.ui.Window; read-only; live>
--- Field
--- Returns a list containing the [Window](cp.ui.Window.md) instances currently available.
function app.lazy.prop:windows()
    return self.windowsUI:mutate(function(original)
        local uis = original()
        local windows = {}
        for _,ui in ipairs(uis) do
            insert(windows, self:_findWindow(ui))
        end
        return windows
    end)
end

--- cp.app.windowsUI <cp.prop: table of hs._asm.axuielement; read-only; live>
--- Field
--- Returns the UI containing the list of windows in the app.
function app.lazy.prop:windowsUI()
    return notifyWatch(
        self.UI:mutate(function(original)
            local ui = original()
            local windows = ui and ui:attributeValue("AXWindows")
            if windows ~= nil and #windows == 0 then
                local mainWindow = ui:attributeValue("AXMainWindow")
                if mainWindow then
                    insert(windows, mainWindow)
                end
            end
            return windows
        end),
        {"AXWindowCreated", "AXDrawerCreated", "AXSheetCreated", "AXUIElementDestroyed"}
    )
end

--- cp.app.focusedWindow <cp.prop: cp.ui.Window; read-only; live>
--- Field
--- The currently-focused [Window](cp.ui.Window.md). This may be a subclass of `Window` if
--- additional types of `Window` have been registered via [#registerWindowType].
function app.lazy.prop:focusedWindow()
    return self.focusedWindowUI:mutate(function(original)
        return self:_findWindow(original())
    end)
end

--- cp.app.focusedWindowUI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- Returns the UI containing the currently-focused window for the app.
function app.lazy.prop:focusedWindowUI()
    return notifyWatch(
        axutils.prop(self.UI, "AXFocusedWindow"),
        {"AXFocusedWindowChanged"}
    )
end

--- cp.prop.mainWindow <cp.prop: cp.ui.Window; read-only; live>
--- Field
--- The main [Window](cp.ui.Window.md), or `nil` if none is available.
function app.lazy.prop:mainWindow()
    return self.mainWindowUI:mutate(function(original)
        return self:_findWindow(original())
    end)
end

--- cp.app.mainWindowUI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- Returns the UI containing the currently-focused window for the app.
function app.lazy.prop:mainWindowUI()
    return notifyWatch(
        axutils.prop(self.UI, "AXMainWindow"),
        {"AXMainWindowChanged"}
    )
end

--- cp.app.modalDialogOpen <cp.prop: boolean; read-only>
--- Field
--- Checks if a modal dialog window is currently opon.
function app.lazy.prop:modalDialogOpen()
    return self.focusedWindowUI:mutate(function(original)
        local window = original()
        if window then
            return window:attributeValue("AXModal") == true or window:attributeValue("AXRole") == "AXSheet"
        end
        return false
    end)
end

--- cp.app.path <cp.prop: string; read-only; live>
--- Field
--- Path to the application, or `nil` if not found.
function app.lazy.prop:path()
    return self.hsApplication:mutate(function(original)
        local hsApp = original()
        if hsApp and hsApp:isRunning() then
            ----------------------------------------------------------------------------------------
            -- The app is running
            ----------------------------------------------------------------------------------------
            local appPath = hsApp:path()
            if appPath then
                return appPath
            else
                log.ef("Failed to get running application path: %s", self)
            end
        else
            ----------------------------------------------------------------------------------------
            -- The app is closed.
            ----------------------------------------------------------------------------------------
            local result = application.pathForBundleID(self:bundleID())
            if result then
                return result
            end
        end
        return nil
    end)
end

--- cp.app.info <cp.prop: table; read-only; live>
--- Field
--- The info table for the application, if available.
--- If multiple versions of the app are installed, it will return the details for the running app as first priority,
--- and then it could be any installed version after that.
function app.lazy.prop:info()
    return self.hsApplication:mutate(function(original)
        ----------------------------------------------------------------------------------------
        -- Check if the app is running already...
        ----------------------------------------------------------------------------------------
        local hsApp = original()
        if hsApp and hsApp:isRunning() then
            local appPath = hsApp:path()
            if appPath then
                return application.infoForBundlePath(appPath)
            else
                log.ef("Found app, but could not determine its path: %s", self:bundleID())
            end
        end

        ----------------------------------------------------------------------------------------
        -- If not, grab it from the default location.
        ----------------------------------------------------------------------------------------
        return application.infoForBundleID(self:bundleID())
    end)
end

--- cp.app.versionString <cp.prop: string; read-only; live>
--- Field
--- The application version as a `string`.
---
--- Notes:
---  * If the application is running it will get the version of the active application as a string, otherwise, it will use `hs.application.infoForBundleID()` to find the version.
function app.lazy.prop:versionString()
    return self.info:mutate(function(original)
        local theInfo = original()
        return theInfo and theInfo["CFBundleShortVersionString"]
    end)
end

--- cp.app.version <cp.prop: semver; read-only; live>
--- Field
--- The application version as a [semver](https://github.com/kikito/semver.lua).
---
--- Notes:
---  * If the application is running it will get the version of the active application as a string, otherwise, it will use `hs.application.infoForBundleID()` to find the version.
function app.lazy.prop:version()
    return self.versionString:mutate(function(original)
        local vs = original()
        return vs ~= nil and v(vs) or nil
    end)
end

--- cp.app.displayName <cp.prop: string; read-only; live>
--- Field
--- The application display name as a string.
function app.lazy.prop:displayName()
    return self.info:mutate(function(original)
        local theInfo = original()
        return theInfo and (theInfo["CFBundleDisplayName"] or theInfo["CFBundleName"])
    end)
end

--- cp.app.installed <cp.prop: boolean; read-only>
--- Field
--- Checks if the application currently installed.
function app.lazy.prop:installed()
    return self.info:mutate(function(original) return original() ~= nil end)
end

--- cp.app.baseLocale <cp.prop: cp.i18n.localeID; read-only>
--- Field
--- Returns the [localeID](cp.i18n.localeID.md) of the development region. This is the 'Base' locale for I18N.
function app.lazy.prop:baseLocale()
    return self.info:mutate(function(original)
        local theInfo = original()
        local devRegion = theInfo and theInfo.CFBundleDevelopmentRegion or nil
        return devRegion and localeID.forCode(devRegion)
    end)
end

--- cp.app.supportedLocales <cp.prop: table of cp.i18n.localeID; read-only; live>
--- Field
--- Returns a list of `cp.i18n.localeID` values for locales that are supported by this app.
function app.lazy.prop:supportedLocales()
    return self.path:mutate(function(original)
        local locales = {}
        local appPath = original()
        if appPath then
            local resourcesPath = fs.pathToAbsolute(appPath .. "/Contents/Resources")
            if resourcesPath then
                local theBaseLocale = self:baseLocale()
                if theBaseLocale then
                    -- always add the base locale, if present.
                    insert(locales, theBaseLocale)
                end

                local iterFn, dirObj = fs.dir(resourcesPath)
                if not iterFn then
                    log.ef("An error occured in cp.app.forBundleID: %s", dirObj)
                else
                    for file in iterFn, dirObj do
                        local localeCode = file:match("(.+)%.lproj")
                        if localeCode then
                            if localeCode ~= BASE_LOCALE then
                                local locale = localeID.forCode(localeCode)
                                if locale and locale ~= theBaseLocale then
                                    insert(locales, locale)
                                end
                            end
                        end
                    end
                end
            end
        end
        table.sort(locales)
        return locales
    end)
end

--- cp.app.currentLocale <cp.prop: cp.i18n.localeID; live>
--- Field
--- Gets and sets the current locale for the application.
function app.lazy.prop:currentLocale()
    return prop(
        function()
            --------------------------------------------------------------------------------
            -- If the app is not running, we next try to determine the language using
            -- the 'AppleLanguages' preference:
            --------------------------------------------------------------------------------
            local appLanguages = self.preferences.AppleLanguages
            if appLanguages then
                for _,lang in ipairs(appLanguages) do
                    if self:isSupportedLocale(lang) then
                        local currentLocale = localeID.forCode(lang)
                        local bestLocale = currentLocale and self:bestSupportedLocale(currentLocale)
                        if bestLocale then
                            return bestLocale
                        end
                    end
                end
            end

            --------------------------------------------------------------------------------
            -- If that also fails, we try and use NSGlobalDomain AppleLanguages:
            --------------------------------------------------------------------------------
            local output, status = hs.execute("defaults read NSGlobalDomain AppleLanguages")
            if status then
                local appleLanguages = tools.lines(output)
                if next(appleLanguages) ~= nil then
                    if appleLanguages[1] == "(" and appleLanguages[#appleLanguages] == ")" then
                        for i=2, #appleLanguages - 1 do
                            local line = appleLanguages[i]
                            -- match the main country code
                            local lang = line:match("^%s*\"?([%w%-]+)")
                            local theLanguage = languageID.forCode(lang)
                            if theLanguage then
                                local theLocale = theLanguage:toLocaleID()
                                local bestLocale = self:bestSupportedLocale(theLocale)
                                if bestLocale then
                                    return bestLocale
                                end
                            end
                        end
                    end
                end
            end

            --------------------------------------------------------------------------------
            -- If that also fails, we use the base locale, or failing that, English:
            --------------------------------------------------------------------------------
            local locale = self:baseLocale() or localeID.forCode("en")
            return locale
        end,
        function(value, _, theProp)
            value = localeID(value)
            if not localeID.is(value) then
                error(format("The provided value is not a cp.i18n.localeID: %s", inspect(value)))
            end

            -- if the new value matches the current value, don't do anything.
            if value == theProp:get() then return end

            local thePrefs = self.preferences
            if value == nil then
                if thePrefs.AppleLanguages == nil then return end
                thePrefs.AppleLanguages = nil
            else
                local bestLocale = self:bestSupportedLocale(value)
                if bestLocale then
                    thePrefs.AppleLanguages = {bestLocale.code}
                else
                    error("Unsupported language: "..value.code)
                end
            end
            if self:running() then
                self:doRestart():Now()
            end
        end
    ):monitor(self.running)
end

--- cp.app.resourcesPath <cp.prop: string; read-only; live>
--- Field
--- A [prop](cp.prop.md) for the file path to the `Contents/Resources` folder inside the app.
function app.lazy.prop:resourcesPath()
    return self.path:mutate(function(original)
        local path = original()
        return path and fs.pathToAbsolute(path .. "/Contents/Resources") or nil
    end)
end

--- cp.app.baseResourcesPath <cp.prop: string; read-only; live>
--- Field
--- A [prop](cp.prop.md) for the file path to the `Content/Resources/Base.lproj` folder
--- for the application, or `nil` if not present.
function app.lazy.prop:baseResourcesPath()
    return self.resourcesPath:mutate(function(original)
        local path = original()
        return path and fs.pathToAbsolute(path .. "/Base.lproj") or nil
    end)
end

--- cp.app.localeResourcesPath <cp.prop: string; read-only; live>
--- Field
--- A [prop](cp.prop.md) for the file path to the locale-specific resources
--- for the current locale. If no resources for the locale are available, `nil` is returned.
function app.lazy.prop:localeResourcesPath()
    return self.resourcesPath:mutate(function(original)
        local resourcesPath = original()
        if resourcesPath then
            local locale = self:bestSupportedLocale(self:currentLocale())
            for _, alias in pairs(locale.aliases) do
                local path = fs.pathToAbsolute(resourcesPath .. "/" .. alias .. ".lproj")
                if path then
                    return path
                end
            end
        end
    end)
    :monitor(self.currentLocale)
end

--- cp.app.menu <cp.app.menu>
--- Field
--- The main [menu](cp.app.menu.md) for the application.
function app.lazy.value:menu()
    return menu(self)
end

--- cp.app:launch([waitSeconds], [path]) -> self
--- Method
--- Launches the application, or brings it to the front if it was already running.
---
--- Parameters:
---  * `waitSeconds` - If provided, the number of seconds to wait until the launch
---                    completes. If `nil`, it will return immediately.
---  * `path`        - An optional full path to an application without an extension
---                    (i.e `/Applications/Final Cut Pro 10.3.4`). This allows you to
---                    load previous versions of the application.
---
--- Returns:
---  * The `cp.app` instance.
function app:launch(waitSeconds, path)
    local hsApp = self:hsApplication()
    if hsApp == nil or not hsApp:isFrontmost() then
        -- Closed:
        if path then
            path = path .. ".app"
            if tools.doesDirectoryExist(path) then
                local ok = application.open(path)
                if ok and waitSeconds then
                    just.doUntil(function() return self:running() end, waitSeconds, 0.1)
                end
            else
                log.ef("Application path does not exist: %s", path)
            end
        else
            local ok = application.launchOrFocusByBundleID(self:bundleID())
            if ok and waitSeconds then
                just.doUntil(function() return self:running() end, waitSeconds, 0.1)
            end
        end
    end
    return self
end

--- cp.app:doLaunch([waitSeconds[, path]]) -> cp.rx.Statement <boolean>
--- Method
--- Returns a `Statement` that can be run to launch or focus the current app.
--- It will resolve to `true` when the app was launched.
---
--- Parameters:
---  * waitSeconds - (optional) The number of seconds to wait for it to load. Defaults to 30 seconds.
---  * path - (optional) The alternate path of the app to launch.
---
--- Returns:
---  * The `Statement`, resolving to `true` after the app is frontmost.
---
--- Notes:
---  * By default the `Statement` will time out after 30 seconds, sending an error signal.
function app:doLaunch(waitSeconds, path)
    waitSeconds = waitSeconds or 30
    return If(self.installed):Then(
        If(self.frontmost):Is(false):Then(
            If(path ~= nil):Then(function()
                path = path .. ".app"
                if tools.doesDirectoryExist(path) then
                    local ok, msg = application.open(path)
                    if not ok then
                        log.ef("Unable to open application at %q: msg", path, msg or "")
                    end
                else
                    log.ef("Application path does not exist: %s", path)
                end
            end)
            :Otherwise(
                If(self.hsApplication):Then(function(hsApp)
                    hsApp:activate()
                    return true
                end)
                :Otherwise(function()
                    local ok = application.launchOrFocusByBundleID(self:bundleID())
                    if not ok then
                        return Throw("Unable to launch %s.", self:displayName())
                    end
                    return true
                end)
            )
        )
        :Then(WaitUntil(self.frontmost))
        :Otherwise(true)
    )
    :Otherwise(
        Throw("No app with a bundle ID of '%s' is installed.", self:bundleID())
    )
    :TimeoutAfter(waitSeconds * 1000, format("Unable to complete launching %s within %d seconds", self:displayName(), waitSeconds))
    :Label(self:bundleID()..":doLaunch")
end

--- cp.app:quit(waitSeconds) -> self
--- Method
--- Asks the application to quit, if it's running. The app may not have actually quit after this
--- function runs, even if `true` is returned. The application may take some time, or may be prompting
--- the user for input, etc.
---
--- Parameters:
---  * `waitSeconds`    - If povided, the number of seconds to wait until the quit completes. If `nil`, it will return immediately.
---
--- Returns:
---  * The `cp.app` instance.
function app:quit(waitSeconds)
    local hsApp = self:hsApplication()
    if hsApp then
        hsApp:kill()
        if waitSeconds then
            just.doWhile(function() return self:running() end, waitSeconds, 0.1)
        end
    end
    return self
end

--- cp.app:doQuit() -> cp.rx.go.Statement <boolean>
--- Method
--- Returns a `Statement` that will attempt to quit the app when executed.
---
--- Parameters:
---  * None.
---
--- Returns:
---  * The `Statement`, resolving to `true` if the app was running and was quit successfully, otherwise `false`.
---
--- Notes:
---  * The Statement will time out after 60 seconds by default. This can be changed by calling the `TimeoutAfter` method on the Statement before executing.
function app.lazy.method:doQuit()
    return If(self.hsApplication):Then(function(hsApp)
        hsApp:kill()
    end)
    :Then(WaitUntil(self.running):Is(false))
    :Otherwise(false)
    :TimeoutAfter(60 * 1000, format("%s did not quit successfully after 60 seconds.", self:displayName()))
    :Label(self:bundleID()..":doQuit")
end


--- cp.app:doRestart() -> cp.rx.go.Statement <boolean>
--- Method
--- Returns a `Statement` which will attempt to restart the app. If the app
--- was not running at the time, no action is taken and `false` is returned. If it was
--- running then the app will be attempted to quit then restarted.
---
--- If you have multiple versions of the same app on your system, this will
--- restart with the same version that was running when the restart was requested.
---
--- Parameters:
---  * None.
---
--- Returns:
---  * The `Statement`, resolving to `true` if the app was running and was quit and restarted successfully, otherwise `false`.
---
--- Notes:
---  * The Statement will time out after 60 seconds by default. This can be changed by calling the `TimeoutAfter` method on the Statement before executing.
function app.lazy.method:doRestart()
    return If(self.hsApplication):Then(function(hsApp)
        local appPath = hsApp:path()

        return Given(
            self:doQuit()
        )
        :Then(function()
            -- force the application prop to update, otherwise it isn't closed long enough to prompt an event.
            self.hsApplication:update()

            local output, ok = hs.execute(format('open "%s"', appPath))
            if not ok then
                return Throw("%s was unable to restart: %s", self:displayName(), output)
            end

            return WaitUntil(self.frontmost)
        end)
    end)
    :Otherwise(false)
    :TimeoutAfter(60 * 1000, format("%s did not restart successfully after 60 seconds", self:displayName()))
    :Label(self:bundleID()..":doRestart")
end

--- cp.app:show() -> self
--- Method
--- Ensure the app is onscreen if it is currently running.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.app` instance.
function app:show()
    local hsApp = self:hsApplication()
    if hsApp then
        if hsApp:isHidden() then
            hsApp:unhide()
        end
        if hsApp:isRunning() then
            hsApp:activate()
        end
    end
    return self
end

--- cp.app:doShow() -> cp.rx.go.Statement <boolean>
--- Method
--- Returns a `Statement` which will show the app if it's currently running.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `Statement`, resolving to `true` if the app is running and was successfully shown, or `false` otherwise.
function app.lazy.method:doShow()
    return If(self.hsApplication):Then(function(hsApp)
        if hsApp:isHidden() then
            hsApp:unhide()
        end
        if hsApp:isRunning() then
            hsApp:activate()
        end
        return WaitUntil(self.frontmost)
    end)
    :Otherwise(false)
    :Label(self:bundleID()..":doShow")
end

--- cp.app:hide() -> self
--- Method
--- Hides the application, if it's currently running.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.app` instance.
function app:hide()
    local hsApp = self:hsApplication()
    if hsApp then
        hsApp:hide()
    end
    return self
end

--- cp.app:doHide() -> cp.rx.go.Statement <boolean>
--- Method
--- Returns a `Statement` which will hide the app if it's currently running.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `Statement`, resolving to `true` if the app is running and was successfully hidden, or `false` otherwise.
function app.lazy.method:doHide()
    return If(self.hsApplication):Then(function(hsApp)
        hsApp:hide()
    end)
    :Then(WaitUntil(self.frontmost):Is(false))
    :Otherwise(false)
    :Label(self:bundleID()..":doHide")
end

--- cp.app:notifier() -> cp.ui.notifier
--- Method
--- Returns a `notifier` that is tracking the application UI element. It has already been started.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The notifier.
function app.lazy.method:notifier()
    return notifier.new(self:bundleID(), function() return self:UI() end):start()
end

--- cp.app.description -> string
--- Field
--- Returns the short description of the class as "cp.app: <bundleID>"
function app.lazy.value:description()
    return format("%s: %s (%s)", self.class.name, self:displayName(), self:bundleID())
end

function app:__tostring()
    return self.description
end

-- cp.app._findApp(bundleID, appName) -> cp.app
-- Function
-- Attempts to find the registered app, first by Bundle ID, then by the app name if provided.
-- It will not create a new `cp.app` instance for the Bundle ID if it does not exist.
--
-- Parameters:
--  * bundleID       - The app Bundle ID
--  * appName        - The app display name
--
-- Returns:
--  * The `cp.app` matching the details, or `nil` if not found.
function app.static._findApp(bundleID, appName)
    local cpApp = apps[bundleID]
    if cpApp == nil and bundleID == nil and appName ~= nil then
        -- look harder...
        for _,a in pairs(apps) do
            if a:displayName() == appName then
                return a
            end
        end
    end
    return cpApp
end

--- cp.app:isSupportedLocale(locale) -> boolean
--- Method
--- Checks if the specified locale is supported. The `locale` can
--- be either a string with the locale code (eg. "en_AU") or a
--- `cp.i18n.localeID`.
---
--- Parameters:
---  * locale    - The locale code string or `localeID` to check.
---
--- Returns:
---  * `true` if it is supported, otherwise `false`.
function app:isSupportedLocale(locale)
    locale = localeID(locale)

    if localeID.is(locale) then
        for _,sl in ipairs(self:supportedLocales()) do
            if sl:matches(locale) > 0 then
                return true
            end
        end
    end
    return false
end

--- cp.app:bestSupportedLocale(locale) -> cp.i18n.localeID or nil
--- Method
--- Finds the closest match for the specified locale. The returned locale
--- will be in the same language as the provided locale, and as close a match as possible with the region and script.
---
--- Parameters:
---  * locale    - The local to match
---
--- Returns:
---  * The closest supported locale or `nil` if none are available in the language.
function app:bestSupportedLocale(locale)
    -- cast to localeID
    locale = localeID(locale)

    if locale then
        local currentLocale = nil
        local currentScore = 0
        for _,sl in ipairs(self:supportedLocales()) do
            local score = sl:matches(locale)
            if score > currentScore then
                currentLocale = sl
                currentScore = score
            end
        end
        return currentLocale
    end
    return nil
end

--- cp.app:update() -> self
--- Method
--- Updates the app, triggering any watchers if values have changed.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.app` instance.
function app:update()
    self.hsApplication:update()
    return self
end

-- TODO: Add documentation
local whiches = {}
local function which(cmd)
    local path = whiches[cmd]
    if not path then
        local output, ok = hs.execute(string.format("which %q", cmd))
        if ok then
            path = output:match("([^\r\n]*)")
            whiches[cmd] = path
        else
            return nil, output
        end
    end
    return path
end

--- cp.app:searchResources(value) -> hs.task
--- Method
--- Creates a `hs.task` which will search for the specified string value in the resources
--- of the current app.
---
--- Parameters:
---  * value     - The string value to search for.
---
--- Returns:
---  * `hs.task` which is already running, searching for the `value`. Results will be output in the Error Log.
---
--- Notes:
---  * This may take some time to complete, depending on how many resources the app contains.
function app:searchResources(value)
    local grep = which("grep")
    if grep and value then
        value = tostring(value)
        local finder = task.new(grep,
            function(status, stdOut, stdErr)
                printf("%s: Completed search for resources containing %q.", self:displayName(), value)
                if stdOut then
                    print(stdOut)
                end
                if status ~= 0 then
                    printf("%s: ERROR #%d: %s", self:displayName(), status, stdErr)
                end
            end,
            function(_, stdOut, strErr)
                printf("%s: Found resources containing %q:\n%s", self:displayName(), value, stdOut)
                if strErr and #strErr > 0 then
                    printf("%s: ERROR:\n%s", self:displayName(), strErr)
                end
                return true
            end,
            { "-r", value, self:path() }
        )
        printf("%s: Searching resources for %q...", self:displayName(), value)
        finder:start()
        return finder
    end
    return nil
end

----------------------------------------------------------------------------
-- API Config
----------------------------------------------------------------------------

-- Watchers to keep the contents up-to-date.
local function updateFrontmostApp(cpApp)
    if cpApp then
        if cpApp:bundleID() ~= COMMANDPOST_BUNDLE_ID then
            frontmostApp = cpApp
        end
    else
        frontmostApp = nil
    end
    app.frontmostApp:update()
end

-- cp.app._initWatchers() -> none
-- Method
-- Initialise all the various application watchers.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function app.static._initWatchers()
    if app._appWatcher then
        return
    end

    --------------------------------------------------------------------------------
    -- Setup Application Watcher:
    --------------------------------------------------------------------------------
    app._appWatcher = applicationwatcher.new(
        function(appName, eventType, hsApp)
            local cpApp = app._findApp(hsApp:bundleID(), appName)

            if cpApp then
                if eventType == applicationwatcher.activated then
                    doAfter(0.01, function()
                        cpApp.showing:update()
                        cpApp.frontmost:update()
                        updateFrontmostApp(cpApp)
                    end)
                    return
                elseif eventType == applicationwatcher.deactivated then
                    doAfter(0.01, function()
                        cpApp.showing:update()
                        cpApp.frontmost:update()
                    end)
                    return
                elseif eventType == applicationwatcher.launched then
                    doAfter(0.01, function()
                        cpApp.hsApplication:update()
                        cpApp.running:update()
                        cpApp.frontmost:update()
                        updateFrontmostApp(cpApp)
                    end)
                    return
                elseif eventType == applicationwatcher.terminated then
                    doAfter(0.01, function()
                        cpApp.hsApplication:update()
                        cpApp.running:update()
                        cpApp.frontmost:update()
                        updateFrontmostApp(cpApp)
                    end)
                    return
                end
            elseif hsApp:bundleID() ~= COMMANDPOST_BUNDLE_ID then
                updateFrontmostApp(nil)
            end
        end
    ):start()
end

-- register CommandPost as an app
app.forBundleID(COMMANDPOST_BUNDLE_ID)

return app
