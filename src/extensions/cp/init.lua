--- === cp ===
---
--- Core CommandPost functionality.

local startTime             = os.clock()

local require               = require
local hs                    = hs

local logger                = require "hs.logger"
logger.defaultLogLevel      = "verbose"

local application           = require "hs.application"
local console               = require "hs.console"
local image                 = require "hs.image"
local keycodes              = require "hs.keycodes"
local settings              = require "hs.settings"
local styledtext            = require "hs.styledtext"
local toolbar               = require "hs.webview.toolbar"
local window                = require "hs.window"

local config                = require "cp.config"
local fcp                   = require "cp.apple.finalcutpro"
local feedback              = require "cp.feedback"
local i18n                  = require "cp.i18n"
local plugins               = require "cp.plugins"
local tools                 = require "cp.tools"

local imageFromName         = image.imageFromName
local imageFromPath         = image.imageFromPath

--------------------------------------------------------------------------------
-- Not used in `init.lua`, but is required to "jump start" the CLI support:
--------------------------------------------------------------------------------
require("hs.ipc")

--------------------------------------------------------------------------------
-- Set the accessibility API timeout to one second:
--------------------------------------------------------------------------------
window.timeout(1)

local mod = {}

--- cp.init()
--- Function
--- Initialise CommandPost
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init()

    --------------------------------------------------------------------------------
    -- Setup Logger:
    --------------------------------------------------------------------------------
    local log = logger.new("cp")

    --------------------------------------------------------------------------------
    -- Show Dock Icon:
    --------------------------------------------------------------------------------
    if config.get("dockIcon", true) then
        hs.dockIcon(true)
    end

    --------------------------------------------------------------------------------
    -- Save Error Log History across sessions:
    --------------------------------------------------------------------------------
    hs._consoleHistory = require("cp.console.history")

    --------------------------------------------------------------------------------
    -- Enable Spotlight for Name Searches (used in Search Console):
    --------------------------------------------------------------------------------
    application.enableSpotlightForNameSearches(true)

    --------------------------------------------------------------------------------
    -- Disable Window Animations:
    --------------------------------------------------------------------------------
    window.animationDuration = 0

    --------------------------------------------------------------------------------
    -- Console Colour Scheme:
    --------------------------------------------------------------------------------
    local grey = {hex = "#999999", alpha = 1}
    console.consoleCommandColor(grey)
    console.consolePrintColor(grey)
    console.consoleResultColor(grey)
    console.outputBackgroundColor({hex = "#161616", alpha = 1})

    --------------------------------------------------------------------------------
    -- Add Toolbar To Error Log:
    --------------------------------------------------------------------------------
    local function consoleOnTopIcon()
        if hs.consoleOnTop() then
            return imageFromName("NSStatusAvailable")
        else
            return imageFromName("NSStatusUnavailable")
        end
    end
    local function autoReloadIcon()
        if config.automaticScriptReloading() then
            return imageFromName("NSStatusAvailable")
        else
            return imageFromName("NSStatusUnavailable")
        end
    end
    console.toolbar(toolbar.new("myConsole", {
            { id = i18n("reload"), image = imageFromName("NSSynchronize"),
                fn = function()
                    console.clearConsole()
                    print("Reloading CommandPost...")
                    hs.reload()
                end
            },
            { id = i18n("clearLog"), image = imageFromName("NSTrashFull"),
                fn = function()
                    console.clearConsole()
                end
            },
            { id = i18n("alwaysOnTop"), image = consoleOnTopIcon(),
                fn = function(object)
                    hs.consoleOnTop(not hs.consoleOnTop())
                    object:modifyItem({id = i18n("alwaysOnTop"), image = consoleOnTopIcon()})
                end
            },
            { id = i18n("toggleAutomaticScriptReloading"), image = autoReloadIcon(),
                fn = function(object)
                    config.automaticScriptReloading:toggle()
                    object:modifyItem({id = i18n("toggleAutomaticScriptReloading"), image = autoReloadIcon()})
                end
            },
            { id = "NSToolbarFlexibleSpaceItem" },
            { id = i18n("toolbox"), image = imageFromName("NSAdvanced"),
                fn = function()
                    plugins("core.toolbox.manager").show()
                end
            },
            { id = i18n("controlSurfaces"), image = imageFromPath(config.bundledPluginsPath .. "/core/midi/prefs/images/AudioMIDISetup.icns"),
                fn = function()
                    plugins("core.controlsurfaces.manager").show()
                end
            },
            { id = i18n("preferences"), image = imageFromName("NSPreferencesGeneral"),
                fn = function()
                    plugins("core.preferences.manager").show()
                end
            },
            { id = i18n("feedback"), image = imageFromName("NSInfo"),
                fn = function()
                    feedback.showFeedback()
                end
            },
        })
        :canCustomize(true)
        :autosaves(true)
    )

    --------------------------------------------------------------------------------
    -- Open Error Log:
    --------------------------------------------------------------------------------
    local errorLogOpenOnClose = config.get("errorLogOpenOnClose", false)
    if errorLogOpenOnClose then hs.openConsole() end

    --------------------------------------------------------------------------------
    -- Setup Global Shutdown Callback:
    --------------------------------------------------------------------------------
    hs.shutdownCallback = function()
        local shutdownCallbacks = config.shutdownCallback:getAll()
        if shutdownCallbacks and type(shutdownCallbacks) == "table" then
            for _, v in pairs(shutdownCallbacks) do
                local fn = v:callbackFn()
                if fn and type(fn) == "function" then
                    fn()
                end
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Setup Global Text Dropped to Dock Icon Callback:
    --------------------------------------------------------------------------------
    hs.textDroppedToDockIconCallback = function(value)
        local textDroppedToDockIconCallbacks = config.textDroppedToDockIconCallback:getAll()
        if textDroppedToDockIconCallbacks and type(textDroppedToDockIconCallbacks) == "table" then
            for _, v in pairs(textDroppedToDockIconCallbacks) do
                local fn = v:callbackFn()
                if fn and type(fn) == "function" then
                    fn(value)
                end
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Setup Global File Dropped to Dock Icon Callback:
    --------------------------------------------------------------------------------
    hs.fileDroppedToDockIconCallback = function(value)
        local fileDroppedToDockIconCallbacks = config.fileDroppedToDockIconCallback:getAll()
        if fileDroppedToDockIconCallbacks and type(fileDroppedToDockIconCallbacks) == "table" then
            for _, v in pairs(fileDroppedToDockIconCallbacks) do
                local fn = v:callbackFn()
                if fn and type(fn) == "function" then
                    fn(value)
                end
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Setup Global Dock Icon Click Callback:
    --------------------------------------------------------------------------------
    hs.dockIconClickCallback = function(value)
        local dockIconClickCallbacks = config.dockIconClickCallback:getAll()
        if dockIconClickCallbacks and type(dockIconClickCallbacks) == "table" then
            for _, v in pairs(dockIconClickCallbacks) do
                local fn = v:callbackFn()
                if fn and type(fn) == "function" then
                    fn(value)
                end
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Create CommandPost Shutdown Callback:
    --------------------------------------------------------------------------------
    hs.shuttingDown = false
    config.shutdownCallback:new("cp", function()
        hs.shuttingDown = true
        if console.hswindow() then
            config.set("errorLogOpenOnClose", true)
        else
            config.set("errorLogOpenOnClose", false)
        end
        console.clearConsole()
    end)

    --------------------------------------------------------------------------------
    -- Enable "Launch at Startup" by default:
    --------------------------------------------------------------------------------
    if not config.get("hasRunOnce", false) then
        --------------------------------------------------------------------------------
        -- Enable Automatic Launch by default:
        --------------------------------------------------------------------------------
        if not hs.autoLaunch() then
            hs.autoLaunch(true)
        end

        --------------------------------------------------------------------------------
        -- Set Log Level to Verbose for Debugging:
        --------------------------------------------------------------------------------
        settings.set("hs._asm.axuielement.logLevel", "verbose")

        --------------------------------------------------------------------------------
        -- Don't do this again unless you trash preferences:
        --------------------------------------------------------------------------------
        config.set("hasRunOnce", true)
    end

    --------------------------------------------------------------------------------
    -- Check Versions & Language:
    --------------------------------------------------------------------------------
    local fcpVersion            = fcp:version() or "Unknown"
    local fcpPath               = fcp:getPath() or "Unknown"
    local osVersion             = tools.macOSVersion() or "Unknown"
    local fcpLocale             = fcp:currentLocale()
    local fcpLanguage           = fcpLocale and fcpLocale.code or "Unknown"
    local debugMode             = config.developerMode()

    --------------------------------------------------------------------------------
    -- Clear The Console:
    --------------------------------------------------------------------------------
    local consoleLoadingContent = console.getConsole()
    console.clearConsole()

    --------------------------------------------------------------------------------
    -- Display Welcome Message In The Console:
    --------------------------------------------------------------------------------
    console.printStyledtext(styledtext.new(config.appName .. " v" .. config.appVersion .. " (Build: " .. config.appBuild .. ")", {
        color = {hex = "#999999", alpha = 1},
        font = { name = "Helvetica", size = 18 },
    }))

    --------------------------------------------------------------------------------
    -- Write To Console For Debug Messages:
    --------------------------------------------------------------------------------
    local writeToConsoleDebug = function(value)
        console.printStyledtext(styledtext.new(value, {
            color = {hex = "#999999", alpha = 1},
            font = { name = "Menlo", size = 12 },
        }))
    end

    --------------------------------------------------------------------------------
    -- Display Useful Debugging Information in Console:
    --------------------------------------------------------------------------------
    console.printStyledtext("")
                                                writeToConsoleDebug("Build Date:                     " .. hs.processInfo.buildTime)
    if osVersion ~= nil then                    writeToConsoleDebug("macOS Version:                  " .. tostring(osVersion),                   true) end
                                                writeToConsoleDebug(config.appName .. " Locale:             " .. tostring(i18n.getLocale()),     true)
    if keycodes.currentLayout() ~= nil then     writeToConsoleDebug("Current Keyboard Layout:        " .. tostring(keycodes.currentLayout()),    true) end
    if fcpPath ~= nil then                      writeToConsoleDebug("Final Cut Pro Path:             " .. tostring(fcpPath),                     true) end
    if fcpVersion ~= nil then                   writeToConsoleDebug("Final Cut Pro Version:          " .. tostring(fcpVersion),                  true) end
    if fcpLanguage ~= nil then                  writeToConsoleDebug("Final Cut Pro Language:         " .. tostring(fcpLanguage),                 true) end
                                                writeToConsoleDebug("Developer Mode:                 " .. tostring(debugMode))
    console.printStyledtext("")

    --------------------------------------------------------------------------------
    -- Display the content that was displayed before loading...
    --------------------------------------------------------------------------------
    print(tools.trim(consoleLoadingContent))

    --------------------------------------------------------------------------------
    -- Setup Automatic Script Reloading:
    --------------------------------------------------------------------------------
    config.automaticScriptReloading:update()

    --------------------------------------------------------------------------------
    -- Load Plugins:
    --------------------------------------------------------------------------------
    log.df("Loading Plugins...")
    plugins.init(config.pluginPaths)
    log.df("Plugins Loaded.")

    --------------------------------------------------------------------------------
    -- Display how long it took to load CommandPost:
    --------------------------------------------------------------------------------
    local finishTime = os.clock()
    local loadingTime = finishTime-startTime
    log.df("Startup Time: %s seconds", loadingTime)

    --------------------------------------------------------------------------------
    -- Collect Garbage because we love a fresh slate:
    --------------------------------------------------------------------------------
    collectgarbage("collect")
    collectgarbage("collect")

    --------------------------------------------------------------------------------
    -- Return the module:
    --------------------------------------------------------------------------------
    return mod
end

return mod.init()