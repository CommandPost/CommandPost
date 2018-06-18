--- === hs._asm.guitk ===
---
--- This module provides a window or panel which can be used to display a variety of graphical elements defined in the submodules or other Hammerspoon modules.
---
--- In the macOS, all visual elements are contained within a "window", though many of these windows have no extra decorations (title bar, close button, etc.). This module and its submodules is an attempt to provide a generic toolkit so that you can develop whatever type of visual interface you wish from a single set of tools rather then replicating code across multiple modules. Ultimately this module should be able to replace the other drawing or user interface modules and allow you to mix their components or even create completely new ones.
---
--- By itself, this module just creates the "window" and its methods describe how (or if) it should be visible, movable, etc. and provides a notification callback for potentially interesting events, for example when the "window" becomes visible, is moved, etc.
---
--- See `hs._asm.guitk.manager` for more information on how to populate a guitkObject with visual elements and `hs._asm.guitk.element` for a description of the currently supported visual elements which can included in a guitk window.
local USERDATA_TAG = "hs._asm.guitk"
local module       = require(USERDATA_TAG .. ".internal")
module.manager     = require(USERDATA_TAG .. ".manager")
module.element     = require(USERDATA_TAG .. ".element")

local guitkMT = hs.getObjectMetatable(USERDATA_TAG)

-- make sure support functions registered
require("hs.drawing.color")
require("hs.image")
require("hs.window")

local basePath = package.searchpath(USERDATA_TAG, package.path)
if basePath then
    basePath = basePath:match("^(.+)/init.lua$")
    if require"hs.fs".attributes(basePath .. "/docs.json") then
        require"hs.doc".registerJSONFile(basePath .. "/docs.json")
    end
end

local log = require("hs.logger").new(USERDATA_TAG, require"hs.settings".get(USERDATA_TAG .. ".logLevel") or "warning")

-- private variables and methods -----------------------------------------

-- a mapping from actual notification names to the simplified ones introduced with hs.webview
local simplifiedNotificationMap = {
    ["willClose"]    = "closing",
    ["didBecomeKey"] = "focusChange",
    ["didResignKey"] = "focusChange",
    ["didResize"]    = "frameChange",
    ["didMove"]      = "frameChange",
}

-- Public interface ------------------------------------------------------

--- hs._asm.guitk:styleMask([mask]) -> guitkObject | integer
--- Method
--- Get or set the window display style
---
--- Parameters:
---  * `mask` - if present, this mask should be a combination of values found in [hs._asm.guitk.masks](#masks) describing the window style.  The mask should be provided as one of the following:
---    * integer - a number representing the style which can be created by combining values found in [hs._asm.guitk.masks](#masks) with the logical or operator (e.g. `value1 | value2 | ... | valueN`).
---    * string  - a single key from [hs._asm.guitk.masks](#masks) which will be toggled in the current window style.
---    * table   - a list of keys from [hs._asm.guitk.masks](#masks) which will be combined to make the final style by combining their values with the logical or operator.
---
--- Returns:
---  * if a parameter is specified, returns the guitk object, otherwise the current value
guitkMT._styleMask = guitkMT.styleMask -- save raw version
guitkMT.styleMask = function(self, ...) -- add nice wrapper version
    local arg = table.pack(...)
    local theMask = guitkMT._styleMask(self)

    if arg.n ~= 0 then
        if math.type(arg[1]) == "integer" then
            theMask = arg[1]
        elseif type(arg[1]) == "string" then
            if module.masks[arg[1]] then
                theMask = theMask ~ module.masks[arg[1]]
            else
                return error("unrecognized style specified: "..arg[1])
            end
        elseif type(arg[1]) == "table" then
            theMask = 0
            for i,v in ipairs(arg[1]) do
                if module.masks[v] then
                    theMask = theMask | module.masks[v]
                else
                    return error("unrecognized style specified: "..v)
                end
            end
        else
            return error("integer, string, or table expected, got "..type(arg[1]))
        end
        return guitkMT._styleMask(self, theMask)
    else
        return theMask
    end
end

--- hs._asm.guitk:collectionBehavior([behaviorMask]) -> guitkObject | integer
--- Method
--- Get or set the guitk window collection behavior with respect to Spaces and Exposé.
---
--- Parameters:
---  * `behaviorMask` - if present, this mask should be a combination of values found in [hs._asm.guitk.behaviors](#behaviors) describing the collection behavior.  The mask should be provided as one of the following:
---    * integer - a number representing the desired behavior which can be created by combining values found in [hs._asm.guitk.behaviors](#behaviors) with the logical or operator (e.g. `value1 | value2 | ... | valueN`).
---    * string  - a single key from [hs._asm.guitk.behaviors](#behaviors) which will be toggled in the current collection behavior.
---    * table   - a list of keys from [hs._asm.guitk.behaviors](#behaviors) which will be combined to make the final collection behavior by combining their values with the logical or operator.
---
--- Returns:
---  * if a parameter is specified, returns the guitk object, otherwise the current value
---
--- Notes:
---  * Collection behaviors determine how the guitk window is handled by Spaces and Exposé. See [hs._asm.guitk.behaviors](#behaviors) for more information.
guitkMT._collectionBehavior = guitkMT.collectionBehavior -- save raw version
guitkMT.collectionBehavior = function(self, ...)          -- add nice wrapper version
    local arg = table.pack(...)
    local theBehavior = guitkMT._collectionBehavior(self)

    if arg.n ~= 0 then
        if math.type(arg[1]) == "integer" then
            theBehavior = arg[1]
        elseif type(arg[1]) == "string" then
            if module.behaviors[arg[1]] then
                theBehavior = theBehavior ~ module.behaviors[arg[1]]
            else
                return error("unrecognized behavior specified: "..arg[1])
            end
        elseif type(arg[1]) == "table" then
            theBehavior = 0
            for i,v in ipairs(arg[1]) do
                if module.behaviors[v] then
                    theBehavior = theBehavior | ((type(v) == "string") and module.behaviors[v] or v)
                else
                    return error("unrecognized behavior specified: "..v)
                end
            end
        else
            return error("integer, string, or table expected, got "..type(arg[1]))
        end
        return guitkMT._collectionBehavior(self, theBehavior)
    else
        return theBehavior
    end
end

--- hs._asm.guitk:level([theLevel]) -> guitkObject | integer
--- Method
--- Get or set the guitk window level
---
--- Parameters:
---  * `theLevel` - an optional parameter specifying the desired level as an integer or as a string matching a label in [hs._asm.guitk.levels](#levels)
---
--- Returns:
---  * if a parameter is specified, returns the guitk object, otherwise the current value
---
--- Notes:
---  * See the notes for [hs._asm.guitk.levels](#levels) for a description of the available levels.
---
---  * Recent versions of macOS have made significant changes to the way full-screen apps work which may prevent placing Hammerspoon elements above some full screen applications.  At present the exact conditions are not fully understood and no work around currently exists in these situations.
guitkMT._level = guitkMT.level     -- save raw version
guitkMT.level = function(self, ...) -- add nice wrapper version
    local arg = table.pack(...)
    local theLevel = guitkMT._level(self)

    if arg.n ~= 0 then
        if math.type(arg[1]) == "integer" then
            theLevel = arg[1]
        elseif type(arg[1]) == "string" then
            if module.levels[arg[1]] then
                theLevel = module.levels[arg[1]]
            else
                return error("unrecognized level specified: "..arg[1])
            end
        else
            return error("integer or string expected, got "..type(arg[1]))
        end
        return guitkMT._level(self, theLevel)
    else
        return theLevel
    end
end

--- hs._asm.guitk:bringToFront([aboveEverything]) -> guitkObject
--- Method
--- Places the guitk window on top of normal windows
---
--- Parameters:
---  * `aboveEverything` - An optional boolean value that controls how far to the front the guitk window should be placed. True to place the window on top of all windows (including the dock and menubar and fullscreen windows), false to place the webview above normal windows, but below the dock, menubar and fullscreen windows. Defaults to false.
---
--- Returns:
---  * The webview object
---
--- Notes:
---  * Recent versions of macOS have made significant changes to the way full-screen apps work which may prevent placing Hammerspoon elements above some full screen applications.  At present the exact conditions are not fully understood and no work around currently exists in these situations.
guitkMT.bringToFront = function(self, ...)
    local args = table.pack(...)

    if args.n == 0 then
        return self:level(module.levels.floating)
    elseif args.n == 1 and type(args[1]) == "boolean" then
        return self:level(module.levels[(args[1] and "screenSaver" or "floating")])
    elseif args.n > 1 then
        error("bringToFront method expects 0 or 1 arguments", 2)
    else
        error("bringToFront method argument must be boolean", 2)
    end
end

--- hs._asm.guitk:sendToBack() -> guitkObject
--- Method
--- Places the guitk window behind normal windows, between the desktop wallpaper and desktop icons
---
--- Parameters:
---  * None
---
--- Returns:
---  * The guitk object
guitkMT.sendToBack = function(self, ...)
    local args = table.pack(...)

    if args.n == 0 then
        return self:level(module.levels.desktopIcon - 1)
    else
        error("sendToBack method expects 0 arguments", 2)
    end
end

--- hs._asm.guitk:isVisible() -> boolean
--- Method
--- Returns whether or not the guitk window is currently showing and is (at least partially) visible on screen.
---
--- Parameters:
---  * None
---
--- Returns:
---  * a boolean indicating whether or not the guitk window is currently visible.
---
--- Notes:
---  * This is syntactic sugar for `not hs._asm.guitk:isOccluded()`.
---  * See [hs._asm.guitk:isOccluded](#isOccluded) for more details.
guitkMT.isVisible = function(self, ...) return not self:isOccluded(...) end

--- hs._asm.guitk:simplifiedWindowCallback([fn]) -> guitkObject
--- Method
--- Set or clear a callback for updates to the guitk window using a simplified subset of the available notifications
---
--- Parameters:
---  * `fn` - the function to be called when the guitk window is moved or closed. Specify an explicit nil to clear the current callback.  The function should expect 2 or 3 arguments and return none.  The arguments will be one of the following:
---
---    * "closing", guitkObject - specifies that the guitk window is being closed, either by the user or with the [hs._asm.guitk:delete](#delete) method.
---      * `action`      - in this case "closing", specifying that the guitk window is being closed
---      * `guitkObject` - the guitk window that is being closed
---
---    * "focusChange", guitkObject, state - indicates that the guitk window has either become or stopped being the focused window
---      * `action`      - in this case "focusChange", specifying that the guitk window has changed focus
---      * `guitkObject` - the guitk window which has changed focus
---      * `state`       - a boolean, true if the guitk window has become the focused window, or false if it has lost focus
---
---    * "frameChange", guitkObject, frame - indicates that the guitk window has been moved or resized
---      * `action`      - in this case "frameChange", specifying that the guitk window's frame has changed
---      * `guitkObject` - the guitk window which has had its frame changed
---      * `frame`       - a rect-table containing the new co-ordinates and size of the guitk window
---
--- Returns:
---  * The guitk object
---
--- Notes:
---  * This method is a wrapper to the [hs._asm.guitk:notificationCallback](#notificationCallback) method which mimics the behavior for window changes first introduced with `hs.webview`. Setting or clearing a callback with this method is equivalent to doing the same with [hs._asm.guitk:notificationCallback](#notificationCallback) directly.
---
---  * Setting a callback function with this method will reset the currently watched notifications to "willClose", "didBecomeKey", "didResignKey", "didResize", and "didMove".  You can add additional notifications after setting the callback function with [hs._asm.guitk:notificationMessages](#notificationMessages) and the following arguments will be passed to the callback when the additional notifications occur:
---    * "other", guitkObject, message
---      * `action`      - in this case "other" indicating that the notification is for something not recognized by the simplified wrapper.
---      * `guitkObject` - the guitk window for which the notification has occurred.
---      * `message`     - the name of the notification which has been triggered. See [hs._asm.guitk.notifications](#notifications).
guitkMT.simplifiedWindowCallback = function(self, ...)
    local args = table.pack(...)
    if args.n == 0 then
        return self:notificationCallback()
    elseif (args.n == 1) and (type(args[1]) == "function") or (getmetatable(args[1]) or {}).__call then
        local fn = function(s, m)
            local newM         = simplifiedNotificationMap[m]
            local callbackArgs = { newM or "other", s }
            if newM then
                if newM == "focusChange" then table.insert(callbackArgs, (m == didBecomeKey)) end
                if newM == "frameChange" then table.insert(callbackArgs, s:frame()) end
            else
                table.insert(callbackArgs, m)
            end
            args[1](table.unpack(callbackArgs))
        end
        local watchKeys = {}
        for k,v in pairs(simplifiedNotificationMap) do table.insert(watchKeys, k) end
        self:notificationMessages(watchKeys, true)
        self:notificationCallback(fn)
    elseif args.n == 1 and type(args[1]) == nil then
        self:notificationCallback(nil)
    else
        error("expected callback function", 2)
    end
    return self
end

module.behaviors     = ls.makeConstantsTable(module.behaviors)
module.levels        = ls.makeConstantsTable(module.levels)
module.masks         = ls.makeConstantsTable(module.masks)
module.notifications = ls.makeConstantsTable(module.notifications)

--- hs._asm.guitk.newCanvas([rect]) -> guitkObject
--- Constructor
--- Creates a new empty guitk window that is transparent and has no decorations.
---
--- Parameters:
---  * `rect` - an optional rect-table specifying the initial location and size of the guitk window.
---
--- Returns:
---  * the guitk object, or nil if there was an error creating the window.
---
--- Notes:
---  * a rect-table is a table with key-value pairs specifying the top-left coordinate on the screen of the guitk window (keys `x`  and `y`) and the size (keys `h` and `w`). The table may be crafted by any method which includes these keys, including the use of an `hs.geometry` object.
---
---  * this constructor creates an "invisible" container which is intended to display visual information only and does not accept user interaction by default, similar to an empty canvas created with `hs.canvas.new`. This is a shortcut for the following:
--- ~~~lua
--- hs._asm.guitk.new(rect, hs._asm.guitk.masks.borderless):backgroundColor{ alpha = 0 }
---                                                        :opaque(false)
---                                                        :hasShadow(false)
---                                                        :ignoresMouseEvents(true)
---                                                        :allowTextEntry(false)
---                                                        :animationBehavior("none")
---                                                        :level(hs._asm.guitk.levels.screenSaver)
--- ~~~
---  * If you do not specify `rect`, then the window will have no height or width and will not be able to display its contents; make sure to adjust this with [hs._asm.guitk:frame](#frame) or [hs._asm.guitk:size](#size) once content has been assigned to the window.
module.newCanvas = function(...)
    local args = table.pack(...)
    if type(args[1]) == "nil" then args[1] = {} end
    table.insert(args, 2, module.masks.borderless)
    return module.new(table.unpack(args)):backgroundColor{ alpha = 0 }
                                         :opaque(false)
                                         :hasShadow(false)
                                         :ignoresMouseEvents(true)
                                         :allowTextEntry(false)
                                         :animationBehavior("none")
                                         :level(module.levels.screenSaver)
end

-- Return Module Object --------------------------------------------------

return module
