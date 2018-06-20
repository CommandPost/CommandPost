--- === plugins.finalcutpro.console.font ===
---
--- Final Cut Pro Font Console

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("fontConsole")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local inspect           = require("hs.inspect")
local styledtext        = require("hs.styledtext")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config            = require("cp.config")
local dialog            = require("cp.dialog")
local fcp               = require("cp.apple.finalcutpro")
local font              = require("cp.font")
local json              = require("cp.json")
local just              = require("cp.just")
local tools             = require("cp.tools")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.console.font.FILE_NAME -> string
--- Constant
--- File name of settings file.
mod.FILE_NAME = "Fonts.json"

--- plugins.finalcutpro.console.font.FOLDER_NAME -> string
--- Constant
--- Folder Name where settings file is contained.
mod.FOLDER_NAME = "Final Cut Pro"

--- plugins.finalcutpro.console.font.FONT_EXTENSIONS -> table
--- Constant
--- Table of support font file extensions.
mod.FONT_EXTENSIONS = {
    "ttf",
    "otf",
    "ttc",
}

--- plugins.finalcutpro.console.font.RENAME_FONTS -> table
--- Constant
--- Special Fonts that appear to have a different name in Final Cut Pro than they do in Font Book.
mod.RENAME_FONTS = {
    [".AppleSystemUIFont"] = "BlueGlyph",                   -- Developers font - not widely used.
    ["Sketch Block Light"] = "Sketch Block",                -- System font not available in Final Cut Pro Inspector.
}

--- plugins.finalcutpro.console.font.IGNORE_FONTS -> table
--- Constant
--- Fonts to ignore as they're used internally by Final Cut Pro or macOS.
mod.IGNORE_FONTS = {
    ["FCMetro34"] = "FCMetro34",                            -- Final Cut Pro Internal Font not available in Final Cut Pro Inspector.
    ["Avenir Black Oblique"] = "Avenir Black Oblique",      -- Final Cut Pro Internal Font not available in Final Cut Pro Inspector.
    ["Garamond Rough Medium"] = "Garamond Rough Medium",    -- Final Cut Pro Internal Font not available in Final Cut Pro Inspector.
    ["Avenir Book"] = "Avenir Book",                        -- System font not available in Final Cut Pro Inspector.
    ["Myriad Pro Light"] = "Myriad Pro Light",              -- System font not available in Final Cut Pro Inspector.
    ["Myriad Pro"] = "Myriad Pro",                          -- System font not available in Final Cut Pro Inspector.
    ["Refrigerator Deluxe Heavy"] = "Refrigerator Deluxe"   -- Obscure
}

--- plugins.finalcutpro.console.font.cachedFonts <cp.prop: table | nil>
--- Field
--- Table of cached fonts.
mod.cachedFonts = json.prop(config.cachePath, mod.FOLDER_NAME, mod.FILE_NAME, nil)

--- plugins.finalcutpro.console.font.deleteCache() -> none
--- Function
--- Deletes the cache file.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.deleteCache()
    local path = config.cachePath .. "/" .. mod.FOLDER_NAME .. "/" .. mod.FILE_NAME
    if tools.doesFileExist(path) then
        os.remove(path)
    end
end

--- plugins.finalcutpro.console.font.getRunningFonts() -> none
--- Function
--- Shows the Final Cut Pro Console.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.getRunningFonts()
    local result = {}
    local fcpApp = fcp:application()
    local processID = fcpApp and fcpApp:pid()
    if processID then
        local o, s, t, r = hs.execute("lsof -p " .. processID)
        if o and s and t == "exit" and r == 0 then
            local lines = tools.lines(o)
            for _, line in pairs(lines) do
                for _, ext in pairs(mod.FONT_EXTENSIONS) do
                    if string.find("." .. string.lower(line), "." .. ext) then
                        local _, position = string.find(line, " /")
                        if position then
                            local path = string.sub(line, position)
                            if path then
                                local fontFamily = font.getFontFamilyFromFile(path)
                                if fontFamily and string.sub(fontFamily, 1, 1) ~= "." then
                                    --------------------------------------------------------------------------------
                                    -- Add workaround:
                                    --------------------------------------------------------------------------------
                                    local ff = styledtext.fontInfo(fontFamily)
                                    if ff then
                                        if ff.familyName ~= ".AppleSystemUIFont" then
                                            if ff.displayName == fontFamily and ff.familyName ~= fontFamily then
                                                --log.df("CHANGING FONT: %s", fontFamily)
                                                fontFamily = ff.familyName
                                            end
                                        end
                                    end
                                    table.insert(result, fontFamily)
                                end
                            end
                        end
                    end
                end
            end
        else
            log.ef("Failed to run `lsof` on Final Cut Pro.")
        end
    end
    return result
end

--- plugins.finalcutpro.console.font.onActivate() -> none
--- Function
--- Handles Console Activations.
---
--- Parameters:
---  * handler - Handler instance.
---  * action - Action table.
---  * text - Selected text from the Console.
---
--- Returns:
---  * None
function mod.onActivate(_, action)
    if action and action.fontName then

        --------------------------------------------------------------------------------
        -- Get Font Name from action:
        --------------------------------------------------------------------------------
        local fontName = action.fontName

        --------------------------------------------------------------------------------
        -- Get font ID from lookup table:
        --------------------------------------------------------------------------------
        local id = mod._fontLookup[fontName]

        --------------------------------------------------------------------------------
        -- If we need to rebuild the Font Database:
        --------------------------------------------------------------------------------
        if not id or not mod.cachedFonts() then

            dialog.displayMessage("The selected font could not be found in the cache. Your system will now be re-scanned for fonts. This can take several minutes.")

            --------------------------------------------------------------------------------
            -- Trash Cache:
            --------------------------------------------------------------------------------
            mod._fontLookup = nil
            mod._firstTime = true
            mod.deleteCache()
            mod._fontConsoleTriggeredScan = true
            mod.reset()
            mod._fontConsoleTriggeredScan = false
            id = mod._fontLookup[fontName]
        end

        --------------------------------------------------------------------------------
        -- Make sure Inspector is open:
        --------------------------------------------------------------------------------
        local inspector = fcp:inspector()
        inspector:show()
        if not just.doUntil(function() return inspector:isShowing() end) then
            dialog.displayErrorMessage("Failed to open the Inspector.")
            return
        end

        --------------------------------------------------------------------------------
        -- Make sure the Text Inspector is open:
        --------------------------------------------------------------------------------
        local text = inspector:text()
        text:show()
        if not just.doUntil(function() return text:isShowing() end) then
            dialog.displayMessage(i18n("pleaseSelectATitle"))
            return
        end

        --------------------------------------------------------------------------------
        -- Make sure we can get the currently selected font:
        --------------------------------------------------------------------------------
        local f = text:basic():font()
        if not f or not f.family then
            dialog.displayErrorMessage(string.format("Failed to get Font Dropdown: %s", f))
            return
        end

        --------------------------------------------------------------------------------
        -- Get the Font Family UI:
        --------------------------------------------------------------------------------
        local ui = f.family:UI()
        if not ui then
            dialog.displayErrorMessage(string.format("Failed to get Font Family UI: %s", ui))
            return
        end

        --------------------------------------------------------------------------------
        -- Activate the drop down:
        --------------------------------------------------------------------------------
        ui:performAction("AXPress")
        local menu = just.doUntil(function()
            return ui:attributeValue("AXChildren") and ui:attributeValue("AXChildren")[1]
        end)
        if not menu then
            dialog.displayErrorMessage(string.format("Failed to get Font Family UI: %s", ui))
            return
        end

        --------------------------------------------------------------------------------
        -- Get the kids:
        --------------------------------------------------------------------------------
        local kids = menu:attributeValue("AXChildren")
        if not kids then
            dialog.displayErrorMessage(string.format("Failed to get Font Kids: %s", kids))
            return
        end

        --------------------------------------------------------------------------------
        -- Compare the number of items in the drop down to what we've cached:
        --------------------------------------------------------------------------------
        local difference = #kids - mod._consoleFontCount
        if difference == 0 then
            if menu[id] then
                --------------------------------------------------------------------------------
                -- Click on chosen font:
                --------------------------------------------------------------------------------
                --log.df("Selecting item: %s (%s)", fontName, id)
                local result = menu[id]:performAction("AXPress")
                if result then
                    return
                end
            end
        else
            --------------------------------------------------------------------------------
            -- Wrong number of fonts comparing Console with Popup:
            --------------------------------------------------------------------------------
            local cachedFonts = mod.cachedFonts()
            log.df("--------------------------------------------------------------------------------")
            log.df("NUMBER OF FONTS IN CONSOLE: %s", mod._consoleFontCount)
            log.df("NUMBER OF FONTS IN POPUP: %s", #kids)
            log.df("--------------------------------------------------------------------------------")
            log.df("DIFFERENCE: %s", #kids - mod._consoleFontCount)
            log.df("--------------------------------------------------------------------------------")
            log.df("Cached Fonts: %s", inspect(cachedFonts))
            log.df("--------------------------------------------------------------------------------")
            log.df("Fonts: %s", inspect(mod._debugFontList))
            log.df("--------------------------------------------------------------------------------")

            dialog.displayErrorMessage(string.format("An error has occured where the number of fonts in the CommandPost Console (%s) is different to the number of fonts in Final Cut Pro (%s).\n\nThe font cache will be trashed. Please try again.", mod._consoleFontCount, #kids))

            --------------------------------------------------------------------------------
            -- Trash Cache:
            --------------------------------------------------------------------------------
            mod.deleteCache()
            if mod.activator then
                mod.activator:refresh()
            end
        end
    else
        --------------------------------------------------------------------------------
        -- Bad Action:
        --------------------------------------------------------------------------------
        dialog.displayErrorMessage("Something went wrong with the action you supplied. Try re-applying the action and try again.")
    end
end

--- plugins.finalcutpro.console.font.show() -> none
--- Function
--- Shows the Font Console.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.show()

    local hasCache = mod.cachedFonts() ~= nil
    local inspector = fcp:inspector()
    inspector:show()
    if not just.doUntil(function() return inspector:isShowing() end) then
        dialog.displayErrorMessage("Failed to open the Inspector.")
        return
    end
    if not inspector:tabAvailable("Text") then
        dialog.displayMessage(i18n("pleaseSelectATitle"))
        return
    end

    mod._fontConsoleTriggeredScan = true

    if not mod.activator then
        --------------------------------------------------------------------------------
        -- Display initialisation message:
        --------------------------------------------------------------------------------
        if not mod.cachedFonts() then
            mod._firstTime = true
            mod._warningDisplayed = true
            dialog.displayMessage(i18n("fontScanInitalisationMessage"))
        end

        --------------------------------------------------------------------------------
        -- Setup Activator:
        --------------------------------------------------------------------------------
        mod.activator = mod.actionmanager.getActivator("finalcutpro.font")
        mod.activator:preloadChoices()
        mod.activator:allowHandlers("fcpx_fonts")
        mod.activator:onActivate(mod.onActivate)

        --------------------------------------------------------------------------------
        -- Show the Console if we restored values from the cache:
        --------------------------------------------------------------------------------
        if hasCache then
            mod.activator:show()
        end
    else
        --------------------------------------------------------------------------------
        -- Show Font Console:
        --------------------------------------------------------------------------------
        mod.activator:show()
    end

    mod._fontConsoleTriggeredScan = false

end

--- plugins.finalcutpro.commands.actions.onChoices([choices]) -> none
--- Function
--- Adds available choices to the selection.
---
--- Parameters:
--- * `choices` - The optional `cp.choices` to add choices to.
---
--- Returns:
--- * None
function mod.onChoices(choices)

    --------------------------------------------------------------------------------
    -- Get cached fonts:
    --------------------------------------------------------------------------------
    local cachedFonts = mod.cachedFonts()

    --------------------------------------------------------------------------------
    -- Display warning if this is the first time we've loaded fonts:
    --------------------------------------------------------------------------------
    if not mod._warningDisplayed and not cachedFonts and mod._fontConsoleTriggeredScan then
        dialog.displayMessage(i18n("fontScanConsoleInitalisationMessage"))
        mod._warningDisplayed = true
    end

    local fonts = {}
    local newFonts = {}
    local systemFonts = {}

    if cachedFonts then
        --------------------------------------------------------------------------------
        -- Restoring fonts from cache:
        --------------------------------------------------------------------------------
        --log.df("Restoring Fonts from Cache.")
        fonts = cachedFonts
    else
        --------------------------------------------------------------------------------
        -- Get a list of fonts currently being used by Final Cut Pro & Cache:
        --------------------------------------------------------------------------------
        --log.df("Gathering list of fonts in active use by Final Cut Pro.")
        if mod._fontConsoleTriggeredScan or mod._forceScan then
            fonts = mod.getRunningFonts()
            mod.cachedFonts(fonts)
        end
    end

    --------------------------------------------------------------------------------
    -- Add System Fonts (found in Font Book):
    --------------------------------------------------------------------------------
    for _, fontName in pairs(styledtext.fontNames()) do
        if string.sub(fontName, 1, 1) ~= "." then
            table.insert(fonts, styledtext.fontInfo(fontName).familyName)
            systemFonts[styledtext.fontInfo(fontName).familyName] = true
        end
    end

    --------------------------------------------------------------------------------
    -- Remove duplicate fonts, remove hidden fonts and rename fonts as required:
    --------------------------------------------------------------------------------
    local hash = {}
    for _,fontName in ipairs(fonts) do
        if (not hash[fontName]) then
            if string.sub(fontName, 1, 1) == "." or mod.IGNORE_FONTS[fontName] then -- luacheck: ignore
                --log.df("Skipping Hidden/Ignored Font: %s", fontName)
            else
                if mod.RENAME_FONTS[fontName] then
                    --log.df("Renaming Font: %s = %s", fontName, mod.RENAME_FONTS[fontName])
                    fontName = mod.RENAME_FONTS[fontName]
                end
                newFonts[#newFonts+1] = fontName
                hash[fontName] = true
            end
        --else
            --log.df("Skipping Duplicate: %s", fontName)
        end
    end

    --------------------------------------------------------------------------------
    -- Sort and add to table:
    --------------------------------------------------------------------------------
    mod._fontLookup = {}
    table.sort(newFonts, function(a, b) return string.lower(a) < string.lower(b) end)
    for id,fontName in pairs(newFonts) do
            local name
            if systemFonts[fontName] then
                name = styledtext.new(fontName, {
                    font = { name = fontName, size = 18 },
                })
            else
                name = styledtext.new(fontName, {
                    font = { size = 18 },
                })
            end
            --------------------------------------------------------------------------------
            -- Add ID to Font Lookup Table:
            --------------------------------------------------------------------------------
            mod._fontLookup[fontName] = id

            if choices then
                choices
                    :add(name)
                    :subText("")
                    :id(fontName)
                    :params({
                        fontName = fontName,
                    })
            end
            --log.df("%s: %s", id, fontName)
    end

    --------------------------------------------------------------------------------
    -- Get a list of fonts for debugging purposes:
    --------------------------------------------------------------------------------
    mod._debugFontList = newFonts

    --------------------------------------------------------------------------------
    -- Display initialisation message:
    --------------------------------------------------------------------------------
    if mod._firstTime then
        dialog.displayMessage(i18n("fontScanComplete"))
        mod._firstTime = false
    end

    --------------------------------------------------------------------------------
    -- Font Count:
    --------------------------------------------------------------------------------
    mod._consoleFontCount = newFonts and #newFonts or 0
    --log.df("NUMBER OF FONTS IN CONSOLE: %s", mod._consoleFontCount)

    --------------------------------------------------------------------------------
    -- Fuck things up (for science):
    --------------------------------------------------------------------------------
    --mod._consoleFontCount = mod._consoleFontCount + 1

end

--- plugins.finalcutpro.commands.actions.getId(action) -> string
--- Function
--- Get ID.
---
--- Parameters:
--- * action - The action table.
---
--- Returns:
--- * The ID as a string.
function mod.getId(action)
    return string.format("%s:%s", "fcpx_fonts", action.id)
end

--- plugins.finalcutpro.commands.actions.onExecute(action) -> none
--- Function
--- On Execute.
---
--- Parameters:
--- * action - The action table.
---
--- Returns:
--- * None
function mod.onExecute(action)
    if not mod._consoleFontCount then mod.onChoices() end
    mod.onActivate(nil, action)
end

--- plugins.finalcutpro.commands.actions.reset() -> none
--- Function
--- Reset the Font Handler Cache.
---
--- Parameters:
--- * None
---
--- Returns:
--- * None
function mod.reset()
    mod._forceScan = true
    mod._handler:reset(true)
    mod._forceScan = false
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.console.font",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]        = "fcpxCmds",
        ["core.action.manager"]         = "actionmanager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Initialise Module:
    --------------------------------------------------------------------------------
    mod.actionmanager = deps.actionmanager

    --------------------------------------------------------------------------------
    -- Create new Font Handler:
    --------------------------------------------------------------------------------
    mod._handler = mod.actionmanager.addHandler("fcpx_fonts", "fcpx")
        :onChoices(mod.onChoices)
        :onExecute(mod.onExecute)
        :onActionId(mod.getId)

    --------------------------------------------------------------------------------
    -- Add the command trigger:
    --------------------------------------------------------------------------------
    deps.fcpxCmds:add("cpFontConsole")
        :groupedBy("commandPost")
        :whenActivated(mod.show)

    return mod

end

return plugin
