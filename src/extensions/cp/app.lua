--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local require                   = require
local log                       = require("hs.logger").new("app")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local application               = require("hs.application")
local applicationwatcher		= require("hs.application.watcher")
local ax                        = require("hs._asm.axuielement")
local fs                        = require("hs.fs")
local inspect                   = require("hs.inspect")
local task                      = require("hs.task")
local timer                     = require("hs.timer")

local printf                    = hs.printf

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils                   = require("cp.ui.axutils")
local just                      = require("cp.just")
local languageID                = require("cp.i18n.languageID")
local localeID                  = require("cp.i18n.localeID")
local menu                      = require("cp.app.menu")
local notifier					= require("cp.ui.notifier")
local prefs                     = require("cp.app.prefs")
local prop                      = require("cp.prop")
local tools                     = require("cp.tools")

local go                        = require("cp.rx.go")

local Given                     = go.Given
local WaitUntil, Throw, If      = go.WaitUntil, go.Throw, go.If

--------------------------------------------------------------------------------
-- 3rd Party Extensions:
--------------------------------------------------------------------------------
local v							= require("semver")

--------------------------------------------------------------------------------
-- Local Lua Functions:
--------------------------------------------------------------------------------
local insert                    = table.insert
local format                    = string.format

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- COMMANDPOST_BUNDLE_ID -> string
-- Constant
-- CommandPost's Bundle ID string.
local COMMANDPOST_BUNDLE_ID = hs.processInfo.bundleID

-- BASE_LOCALE -> string
-- Constant
-- Base Locale.
local BASE_LOCALE = "Base"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local app = {}
app.mt = {}

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
function app.is(thing)
    return type(thing) == "table" and thing == app.mt or app.is(getmetatable(thing))
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
function app.bundleIDs()
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
function app.apps()
    local result = {}
    for _,a in pairs(apps) do
        insert(result, a)
    end
    return result
end

local frontmostApp = nil

--- cp.app.frontmostApp <cp.prop: cp.app; read-only; live>
--- Field
--- Returns the most recent 'registered' app that was active, other than CommandPost itself.
app.frontmostApp = prop(function() return frontmostApp end):label("frontmostApp")

-- utility function to help set up watchers
local function notifyWatch(cpProp, notifications)
    cpProp:preWatch(function(self)
        self:notifier():watchFor(
            notifications,
            function() cpProp:update() end
        )
    end)
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
function app.forBundleID(bundleID)
    assert(type(bundleID) == "string", "`bundleID` must be a string")
    local theApp = apps[bundleID]
    if not theApp then
        theApp = prop.extend({
            _bundleID = bundleID,
            preferences = prefs.new(bundleID),
        }, app.mt)

        local hsApplication = prop(function(self)
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
        end)

        local pid = hsApplication:mutate(function(original)
            local hsApp = original()
            return hsApp and hsApp:pid()
        end)

        local running = hsApplication:mutate(function(original)
            local hsApp = original()
            return hsApp ~= nil and hsApp:bundleID() ~= nil and hsApp:isRunning()
        end)

        local UI = pid:mutate(function(original, self)
            return axutils.cache(self, "_ui", function()
                local thePid = original()
                return thePid and ax.applicationElementForPID(thePid)
            end)
        end)

        local showing = UI:mutate(function(original)
            local ui = original()
            return ui ~= nil and not ui:attributeValue("AXHidden")
        end)

        local frontmost = UI:mutate(function(original)
            local ui = original()
            return ui ~= nil and ui:attributeValue("AXFrontmost")
        end)

        local focusedWindowUI = UI:mutate(function(original)
            local ui = original()
            return ui and ui:attributeValue("AXFocusedWindow")
        end)

        local mainWindowUI = UI:mutate(function(original)
            local ui = original()
            return ui and ui:attributeValue("AXMainWindow")
        end)

        local modalDialogOpen = focusedWindowUI:mutate(function(original)
            local window = original()
            if window then
                return window:attributeValue("AXModal") == true or window:attributeValue("AXRole") == "AXSheet"
            end
            return false
        end)

        local path = hsApplication:mutate(function(original, self)
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

        local info = hsApplication:mutate(function(original, self)
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

        local versionString = info:mutate(function(original)
            local theInfo = original()
            return theInfo and theInfo["CFBundleShortVersionString"]
        end)

        local version = versionString:mutate(function(original)
            local vs = original()
            return vs ~= nil and v(vs) or nil
        end)

        local displayName = info:mutate(function(original)
            local theInfo = original()
            return theInfo and (theInfo["CFBundleDisplayName"] or theInfo["CFBundleName"])
        end)

        local installed = info:mutate(function(original) return original() ~= nil end)

        local windowsUI = UI:mutate(function(original)
            local ui = original()
            local windows = ui and ui:attributeValue("AXWindows")
            if windows ~= nil and #windows == 0 then
                local mainWindow = ui:attributeValue("AXMainWindow")
                if mainWindow then
                    insert(windows, mainWindow)
                end
            end
            return windows
        end)

        -- Localization/I18N
        local baseLocale = info:mutate(function(original)
            local theInfo = original()
            local devRegion = theInfo and theInfo.CFBundleDevelopmentRegion or nil
            return devRegion and localeID.forCode(devRegion)
        end)

        local supportedLocales = path:mutate(function(original)
            local locales = {}
            local appPath = original()
            if appPath then
                local resourcesPath = fs.pathToAbsolute(appPath .. "/Contents/Resources")
                if resourcesPath then
                    local theBaseLocale = baseLocale()
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

        local currentLocale = prop(
            function(self)
                --------------------------------------------------------------------------------
                -- If the app is not running, we next try to determine the language using
                -- the 'AppleLanguages' preference...
                --------------------------------------------------------------------------------
                local appLanguages = self.preferences.AppleLanguages
                if appLanguages then
                    for _,lang in ipairs(appLanguages) do
                        if self:isSupportedLocale(lang) then
                            local currentLocale = localeID.forCode(lang)
                            if currentLocale then
                                return currentLocale
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
            function(value, self, theProp)
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
                    self:doRestart():TimeoutAfter(20*1000):Now()
                end
            end
        ):monitor(running)


        prop.bind(theApp) {
            --- cp.app.hsApplication <cp.prop: hs.application; read-only; live>
            --- Field
            --- Returns the running `hs.application` for the application, or `nil` if it's not running.
            hsApplication = hsApplication,

            --- cp.app.pid <cp.prop: number; read-only; live>
            --- Field
            --- Returns the PID for the currently-running application, or `nil` if it's not running.
            pid = pid,

            --- cp.app.running <cp.prop: boolean; read-only; live>
            --- Field
            --- Checks if the application currently is running.
            running = running,

            --- cp.app.showing <cp.prop: boolean; read-only; live>
            --- Field
            --- Is the app visible on screen?
            showing = showing,

            --- cp.app.frontmost <cp.prop: boolean; read-only; live>
            --- Field
            --- Is the application currently frontmost?
            frontmost = frontmost,

            --- cp.app.modalDialogOpen <cp.prop: boolean; read-only>
            --- Field
            --- Checks if a modal dialog window is currently opon.
            modalDialogOpen = modalDialogOpen,

            --- cp.app.path <cp.prop: string; read-only; live>
            --- Field
            --- Path to the application, or `nil` if not found.
            path = path,

            --- cp.app.info <cp.prop: table; read-only; live>
            --- Field
            --- The info table for the application, if available.
            --- If multiple versions of the app are installed, it will return the details for the running app as first priority,
            --- and then it could be any installed version after that.
            info = info,

            --- cp.app.versionString <cp.prop: string; read-only; live>
            --- Field
            --- The application version as a `string`.
            ---
            --- Notes:
            ---  * If the application is running it will get the version of the active application as a string, otherwise, it will use `hs.application.infoForBundleID()` to find the version.
            versionString = versionString,

            --- cp.app.version <cp.prop: semver; read-only; live>
            --- Field
            --- The application version as a `semver`.
            ---
            --- Notes:
            ---  * If the application is running it will get the version of the active application as a string, otherwise, it will use `hs.application.infoForBundleID()` to find the version.
            version = version,

            --- cp.app.displayName <cp.prop: string; read-only; live>
            --- The application display name as a string.
            displayName = displayName,

            --- cp.app.installed <cp.prop: boolean; read-only>
            --- Field
            --- Checks if the application currently installed.
            installed = installed,

            --- cp.app.UI <cp.prop: hs._asm.axuielement; read-only; live>
            --- Field
            --- Returns the application's `axuielement`, if available.
            UI = UI,

            --- cp.app.windowsUI <cp.prop: hs._asm.axuielement; read-only; live>
            --- Field
            --- Returns the UI containing the list of windows in the app.
            windowsUI = windowsUI,

            --- cp.app.focusedWindowUI <cp.prop: hs._asm.axuielement; read-only; live>
            --- Field
            --- Returns the UI containing the currently-focused window for the app.
            focusedWindowUI = focusedWindowUI,

            --- cp.app.mainWindowUI <cp.prop: hs._asm.axuielement; read-only; live>
            --- Field
            --- Returns the UI containing the currently-focused window for the app.
            mainWindowUI = mainWindowUI,

            --- cp.app.baseLocale <cp.prop: cp.i18n.localeID; read-only>
            --- Field
            --- Returns the locale of the development region. This is the 'Base' locale for I18N.
            baseLocale = baseLocale,

            --- cp.app.supportedLocales <cp.prop: table of cp.i18n.localeID; read-only; live>
            --- Field
            --- Returns a list of `cp.i18n.localeID` values for locales that are supported by this app.
            supportedLocales = supportedLocales,

            --- cp.app.currentLocale <cp.prop: cp.i18n.localeID; live>
            --- Field
            --- Gets and sets the current locale for the application.
            currentLocale = currentLocale,
        }

        notifyWatch(hsApplication, {"AXApplicationActivated", "AXApplicationDeactivated"})
        notifyWatch(showing, {"AXApplicationHidden", "AXApplicationShown"})
        notifyWatch(frontmost, {"AXApplicationActivated", "AXApplicationDeactivated"})
        notifyWatch(focusedWindowUI, {"AXFocusedWindowChanged"})
        notifyWatch(mainWindowUI, {"AXMainWindowChanged"})
        notifyWatch(windowsUI, {"AXWindowCreated", "AXDrawerCreated", "AXSheetCreated", "AXUIElementDestroyed"})

        apps[bundleID] = theApp

        app._initWatchers()
    end

    return theApp
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
function app.mt:bundleID()
    return self._bundleID
end

--- cp.app:menu() -> cp.app.menu
--- Method
--- Returns the main `menu` for the application.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.app.menu` for the `cp.app` instance.
function app.mt:menu()
    if not self._menu then
        self._menu = menu.new(self)
    end
    return self._menu
end

--- cp.app:launch([waitSeconds]) -> self
--- Method
--- Launches the application, or brings it to the front if it was already running.
---
--- Parameters:
---  * `waitSeconds`    - If povided, the number of seconds to wait until the launch completes. If `nil`, it will return immediately.
---
--- Returns:
---  * The `cp.app` instance.
function app.mt:launch(waitSeconds)
    local hsApp = self:hsApplication()
    if hsApp == nil or not hsApp:isFrontmost() then
        -- Closed:
        local ok = application.launchOrFocusByBundleID(self:bundleID())
        if ok and waitSeconds then
            just.doUntil(function() return self:running() end, waitSeconds, 0.1)
        end
    end

    return self
end

--- cp.app:doLaunch() -> cp.rx.Statement <boolean>
--- Method
--- Returns a `Statement` that can be run to launch or focus the current app.
--- It will resolve to `true` when the app was launched.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement`, resolving to `true` after the app is frontmost.
---
--- Notes:
--- * By default the `Statement` will time out after 30 seconds, sending an error signal.
function app.mt:doLaunch()
    return If(self.installed):Then(
        If(self.frontmost):Is(false):Then(
            If(self.hsApplication):Then(function(hsApp)
                hsApp:activate()
            end)
            :Otherwise(function()
                local ok = application.launchOrFocusByBundleID(self:bundleID())
                if not ok then
                    return Throw("Unable to launch %s.", self:displayName())
                end
            end)
        )
        :Then(WaitUntil(self.frontmost))
        :Otherwise(true)
    )
    :Otherwise(
        Throw("No app with a bundle ID of '%s' is installed.", self:bundleID())
    )
    :TimeoutAfter(30 * 1000, format("Unable to complete launching %s within 30 seconds", self:displayName()))
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
function app.mt:quit(waitSeconds)
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
function app.mt:doQuit()
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
function app.mt:doRestart()
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
function app.mt:show()
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
function app.mt:doShow()
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
function app.mt:hide()
    local hsApp = self:application()
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
function app.mt:doHide()
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
function app.mt:notifier()
    if not self._notifier then
        self._notifier = notifier.new(self:bundleID(), function() return self:UI() end):start()
    end
    return self._notifier
end

function app.mt:__tostring()
    return format("cp.app: %s", self:bundleID())
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
function app._findApp(bundleID, appName)
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
function app.mt:isSupportedLocale(locale)
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
function app.mt:bestSupportedLocale(locale)
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
function app.mt:update()
    self.hsApplication:update()
    return self
end

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
--- * value     - The string value to search for.
---
--- Returns:
--- * `hs.task` which is already running, searching for the `value`. Results will be output in the Error Log.
---
--- Notes:
--- * This may take some time to complete, depending on how many resources the app contains.
function app.mt:searchResources(value)
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
function app._initWatchers()
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
                    timer.doAfter(0.01, function()
                        cpApp.showing:update()
                        cpApp.frontmost:update()
                        updateFrontmostApp(cpApp)
                    end)
                    return
                elseif eventType == applicationwatcher.deactivated then
                    timer.doAfter(0.01, function()
                        cpApp.showing:update()
                        cpApp.frontmost:update()
                    end)
                    return
                elseif eventType == applicationwatcher.launched then
                    timer.doAfter(0.01, function()
                        cpApp.hsApplication:update()
                        cpApp.running:update()
                        cpApp.frontmost:update()
                        updateFrontmostApp(cpApp)
                    end)
                    return
                elseif eventType == applicationwatcher.terminated then
                    timer.doAfter(0.01, function()
                        cpApp.hsApplication:update()
                        cpApp.running:update()
                        cpApp.frontmost:update()
                    end)
                    return
                end
            elseif hsApp:bundleID() ~= COMMANDPOST_BUNDLE_ID then
                updateFrontmostApp(nil)
            end
        end
    ):start()
end

setmetatable(app, {
    __call = function(_, key)
        return app.forBundleID(key)
    end,
})

-- register CommandPost as an app
app.forBundleID(COMMANDPOST_BUNDLE_ID)

return app