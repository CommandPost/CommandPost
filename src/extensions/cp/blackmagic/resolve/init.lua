--- === cp.blackmagic.resolve ===
---
--- The Blackmagic DaVinci Resolve Extension.

local require           = require

local app               = require("cp.blackmagic.resolve.app")
local prop			    = require("cp.prop")
local lazy              = require("cp.lazy")

local PrimaryWindow     = require("cp.blackmagic.resolve.main.PrimaryWindow")

local Color			    = require("cp.blackmagic.resolve.color.Color")

local class             = require("middleclass")
local v                 = require("semver")

local resolve = class("resolve"):include(lazy)

--- cp.blackmagic.resolve.EARLIEST_SUPPORTED_VERSION <semver>
--- Constant
--- The earliest version this API supports.
resolve.EARLIEST_SUPPORTED_VERSION = v("15.3.1")

function resolve:initialize()
--- cp.blackmagic.resolve.app <cp.app>
--- Constant
--- The `cp.app` for DaVinci Resolve.
    self.app = app

--- cp.blackmagic.resolve.preferences <cp.app.prefs>
--- Constant
--- The `cp.app.prefs` for DaVinci Resolve.
    self.preferences = app.preferences

    app:update()

end

--------------------------------------------------------------------------------
-- Bind the `cp.app` props to the DaVinci Resolve instance for easy
-- access/backwards compatibility:
--------------------------------------------------------------------------------

--- cp.blackmagic.resolve.application <cp.prop: hs.application; read-only>
--- Field
--- Returns the running `hs.application` for DaVinci Resolve, or `nil` if it's not running.
function resolve.lazy.prop:application()
    return self.app.hsApplication
end

--- cp.blackmagic.resolve.isRunning <cp.prop: boolean; read-only>
--- Field
--- Is DaVinci Resolve Running?
function resolve.lazy.prop:isRunning()
    return self.app.running
end

--- cp.blackmagic.resolve.UI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- The DaVinci Resolve `axuielement`, if available.
function resolve.lazy.prop:UI()
    return self.app.UI
end

--- cp.blackmagic.resolve.windowsUI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- Returns the UI containing the list of windows in the app.
function resolve.lazy.prop:windowsUI()
    return self.app.windowsUI
end

--- cp.blackmagic.resolve.isShowing <cp.prop: boolean; read-only; live>
--- Field
--- Is Final Cut visible on screen?
function resolve.lazy.prop:isShowing()
    return self.app.showing
end

--- cp.blackmagic.resolve.isInstalled <cp.prop: boolean; read-only>
--- Field
--- Is any version of DaVinci Resolve Installed?
function resolve.lazy.prop:isInstalled()
    return self.app.installed
end

--- cp.blackmagic.resolve:isFrontmost <cp.prop: boolean; read-only; live>
--- Field
--- Is DaVinci Resolve Frontmost?
function resolve.lazy.prop:isFrontmost()
    return self.app.frontmost
end

--- cp.blackmagic.resolve:isModalDialogOpen <cp.prop: boolean; read-only>
--- Field
--- Is a modal dialog currently open?
function resolve.lazy.prop:isModalDialogOpen()
    return self.app.modalDialogOpen
end

--- cp.blackmagic.resolve.isSupported <cp.prop: boolean; read-only; live>
--- Field
--- Is a supported version of DaVinci Resolve installed?
---
--- Note:
---  * Supported version refers to any version of DaVinci Resolve equal or higher to `cp.blackmagic.resolve.EARLIEST_SUPPORTED_VERSION`
function resolve.lazy.prop:isSupported()
    return self.app.version:mutate(function(original)
        local version = original()
        return version ~= nil and version >= resolve.EARLIEST_SUPPORTED_VERSION
    end)
end

--- cp.blackmagic.resolve.supportedLocales <cp.prop: table of cp.i18n.localeID; read-only>
--- Field
--- The list of supported locales for this version of FCPX.
function resolve.lazy.prop:supportedLocales()
    return self.app.supportedLocales
end

--- cp.blackmagic.resolve.currentLocale <cp.prop: cp.i18n.localeID; live>
--- Field
--- Gets and sets the current locale for FCPX.
function resolve.lazy.prop:currentLocale()
    return self.app.currentLocale
end

--- cp.blackmagic.resolve.version <cp.prop: semver; read-only; live>
--- Field
--- The version number of the running or default installation of FCPX as a `semver`.
function resolve.lazy.prop:version()
    return self.app.version
end

--- cp.blackmagic.resolve.versionString <cp.prop: string; read-only; live>
--- Field
--- The version number of the running or default installation of FCPX as a `string`.
function resolve.lazy.prop:versionString()
    return self.app.versionString
end

--- cp.blackmagic.resolve.isUnsupported <cp.prop: boolean; read-only>
--- Field
--- Is an unsupported version of DaVinci Resolve installed?
---
--- Note:
---  * Supported version refers to any version of DaVinci Resolve equal or higher to cp.blackmagic.resolve.EARLIEST_SUPPORTED_VERSION
function resolve.lazy.prop:isUnsupported()
    return self.isInstalled:AND(self.isSupported:NOT())
end

--- cp.blackmagic.resolve:bundleID() -> string
--- Method
--- Returns the Bundle ID for the app.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The Bundle ID
function resolve:bundleID()
    return self.app:bundleID()
end

--- cp.blackmagic.resolve:notifier() -> cp.ui.notifier
--- Method
--- Returns a notifier that is tracking the application UI element. It has already been started.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The notifier.
function resolve:notifier()
    return self.app:notifier()
end

--- cp.blackmagic.resolve:launch([waitSeconds], [path]) -> self
--- Method
--- Launches DaVinci Resolve, or brings it to the front if it was already running.
---
--- Parameters:
---  * `waitSeconds` - If provided, the number of seconds to wait until the launch
---                    completes. If `nil`, it will return immediately.
---  * `path`        - An optional full path to an application without an extension
---                    (i.e `/Applications/DaVinci Resolve 10.3.4`). This allows you to
---                    load previous versions of the application.
---
--- Returns:
---  * The FCP instance.
function resolve:launch(waitSeconds, path)
    self.app:launch(waitSeconds, path)
    return self
end

--- cp.blackmagic.resolve:doLaunch() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will launch, or focus it if already running FCP.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement` to execute.
function resolve.lazy.method:doLaunch()
    return self.app:doLaunch()
end

--- cp.blackmagic.resolve:doRestart() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.cp) that will restart DaVinci Resolve, if it is running. If not, nothing happens.
---
--- Parameters:
---  * None.
---
--- Returns:
---  * The FCP instance.
function resolve.lazy.method:doRestart()
    return self.app:doRestart()
end

--- cp.blackmagic.resolve:show() -> cp.blackmagic.resolve
--- Method
--- Activate DaVinci Resolve, if it is running.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The FCP instance.
function resolve:show()
    self.app:show()
    return self
end

--- cp.blackmagic.resolve:doShow() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will show FCP on-screen.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement` to execute.
function resolve.lazy.method:doShow()
    return self.app:doShow()
end

--- cp.blackmagic.resolve:hide() -> self
--- Method
--- Hides DaVinci Resolve
---
--- Parameters:
---  * None
---
--- Returns:
---  * The FCP instance.
function resolve:hide()
    self.app:hide()
    return self
end

--- cp.blackmagic.resolve:doHide() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will hide the FCP.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement` to execute.
function resolve.lazy.method:doHide()
    return self.app:doHide()
end

--- cp.blackmagic.resolve:quit([waitSeconds]) -> self
--- Method
--- Quits DaVinci Resolve, if it's running.
---
--- Parameters:
---  * waitSeconds      - The number of seconds to wait for the quit to complete.
---
--- Returns:
---  * The FCP instance.
function resolve:quit(waitSeconds)
    self.app:quit(waitSeconds)
    return self
end

--- cp.blackmagic.resolve:doQuit() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that will quit FCP.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement` to execute.
function resolve.lazy.method:doQuit()
    return self.app:doQuit()
end

--- cp.blackmagic.resolve:getPath() -> string or nil
--- Method
--- Path to DaVinci Resolve Application
---
--- Parameters:
---  * None
---
--- Returns:
---  * A string containing DaVinci Resolve's filesystem path, or nil if DaVinci Resolve's path could not be determined.
function resolve:getPath()
    return self.app:path()
end

----------------------------------------------------------------------------------------
--
-- WINDOWS
--
----------------------------------------------------------------------------------------

--- cp.blackmagic.resolve:primaryWindow() -> primaryWindow object
--- Method
--- Returns the DaVinci Resolve Primary Window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Primary Window
function resolve.lazy.method:primaryWindow()
    return PrimaryWindow(self)
end

----------------------------------------------------------------------------------------
--
-- WORKSPACES
--
----------------------------------------------------------------------------------------

--- cp.blackmagic.resolve.Color <cp.blackmagic.resolve.Color>
--- Field
--- The Color Workspace.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the Browser
function resolve.lazy.value:color()
    return Color(self)
end

return resolve()