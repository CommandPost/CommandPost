--- === cp.ui.notifier ===
---
--- Supports long-lived 'AX' notifiers. Configure the application to watch, the
--- function that provides the `axuielement` and then register for the type of
--- notification to watch, along with a function that will get triggered.
---
--- For example:
---
--- ```lua
--- local notifier = require("cp.ui.notifier")
--- local function finder() ... end -- returns the axuielement
--- local o = notifier.new("com.apple.FinalCut", finder)
--- o:watchFor("AXValueChanged", function(notifier, element, notification, details) ... end)
--- o:start()
--- ```

local require               = require

local log                   = require "hs.logger".new "notifier"
local inspect               = require "hs.inspect"

local application           = require "hs.application"
local applicationwatcher    = require "hs.application.watcher"
local timer                 = require "hs.timer"

local axutils               = require "cp.ui.axutils"
local prop                  = require "cp.prop"

local ax                    = require "hs._asm.axuielement"

local doAfter               = timer.doAfter
local insert                = table.insert

local LAUNCHED              = applicationwatcher.launched
local TERMINATED            = applicationwatcher.terminated

local mod = {}

--------------------------------------------------------------------------------
-- The Metatable:
--------------------------------------------------------------------------------
mod.mt = {}
mod.mt.__index = mod.mt

-- The table of bundle IDs with notifiers registered.
-- The key is the `Bundle ID`, the value is a list of `cp.ui.notifiers`.
local registeredBundleIDs = {}
mod._registeredBundleIDs = registeredBundleIDs

-- The table of observed PIDs.
-- The key is the `pid`, and the value is the matching `Bundle ID`.
local registeredPIDs = {}
mod._registeredPIDs = registeredPIDs

-- The table of AX observers:
mod.__observers = {}

-- The table of AX observer callback functions:
mod.__observersFn = {}

-- The overall app watcher for all cp.ui.notifiers:
mod._appWatcher = applicationwatcher.new(
    function(_, eventType, app)
        local pid = app:pid()
        local notifiers = nil
        if eventType == LAUNCHED then
            --------------------------------------------------------------------------------
            -- Figure out if there are any notifiers for the app:
            --------------------------------------------------------------------------------
            local bundleID = app:bundleID()
            notifiers = registeredBundleIDs[bundleID]
            if notifiers then
                --------------------------------------------------------------------------------
                -- We have notifiers, so link the PID to the BundleID:
                --------------------------------------------------------------------------------
                --log.df("Registering PID %s to Bundle ID '%s'", pid, bundleID)
                registeredPIDs[pid] = bundleID
            end
        elseif eventType == TERMINATED then
            local bundleID = registeredPIDs[pid]
            registeredPIDs[pid] = nil
            if bundleID then
                --log.df("Deregistering PID %s from Bundle ID '%s'", pid, bundleID)
                notifiers = registeredBundleIDs[bundleID]
            end
        end

        --------------------------------------------------------------------------------
        -- Check if we need to update:
        --------------------------------------------------------------------------------
        if notifiers then
            --log.df("Updating notifiers that their app has changed state...")
            for _,o in ipairs(notifiers) do
                o:reset():_startObserving()
            end
        end
    end
):start()

-- registerNotifier(notifier) -> nil
-- Local Function
-- Registers the specified `cp.ui.notifier`
local function registerNotifier(notifier)
    local bundleID = notifier:bundleID()

    --------------------------------------------------------------------------------
    -- Add it to the list of notifiers:
    --------------------------------------------------------------------------------
    local notifiers = registeredBundleIDs[bundleID]
    if not notifiers then
        notifiers = {}
        registeredBundleIDs[bundleID] = notifiers
    end
    insert(notifiers, notifier)

    --------------------------------------------------------------------------------
    -- If the app is running, link the PID to the BundleID:
    --------------------------------------------------------------------------------
    local pid = notifier:pid()
    if pid then
        registeredPIDs[pid] = bundleID
    end
    return notifier
end

--- cp.ui.notifier.new(bundleID, elementFinderFn) -> cp.ui.notifier
--- Constructor
--- Creates a new `cp.ui.notifier` instance with the specified bundle ID and
--- a function that returns the element being observed.
---
--- The function has a signature of `function() -> hs._asm.axuielement`.
--- It simply returns the current element being observed, or `nil` if none is available.
--- The function will be called multiple times over the life of the notifier.
---
--- Parameters:
---  * bundleID          - The application Bundle ID being observed. E.g. "com.apple.FinalCut".
---  * elementFinderFn   - The function that will return the `axuielement` to observe.
---
--- Returns:
---  * A new `cp.ui.notifier` instance.
function mod.new(bundleID, elementFinderFn)
    assert(type(bundleID) == "string", "Provide a string value for the `bundleID`.")
    assert(type(elementFinderFn) == "function" or prop.is(elementFinderFn), "Provide a function for the `elementFinderFn`.")

    local o = registerNotifier(prop.extend({
        __bundleID = bundleID,
        __finder = elementFinderFn,
        __watchers = {},

        --- cp.ui.notifier.running <cp.prop: boolean; read-only>
        --- Field
        --- Indicates if the notifier is currently running.
        running = prop.FALSE(),

    }, mod.mt))

    return o
end

--- cp.ui.notifier.notifiersForBundleID(bundleID) -> table of cp.ui.notifier
--- Function
--- Returns the list of `cp.ui.notifier` instances that have been created for the specified `Bundle ID`.
---
--- Parameters:
---  * bundleID          - The application Bundle ID being observed. E.g. "com.apple.FinalCut".
---
--- Returns:
---  * A table of `cp.ui.notifier` instances.
function mod.notifiersForBundleID(bundleID)
    return registeredBundleIDs[bundleID]
end

--- cp.ui.notifier:currentElement() -> hs._asm.axuielement
--- Method
--- Returns the current `axuielement` being observed.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `axuielement`, or `nil` if not available.
function mod.mt:currentElement()
    return self.__finder and self.__finder() or nil
end

--- cp.ui.notifier:watchFor(notification, callbackFn) -> self
--- Method
--- Registers a function to get called whenever the specified notification type is triggered
--- for the current `axuielement`.
---
--- Parameters:
---  * notifications     - The `string` or `table of strings` with the notification type(s) to watch for (e.g. "AXValueChanged").
---  * callbackFn        - The function to call when the matching notification is happens.
---
--- Returns:
---  * The `cp.ui.notifier` instance.
---
--- Notes:
---  * The callback function should expect 3 arguments and return none. The arguments passed to the callback will be as follows:
---      * the `hs._asm.axuielement` object for the accessibility element which generated the notification.
---      * a string with the notification type.
---      * A table containing key-value pairs with more information about the notification, if provided. Commonly this will be an empty table.
function mod.mt:watchFor(notifications, callbackFn)
    local nType = type(notifications)
    assert(nType == "string" or nType == "table", "Provide a string or table value for the `notifications`")
    assert(type(callbackFn) == "function", "Provide a function for the `callbackFn`.")

    if nType == "string" then
        self:_registerNotification(notifications, callbackFn)
    else
        for _,notification in ipairs(notifications) do
            self:_registerNotification(notification, callbackFn)
        end
    end

    return self:update(true)
end

--------------------------------------------------------------------------------
-- Does the actual notification registration:
--------------------------------------------------------------------------------
function mod.mt:_registerNotification(notification, callbackFn)
    local watchers = self.__watchers[notification]
    if not watchers then
        watchers = {}
        self.__watchers[notification] = watchers
    end

    --------------------------------------------------------------------------------
    -- Add it to the list of functions for the notification type:
    --------------------------------------------------------------------------------
    watchers[callbackFn] = true
end

--- cp.ui.notifier:watchAll(callbackFn) -> self
--- Method
--- Registers the callback as a watcher for all standard notifications for the current `axuielement`.
---
--- Parameters:
---  * callbackFn   - the function to call when the notification happens.
---
--- Returns:
---  * The `cp.ui.notifier` instance.
---
--- Notes:
---  * This should generally just be used for debugging purposes. It's best to use `watchFor`[#watchFor] in most cases.
---  * The callback function should expect 3 arguments and return none. The arguments passed to the callback will be as follows:
---      * the `hs._asm.axuielement` object for the accessibility element which generated the notification.
---      * a string with the notification type.
---      * A table containing key-value pairs with more information about the notification, if provided. Commonly this will be an empty table.
function mod.mt:watchAll(callbackFn)
    return self:watchFor(ax.observer.notifications, callbackFn)
end

function mod.mt:unwatchFor(notifications, callbackFn)
    local nType = type(notifications)
    assert(nType == "string" or nType == "table", "Provide a string or table value for the `notifications`")
    assert(type(callbackFn) == "function", "Provide a function for the `callbackFn`.")

    if nType == "string" then
        self:_unregisterNotification(notifications, callbackFn)
    else
        for _,notification in ipairs(notifications) do
            self:_unregisterNotification(notification, callbackFn)
        end
    end

    return self:update(true)
end

function mod.mt:unwatchAll(callbackFn)
    return self:unwatchFor(ax.observer.notifications, callbackFn)
end

function mod.mt:_unregisterNotification(notification, callbackFn)
    local watchers = self.__watchers[notification]
    if watchers then
        watchers[callbackFn] = nil
    end
end

--- cp.ui.notifier:bundleID()
--- Method
--- Returns the application 'bundle ID' that this notifier is tracking.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application 'bundle ID' string (e.g. "com.apple.FinalCut")
function mod.mt:bundleID()
    return self.__bundleID
end

--- cp.ui.notifier:app() -> hs.application
--- Method
--- Returns the current `hs.application` instance for the app this notifier tracks.
--- May be `nil` if the application is not running.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The running `hs.application` for the notifier's `bundleID`, or `nil`.
function mod.mt:app()
    local app = self.__app
    if not app or app:bundleID() == nil or not app:isRunning() then

        --------------------------------------------------------------------------------
        -- New/no app available. Reset:
        --------------------------------------------------------------------------------
        self:reset()

        --------------------------------------------------------------------------------
        -- Find the app for the bundle ID:
        --------------------------------------------------------------------------------
        local result = application.applicationsForBundleID(self.__bundleID)
        if result and #result > 0 then
            --------------------------------------------------------------------------------
            -- If there is at least one copy running, return the first one:
            --------------------------------------------------------------------------------
            app = result[1]
        else
            app = nil
        end
        self.__app = app
    end
    return app
end

--- cp.ui.notifier:pid() -> number
--- Method
--- Returns the PID for the application being observed, or `nil` if it's not running.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The PID, or `nil`.
function mod.mt:pid()
    local app = self:app()
    return app and app:pid()
end

-- cp.ui.notifier:_observer([create]) -> hs._asm.axuielement.observer
-- Private Method
-- Returns the current observer, or `nil` if one does not yet exist.
--
-- Parameters:
-- * create    - Defaults to `false`. If `true`, and the application is running, the observer will be created.
--
-- Returns:
-- * The current `hs._asm.axuilelement.observer`, or `nil` if it does not exist and/or could not be created.
function mod.mt:_observer(create)

    --------------------------------------------------------------------------------
    -- Get the App:
    --------------------------------------------------------------------------------
    local app = self.__app
    if not app or app:bundleID() == nil or not app:isRunning() then
        local result = application.applicationsForBundleID(self.__bundleID)
        if result and #result > 0 then
            app = result[1] -- If there is at least one copy running, return the first one
        else
            app = nil
        end
    end

    --------------------------------------------------------------------------------
    -- Get the PID:
    --------------------------------------------------------------------------------
    local pid = app and app:pid()

    if create and pid and not mod.__observers[pid] then
        --------------------------------------------------------------------------------
        -- Create the observer:
        --------------------------------------------------------------------------------
        mod.__observers[pid] = ax.observer.new(pid)

        --------------------------------------------------------------------------------
        -- Set up the callback to pass on to appropriate watchers:
        --------------------------------------------------------------------------------
        mod.__observers[pid]:callback(function(_, element, notification, details)
            if mod.__observersFn[pid] then
                for _, v in pairs(mod.__observersFn[pid]) do
                    if type(v) == "function" then
                        doAfter(0.00000000000001, function()
                            v(_, element, notification, details)
                        end)
                    end
                end
            end
        end)

        --------------------------------------------------------------------------------
        -- Update the watcher list (forced):
        --------------------------------------------------------------------------------
        self:update(true)

        --------------------------------------------------------------------------------
        -- Match the running state:
        --------------------------------------------------------------------------------
        if self:running() then
            mod.__observers[pid]:start()
        end

    end

    if create and pid then
        --------------------------------------------------------------------------------
        -- Prepare the module table of observer callback functions per app.
        --------------------------------------------------------------------------------
        if not mod.__observersFn[pid] then
            mod.__observersFn[pid] = {}
        end

        --------------------------------------------------------------------------------
        -- Setup the individual callback function:
        --------------------------------------------------------------------------------
        local fn = function(_, element, notification, details)
            local watchers = self.__watchers[notification]
            if watchers then
                for fn,_ in pairs(watchers) do
                    local ok, result = xpcall(function() fn(element, notification, details) end, debug.traceback)
                    if not ok then
                        log.ef("Error processing '%s' notification from app '%sS':\n%s", notification, self:bundleID(), result)
                    end
                end
            end
        end

        --------------------------------------------------------------------------------
        -- Check that the function isn't already in the table:
        --------------------------------------------------------------------------------
        local alreadyExists = false
        for _, v in pairs(mod.__observersFn[pid]) do
            if v == fn then
                alreadyExists = true
            end
        end

        --------------------------------------------------------------------------------
        -- If it isn't add it.
        --------------------------------------------------------------------------------
        if not alreadyExists then
            mod.__observersFn[pid][#mod.__observersFn[pid] + 1] = fn
        end
    end

    return pid and mod.__observers and mod.__observers[pid]
end

-- cp.ui.notifier:_startObserving() -> boolean
-- Private Method
-- Will attempt to start observing the UI element, notifying watchers when events happen.
--
-- Parameters:
-- * None
--
-- Returns:
-- * `true` if the the element is found and is being observed.
function mod.mt:_startObserving()
    if self:running() then
        local observer = self:_observer(true)
        if observer and not observer:isRunning() then
            observer:start()
            return observer:isRunning()
        end
    end
    return false
end

-- cp.ui.notifier:_stopObserving() -> boolean
-- Private Method
-- Will stop observing the UI element if the observer is currently running.
--
-- Parameters:
-- * None
--
-- Returns:
-- * `true` if observing was successfully stopped.
function mod.mt:_stopObserving()
    local observer = self:_observer(false)
    if observer and observer:isRunning() then
        observer:stop()
        return not observer:isRunning()
    end
    return true
end

--- cp.ui.notifier:update([force]) -> self
--- Method
--- Updates any watchers to use the current `axuielement`.
---
--- Parameters:
---  * force     - If `true`, the notifier will be updated even if the element has not changed since the last update. Defaults to `false`.
---
--- Returns:
---  * The `cp.ui.notifier` instance.
function mod.mt:update(force)
    local element = self.__finder()
    local lastElement = self._lastElement
    self._lastElement = element

    --------------------------------------------------------------------------------
    -- Get the current observer (don't create if not present):
    --------------------------------------------------------------------------------
    local observer = self:_observer(false)

    if observer then
        local doRemove = axutils.isValid(lastElement) and (force or lastElement ~= element)
        for n,watchers in pairs(self.__watchers) do
            --------------------------------------------------------------------------------
            -- De-register the old element:
            --------------------------------------------------------------------------------
            if doRemove then
                observer:removeWatcher(lastElement, n)
            end

            --------------------------------------------------------------------------------
            -- Register the current one:
            --------------------------------------------------------------------------------
            if next(watchers) ~= nil then
                if element then
                    observer:addWatcher(element, n)
                end
            else
                --------------------------------------------------------------------------------
                -- No more watchers registered, remove it:
                --------------------------------------------------------------------------------
                self.__watchers[n] = nil
            end
        end

        if self:running() then
            observer:start()
        else
            observer:stop()
        end
    end

    return self
end

--- cp.ui.notifier:start() -> self
--- Method
--- Starts notifying watchers when events happen.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.ui.notifier` instance.
function mod.mt:start()
    self:running(true)
    --------------------------------------------------------------------------------
    -- Start observing, if possible:
    --------------------------------------------------------------------------------
    self:_startObserving()
    return self
end

--- cp.ui.notifier:start() -> self
--- Method
--- Stops notifying watchers when events happen.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.ui.notifier` instance.
function mod.mt:stop()
    if self:running() then
        self:running(false)
        self:reset()
    end
    return self
end

--- cp.ui.notifier:reset() -> self
--- Method
--- Resets the notifier
function mod.mt:reset()
    self:_stopObserving()

    --------------------------------------------------------------------------------
    -- Destroy any dead observers and their callback functions:
    --------------------------------------------------------------------------------
    for pid, _ in pairs(mod.__observers) do
        if not mod._registeredPIDs[pid] then
            mod.__observers[pid] = nil
            if mod.__observersFn[pid] then
                for i, _ in pairs(mod.__observersFn[pid]) do
                    mod.__observersFn[pid][i] = nil
                end
            end
            mod.__observersFn[pid] = nil
        end
    end

    self.__lastElement = nil
    self.__app = nil

    return self
end

-- the debug printing function
local function printDebug(ui, notification, details)
    log.df("notification: %s; ui: %s; details: %s", notification, ui, inspect(details))
end

--- cp.ui.notifier:debugging([enabled]) -> boolean
--- Method
--- Enables/disables and reports current debugging status.
--- When enabled, a message will be output for each known notification received.
---
--- Parameters:
---  * enabled  - If `true`, debugging notifications will be emitted. If `false`, it will be disabled. If not provided, no change is made.
---
--- Returns:
---  * `true` if currently debugging, `false` otherwise.
function mod.mt:debugging(enabled)
    if enabled == true then
        if not self._debugging then
            self:watchAll(printDebug)
            self._debugging = true
        end
    elseif enabled == false then
        if self._debugging then
            self:unwatchAll(printDebug)
            self._debugging = false
        end
    end
    return self._debugging == true
end

return mod
