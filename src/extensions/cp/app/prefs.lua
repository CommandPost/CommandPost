--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.app.prefs ===
---
--- Provides access to application preferences, typically stored via `NSUserDefaults` or `CFProperties`.
--- To access the preferences, simply pass in the Bundle ID (eg. "com.apple.Preview") and it will return
--- a table whose keys can be accessed or updated, or iterated via `ipairs`.
---
--- For example:
---
--- ```lua
--- local previewPrefs = require("cp.app.prefs").new("com.apple.Preview")
--- previewPrefs.MyCustomPreference = "Hello world"
--- print(previewPrefs.MyCustomPreference) --> "Hello world"
---
--- for k,v in pairs(previewPrefs) do
---     print(k .. " = " .. tostring(v))
--- end
--- ```

-- local log               = require("hs.logger").new("app_prefs")
-- local inspect           = require("hs.inspect")

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local cfprefs               = require("hs._asm.cfpreferences")
local pathwatcher			= require("hs.pathwatcher")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}
mod.mt = {}

local METADATA = {}

local function firstFilePath(bundleID)
    local paths = cfprefs.applicationMap()[bundleID]
    if paths and #paths > 0 then
        return paths[1].filePath
    end
    return nil
end

local function metadata(self)
    return rawget(self, METADATA)
end

local function prefsPath(self)
    local data = metadata(self)
    local path = data.path
    if not path then
        path = firstFilePath(data.bundleID)
        data.path = path
    end
    return path
end

local function prefsFilePath(self)
    local data = metadata(self)
    local filePath = data.filePath
    if not filePath then
        local path = prefsPath(self)
        if path then
            filePath = path .. "/" .. data.bundleID .. ".plist"
            data.filePath = filePath
        end
    end
    return filePath
end

--- cp.app.prefs.new(bundleID) -> cp.app.prefs
--- Constructor
--- Creates a new `cp.app.prefs` instance, pointing at the specified `bundleID`.
---
--- Parameters:
---  * bundleID      The Bundle ID to access preferences for.
---
--- Returns:
---  * A new `cp.app.prefs` with read/write access to the application's preferences.
function mod.new(bundleID)
    local o =
        setmetatable(
        {
            [METADATA] = {
                bundleID = bundleID
            }
        },
        mod.mt
    )

    return o
end

--- cp.app.prefs.is(thing) -> boolean
--- Function
--- Checks if the `thing` is a `cp.app.prefs` instance.
---
--- Parameters:
---  * thing     - The value to check
---
--- Returns:
---  * `true` if if's a `prefs`, otherwise `false`.
function mod.is(thing)
    return type(thing) == "table" and getmetatable(thing) == mod.mt
end

--- cp.app.prefs.bundleID(prefs) -> string
--- Function
--- Retrieves the `bundleID` associated with the `cp.app.prefs` instance.
---
--- Parameters:
---  * prefs     - the `prefs` object to query
---
--- Returns:
---  * The Bundle ID string, or `nil` if it's not a `cp.app.prefs`.
function mod.bundleID(prefs)
    if mod.is(prefs) then
        return metadata(prefs).bundleID
    end
end

local PLIST_MATCH = "^.-([^/]+)%.plist$"

--- cp.app.prefs.watch(prefs, watchFn) -> nil
--- Function
--- Adds a watch function which will be notified when the preferences change.
--- The `watchFn` is a function which will be passed the `prefs` when it has been updated.
---
--- Parameters:
---  * prefs     - The `prefs` instance to watch.
---  * watchFn   - The function that will get called.
---
--- Returns:
---  * Nothing
function mod.watch(prefs, watchFn)
    if type(watchFn) ~= "function" then
        error("The `watchFn` provided is not a function: " .. type(watchFn))
    end

    local data = metadata(prefs)
    local watchers = data.watchers
    if watchers == nil then
        -- first watcher. set it up!
        watchers = {}
        data.watchers = watchers

        --log.df("Setting up Preferences Watcher...")
        local path = prefsPath(prefs)

        data.pathwatcher = pathwatcher.new(path, function(files)
            for _,file in pairs(files) do
                local fileName = file:match(PLIST_MATCH)
                if fileName == data.bundleID then
                    for _,watcher in ipairs(watchers) do
                        watcher(prefs)
                    end
                end
            end
        end):start()

    end
    table.insert(watchers, watchFn)
end



function mod.mt:__index(key)
    if key == "watch" then
        --- cp.app.prefs:watch(watchFn) -> nil
        --- Function
        --- Adds a watch function which will be notified when the preferences change.
        --- The `watchFn` is a function which will be passed the `prefs` when it has been updated.
        ---
        --- Parameters:
        ---  * watchFn   - The function that will get called.
        ---
        --- Returns:
        ---  * Nothing
        return mod.watch
    end

    local path = prefsFilePath(self)

    if path then
        return cfprefs.getValue(key, path)
    else
        return nil
    end
end

function mod.mt:__newindex(key, value)
    local path = prefsFilePath(self)

    if path and key then
        cfprefs.setValue(key, value, path)
        cfprefs.synchronize(path)
    end
end

function mod.mt:__pairs()
    local keys

    local path = prefsFilePath(self)
    keys = path and cfprefs.keyList(path) or nil
    local i = 0

    local function stateless_iter(_, k)
        local v
        if keys then
            if not keys[i] == k then
                i = nil
                -- loop through keys until we find it
                for j, key in ipairs(keys) do
                    if key == k then
                        i = j
                        break
                    end
                end
                if not i then
                    return nil
                end
            end
            i = i + 1
            k = keys[i]
            if k then
                v = cfprefs.getValue(k, path)
            end
        end
        if v then
            return k, v
        end
    end

    -- Return an iterator function, the table, starting point
    return stateless_iter, self, nil
end

function mod.mt:__tostring()
    return "cp.app.prefs: " .. metadata(self).bundleID
end

return mod
