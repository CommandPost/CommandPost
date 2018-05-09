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
local fs                = require("hs.fs")
local fnutils           = require("hs.fnutils")
local styledtext        = require("hs.styledtext")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local dialog            = require("cp.dialog")
local fcp               = require("cp.apple.finalcutpro")
local font              = require("cp.font")
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
                        local path = string.sub(line, 85)
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
    end
    return result
end

--- plugins.finalcutpro.console.font.SPECIAL_FONTS -> table
--- Constant
--- Special Fonts that appear to have a different name in Final Cut Pro than they do in Font Book.
mod.SPECIAL_FONTS = {
    [".AppleSystemUIFont"] = "BlueGlyph",
    ["Avenir Black Oblique"] = "Avenir",
    ["Garamond Rough Medium"] = "Garamond Rough",
}

--- plugins.finalcutpro.console.font.IGNORE_FONTS -> table
--- Constant
--- Fonts to ignore as they're used internally by Final Cut Pro or macOS.
mod.IGNORE_FONTS = {
    "FCMetro34"
}

--- plugins.finalcutpro.console.font.show() -> none
--- Function
--- Shows the Final Cut Pro Console.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.show()
    local inspector = fcp:inspector()
    if not inspector:tabAvailable("Text") then
        dialog.displayMessage("Please select a title in the timeline.")
        return
    end
    if not mod.activator then
        mod.activator = mod.actionmanager.getActivator("finalcutpro.font")
        mod.activator:preloadChoices()
        mod.activator:allowHandlers("fcpx_fonts")

        --------------------------------------------------------------------------------
        -- Setup Activator Callback:
        --------------------------------------------------------------------------------
        mod.activator:onActivate(function(handler, action, text)

            log.df("action: %s", hs.inspect(action))

            if action and action.fontName and action.id then
                local font = fcp:inspector():text():basic():font()
                if font and font.family then
                    local ui = font.family:UI()
                    if ui then
                        ui:performAction("AXPress")
                        local menu = ui:attributeValue("AXChildren") and ui:attributeValue("AXChildren")[1]
                        if menu then
                            local kids = menu:attributeValue("AXChildren")
                            log.df("NUMBER OF FONTS IN POPUP: %s", #kids)
                            log.df("DIFFERENCE: %s", #kids - mod._consoleFontCount)
                            if menu[action.id] then
                                log.df("Selecting item: %s (%s)", action.fontName, action.id)
                                menu[action.id]:performAction("AXPress")
                            end
                        end
                    end
                end
            end
        end)
    end
    mod.activator:show()
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

    --------------------------------------------------------------------------------
    -- Build list of fonts:
    --------------------------------------------------------------------------------
    local systemFonts = {}

    --------------------------------------------------------------------------------
    -- Get a list of fonts currently being used by Final Cut Pro:
    --------------------------------------------------------------------------------
    local fonts = mod.getRunningFonts()

    --------------------------------------------------------------------------------
    -- Special Fonts (found in Font Book):
    --------------------------------------------------------------------------------
    for familyName, fontName in pairs(mod.SPECIAL_FONTS) do
        if styledtext.fontInfo(familyName) then
            table.insert(fonts, fontName)
        end
    end

    --------------------------------------------------------------------------------
    -- System Fonts (found in Font Book):
    --------------------------------------------------------------------------------
    for _, fontName in pairs(styledtext.fontNames()) do
        if string.sub(fontName, 1, 1) ~= "." then
            table.insert(fonts, styledtext.fontInfo(fontName).familyName)
            systemFonts[styledtext.fontInfo(fontName).familyName] = true
        end
    end

    --------------------------------------------------------------------------------
    -- Remove duplicates and hidden fonts:
    --------------------------------------------------------------------------------
    local hash = {}
    local newFonts = {}
    for _,fontName in ipairs(fonts) do
        if (not hash[fontName]) then
            if string.sub(fontName, 1, 1) == "."  or fnutils.contains(mod.IGNORE_FONTS, fontName) then
                log.df("Skipping Hidden/Ignored Font: %s", v)
            else
                newFonts[#newFonts+1] = fontName
                hash[fontName] = true
            end
        else
            log.df("Skipping Duplicate: %s", fontName)
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
            log.df("%s: %s", id, fontName)
    end

    --------------------------------------------------------------------------------
    -- Debugging:
    --------------------------------------------------------------------------------
    log.df("NUMBER OF FONTS IN CONSOLE: %s", newFonts and #newFonts)
    mod._consoleFontCount = newFonts and #newFonts

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
    return string.format("%s:%s", ID, action.id)
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
    log.df("action: %s", hs.inspect(action))
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