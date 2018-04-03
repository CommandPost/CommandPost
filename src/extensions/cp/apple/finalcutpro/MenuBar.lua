--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.MenuBar ===
---
--- Represents the Final Cut Pro menu bar, providing functions that allow different tasks to be accomplished.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                                           = require("hs.logger").new("menubar")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local archiver                                      = require("cp.plist.archiver")
local axutils                                       = require("cp.ui.axutils")
local just                                          = require("cp.just")
local plist                                         = require("cp.plist")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local MenuBar = {}

--- cp.apple.finalcutpro.MenuBar.ROLE -> string
--- Constant
--- The menubar role
MenuBar.ROLE = "AXMenuBar"

--- cp.apple.finalcutpro.MenuBar:new(App) -> MenuBar
--- Function
--- Constructs a new MenuBar for the specified App.
---
--- Parameters:
---  * app - The App instance the MenuBar belongs to.
---
--- Returns:
---  * a new MenuBar instance
function MenuBar:new(app)
    local o = {
      _app          = app,
      _itemFinders  = {},
    }
    setmetatable(o, self)
    self.__index = self

    return o
end

--- cp.apple.finalcutpro.MenuBar:app() -> App
--- Method
--- Returns the app instance representing Final Cut Pro.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function MenuBar:app()
    return self._app
end

--- cp.apple.finalcutpro.MenuBar:UI() -> axuielementObject
--- Method
--- Returns the Final Cut Pro Menu Bar Accessibility Object
---
--- Parameters:
---  * None
---
--- Returns:
---  * An `axuielementObject` on `nil`
function MenuBar:UI()
    return axutils.cache(self, "_ui", function()
        local appUI = self:app():UI()
        return appUI and axutils.childWith(appUI, "AXRole", MenuBar.ROLE)
    end)
end

--- cp.apple.finalcutpro.MenuBar:isShowing() -> boolean
--- Method
--- Tells you if the Final Cut Pro Menu Bar is visible.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if showing, otherwise `false`
function MenuBar:isShowing()
    return self:UI() ~= nil
end

--- cp.apple.finalcutpro.MenuBar:getMainMenu() -> table
--- Method
--- Returns a table of all the possible Menu Bar values for each language.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of Menu Bar Values
function MenuBar:getMainMenu()
    if not MenuBar._mainMenu then
        MenuBar._mainMenu = self:_loadMainMenu()
    end
    return MenuBar._mainMenu
end

--- cp.apple.finalcutpro.MenuBar:selectMenu(path) -> boolean
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
---    `require("cp.apple.finalcutpro"):menuBar():selectMenu({"View", "Browser", "Toggle Filmstrip/List View"})`
function MenuBar:selectMenu(path)
    local menuItemUI = self:findMenuUI(path)
    if menuItemUI and menuItemUI:attributeValue("AXEnabled") then
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
--  * menu - The `axuielementObject` of the menu
--
-- Returns:
--  * `true` if checked otherwise `false`.
local function _isMenuChecked(menu)
    return menu:attributeValue("AXMenuItemMarkChar") ~= nil
end

--- cp.apple.finalcutpro.MenuBar:isChecked(path) -> boolean
--- Method
--- Is a menubar item checked?
---
--- Parameters:
---  * path - At table containing the path to the menu bar item.
---
--- Returns:
---  * `true` if checked otherwise `false`.
function MenuBar:isChecked(path)
    local menuItemUI = self:findMenuUI(path)
    return menuItemUI and _isMenuChecked(menuItemUI)
end

--- cp.apple.finalcutpro.MenuBar:isEnabled(path) -> boolean
--- Method
--- Is a menubar item enabled?
---
--- Parameters:
---  * path - At table containing the path to the menu bar item.
---
--- Returns:
---  * `true` if enabled otherwise `false`.
function MenuBar:isEnabled(path)
    local menuItemUI = self:findMenuUI(path)
    return menuItemUI and menuItemUI:attributeValue("AXEnabled")
end

--- cp.apple.finalcutpro.MenuBar:checkMenu(path, wait) -> boolean
--- Method
--- Checks a menu item.
---
--- Parameters:
---  * path - At table containing the path to the menu bar item.
---  * wait - How long to wait before checking.
---
--- Returns:
---  * `true` if successful, otherwise `false`.
function MenuBar:checkMenu(path, wait)
    local menuItemUI = self:findMenuUI(path)
    if menuItemUI then
        if not _isMenuChecked(menuItemUI) then
            menuItemUI:doPress()
            if wait then
                just.doUntil(function() return _isMenuChecked(menuItemUI) end, 5)
            end
        end
        return true
    end
    return false
end

--- cp.apple.finalcutpro.MenuBar:uncheckMenu(path, wait) -> boolean
--- Method
--- Uncheck's a menu item.
---
--- Parameters:
---  * path - At table containing the path to the menu bar item.
---  * wait - How long to wait before unchecking.
---
--- Returns:
---  * `true` if successful, otherwise `false`.
function MenuBar:uncheckMenu(path, wait)
    local menuItemUI = self:findMenuUI(path)
    if menuItemUI then
        if _isMenuChecked(menuItemUI) then
            menuItemUI:doPress()
            if wait then
                just.doUntil(function() return not _isMenuChecked(menuItemUI) end, 5)
            end
        end
        return true
    end
    return false
end

--- cp.apple.finalcutpro.MenuBar:addMenuFinder(finder) -> nothing
--- Method
--- Registers an `AXMenuItem` finder function. The finder's job is to take an individual 'find' step and return either the matching child, or nil if it can't be found. It is used by the [addMenuFinder](#addMenuFinder) function. The `finder` should have the following signature:
---
--- ```lua
--- function(parentItem, path, childName, language) -> childItem
--- ```
---
--- The elements are:
--- * `parentItem`  - The `AXMenuItem` containing the children. E.g. the `Go To` menu under `Window`.
--- * `path`        - An array of strings in the specified language leading to the parent item. E.g. `{"Window", "Go To"}`.
--- * `childName`   - The name of the next child to find, in the specified language. E.g. `"Libraries"`.
--- * `language`    - The language that the menu titles are in.
--- * `childItem`   - The `AXMenuItem` that was found, or `nil` if not found.
---
--- Parameters:
---  * `finder`     - The finder function
---
--- Returns:
---  * The `AXMenuItem` found, or `nil`.
function MenuBar:addMenuFinder(finder)
    self._itemFinders[#self._itemFinders+1] = finder
end

-- _translateTitle(menuMap, title, sourceLanguage, targetLanguage) -> string
-- Function
-- Looks through the `menuMap` to find a matching title in the source language,
-- and returns the equivalent in the target language, or the original title if it can't be found.
--
-- Parameters:
--  * menuMap - A table containing the menu map.
--  * title - The title
--  * sourceLanguage - Source Language
--  * targetLanguage - Target language
--
-- Returns:
--  * The translated title as a string.
local function _translateTitle(menuMap, title, sourceLanguage, targetLanguage)
    if menuMap then
        for _ in ipairs(menuMap) do
            if menuMap[sourceLanguage] == title then
                return menuMap[targetLanguage]
            end
        end
    end
    return title
end

--- cp.apple.finalcutpro.MenuBar:findMenuUI(path) -> Menu UI
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
---  * `language`   - The language code the path is in. E.g. "en" or "fr". Defaults to the
---
--- Returns:
---  * The Menu UI, or `nil` if it could not be found.
function MenuBar:findMenuUI(path, language)
    assert(type(path) == "table" and #path > 0, "Please provide a table array of menu steps.")

    --------------------------------------------------------------------------------
    -- Start at the top of the menu bar list:
    --------------------------------------------------------------------------------
    local menuMap = self:getMainMenu()
    local menuUI = self:UI()
    language = language or "en"
    local appLang = self:app():currentLanguage() or "en"

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
            menuItemName = _translateTitle(menuMap, menuItemUI, appLang, language)
        elseif type(step) == "function" then
            --------------------------------------------------------------------------------
            -- Check each child against the function:
            --------------------------------------------------------------------------------
            for _,child in ipairs(menuUI) do
                if step(child) then
                    menuItemUI = child
                    menuItemName = _translateTitle(menuMap, menuItemUI, appLang, language)
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
                menuItemUI = finder(menuUI, currentPath, step, language)
                if menuItemUI then
                    break
                end
            end

            if not menuItemUI and menuMap then
                --------------------------------------------------------------------------------
                -- See if the menu is in the map:
                --------------------------------------------------------------------------------
                for _,item in ipairs(menuMap) do
                    if item[language] == step then
                        menuItemUI = item.item
                        if not axutils.isValid(menuItemUI) then
                            menuItemUI = axutils.childWith(menuUI, "AXTitle", item[appLang])
                            --------------------------------------------------------------------------------
                            -- Cache the menu item, since getting children can be expensive:
                            --------------------------------------------------------------------------------
                            item.item = menuItemUI
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
                log.wf("Searching manually for '%s' in '%s'.", step, table.concat(currentPath, ", "))
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
            log.wf("Unable to find a menu called '%s'", step)
            return nil
        end
    end

    return menuItemUI
end

--- cp.apple.finalcutpro.MenuBar:findMenuItemsUI(path) -> axuielementObject
--- Method
--- Returns the set of menu items in the provided path. If the path contains a menu, the
--- actual children of that menu are returned, otherwise the menu item itself is returned.
---
--- Parameters:
---  * path - A table containing the path to the menu.
---
--- Returns:
---  * An `axuielementObject` for the menu items.
function MenuBar:findMenuItemsUI(path)
    local menu = self:findMenuUI(path)
    if menu and #menu == 1 then
        return menu[1]:children()
    end
    return menu
end

--- cp.apple.finalcutpro.MenuBar:visitMenuItems(visitFn[, startPath]) -> nil
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
function MenuBar:visitMenuItems(visitFn, startPath)
    local menu
    local path = startPath or {}
    if #path > 0 then
        menu = self:findMenuUI(path)
        table.remove(path)
    else
        menu = self:UI()
    end
    if menu then
        self:_visitMenuItems(visitFn, path, menu)
    end
end

-- cp.apple.finalcutpro.MenuBar:_visitMenuItems(visitFn, path, menu) -> axuielementObject
-- Method
-- Returns the set of menu items in the provided path. If the path contains a menu, the
--
-- Parameters:
--  * visitFn - A function that is called on all the item values.
--  * path - Table containing the path to the menu
--  * menu - The `axuielementObject` of the menu item.
--
-- Returns:
--  * An `axuielementObject` for the menu items.
function MenuBar:_visitMenuItems(visitFn, path, menu)
    local role = menu:attributeValue("AXRole")
    local children = menu:attributeValue("AXChildren")
    if role == "AXMenuBar" or role == "AXMenu" then
        if children then
            for _,item in ipairs(children) do
                self:_visitMenuItems(visitFn, path, item)
            end
        end
    elseif role == "AXMenuBarItem" or role == "AXMenuItem" then
        local title = menu:attributeValue("AXTitle")
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
                visitFn(path, menu)
            end
        end
    end
end

-- cp.apple.finalcutpro.MenuBar:_loadMainMenu(languages) -> table
-- Method
-- Loads a Main Menu Language.
--
-- Parameters:
--  * languages - A table of languages.
--
-- Returns:
--  * The menu table.
function MenuBar:_loadMainMenu(languages)
    languages = languages or self:app():getSupportedLanguages()
    local menu = {} -- TODO: David, I don't understand the point of this table?
    for _,language in ipairs(languages) do
        if language then
            self:_loadMainMenuLanguage(language, menu)
        else
            log.wf("Received a nil language request.")
        end
    end
    return menu
end

-- cp.apple.finalcutpro.MenuBar:_loadMainMenuLanguage(language, menu) -> table
-- Method
-- Loads a Main Menu Language.
--
-- Parameters:
--  * language - The language to load as a string.
--  * menu - The menu.
--
-- Returns:
--  * The menu table.
function MenuBar:_loadMainMenuLanguage(language, menu)
    local menuPlist = plist.fileToTable(string.format("%s/Contents/Resources/%s.lproj/MainMenu.nib", self:app():getPath(), language))
    if menuPlist then
        local menuArchive = archiver.unarchive(menuPlist)
        --------------------------------------------------------------------------------
        -- Find the 'MainMenu' item:
        --------------------------------------------------------------------------------
        local mainMenu = nil
        for _,item in ipairs(menuArchive["IB.objectdata"].NSObjectsKeys) do
            if item.NSName == "_NSMainMenu" and item["$class"] and item["$class"]["$classname"] == "NSMenu" then
                mainMenu = item
                break
            end
        end
        if mainMenu then
            return self:_processMenu(mainMenu, language, menu)
        else
            log.ef("Unable to locate MainMenu in '%s.lproj/MainMenu.nib'.", language)
            return nil
        end
    else
        log.ef("Unable to load MainMenu.nib for specified language: %s", language)
        return nil
    end
end

-- cp.apple.finalcutpro.MenuBar:_processMenu(menuData, language, menu) -> table
-- Method
-- Loads a Main Menu Language.
--
-- Parameters:
--  * menuData - Menu data.
--  * language - Langauge as string.
--  * menu - The menu.
--
-- Returns:
--  * Menu
function MenuBar:_processMenu(menuData, language, menu) -- luacheck: ignore
    if not menuData then
        return nil
    end
    --------------------------------------------------------------------------------
    -- Process the menu items:
    --------------------------------------------------------------------------------
    menu = menu or {}
    if menuData.NSMenuItems then
        for i,itemData in ipairs(menuData.NSMenuItems) do
            local item = menu[i] or {}
            item[language]  = itemData.NSTitle
            item.separator  = itemData.NSIsSeparator
            --------------------------------------------------------------------------------
            -- Check if there is a submenu:
            --------------------------------------------------------------------------------
            if itemData.NSSubmenu then
                item.submenu = MenuBar:_processMenu(itemData.NSSubmenu, language, item.submenu)
            end
            menu[i] = item
        end
    end
    return menu
end

return MenuBar