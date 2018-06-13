--- === cp.app.menu ===
---
--- Represents an app's menu bar, providing multi-lingual access to find and
--- trigger menu items.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log = require("hs.logger").new("menu")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local fs = require("hs.fs")
local inspect = require("hs.inspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local archiver = require("cp.plist.archiver")
local axutils = require("cp.ui.axutils")
local localeID = require("cp.i18n.localeID")
local plist = require("cp.plist")
local prop = require("cp.prop")
local rx = require("cp.rx")

--------------------------------------------------------------------------------
-- Local Lua Functions:
--------------------------------------------------------------------------------
local format = string.format
local insert, remove, concat = table.insert, table.remove, table.concat

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- BASE_LOCALE -> string
-- Constant
-- Base Locale string.
local BASE_LOCALE = "Base"

-- NIB_EXT -> string
-- Constant
-- NIB File Extension.
local NIB_EXT = "nib"

-- STRINGS_EXT -> string
-- Constant
-- Strings File Extension.
local STRINGS_EXT = "strings"

-- MENU_FILE_PATH -> string
-- Constant
-- Menu File Path.
local MENU_FILE_PATH = "%s/Contents/Resources/%s.lproj/%s.%s"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local menu = {}
menu.mt = {}

--- cp.app.menu.ROLE -> string
--- Constant
--- The menu role
menu.ROLE = "AXMenuBar"

--- cp.app.menu.NIB_FILE -> string
--- Constant
--- Main NIB File.
menu.NIB_FILE = "NSMainNibFile"

local function findMenuNibPath(app, localeAliases, nibName)
    local appPath = app:path()
    for _, alias in pairs(localeAliases) do
        local path = fs.pathToAbsolute(format(MENU_FILE_PATH, appPath, alias, nibName, NIB_EXT))
        if path then
            return path
        end
    end
end

local function findMenuStringsPath(app, localeAliases, nibName)
    local appPath = app:path()
    for _, alias in pairs(localeAliases) do
        local path = fs.pathToAbsolute(format(MENU_FILE_PATH, appPath, alias, nibName, STRINGS_EXT))
        if path then
            return path
        end
    end
end

-- processMenu(menuData, localeCode, menu) -> table
-- Function
-- Loads a Main Menu locale.
--
-- Parameters:
--  * menuData      - Menu data.
--  * localeCode    - The local code string being processed (eg. "en", "pt_PT")
--  * menuCache     - The table containing the menu structure.
--
-- Returns:
--  * Menu
local function processMenu(menuData, localeCode, menuCache)
    if not menuData then
        return nil
    end
    --------------------------------------------------------------------------------
    -- Process the menu items:
    --------------------------------------------------------------------------------
    menuCache = menuCache or {}
    if menuData.NSMenuItems then
        for i, itemData in ipairs(menuData.NSMenuItems) do
            local item = menuCache[i] or {}
            item[localeCode] = itemData.NSTitle
            item.separator = itemData.NSIsSeparator
            --------------------------------------------------------------------------------
            -- Check if there is a submenu:
            --------------------------------------------------------------------------------
            if itemData.NSSubmenu then
                item.submenu = processMenu(itemData.NSSubmenu, localeCode, item.submenu)
            end
            menuCache[i] = item
        end
    end
    return menuCache
end

local function processNib(menuNib, localeCode, menuCache)
    --------------------------------------------------------------------------------
    -- Find the 'MenuTitles' item:
    --------------------------------------------------------------------------------
    local menuTitles = nil
    for _, item in ipairs(menuNib["IB.objectdata"].NSObjectsKeys) do
        if item.NSName == "_NSMainMenu" and item["$class"] and item["$class"]["$classname"] == "NSMenu" then
            menuTitles = item
            break
        end
    end
    if menuTitles then
        menuCache[localeCode] = true
        return processMenu(menuTitles, localeCode, menuCache)
    else
        log.ef("Unable to locate Main .nib file for %s.", localeCode)
        return nil
    end
end

local function processStrings(menuStrings, localeCode, theMenu)
    if not theMenu[localeCode] then
        for _, item in ipairs(theMenu) do
            local base = item[BASE_LOCALE]
            if base and base.NSKey then
                item[localeCode] = menuStrings and menuStrings[base.NSKey] or base["NS.string"]
            end
            if item.submenu then
                processStrings(menuStrings, localeCode, item.submenu)
            end
        end
    end
end

-- unarchiveNibFile(app,  nibName, localeAliases) -> table
-- Function
-- Unarchives the `.nib` file with the specified app, nib name and local aliases.
-- The first locale alias found to have a `.nib` file will be unarchived and returned.
--
-- Parameters:
-- * app            - The `cp.app` being processed
-- * localeAliases  - The list of locale aliases to check.
-- * nibName        - The nib name for the app
--
-- Returns:
-- * table of unarchived Nib data.
local function readNibFile(app, localeAliases, nibName)
    local path = findMenuNibPath(app, localeAliases, nibName)
    if path then
        return archiver.unarchiveFile(path)
    end
end

local function readStringsFile(app, localeAliases, nibName)
    local path = findMenuStringsPath(app, localeAliases, nibName)
    if path then
        return plist.fileToTable(path)
    end
end

-- loadMenuTitlesLocale(app, locale, menuCache) -> table
-- Method
-- Loads a Main Menu locale.
--
-- Parameters:
--  * app       - The `cp.app` we're loading for.
--  * locale    - The `localeID`.
--  * menuCache - The menu table containing the main menu structure.
--
-- Returns:
--  * The menu table.
local function loadMenuTitlesLocale(app, locale, menuCache)
    local theLocale = localeID(locale)
    if not locale then
        -- it's not a real locale (according to our records...)
        log.wf("Unable to find requested main menu locale: %s", locale)
        return nil
    end

    -- get best supported locale
    theLocale = app:bestSupportedLocale(theLocale)
    if not theLocale or menuCache[theLocale.code] then
        -- not supported, or already processed...
        return
    end

    local nibName = app:info()[menu.NIB_FILE]
    local menuNib = readNibFile(app, theLocale.aliases, nibName)
    if menuNib then
        return processNib(menuNib, theLocale.code, menuCache)
    else
        -- 1. Ensure the 'Base' locale nib is processed.
        if not menuCache[BASE_LOCALE] then
            local baseNib = readNibFile(app, {BASE_LOCALE}, nibName)
            if baseNib then
                processNib(baseNib, BASE_LOCALE, menuCache)
            else
                log.ef("Unable to load `Base.nib` file for app: %s", app:bundleID())
            end
        end

        -- 2. If currently in the `baseLocale` then apply the strings from the NSLocalizedStrings
        if theLocale == app:baseLocale() then
            processStrings(nil, theLocale.code, menuCache)
        end

        -- 3. could be a 'strings' file
        local menuStrings = readStringsFile(app, theLocale.aliases, nibName)
        if menuStrings then
            -- Process the locale's .strings
            processStrings(menuStrings, theLocale.code, menuCache)
        end

        return nil
    end
end

function menu.matches(element)
    return element and element:attributeValue("AXRole") == menu.ROLE and #element > 0
end

--- cp.app.menu.new(app) -> menu
--- Constructor
--- Constructs a new menu for the specified App.
---
--- Parameters:
---  * app - The `cp.app` instance the menu belongs to.
---
--- Returns:
---  * a new menu instance
function menu.new(app)
    local o = prop.extend({
        _app = app,
        _menuTitles = {},
        _itemFinders = {}
    }, menu.mt)

    local UI = app.UI:mutate(function(original, self)
        return axutils.cache(self, "_ui", function()
            return axutils.childMatching(original(), menu.matches)
        end, menu.matches)
    end)

    local showing = UI:ISNOT(nil)

    prop.bind(o) {
        --- cp.app.menu.UI <cp.prop:hs._asm.axuielement; read-only; live>
        --- Field
        --- Returns the `axuielement` representing the menu.
        UI = UI,
        --- cp.app.menu.showing <cp.prop: boolean; read-only; live>
        --- Field
        --- Tells you if the app's Menu Bar is visible.
        showing = showing,
    }

    -- load default locale for the menu when the local changes.
    app.currentLocale:watch(function(newLocale)
        o:getMenuTitles({newLocale})
    end)

    return o
end

--- cp.app.menu:app() -> cp.app
--- Method
--- Returns the `cp.app` instance this belongs to.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.app`.
function menu.mt:app()
    return self._app
end

--- cp.app.menu:getMenuTitles([locales]) -> table
--- Method
--- Returns a table with the available menus, items and sub-menu, in the specified locales (if available).
--- If no `locales` are specified, the app's current locale is loaded.
---
--- This menu may get added to over time if additional locales are loaded - previously loaded locales
--- are not removed from the cache.
---
--- Parameters:
---  * locales       - An optional single `localeID` or a list of `localeID`s to ensure are loaded.
---
--- Returns:
---  * A table of Menu Bar Values
function menu.mt:getMenuTitles(locales)
    local app = self:app()
    if type(locales) ~= "table" then
        local locale = locales or app:currentLocale()
        locales = {locale}
    end

    local menuCache = self._menuTitles
    for _, locale in ipairs(locales) do
        loadMenuTitlesLocale(app, locale, menuCache)
    end

    return menuCache
end

--- cp.app.menu:selectMenuItem(path[, pathLocale][, pressAll]) -> cp.rx.Observable <hs._asm.axuielement>
--- Function
--- Selects a Final Cut Pro Menu Item based on the list of menu titles in English.
---
--- Parameters:
---  * path - The list of menu items you'd like to activate.
---  * pathLocale - The locale the path is in. Defaults to "en".
---  * pressAll - If `true`, all menus will be pressed en route to the target. Defaults to `false`.
---
--- Returns:
---  * An `Observable` which emits the final menu, or an error if the selection failed.
---
--- Notes:
---  * Example usage:
---    `require("cp.app"):forBundleID("com.apple.FinalCut"):menu():selectMenuItem({"View", "Browser", "Toggle Filmstrip/List View"})`
function menu.mt:selectMenuItem(path, pathLocale, pressAll)
    if type(pathLocale) == "boolean" then
        pressAll = pathLocale
        pathLocale = nil
    end

    local subject = rx.AsyncSubject.create()

    local finder = self:findMenuItems(path, pathLocale)

    if not pressAll then
        finder = finder:last()
    end

    finder:flatMap(function(item)
        if item:attributeValue("AXEnabled") then
            return rx.Observable.of(item:doPress())
        else
            return rx.Observable.throw("Menu Item Disabled: "..tostring(item:attributeValue("AXTitle")))
        end
    end):last():subscribe(subject)

    return subject
end

--- cp.app.menu:selectMenu(path[, locale][, pressAll]) -> boolean
--- Function
--- Selects a Final Cut Pro Menu Item based on the list of menu titles in English.
---
--- Parameters:
---  * path - The list of menu items you'd like to activate.
---  * locale - The locale the path is in. Defaults to "en".
---  * pressAll - If `true`, all menus will be pressed en route to the target. Defaults to `false`.
---
--- Returns:
---  * `true` if the press was successful.
---
--- Notes:
---  * Example usage:
---    `require("cp.app"):forBundleID("com.apple.FinalCut"):menu():selectMenu({"View", "Browser", "Toggle Filmstrip/List View"})`
function menu.mt:selectMenu(path, locale, pressAll)
    if type(locale) == "boolean" then
        pressAll = locale
        locale = nil
    end

    local menuItemUI, menuPath = self:findMenuUI(path, locale)

    if pressAll and #menuPath > 0 then
        for _, ui in ipairs(menuPath) do
            if not ui:performAction("AXPress") then
                return false
            end
        end
        return true
    elseif menuItemUI then
        local result = menuItemUI:performAction("AXPress")
        if result then
            return true
        end
    end
    return false
end

-- _isMenuChecked(menu) -> boolean
-- Function
-- Is a menu item checked?
--
-- Parameters:
--  * menuItem - The `axuielementObject` of the menu
--
-- Returns:
--  * `true` if checked otherwise `false`.
local function _isMenuChecked(menuItem)
    return menuItem:attributeValue("AXMenuItemMarkChar") ~= nil
end

--- cp.app.menu:isChecked(path[, locale]) -> boolean
--- Method
--- Is a menu item checked?
---
--- Parameters:
---  * path - At table containing the path to the menu bar item.
---  * locale - The locale the path is in. Defaults to "en".
---
--- Returns:
---  * `true` if checked otherwise `false`.
function menu.mt:isChecked(path, locale)
    local menuItemUI = self:findMenuUI(path, locale)
    return menuItemUI and _isMenuChecked(menuItemUI)
end

--- cp.app.menu:isEnabled(path[, locale]) -> boolean
--- Method
--- Is a menu item enabled?
---
--- Parameters:
---  * path - At table containing the path to the menu bar item.
---  * locale - The locale the path is in. Defaults to "en".
---
--- Returns:
---  * `true` if enabled otherwise `false`.
function menu.mt:isEnabled(path, locale)
    local menuItemUI = self:findMenuUI(path, locale)
    return menuItemUI and menuItemUI:attributeValue("AXEnabled")
end

--- cp.app.menu:addMenuFinder(finder) -> nothing
--- Method
--- Registers an `AXMenuItem` finder function. The finder's job is to take an individual 'find' step and return either the matching child, or nil if it can't be found. It is used by the [addMenuFinder](#addMenuFinder) function. The `finder` should have the following signature:
---
--- ```lua
--- function(parentItem, path, childName, locale) -> childItem
--- ```
---
--- The elements are:
--- * parentItem    - The `AXMenuItem` containing the children. E.g. the `Go To` menu under `Window`.
--- * path          - An array of strings in the specified locale leading to the parent item. E.g. `{"Window", "Go To"}`.
--- * childName     - The name of the next child to find, in the specified locale. E.g. `"Libraries"`.
--- * locale        - The `cp.i18n.localeID` that the menu titles are in.
--- * childItem     - The `AXMenuItem` that was found, or `nil` if not found.
---
--- Parameters:
---  * `finder`     - The finder function
---
--- Returns:
---  * The `AXMenuItem` found, or `nil`.
function menu.mt:addMenuFinder(finder)
    self._itemFinders[#self._itemFinders + 1] = finder
end

-- _translateTitle(menuTitles, title, sourceLocale, targetLocale) -> string
-- Function
-- Looks through the `menuTitles` to find a matching title in the source locale,
-- and returns the equivalent in the target locale, or the original title if it can't be found.
--
-- Parameters:
--  * menuTitles - A table containing the menu map.
--  * title - The title
--  * sourceLocale - Source `cp.i18n.localeID`
--  * targetLocale - Target `cp.i18n.localeID`
--
-- Returns:
--  * The translated title as a string.
local function _translateTitle(menuTitles, title, sourceLocale, targetLocale)
    if menuTitles then
        local sourceCode, targetCode = sourceLocale.code, targetLocale.code
        for _,item in ipairs(menuTitles) do
            if item[sourceCode] == title then
                return item[targetCode]
            end
        end
    end
    return title
end

--- cp.app.menu:findUI([timeout]) -> cp.rx.Observable <hs._asm.axuielement>
--- Method
--- Returns an `Observable` that will emit the next available instance of
--- the Menu's UI once only, then complete.
---
--- Parameters:
---  * timeout - (optional) the number of seconds to wait for the UI. It not provided, defaults to forever.
---
--- Returns:
---  * An `Observer` that emits the UI.
function menu.mt:findUI(timeout)
    local finder = self.UI:observe():find(function(value)
        return value ~= nil and #value > 0
    end)
    return timeout and finder:timeout(timeout * 1000) or finder
end

local function exactMatch(value, pattern)
    if value and pattern then
        local s,e = value:find(pattern)
        return s == 1 and e == value:len()
    end
    return false
end

--- cp.app.menu:findMenuItems(path[, pathLocale][, timeout]) -> cp.rx.Observable <hs._asm.axuielement>
--- Method
--- Returns an `Observable` that will emit each of the menu items along the path.
--- E.g. `findMenuItems({"Edit", "Copy"})` emits the 'Edit' menu then the 'Copy' menu item.
---
--- Each step on the path can be either one of:
---  * a string     - The exact name of the menu item.
---  * a number     - The menu item number, starting from 1.
---  * a function   - Passed one argument - the Menu UI to check - returning `true` if it matches.
---
--- Parameters:
---  * path         - the table of path items.
---  * pathLocale   - (optional) the string or `localeID` with the locale the path labels are in. Defaults to "en"
---  * timeout      - (optional) the number of seconds to allow before failing the operation. Defaults to 10 seconds.
---
--- Returns:
---  * The `Observable` instance.
function menu.mt:findMenuItems(path, pathLocale, timeout)
    if type(path) ~= "table" or #path == 0 then
        return rx.Observable.throw("Please provide a table array of menu steps.")
    end
    if type(pathLocale) == "number" then
        timeout = pathLocale
        pathLocale = nil
    end
    timeout = timeout or 10

    return self:findUI(timeout):flatMap(
        function(ui)
            pathLocale = localeID(pathLocale) or localeID("en")
            local appLocale = self:app():currentLocale()

            local menuTitles = self:getMenuTitles({pathLocale, appLocale})
            local currentPath = {}
            local menuItemName
            local menuUI = ui

            return rx.Observable.fromTable(path, ipairs):flatMap(
                function(step)
                    local menuItemUI
                    if type(step) == "number" then
                        menuItemUI = menuUI[step]
                        menuItemName = _translateTitle(menuTitles, menuItemUI, appLocale, pathLocale)
                    elseif type(step) == "function" then
                        for _, child in ipairs(menuUI) do
                            if step(child) then
                                menuItemUI = child
                                menuItemName = _translateTitle(menuTitles, menuItemUI, appLocale, pathLocale)
                                break
                            end
                        end
                    else
                        menuItemName = step
                        --------------------------------------------------------------------------------
                        -- Check with the finder functions:
                        --------------------------------------------------------------------------------
                        for _, finder in ipairs(self._itemFinders) do
                            menuItemUI = finder(menuUI, currentPath, step, pathLocale)
                            if menuItemUI then
                                break
                            end
                        end

                        if not menuItemUI and menuTitles then
                            --------------------------------------------------------------------------------
                            -- See if the menu is in the map:
                            --------------------------------------------------------------------------------
                            for _, item in ipairs(menuTitles) do
                                local pathItemTitle = item[pathLocale.code]
                                if pathItemTitle and pathItemTitle:match(step) ~= nil then
                                    menuItemUI = item.ui
                                    if not axutils.isValid(menuItemUI) then
                                        local currentTitle = item[appLocale.code]
                                        if currentTitle then
                                            currentTitle = currentTitle:gsub("%%@", ".*")
                                            menuItemUI = axutils.childMatching(menuUI, function(child) return exactMatch(child:attributeValue("AXTitle"), currentTitle) end)
                                            --------------------------------------------------------------------------------
                                            -- Cache the menu item, since getting children can be expensive:
                                            --------------------------------------------------------------------------------
                                            item.ui = menuItemUI
                                        else
                                            return rx.Observable.throw("Unable to find '%s' in '%s' with %s.", pathItemTitle, concat(currentPath, " > ", appLocale))
                                        end
                                    end
                                    menuTitles = item.submenu
                                    break
                                end
                            end
                        end

                        if not menuItemUI then
                            --------------------------------------------------------------------------------
                            -- We don't have it in our list, so look it up manually.
                            -- Hopefully they are in English!
                            --------------------------------------------------------------------------------
                            log.wf("Searching manually for '%s' in '%s' while in %s.", step, concat(currentPath, " > "), appLocale)
                            menuItemUI = axutils.childWith(menuUI, "AXTitle", step)
                        end
                    end

                    if menuItemUI then
                        if #menuItemUI == 1 then
                            -- the item is a sub-menu. Find the next values.
                            menuUI = menuItemUI[1]
                            for _, item in ipairs(menuTitles) do
                                local mapTitle = item[appLocale.code]
                                if mapTitle and exactMatch(menuItemUI:attributeValue("AXTitle"), mapTitle:gsub("%%@", ".*")) then
                                    menuTitles = item
                                    break
                                end
                            end
                        end

                        insert(currentPath, menuItemName)

                        return rx.Observable.of(menuItemUI)
                    else
                        return rx.Observable.throw(format("Unable to find '%s' in '%s' while in %s.", step, concat(currentPath, " > "), appLocale))
                    end
                end
            )
        end
    )
end

--- cp.app.menu:findMenuUI(path[, locale]) -> Menu UI, table
--- Method
--- Finds a specific Menu UI element for the provided path.
--- E.g. `findMenuUI({"Edit", "Copy"})` returns the 'Copy' menu item in the 'Edit' menu.
---
--- Each step on the path can be either one of:
---  * a string     - The exact name of the menu item.
---  * a number     - The menu item number, starting from 1.
---  * a function   - Passed one argument - the Menu UI to check - returning `true` if it matches.
---
--- Parameters:
---  * path         - The path list to search for.
---  * locale       - The locale code the path is in. E.g. "en" or "fr". Defaults to "en".
---
--- Returns:
---  * The Menu UI, or `nil` if it could not be found.
---  * The full list of Menu UIs for the path in a table.
function menu.mt:findMenuUI(path, locale)
    assert(type(path) == "table" and #path > 0, "Please provide a table array of menu steps.")

    --------------------------------------------------------------------------------
    -- Start at the top of the menu bar list:
    --------------------------------------------------------------------------------
    locale = localeID(locale) or localeID("en")
    local appLocale = self:app():currentLocale()

    local menuTitles = self:getMenuTitles({locale, appLocale})
    local menuUI = self:UI()
    if not menuUI then
        return nil
    end

    local menuItemUI = nil
    local menuItemName = nil
    local currentPath = {}
    local menuPath = {}

    --------------------------------------------------------------------------------
    -- Step through the path:
    --------------------------------------------------------------------------------
    for i, step in ipairs(path) do
        menuItemUI = nil
        --------------------------------------------------------------------------------
        -- Check what type of step it is:
        --------------------------------------------------------------------------------
        if type(step) == "number" then
            --------------------------------------------------------------------------------
            -- Access it by index:
            --------------------------------------------------------------------------------
            menuItemUI = menuUI[step]
            menuItemName = _translateTitle(menuTitles, menuItemUI, appLocale, locale)
        elseif type(step) == "function" then
            --------------------------------------------------------------------------------
            -- Check each child against the function:
            --------------------------------------------------------------------------------
            for _, child in ipairs(menuUI) do
                if step(child) then
                    menuItemUI = child
                    menuItemName = _translateTitle(menuTitles, menuItemUI, appLocale, locale)
                    break
                end
            end
        else
            --------------------------------------------------------------------------------
            -- Look it up by name:
            --------------------------------------------------------------------------------
            menuItemName = step
            --------------------------------------------------------------------------------
            -- Check with the finder functions:
            --------------------------------------------------------------------------------
            for _, finder in ipairs(self._itemFinders) do
                menuItemUI = finder(menuUI, currentPath, step, locale)
                if menuItemUI then
                    break
                end
            end

            if not menuItemUI and menuTitles then
                --------------------------------------------------------------------------------
                -- See if the menu is in the map:
                --------------------------------------------------------------------------------
                for _, item in ipairs(menuTitles) do
                    if item[locale.code] == step then
                        menuItemUI = item.ui
                        if not axutils.isValid(menuItemUI) then
                            local currentTitle = item[appLocale.code]
                            menuItemUI = axutils.childWith(menuUI, "AXTitle", currentTitle)
                            --------------------------------------------------------------------------------
                            -- Cache the menu item, since getting children can be expensive:
                            --------------------------------------------------------------------------------
                            item.ui = menuItemUI
                        end
                        menuTitles = item.submenu
                        break
                    end
                end
            end

            if not menuItemUI then
                --------------------------------------------------------------------------------
                -- We don't have it in our list, so look it up manually.
                -- Hopefully they are in English!
                --------------------------------------------------------------------------------
                log.wf("Searching manually for '%s' in '%s' while in %s.", step, concat(currentPath, ", "), appLocale)
                menuItemUI = axutils.childWith(menuUI, "AXTitle", step)
            end
        end

        if menuItemUI then
            insert(menuPath, menuItemUI)
            if #menuItemUI == 1 then
                --------------------------------------------------------------------------------
                -- Assign the contained AXMenu to the menuUI,
                -- it contains the next set of AXMenuItems.
                --------------------------------------------------------------------------------
                menuUI = menuItemUI[1]
            end
            insert(currentPath, menuItemName)
        else
            local value = type(step) == "string" and '"' .. step .. '" (' .. locale.code .. ")" or tostring(step)
            log.wf(
                "Unable to match step #%d in %s, a %s with a value of %s with the app in %s",
                i,
                inspect(path),
                type(step),
                value,
                appLocale
            )
            return nil
        end
    end

    return menuItemUI, menuPath
end

--- cp.app.menu:findMenuItemsUI(path[, locale]) -> axuielementObject
--- Method
--- Returns the set of menu items in the provided path. If the path contains a menu, the
--- actual children of that menu are returned, otherwise the menu item itself is returned.
---
--- Parameters:
---  * path - A table containing the path to the menu.
---  * locale - The locale the path is in. Defaults to "en".
---
--- Returns:
---  * An `axuielementObject` for the menu items.
function menu.mt:findMenuItemsUI(path, locale)
    local menuUI = self:findMenuUI(path, locale)
    if menuUI and #menuUI == 1 then
        return menuUI[1]:children()
    end
    return menuUI
end

--- cp.app.menu:visitMenuItems(visitFn[, startPath[, locale]]) -> nil
--- Method
--- Walks the menu tree, calling the `visitFn` on all the 'item' values - that is,
--- `AXMenuItem`s that don't have any sub-menus.
---
--- The `visitFn` will be called on each menu item with the following parameters:
---
--- ```
--- function(path, menuItem)
--- ```
---
--- The `menuItem` is the AXMenuItem object, and the `path` is an array with the path to that
--- menu item. For example, if it is the "Copy" item in the "Edit" menu, the path will be
--- `{ "Edit" }`.
---
--- Parameters:
---  * visitFn - The function called for each menu item.
---  * startPath - The path to the menu item to start at.
---  * locale - The locale the path is in. Defaults to "en".
---
--- Returns:
---  * Nothing
function menu.mt:visitMenuItems(visitFn, startPath, locale)
    local menuUI
    local path = startPath or {}
    if #path > 0 then
        menuUI = self:findMenuUI(path, locale)
        remove(path)
    else
        menuUI = self:UI()
    end
    if menuUI then
        self:_visitMenuItems(visitFn, path, locale, menuUI)
    end
end

-- cp.app.menu:_visitMenuItems(visitFn, path, menuUI) -> hs._asm.axuielement
-- Method
-- Returns the set of menu items in the provided path. If the path contains a menu, the
--
-- Parameters:
--  * visitFn - A function that is called on all the item values.
--  * path - Table containing the path to the menu
--  * locale - The locale the path is in. Defaults to "en".
--  * menuUI - The `axuielement` of the menu item.
--
-- Returns:
--  * An `axuielementObject` for the menu items.
function menu.mt:_visitMenuItems(visitFn, path, locale, menuUI)
    local role = menuUI:attributeValue("AXRole")
    local children = menuUI:attributeValue("AXChildren")
    if role == "AXmenu" or role == "AXMenu" then
        if children then
            for _, item in ipairs(children) do
                self:_visitMenuItems(visitFn, path, locale, item)
            end
        end
    elseif role == "AXmenuItem" or role == "AXMenuItem" then
        local title = menuUI:attributeValue("AXTitle")
        if #children == 1 then
            -- log.df("_visitMenuItems: post remove: path = %s", hs.inspect(path))
            --------------------------------------------------------------------------------
            -- Add the title:
            --------------------------------------------------------------------------------
            insert(path, title)
            -- log.df("_visitMenuItems: post insert: path = %s", hs.inspect(path))
            self:_visitMenuItems(visitFn, path, locale, children[1])
            --------------------------------------------------------------------------------
            -- Drop the extra title:
            --------------------------------------------------------------------------------
            -- log.df("_visitMenuItems: pre remove: path = %s", hs.inspect(path))
            remove(path)
        else
            if title ~= nil and title ~= "" then
                visitFn(path, menuUI)
            end
        end
    end
end

function menu.mt:__tostring()
    return format("cp.app.menu: %s", self:app():bundleID())
end

return menu
