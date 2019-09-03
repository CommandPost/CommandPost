--- === plugins.finalcutpro.menu.menuaction ===
---
--- A `action` which will trigger an Final Cut Pro menu with a matching path, if available/enabled.
--- Registers itself with the `plugins.core.actions.actionmanager`.

local require = require

local log				= require "hs.logger".new "menuaction"

local fnutils           = require "hs.fnutils"
local image             = require "hs.image"

local config            = require "cp.config"
local destinations      = require "cp.apple.finalcutpro.export.destinations"
local fcp               = require "cp.apple.finalcutpro"
local fcpStrings        = require "cp.apple.finalcutpro.strings"
local i18n              = require "cp.i18n"
local idle              = require "cp.idle"
local localeID          = require "cp.i18n.localeID"
local strings           = require "cp.strings"
local text              = require "cp.web.text"

local concat            = table.concat
local imageFromPath     = image.imageFromPath
local insert            = table.insert
local unescapeXML       = text.unescapeXML

local mod = {}

-- ID -> string
-- Constant
-- The menu ID.
local ID = "menu"

-- GROUP -> string
-- Constant
-- The group ID.
local GROUP = "fcpx"

-- ICON -> hs.image object
-- Constant
-- Icon
local ICON = imageFromPath(config.basePath .. "/plugins/finalcutpro/console/images/menu.png")

--- plugins.finalcutpro.menu.menuaction.actionId(params) -> string
--- Function
--- Gets the action ID from the parameters table.
---
--- Parameters:
---  * params - Parameters table.
---
--- Returns:
---  * Action ID as string.
function mod.actionId(params)
    return ID .. ":" .. concat(params.path, "||")
end

-- processSubMenu(menu, path, localeCode, choices) -> table
-- Function
-- Processes a Final Cut Pro sub-menu.
--
-- Parameters:
--  * menu - The menu table to process
--  * localeCode - The current locale code
--  * choices - A table of existing choices
--  * path - A table containing the current path
--
-- Returns:
--  * A table of choices.
local function processSubMenu(menu, localeCode, choices, path)
    for _, v in pairs(menu) do
        if type(v) == "table" then
            if not v.seperator and v[localeCode] and v[localeCode] ~= "" and v.submenu then
                --------------------------------------------------------------------------------
                -- Submenu:
                --------------------------------------------------------------------------------
                local newPath = fnutils.copy(path)
                local title = unescapeXML(v[localeCode])
                table.insert(newPath, title)
                choices = processSubMenu(v.submenu, localeCode, choices, newPath)
            elseif not v.seperator and v[localeCode] and v[localeCode] ~= "" then
                --------------------------------------------------------------------------------
                -- Menu Item:
                --------------------------------------------------------------------------------
                local title = unescapeXML(v[localeCode])
                local params = {}
                params.path = fnutils.concat(fnutils.copy(path), { title })
                params.locale = localeCode
                params.plain = true
                table.insert(choices, {
                    text = title,
                    subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
                    params = params,
                    id = mod.actionId(params),
                })
            end
        end
    end
    return choices
end

-- processMenu(menu, path, localeCode, choices) -> table
-- Function
-- Processes a Final Cut Pro menu.
--
-- Parameters:
--  * menu - The menu table to process
--  * localeCode - The current locale code
--
-- Returns:
--  * A table of choices.
local function processMenu(menu, localeCode)
    local choices = {}
    for _, v in pairs(menu) do
        if type(v) == "table" then
            if v.submenu and v[localeCode] and v[localeCode] ~= "Debug" then
                local path = { v[localeCode] }
                choices = processSubMenu(v.submenu, localeCode, choices, path)
            end
        end
    end
    return choices
end

-- legacyScan() -> table
-- Function
-- Scans the Final Cut Pro Menubar via the Accessibility Framework.
--
-- Parameters:
--  * None
--
-- Returns:
--  * A table of choices.
local function legacyScan() -- luacheck: ignore
    local choices = {}
    fcp:menu():visitMenuItems(function(path, menuItem)
        local title = menuItem:title()
        if path[1] ~= "Apple" then
            local params = {}
            params.path = fnutils.concat(fnutils.copy(path), { title })
            params.locale = fcp:currentLocale().code
            insert(choices, {
                text = title,
                subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
                params = params,
                id = mod.actionId(params),
            })
        end
    end)
    return choices
end

-- compareLegacyVersusNew(choices) -> table
-- Function
-- Compares the supplied choices with the legacy choices.
--
-- Parameters:
--  * choices - The new choices to compare
--
-- Returns:
--  * None
local function compareLegacyVersusNew(choices) -- luacheck: ignore
    --hs.console.clearConsole()
    local legacyChoices = legacyScan()
    log.df("In Legacy Choices, but not in New Choices:")
    for _, v in pairs(legacyChoices) do
        local match = false
        for _, vv in pairs(choices) do
            if v.text == vv.text then
                match = true
                break
            end
        end
        if not match then
            log.df("NO MATCH: %s (%s)", v.text, v.subText)
        end
    end
    log.df("-----------------------------------")
    log.df("In New Choices, but not in Legacy Choices:")
    for _, v in pairs(choices) do
        local match = false
        for _, vv in pairs(legacyChoices) do
            if v.text == vv.text then
                match = true
                break
            end
        end
        if not match then
            log.df("NO MATCH: %s (%s)", v.text, v.subText)
        end
    end
    log.df("-----------------------------------")
end

-- applyMenuWorkarounds(choices) -> table
-- Function
-- Applies a bunch of workarounds to the choices table.
--
-- Parameters:
--  * choices - A table of choices
--  * menu - The full menu
--  * currentLocaleCode - Current locale code
--
-- Returns:
--  * A new table of choices
local function applyMenuWorkarounds(choices, menu, currentLocaleCode)
    --------------------------------------------------------------------------------
    --
    -- WORKAROUNDS FOR MENU ITEMS THAT WERE NOT IN THE NIB:
    --
    --------------------------------------------------------------------------------
    local en = localeID("en")
    local currentLocale = fcp:currentLocale()
    local context = {
        appPath = fcp.app:path(),
        locale = currentLocale.aliases,
        fcpVersion = fcpStrings:_bestVersion(currentLocale, fcp:version())
    }

    --------------------------------------------------------------------------------
    -- NOTE: The 'Commands.strings' Property List is actually included in the
    --       Final Cut Pro strings collection, but there's other Property Lists that
    --       also have the same keys for Import & Export, so we'll point to it
    --       directly instead.
    --------------------------------------------------------------------------------
    local commandsStrings = strings.new(context):fromPlist("${appPath}/Contents/Frameworks/LunaKit.framework/Resources/${locale}.lproj/Commands.strings")
    local dictationStrings = strings.new(context):fromPlist("/System/Library/Frameworks/AppKit.framework/Versions/C/Resources/${locale}.lproj/DictationManager.strings")
    local emojiStrings = strings.new(context):fromPlist("/System/Library/Frameworks/Carbon.framework/Versions/A/Frameworks/HIToolbox.framework/Versions/A/Resources/${locale}.lproj/Menus.strings")

        --------------------------------------------------------------------------------
        -- Final Cut Pro > Commands
        --------------------------------------------------------------------------------
        local userCommandSets = fcp:userCommandSets()
        for _, title in pairs(userCommandSets) do
            local path = {"Final Cut Pro", "Commands"}
            local params = {}
            params.path = fnutils.concat(fnutils.copy(path), { title })
            params.locale = en
            params.plain = true
            table.insert(choices, {
                text = title,
                subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
                params = params,
                id = mod.actionId(params),
            })
        end

        --------------------------------------------------------------------------------
        -- Customize… (Menu: Final Cut Pro > Commands)
        --------------------------------------------------------------------------------
        do
            local title = commandsStrings:find("Customize")
            local path = {"Final Cut Pro", "Commands"}
            local params = {}
            params.path = fnutils.concat(fnutils.copy(path), { title .. ".*" })
            params.locale = en
            params.plain = true
            table.insert(choices, {
                text = title .. "…",
                subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
                params = params,
                id = mod.actionId(params),
            })
        end

        --------------------------------------------------------------------------------
        -- Import… (Menu: Final Cut Pro > Commands)
        --------------------------------------------------------------------------------
        do
            local title = commandsStrings:find("Import")
            local path = {"Final Cut Pro", "Commands"}
            local params = {}
            params.path = fnutils.concat(fnutils.copy(path), { title .. ".*" })
            params.locale = en
            params.plain = true
            table.insert(choices, {
                text = title .. "…",
                subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
                params = params,
                id = mod.actionId(params),
            })
        end

        --------------------------------------------------------------------------------
        -- Export… (Menu: Final Cut Pro > Commands)
        --------------------------------------------------------------------------------
        do
            local title = commandsStrings:find("Export")
            local path = {"Final Cut Pro", "Commands"}
            local params = {}
            params.path = fnutils.concat(fnutils.copy(path), { title .. ".*" })
            params.locale = en
            params.plain = true
            table.insert(choices, {
                text = title .. "…",
                subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
                params = params,
                id = mod.actionId(params),
            })
        end

        --------------------------------------------------------------------------------
        -- Command Sets (Menu: Final Cut Pro > Commands)
        -- Custom Command Sets (Menu: Final Cut Pro > Commands)
        --
        -- NOTE: These are just un-click-able descriptions.
        --------------------------------------------------------------------------------

        --------------------------------------------------------------------------------
        -- Final Cut Pro > Services
        --------------------------------------------------------------------------------

            -- TODO: Need to build a list of services.
            --       On my machine I only see "Development" tools in the Services list
            --       when clicking on the Final Cut Pro menu, however I can see a lot
            --       more listed in UI Browser.

        --------------------------------------------------------------------------------
        -- File > Share
        --------------------------------------------------------------------------------
        local shares = destinations.names()
        for _, title in pairs(shares) do
            title = title .. "…"
            local path = {"File", "Share"}
            local params = {}
            params.path = fnutils.concat(fnutils.copy(path), { title })
            params.locale = en
            params.plain = true
            table.insert(choices, {
                text = title,
                subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
                params = params,
                id = mod.actionId(params),
            })
        end

        --------------------------------------------------------------------------------
        -- Edit > Captions > Duplicate Captions to New Language
        --------------------------------------------------------------------------------

            -- TODO: Work out how to generate these menu items, taking into account language.

        --------------------------------------------------------------------------------
        -- Start Dictation… (Edit)
        --------------------------------------------------------------------------------
        do
            local title = dictationStrings:find("Start Dictation…")
            local path = {"Edit"}
            local params = {}
            params.path = fnutils.concat(fnutils.copy(path), { title })
            params.locale = en
            params.plain = true
            table.insert(choices, {
                text = title,
                subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
                params = params,
                id = mod.actionId(params),
            })
        end

        --------------------------------------------------------------------------------
        -- Emoji & Symbols (Edit)
        --------------------------------------------------------------------------------
        do
            local title = emojiStrings:find("Emoji & Symbols") -- NOTE: It's actually "Emoji &amp; Symbols" in the Property List.
            local path = {"Edit"}
            local params = {}
            params.path = fnutils.concat(fnutils.copy(path), { title })
            params.locale = en
            params.plain = true
            table.insert(choices, {
                text = title,
                subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
                params = params,
                id = mod.actionId(params),
            })
        end

        --------------------------------------------------------------------------------
        -- Workflow Extensions
        --
        -- Frame.io (Window > Extensions)
        -- Getting Started for Final Cut Pro 10.4 (Window > Extensions)
        -- KeyFlow Pro 2 Extension (Window > Extensions)
        -- ShareBrowser (Window > Extensions)
        -- Shutterstock (Window > Extensions)
        -- Simon Says Transcription (Window > Extensions)
        --------------------------------------------------------------------------------
        local workflowExtensions = fcp.workflowExtensions()
        for _, title in pairs(workflowExtensions) do
            local path = {"Window", "Extensions"}
            local params = {}
            params.path = fnutils.concat(fnutils.copy(path), { title })
            params.locale = currentLocaleCode
            params.plain = true
            table.insert(choices, {
                text = title,
                subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
                params = params,
                id = mod.actionId(params),
            })
        end

        --------------------------------------------------------------------------------
        -- Sidebar (Window > Show in Workspace)
        --
        -- Window > Show in Workspace > Libraries
        --------------------------------------------------------------------------------
        --local sidebar = fcp:string("PEEventsLibrary")

            -- TO DO: Work out how to nicely replace "Libraries" with "Sidebar"

        --------------------------------------------------------------------------------
        -- Custom Workspaces:
        --------------------------------------------------------------------------------
        local customWorkspaces = fcp:customWorkspaces()
        for _, title in pairs(customWorkspaces) do
            local path = {"Window", "Workspaces"}
            local params = {}
            params.path = fnutils.concat(fnutils.copy(path), { title })
            params.locale = currentLocaleCode
            params.plain = true
            table.insert(choices, {
                text = title,
                subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
                params = params,
                id = mod.actionId(params),
            })
        end

        --------------------------------------------------------------------------------
        -- Open Workspace Folder in Finder (Window > Workspaces)
        --------------------------------------------------------------------------------
        do
            local title = fcp:string("PEWorkspacesMenuOpenFolder")
            local path = {window, workspaces}
            local params = {}
            params.path = fnutils.concat(fnutils.copy(path), { title })
            params.locale = currentLocaleCode
            params.plain = true
            table.insert(choices, {
                text = title,
                subText = i18n("menuChoiceSubText", {path = concat(path, " > ")}),
                params = params,
                id = mod.actionId(params),
            })
        end

        --------------------------------------------------------------------------------
        -- Gather App Diagnostics (Help)
        --
        -- We can just ignore this, as it requires a modifier key to access anyway.
        --------------------------------------------------------------------------------

    --------------------------------------------------------------------------------
    --
    -- WORKAROUNDS FOR MENU ITEMS THAT WERE IN THE NIB:
    --
    --------------------------------------------------------------------------------
    local itemString = fcp:string("FFTimelineItemElementAccessibilityDescription")
    local closeLibraryString = fcp:string("FFCloseLibrary")

    for i, v in pairs(choices) do
        --------------------------------------------------------------------------------
        -- 360 (View > Show in Viewer)
        -- 360 (View > Show in Event Viewer)
        --
        -- Add in missing degrees symbol.
        --------------------------------------------------------------------------------
        if v.text and v.text == "360" then
            v.text = "360°"
            v.params.path[3] = "360°"
        end

        --------------------------------------------------------------------------------
        -- Close Library (File)
        --
        -- File > Close Library "Library Name"
        --------------------------------------------------------------------------------
        if v.text and v.text == closeLibraryString then
            v.params.path = {"File", "Close Library.*"}
            v.params.plain = false
        end

        --------------------------------------------------------------------------------
        -- Item (File > Share)
        --
        -- Not needed
        --------------------------------------------------------------------------------
        if v.text and v.text == itemString then
            table.remove(choices, i)
        end

        --------------------------------------------------------------------------------
        -- Copy to Library (File)
        --
        -- It's actually a submenu called "Copy Clip to Library", "Copy Event to Library", "Copy Project to Library", etc.
        --------------------------------------------------------------------------------

            -- TODO: Add workaround

        --------------------------------------------------------------------------------
        -- Move to Library (File)
        --
        -- It's actually a submenu called "Move Clip to Library", "Move Event to Library", "Move Project to Library", etc.
        --------------------------------------------------------------------------------

            -- TODO: Add workaround

        --------------------------------------------------------------------------------
        -- Consolidate Files… (File)
        --
        -- Can be "Consolidate Library Media...", "Consolidate Event Media...", "Consolidate Project Media..."
        -- Can be "Consolidate Motion Content..."
        --------------------------------------------------------------------------------

            -- TODO: Add workaround

        --------------------------------------------------------------------------------
        -- Delete Render Files… (File)
        --
        -- Can be "Delete Generated Event Files..." or "Delete Generated Library Files..."
        --------------------------------------------------------------------------------

            -- TODO: Add workaround

        --------------------------------------------------------------------------------
        -- Add Default Transition (Edit)
        --
        -- Add <Default Transition>
        --------------------------------------------------------------------------------

            -- TODO: Add workaround

        --------------------------------------------------------------------------------
        -- Add Default Video Effect (Edit)
        --
        -- Add <Default Video Effect>
        --------------------------------------------------------------------------------

            -- TODO: Add workaround

        --------------------------------------------------------------------------------
        -- Add Default Audio Effect (Edit)
        --
        -- Add <Default Audio Effect>
        --------------------------------------------------------------------------------

            -- TODO: Add workaround

        --------------------------------------------------------------------------------
        -- Reject (Mark)
        --
        -- Can also be "Delete" if focussed on timeline instead of browser.
        --------------------------------------------------------------------------------

            -- TODO: Add workaround

        --------------------------------------------------------------------------------
        -- Open in Timeline (Clip)
        --
        -- Can also be "Open Clip", "Open in Angle Editor",
        --------------------------------------------------------------------------------

            -- TODO: Add workaround

        --------------------------------------------------------------------------------
        -- Verify and Repair Project (Clip)
        --
        -- This is a hidden menu item, you can access it by holding down OPTION when pressing Clip.
        --------------------------------------------------------------------------------

            -- TODO: I'm not sure the best way to remove this from choices?

        --------------------------------------------------------------------------------
        -- Enable (Clip)
        --
        -- Could also be "Disable"
        --------------------------------------------------------------------------------

            -- TODO: Add workaround

        --------------------------------------------------------------------------------
        -- Optical Flow Classic (Modify > Retime > Video Quality)
        --
        -- This seems to be a hidden menu item.
        --------------------------------------------------------------------------------

            -- TODO: I'm not sure the best way to remove this from choices?

        --------------------------------------------------------------------------------
        -- Assign Audio Roles (Modify)
        --
        -- This is actually a sub-menu.
        --------------------------------------------------------------------------------

            -- TODO: Add workaround

        --------------------------------------------------------------------------------
        -- Assign Video Roles (Modify)
        --
        -- This is actually a sub-menu.
        --------------------------------------------------------------------------------

            -- TODO: Add workaround

        --------------------------------------------------------------------------------
        -- Assign Caption Roles (Modify)
        --
        -- This is actually a sub-menu.
        --------------------------------------------------------------------------------

            -- TODO: Add workaround

        --------------------------------------------------------------------------------
        -- Update ' ' Workspace (Window > Workspaces)
        --
        -- Update 'WORKSPACE NAME' Workspace
        --------------------------------------------------------------------------------

            -- TODO: Add workaround

        --------------------------------------------------------------------------------
        -- Open Custom Workspace Folder in Finder (Window > Workspaces)
        --
        -- Open Workspace Folder in Finder (PEWorkspacesMenuOpenFolder)
        --------------------------------------------------------------------------------

            -- TODO: Add workaround to remove this.

    end
    return choices
end

--- plugins.finalcutpro.menu.menuaction.init(actionmanager) -> none
--- Function
--- Initialises the Menu Action plugin
---
--- Parameters:
---  * `actionmanager` - the Action Manager plugin
---
--- Returns:
---  * None
function mod.init(actionmanager)

    mod._handler = actionmanager.addHandler(GROUP .. "_" .. ID, GROUP)
        :onChoices(function(choices)
            local menu = fcp:menu():getMenuTitles()
            local currentLocaleCode = fcp:currentLocale().code
            local result = processMenu(menu, currentLocaleCode)

            result = applyMenuWorkarounds(result, menu, currentLocaleCode)

            --compareLegacyVersusNew(result)

            for _,choice in ipairs(result) do
                choices:add(choice.text)
                    :subText(choice.subText)
                    :params(choice.params)
                    :image(ICON)
                    :id(choice.id)
            end
        end)
        :onExecute(function(action)
            if action and action.path then
                fcp:launch():menu():doSelectMenu(action.path, {plain=action.plain, locale=action.locale}):Now()
            end
        end)
        :onActionId(function(params)
            return ID .. ":" .. concat(params.path, "||")
        end)

    --------------------------------------------------------------------------------
    -- Watch for new Custom Workspaces:
    --------------------------------------------------------------------------------
    fcp.customWorkspaces:watch(function()
        mod._handler:reset()
    end)

    -- TODO: Need to reload if the FCPX language changes.

end

local plugin = {
    id              = "finalcutpro.menu.menuaction",
    group           = "finalcutpro",
    dependencies    = {
        ["core.action.manager"] = "actionmanager",
    }
}

function plugin.init(deps)
    mod.init(deps.actionmanager)
    return mod
end

return plugin
