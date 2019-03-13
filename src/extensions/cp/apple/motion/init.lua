--- === cp.apple.motion ===
---
--- Represents the Motion application, providing functions that allow different tasks to be accomplished.

local require = require

local app             = require("cp.apple.motion.app")
local prop					  = require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local motion = {
    app = app,
}

--- cp.apple.motion.BUNDLE_ID
--- Constant
--- Compressor's Bundle ID
motion.BUNDLE_ID = "com.apple.motionapp"

function motion:init()
    return self
end

prop.bind(motion) {
    --- cp.apple.motion.application <cp.prop: hs.application; read-only>
    --- Field
    --- Returns the running `hs.application` for Final Cut Pro, or `nil` if it's not running.
    application = app.hsApplication,

    --- cp.apple.motion.isRunning <cp.prop: boolean; read-only>
    --- Field
    --- Is Final Cut Pro Running?
    isRunning = app.running,

    --- cp.apple.motion.UI <cp.prop: hs._asm.axuielement; read-only; live>
    --- Field
    --- The Final Cut Pro `axuielement`, if available.
    UI = app.UI,

    --- cp.apple.motion.windowsUI <cp.prop: hs._asm.axuielement; read-only; live>
    --- Field
    --- Returns the UI containing the list of windows in the app.
    windowsUI = app.windowsUI,

    --- cp.apple.motion.isShowing <cp.prop: boolean; read-only; live>
    --- Field
    --- Is Final Cut visible on screen?
    isShowing = app.showing,

    --- cp.apple.motion.isInstalled <cp.prop: boolean; read-only>
    --- Field
    --- Is any version of Final Cut Pro Installed?
    isInstalled = app.installed,

    --- cp.apple.motion:isFrontmost <cp.prop: boolean; read-only; live>
    --- Field
    --- Is Final Cut Pro Frontmost?
    isFrontmost = app.frontmost,

    --- cp.apple.motion:isModalDialogOpen <cp.prop: boolean; read-only>
    --- Field
    --- Is a modal dialog currently open?
    isModalDialogOpen = app.modalDialogOpen,

    --- cp.apple.motion.isSupported <cp.prop: boolean; read-only; live>
    --- Field
    --- Is a supported version of Final Cut Pro installed?
    ---
    --- Note:
    ---  * Supported version refers to any version of Final Cut Pro equal or higher to `cp.apple.motion.EARLIEST_SUPPORTED_VERSION`
    isSupported = app.version:mutate(function(original)
        local version = original()
        return version ~= nil and version >= motion.EARLIEST_SUPPORTED_VERSION
    end),

    --- cp.apple.motion.supportedLocales <cp.prop: table of cp.i18n.localeID; read-only>
    --- Field
    --- The list of supported locales for this version of FCPX.
    supportedLocales = app.supportedLocales,

    --- cp.apple.motion.currentLocale <cp.prop: cp.i18n.localeID; live>
    --- Field
    --- Gets and sets the current locale for FCPX.
    currentLocale = app.currentLocale,

    --- cp.apple.motion.version <cp.prop: semver; read-only; live>
    --- Field
    --- The version number of the running or default installation of FCPX as a `semver`.
    version = app.version,

    --- cp.apple.motion.versionString <cp.prop: string; read-only; live>
    --- Field
    --- The version number of the running or default installation of FCPX as a `string`.
    versionString = app.versionString,
}

--- cp.apple.motion:bundleID() -> string
--- Method
--- Returns the Compressor Bundle ID
---
--- Parameters:
---  * None
---
--- Returns:
---  * A string of the Compressor Bundle ID
function motion:bundleID()
    return self.app:bundleID()
end

--- cp.apple.motion:notifier() -> cp.ui.notifier
--- Method
--- Returns a notifier that is tracking the application UI element. It has already been started.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The notifier.
function motion:notifier()
    return self.app:notifier()
end

--- cp.apple.motion:launch([waitSeconds]) -> self
--- Method
--- Launches Compressor, or brings it to the front if it was already running.
---
--- Parameters:
---  * waitSeconds      - if provided, we will wait for up to the specified seconds for the launch to complete.
---
--- Returns:
---  * `true` if Compressor was either launched or focused, otherwise false (e.g. if Compressor doesn't exist)
function motion:launch(waitSeconds)
    self.app:launch(waitSeconds)
    return self
end


function motion:doLaunch()
    return self.app:doLaunch()
end

--- cp.apple.motion:doRestart() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will restart the application.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if the application was running and restarted successfully.
function motion:doRestart()
    return self.app:doRestart()
end

--- cp.apple.motion:show() -> self
--- Method
--- Activate Compressor
---
--- Parameters:
---  * None
---
--- Returns:
---  * The motion instance.
function motion:show()
    self.app:show()
    return self
end

function motion:doShow()
    return self.app:doShow()
end

--- cp.apple.motion:hide() -> self
--- Method
--- Hides Compressor
---
--- Parameters:
---  * None
---
--- Returns:
---  * The motion instance.
function motion:hide()
    self.app:hide()
    return self
end

function motion:doHide()
    return self.app:doHide()
end

--- cp.apple.motion:quit([waitSeconds]) -> self
--- Method
--- Quits Compressor
---
--- Parameters:
---  * waitSeconds  - if provided, we will wait for the specified time for the quit to complete before returning.
---
--- Returns:
---  * The `motion` instance.
function motion:quit(waitSeconds)
    self.app:quit(waitSeconds)
    return self
end

function motion:doQuit()
    return self.app:doQuit()
end

--- cp.apple.motion:path() -> string or nil
--- Method
--- Path to Compressor Application
---
--- Parameters:
---  * None
---
--- Returns:
---  * A string containing Compressor's filesystem path, or `nil` if the bundle identifier could not be located
function motion:getPath()
    return self.app:path()
end

setmetatable(motion, {
    __tostring = function() return "cp.apple.motion" end
})

return motion
