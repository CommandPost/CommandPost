--- === plugins.finalcutpro.hud.panels.notes ===
---
--- Notes Panel for the Final Cut Pro HUD.

local require           = require

--local log               = require("hs.logger").new("notes")

local image             = require("hs.image")
local fs                = require("hs.fs")

local config            = require("cp.config")
local fcp               = require("cp.apple.finalcutpro")
local i18n              = require("cp.i18n")
local tools             = require("cp.tools")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

-- FILENAME -> string
-- Constant
-- The filename used by the Notes HUD Panel.
local FILENAME = "Notes.cpHUD"

-- LOCAL_MACHINE_PATH -> string
-- Constant
-- The path to the local machine Notes file.
local LOCAL_MACHINE_PATH = config.userConfigRootPath .. "/HUD"

--- plugins.finalcutpro.hud.panels.notes.lastLocation <cp.prop: string>
--- Field
--- Last Location
mod.lastLocation = config.prop("hub.notes.lastLocation", "Local Machine")

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

-- writeToFile(path, data) -> none
-- Function
-- Write data to a file at a given path.
--
-- Parameters:
--  * path - The path of where you want to save the file.
--  * data - The data to write to the file.
--
-- Returns:
--  * None
local function writeToFile(path, data)
    local file = io.open(path .. "/" .. FILENAME, "w")
    file:write(data)
    file:close()
end

-- readFromFile(path) -> string
-- Function
-- Read data from file.
--
-- Parameters:
--  * path - The path of where you want to load the file.
--
-- Returns:
--  * None
local function readFromFile(path)
    local file = io.open(path .. "/" .. FILENAME, "r")
    if file then
        local data = file:read("*a")
        file:close()
        return data
    end
end

--- plugins.finalcutpro.hud.panels.notes.updateInfo() -> none
--- Function
--- Update the Info Panel HTML content.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
local function updateInfo()
    local script = "clearLocations();\n"

    local activeLibraryPaths = fcp.activeLibraryPaths()
    if #activeLibraryPaths >= 1 then
        for i=1, #activeLibraryPaths do
            local path = activeLibraryPaths[i]
            if path then
                local filename = fs.displayName(path)
                script = script .. "insertLocation('" .. filename .. "', '" .. path .. "');\n"
            end
        end
    end

    local lastLocation = mod.lastLocation()
    if tools.tableContains(activeLibraryPaths, lastLocation) then
        script = script .. "setLocation('" .. lastLocation .. "');\n"
    else
        lastLocation = "Local Machine"
        mod.lastLocation(lastLocation)
    end

    if lastLocation == "Local Machine" then
        local notes = readFromFile(LOCAL_MACHINE_PATH)
        if notes then
            script = script .. "updateNotes(" .. notes .. ");\n"
        else
            script = script .. "clearNotes();\n"
        end
    else
        local notes = readFromFile(lastLocation)
        if notes then
            script = script .. "updateNotes(" .. notes .. ");\n"
        else
            script = script .. "clearNotes();\n"
        end
    end

    mod._manager.injectScript(script)
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
        fcp.app.preferences:prop("FFActiveLibraries", nil, false):watch(updateInfo)
    else
        --------------------------------------------------------------------------------
        -- Destroy Watchers:
        --------------------------------------------------------------------------------
        fcp.app.preferences:prop("FFActiveLibraries", nil, false):unwatch(updateInfo)
    end
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
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
        tools.ensureDirectoryExists(config.userConfigRootPath, "HUD")

        --------------------------------------------------------------------------------
        -- Create new Panel:
        --------------------------------------------------------------------------------
        mod._manager = deps.manager
        local panel = deps.manager.addPanel({
            priority    = 6,
            id          = "notes",
            label       = i18n("notes"),
            image       = image.imageFromPath(tools.iconFallback(env:pathToAbsolute("/images/notes.png"))),
            tooltip     = i18n("notes"),
            loadedFn    = updateInfo,
            height      = 300,
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
                mod.lastLocation(location)
                updateInfo()
            elseif params["type"] == "notesChanged" then
                if params["location"] == "Local Machine" then
                    writeToFile(LOCAL_MACHINE_PATH, params["notes"])
                else
                    writeToFile(params["location"], params["notes"])
                end
            end
        end
        deps.manager.addHandler("hudNotes", controllerCallback)
    end
end

return plugin
