--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

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
local just              = require("cp.just")
local tools             = require("cp.tools")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

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
}

--- plugins.finalcutpro.console.font.cachedFonts <cp.prop: table>
--- Field
--- Table of cached fonts
mod.cachedFonts = config.prop("cachedFonts", nil)

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
                                    table.insert(result, fontFamily)
                                end
                            end
                        end
                    end
                end
            end
        else
            log.ef("Failed to run lsof on Final Cut Pro.")
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
function mod.onActivate(_, action, _)
    if action and action.fontName and action.id then
        local f = fcp:inspector():text():basic():font()
        if f and f.family then
            local ui = f.family:UI()
            if ui then
                ui:performAction("AXPress")
                local menu = just.doUntil(function()
                    return ui:attributeValue("AXChildren") and ui:attributeValue("AXChildren")[1]
                end)
                if menu then
                    local kids = menu:attributeValue("AXChildren")
                    if kids then
                        local difference = #kids - mod._consoleFontCount
                        if difference == 0 then
                            if menu[action.id] then
                                --------------------------------------------------------------------------------
                                -- Click on chosen font:
                                --------------------------------------------------------------------------------
                                --log.df("Selecting item: %s (%s)", action.fontName, action.id)
                                local result = menu[action.id]:performAction("AXPress")
                                if result then
                                    return
                                end
                            end
                        else
                            --------------------------------------------------------------------------------
                            -- Wrong number of fonts comparing Console with Popup:
                            --------------------------------------------------------------------------------
                            local cachedFonts = mod.cachedFonts()
                            log.df("Cached Fonts: %s", inspect(cachedFonts))
                            log.df("NUMBER OF FONTS IN CONSOLE: %s", mod._consoleFontCount)
                            log.df("NUMBER OF FONTS IN POPUP: %s", #kids)
                            log.df("DIFFERENCE: %s", #kids - mod._consoleFontCount)

                            dialog.displayErrorMessage(i18n("fontScanError"))
                            mod.cachedFonts(nil)
                            mod.activator:refresh()
                        end
                    end
                end
            end
        end
    end
    --------------------------------------------------------------------------------
    -- Something funky has happened:
    --------------------------------------------------------------------------------
    dialog.displayErrorMessage(i18n("unexpectedError"))
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
    if not inspector:tabAvailable("Text") then
        dialog.displayMessage(i18n("pleaseSelectATitle"))
        return
    end
    if not mod.activator then
        --------------------------------------------------------------------------------
        -- Display initialisation message:
        --------------------------------------------------------------------------------
        if not mod.cachedFonts() then
            mod._firstTime = true
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
end

--- plugins.finalcutpro.commands.actions.onChoices(choices) -> none
--- Function
--- Adds available choices to the  selection.
---
--- Parameters:
--- * `choices` - The `cp.choices` to add choices to.
---
--- Returns:
--- * None
function mod.onChoices(choices)

    local fonts
    local newFonts = {}
    local systemFonts = {}

    --------------------------------------------------------------------------------
    -- Get cached fonts:
    --------------------------------------------------------------------------------
    local cachedFonts = mod.cachedFonts()

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
        fonts = mod.getRunningFonts()
        mod.cachedFonts(fonts)
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
            choices
                :add(name)
                :subText("")
                :id(fontName)
                :params({
                    fontName = fontName,
                    id = id,
                })
            --log.df("%s: %s", id, fontName)
    end

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
function mod.onExecute()
    --log.df("action: %s", hs.inspect(action))
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
