--- === hs._asm.module ===
---
--- Stuff about the module

local USERDATA_TAG = "hs._asm.guitk.menubar"
local module = {}

local statusitem  = require(USERDATA_TAG .. ".statusitem")
local menu        = require(USERDATA_TAG .. ".menu")
local menuitem    = require(USERDATA_TAG .. ".menuItem")

local styledtext  = require("hs.styledtext")
local eventtap    = require("hs.eventtap")
local image       = require("hs.image")

local log = require("hs.logger").new(USERDATA_TAG, require"hs.settings".get(USERDATA_TAG .. ".logLevel") or "warning")

-- private variables and methods -----------------------------------------

local warnedAbout = {
    priorityConstructor = false,
    priorityMethod      = false,
    priorityTable       = false,
 -- need to think about how blatantly we want to move people off of the legacy style; don't warn for now
    legacyConstructor   = true,
}
local priorityWarning = "***** hs.menubar priority support is not supported in macOS 10.12 and newer and has been deprecated *****"
local legacyWarning   = "***** hs.menubar has been replaced with hs.menubar.statusitem, hs.menubar.menu, and hs.menubar.menu.item and this legacy wrapper may be deprecated in the future. *****"

local legacyMT = {}
-- we're not using weak keys since an explicit delete was part of the legacy module
-- and statusitem requires it anyways
local internalData = {}

local parseMenuTable
parseMenuTable = function(self, menuTable, targetMenu)
    local obj = internalData[self]
    if menuTable then
        for i, v in ipairs(menuTable) do
            repeat -- stupid missing continue hack
                if type(v) ~= "table" then
                    log.wf("entry %d is not a menu item table", i)
                    break
                end
                local s, item = pcall(menuitem.new, v.title)
                if not s then
                    log.wf("malformed menu table entry; missing or invalid title string for entry %d (%s)", i, item)
                    break
                end
                targetMenu:insert(item)
                if v.title == "-" then break end -- separator; nothing else matters
                if type(v.menu) ~= "nil" then
                    if type(v.menu) == "table" then
                        local newMenu = menu.new("HammerspoonSubMenu")
                        parseMenuTable(self, v.menu, newMenu)
                        item:submenu(newMenu)
                    else
                        log.f("expected table for menu key of entry %d", i)
                    end
                end
                if type(v.fn) ~= "nil" then
                    if type(v.fn) == "function" or (type(v.fn) == "table" and (getmetatable(v.fn) or {}).__call) then
                        item:callback(function(itemObj, msg)
                            if msg == "select" then v.fn(eventtap.checkKeyboardModifiers()) end
                        end)
                    else
                        log.f("expected table for fn key of entry %d", i)
                    end
                end
                if type(v.disabled) ~= "nil" then
                    if type(v.disabled) == "boolean" then
                        item:enabled(not v.disabled)
                    else
                        log.f("expected boolean for disabled key of entry %d", i)
                    end
                end
                if type(v.checked) ~= "nil" then
                    if type(v.checked) == "boolean" then
                        item:state(v.checked and "on" or "off")
                    else
                        log.f("expected boolean for checked key of entry %d", i)
                    end
                end
                if type(v.state) ~= "nil" then
                    if type(v.state) == "string" then
                        if v.state == "on" or v.state == "off" or v.state == "mixed" then
                            item:state(v.state)
                        else
                            log.f("expected one of on, off, or mixed for state key of entry %d", i)
                        end
                    else
                        log.f("expected string for state key of entry %d", i)
                    end
                end
                if type(v.tooltip) ~= "nil" then
                    if type(v.tooltip) == "string" then
                        item:tooltip(v.tooltip)
                    else
                        log.f("expected string for tooltip key of entry %d", i)
                    end
                end

                if type(v.indent) ~= "nil" then
                    if math.type(v.indent) == "integer" then
                        item:indentationLevel(v.indent)
                    else
                        log.f("expected integer for indent key of entry %d", i)
                    end
                end

                if type(v.image) ~= "nil" then
                    if type(v.image) == "userdata" and getmetatable(v.image).__name == "hs.image" then
                        item:image(v.image)
                    else
                        log.f("expected hs.image object for image key of entry %d", i)
                    end
                end

                if type(v.onStateImage) ~= "nil" then
                    if type(v.onStateImage) == "userdata" and getmetatable(v.onStateImage).__name == "hs.image" then
                        item:onStateImage(v.onStateImage)
                    else
                        log.f("expected hs.image object for onStateImage key of entry %d", i)
                    end
                end

                if type(v.offStateImage) ~= "nil" then
                    if type(v.offStateImage) == "userdata" and getmetatable(v.offStateImage).__name == "hs.image" then
                        item:offStateImage(v.offStateImage)
                    else
                        log.f("expected hs.image object for offStateImage key of entry %d", i)
                    end
                end

                if type(v.mixedStateImage) ~= "nil" then
                    if type(v.mixedStateImage) == "userdata" and getmetatable(v.mixedStateImage).__name == "hs.image" then
                        item:mixedStateImage(v.mixedStateImage)
                    else
                        log.f("expected hs.image object for mixedStateImage key of entry %d", i)
                    end
                end

                if type(v.shortcut) ~= "nil" then
                    if type(v.shortcut) == "string" then
                        item:keyEquivalent(v.shortcut)
                    else
                        log.f("expected string for shortcut key of entry %d", i)
                    end
                end

            until true
        end
    end
end

local updateMenu = function(self)
    local obj = internalData[self]
    if obj._menuCallback then
        obj._menu:removeAll()
        parseMenuTable(self, obj._menuCallback(eventtap.checkKeyboardModifiers()), obj._menu)
    end
end

local statusitemClick = function(self)
    local obj = internalData[self]
    if not obj._statusitem:menu() and obj._clickCallback then
        obj._clickCallback(eventtap.checkKeyboardModifiers())
    end
end

-- Public interface ------------------------------------------------------

legacyMT.__index = legacyMT
legacyMT.__name  = USERDATA_TAG
legacyMT.__type  = USERDATA_TAG

legacyMT.__tostring = function(self, ...)
    local obj = internalData[self]
    return USERDATA_TAG .. ": " .. (obj._title or "") .. " " .. tostring(obj._menu):match("%(0x.*%)$")
end

legacyMT.setMenu = function(self, ...)
    local obj, args = internalData[self], table.pack(...)

    if args.n == 1 then
        local theMenu = args[1]
        if type(theMenu) == "function" or (type(theMenu) == "table" and (getmetatable(theMenu) or {}).__call) then
            obj._menuCallback = theMenu
            obj._statusitem:menu(obj._menu)
            return self
        elseif type(theMenu) == "table" then
            obj._menu:removeAll()
            parseMenuTable(self, theMenu, obj._menu)
            obj._menuCallback = false
            obj._statusitem:menu(obj._menu)
            return self
        elseif type(theMenu) == "nil" then
            obj._menuCallback = nil
            obj._statusitem:menu(nil)
            return self
        end
    end
    error("expected callback function, menu table, or explicit nil", 2)
end

legacyMT.setClickCallback = function(self, ...)
    local obj, args = internalData[self], table.pack(...)

    if args.n == 1 then
        local callback = args[1]
        if type(callback) == "function" or
           type(callback) == "nil" or
           (type(callback) == "table" and (getmetatable(callback) or {}).__call) then
                obj._statusitem:callback(callback)
                return self
        end
    end
    error("expected function or explicit nil", 2)
end

legacyMT.popupMenu = function(self, loc, ...)
    local obj, args = internalData[self], table.pack(...)

    -- they may have specified nil, so we can't do the `expr and val or val2` shorthand
    local dark = false -- legacy version didn't support dark mode popups, so that's the default
    if args.n > 0 then dark = args[1] end

    if type(obj._menuCallback) ~= "nil" then
        obj._menu:popupMenu(loc, dark)
    else
        statusitemClick(self)
    end
    return self
end

legacyMT.stateImageSize = function(self, ...)
    local obj, args = internalData[self], table.pack(...)

    if args.n == 0 then
        return obj._stateImageSize
    elseif args.n == 1 and type(args[1]) == "number" then
        obj._stateImageSize = args[1]
        return self
    else
        error("expected optional number", 2)
    end
end

legacyMT.setTooltip = function(self, tooltip)
    local obj = internalData[self]
    if obj._statusitem then obj._statusitem:tooltip(tooltip) end
    obj._tooltip = tooltip or ""
    return self
end

legacyMT.setIcon = function(self, icon, template)
    local obj = internalData[self]

    if type(icon) == "string" then
        if string.sub(icon, 1, 6) == "ASCII:" then
            icon = image.imageFromASCII(string.sub(icon, 7, -1))
        else
            icon = image.imageFromPath(icon)
        end
    end
    if icon then
        if type(template) == "boolean" then
            icon:template(template)
        else
            icon:template(true)
        end
    end

    if obj._statusitem then obj._statusitem:image(icon) end
    obj._icon = icon
    return self
end

legacyMT.icon = function(self)
    local obj = internalData[self]
    return obj._icon
end

legacyMT.setTitle = function(self, title)
    local obj = internalData[self]
        if obj._statusitem then obj._statusitem:title(title) end
    obj._title = title or ""
    return self
end

legacyMT.title = function(self)
    local obj = internalData[self]
    return obj._title or ""
end

legacyMT.frame = function(self)
    local obj = internalData[self]
    if obj._statusitem then
        return obj._statusitem:frame()
    else
        return obj._frame
    end
end

legacyMT.isInMenubar = function(self)
    local obj = internalData[self]
    return obj._statusitem and true or false
end

legacyMT.returnToMenuBar = function(self)
    local obj = internalData[self]
    if not obj._statusitem then
        obj._statusitem = statusitem.new(true):title(obj._title)
                                              :tooltip(obj._tooltip)
                                              :menu(obj._menu)

        if obj._icon then obj._statusitem:image(obj._icon) end
        obj._frame = nil
    end
    return self
end

legacyMT.removeFromMenuBar = function(self)
    local obj = internalData[self]
    if obj._statusitem then
        obj._title      = obj._statusitem:title()
        obj._icon       = obj._statusitem:image()
        obj._tooltip    = obj._statusitem:tooltip()
        obj._frame      = obj._statusitem:frame()
        obj._statusitem:delete()
        obj._statusitem = nil
    end
    return self
end

legacyMT.priority = function(self)
    if not warnedAbout.priorityMethod then
        print(priorityWarning)
        warnedAbout.priorityMethod = true
    end
    return self
end

legacyMT.delete = function(self)
    local obj = internalData[self]
    if obj._statusitem then obj._statusitem:delete() end
    obj._statusitem    = nil
    obj._menu          = nil
    obj._clickCallback = nil
    internalData[self] = nil
end

legacyMT._frame   = legacyMT.frame
legacyMT._setIcon = legacyMT.setIcon
legacyMT.__gc     = legacyMT.delete

module.new = function(inMenuBar)
    if not warnedAbout.legacyConstructor then
        print(legacyWarning)
        warnedAbout.legacyConstructor = true
    end
    inMenuBar = type(inMenuBar) == "nil" and true or inMenuBar

    local newMenu = {}
    internalData[newMenu] = {
        _statusitem    = statusitem.new(true):callback(function(_, msg, ...)
            if msg == "mouseClick" then statusitemClick(newMenu) end
        end),
        _menu          = menu.new("HammerspoonPlaceholderMenu"):callback(function(_, msg, ...)
            if msg == "update" then updateMenu(newMenu) end
        end),
        _menuCallback   = nil,
        _clickCallback  = nil,
        _stateImageSize = styledtext.defaultFonts.menu.size,
    }
    newMenu = setmetatable(newMenu, legacyMT)

    -- mimics approach used in original module; frame will match the legacy behavior as well
    if not inMenuBar then newMenu:removeFromMenuBar() end

    return newMenu
end

module.newWithPriority = function()
    if not warnedAbout.priorityConstructor then
        print(priorityWarning)
        warnedAbout.priorityConstructor = true
    end
    return module.new()
end

module.priorities = setmetatable({}, {
    __index = function(self, key)
        if not warnedAbout.priorityTable then
            print(priorityWarning)
            warnedAbout.priorityTable = true
        end
        return ({
            default            = 1000,
            notificationCenter = 2147483647,
            spotlight          = 2147483646,
            system             = 2147483645,
        })[key]
    end,
    __tostring = function(self) return priorityWarning end,
})

-- assign to the registry in case we ever need to access the metatable from the C side
debug.getregistry()[USERDATA_TAG] = legacyMT

-- Return Module Object --------------------------------------------------

return setmetatable(module, {
    _internalData = internalData,
})

