--- === plugins.finalcutpro.hud.panels.notes ===
---
--- Notes Panel for the Final Cut Pro HUD.

local require                   = require

--local log                       = require "hs.logger".new "notes"

local fs                        = require "hs.fs"
local image                     = require "hs.image"
local timer                     = require "hs.timer"

local config                    = require "cp.config"
local deferred                  = require "cp.deferred"
local fcp                       = require "cp.apple.finalcutpro"
local i18n                      = require "cp.i18n"
local tools                     = require "cp.tools"

local displayName               = fs.displayName
local doAfter                   = timer.doAfter
local ensureDirectoryExists     = tools.ensureDirectoryExists
local iconFallback              = tools.iconFallback
local imageFromPath             = image.imageFromPath
local readFromFile              = tools.readFromFile
local tableMatch                = tools.tableMatch
local userConfigRootPath        = config.userConfigRootPath
local writeToFile               = tools.writeToFile

-- FILENAME -> string
-- Constant
-- The filename used by the Notes HUD Panel.
local FILENAME = "Notes.cpHUD"

-- LOCAL_MACHINE_PATH -> string
-- Constant
-- The path to the local machine Notes file.
local LOCAL_MACHINE_PATH = userConfigRootPath .. "/HUD"

-- manager -> plugins.finalcutpro.hud.manager
-- Variable
-- The HUD Manager plugin.
local manager

-- lastLocation <cp.prop: string>
-- Field
-- Last Location
local lastLocation = config.prop("hub.notes.lastLocation", "Local Machine")

-- getEnv() -> table
-- Function
-- Set up the template environment.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function getEnv()
    local env = {}
    env.i18n = i18n
    return env
end

--- plugins.finalcutpro.hud.panels.notes.updateInfo() -> none
--- Function
--- Update the Notes Panel HTML content.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
local function updateInfo()
    local script = "clearLocations();\n"

    local activeLibraryPaths = fcp:activeLibraryPaths()
    if #activeLibraryPaths >= 1 then
        for i=1, #activeLibraryPaths do
            local path = activeLibraryPaths[i]
            if path then
                local filename = displayName(path)
                script = script .. "insertLocation('" .. filename .. "', '" .. path .. "');\n"
            end
        end
    end

    local currentLastLocation = lastLocation()
    if tools.tableContains(activeLibraryPaths, currentLastLocation) then
        script = script .. "setLocation('" .. currentLastLocation .. "');\n"
    else
        currentLastLocation = "Local Machine"
        lastLocation(currentLastLocation)
    end

    if currentLastLocation == "Local Machine" then
        local notes = readFromFile(LOCAL_MACHINE_PATH .. "/" .. FILENAME)
        if notes then
            script = script .. "updateNotes(" .. notes .. ");\n"
        else
            script = script .. "clearNotes();\n"
        end
    else
        local notes = readFromFile(currentLastLocation .. "/" .. FILENAME)
        if notes then
            script = script .. "updateNotes(" .. notes .. ");\n"
        else
            script = script .. "clearNotes();\n"
        end
    end

    manager.injectScript(script)
end

-- updater -> cp.deferred
-- Variable
-- A deferred timer that triggers the updateInfo function.
local updater = deferred.new(0.1):action(updateInfo)

-- lastActiveLibraryPaths -> table
-- Variable
-- Last Active Library Paths
local lastActiveLibraryPaths

-- deferredUpdateInfo -> none
-- Function
-- Triggers the updateInfo function if activeLibraryPaths has changed.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function deferredUpdateInfo()
    doAfter(0, function()
        local activeLibraryPaths = fcp:activeLibraryPaths()
        if not tableMatch(lastActiveLibraryPaths, activeLibraryPaths) then
            lastActiveLibraryPaths = activeLibraryPaths
            updater()
        end
    end)
end

-- updateWatchers(enabled) -> none
-- Function
-- Sets up or destroys the Notes Panel watchers.
--
-- Parameters:
--  * enabled - `true` to setup, `false` to destroy
--
-- Returns:
--  * None
local function updateWatchers(enabled)
    if enabled then
        --------------------------------------------------------------------------------
        -- Setup Watchers:
        --------------------------------------------------------------------------------
        fcp.app.preferences:prop("FFActiveLibraries", nil, false):watch(deferredUpdateInfo)
    else
        --------------------------------------------------------------------------------
        -- Destroy Watchers:
        --------------------------------------------------------------------------------
        fcp.app.preferences:prop("FFActiveLibraries", nil, false):unwatch(deferredUpdateInfo)
    end
end

local plugin = {
    id              = "finalcutpro.hud.panels.notes",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.hud.manager"] = "manager",
    }
}

function plugin.init(deps, env)
    if fcp:isSupported() then
        --------------------------------------------------------------------------------
        -- Make sure the HUD application support folder exists:
        --------------------------------------------------------------------------------
        ensureDirectoryExists(config.userConfigRootPath, "HUD")

        --------------------------------------------------------------------------------
        -- Create new Panel:
        --------------------------------------------------------------------------------
        manager = deps.manager
        local panel = deps.manager.addPanel({
            priority    = 6,
            id          = "notes",
            label       = i18n("notes"),
            image       = imageFromPath(iconFallback(env:pathToAbsolute("/images/notes.png"))),
            tooltip     = i18n("notes"),
            loadedFn    = updateInfo,
            height      = 310,
            openFn      = function() updateWatchers(true) end,
            closeFn     = function() updateWatchers(false) end,
        })

        --------------------------------------------------------------------------------
        -- Generate HTML for Panel:
        --------------------------------------------------------------------------------
        local renderPanel = env:compileTemplate("html/panel.html")
        panel:addContent(1, function() return renderPanel(getEnv()) end, false)

        --------------------------------------------------------------------------------
        -- Setup Controller Callback:
        --------------------------------------------------------------------------------
        local controllerCallback = function(_, params)
            if params["type"] == "locationChanged" then
                local location = params["location"]
                lastLocation(location)
                updateInfo()
            elseif params["type"] == "notesChanged" then
                if params["location"] == "Local Machine" then
                    writeToFile(LOCAL_MACHINE_PATH .. "/" .. FILENAME, params["notes"])
                else
                    writeToFile(params["location"] .. "/" .. FILENAME, params["notes"])
                end
            end
        end
        deps.manager.addHandler("hudNotes", controllerCallback)
    end
end

return plugin