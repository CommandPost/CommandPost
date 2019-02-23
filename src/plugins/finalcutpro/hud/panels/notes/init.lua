--- === plugins.finalcutpro.hud.panels.notes ===
---
--- Notes Panel for the Final Cut Pro HUD.

local require           = require

--local log               = require("hs.logger").new("info")

local image             = require("hs.image")
local fs                = require("hs.fs")

local config            = require("cp.config")
local fcp               = require("cp.apple.finalcutpro")
local i18n              = require("cp.i18n")
local json              = require("cp.json")
local tools             = require("cp.tools")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

local FILENAME = "Notes.cpHUD"

--- plugins.finalcutpro.hud.panels.notes.notes <cp.prop: table>
--- Field
--- Table of HUD note values.
mod.notes = json.prop(config.userConfigRootPath, "HUD", "Notes.cpHUD", {})

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

local function writeToFile(path, data)
    local file = io.open(path .. "/" .. FILENAME, "w")
    file:write(data)
    file:close()
end

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
    local script = ""

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
    end

    if lastLocation == "Local Machine" then
        local notes = mod.notes()
        if notes and notes.notes then
            script = script .. "updateNotes(" .. notes.notes .. ");\n"
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

    if script ~= "" then
        mod._manager.injectScript(script)
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
        -- Create new Panel:
        --------------------------------------------------------------------------------
        mod._manager = deps.manager
        local panel = deps.manager.addPanel({
            priority    = 3,
            id          = "notes",
            label       = "Notes Panel",
            image       = image.imageFromPath(tools.iconFallback(env:pathToAbsolute("/images/notes.png"))),
            tooltip     = "Notes Panel",
            loadedFn    = updateInfo,
            height      = 300,
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
                    local notes = params["notes"]
                    mod.notes({notes=notes})
                else
                    writeToFile(params["location"], params["notes"])
                end
            elseif params["type"] == "refresh" then
                mod._manager.refresh()
            end
        end
        deps.manager.addHandler("hudNotes", controllerCallback)
    end
end

return plugin
