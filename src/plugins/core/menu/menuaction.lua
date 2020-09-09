--- === plugins.core.menu.menuaction ===
---
--- Add actions that allow you to trigger the menubar items from any application.
---
--- Specials thanks to @asmagill for his amazing work with `coroutine` support.

local require               = require

--local log                   = require "hs.logger".new "menuaction"

local application           = require "hs.application"
local fnutils               = require "hs.fnutils"
local image                 = require "hs.image"
local timer                 = require "hs.timer"

local config                = require "cp.config"
local i18n                  = require "cp.i18n"
local tools                 = require "cp.tools"

local ax                    = require "hs._asm.axuielement"

local concat                = table.concat
local copy                  = fnutils.copy
local doAfter               = timer.doAfter
local imageFromPath         = image.imageFromPath
local playErrorSound        = tools.playErrorSound
local runningApplications   = application.runningApplications
local watcher               = application.watcher

local mod = {}

mod._handlers = {}

mod._cache = {}

local icon = imageFromPath(config.basePath .. "/plugins/core/console/images/menu.png")

local kAXMenuItemModifierControl = (1 << 2)
local kAXMenuItemModifierNoCommand = (1 << 3)
local kAXMenuItemModifierOption = (1 << 1)
local kAXMenuItemModifierShift = (1 << 0)

-- SOURCE: https://github.com/Hammerspoon/hammerspoon/pull/2308#issuecomment-590246330
function mod._getMenuStructure(item)

    if not item then return end
    local values = item:allAttributeValues()
    if not values then return end

    local thisMenuItem = {
        AXTitle                = values["AXTitle"] or "",
        AXRole                 = values["AXRole"] or "",
        AXMenuItemMarkChar     = values["AXMenuItemMarkChar"] or "",
        AXMenuItemCmdChar      = values["AXMenuItemCmdChar"] or "",
        AXMenuItemCmdModifiers = values["AXMenuItemCmdModifiers"] or "",
        AXEnabled              = values["AXEnabled"] or "",
        AXMenuItemCmdGlyph     = values["AXMenuItemCmdGlyph"] or "",
    }

    if thisMenuItem["AXTitle"] == "Apple" then
        thisMenuItem = nil
    else
        local role = thisMenuItem["AXRole"]

        local modsDst = nil
        local modsVal = thisMenuItem["AXMenuItemCmdModifiers"]
        if type(modsVal) == "number" then
            modsDst = ((modsVal & kAXMenuItemModifierNoCommand) > 0) and {} or { "cmd" }
            if (modsVal & kAXMenuItemModifierShift)   > 0 then table.insert(modsDst, "shift") end
            if (modsVal & kAXMenuItemModifierOption)  > 0 then table.insert(modsDst, "alt") end
            if (modsVal & kAXMenuItemModifierControl) > 0 then table.insert(modsDst, "ctrl") end
        end
        thisMenuItem["AXMenuItemCmdModifiers"] = modsDst

        local children = {}
        for i = 1, #item, 1 do
            local data = mod._getMenuStructure(item[i])
            if data then
                table.insert(children, data)
            end
        end
        if #children > 0 then
            thisMenuItem["AXChildren"] = children
        end

        if not (role == "AXMenuItem" or role == "AXMenuBarItem") then
            thisMenuItem = (#children > 0) and children or nil
        end
    end
    hs.coroutineApplicationYield()
    return thisMenuItem
end

local function getMenuItems(appObject, callback)
    hs.assert(getmetatable(appObject) == hs.getObjectMetatable("hs.application"), "expect hs.application for first parameter")
    hs.assert(type(callback) == "function" or (getmetatable(callback) or {}).__call, "expected function for second parameter")

    local app = ax.applicationElement(appObject)
    local menus
    local menuBar = app and app:attributeValue("AXMenuBar")
    if menuBar then
        coroutine.wrap(function(m, c)
            menus = mod._getMenuStructure(m)
            c(menus)
        end)(menuBar, callback)
    else
        callback(menus) -- luacheck: ignore
    end
end

function mod._processMenuItems(items, choices, bundleID, path)
    path = path or {}
    for _,v in pairs(items) do
        if type(v) == "table" then
            local role = v.AXRole
            local children = v.AXChildren
            local title = v.AXTitle
            if role == "AXMenuBarItem" and type(children) == "table" then
                table.insert(path, title)
                mod._processMenuItems(children[1], choices, bundleID, path)
            elseif role == "AXMenuItem" and not children then
                if title and title ~= "" then
                    local menuPath = copy(path)
                    local menuPathString = concat(path, " > ")
                    table.insert(menuPath, title)
                    choices
                        :add(title)
                        :subText(menuPathString)
                        :params({
                            bundleID = bundleID,
                            path = menuPath,
                        })
                        :image(icon)
                        :id(menuPathString)
                end
            end
        end
    end
end

local plugin = {
    id              = "core.menu.menuaction",
    group           = "core",
    dependencies    = {
        ["core.action.manager"]         = "actionmanager",
        ["core.application.manager"]    = "applicationmanager",
        ["core.midi.manager"]           = "midimanager",
        ["core.loupedeckct.manager"]    = "loupedeckctmanager",
        ["core.tourbox.manager"]        = "tourboxmanager",
        ["core.streamdeck.manager"]     = "streamdeckmanager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Watch for application changes:
    --------------------------------------------------------------------------------
    mod._appWatcher = watcher.new(function(_, event, app)
        if app and event == watcher.activated and app:bundleID() then
            if mod._handlers[app:bundleID()] then
                mod._handlers[app:bundleID()]:reset(true)
            end
            mod._handler:reset(true)
            if not mod._cache[app:bundleID()] then
                doAfter(0.1, function()
                    if app and app:bundleID() then
                        getMenuItems(app, function(result)
                            local bundleID = app:bundleID()
                            if bundleID and not mod._cache[bundleID] then
                                mod._cache[bundleID] = result
                                mod._handler:reset(true)
                                if mod._handlers[bundleID] then
                                    mod._handlers[bundleID]:reset(true)
                                end
                            end
                        end)
                    end
                end)
            end
        end
    end):start()

    --------------------------------------------------------------------------------
    -- Setup the Global Menu Actions Handler:
    --------------------------------------------------------------------------------
    local actionmanager = deps.actionmanager
    mod._handler = actionmanager.addHandler("global_menuactions", "global")
        :onChoices(function(choices)
            local app = application.frontmostApplication()
            local bundleID = app and app:bundleID()
            if bundleID then
                local menuItems = mod._cache[bundleID]
                if menuItems then
                    mod._processMenuItems(menuItems, choices, bundleID)
                else
                    choices
                        :add(i18n("loading") .. "...")
                        :subText(i18n("menuItemsLoading"))
                        :params({})
                end
            end
        end)
        :onExecute(function(action)
            if action.bundleID and action.path then
                local apps = application.applicationsForBundleID(action.bundleID)
                local app = apps and apps[1]
                if app and app:selectMenuItem(action.path) then
                    return
                end
            end
            playErrorSound()
        end)
        :onActionId(function(params)
            if params.path then
                return "global_menuactions: " .. concat(params.path, " > ")
            end
        end)

    return mod
end

local bundleIDs = {}
local bundleIDsHash = {}

function plugin.postInit(deps)

    local appManager            = deps.applicationmanager
    local actionmanager         = deps.actionmanager

    local loupedeckCTItems      = deps.loupedeckctmanager.items
    local loupedeckItems        = deps.midimanager.loupedeckItems
    local loupedeckPlusItems    = deps.midimanager.loupedeckPlusItems
    local midiItems             = deps.midimanager.items
    local streamDeckItems       = deps.streamdeckmanager.items
    local tourBoxItems          = deps.tourboxmanager.items

    local registeredApps        = appManager.getApplications()

    local setupHandler = function(bundleID)
        if not mod._handlers[bundleID] then
            local handlerID = registeredApps[bundleID] and registeredApps[bundleID].legacyGroupID or bundleID
            mod._handlers[bundleID] = actionmanager.addHandler(handlerID .. "_menuactions", handlerID, "Menu Items")
            :onChoices(function(choices)
                local menuItems = mod._cache[bundleID]
                if menuItems then
                    mod._processMenuItems(menuItems, choices, bundleID)
                else
                    choices
                        :add(i18n("loading") .. "...")
                        :subText(i18n("menuItemsLoading"))
                        :params({})
                end
            end)
            :onExecute(function(action)
                if action.bundleID and action.path then
                    local apps = application.applicationsForBundleID(action.bundleID)
                    local app = apps and apps[1]
                    if app and app:selectMenuItem(action.path) then
                        return
                    end
                end
                playErrorSound()
            end)
            :onActionId(function(params)
                if params.path then
                    return bundleID .. "_menuactions: " .. concat(params.path, " > ")
                end
            end)
        end
    end

    --------------------------------------------------------------------------------
    -- Get a list of registered bundle IDs:
    --------------------------------------------------------------------------------
    for bundleID, _ in pairs(registeredApps) do
        if not bundleIDsHash[bundleID] then
            bundleIDsHash[bundleID] = true
            table.insert(bundleIDs, bundleID)
        end
    end

    local scanPreferences = function()
        --------------------------------------------------------------------------------
        -- Get a list of custom applications used in control surfaces:
        --------------------------------------------------------------------------------
        local items = {
            loupedeckCTItems,
            loupedeckItems,
            loupedeckPlusItems,
            midiItems,
            streamDeckItems,
            tourBoxItems,
        }
        for _, item in pairs(items) do
            for bundleID, v in pairs(item()) do
                if v.displayName then
                    if not bundleIDsHash[bundleID] then
                        bundleIDsHash[bundleID] = true
                        table.insert(bundleIDs, bundleID)
                    end
                end
            end
        end

        --------------------------------------------------------------------------------
        -- Get a list of custom applications used in Stream Deck:
        --------------------------------------------------------------------------------
        for _, device in pairs(streamDeckItems()) do
            for _, unit in pairs(device) do
                for bundleID, v in pairs(unit) do
                    if v.displayName then
                        if not bundleIDsHash[bundleID] then
                            bundleIDsHash[bundleID] = true
                            table.insert(bundleIDs, bundleID)
                        end
                    end
                end
            end
        end

        --------------------------------------------------------------------------------
        -- Setup application specific Menu Actions Handlers:
        --------------------------------------------------------------------------------
        for _, bundleID in pairs(bundleIDs) do
            setupHandler(bundleID)
        end
    end

    --------------------------------------------------------------------------------
    -- Watch for changes:
    --------------------------------------------------------------------------------
    loupedeckCTItems:watch(function() scanPreferences() end)
    loupedeckItems:watch(function() scanPreferences() end)
    loupedeckPlusItems:watch(function() scanPreferences() end)
    midiItems:watch(function() scanPreferences() end)
    streamDeckItems:watch(function() scanPreferences() end)
    tourBoxItems:watch(function() scanPreferences() end)

    --------------------------------------------------------------------------------
    -- Scan preferences:
    --------------------------------------------------------------------------------
    scanPreferences()

    --------------------------------------------------------------------------------
    -- Scan open applications to give ourselves a head start:
    --------------------------------------------------------------------------------
    local apps = runningApplications()
    for _, app in pairs(apps) do
        local bundleID = app:bundleID()
        if not mod._cache[bundleID] then
            local visibleWindows = app:visibleWindows()
            if next(visibleWindows) then
                getMenuItems(app, function(result)
                    if not mod._cache[bundleID] then
                        mod._cache[bundleID] = result
                        mod._handler:reset()
                        if mod._handlers[bundleID] then
                            mod._handlers[bundleID]:reset()
                        end
                    end
                end)
            end
        end
    end
end

return plugin
