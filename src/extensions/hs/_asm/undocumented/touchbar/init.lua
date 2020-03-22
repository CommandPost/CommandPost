if package.searchpath("hs._asm.coroutineshim", package.path) then
    require"hs._asm.coroutineshim"
end

--- === hs._asm.undocumented.touchbar ===
---
--- This module and its submodules provide support for manipulating the Apple Touch Bar on newer Macbook Pro laptops. For machines that do not have a touchbar, the `hs._asm.undocumented.touchbar.virtual` submodule provides a method for mimicing one on screen.
---
--- Use of this module and its submodules in conunction with other third party applications that can create the virtual touchbar has not been tested specifically, but *should* work. I have not run into any problems or issues while using [Duet Display](https://www.duetdisplay.com), but haven't performed extensive testing.
---
--- This module and it's submodules require a mac that is running macOS 10.12.1 build 16B2657 or newer. If you wish to use this module in an environment where the end-user's machine may not have a new enough macOS release version, you should always check the value of [hs._asm.undocumented.touchbar.supported](#supported) before trying to create the Touch Bar and provide your own fallback or message. By supplying the argument `true` to this function, the user will be prompted to upgrade if necessary.
---
--- This module relies heavily on undocumented APIs in the macOS and may break with future OS updates. With minor updates and bug fixes, this module has continued to work through 10.15.2, and we hope to continue to maintain this, but no guarantees are given.
---
--- Bug fixes and feature updates are always welcome and can be submitted at https://github.com/asmagill/hs._asm.undocumented.touchbar.
---
--- This module is very experimental and is still under development, so the exact functions and methods may be subject to change without notice.
---
--- Special thanks to @cmsj and @latenitefilms for code samples and bugfixes, and to @randomeizer, @Madd0g, and @medranocalvo for tests and reports. This is by no means a conclusive list, and if I've left anyone out, it's totally on me -- feel free to poke me with a (virtual) stick 😜.

local USERDATA_TAG = "hs._asm.undocumented.touchbar"
local module       = require(USERDATA_TAG .. ".internal")

-- capture this for use when touchbar not supported, but don't leave it directly available
local _fakeNew  = module._fakeNew
module._fakeNew = nil

if not module.supported() then
    module.virtual = {
        new = _fakeNew
    }
    return module
end

module.virtual   = require(USERDATA_TAG .. ".virtual")
module.item      = require(USERDATA_TAG .. ".item")
module.bar       = require(USERDATA_TAG .. ".bar")
-- module._debug    = require(USERDATA_TAG .. ".debug")

-- adds documentation (if present) in module subdir; should be removed if module moved into core
local basePath = package.searchpath(USERDATA_TAG, package.path)
if basePath then
    basePath = basePath:match("^(.+)/init.lua$")
    if require"hs.fs".attributes(basePath .. "/docs.json") then
        require"hs.doc".registerJSONFile(basePath .. "/docs.json")
    end
    -- remove no longer required wrapper file -- should be removed if module moved into core or sufficient time has passed
    if require"hs.fs".attributes(basePath .. "/supported.so") then
        os.remove(basePath .. "/supported.so")
    end
end

local virtualMT    = hs.getObjectMetatable(USERDATA_TAG .. ".virtual")
local itemMT       = hs.getObjectMetatable(USERDATA_TAG .. ".item")
local barMT        = hs.getObjectMetatable(USERDATA_TAG .. ".bar")

local mouse        = require("hs.mouse")
local screen       = require("hs.screen")

require("hs.drawing.color")
require("hs.image")
require("hs.styledtext")

-- private variables and methods -----------------------------------------

-- Public interface ------------------------------------------------------

--- hs._asm.undocumented.touchbar.virtual:toggle([duration]) -> touchbarObject
--- Method
--- Toggle's the visibility of the touch bar window.
---
--- Parameters:
---  * `duration` - an optional number, default 0.0, specifying the fade-in/out time when changing the visibility of the touch bar window.
---
--- Returns:
---  * the touchbarObject
virtualMT.toggle = function(self, ...)
    return self:isVisible() and self:hide(...) or self:show(...)
end

--- hs._asm.undocumented.touchbar.virtual:atMousePosition() -> touchbarObject
--- Method
--- Moves the touch bar window so that it is centered directly underneath the mouse pointer.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the touchbarObject
---
--- Notes:
---  * This method mimics the display location as set by the sample code this module is based on.  See https://github.com/bikkelbroeders/TouchBarDemoApp for more information.
---  * The touch bar position will be adjusted so that it is fully visible on the screen even if this moves it left or right from the mouse's current position.
virtualMT.atMousePosition = function(self)
    local origin    = mouse.getAbsolutePosition()
    local tbFrame   = self:getFrame()
    local scFrame   = mouse.getCurrentScreen():fullFrame()
    local scRight   = scFrame.x + scFrame.w
    local scBottom  = scFrame.y + scFrame.h

    origin.x = origin.x - tbFrame.w * 0.5
--     origin.y = origin.y - tbFrame.h -- Hammerspoon's 0,0 is the topLeft

    if origin.x < scFrame.x then origin.x = scFrame.x end
    if origin.x + tbFrame.w > scRight then origin.x = scRight - tbFrame.w end
    if origin.y + tbFrame.h > scBottom then origin.y = scBottom - tbFrame.h end
    return self:topLeft(origin)
end

--- hs._asm.undocumented.touchbar.virtual:centered([top]) -> touchbarObject
--- Method
--- Moves the touch bar window to the top or bottom center of the main screen.
---
--- Parameters:
---  * `top` - an optional boolean, default false, specifying whether the touch bar should be centered at the top (true) of the screen or at the bottom (false).
---
--- Returns:
---  * the touchbarObject
virtualMT.centered = function(self, top)
    top = top or false

    local origin    = {}
    local tbFrame   = self:getFrame()
    local scFrame   = screen.mainScreen():fullFrame()
--     local scRight   = scFrame.x + scFrame.w
    local scBottom  = scFrame.y + scFrame.h

    origin.x = scFrame.x + (scFrame.w - tbFrame.w) / 2
    origin.y = top and scFrame.y or (scBottom - tbFrame.h)
    return self:topLeft(origin)
end

module.item.visibilityPriorities = ls.makeConstantsTable(module.item.visibilityPriorities)
module.bar.builtInIdentifiers    = ls.makeConstantsTable(module.bar.builtInIdentifiers)

--- hs._asm.undocumented.touchbar.item:presentModalBar(touchbar, [dismissButton]) -> touchbarItemObject
--- Method
--- Presents a bar in the touch bar display modally and hides this item if it is present in the System Tray of the touch bar display.
---
--- Parameters:
---  * `touchbar` - An `hs._asm.undocumented.touchbar.bar` object of the bar to display modally in the touch bar display.
---  * `dismissButton` - an optional boolean, default true, specifying whether or not the system escape (or its current replacement) button should be replaced by a button to remove the modal bar from the touch bar display when pressed.
---
--- Returns:
---  * the touchbarItem object
---
--- Notes:
---  * If you specify `dismissButton` as false, then you must use `hs._asm.undocumented.touchbar.bar:minimizeModalBar` or `hs._asm.undocumented.touchbar.bar:dismissModalBar` to remove the modal bar from the touch bar display.
---    * Use `hs._asm.undocumented.touchbar.bar:minimizeModalBar` if you want the item to reappear in the System Tray (if it was present before displaying the bar).
---
---  * If you do not have "Touch Bar Shows" set to "App Controls With Control Strip" set in the Keyboard System Preferences, the modal bar will only be displayed when the Hammerspoon application is the frontmost application.
---
---  * This method is actually a wrapper to `hs._asm.undocumented.touchbar.bar:presentModalBar` provided for convenience.
---
---  * This method uses undocumented functions and/or framework methods and is not guaranteed to work with future updates to macOS. It has currently been tested with 10.12.6.
itemMT.presentModalBar = function(self, touchbar, ...)
    barMT.presentModalBar(touchbar, self, ...)
    return self
end

--- hs._asm.undocumented.touchbar.item:groupItems([itemsTable]) -> touchbarItemObject | current value
--- Method
--- Get or set the touchbar item objects which belong to this group touchbar item.
---
--- Parameters:
---  * `itemsTable` - an optional table as an array of touchbar item objects to display when this group touchbar item is present in the touchbar.
---
--- Returns:
---  * if an argument is provided, returns the touchbarItem object; otherwise returns the current value
---
--- Notes:
---  * This method will generate an error if the touchbar item was not created with the [hs._asm.undocumented.touchbar.item.newGroup](#newGroup) constructor.
---  * The group touchbar item's callback, if set, is never invoked; instead the callback for the items within the group item is invoked when the item is touched.
---  * This is a convenience method which creates an `hs._asm.undocumented.touchbar.bar` object and uses [hs._asm.undocumented.touchbar.item:groupTouchbar](#groupTouchbar) to assign the items to the group item.
itemMT.groupItems = function(self, ...)
    if self:itemType() == "group" then
        local args = table.pack(...)
        if args.n == 0 then
            local itemsArray = {}
            for i,v in ipairs(self:groupTouchbar():itemIdentifiers()) do
                table.insert(itemsArray, self:groupTouchbar():itemForIdentifier(v))
            end
            return itemsArray
        else
            if args.n == 1 and type(args[1]) == "table" then
                args = args[1]
            else
                args.n = nil
            end
            local itemsIdentifiers = {}
            for i,v in ipairs(args) do
                local s, r = pcall(itemMT.identifier, v)
                if s then
                    table.insert(itemsIdentifiers, r)
                else
                    return error("expected " .. USERDATA_TAG .. " object at index " .. tostring(i), 2)
                end
            end
            return self:groupTouchbar(module.bar.new():templateItems(args):defaultIdentifiers(itemsIdentifiers))
        end
    else
        return error("method only valid for group type", 2)
    end
end

-- Return Module Object --------------------------------------------------

return module
