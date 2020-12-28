--- === cp ===
---
--- Core CommandPost functionality.

local startTime             = os.clock()

local require               = require
local hs                    = _G.hs

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
        settings.set("hs.axuielement.logLevel", "verbose")

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
    -- Set Garbage Collection Mode:
    --------------------------------------------------------------------------------
    local garbageCollectionMode = "generational"

    --------------------------------------------------------------------------------
    -- Use Incremental Garbage Collection:
    --
    -- In incremental mode, each GC cycle performs a mark-and-sweep collection in
    -- small steps interleaved with the program's execution. In this mode, the
    -- collector uses three numbers to control its garbage-collection cycles:
    -- the garbage-collector pause, the garbage-collector step multiplier,
    -- and the garbage-collector step size.
    --
    -- The garbage-collector pause controls how long the collector waits before
    -- starting a new cycle. The collector starts a new cycle when the use of memory
    -- hits n% of the use after the previous collection. Larger values make the
    -- collector less aggressive. Values equal to or less than 100 mean the collector
    -- will not wait to start a new cycle. A value of 200 means that the collector
    -- waits for the total memory in use to double before starting a new cycle.
    -- The default value is 200; the maximum value is 1000.
    --
    -- The garbage-collector step multiplier controls the speed of the collector
    -- relative to memory allocation, that is, how many elements it marks or sweeps
    -- for each kilobyte of memory allocated. Larger values make the collector more
    -- aggressive but also increase the size of each incremental step. You should
    -- not use values less than 100, because they make the collector too slow and
    -- can result in the collector never finishing a cycle.
    -- The default value is 100; the maximum value is 1000.
    --
    -- The garbage-collector step size controls the size of each incremental step,
    -- specifically how many bytes the interpreter allocates before performing a step.
    -- This parameter is logarithmic: A value of n means the interpreter will
    -- allocate 2n bytes between steps and perform equivalent work during the step.
    -- A large value (e.g., 60) makes the collector a stop-the-world (non-incremental)
    -- collector. The default value is 13, which means steps of approximately 8 Kbytes.
    --------------------------------------------------------------------------------
    if garbageCollectionMode == "incremental" then
        local gcPause = 100             -- The default value is 200; the maximum value is 1000.
        local stepMultiplier = 100      -- The default value is 100; the maximum value is 1000.
        local stepSize = 13             -- The default value is 13, which means steps of approximately 8 Kbytes.
        collectgarbage("incremental", gcPause, stepMultiplier, stepSize)
    end

    --------------------------------------------------------------------------------
    -- Use Generational Garbage Collection:
    --
    -- In generational mode, the collector does frequent minor collections, which
    -- traverses only objects recently created. If after a minor collection the use
    -- of memory is still above a limit, the collector does a stop-the-world major
    -- collection, which traverses all objects. The generational mode uses two
    -- parameters: the minor multiplier and the the major multiplier.
    --
    -- The minor multiplier controls the frequency of minor collections. For a
    -- minor multiplier x, a new minor collection will be done when memory grows x%
    -- larger than the memory in use after the previous major collection. For instance,
    -- for a multiplier of 20, the collector will do a minor collection when the use
    -- of memory gets 20% larger than the use after the previous major collection.
    -- The default value is 20; the maximum value is 200.
    --
    -- The major multiplier controls the frequency of major collections.
    -- For a major multiplier x, a new major collection will be done when memory
    -- grows x% larger than the memory in use after the previous major collection.
    -- For instance, for a multiplier of 100, the collector will do a major
    -- collection when the use of memory gets larger than twice the use after the
    -- previous collection. The default value is 100; the maximum value is 1000.
    --------------------------------------------------------------------------------
    if garbageCollectionMode == "generational" then
        local minorMultiplier = 20      -- The default value is 20; the maximum value is 200.
        local majorMultiplier = 100     -- The default value is 100; the maximum value is 1000.
        collectgarbage("generational", minorMultiplier, majorMultiplier)
    end

    --------------------------------------------------------------------------------
    -- Collect Garbage because we love a fresh slate:
    --------------------------------------------------------------------------------
    collectgarbage("collect")
    collectgarbage("collect")
    log.df("Garbage Collection Mode: %s", garbageCollectionMode)

    --------------------------------------------------------------------------------
    -- Return the module:
    --------------------------------------------------------------------------------
    return mod
end

return mod.init()