--- === cp.apple.finalcutpro ===
---
--- Represents the Final Cut Pro application, providing functions that allow different tasks to be accomplished.
---
--- Generally, you will `require` the `cp.apple.finalcutpro` module to import it, like so:
---
--- ```lua
--- local fcp = require("cp.apple.finalcutpro")
--- ```
---
--- Then, there are the `UpperCase` files, which represent the application itself:
---
--- * `MenuBar` 	            - The main menu bar.
--- * `prefs/PreferencesWindow` - The preferences window.
--- * etc...
---
--- The `fcp` variable is the root application. It has functions which allow you to perform tasks or access parts of the UI. For example, to open the `Preferences` window, you can do this:
---
--- ```lua
--- fcp:preferencesWindow():show()
--- ```
---
--- In general, as long as Final Cut Pro is running, actions can be performed directly, and the API will perform the required operations to achieve it. For example, to toggle the 'Create Optimized Media' checkbox in the 'Import' section of the 'Preferences' window, you can simply do this:
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

local require = require

local log										= require("hs.logger").new("fcp")

local fs 										= require("hs.fs")
local hsplist                                   = require("hs.plist")
local inspect									= require("hs.inspect")
local osascript 								= require("hs.osascript")
local pathwatcher                               = require("hs.pathwatcher")

local axutils                                   = require("cp.ui.axutils")
local config                                    = require("cp.config")
local go                                        = require("cp.rx.go")
local i18n                                      = require("cp.i18n")
local just										= require("cp.just")
local localeID                                  = require("cp.i18n.localeID")
local plist										= require("cp.plist")
local prop										= require("cp.prop")
local Set                                       = require("cp.collect.Set")

local commandeditor								= require("cp.apple.commandeditor")

local app                                       = require("cp.apple.finalcutpro.app")
local strings                                   = require("cp.apple.finalcutpro.strings")
local menu                                      = require("cp.apple.finalcutpro.menu")
local plugins									= require("cp.apple.finalcutpro.plugins")

local Browser									= require("cp.apple.finalcutpro.main.Browser")
local FullScreenWindow							= require("cp.apple.finalcutpro.main.FullScreenWindow")
local KeywordEditor								= require("cp.apple.finalcutpro.main.KeywordEditor")
local PrimaryWindow								= require("cp.apple.finalcutpro.main.PrimaryWindow")
local SecondaryWindow							= require("cp.apple.finalcutpro.main.SecondaryWindow")
local Timeline									= require("cp.apple.finalcutpro.timeline.Timeline")
local Viewer									= require("cp.apple.finalcutpro.viewer.Viewer")

local CommandEditor								= require("cp.apple.finalcutpro.cmd.CommandEditor")
local ExportDialog								= require("cp.apple.finalcutpro.export.ExportDialog")
local MediaImport								= require("cp.apple.finalcutpro.import.MediaImport")
local PreferencesWindow							= require("cp.apple.finalcutpro.prefs.PreferencesWindow")
local FindAndReplaceTitleText	                = require("cp.apple.finalcutpro.main.FindAndReplaceTitleText")

local v											= require("semver")
local class                                     = require("middleclass")
local lazy                                      = require("cp.lazy")

local format, gsub 						        = string.format, string.gsub
local Do, Throw                                 = go.Do, go.Throw

local childMatching                             = axutils.childMatching

-- a Non-Breaking Space. Looks like a space, isn't a space.
local NBSP = " "

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local fcp = class("finalcutpro"):include(lazy)

function fcp:initialize()
--- cp.apple.finalcutpro.app <cp.app>
--- Constant
--- The `cp.app` for Final Cut Pro.
    self.app = app

--- cp.apple.finalcutpro.preferences <cp.app.prefs>
--- Constant
--- The `cp.app.prefs` for Final Cut Pro.
    self.preferences = app.preferences

--- cp.apple.finalcutpro.strings <cp.strings>
--- Constant
--- The `cp.strings` providing access to common FCPX text values.
    self.strings = strings

    app:update()

    --------------------------------------------------------------------------------
    -- Refresh Command Set Cache if a Command Set is modified:
    --------------------------------------------------------------------------------
    local userCommandSetPath = fcp.userCommandSetPath()
    if userCommandSetPath then
        --log.df("Setting up User Command Set Watcher: %s", userCommandSetPath)
        self.userCommandSetWatcher = pathwatcher.new(userCommandSetPath .. "/", function()
            --log.df("Updating Final Cut Pro Command Editor Cache.")
            self.activeCommandSet:update()
        end):start()
    end

end

-- cleanup
function fcp:__gc()
    if self.userCommandSetWatcher then
        self.userCommandSetWatcher:stop()
        self.userCommandSetWatcher = nil
    end
end

-- tostring
function fcp.__tostring() return "cp.apple.finalcutpro" end

--- cp.apple.finalcutpro.BUNDLE_ID -> string
--- Constant
--- Final Cut Pro's Bundle ID as a `semver`.
fcp.BUNDLE_ID = "com.apple.FinalCut"

--- cp.apple.finalcutpro.EARLIEST_SUPPORTED_VERSION -> string
--- Constant
--- The earliest version of Final Cut Pro supported by this module.
fcp.EARLIEST_SUPPORTED_VERSION = v("10.4.4")

--- cp.apple.finalcutpro.PASTEBOARD_UTI -> string
--- Constant
--- Final Cut Pro's Pasteboard UTI
fcp.PASTEBOARD_UTI = "com.apple.flexo.proFFPasteboardUTI"

--- cp.apple.finalcutpro.EVENT_DESCRIPTION_PATH -> string
--- Constant
--- The Event Description Path.
fcp.EVENT_DESCRIPTION_PATH = "/Contents/Frameworks/TLKit.framework/Versions/A/Resources/EventDescriptions.plist"

--- cp.apple.finalcutpro.FLEXO_LANGUAGES -> table
--- Constant
--- Table of Final Cut Pro's supported Languages for the Flexo Framework
fcp.FLEXO_LANGUAGES	= Set("de", "en", "es_419", "es", "fr", "id", "ja", "ms", "vi", "zh_CN")

--- cp.apple.finalcutpro.ALLOWED_IMPORT_VIDEO_EXTENSIONS -> table
--- Constant
--- Table of video file extensions Final Cut Pro can import.
fcp.ALLOWED_IMPORT_VIDEO_EXTENSIONS	= Set("3gp", "avi", "mov", "mp4", "mts", "m2ts", "mxf", "m4v", "r3d")

--- cp.apple.finalcutpro.ALLOWED_IMPORT_AUDIO_EXTENSIONS -> table
--- Constant
--- Table of audio file extensions Final Cut Pro can import.
fcp.ALLOWED_IMPORT_AUDIO_EXTENSIONS	= Set("aac", "aiff", "aif", "bwf", "caf", "mp3", "mp4", "wav")

--- cp.apple.finalcutpro.ALLOWED_IMPORT_IMAGE_EXTENSIONS -> table
--- Constant
--- Table of image file extensions Final Cut Pro can import.
fcp.ALLOWED_IMPORT_IMAGE_EXTENSIONS	= Set("bmp", "gif", "jpeg", "jpg", "png", "psd", "raw", "tga", "tiff", "tif")

--- cp.apple.finalcutpro.ALLOWED_IMPORT_EXTENSIONS -> table
--- Constant
--- Table of all file extensions Final Cut Pro can import.
fcp.ALLOWED_IMPORT_ALL_EXTENSIONS = fcp.ALLOWED_IMPORT_VIDEO_EXTENSIONS + fcp.ALLOWED_IMPORT_AUDIO_EXTENSIONS + fcp.ALLOWED_IMPORT_IMAGE_EXTENSIONS

--------------------------------------------------------------------------------
-- Bind the `cp.app` props to the Final Cut Pro instance for easy
-- access/backwards compatibility:
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.application <cp.prop: hs.application; read-only>
--- Field
--- Returns the running `hs.application` for Final Cut Pro, or `nil` if it's not running.
function fcp.lazy.prop:application()
    return self.app.hsApplication
end

--- cp.apple.finalcutpro.isRunning <cp.prop: boolean; read-only>
--- Field
--- Is Final Cut Pro Running?
function fcp.lazy.prop:isRunning()
    return self.app.running
end

--- cp.apple.finalcutpro.UI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- The Final Cut Pro `axuielement`, if available.
function fcp.lazy.prop:UI()
    return self.app.UI
end

--- cp.apple.finalcutpro.windowsUI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- Returns the UI containing the list of windows in the app.
function fcp.lazy.prop:windowsUI()
    return self.app.windowsUI
end

--- cp.apple.finalcutpro.isShowing <cp.prop: boolean; read-only; live>
--- Field
--- Is Final Cut visible on screen?
function fcp.lazy.prop:isShowing()
    return self.app.showing
end

--- cp.apple.finalcutpro.isInstalled <cp.prop: boolean; read-only>
--- Field
--- Is any version of Final Cut Pro Installed?
function fcp.lazy.prop:isInstalled()
    return self.app.installed
end

--- cp.apple.finalcutpro:isFrontmost <cp.prop: boolean; read-only; live>
--- Field
--- Is Final Cut Pro Frontmost?
function fcp.lazy.prop:isFrontmost()
    return self.app.frontmost
end

--- cp.apple.finalcutpro:isModalDialogOpen <cp.prop: boolean; read-only>
--- Field
--- Is a modal dialog currently open?
function fcp.lazy.prop:isModalDialogOpen()
    return self.app.modalDialogOpen
end

--- cp.apple.finalcutpro.isSupported <cp.prop: boolean; read-only; live>
--- Field
--- Is a supported version of Final Cut Pro installed?
---
--- Note:
---  * Supported version refers to any version of Final Cut Pro equal or higher to `cp.apple.finalcutpro.EARLIEST_SUPPORTED_VERSION`
function fcp.lazy.prop:isSupported()
    return self.app.version:mutate(function(original)
        local version = original()
        return version ~= nil and version >= fcp.EARLIEST_SUPPORTED_VERSION
    end)
end

--- cp.apple.finalcutpro.supportedLocales <cp.prop: table of cp.i18n.localeID; read-only>
--- Field
--- The list of supported locales for this version of FCPX.
function fcp.lazy.prop:supportedLocales()
    return self.app.supportedLocales
end

--- cp.apple.finalcutpro.currentLocale <cp.prop: cp.i18n.localeID; live>
--- Field
--- Gets and sets the current locale for FCPX.
function fcp.lazy.prop:currentLocale()
    return self.app.currentLocale
end

--- cp.apple.finalcutpro.version <cp.prop: semver; read-only; live>
--- Field
--- The version number of the running or default installation of FCPX as a `semver`.
function fcp.lazy.prop:version()
    return self.app.version
end

--- cp.apple.finalcutpro.versionString <cp.prop: string; read-only; live>
--- Field
--- The version number of the running or default installation of FCPX as a `string`.
function fcp.lazy.prop:versionString()
    return self.app.versionString
end

--- cp.apple.finalcutpro.isUnsupported <cp.prop: boolean; read-only>
--- Field
--- Is an unsupported version of Final Cut Pro installed?
---
--- Note:
---  * Supported version refers to any version of Final Cut Pro equal or higher to cp.apple.finalcutpro.EARLIEST_SUPPORTED_VERSION
function fcp.lazy.prop:isUnsupported()
    return self.isInstalled:AND(self.isSupported:NOT())
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
    return self.app:notifier()
end

--- cp.apple.finalcutpro:launch([waitSeconds], [path]) -> self
--- Method
--- Launches Final Cut Pro, or brings it to the front if it was already running.
---
--- Parameters:
---  * `waitSeconds` - If provided, the number of seconds to wait until the launch
---                    completes. If `nil`, it will return immediately.
---  * `path`        - An optional full path to an application without an extension
---                    (i.e `/Applications/Final Cut Pro 10.3.4`). This allows you to
---                    load previous versions of the application.
---
--- Returns:
---  * The FCP instance.
function fcp:launch(waitSeconds, path)
    self.app:launch(waitSeconds, path)
    return self
end

--- cp.apple.finalcutpro:doLaunch() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will launch, or focus it if already running FCP.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement` to execute.
function fcp.lazy.method:doLaunch()
    return self.app:doLaunch()
end

--- cp.apple.finalcutpro:doRestart() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.cp) that will restart Final Cut Pro, if it is running. If not, nothing happens.
---
--- Parameters:
---  * None.
---
--- Returns:
---  * The FCP instance.
function fcp.lazy.method:doRestart()
    return self.app:doRestart()
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

--- cp.apple.finalcutpro:doShow() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will show FCP on-screen.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement` to execute.
function fcp.lazy.method:doShow()
    return self.app:doShow()
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
    return self
end

--- cp.apple.finalcutpro:doHide() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will hide the FCP.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement` to execute.
function fcp.lazy.method:doHide()
    return self.app:doHide()
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

--- cp.apple.finalcutpro:doQuit() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will quit FCP.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement` to execute.
function fcp.lazy.method:doQuit()
    return self.app:doQuit()
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
--
-- LIBRARIES
--
----------------------------------------------------------------------------------------

--- cp.apple.finalcutpro:activeLibraryPaths() -> table
--- Method
--- Gets a table of all the active library paths.
---
--- Parameters:
--- * None
---
--- Returns:
--- * A table containing any active library paths.
function fcp.activeLibraryPaths()
    local paths = {}
    local fcpPlist = hsplist.read("~/Library/Preferences/" .. fcp.BUNDLE_ID .. ".plist")
    local FFActiveLibraries = fcpPlist and fcpPlist.FFActiveLibraries
    if FFActiveLibraries and #FFActiveLibraries >= 1 then
        for i=1, #FFActiveLibraries do
            local activeLibrary = FFActiveLibraries[i]
            local path = fs.getPathFromBookmark(activeLibrary)
            table.insert(paths, path)
        end
    end
    return paths
end

--- cp.apple.finalcutpro:openLibrary(path) -> boolean
--- Method
--- Attempts to open a file at the specified absolute `path`.
---
--- Parameters:
--- * path	- The path to the FCP Library to open.
---
--- Returns:
--- * `true` if successful, or `false` if not.
function fcp.openLibrary(_, path)
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
        --------------------------------------------------------------------------------
        -- Waiting here for a couple of seconds seems to make it less likely to
        -- crash Final Cut Pro:
        --------------------------------------------------------------------------------
        just.wait(2.0)
        if libraries:selectLibrary(title) ~= nil then
            just.wait(1.0)
            local closeLibrary = self:string("FFCloseLibraryFormat")
            if closeLibrary then
                -- some languages contain NBSPs instead of spaces, but these don't survive to the actual menu title. Swap them out.
                closeLibrary = gsub(closeLibrary, "%%@", title):gsub(NBSP, " ")
            end

            self:selectMenu({"File", function(item)
                local itemTitle = item:title():gsub(NBSP, " ")
                local result = itemTitle == closeLibrary
                return result
            end})
            --------------------------------------------------------------------------------
            -- Wait until the library actually closes, up to 10 seconds:
            --------------------------------------------------------------------------------
            return just.doUntil(function() return libraries:show():selectLibrary(title) == nil end, 10.0)
        end
    end
    return false
end

----------------------------------------------------------------------------------------
--
-- SCAN PLUGINS
--
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
function fcp.lazy.method:plugins()
    return plugins.new(self)
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
--
-- MENU BAR
--
----------------------------------------------------------------------------------------

--- cp.apple.finalcutpro:menu() -> cp.app.menu
--- Method
--- Returns the `cp.app.menu` for FCP.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.app.menu` for the app.
function fcp.lazy.method.menu()
    return menu
end

--- cp.apple.finalcutpro:selectMenu(path[, options]) -> boolean
--- Method
--- Selects a Final Cut Pro Menu Item based on the list of menu titles in English.
---
--- Parameters:
---  * `path`	    - The list of menu items you'd like to activate, for example:
---            select("View", "Browser", "as List")
---  * `options`    - (optional) The table of options. See `cp.app.menu:selectMenu(...)` for details.
---
--- Returns:
---  * `true` if the press was successful.
function fcp:selectMenu(path, options)
    return self:menu():selectMenu(path, options)
end

--- cp.apple.finalcutpro:doSelectMenu(path, options) -> cp.rx.Observable <hs._asm.axuielement>
--- Method
--- Selects a Menu Item based on the provided menu path.
---
--- Each step on the path can be either one of:
---  * a string     - The exact name of the menu item.
---  * a number     - The menu item number, starting from 1.
---  * a function   - Passed one argument - the Menu UI to check - returning `true` if it matches.
---
--- Options supported include:
---  * locale - The `localeID` or `string` for the locale that the path values are in.
---  * pressAll - If `true`, all menu items will be pressed on the way to the final destination.
---  * timeout - The maximum time to wait for the menu to be available before producing an error. Defaults to 10 seconds.
---
--- Examples:
---
--- ```lua
--- local preview = require("cp.app").forBundleID("com.apple.Preview")
--- preview:launch():menu():doSelectMenu({"File", "Take Screenshot", "From Entire Screen"}):Now()
--- ```
---
--- Parameters:
---  * path - The list of menu items you'd like to activate.
---  * options - (optional) The table of options to apply.
---
--- Returns:
---  * An `Observable` which emits the final menu item, or an error if the selection failed.
---
--- Notes:
---  * The returned `Observable` will be 'hot', in that it will execute even if no subscription is made to the result. However, it will potentially be run asynchronously, so the actual execution may occur later.
function fcp:doSelectMenu(...)
    return self.app:menu():doSelectMenu(...)
end

----------------------------------------------------------------------------------------
--
-- WORKSPACES
--
----------------------------------------------------------------------------------------

--- cp.apple.finalcutpro.selectedWorkspace <cp.prop: string; live>
--- Variable
--- The currently selected workspace name. The result is cached, but updated
--- automatically if the window layout changes.
function fcp.lazy.prop:selectedWorkspace()
    return prop(function()
        local workspacesUI = self:menu():findMenuUI({"Window", "Workspaces"})
        local children = workspacesUI and workspacesUI[1] and workspacesUI[1]:attributeValue("AXChildren")
        local selected = children and childMatching(children, function(menuItem)
            return menuItem:attributeValue("AXMenuItemMarkChar") ~= nil
        end)
        return selected and selected:attributeValue("AXTitle")
    end)
    :cached()
    :monitor(self.app.windowsUI)
end

----------------------------------------------------------------------------------------
--
-- WINDOWS
--
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
function fcp.lazy.method:preferencesWindow()
    return PreferencesWindow.new(self)
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
function fcp.lazy.method:primaryWindow()
    return PrimaryWindow(self)
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
function fcp.lazy.method:secondaryWindow()
    return SecondaryWindow(self)
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
function fcp.lazy.method:fullScreenWindow()
    return FullScreenWindow.new(self)
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
function fcp.lazy.method:commandEditor()
    return CommandEditor.new(self)
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
function fcp.lazy.method:keywordEditor()
    return KeywordEditor.new(self)
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
function fcp.lazy.method:mediaImport()
    return MediaImport.new(self)
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
function fcp.lazy.method:exportDialog()
    return ExportDialog.new(self)
end

--- cp.apple.finalcutpro:findAndReplaceTitleText() -> FindAndReplaceTitleText
--- Method
--- Returns the [FindAndReplaceTitleText](cp.apple.finalcutpro.main.FindAndReplaceTitleText.md) dialog window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The window.
function fcp.lazy.method:findAndReplaceTitleText()
    return FindAndReplaceTitleText(self.app)
end

----------------------------------------------------------------------------------------
--
-- APP SECTIONS
--
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
function fcp.lazy.method:timeline()
    return Timeline(self)
end

--- cp.apple.finalcutpro.viewer <cp.apple.finalcutpro.viewer.Viewer>
--- Field
--- Returns the [Viewer](cp.apple.finalcutpro.viewer.Viewer.md) instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the Viewer
function fcp.lazy.value:viewer()
    return Viewer(self, false)
end

--- cp.apple.finalcutpro.eventViewer <cp.apple.finalcutpro.viewer.Viewer>
--- Field
--- Returns the [Viewer](cp.apple.finalcutpro.viewer.Viewer.md) instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the Event Viewer
function fcp.lazy.value:eventViewer()
    return Viewer(self, true)
end

--- cp.apple.finalcutpro.browser <cp.apple.finalcutpro.main.Browser>
--- Field
--- The [Browser](cp.apple.finalcutpro.main.Browser.md) instance, whether it is in the primary or secondary window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the Browser
function fcp.lazy.value:browser()
    return Browser(self)
end

--- cp.apple.finalcutpro.libraries <cp.apple.finalcutpro.main.LibrariesBrowser>
--- Field
--- Returns the [LibrariesBrowser](cp.apple.finalcut.main.LibrariesBrowser.md) instance, whether it is in the primary or secondary window.
function fcp.lazy.value:libraries()
    return self.browser.libraries
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
function fcp.lazy.method:media()
    return self.browser.media()
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
function fcp.lazy.method:generators()
    return self.browser.generators()
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
function fcp.lazy.method:effects()
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
function fcp.lazy.method:transitions()
    return self:timeline():transitions()
end

--- cp.apple.finalcutpro.inspector <cp.apple.finalcutpro.inspector.Inspector>
--- Field
--- Returns the [Inspector](cp.apple.finalcutpro.inspector.Inspector.md) instance from the primary window.
function fcp.lazy.value:inspector()
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
function fcp.lazy.method:colorBoard()
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
function fcp.lazy.method:color()
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
function fcp.lazy.method:alert()
    return self:primaryWindow():alert()
end

----------------------------------------------------------------------------------------
--
-- PREFERENCES, SETTINGS, XML
--
----------------------------------------------------------------------------------------

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
--
-- SHORTCUTS
--
----------------------------------------------------------------------------------------

--- cp.apple.finalcutpro.userCommandSetPath() -> string or nil
--- Function
--- Gets the path where User Command Set files are stored.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A path as a string or `nil` if the folder doesn't exist.
function fcp.static.userCommandSetPath()
    return fs.pathToAbsolute("~/Library/Application Support/Final Cut Pro/Command Sets/")
end

--- cp.apple.finalcutpro:defaultCommandSetPath([locale]) -> string
--- Method
--- Gets the path to the 'Default' Command Set.
---
--- Parameters:
---  * `locale`	- The optional locale to use. Defaults to the [current locale](#currentLocale).
---
--- Returns:
---  * The 'Default' Command Set path, or `nil` if an error occurred
function fcp:defaultCommandSetPath(locale)
    locale = localeID(locale) or self:currentLocale()
    return self:getPath() .. "/Contents/Resources/" .. locale.code .. ".lproj/Default.commandset"
end

--- cp.apple.finalcutpro.activeCommandSetPath <cp.prop: string>
--- Field
--- Gets the 'Active Command Set' value from the Final Cut Pro preferences
function fcp.lazy.prop:activeCommandSetPath()
    return self.preferences:prop("Active Command Set", self:defaultCommandSetPath())
end

--- cp.apple.finalcutpro.commandSet(path) -> string
--- Function
--- Gets the Command Set at the specified path as a table.
---
--- Parameters:
---  * `path`	- The path to the Command Set.
---
--- Returns:
---  * The Command Set as a table, or `nil` if there was a problem.
function fcp.static.commandSet(path)
    if not fs.attributes(path) then
        log.ef("Invalid Command Set Path: %s", path)
        return nil
    else
        return plist.fileToTable(path)
    end
end

--- cp.apple.finalcutpro.activeCommandSet <cp.prop: table; live>
--- Variable
--- Contins the 'Active Command Set' as a `table`. The result is cached, but
--- updated automatically if the command set changes.
function fcp.lazy.prop:activeCommandSet()
    return prop(function()
        local path = self:activeCommandSetPath()
        local commandSet = fcp.commandSet(path)
        ----------------------------------------------------------------------------------------
        -- Reset the command cache since we've loaded a new set:
        ----------------------------------------------------------------------------------------
        self._activeCommands = nil

        return commandSet
    end)
    :cached()
    :monitor(self.activeCommandSetPath)
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
    if type(id) ~= "string" then
        log.ef("ID is required for cp.apple.finalcutpro.getCommandShortcuts.")
        return nil
    end
    local activeCommands = self._activeCommands or {}
    local shortcuts = activeCommands[id]
    if not shortcuts then
        local commandSet = self:activeCommandSet()
        shortcuts = commandeditor.shortcutsFromCommandSet(id, commandSet)
        if not shortcuts then
            return nil
        end
        ----------------------------------------------------------------------------------------
        -- Cache the value for faster access next time:
        ----------------------------------------------------------------------------------------
        if not self._activeCommands then
            self._activeCommands = {}
        end
        self._activeCommands[id] = shortcuts
    end
    return shortcuts
end

--- cp.apple.finalcutpro:doShortcut(whichShortcut) -> Statement
--- Method
--- Perform a Final Cut Pro Keyboard Shortcut
---
--- Parameters:
---  * whichShortcut - As per the Command Set name
---
--- Returns:
---  * A `Statement` that will perform the shortcut when executed.
function fcp:doShortcut(whichShortcut)
    return Do(self:doLaunch())
    :Then(function()
        local shortcuts = self:getCommandShortcuts(whichShortcut)
        if shortcuts and #shortcuts > 0 then
            shortcuts[1]:trigger()
            return true
        else
            return Throw(i18n("fcpShortcut_NoShortcutAssigned", {id=whichShortcut}))
        end
    end)
    :ThenYield()
    :Label("fcp:doShortcut:"..whichShortcut)
end

----------------------------------------------------------------------------------------
--
-- LANGUAGE
--
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

--------------------------------------------------------------------------------
--
-- DEVELOPMENT TOOLS
--
--------------------------------------------------------------------------------

-- cp.apple.finalcutpro:searchResources(value) -> hs.task
-- Method
-- Searches the resources inside the FCP app for the specified value.
--
-- Parameters:
-- * value      - The value to search for.
--
-- Returns:
-- * The `hs.task` that is running the search.
function fcp:searchResources(value)
    return self.app:searchResources(value)
end

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

local result = fcp()

-- Add `cp.dev.fcp` when in developer mode.
if config.developerMode() then
    local dev = require("cp.dev")
    dev.fcp = result
end

return result
