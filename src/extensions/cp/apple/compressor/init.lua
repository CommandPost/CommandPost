--- === cp.apple.compressor ===
---
--- Represents the Compressor application, providing functions that allow different tasks to be accomplished.

local require       = require

local fnutils       = require "hs.fnutils"

local app           = require "cp.apple.compressor.app"
local prop			= require "cp.prop"

local v             = require "semver"

local compressor = {
    app = app,
}

--- cp.apple.compressor.BUNDLE_ID
--- Constant
--- Compressor's Bundle ID
compressor.BUNDLE_ID = "com.apple.Compressor"

--- cp.apple.compressor.ALLOWED_IMPORT_VIDEO_EXTENSIONS
--- Constant
--- Table of video file extensions Final Cut Pro can import.
compressor.ALLOWED_IMPORT_VIDEO_EXTENSIONS = {"3gp", "avi", "mov", "mp4", "mts", "m2ts", "mxf", "m4v", "r3d"}

--- cp.apple.compressor.ALLOWED_IMPORT_AUDIO_EXTENSIONS
--- Constant
--- Table of audio file extensions Final Cut Pro can import.
compressor.ALLOWED_IMPORT_AUDIO_EXTENSIONS	= {"aac", "aiff", "aif", "bwf", "caf", "mp3", "mp4", "wav"}

--- cp.apple.compressor.ALLOWED_IMPORT_IMAGE_EXTENSIONS
--- Constant
--- Table of image file extensions Final Cut Pro can import.
compressor.ALLOWED_IMPORT_IMAGE_EXTENSIONS = {"bmp", "gif", "jpeg", "jpg", "png", "psd", "raw", "tga", "tiff", "tif"}

--- cp.apple.compressor.ALLOWED_IMPORT_ALL_EXTENSIONS
--- Constant
--- Table of all file extensions Final Cut Pro can import.
compressor.ALLOWED_IMPORT_ALL_EXTENSIONS = fnutils.concat(compressor.ALLOWED_IMPORT_VIDEO_EXTENSIONS, fnutils.concat(compressor.ALLOWED_IMPORT_AUDIO_EXTENSIONS, compressor.ALLOWED_IMPORT_IMAGE_EXTENSIONS))

--- cp.apple.compressor.EARLIEST_SUPPORTED_VERSION <semver>
--- Constant
--- The earliest version this API supports.
compressor.EARLIEST_SUPPORTED_VERSION = v("4.3")

function compressor:init()
    return self
end

prop.bind(compressor) {
    --- cp.apple.compressor.application <cp.prop: hs.application; read-only>
    --- Field
    --- Returns the running `hs.application` for Final Cut Pro, or `nil` if it's not running.
    application = app.hsApplication,

    --- cp.apple.compressor.isRunning <cp.prop: boolean; read-only>
    --- Field
    --- Is Final Cut Pro Running?
    isRunning = app.running,

    --- cp.apple.compressor.UI <cp.prop: hs.axuielement; read-only; live>
    --- Field
    --- The Final Cut Pro `axuielement`, if available.
    UI = app.UI,

    --- cp.apple.compressor.windowsUI <cp.prop: hs.axuielement; read-only; live>
    --- Field
    --- Returns the UI containing the list of windows in the app.
    windowsUI = app.windowsUI,

    --- cp.apple.compressor.isShowing <cp.prop: boolean; read-only; live>
    --- Field
    --- Is Final Cut visible on screen?
    isShowing = app.showing,

    --- cp.apple.compressor.isInstalled <cp.prop: boolean; read-only>
    --- Field
    --- Is any version of Final Cut Pro Installed?
    isInstalled = app.installed,

    --- cp.apple.compressor:isFrontmost <cp.prop: boolean; read-only; live>
    --- Field
    --- Is Final Cut Pro Frontmost?
    isFrontmost = app.frontmost,

    --- cp.apple.compressor:isModalDialogOpen <cp.prop: boolean; read-only>
    --- Field
    --- Is a modal dialog currently open?
    isModalDialogOpen = app.modalDialogOpen,

    --- cp.apple.compressor.isSupported <cp.prop: boolean; read-only; live>
    --- Field
    --- Is a supported version of Final Cut Pro installed?
    ---
    --- Note:
    ---  * Supported version refers to any version of Final Cut Pro equal or higher to `cp.apple.compressor.EARLIEST_SUPPORTED_VERSION`
    isSupported = app.version:mutate(function(original)
        local version = original()
        return version ~= nil and version >= compressor.EARLIEST_SUPPORTED_VERSION
    end),

    --- cp.apple.compressor.supportedLocales <cp.prop: table of cp.i18n.localeID; read-only>
    --- Field
    --- The list of supported locales for this version of FCPX.
    supportedLocales = app.supportedLocales,

    --- cp.apple.compressor.currentLocale <cp.prop: cp.i18n.localeID; live>
    --- Field
    --- Gets and sets the current locale for FCPX.
    currentLocale = app.currentLocale,

    --- cp.apple.compressor.version <cp.prop: semver; read-only; live>
    --- Field
    --- The version number of the running or default installation of FCPX as a `semver`.
    version = app.version,

    --- cp.apple.compressor.versionString <cp.prop: string; read-only; live>
    --- Field
    --- The version number of the running or default installation of FCPX as a `string`.
    versionString = app.versionString,
}

--- cp.apple.compressor:bundleID() -> string
--- Method
--- Returns the Compressor Bundle ID
---
--- Parameters:
---  * None
---
--- Returns:
---  * A string of the Compressor Bundle ID
function compressor:bundleID()
    return self.app:bundleID()
end

--- cp.apple.compressor:notifier() -> cp.ui.notifier
--- Method
--- Returns a notifier that is tracking the application UI element. It has already been started.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The notifier.
function compressor:notifier()
    return self.app:notifier()
end

--- cp.apple.compressor:launch([waitSeconds]) -> self
--- Method
--- Launches Compressor, or brings it to the front if it was already running.
---
--- Parameters:
---  * waitSeconds      - if provided, we will wait for up to the specified seconds for the launch to complete.
---
--- Returns:
---  * `true` if Compressor was either launched or focused, otherwise false (e.g. if Compressor doesn't exist)
function compressor:launch(waitSeconds)
    self.app:launch(waitSeconds)
    return self
end


function compressor:doLaunch()
    return self.app:doLaunch()
end

--- cp.apple.compressor:doRestart() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will restart the application.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if the application was running and restarted successfully.
function compressor:doRestart()
    return self.app:doRestart()
end

--- cp.apple.compressor:show() -> self
--- Method
--- Activate Compressor
---
--- Parameters:
---  * None
---
--- Returns:
---  * The compressor instance.
function compressor:show()
    self.app:show()
    return self
end

function compressor:doShow()
    return self.app:doShow()
end

--- cp.apple.compressor:hide() -> self
--- Method
--- Hides Compressor
---
--- Parameters:
---  * None
---
--- Returns:
---  * The compressor instance.
function compressor:hide()
    self.app:hide()
    return self
end

function compressor:doHide()
    return self.app:doHide()
end

--- cp.apple.compressor:quit([waitSeconds]) -> self
--- Method
--- Quits Compressor
---
--- Parameters:
---  * waitSeconds  - if provided, we will wait for the specified time for the quit to complete before returning.
---
--- Returns:
---  * The `compressor` instance.
function compressor:quit(waitSeconds)
    self.app:quit(waitSeconds)
    return self
end

function compressor:doQuit()
    return self.app:doQuit()
end

--- cp.apple.compressor:path() -> string or nil
--- Method
--- Path to Compressor Application
---
--- Parameters:
---  * None
---
--- Returns:
---  * A string containing Compressor's filesystem path, or `nil` if the bundle identifier could not be located
function compressor:getPath()
    return self.app:path()
end

setmetatable(compressor, {
    __tostring = function() return "cp.apple.compressor" end
})

return compressor
