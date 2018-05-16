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
local log                                           = require("hs.logger").new("menu")
local inspect                                       = require("hs.inspect")

local fs                                            = require("hs.fs")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local localeID                                      = require("cp.i18n.localeID")
local prop                                          = require("cp.prop")
local plist                                         = require("cp.plist")
local archiver                                      = require("cp.plist.archiver")
local axutils                                       = require("cp.ui.axutils")

local format                                        = string.format

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local menu = {}
menu.mt = {}

local BASE_LOCALE = "Base"

--- cp.app.menu.ROLE -> string
--- Constant
--- The menu role
menu.ROLE = "AXMenuBar"

menu.NIB_FILE = "NSMainNibFile"

local NIB_EXT = "nib"
local STRINGS_EXT = "strings"

local MENU_FILE_PATH = "%s/Contents/Resources/%s.lproj/%s.%s"

local function findMenuNibPath(app, localeAliases, nibName)
    local appPath = app:path()
    for _,alias in pairs(localeAliases) do
        local path = fs.pathToAbsolute(format(MENU_FILE_PATH, appPath, alias, nibName, NIB_EXT))
        if path then return path end
    end
end

local function findMenuStringsPath(app, localeAliases, nibName)
    local appPath = app:path()
    for _,alias in pairs(localeAliases) do
        local path = fs.pathToAbsolute(format(MENU_FILE_PATH, appPath, alias, nibName, STRINGS_EXT))
        if path then return path end
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
        for i,itemData in ipairs(menuData.NSMenuItems) do
            local item = menuCache[i] or {}
            item[localeCode]  = itemData.NSTitle
            item.separator  = itemData.NSIsSeparator
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
    -- Find the 'MainMenu' item:
    --------------------------------------------------------------------------------
    local mainMenu = nil
    for _,item in ipairs(menuNib["IB.objectdata"].NSObjectsKeys) do
        if item.NSName == "_NSMainMenu" and item["$class"] and item["$class"]["$classname"] == "NSMenu" then
            mainMenu = item
            break
        end
    end
    if mainMenu then
        menuCache[localeCode] = true
        return processMenu(mainMenu, localeCode, menuCache)
    else
        log.ef("Unable to locate Main .nib file for %s.", localeCode)
        return nil
    end
end

local function processStrings(menuStrings, localeCode, theMenu)
    if not theMenu[localeCode] then
        for _,item in ipairs(theMenu) do
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

-- loadMainMenuLocale(app, locale, menuCache) -> table
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
local function loadMainMenuLocale(app, locale, menuCache)
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
      _app          = app,
      _mainMenu     = {},
      _itemFinders  = {},
    }, menu.mt)

    local UI = app.UI:mutate(function(original, self)
        return axutils.cache(self, "_ui", function()
            local appUI = original()
            return appUI and axutils.childWithRole(appUI, menu.ROLE)
        end, function(ui) return ui and ui:attributeValue("AXRole") == menu.ROLE end)
    end)

    local showing = UI:mutate(function(original)
        return original() ~= nil
    end)

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

    -- load default locale the menu when the local changes.
    app.currentLocale:watch(function(newLocale)
        o:getMainMenu({newLocale})
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

--- cp.app.menu:getMainMenu([locales]) -> table
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
function menu.mt:getMainMenu(locales)
    local app = self:app()
    if type(locales) ~= "table" then
        local locale = locales or app:currentLocale()
        locales = {locale}
    end

    local menuCache = self._mainMenu
    for _,locale in ipairs(locales) do
        loadMainMenuLocale(app, locale, menuCache)
    end

    return menuCache
end

--- cp.app.menu:selectMenu(path) -> boolean
--- Function
--- Selects a Final Cut Pro Menu Item based on the list of menu titles in English.
---
--- Parameters:
---  * path - The list of menu items you'd like to activate.
---
--- Returns:
---  * `true` if the press was successful.
---
--- Notes:
---  * Example usage:
---    `require("cp.app"):forBundleID("com.apple.FinalCut"):menu():selectMenu({"View", "Browser", "Toggle Filmstrip/List View"})`
function menu.mt:selectMenu(path)

    local menuItemUI = self:findMenuUI(path)

    --------------------------------------------------------------------------------
    -- NOTE: For some reason this AXEnabled line was causing all kinds of issues.
    --       I think it's because, like the Undo button, Final Cut Pro doesn't
    --       actually update the menu until the user clicks the root menu item.
    --------------------------------------------------------------------------------
    --if menuItemUI and menuItemUI:attributeValue("AXEnabled") then

    if menuItemUI then
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

--- cp.app.menu:isChecked(path) -> boolean
--- Method
--- Is a menu item checked?
---
--- Parameters:
---  * path - At table containing the path to the menu bar item.
---
--- Returns:
---  * `true` if checked otherwise `false`.
function menu.mt:isChecked(path)
    local menuItemUI = self:findMenuUI(path)
    return menuItemUI and _isMenuChecked(menuItemUI)
end

--- cp.app.menu:isEnabled(path) -> boolean
--- Method
--- Is a menu item enabled?
---
--- Parameters:
---  * path - At table containing the path to the menu bar item.
---
--- Returns:
---  * `true` if enabled otherwise `false`.
function menu.mt:isEnabled(path)
    local menuItemUI = self:findMenuUI(path)
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
--- * `parentItem`  - The `AXMenuItem` containing the children. E.g. the `Go To` menu under `Window`.
--- * `path`        - An array of strings in the specified locale leading to the parent item. E.g. `{"Window", "Go To"}`.
--- * `childName`   - The name of the next child to find, in the specified locale. E.g. `"Libraries"`.
--- * `locale`      - The `cp.i18n.localeID` that the menu titles are in.
--- * `childItem`   - The `AXMenuItem` that was found, or `nil` if not found.
---
--- Parameters:
---  * `finder`     - The finder function
---
--- Returns:
---  * The `AXMenuItem` found, or `nil`.
function menu.mt:addMenuFinder(finder)
    self._itemFinders[#self._itemFinders+1] = finder
end

-- _translateTitle(menuMap, title, sourceLocale, targetLocale) -> string
-- Function
-- Looks through the `menuMap` to find a matching title in the source locale,
-- and returns the equivalent in the target locale, or the original title if it can't be found.
--
-- Parameters:
--  * menuMap - A table containing the menu map.
--  * title - The title
--  * sourceLocale - Source `cp.i18n.localeID`
--  * targetLocale - Target `cp.i18n.localeID`
--
-- Returns:
--  * The translated title as a string.
local function _translateTitle(menuMap, title, sourceLocale, targetLocale)
    if menuMap then
        local sourceCode, targetCode = sourceLocale.code, targetLocale.code
        for _ in ipairs(menuMap) do
            if menuMap[sourceCode] == title then
                return menuMap[targetCode]
            end
        end
    end
    return title
end

--- cp.app.menu:findMenuUI(path[, locale]) -> Menu UI
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
---  * `path`       - The path list to search for.
---  * `locale`     - The locale code the path is in. E.g. "en" or "fr". Defaults to "en".
---
--- Returns:
---  * The Menu UI, or `nil` if it could not be found.
function menu.mt:findMenuUI(path, locale)
    assert(type(path) == "table" and #path > 0, "Please provide a table array of menu steps.")

    --------------------------------------------------------------------------------
    -- Start at the top of the menu bar list:
    --------------------------------------------------------------------------------
    locale = localeID(locale) or localeID("en")
    local appLocale = self:app():currentLocale()

    local menuMap = self:getMainMenu({locale, appLocale})
    local menuUI = self:UI()
    if not menuUI then
        return nil
    end

    local menuItemUI = nil
    local menuItemName = nil
    local currentPath = {}

    --------------------------------------------------------------------------------
    -- Step through the path:
    --------------------------------------------------------------------------------
    for _,step in ipairs(path) do
        menuItemUI = nil
        --------------------------------------------------------------------------------
        -- Check what type of step it is:
        --------------------------------------------------------------------------------
        if type(step) == "number" then
            --------------------------------------------------------------------------------
            -- Access it by index:
            --------------------------------------------------------------------------------
            menuItemUI = menuUI[step]
            menuItemName = _translateTitle(menuMap, menuItemUI, appLocale, locale)
        elseif type(step) == "function" then
            --------------------------------------------------------------------------------
            -- Check each child against the function:
            --------------------------------------------------------------------------------
            for _,child in ipairs(menuUI) do
                if step(child) then
                    menuItemUI = child
                    menuItemName = _translateTitle(menuMap, menuItemUI, appLocale, locale)
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
            for _,finder in ipairs(self._itemFinders) do
                menuItemUI = finder(menuUI, currentPath, step, locale)
                if menuItemUI then
                    break
                end
            end

            if not menuItemUI and menuMap then
                --------------------------------------------------------------------------------
                -- See if the menu is in the map:
                --------------------------------------------------------------------------------
                for _,item in ipairs(menuMap) do
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
                        menuMap = item.submenu
                        break
                    end
                end
            end

            if not menuItemUI then
                --------------------------------------------------------------------------------
                -- We don't have it in our list, so look it up manually.
                -- Hopefully they are in English!
                --------------------------------------------------------------------------------
                log.wf("Searching manually for '%s' in '%s' while in %s.", step, table.concat(currentPath, ", "), appLocale)
                menuItemUI = axutils.childWith(menuUI, "AXTitle", step)
            end
        end

        if menuItemUI then
            if #menuItemUI == 1 then
                --------------------------------------------------------------------------------
                -- Assign the contained AXMenu to the menuUI,
                -- it contains the next set of AXMenuItems.
                --------------------------------------------------------------------------------
                menuUI = menuItemUI[1]
            end
            table.insert(currentPath, menuItemName)
        else
            log.wf("Unable to find a menu matching '%s' (%s) in %s", inspect(step), locale, appLocale)
            return nil
        end
    end

    return menuItemUI
end

--- cp.app.menu:findMenuItemsUI(path) -> axuielementObject
--- Method
--- Returns the set of menu items in the provided path. If the path contains a menu, the
--- actual children of that menu are returned, otherwise the menu item itself is returned.
---
--- Parameters:
---  * path - A table containing the path to the menu.
---
--- Returns:
---  * An `axuielementObject` for the menu items.
function menu.mt:findMenuItemsUI(path)
    local menuUI = self:findMenuUI(path)
    if menuUI and #menuUI == 1 then
        return menuUI[1]:children()
    end
    return menuUI
end

--- cp.app.menu:visitMenuItems(visitFn[, startPath]) -> nil
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
---  * `visitFn`    - The function called for each menu item.
---  * `startPath`  - The path to the menu item to start at.
---
--- Returns:
---  * Nothing
function menu.mt:visitMenuItems(visitFn, startPath)
    local menuUI
    local path = startPath or {}
    if #path > 0 then
        menuUI = self:findMenuUI(path)
        table.remove(path)
    else
        menuUI = self:UI()
    end
    if menuUI then
        self:_visitMenuItems(visitFn, path, menuUI)
    end
end

-- cp.app.menu:_visitMenuItems(visitFn, path, menuUI) -> hs._asm.axuielement
-- Method
-- Returns the set of menu items in the provided path. If the path contains a menu, the
--
-- Parameters:
--  * visitFn - A function that is called on all the item values.
--  * path - Table containing the path to the menu
--  * menuUI - The `axuielement` of the menu item.
--
-- Returns:
--  * An `axuielementObject` for the menu items.
function menu.mt:_visitMenuItems(visitFn, path, menuUI)
    local role = menuUI:attributeValue("AXRole")
    local children = menuUI:attributeValue("AXChildren")
    if role == "AXmenu" or role == "AXMenu" then
        if children then
            for _,item in ipairs(children) do
                self:_visitMenuItems(visitFn, path, item)
            end
        end
    elseif role == "AXmenuItem" or role == "AXMenuItem" then
        local title = menuUI:attributeValue("AXTitle")
        if #children == 1 then
            --------------------------------------------------------------------------------
            -- Add the title:
            --------------------------------------------------------------------------------
            table.insert(path, title)
            -- log.df("_visitMenuItems: post insert: path = %s", hs.inspect(path))
            self:_visitMenuItems(visitFn, path, children[1])
            --------------------------------------------------------------------------------
            -- Drop the extra title:
            --------------------------------------------------------------------------------
            -- log.df("_visitMenuItems: pre remove: path = %s", hs.inspect(path))
            table.remove(path)
            -- log.df("_visitMenuItems: post remove: path = %s", hs.inspect(path))
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