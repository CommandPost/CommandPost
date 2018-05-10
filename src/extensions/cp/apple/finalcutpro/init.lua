--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro ===
---
--- Represents the Final Cut Pro application, providing functions that allow different tasks to be accomplished.
---
--- This module provides an API to work with the FCPX application. There are a couple of types of files:
---
--- * `init.lua` - the main module that gets imported.
--- * `axutils.lua` - some utility functions for working with `axuielement` objects.
---
--- Generally, you will `require` the `cp.apple.finalcutpro` module to import it, like so:
---
--- ```lua
--- local fcp = require("cp.apple.finalcutpro")
--- ```
---
--- Then, there are the `UpperCase` files, which represent the application itself:
---
--- * `MenuBar` 	- The main menu bar.
--- * `prefs/PreferencesWindow` - The preferences window.
--- * etc...
---
--- The `fcp` variable is the root application. It has functions which allow you to perform tasks or access parts of the UI. For example, to open the `Preferences` window, you can do this:
---
--- ```lua
--- fcp:preferencesWindow():show()
--- ```
---
--- In general, as long as FCPX is running, actions can be performed directly, and the API will perform the required operations to achieve it. For example, to toggle the 'Create Optimized Media' checkbox in the 'Import' section of the 'Preferences' window, you can simply do this:
---
--- ```lua
--- fcp:preferencesWindow():importPanel():toggleCreateOptimizedMedia()
--- ```
---
--- The API will automatically open the `Preferences` window, navigate to the 'Import' panel and toggle the checkbox.
---
--- The `UpperCase` classes also have a variety of `UI` methods. These will return the `axuielement` for the relevant GUI element, if it is accessible. If not, it will return `nil`. These allow direct interaction with the GUI if necessary. It's most useful when adding new functions to `UpperCase` files for a particular element.
---
--- This can also be used to 'wait' for an element to be visible before performing a task. For example, if you need to wait for the `Preferences` window to finish loading before doing something else, you can do this with the `cp.just` library:
---
--- ```lua
--- local just = require("cp.just")
---
--- local prefsWindow = fcp:preferencesWindow()
---
--- local prefsUI = just.doUntil(function() return prefsWindow:UI() end)
---
--- if prefsUI then
--- 	-- it's open!
--- else
--- 	-- it's closed!
--- end
--- ```
---
--- By using the `just` library, we can do a loop waiting until the function returns a result that will give up after a certain time period (10 seconds by default).
---
--- Of course, we have a specific support function for that already, so you could do this instead:
---
--- ```lua
--- if fcp:preferencesWindow():isShowing() then
--- 	-- it's open!
--- else
--- 	-- it's closed!
--- end
--- ```

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local logname									= "fcp"
local log										= require("hs.logger").new(logname)

local fnutils									= require("hs.fnutils")
local fs 										= require("hs.fs")
local inspect									= require("hs.inspect")
local osascript 								= require("hs.osascript")

local v											= require("semver")
local moses										= require("moses")

local just										= require("cp.just")
local localeID                                  = require("cp.i18n.localeID")
local plist										= require("cp.plist")
local prop										= require("cp.prop")
local shortcut									= require("cp.commands.shortcut")
local tools										= require("cp.tools")
local watcher									= require("cp.watcher")

local axutils									= require("cp.ui.axutils")
local notifier									= require("cp.ui.notifier")
local Browser									= require("cp.apple.finalcutpro.main.Browser")
local CommandEditor								= require("cp.apple.finalcutpro.cmd.CommandEditor")
local KeywordEditor								= require("cp.apple.finalcutpro.main.KeywordEditor")
local destinations								= require("cp.apple.finalcutpro.export.destinations")
local ExportDialog								= require("cp.apple.finalcutpro.export.ExportDialog")
local FullScreenWindow							= require("cp.apple.finalcutpro.main.FullScreenWindow")
local kc										= require("cp.apple.finalcutpro.keycodes")
local MediaImport								= require("cp.apple.finalcutpro.import.MediaImport")
local MenuBar									= require("cp.apple.finalcutpro.MenuBar")
local PreferencesWindow							= require("cp.apple.finalcutpro.prefs.PreferencesWindow")
local PrimaryWindow								= require("cp.apple.finalcutpro.main.PrimaryWindow")
local SecondaryWindow							= require("cp.apple.finalcutpro.main.SecondaryWindow")
local Timeline									= require("cp.apple.finalcutpro.main.Timeline")
local Viewer									= require("cp.apple.finalcutpro.main.Viewer")
local windowfilter								= require("cp.apple.finalcutpro.windowfilter")

local app                                       = require("cp.apple.finalcutpro.app")
local plugins									= require("cp.apple.finalcutpro.plugins")
local fcpStrings                                = require("cp.apple.finalcutpro.strings")


local format, gsub, find						= string.format, string.gsub, string.find

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local fcp = {
    --- cp.apple.finalcutpro.app <cp.app>
    --- Constant
    --- The `cp.app` for Final Cut Pro.
    app = app,
    strings = fcpStrings,
}

--- cp.apple.finalcutpro.BUNDLE_ID
--- Constant
--- Final Cut Pro's Bundle ID as a `semver`.
fcp.BUNDLE_ID = "com.apple.FinalCut"

--- cp.apple.finalcutpro.EARLIEST_SUPPORTED_VERSION
--- Constant
--- The earliest version of Final Cut Pro supported by this module.
fcp.EARLIEST_SUPPORTED_VERSION = v("10.3.2")

--- cp.apple.finalcutpro.PASTEBOARD_UTI
--- Constant
--- Final Cut Pro's Pasteboard UTI
fcp.PASTEBOARD_UTI = "com.apple.flexo.proFFPasteboardUTI"

--- cp.apple.finalcutpro.EVENT_DESCRIPTION_PATH
--- Constant
--- The Event Description Path.
fcp.EVENT_DESCRIPTION_PATH = "/Contents/Frameworks/TLKit.framework/Versions/A/Resources/EventDescriptions.plist"

--- cp.apple.finalcutpro.FLEXO_LANGUAGES
--- Constant
--- Table of Final Cut Pro's supported Languages for the Flexo Framework
fcp.FLEXO_LANGUAGES	= {"de", "en", "es_419", "es", "fr", "id", "ja", "ms", "vi", "zh_CN"}

--- cp.apple.finalcutpro.ALLOWED_IMPORT_VIDEO_EXTENSIONS
--- Constant
--- Table of video file extensions Final Cut Pro can import.
fcp.ALLOWED_IMPORT_VIDEO_EXTENSIONS	= {"3gp", "avi", "mov", "mp4", "mts", "m2ts", "mxf", "m4v", "r3d"}

--- cp.apple.finalcutpro.ALLOWED_IMPORT_AUDIO_EXTENSIONS
--- Constant
--- Table of audio file extensions Final Cut Pro can import.
fcp.ALLOWED_IMPORT_AUDIO_EXTENSIONS	= {"aac", "aiff", "aif", "bwf", "caf", "mp3", "mp4", "wav"}

--- cp.apple.finalcutpro.ALLOWED_IMPORT_IMAGE_EXTENSIONS
--- Constant
--- Table of image file extensions Final Cut Pro can import.
fcp.ALLOWED_IMPORT_IMAGE_EXTENSIONS	= {"bmp", "gif", "jpeg", "jpg", "png", "psd", "raw", "tga", "tiff", "tif"}

--- cp.apple.finalcutpro.ALLOWED_IMPORT_EXTENSIONS
--- Constant
--- Table of all file extensions Final Cut Pro can import.
fcp.ALLOWED_IMPORT_ALL_EXTENSIONS = fnutils.concat(fcp.ALLOWED_IMPORT_VIDEO_EXTENSIONS, fnutils.concat(fcp.ALLOWED_IMPORT_AUDIO_EXTENSIONS, fcp.ALLOWED_IMPORT_IMAGE_EXTENSIONS))

--- cp.apple.finalcutpro.PLAYER_QUALITY
--- Constant
--- Table of Player Quality values used by the `FFPlayerQuality` preferences value:
fcp.PLAYER_QUALITY = {
    ["ORIGINAL_BETTER_QUALITY"]     = 10,
    ["ORIGINAL_BETTER_PERFORMANCE"] = 5,
    ["PROXY"]                       = 4,
}

--- cp.apple.finalcutpro:init() -> App
--- Function
--- Initialises the app instance representing Final Cut Pro.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The app.
function fcp:init()
    self:_initWatchers()
    self.app.hsApplication:watch(function() self:reset() end)

    -- set initial state
    self.app:update()
    return self
end

-- bind the `cp.app` props to the FCP instance for easy access/backwards compatibility.
prop.bind(fcp) {

    --- cp.apple.finalcutpro.application <cp.prop: hs.application; read-only>
    --- Field
    --- Returns the running `hs.application` for Final Cut Pro, or `nil` if it's not running.
    application = fcp.app.hsApplication,

    --- cp.apple.finalcutpro.isRunning <cp.prop: boolean; read-only>
    --- Field
    --- Is Final Cut Pro Running?
    isRunning = fcp.app.running,

    --- cp.apple.finalcutpro.UI <cp.prop: hs._asm.axuielement; read-only; live>
    --- Method
    --- The Final Cut Pro `axuielement`, if available.
    UI = fcp.app.UI,

    --- cp.apple.finalcutpro.isShowing <cp.prop: boolean; read-only; live>
    --- Field
    --- Is Final Cut visible on screen?
    isShowing = fcp.app.showing,

    --- cp.apple.finalcutpro.getVersion <cp.prop: string; read-only; live>
    --- Field
    --- Version of Final Cut Pro as string.
    getVersion = fcp.app.versionString,

    --- cp.apple.finalcutpro.isInstalled <cp.prop: boolean; read-only>
    --- Field
    --- Is any version of Final Cut Pro Installed?
    isInstalled = fcp.app.installed,

    --- cp.apple.finalcutpro:isFrontmost <cp.prop: boolean; read-only; live>
    --- Field
    --- Is Final Cut Pro Frontmost?
    isFrontmost = fcp.app.frontmost,

    --- cp.apple.finalcutpro:isModalDialogOpen <cp.prop: boolean; read-only>
    --- Field
    --- Is a modal dialog currently open?
    isModalDialogOpen = fcp.app.modalDialogOpen,

    --- cp.apple.finalcutpro.isSupported <cp.prop: boolean; read-only; live>
    --- Field
    --- Is a supported version of Final Cut Pro installed?
    ---
    --- Note:
    ---  * Supported version refers to any version of Final Cut Pro equal or higher to `cp.apple.finalcutpro.EARLIEST_SUPPORTED_VERSION`
    isSupported = fcp.app.version:mutate(function(original)
        local version = original()
        return version ~= nil and version >= fcp.EARLIEST_SUPPORTED_VERSION
    end),

    --- cp.apple.finalcutpro.supportedLocales <cp.prop: table of cp.i18n.localeID; read-only>
    --- Field
    --- The list of supported locales for this version of FCPX.
    supportedLocales = fcp.app.supportedLocales,

    --- cp.apple.finalcutpro.currentLocale <cp.prop: cp.i18n.localeID; live>
    --- Field
    --- Gets and sets the current locale for FCPX.
    currentLocale = fcp.app.currentLocale,

    --- cp.apple.finalcutpro.version <cp.prop: semver; read-only; live>
    --- Field
    --- The version number of the running or default installation of FCPX as a `semver`.
    version = fcp.app.version,

    --- cp.apple.finalcutpro.versionString <cp.prop: string; read-only; live>
    --- Field
    --- The version number of the running or default installation of FCPX as a `string`.
    versionString = fcp.app.versionString,
}

prop.bind(fcp) {
    --- cp.apple.finalcutpro.isUnsupported <cp.prop: boolean; read-only>
    --- Field
    --- Is an unsupported version of Final Cut Pro installed?
    ---
    --- Note:
    ---  * Supported version refers to any version of Final Cut Pro equal or higher to cp.apple.finalcutpro.EARLIEST_SUPPORTED_VERSION
    isUnsupported = fcp.isInstalled:AND(fcp.isSupported:NOT())
}

--- cp.apple.finalcutpro:reset() -> none
--- Function
--- Resets the language cache
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function fcp:reset()
    self._activeCommandSet = nil
end

--- cp.apple.finalcutpro:string(key[, locale[, quiet]]) -> string
--- Method
--- Looks up an application string with the specified `key`.
--- If no `locale` value is provided, the [current locale](#currentLocale) is used.
---
--- Parameters:
---  * `key`	- The key to look up.
---  * `locale`	- The locale code to use. Defaults to the current locale.
---  * `quiet`	- Optional boolean, defaults to `false`. If `true`, no warnings are logged for missing keys.
---
--- Returns:
---  * The requested string or `nil` if the application is not running.
function fcp:string(key, locale, quiet)
    return self.strings:find(key, locale, quiet)
end

--- cp.apple.finalcutpro:keysWithString(string[, locale]) -> {string}
--- Method
--- Looks up an application string and returns an array of keys that match. It will take into account current locale the app is running in, or use `locale` if provided.
---
--- Parameters:
---  * `key`	- The key to look up.
---  * `locale`	- The locale (defaults to current FCPX locale).
---
--- Returns:
---  * The array of keys with a matching string.
---
--- Notes:
---  * This method may be very inefficient, since it has to search through every possible key/value pair to find matches. It is not recommended that this is used in production.
function fcp:keysWithString(string, locale)
    return self.strings:findKeys(string, locale)
end

--- cp.apple.finalcutpro:bundleID() -> string
--- Method
--- Returns the Bundle ID for the app.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The Bundle ID
function fcp:bundleID()
    return self.app:bundleID()
end

--- cp.apple.finalcutpro:getPasteboardUTI() -> string
--- Method
--- Returns the Final Cut Pro Pasteboard UTI
---
--- Parameters:
---  * None
---
--- Returns:
---  * A string of the Final Cut Pro Pasteboard UTI
-- TODO: This should be a function rather than a method.
function fcp:getPasteboardUTI() -- luacheck: ignore
    return fcp.PASTEBOARD_UTI
end

--- cp.apple.finalcutpro:notifier() -> cp.ui.notifier
--- Method
--- Returns a notifier that is tracking the application UI element. It has already been started.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The notifier.
function fcp:notifier()
    if not self._notifier then
        self._notifier = notifier.new(self:bundleID(), function() return self:UI() end):start()
    end
    return self._notifier
end

--- cp.apple.finalcutpro:launch([waitSeconds]) -> self
--- Method
--- Launches Final Cut Pro, or brings it to the front if it was already running.
---
--- Parameters:
---  * waitSeconds  - if provided, we will wait for up to the specified seconds for the launch to complete.
---
--- Returns:
---  * The FCP instance.
function fcp:launch(waitSeconds)
    self.app:launch(waitSeconds)
    return self
end

--- cp.apple.finalcutpro:restart([waitSeconds]) -> self
--- Method
--- Restart Final Cut Pro, if it is running. If not, nothing happens.
---
--- Parameters:
---  * `waitSeconds`	- If provided, the number of seconds to wait for the restart to complete.
---
--- Returns:
---  * The FCP instance.
function fcp:restart(waitSeconds)
    self.app:restart(waitSeconds)
    return self
end

--- cp.apple.finalcutpro:show() -> cp.apple.finalcutpro
--- Method
--- Activate Final Cut Pro, if it is running.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The FCP instance.
function fcp:show()
    self.app:show()
    return self
end

--- cp.apple.finalcutpro:hide() -> self
--- Method
--- Hides Final Cut Pro
---
--- Parameters:
---  * None
---
--- Returns:
---  * The FCP instance.
function fcp:hide()
    self.app:hide()
end

--- cp.apple.finalcutpro:quit([waitSeconds]) -> self
--- Method
--- Quits Final Cut Pro, if it's running.
---
--- Parameters:
---  * waitSeconds      - The number of seconds to wait for the quit to complete.
---
--- Returns:
---  * The FCP instance.
function fcp:quit(waitSeconds)
    self.app:quit(waitSeconds)
    return self
end

--- cp.apple.finalcutpro:getPath() -> string or nil
--- Method
--- Path to Final Cut Pro Application
---
--- Parameters:
---  * None
---
--- Returns:
---  * A string containing Final Cut Pro's filesystem path, or nil if Final Cut Pro's path could not be determined.
function fcp:getPath()
    return self.app:path()
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--
-- LIBRARIES
--
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

--- cp.apple.finalcutpro:openLibrary(path) -> boolean
--- Method
--- Attempts to open a file at the specified absolute `path`.
---
--- Parameters:
--- * path	- The path to the FCP Library to open.
---
--- Returns:
--- * `true` if successful, or `false` if not.
-- TODO: This should be a function rather than a method.
function fcp:openLibrary(path) -- luacheck: ignore
    assert(type(path) == "string", "Please provide a valid path to the FCP Library.")
    if fs.attributes(path) == nil then
        log.ef("Unable to find an FCP Library file at the provided path: %s", path)
        return false
    end

    local output, ok = os.execute("open '".. path .. "'")
    if not ok then
        log.ef(format("Error while opening the FCP Library at '%s': %s", path, output))
        return false
    end

    return true
end

--- cp.apple.finalcutpro:selectLibrary(title) -> axuielement
--- Method
--- Attempts to select an open library with the specified title.
---
--- Parameters:
--- * title - The title of the library to select.
---
--- Returns:
--- * The library row `axuielement`.
function fcp:selectLibrary(title)
    return self:libraries():selectLibrary(title)
end

--- cp.apple.finalcutpro:closeLibrary(title) -> boolean
--- Method
--- Attempts to close a library with the specified `title`.
---
--- Parameters:
--- * title	- The title of the FCP Library to close.
---
--- Returns:
--- * `true` if successful, or `false` if not.
function fcp:closeLibrary(title)
    if self:isRunning() then
        local libraries = self:libraries()
        libraries:show()
        just.doUntil(function() return libraries:isShowing() end, 5.0)
        -- waiting here for a couple of seconds seems to make it less likely to crash FCP
        just.wait(2.0)
        if libraries:selectLibrary(title) ~= nil then
            local closeLibrary = self:string("FFCloseLibraryFormat")
            if closeLibrary then
                closeLibrary = gsub(closeLibrary, "%%@", title)
            end

            self:selectMenu({"File", function(item)
                return item:title() == closeLibrary
            end})
            -- wait until the library actually closes, up to 5 seconds.
            return just.doUntil(function() return libraries:show():selectLibrary(title) == nil end, 10.0)
        end
    end
    return false
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--
-- SCAN PLUGINS
--
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

--- cp.apple.finalcutpro:plugins() -> cp.apple.finalcutpro.plugins
--- Method
--- Returns the plugins manager for the app.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The plugins manager.
function fcp:plugins()
    if not self._plugins then
        self._plugins = plugins.new(self)
    end
    return self._plugins
end

--- cp.apple.finalcutpro:scanPlugins() -> table
--- Method
--- Scan Final Cut Pro Plugins
---
--- Parameters:
---  * None
---
--- Returns:
---  * A MenuBar object
function fcp:scanPlugins()
    return self:plugins():scan()
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--
-- MENU BAR
--
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

--- cp.apple.finalcutpro:menuBar() -> menuBar object
--- Method
--- Returns the Final Cut Pro Menu Bar
---
--- Parameters:
---  * None
---
--- Returns:
---  * A MenuBar object
function fcp:menuBar()
    if not self._menuBar then
        local menuBar = MenuBar:new(self)
        ----------------------------------------------------------------------------------------
        -- Add a finder for Share Destinations:
        ----------------------------------------------------------------------------------------
        menuBar:addMenuFinder(function(parentItem, path, childName)
            if moses.isEqual(path, {"File", "Share"}) then
                childName = childName:match("(.*)…$") or childName
                local index = destinations.indexOf(childName)
                if index then
                    local children = parentItem:attributeValue("AXChildren")
                    return children[index]
                end
            end
            return nil
        end)
        ----------------------------------------------------------------------------------------
        -- Add a finder for missing menus:
        ----------------------------------------------------------------------------------------
        local missingMenuMap = {
            { path = {"Final Cut Pro"},					child = "Commands",			key = "CommandSubmenu" },
            { path = {"Final Cut Pro", "Commands"},		child = "Customize…",		key = "Customize" },
            { path = {"Clip"},							child = "Open Clip",		key = "FFOpenInTimeline" },
            { path = {"Window", "Show in Workspace"},	child = "Sidebar",			key = "PEEventsLibrary" },
            { path = {"Window", "Show in Workspace"},	child = "Timeline",			key = "PETimeline" },
        }

        menuBar:addMenuFinder(function(parentItem, path, childName)
            for _,item in ipairs(missingMenuMap) do
                if moses.isEqual(path, item.path) and childName == item.child then
                    return axutils.childWith(parentItem, "AXTitle", self:string(item.key))
                end
            end
            return nil
        end)

        self._menuBar = menuBar
    end
    return self._menuBar
end

--- cp.apple.finalcutpro:selectMenu(path) -> boolean
--- Method
--- Selects a Final Cut Pro Menu Item based on the list of menu titles in English.
---
--- Parameters:
---  * `path`	- The list of menu items you'd like to activate, for example:
---            select("View", "Browser", "as List")
---
--- Returns:
---  * `true` if the press was successful.
function fcp:selectMenu(path)
    return self:menuBar():selectMenu(path)
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--
-- WINDOWS
--
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

--- cp.apple.finalcutpro:preferencesWindow() -> preferenceWindow object
--- Method
--- Returns the Final Cut Pro Preferences Window
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Preferences Window
function fcp:preferencesWindow()
    if not self._preferencesWindow then
        self._preferencesWindow = PreferencesWindow.new(self)
    end
    return self._preferencesWindow
end

--- cp.apple.finalcutpro:primaryWindow() -> primaryWindow object
--- Method
--- Returns the Final Cut Pro Preferences Window
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Primary Window
function fcp:primaryWindow()
    if not self._primaryWindow then
        self._primaryWindow = PrimaryWindow:new(self)
    end
    return self._primaryWindow
end

--- cp.apple.finalcutpro:secondaryWindow() -> secondaryWindow object
--- Method
--- Returns the Final Cut Pro Preferences Window
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Secondary Window
function fcp:secondaryWindow()
    if not self._secondaryWindow then
        self._secondaryWindow = SecondaryWindow:new(self)
    end
    return self._secondaryWindow
end

--- cp.apple.finalcutpro:fullScreenWindow() -> fullScreenWindow object
--- Method
--- Returns the Final Cut Pro Full Screen Window
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Full Screen Playback Window
function fcp:fullScreenWindow()
    if not self._fullScreenWindow then
        self._fullScreenWindow = FullScreenWindow:new(self)
    end
    return self._fullScreenWindow
end

--- cp.apple.finalcutpro:commandEditor() -> commandEditor object
--- Method
--- Returns the Final Cut Pro Command Editor
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Final Cut Pro Command Editor
function fcp:commandEditor()
    if not self._commandEditor then
        self._commandEditor = CommandEditor:new(self)
    end
    return self._commandEditor
end

--- cp.apple.finalcutpro:keywordEditor() -> keywordEditor object
--- Method
--- Returns the Final Cut Pro Keyword Editor
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Final Cut Pro Keyword Editor
function fcp:keywordEditor()
    if not self._keywordEditor then
        self._keywordEditor = KeywordEditor:new(self)
    end
    return self._keywordEditor
end

--- cp.apple.finalcutpro:mediaImport() -> mediaImport object
--- Method
--- Returns the Final Cut Pro Media Import Window
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Final Cut Pro Media Import Window
function fcp:mediaImport()
    if not self._mediaImport then
        self._mediaImport = MediaImport:new(self)
    end
    return self._mediaImport
end

--- cp.apple.finalcutpro:exportDialog() -> exportDialog object
--- Method
--- Returns the Final Cut Pro Export Dialog Box
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Final Cut Pro Export Dialog Box
function fcp:exportDialog()
    if not self._exportDialog then
        self._exportDialog = ExportDialog:new(self)
    end
    return self._exportDialog
end

--- cp.apple.finalcutpro:windowsUI() -> axuielement
--- Method
--- Returns the UI containing the list of windows in the app.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The axuielement, or nil if the application is not running.
function fcp:windowsUI()
    return self.app:windowsUI()
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--
-- APP SECTIONS
--
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

--- cp.apple.finalcutpro:toolbar() -> PrimaryToolbar
--- Method
--- Returns the Primary Toolbar - the toolbar at the top of the Primary Window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the PrimaryToolbar
function fcp:toolbar()
    return self:primaryWindow():toolbar()
end

--- cp.apple.finalcutpro:timeline() -> Timeline
--- Method
--- Returns the Timeline instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the Timeline
function fcp:timeline()
    if not self._timeline then
        self._timeline = Timeline.new(self)
    end
    return self._timeline
end

--- cp.apple.finalcutpro:viewer() -> Viewer
--- Method
--- Returns the Viewer instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the Viewer
function fcp:viewer()
    if not self._viewer then
        self._viewer = Viewer.new(self, false)
    end
    return self._viewer
end

--- cp.apple.finalcutpro:eventViewer() -> Event Viewer
--- Method
--- Returns the Event Viewer instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the Event Viewer
function fcp:eventViewer()
    if not self._eventViewer then
        self._eventViewer = Viewer.new(self, true)
    end
    return self._eventViewer
end

--- cp.apple.finalcutpro:browser() -> Browser
--- Method
--- Returns the Browser instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the Browser
function fcp:browser()
    if not self._browser then
        self._browser = Browser:new(self)
    end
    return self._browser
end

--- cp.apple.finalcutpro:libraries() -> LibrariesBrowser
--- Method
--- Returns the LibrariesBrowser instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the LibrariesBrowser
function fcp:libraries()
    return self:browser():libraries()
end

--- cp.apple.finalcutpro:media() -> MediaBrowser
--- Method
--- Returns the MediaBrowser instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the MediaBrowser
function fcp:media()
    return self:browser():media()
end

--- cp.apple.finalcutpro:generators() -> GeneratorsBrowser
--- Method
--- Returns the GeneratorsBrowser instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the GeneratorsBrowser
function fcp:generators()
    return self:browser():generators()
end

--- cp.apple.finalcutpro:effects() -> EffectsBrowser
--- Method
--- Returns the EffectsBrowser instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the EffectsBrowser
function fcp:effects()
    return self:timeline():effects()
end

--- cp.apple.finalcutpro:transitions() -> TransitionsBrowser
--- Method
--- Returns the TransitionsBrowser instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the TransitionsBrowser
function fcp:transitions()
    return self:timeline():transitions()
end

--- cp.apple.finalcutpro:inspector() -> Inspector
--- Method
--- Returns the Inspector instance from the primary window
---
--- Parameters:
---  * None
---
--- Returns:
---  * the Inspector
function fcp:inspector()
    return self:primaryWindow():inspector()
end

--- cp.apple.finalcutpro:colorBoard() -> ColorBoard
--- Method
--- Returns the ColorBoard instance from the primary window
---
--- Parameters:
---  * None
---
--- Returns:
---  * the ColorBoard
function fcp:colorBoard()
    return self:primaryWindow():colorBoard()
end

--- cp.apple.finalcutpro:color() -> ColorInspector
--- Method
--- Returns the ColorInspector instance from the primary window
---
--- Parameters:
---  * None
---
--- Returns:
---  * the ColorInspector
function fcp:color()
    return self:primaryWindow():color()
end

--- cp.apple.finalcutpro:alert() -> cp.ui.Alert
--- Method
--- Provides basic access to any 'alert' dialog windows in the app.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the `Alert` instance
function fcp:alert()
    return self:primaryWindow():alert()
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--
-- PREFERENCES, SETTINGS, XML
--
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

--- cp.apple.finalcutpro:getPreferences() -> table or nil
--- Method
--- Gets Final Cut Pro's Preferences as a table. It checks if the preferences
--- file has been modified and reloads when necessary.
---
--- Parameters:
---  * [forceReload]	- If `true`, an optional reload will be forced even if the file hasn't been modified.
---
--- Returns:
---  * A table with all of Final Cut Pro's preferences, or nil if an error occurred
function fcp:getPreferences()
    return self.app.preferences
end

--- cp.apple.finalcutpro:getPreference(key, [default], [forceReload]) -> string or nil
--- Method
--- Get an individual Final Cut Pro preference
---
--- Parameters:
---  * key 			- The preference you want to return
---  * [default]		- The optional default value to return if the preference is not set.
---
--- Returns:
---  * A string with the preference value, or nil if an error occurred
function fcp:getPreference(key, default)
    return self.app.preferences[key] or default
end

--- cp.apple.finalcutpro:setPreference(key, value) -> nil
--- Method
--- Sets an individual Final Cut Pro preference
---
--- Parameters:
---  * key - The preference you want to change
---  * value - The value you want to set for that preference
---
--- Returns:
---  * `nil`
function fcp:setPreference(key, value)
    self.app.preferences[key] = value
end

--- cp.apple.finalcutpro:importXML(path) -> boolean
--- Method
--- Imports an XML file into Final Cut Pro
---
--- Parameters:
---  * path = Path to XML File
---
--- Returns:
---  * A boolean value indicating whether the AppleScript succeeded or not
function fcp:importXML(path)
    if self:isRunning() then
        local appleScript = [[
            set whichSharedXMLPath to "]] .. path .. [["
            tell application "Final Cut Pro"
                activate
                open POSIX file whichSharedXMLPath as string
            end tell
        ]]
        local bool, _, _ = osascript.applescript(appleScript)
        return bool
    end
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--
-- SHORTCUTS
--
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

--- cp.apple.finalcutpro.userCommandSetPath() -> string or nil
--- Method
--- Gets the path where User Command Set files are stored.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A path as a string or `nil` if the folder doesn't exist.
function fcp.userCommandSetPath()
    local path = "~/Library/Application Support/Final Cut Pro/Command Sets/"
    local absolutePath = fs.pathToAbsolute(path)
    if absolutePath then
        return absolutePath
    else
        return nil
    end
end

--- cp.apple.finalcutpro:getActiveCommandSetPath() -> string or nil
--- Method
--- Gets the 'Active Command Set' value from the Final Cut Pro preferences
---
--- Parameters:
---  * None
---
--- Returns:
---  * The 'Active Command Set' value, or the 'Default' command set if none is set.
function fcp:getActiveCommandSetPath()
    local result = self:getPreference("Active Command Set") or nil
    if result == nil then
        -- In the unlikely scenario that this is the first time FCPX has been run:
        result = self:getDefaultCommandSetPath()
    end
    return result
end

--- cp.apple.finalcutpro:getDefaultCommandSetPath([locale]) -> string
--- Method
--- Gets the path to the 'Default' Command Set.
---
--- Parameters:
---  * `locale`	- The optional locale to use. Defaults to the [current locale](#currentLocale).
---
--- Returns:
---  * The 'Default' Command Set path, or `nil` if an error occurred
function fcp:getDefaultCommandSetPath(locale)
    locale = localeID(locale) or self:currentLocale()
    return self:getPath() .. "/Contents/Resources/" .. locale.code .. ".lproj/Default.commandset"
end

--- cp.apple.finalcutpro:getCommandSet(path) -> string
--- Method
--- Loads the Command Set at the specified path into a table.
---
--- Parameters:
---  * `path`	- The path to the command set.
---
--- Returns:
---  * The Command Set as a table, or `nil` if there was a problem.
-- TODO: This should be a function rather than a method.
function fcp:getCommandSet(path) -- luacheck: ignore
    if fs.attributes(path) ~= nil then
        return plist.fileToTable(path)
    end
end

--- cp.apple.finalcutpro:getActiveCommandSet([forceReload]) -> table or nil
--- Method
--- Returns the 'Active Command Set' as a Table. The result is cached, so pass in
--- `true` for `forceReload` if you want to reload it.
---
--- Parameters:
---  * [forceReload]	- If `true`, require the Command Set to be reloaded.
---
--- Returns:
---  * A table of the Active Command Set's contents, or `nil` if an error occurred
function fcp:getActiveCommandSet(forceReload)

    if forceReload or not self._activeCommandSet then
        local path = self:getActiveCommandSetPath()
        self._activeCommandSet = self:getCommandSet(path)
        -- reset the command cache since we've loaded a new set.
        if self._activeCommands then
            self._activeCommands = nil
        end
    end

    return self._activeCommandSet
end

--- cp.apple.finalcutpro.getCommandShortcuts(id) -> table of hs.commands.shortcut
--- Method
--- Finds a shortcut from the Active Command Set with the specified ID and returns a table
--- of `hs.commands.shortcut`s for the specified command, or `nil` if it doesn't exist.
---
--- Parameters:
---  * id - The unique ID for the command.
---
--- Returns:
---  * The array of shortcuts, or `nil` if no command exists with the specified `id`.
function fcp:getCommandShortcuts(id)
    local activeCommands = self._activeCommands
    if not activeCommands then
        activeCommands = {}
        self._activeCommands = activeCommands
    end

    local shortcuts = activeCommands[id]
    if not shortcuts then
        local commandSet = self:getActiveCommandSet()

        local fcpxCmds = commandSet[id]

        if fcpxCmds == nil then
            return nil
        end

        if #fcpxCmds == 0 then
            fcpxCmds = { fcpxCmds }
        end

        shortcuts = {}

        for _,fcpxCmd in ipairs(fcpxCmds) do
            local modifiers = nil
            local keyCode = nil
            local keypadModifier = false

            if fcpxCmd["modifiers"] ~= nil then
                if string.find(fcpxCmd["modifiers"], "keypad") then keypadModifier = true end
                modifiers = kc.fcpxModifiersToHsModifiers(fcpxCmd["modifiers"])
            elseif fcpxCmd["modifierMask"] ~= nil then
                modifiers = tools.modifierMaskToModifiers(fcpxCmd["modifierMask"])
                if tools.tableContains(modifiers, "numericpad") then
                    keypadModifier = true
                end
            end

            if fcpxCmd["characterString"] ~= nil then
                if keypadModifier then
                    keyCode = kc.keypadCharacterToKeyCode(fcpxCmd["characterString"])
                else
                    keyCode = kc.characterStringToKeyCode(fcpxCmd["characterString"])
                end
            elseif fcpxCmd["character"] ~= nil then
                if keypadModifier then
                    keyCode = kc.keypadCharacterToKeyCode(fcpxCmd["character"])
                else
                    keyCode = kc.characterStringToKeyCode(fcpxCmd["character"])
                end
            end

            if keyCode ~= nil and keyCode ~= "" then
                shortcuts[#shortcuts + 1] = shortcut.new(modifiers, keyCode)
            end
        end

        activeCommands[id] = shortcuts
    end
    return shortcuts
end

--- cp.apple.finalcutpro:performShortcut(whichShortcut) -> boolean
--- Method
--- Performs a Final Cut Pro Shortcut
---
--- Parameters:
---  * whichShortcut - As per the Command Set name
---
--- Returns:
---  * true if successful otherwise false
function fcp:performShortcut(whichShortcut)
    self:launch()
    local shortcuts = self:getCommandShortcuts(whichShortcut)

    if shortcuts and #shortcuts > 0 then
        shortcuts[1]:trigger()
    else
        return false
    end

    return true
end

----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------
--
-- LANGUAGE
--
----------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------

--- cp.apple.finalcutpro:isSupportedLocale(locale) -> boolean
--- Method
--- Checks if the provided `locale` is supported by the app.
---
--- Parameters:
---  * `language`	- The `cp.i18n.localeID` or string code. E.g. "en" or "zh_CN"
---
--- Returns:
---  * `true` if the locale is supported.
function fcp:isSupportedLocale(locale)
    return self.app:isSupportedLocale(locale)
end

--- cp.apple.finalcutpro:getFlexoLanguages() -> table
--- Method
--- Returns a table of languages Final Cut Pro's Flexo Framework supports
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of languages Final Cut Pro supports
-- TODO: This should be a function rather than a method.
function fcp:getFlexoLanguages() -- luacheck: ignore
    return fcp.FLEXO_LANGUAGES
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                               W A T C H E R S                              --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro:watch(events) -> string
--- Method
--- Watch for events that happen in the application.
--- The optional functions will be called when the window is shown or hidden, respectively.
---
--- Parameters:
---  * `events` - A table of functions with to watch. These may be:
--- 	* `active`		- Triggered when the application is the active application.
--- 	* `inactive`	- Triggered when the application is no longer the active application.
---     * `launched		- Triggered when the application is launched.
---     * `terminated	- Triggered when the application has been closed.
--- 	* `preferences`	- Triggered when the application preferences are updated.
---
--- Returns:
---  * An ID which can be passed to `unwatch` to stop watching.
function fcp:watch(events)
    return self._watchers:watch(events)
end

--- cp.apple.finalcutpro:unwatch(id) -> boolean
--- Method
--- Stop watching for events that happen in the application for the specified ID.
---
--- Parameters:
---  * `id` 	- The ID object which was returned from the `watch(...)` function.
---
--- Returns:
---  * `true` if the ID was watching and has been removed.
function fcp:unwatch(id)
    return self._watchers:unwatch(id)
end

-- cp.apple.finalcutpro:_initWatchers() -> none
-- Method
-- Initialise all the various Final Cut Pro Watchers.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function fcp:_initWatchers()

    if not self._watchers then
        --log.df("Setting up Final Cut Pro Watchers...")
        self._watchers = watcher.new("active", "inactive", "launched", "terminated", "preferences")
    end

    --------------------------------------------------------------------------------
    -- Final Cut Pro Window becomes visible:
    --------------------------------------------------------------------------------
    -- TODO: Move this to cp.app
    windowfilter:subscribe("windowVisible", function()
        fcp.isModalDialogOpen:update()
    end)
end

--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   D E V E L O P M E N T      T O O L S                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- cp.apple.finalcutpro._listWindows() -> none
-- Method
-- List Windows to Error Log.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function fcp:_listWindows()
    log.d("Listing FCPX windows:")
    self:show()
    local windows = self:windowsUI()
    for i,w in ipairs(windows) do
        log.df(format("%7d", i)..": "..self:_describeWindow(w))
    end

    log.df("")
    log.df("   Main: "..self:_describeWindow(self:UI():mainWindow()))
    log.df("Focused: "..self:_describeWindow(self:UI():focusedWindow()))
end

-- cp.apple.finalcutpro._describeWindow(w) -> string
-- Function
-- Returns a string containing information about the specified window.
--
-- Parameters:
--  * w - The window object.
--
-- Returns:
--  * A string
function fcp._describeWindow(w)
    return "title: "..inspect(w:attributeValue("AXTitle"))..
           "; role: "..inspect(w:attributeValue("AXRole"))..
           "; subrole: "..inspect(w:attributeValue("AXSubrole"))..
           "; modal: "..inspect(w:attributeValue("AXModal"))
end

return fcp:init()