--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                H A C K S     S H O R T C U T S     P L U G I N             --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.hacks.shortcuts ===
---
--- Plugin that allows the user to customise the CommandPost shortcuts
--- via the Final Cut Pro Command Editor.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log           = require("hs.logger").new("shortcuts")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local dialog        = require("hs.dialog")
local fs            = require("hs.fs")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local commands      = require("cp.commands")
local fcp           = require("cp.apple.finalcutpro")
local prop          = require("cp.prop")
local tools         = require("cp.tools")

--------------------------------------------------------------------------------
-- 3rd Party Extensions:
--------------------------------------------------------------------------------
local v             = require("semver")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local FCP_RESOURCES_PATH    = "/Contents/Resources/"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

local private = {}

-- private.resourcePath(resourceName) -> string
-- Function
-- Returns the path to the specified resource inside FCPX, or `nil` if it cannot be found.
--
-- Parameters:
--  * resourceName - Resource Name
--
-- Returns:
--  * Path as string or `nil` if it can't be found.
function private.resourcePath(resourceName)
    local fcpPath = fcp:getPath()
    if fcpPath then
        return fs.pathToAbsolute(fcpPath .. FCP_RESOURCES_PATH .. tostring(resourceName))
    else
        return nil
    end
end

-- private.hacksPath(resourceName) -> string
-- Function
-- Returns the path to the most recent version of the specified file inside the plugin, or `nil` if it can't be found.
--
-- Parameters:
--  * resourceName - Resource Name
--
-- Returns:
--  * Path as string or `nil` if it can't be found.
function private.hacksPath(resourceName)
    assert(type(resourceName) == "string", "Expected argument #1 to be a string")
    if mod.commandSetsPath and fcp:isInstalled() then
        local ver = fcp:version()
        local target = string.format("%s/%s/%s", mod.commandSetsPath, ver, resourceName)
        return fs.pathToAbsolute(target)
    else
        return nil
    end
end

-- private.hacksOriginalPath(resourceName) -> string
-- Function
-- Returns the Hacks Original Path
--
-- Parameters:
--  * resourceName - Resource Name
--
-- Returns:
--  * Path as string
function private.hacksOriginalPath(resourceName)
    assert(type(resourceName) == "string", "Expected argument #1 to be a string")
    return private.hacksPath("original/"..resourceName)
end

-- private.hacksModifiedPath(resourceName) -> string
-- Function
-- Returns the Hacks Modified Path
--
-- Parameters:
--  * resourceName - Resource Name
--
-- Returns:
--  * Path as string
function private.hacksModifiedPath(resourceName)
    assert(type(resourceName) == "string", "Expected argument #1 to be a string")
    return private.hacksPath("modified/"..resourceName)
end

-- private.fileContentsMatch(path1, path2) -> boolean
-- Function
-- Returns `true` if the file contents match between `path1` and `path2`.
--
-- Parameters:
--  * path1 - Source Path as String
--  * path2 - Target Path as String
--
-- Returns:
--  * `true` if the file contents match between `path1` and `path2`, otherwise `false`
function private.fileContentsMatch(path1, path2)

    --------------------------------------------------------------------------------
    -- Open the first path:
    --------------------------------------------------------------------------------
    local file1, errorMessage
    file1, errorMessage = io.open(path1, "rb")
    if errorMessage then log.wf("Unable to read file: %s", path1); return false; end

    --------------------------------------------------------------------------------
    -- Open the second path:
    --------------------------------------------------------------------------------
    local file2
    file2, errorMessage = io.open(path2,"rb")
    if errorMessage then log.wf("Unable to read file: %s", path2); return false; end

    --------------------------------------------------------------------------------
    -- Compare line by line:
    --------------------------------------------------------------------------------
    local block = 100
    local matches = true

    while matches do
        local bytes1 = file1:read(block)
        local bytes2 = file2:read(block)

        if not bytes1 then
            --------------------------------------------------------------------------------
            -- Make sure file finished as well:
            --------------------------------------------------------------------------------
            matches = not bytes2
            break
        elseif not bytes2 then
            --------------------------------------------------------------------------------
            -- file1 finished before file2:
            --------------------------------------------------------------------------------
            matches = false
            break
        end

        if bytes1 ~= bytes2 then
            matches = false
            break
        end
    end

    file1:close()
    file2:close()

    return matches
end

-- private.filesMatch(path1, path2) -> boolean
-- Function
-- Returns `true` if the files at the specified paths are the same.
--
-- Parameters:
--  * path1 - Source Path as String
--  * path2 - Target Path as String
--
-- Returns:
--  * `true` if the files at the specified paths are the same, otherwise `false`.
function private.filesMatch(path1, path2)
    if path1 and path2 then
        local attr1, attr2 = fs.attributes(path1), fs.attributes(path2)
        if attr1 and attr2 and attr1.mode == attr2.mode then
            --------------------------------------------------------------------------------
            -- They are the same type and size. Now, we compare contents:
            --------------------------------------------------------------------------------
            if attr1.mode == "directory" then
                return private.directoriesMatch(path1, path2)
            elseif attr1.mode == "file" and attr1.size == attr2.size then
                return private.fileContentsMatch(path1, path2)
            end
        end
    end
    return false
end

-- private.directoriesMatch(sourcePath, targetPath) -> boolean
-- Function
-- Checks if all files contained in the source path match
--
-- Parameters:
--  * sourcePath - Source Path as String
--  * targetPath - Target Path as String
--
-- Returns:
--  * `true` if successful, otherwise `false`
function private.directoriesMatch(sourcePath, targetPath)
    local sourceFiles = tools.dirFiles(sourcePath)
    if not sourceFiles then
        return false
    end
    for _,file in ipairs(sourceFiles) do
        if file:sub(1,1) ~= "." then -- it's not a hidden directory/file
            local sourceFile = fs.pathToAbsolute(sourcePath .. "/" .. file)
            local targetFile = fs.pathToAbsolute(targetPath .. "/" .. file)

            if not sourceFile or not targetFile then -- A file is missing
                -- log.df("Missing file:\n\t%s", sourceFile or targetFile)
                return false
            end

            if not private.filesMatch(sourceFile, targetFile) then
                -- log.df("Mismatched file:\n\t%s", sourceFile)
                return false
            end
        end
    end

    return true
end

-- private.copyFiles(batch, sourcePath, targetPath) -> nil
-- Function
-- Adds commands to copy Hacks Shortcuts files into FCPX.
--
-- Parameters:
--  * `batch`       - The table of batch commands to be executed.
--  * `sourcePath`  - The source file.
--  * `targetPath`  - The target path.
--
-- Returns:
--  * None
function private.copyFiles(batch, sourcePath, targetPath)
    local copy = "cp -f '%s' '%s'"
    local mkdir = "mkdir '%s'"

    local sourceFiles = tools.dirFiles(sourcePath)

    for _,file in ipairs(sourceFiles) do
        if file:sub(1,1) ~= "." then -- it's not a hidden directory/file
            local sourceFile = sourcePath .. "/" .. file
            local targetFile = targetPath .. "/" .. file

            local sourceAttr = fs.attributes(sourceFile)
            local targetAttr = fs.attributes(targetFile)

            if sourceAttr.mode == "directory" then
                if not targetAttr then
                    -- The directory doesn't exist. Make it first.
                    table.insert(batch, mkdir:format(targetFile))
                end
                private.copyFiles(batch, sourceFile, targetFile)
            elseif sourceAttr.mode == "file" then
                table.insert(batch, copy:format(sourceFile, targetFile))
            end
        end
    end

end

-- private.updateHacksShortcuts(install) -> none
-- Function
-- Enable Hacks Shortcuts
--
-- Parameters:
--  * install - `true` if you want to install the Hacks shortcuts, otherwise `false`
--
-- Returns:
--  * `true` if successful, otherwise `false`
function private.updateHacksShortcuts(install)

    if not mod.supported() then
        return false
    end

    mod.working(true)

    local batch = {}

    --------------------------------------------------------------------------------
    -- Always copy the originals back into FCPX, just in case the user has
    -- previously removed them or used an old version of CommandPost or FCPX Hacks:
    --------------------------------------------------------------------------------
    private.copyFiles(batch, private.hacksOriginalPath(""), private.resourcePath(""))

    --------------------------------------------------------------------------------
    -- Only then do we copy the 'modified' files...
    --------------------------------------------------------------------------------
    if install then
        private.copyFiles(batch, private.hacksModifiedPath(""), private.resourcePath(""))
    end

    --------------------------------------------------------------------------------
    -- Execute the instructions.
    --------------------------------------------------------------------------------
    local result = tools.executeWithAdministratorPrivileges(batch, false)

    mod.working(false)

    mod.update()

    if result == false then
        --------------------------------------------------------------------------------
        -- Cancel button pressed:
        --------------------------------------------------------------------------------
        return false
    end

    if type(result) == "string" then
        log.ef("The following error(s) occurred: %s", result)
        return false
    end

    --------------------------------------------------------------------------------
    -- Success:
    --------------------------------------------------------------------------------
    return true

end

-- private.updateFCPXCommands(enable, silently) -> none
-- Function
-- Switches to or from having CommandPost commands editible inside FCPX.
--
-- Parameters:
--  * enable - `true` if you want to enable, otherwise `false`
--  * silently - `true` if you want the action to occur without user interaction, otherwise `false`
--
-- Returns:
--  * `true` if already enabled and installed.
function private.updateFCPXCommands(enable, silently)

    if enable == mod.installed() then
        return true
    end

    local running = fcp:isRunning()
    if not silently then
        --------------------------------------------------------------------------------
        -- Check if the user really wants to do this
        --------------------------------------------------------------------------------
        local prompt = enable and i18n("hacksEnabling") or i18n("hacksDisabling")

        if running then
            prompt = prompt .. " " .. i18n("hacksShortcutsRestart")
        else
            prompt = prompt .. " " .. i18n("hacksShortcutAdminPassword")
        end

        local webview = mod._preferencesManager.getWebview()
        if not webview then
            log.ef("Could not find WebView.")
            return nil
        end
        dialog.webviewAlert(webview, function(result)
            if result == i18n("yes") then

                --------------------------------------------------------------------------------
                -- Let's do it!
                --------------------------------------------------------------------------------
                if not private.updateHacksShortcuts(enable) then
                    return false
                end

                --------------------------------------------------------------------------------
                -- Restart Final Cut Pro:
                --------------------------------------------------------------------------------
                if running and not fcp:restart() then
                    --------------------------------------------------------------------------------
                    -- Failed to restart Final Cut Pro:
                    --------------------------------------------------------------------------------
                    dialog.webviewAlert(webview, function()
                        --------------------------------------------------------------------------------
                        -- Refresh the Preferences Panel:
                        --------------------------------------------------------------------------------
                        if mod._manager then
                            mod._manager.refresh()
                        end
                    end, i18n("failedToRestart"), "", i18n("ok"), nil, "warning")
                end

            end
            --------------------------------------------------------------------------------
            -- Refresh the Preferences Panel:
            --------------------------------------------------------------------------------
            if mod._manager then
                if enable then
                    mod._shortcuts.setGroupEditor(mod.fcpxCmds:id(), mod.editorRenderer)
                else
                    mod._shortcuts.setGroupEditor(mod.fcpxCmds:id(), nil)
                end
                mod._manager.refresh()
            end
        end, prompt, i18n("doYouWantToContinue"), i18n("yes"), i18n("no"))

    end

end

-- private.applyShortcut(cmd) -> none
-- Function
-- Apply Shortcut.
--
-- Parameters:
--  * cmd - Command
--
-- Returns:
--  * None
function private.applyShortcut(id, cmd)
    local shortcuts = fcp:getCommandShortcuts(id)
    if shortcuts ~= nil then
        cmd:setShortcuts(shortcuts)
    end
end

-- private.applyShortcuts(commands) -> none
-- Function
-- Apply Shortcuts:
--
-- Parameters:
--  * commands - Commands
--
-- Returns:
--  * None
function private.applyShortcuts(c)
    c:deleteShortcuts()
    for id, cmd in pairs(c:getAll()) do
        private.applyShortcut(id, cmd)
    end
end

-- private.applyCommandSetShortcuts() -> none
-- Function
-- Apply Command Set Shortcuts.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function private.applyCommandSetShortcuts()
    local commandSet = fcp:getActiveCommandSet(true)

    --log.df("Applying Final Cut Pro Shortcuts to Final Cut Pro Commands.")
    private.applyShortcuts(mod.fcpxCmds, commandSet)

    mod.fcpxCmds:watch({
        add     = function(cmd) private.applyShortcut(cmd) end,
    })

    --------------------------------------------------------------------------------
    -- TODO: David, the below line was causing an error on my machine, and I can't
    --       work out what it actually does, as this seems to be the only line of
    --       code with `isEditable`, so I've commented it out.
    --
    --       hacks/shortcuts/init.lua:480: attempt to call a nil value (method 'isEditable')
    --------------------------------------------------------------------------------
    -- mod.fcpxCmds:isEditable(false)
end

--- plugins.finalcutpro.hacks.shortcuts.uninstall(silently) -> none
--- Function
--- Uninstalls the Hacks Shortcuts, if they have been installed
---
--- Parameters:
---  * `silently`   - (optional) If `true`, the user will not be prompted first.
---
--- Returns:
---  * `true` if successful.
---
--- Notes:
---  * Used by Trash Preferences menubar command.
function mod.uninstall(silently)
    return private.updateFCPXCommands(false, silently)
end

--- plugins.finalcutpro.hacks.shortcuts.install(silently) -> none
--- Function
--- Installs the Hacks Shortcuts.
---
--- Parameters:
---  * `silently`   - (optional) If `true`, the user will not be prompted first.
---
--- Returns:
---  * `true` if successful.
function mod.install(silently)
    return private.updateFCPXCommands(true, silently)
end

--- plugins.finalcutpro.hacks.shortcuts.supported <cp.prop: boolean; read-only>
--- Constant
--- A property that returns `true` if the a supported version of FCPX is installed.
mod.supported = prop(function()
    return private.hacksModifiedPath("") ~= nil
end)

--- plugins.finalcutpro.hacks.shortcuts.installed <cp.prop: boolean; read-only>
--- Constant
--- A property that returns `true` if the FCPX Hacks Shortcuts are currently installed in FCPX.
mod.installed = prop(function()
    return private.directoriesMatch(private.hacksModifiedPath(""), private.resourcePath(""))
end)

--- plugins.finalcutpro.hacks.shortcuts.uninstalled <cp.prop: boolean; read-only>
--- Constant
--- A property that returns `true` if the FCPX Hacks Shortcuts are currently installed in FCPX.
mod.uninstalled = prop(function()
    return private.directoriesMatch(private.hacksOriginalPath(""), private.resourcePath(""))
end)

--- plugins.finalcutpro.hacks.shortcuts.uninstalled <cp.prop: boolean; read-only>
--- Constant
--- A property that returns `true` if shortcuts is working on something.
mod.working = prop.FALSE()

--- plugins.finalcutpro.hacks.shortcuts.active <cp.prop: boolean; read-only>
--- Constant
--- A property that returns `true` if the FCPX shortcuts are active.
mod.active = prop.FALSE()

--- plugins.finalcutpro.hacks.shortcuts.requiresActivation <cp.prop: boolean; read-only>
--- Constant
--- A property that returns `true` if the custom shortcuts are installed in FCPX but not active.
mod.requiresActivation = mod.installed:AND(prop.NOT(mod.active)):watch(
    function(activate)
        if activate then
            private.applyCommandSetShortcuts()
            mod._shortcuts.setGroupEditor(mod.fcpxCmds:id(), mod.editorRenderer)
            mod.active(true)
        end
    end
)

--- plugins.finalcutpro.hacks.shortcuts.requiresDeactivation <cp.prop: boolean; read-only>
--- Constant
--- A property that returns `true` if the FCPX shortcuts are active but shortcuts are not installed.
mod.requiresDeactivation = prop.NOT(mod.installed):AND(mod.active):watch(
    function(deactivate)
        if deactivate then
            --------------------------------------------------------------------------------
            -- Got to restart to reset shortcuts.
            --------------------------------------------------------------------------------
            mod.active(false)

            --------------------------------------------------------------------------------
            -- Delete all shortcuts:
            --------------------------------------------------------------------------------
            local groupIDs = commands.groupIds()
            for _, groupID in ipairs(groupIDs) do

                local group = commands.group(groupID)
                local cmds = group:getAll()

                for _,cmd in pairs(cmds) do
                    cmd:deleteShortcuts()
                end
            end

            --------------------------------------------------------------------------------
            -- Load Shortcuts from file:
            --------------------------------------------------------------------------------
            commands.loadFromFile(mod._shortcuts.DEFAULT_SHORTCUTS)

        end
    end
)

--- plugins.finalcutpro.hacks.shortcuts.update() -> none
--- Function
--- Read shortcut keys from the Final Cut Pro Preferences.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.update()
    mod.installed:update()
    mod.uninstalled:update()
end

--- plugins.finalcutpro.hacks.shortcuts.refresh() -> none
--- Function
--- Refresh Hacks Shortcuts if they're enabled.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.refresh()
    if mod.active() then
        --log.df("Refreshing Hacks Shortcuts")
        mod.active(false)
        mod.active(true)
    end
end

--- plugins.finalcutpro.hacks.shortcuts.init() -> none
--- Function
--- Initialises the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init(deps, env)

    --------------------------------------------------------------------------------
    -- Webview Manger:
    --------------------------------------------------------------------------------
    mod._shortcuts = deps.shortcuts
    mod._manager = deps.shortcuts._manager
    mod._preferencesManager = deps.preferencesManager

    --------------------------------------------------------------------------------
    -- Add Preferences:
    --------------------------------------------------------------------------------
    if deps.prefs.panel then
        deps.prefs.panel
            :addHeading(50, i18n("keyboardShortcuts"))
            :addCheckbox(51,
                {
                    label       = i18n("enableHacksShortcuts"),
                    onchange    = function(_,params)
                        if params.checked then
                            mod.install()
                        else
                            mod.uninstall()
                        end
                    end,
                    checked=function() return mod.active() end,
                    disabled=function() return not mod.supported() end,
                }
            )
    end

    --------------------------------------------------------------------------------
    -- Setup:
    --------------------------------------------------------------------------------
    mod.fcpxCmds    = deps.fcpxCmds
    mod.commandSetsPath = env:pathToAbsolute("/commandsets/")

    --------------------------------------------------------------------------------
    -- Cache the last Command Set Path:
    --------------------------------------------------------------------------------
    mod.lastCommandSetPath = fcp:getActiveCommandSetPath()

    --------------------------------------------------------------------------------
    -- Refresh Shortcuts if the Command Set Path in Preferences file is modified:
    --------------------------------------------------------------------------------
    fcp.app.preferences:watch(function()
        local activeCommandSetPath = fcp:getActiveCommandSetPath()
        if activeCommandSetPath and mod.lastCommandSetPath ~= activeCommandSetPath then
            --log.df("Updating Final Cut Pro Command Editor Cache.")
            mod.refresh()
            mod.lastCommandSetPath = activeCommandSetPath
        end
    end)

    --------------------------------------------------------------------------------
    -- Refresh Shortcuts if Command Editor is Closed:
    --------------------------------------------------------------------------------
    fcp:commandEditor():watch({
        close = function()
                    --log.df("Updating Hacks Shortcuts due to Command Editor closing.")
                    mod.refresh()
                end
    })

    --------------------------------------------------------------------------------
    -- Renders the Shortcut Editor Panel:
    --------------------------------------------------------------------------------
    mod.editorRenderer = env:compileTemplate("html/editor.html")

    return mod
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.hacks.shortcuts",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]                            = "fcpxCmds",
        ["finalcutpro.preferences.app"]                     = "prefs",
        ["core.preferences.panels.shortcuts"]               = "shortcuts",
        ["core.preferences.manager"]                        = "preferencesManager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)
    return mod.init(deps, env)
end

--------------------------------------------------------------------------------
-- POST INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.postInit()
    mod.update()
end

return plugin
