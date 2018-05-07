--- === cp.app ===

--- This class assists with working with macOS apps. It provides functions for
--- finding, checking the running status, version number, path, and many other
--- values related to an application. It also provides support for launching,
--- quitting, and other activities related to applications.
---
--- This extension differs from the `hs.application` extension in several ways:
--- * `cp.app` instances are long-lived. You request it once and it will stay up-to-date even if the app quits.
--- * It makes extensive use of `cp.prop`, so you can `watch` many most properties of the app and get live notifications when they change.

local log                       = require("hs.logger").new("app")
local inspect                   = require("hs.inspect")

local ax                        = require("hs._asm.axuielement")
local application               = require("hs.application")
local applicationwatcher		= require("hs.application.watcher")
local fs                        = require("hs.fs")
local pathwatcher				= require("hs.pathwatcher")
local timer                     = require("hs.timer")

local languageID                = require("cp.i18n.languageID")
local localeID                  = require("cp.i18n.localeID")
local just                      = require("cp.just")
local plist                     = require("cp.plist")
local prop                      = require("cp.prop")
local tools                     = require("cp.tools")
local axutils                   = require("cp.ui.axutils")

local v							= require("semver")

local insert                    = table.insert
local format                    = string.format

local mod = {}
mod.mt = {}

local apps = {}

-- PREFS_PATH
-- Constant
-- The standard Preferences Path
local PREFS_PATH = "~/Library/Preferences"

local BASE_LOCALE = "Base"

--- cp.app.bundleIDs() -> table
--- Function
--- Returns a list of Bundle IDs which have been requested via [forBundleID](#forBundleID).
---
--- Parameters:
--- * None
---
--- Returns:
--- * A list of Bundle IDs.
function mod.bundleIDs()
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
--- * None
---
--- Returns:
--- * A list of `cp.app` instances.
function mod.apps()
    local result = {}
    for _,app in pairs(apps) do
        insert(result, app)
    end
    return result
end

--- cp.app.forBundleID(bundleID)
--- Constructor
--- Returns the `cp.app` for the specified Bundle ID. If the app has already been created,
--- the same instance of `cp.app` will be returned on subsequent calls.
---
--- The Bundle ID
---
--- Parameters:
--- * bundleID      - The application bundle ID to find the app for.
---
--- Returns:
--- * The `cp.app` for the bundle.
function mod.forBundleID(bundleID)
    local theApp = apps[bundleID]
    if not theApp then
        theApp = prop.extend({
            _bundleID = bundleID,
            _prefsPath = format("%s/%s.plist", PREFS_PATH, bundleID),
        }, mod.mt)

        local hsApplication = prop.new(function(self)
            local hsApp = self._hsApplication
            if not hsApp or hsApp:bundleID() == nil or not hsApp:isRunning() then
                local result = application.applicationsForBundleID(self._bundleID)
                if result and #result > 0 then
                    hsApp = result[1] -- If there is at least one copy running, return the first one
                else
                    hsApp = nil
                end
                self._application = hsApp
            end
            return hsApp
        end)

        local pid = hsApplication:mutate(function(original)
            local hsApp = original()
            return hsApp and hsApp:pid()
        end)

        local running = hsApplication:mutate(function(original)
            local app = original()
            return app ~= nil and app:bundleID() ~= nil and app:isRunning()
        end)

        local UI = hsApplication:mutate(function(original, self)
            return axutils.cache(self, "_ui", function()
                local hsApp = original()
                return hsApp and ax.applicationElement(hsApp)
            end)
        end)

        local showing = hsApplication:mutate(function(original)
            local app = original()
            return app and not app:isHidden()
        end)

        local frontmost = hsApplication:mutate(function(original)
            local app = original()
            return app ~= nil and app:isFrontmost()
        end)

        local modalDialogOpen = UI:mutate(function(original)
            local ui = original()
            if ui then
                local window = ui:focusedWindow()
                if window then
                    return window:attributeValue("AXModal") == true
                end
            end
            return false
        end)

        local path = hsApplication:mutate(function(original, self)
            local app = original()
            if app and app:isRunning() then
                ----------------------------------------------------------------------------------------
                -- The app is running
                ----------------------------------------------------------------------------------------
                local appPath = app:path()
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
            local app = original()
            if app and app:isRunning() then
                local appPath = app:path()
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
            return theInfo and theInfo["CFBundleDisplayName"]
        end)

        local installed = info:mutate(function(original) return original() ~= nil end)

        local windowsUI = UI:mutate(function(original)
            local ui = original()
            return ui and ui:attributeValue("AXWindows")
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

                    for file in fs.dir(resourcesPath) do
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
            table.sort(locales)
            return locales
        end)

        local currentLocale = prop(
            function(self)
                -- use the cache if present.
                if self._currentLocale ~= nil then
                    return self._currentLocale
                end

                -- TODO: Add checking menus. I believe this is for cases where the system language is not supported by the app, but another language gets selected by default?

                --------------------------------------------------------------------------------
                -- If the app is not running, we next try to determine the language using
                -- the 'AppleLanguages' preference...
                --------------------------------------------------------------------------------
                local appLanguages = self:getPreference("AppleLanguages", nil)
                if appLanguages then
                    for _,lang in ipairs(appLanguages) do
                        if self:isSupportedLocale(lang) then
                            local currentLocale = localeID.forCode(lang)
                            if currentLocale then
                                self._currentLocale = currentLocale
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
                                        self._currentLocale = bestLocale
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
                self._currentLocale = self:baseLocale() or localeID.forCode("en")

                return self._currentLocale
            end,
            function(value, self, theProp)
                if value ~= nil then
                    if type(value) == "string" then
                        value = localeID.forCode(value)
                    end
                    if not localeID.is(value) then
                        error(format("The provided value is not a cp.i18n.localeID: %s", inspect(value)))
                    end
                end

                -- if the new value matches the current value, don't do anything.
                if value == theProp:get() then return end

                if value == nil then
                    if self:getPreference("AppleLanguages") == nil then return end
                    self:setPreference("AppleLanguages", nil)
                else
                    local bestLocale = self:bestSupportedLocale(value)
                    log.df("Found bestLocale: %s", inspect(bestLocale))
                    if bestLocale then
                        local bestLanguage = languageID.forCode()
                        self:setPreference("AppleLanguages", {bestLocale.code})
                    else
                        error("Unsupported language: "..value.code)
                    end
                end
                self._currentLanguage = nil
                if self:running() then
                    self:restart(20)
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

            --- cp.app.windowsUI <cp.prop: hs._asm.axuielement; read-only>
            --- Field
            --- Returns the UI containing the list of windows in the app.
            windowsUI = windowsUI,

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

        apps[bundleID] = theApp

        mod._initWatchers()
    end

    return theApp
end

--- cp.app:bundleID() -> string
--- Function
--- Returns the Bundle ID for the app.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The Bundle ID.
function mod.mt:bundleID()
    return self._bundleID
end

--- cp.app:launch(waitSeconds) -> self
--- Method
--- Launches the application, or brings it to the front if it was already running.
---
--- Parameters:
---  * `waitSeconds`    - If povided, the number of seconds to wait until the launch completes. If `nil`, it will return immediately.
---
--- Returns:
---  * The `cp.app` instance.
function mod.mt:launch(waitSeconds)

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
function mod.mt:quit(waitSeconds)
    local app = self:hsApplication()
    if app then
        app:kill()
        if waitSeconds then
            just.doWhile(function() return self:running() end, waitSeconds, 0.1)
        end
    end
    return self
end

--- cp.app:restart(waitSeconds) -> self
--- Method
--- Restart the application, if currently running. If not, no action is taken.
---
--- Parameters:
---  * `waitSeconds`    - If povided, the number of seconds to wait until the quit completes. If `nil`, it will return immediately.
---
--- Returns:
---  * The `cp.app` instance.
function mod.mt:restart(waitSeconds)
    local app = self:hsApplication()
    if app then
        local appPath = app:path()
        -- Kill it.
        self:quit()

        -- Wait until the app is Closed (checking every 0.1 seconds for up to 20 seconds):
        just.doWhile(function() return self:running() end, 20, 0.1)

        -- force the application prop to update, otherwise it isn't closed long enough to prompt an event.
        self.hsApplication:update()

        -- Launch:
        if appPath then
            local output, ok = hs.execute(format('open "%s"', appPath))
            if not ok then
                log.ef("There was a problem opening the '%s' application: %s", self:bundleID(), output)
            end
        end

        if waitSeconds then
            just.doUntil(function() return self:running() end, waitSeconds, 0.1)
        end

    end
    return self
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
function mod.mt:show()
    local app = self:hsApplication()
    if app then
        if app:isHidden() then
            app:unhide()
        end
        if app:isRunning() then
            app:activate()
        end
    end
    return self
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
function mod.mt:hide()
    local app = self:application()
    if app then
        app:hide()
    end
    return self
end

function mod.mt:__tostring()
    return format("cp.app: %s", self:bundleID())
end

-- cp.app._findApp(bundleID, appName) -> cp.app
-- Function
-- Attempts to find the registered app, first by Bundle ID, then by the app name if provided.
-- It will not create a new `cp.app` instance for the Bundle ID if it does not exist.
--
-- Parameters:
-- * bundleID       - The app Bundle ID
-- * appName        - The app display name
--
-- Returns:
-- * The `cp.app` matching the details, or `nil` if not found.
function mod._findApp(bundleID, appName)
    local app = apps[bundleID]
    if app == nil and bundleID == nil and appName ~= nil then
        -- look harder...
        for _,a in pairs(apps) do
            if a:displayName() == appName then
                return a
            end
        end
    end
    return app
end

-- cp.app._initWatchers() -> none
-- Method
-- Initialise all the various applicaiton watcheres.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function mod._initWatchers()
    if mod._appWatcher then
        return
    end

    --------------------------------------------------------------------------------
    -- Setup Application Watcher:
    --------------------------------------------------------------------------------
    --log.df("Setting up Application Watcher...")
    mod._appWatcher = applicationwatcher.new(
        function(appName, eventType, hsApp)
            local app = mod._findApp(hsApp:bundleID(), appName)

            -- log.df("Application event: bundleID: %s; appName: '%s'; type: %s", bundleID, appName, eventType)
            if app then
                if eventType == applicationwatcher.activated then
                    timer.doAfter(0.01, function()
                        app.showing:update()
                        app.frontmost:update()
                    end)
                    return
                elseif eventType == applicationwatcher.deactivated then
                    timer.doAfter(0.01, function()
                        app.showing:update()
                        app.frontmost:update()
                    end)
                    return
                elseif eventType == applicationwatcher.launched then
                    timer.doAfter(0.01, function()
                        log.df("launched. Updating hs.application etc.")
                        app.hsApplication:update()
                        app.running:update()
                        app.frontmost:update()
                    end)
                    return
                elseif eventType == applicationwatcher.terminated then
                    timer.doAfter(0.01, function()
                        log.df("terminated. Updating hs.application etc.")
                        app.hsApplication:update()
                        app.running:update()
                        app.frontmost:update()
                    end)
                    return
                end
            end
        end
    ):start()

    --------------------------------------------------------------------------------
    -- Setup Preferences Watcher:
    --------------------------------------------------------------------------------
    --log.df("Setting up Preferences Watcher...")
    local plistPattern = [[^.-([^/]+)%.plist$]]
    mod._preferencesWatcher = pathwatcher.new(PREFS_PATH, function(files)
        for _,file in pairs(files) do
            local bundleID = string.match(file, plistPattern)
            if bundleID then
                local app = mod._findApp(bundleID)
                if app then
                    -- force an update
                    app:getPreferences(true)
                end
            end
        end
    end):start()

end

local function syncPreferences(bundleID)
    -- log.df("Reloading Final Cut Pro Preferences: %s; %s", self._preferencesModified, modified)
    -- NOTE: https://macmule.com/2014/02/07/mavericks-preference-caching/
    hs.execute(format([[/usr/bin/python -c 'import CoreFoundation; CoreFoundation.CFPreferencesAppSynchronize("%s")']], bundleID))
end

--- cp.app:getPreferences([forceReload]) -> table or nil
--- Method
--- Gets the application's preferences as a table. It checks if the preferences
--- file has been modified and reloads when necessary.
---
--- Parameters:
---  * forceReload	- If `true`, an optional reload will be forced even if the file hasn't been modified.
---
--- Returns:
---  * A table with all of the app's preferences, or `nil` if an error occurred.
function mod.mt:getPreferences(forceReload)
    local path = self._prefsPath
    local modified = fs.attributes(path, "modification")
    if forceReload or modified ~= self._preferencesModified then
        syncPreferences(self:bundleID())

        self._preferences = plist.binaryFileToTable(path) or nil
        self._preferencesModified = fs.attributes(path, "modification")
     end
    return self._preferences
end

--- cp.app:getPreference(value[, default[, forceReload]]) -> string or nil
--- Method
--- Get an individual preference value for the app.
---
--- Parameters:
---  * value 			- The preference you want to return
---  * default		    - The optional default value to return if the preference is not set.
---  * forceReload	    - If `true`, optionally forces a reload of the app's preferences.
---
--- Returns:
---  * A string with the preference value, or nil if an error occurred
function mod.mt:getPreference(value, default, forceReload)
    local result = nil
    local preferencesTable = self:getPreferences(forceReload)
    if preferencesTable then
        result = preferencesTable[value]
    end

    if result == nil then
        result = default
    end

    return result
end

--- cp.app:setPreference(key, value) -> boolean
--- Method
--- Sets an individual appliaction preference.
---
--- Parameters:
---  * key - The preference you want to change.
---  * value - The value you want to set for that preference
---
--- Returns:
---  * `true` if executed successfully otherwise `false`.
function mod.mt:setPreference(key, value)
    local preferenceType

    if value == nil then
        local executeString = format("defaults delete %s '%s'", self:bundleID(), key)
        local output, ok = hs.execute(executeString)
        if ok then
            return true
        else
            log.wf("Error occurred while deleting defaults: %s", output)
            return false
        end

    end

    if type(value) == "boolean" then
        value = tostring(value)
        preferenceType = "bool"
    elseif type(value) == "table" then
        local arrayString = ""
        for i=1, #value do
            arrayString = arrayString .. value[i]
            if i ~= #value then
                arrayString = arrayString .. ","
            end
        end
        value = "'" .. arrayString .. "'"
        preferenceType = "array"
    elseif type(value) == "string" then
        preferenceType = "string"
        value = "'" .. value .. "'"
    elseif type(value) == "number" then
        preferenceType = "int"
        value = tostring(value)
    else
        return false
    end

    if preferenceType then
        local executeString = format("defaults write %s '%s' -%s %s", self:bundleID(), key, preferenceType, value)
        local output, ok = hs.execute(executeString)
        if ok then
            return true
        else
            log.wf("Error occurred while saving defaults: %s", output)
            return false
        end
    end
    return false
end

--- cp.app:isSupportedLocale(locale) -> boolean
--- Method
--- Checks if the specified locale is supported. The `locale` can
--- be either a string with the locale code (eg. "en_AU") or a
--- `cp.i18n.localeID`.
---
--- Parameters:
--- * locale    - The locale code string or `localeID` to check.
---
--- Returns:
--- * `true` if it is supported, otherwise `false`.
function mod.mt:isSupportedLocale(locale)
    if type(locale) == "string" then
        locale = localeID.forCode(locale)
    end
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
--- * locale    - The local to match
---
--- Returns:
--- * The closest supported locale or `nil` if none are available in the language.
function mod.mt:bestSupportedLocale(locale)
    if type(locale) == "string" then
        locale = localeID.forCode(locale)
    end
    if localeID.is(locale) then
        local currentLocale = nil
        local currentScore = 0
        for _,sl in ipairs(self:supportedLocales()) do
            local score = sl:matches(locale)
            if score > currentScore then
                currentLocale = sl
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
--- * None
---
--- Returns:
--- * The `cp.app` instance.
function mod.mt:update()
    self.hsApplication:update()
    return self
end

return mod