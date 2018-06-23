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
--- o:addWatcher("AXValueChanged", function(notifier, element, notification, details) ... end)
--- o:start()
--- ```

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                   = require("hs.logger").new("notifier")
local inspect               = require("hs.inspect")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local application           = require("hs.application")
local applicationwatcher    = require("hs.application.watcher")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils               = require("cp.ui.axutils")
local prop                  = require("cp.prop")

--------------------------------------------------------------------------------
-- 3rd Party Extensions:
--------------------------------------------------------------------------------
local ax                    = require("hs._asm.axuielement")

--------------------------------------------------------------------------------
-- Local Lua Functions:
--------------------------------------------------------------------------------
local insert                = table.insert
local LAUNCHED, TERMINATED  = applicationwatcher.launched, applicationwatcher.terminated

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--------------------------------------------------------------------------------
-- The Metatable:
--------------------------------------------------------------------------------
mod.mt = {}
mod.mt.__index = mod.mt

-- The table of bundle IDs with notifiers registered.
-- The key is the `Bundle ID`, the value is a list of `cp.ui.notifiers`.
local registeredBundleIDs = {}

-- The table of observed PIDs.
-- The key is the `pid`, and the value is the matching `Bundle ID`.
local registeredPIDs = {}

mod._registeredBundleIDs = registeredBundleIDs
mod._registeredPIDs = registeredPIDs

-- the overall app watcher for all cp.ui.notifiers.
local appWatcher = applicationwatcher.new(
    function(_, eventType, app)
        local pid = app:pid()
        local notifiers = nil
        if eventType == LAUNCHED then
            -- figure out if there are any notifiers for the app
            local bundleID = app:bundleID()
            notifiers = registeredBundleIDs[bundleID]
            if notifiers then -- we have notifiers, so link the PID to the BundleID
                -- log.df("Registering PID %s to Bundle ID '%s'", pid, bundleID)
                registeredPIDs[pid] = bundleID
            end
        elseif eventType == TERMINATED then
            local bundleID = registeredPIDs[pid]
            registeredPIDs[pid] = nil
            if bundleID then
                -- log.df("Deregistering PID %s from Bundle ID '%s'", pid, bundleID)
                notifiers = registeredBundleIDs[bundleID]
            end
        end

        -- check if we need to update
        if notifiers then
            -- log.df("Updating notifiers that their app has changed state...")
            for _,o in ipairs(notifiers) do
                o:reset():_startObserving()
            end
        end
    end
)

-- registerNotifier(notifier) -> nil
-- Local Function
-- Registers the specified `cp.ui.notifier`
local function registerNotifier(notifier)
    appWatcher:start()
    local bundleID = notifier:bundleID()

    -- add it to the list of notifiers
    local notifiers = registeredBundleIDs[bundleID]
    if not notifiers then
        notifiers = {}
        registeredBundleIDs[bundleID] = notifiers
    end
    insert(notifiers, notifier)

    -- if the app is running, link the PID to the BundleID.
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

    return registerNotifier(prop.extend({
        __bundleID = bundleID,
        __finder = elementFinderFn,
        __running = false,
        __watchers = {},
    }, mod.mt))
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

--- cp.ui.notifier:addWatcher(notification, callbackFn) -> self
--- Method
--- Registers a function to get called whenever the specified notification type is triggered
--- for the current `axuielement`.
---
--- Parameters:
---  * notification      - The notification type to watch for (e.g. "AXValueChanged").
---  * callbackFn        - The function to call when the matching notification is happens.
---
--- Returns:
---  * The `cp.ui.notifier` instance.
---
--- Notes:
---  * The callback function should expect 3 arguments and return none. The arguments passed to the callback will be as follows:
---  ** the `hs._asm.axuielement` object for the accessibility element which generated the notification.
---  ** a string with the notification type.
---  ** A table containing key-value pairs with more information about the notification, if provided. Commonly this will be an empty table.
function mod.mt:addWatcher(notification, callbackFn)
    assert(type(notification) == "string", "Provide a string value for the `notification`")
    assert(type(callbackFn) == "function", "Provide a function for the `callbackFn`.")

    local watchers = self.__watchers[notification]
    if not watchers then
        watchers = {}
        self.__watchers[notification] = watchers
    end

    -- add it to the list of functions for the notification type
    insert(watchers, callbackFn)

    -- do an update
    return self:update(true)
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
        -- new/no app available. Reset!
        self:reset()

        -- find the app for the bundle ID
        local result = application.applicationsForBundleID(self.__bundleID)
        if result and #result > 0 then
            app = result[1] -- If there is at least one copy running, return the first one
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
    if not self.__observer and create then
        local app = self:app()
        if app then
            -- create the observer
            local o = ax.observer.new(app:pid())
            self.__observer = o

            -- set up the callback to pass on to appropriate watchers.
            o:callback(function(_, element, notification, details)
                local watchers = self.__watchers[notification]
                if watchers then
                    for _,fn in ipairs(watchers) do
                        local ok, result = xpcall(function() fn(element, notification, details) end, debug.traceback)
                        if not ok then
                            log.ef("Error processing '%s' notification from app '%sS':\n%s", notification, self:bundleID(), result)
                        end
                    end
                end
            end)

            -- update the watcher list (forced)
            self:update(true)

            -- match the running state
            if self.__running then
                o:start()
            end
        end
    end
    return self.__observer
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
    if self:isRunning() then
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

    -- get the current observer (don't create if not present)
    local observer = self:_observer(false)

    if observer then
        --------------------------------------------------------------------------------
        -- TODO: figure out if/how we can remove watches on elements that
        --       are no longer valid.
        --------------------------------------------------------------------------------
        local remove = axutils.isValid(lastElement) and (force or lastElement ~= element)
        for n,_ in pairs(self.__watchers) do
            -- deregister the old element
            if remove then
                observer:removeWatcher(lastElement, n)
            end

            -- register the current one
            if element then
                observer:addWatcher(element, n)
            end
        end

        if self:isRunning() then
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
    self.__running = true
    -- start observing, if possible
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
    if self.__running then
        self.__running = false
        self:reset()
    end
    return self
end

--- cp.ui.notifier.isRunning <cp.prop: boolean; read-only>
--- Field
--- Indicates if the notifier is currently running.
mod.mt.isRunning = prop(function(self)
    return self.__running
end):bind(mod.mt)

--- cp.ui.notifier:reset() -> self
--- Method
--- Resets the notifier
function mod.mt:reset()
    self:_stopObserving()
    self.__observer = nil
    self.__lastElement = nil

    self.__app = nil

    return self
end

return mod