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
local tools             = require("cp.tools")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.console.font.THIRD_PARTY_FONTS -> table
--- Constant
--- Fonts that could be installed by third party effects:
mod.THIRD_PARTY_FONTS = {
    ["/Library/Application Support/FxFactory/idustrial revolution 3D Video Walls.fxtemplates/Assets/Fonts/3DSHAPESXEFFECTS-Regular.ttf"] = "3D SHAPES XEFFECTS",
    ["/Library/Application Support/FxFactory/osmFCPX osm.iPhone.fxtemplates/Assets/Fonts/osm.font.ttf"] = "osm.font",
    ["/Library/Application Support/FxFactory/osmFCPX osm.iPhone.fxtemplates/Assets/Fonts/osmiPhone-110.otf"] = "osm.font2",
}

--- plugins.finalcutpro.console.font.FONTS_IN_FCP_BUNDLE -> table
--- Constant
--- Fonts contained within the Final Cut Pro Application Bundle (in Flexo.framework).
mod.FONTS_IN_FCP_BUNDLE = {
    "Avenir Black Oblique",
    "Aviano Sans",
    "Banco",
    "Bank Gothic",
    "Basic Commercial",
    "Beaufort Pro",
    "Bebas Neue",
    "Blair",
    "Bradley Hand ITC TT",
    "Brush Script MT",
    "Comic Script",
    "Coolvetica",
    "DDT",
    "Duality",
    "Edwardian Script",
    "Engravers Gothic",
    "Flatbush",
    "Forgotten Futurist",
    "Garamond Rough",
    "Garamond Rough Medium",
    "Gaz",
    "Georgia",
    "Gill Sans",
    "Goudy Old Style",
    "Handwriting - Dakota",
    "Hopper Script",
    "ITC Franklin Gothic",
    "Loopiejuice",
    "Luminari",
    "Meloriac",
    "Misadventures",
    "Octin Team",
    "Old English Text",
    "Operina Pro",
    "Paleographic",
    "Posterboard",
    "Sabon Pro",
    "Shababa",
    "Shabash Pro",
    "Sketch Block Light",
    "Strenuous",
    "Superclarendon",
    "Synchro LET",
    "Trattatello",
    "VIP",
    "Zingende",
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
            if action and action.fontName and action.id then
                local font = fcp:inspector():text():basic():font()
                if font and font.family then
                    local ui = font.family:UI()
                    ui:performAction("AXPress")
                    local menu = ui:attributeValue("AXChildren")[1]
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
    local fonts = {}
    local systemFonts = {}

    --------------------------------------------------------------------------------
    -- Fonts in Final Cut Pro Bundle (not found in Font Book):
    --------------------------------------------------------------------------------
    for _, fontName in pairs(mod.FONTS_IN_FCP_BUNDLE) do
        table.insert(fonts, fontName)
    end

    --------------------------------------------------------------------------------
    -- Third Party Fonts (not found in Font Book):
    --------------------------------------------------------------------------------
    for path, fontName in pairs(mod.THIRD_PARTY_FONTS) do
        if tools.doesFileExist(path) then
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
    for _,v in ipairs(fonts) do
        if (not hash[v]) then
            if string.sub(v, 1, 1) == "." then
                log.df("Skipping Hidden Font: %s", v)
            else
                newFonts[#newFonts+1] = v
                hash[v] = true
            end
        else
            log.df("Skipping Duplicate: %s", v)
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