--- === cp.sourcewatcher ===
---
--- Watches folders for specific file extensions and reloads the app if they change.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local require = require
local console                       = require("hs.console")
local pathwatcher                   = require("hs.pathwatcher")

--------------------------------------------------------------------------------
--
-- MODULE:
--
--------------------------------------------------------------------------------

local mod = {}
mod.mt = {}
mod.mt.__index = mod.mt

--- cp.sourcewatcher.new(extensions) -> sourcewatcher
--- Method
--- Creates a new `sourcewatcher` instance.
---
--- Parameters:
---  * `extensions`     - Extensions
---
--- Returns:
---  * A sourcewatcher instance
function mod.new(extensions)
    local o = {
        extensions = extensions,
        paths = {},
        watchers = {},
    }
    setmetatable(o, mod.mt)
    return o
end

--- cp.sourcewatcher:matchesExtensions(file) -> boolean
--- Method
--- Checks that the file that triggered the Path Watcher matches the extension given.
---
--- Parameters:
---  * `file`       - The file as string
---
--- Returns:
---  * A boolean value
function mod.mt:matchesExtensions(file)
    if not self.extensions then
        --------------------------------------------------------------------------------
        -- Nothing specified, all files match:
        --------------------------------------------------------------------------------
        return true
    else
        --------------------------------------------------------------------------------
        -- Must match one of the extensions:
        --------------------------------------------------------------------------------
        for _,ext in ipairs(self.extensions) do
            if file:sub(-1*ext:len()) == ext then
                return true
            end
        end
        return false
    end
end

--- cp.sourcewatcher:filesChanged(files, flagTables) -> boolean
--- Method
--- Checks that the file that triggered the Path Watcher matches the extension given.
---
--- Parameters:
---  * `files`      - Table of files to check as strings
---  * `flagTables` - Table of flagTables (see: `hs.pathwatcher.new`)
---
--- Returns:
---  * None
function mod.mt:filesChanged(files, flagTables)
    for i,file in ipairs(files) do
        if self:matchesExtensions(file) then
            local flag = flagTables[i]
            --------------------------------------------------------------------------------
            -- Only reload if it's a file and it's been modified:
            --------------------------------------------------------------------------------
            if flag and flag.itemIsFile == true and flag.itemModified == true then
                console.clearConsole()
                hs.reload()
            end
            return
        end
    end
end

--- cp.sourcewatcher:watchPath(path) -> sourcewatcher
--- Method
--- Watches a path.
---
--- Parameters:
---  * `path`       - The path you want to watch as a string.
---
--- Returns:
---  * sourcewatcher
function mod.mt:watchPath(path)
    self.watchers[#self.watchers + 1] = pathwatcher.new(
        path,
        function(files, flagTables)
            self:filesChanged(files, flagTables)
        end
    )
    return self
end

--- cp.sourcewatcher:stop() -> none
--- Method
--- Stops a Source Watcher.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.mt:stop()
    if self.watchers then
        for _,watcher in ipairs(self.watchers) do
            watcher:stop()
        end
    end
end

--- cp.sourcewatcher:start() -> none
--- Method
--- Starts a Source Watcher.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.mt:start()
    if self.watchers then
        for _,watcher in ipairs(self.watchers) do
            watcher:start()
        end
    end
end

return mod
