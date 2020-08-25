--- === plugins.finalcutpro.console.font ===
---
--- Final Cut Pro Font Console

local require               = require

local hs                    = hs

local log				    = require "hs.logger".new "fontConsole"

local image                 = require "hs.image"
local styledtext            = require "hs.styledtext"
local timer                 = require "hs.timer"

local axutils               = require "cp.ui.axutils"
local config                = require "cp.config"
local dialog                = require "cp.dialog"
local fcp                   = require "cp.apple.finalcutpro"
local i18n                  = require "cp.i18n"
local just                  = require "cp.just"
local tools                 = require "cp.tools"

local displayErrorMessage   = dialog.displayErrorMessage
local displayMessage        = dialog.displayMessage
local doAfter               = timer.doAfter
local execute               = hs.execute
local imageFromPath         = image.imageFromPath
local childWith             = axutils.childWith

local mod = {}

-- FONT_ICON -> hs.image object
-- ConstantS
-- Font Icon.
local FONT_ICON = imageFromPath(config.basePath .. "/plugins/finalcutpro/console/images/font.png")

--- plugins.finalcutpro.console.font.processedFonts -> table
--- Variable
--- Table of font paths which have already been loaded or skipped.
mod.processedFonts = {}

-- getFinalCutProFontPaths() -> none
-- Function
-- Gets a table of all the fonts currently used by Final Cut Pro.
--
-- Parameters:
--  * None
--
-- Returns:
--  * Table
local function getFinalCutProFontPaths()
    local result = {}
    local fcpApp = fcp:application()
    local processID = fcpApp and fcpApp:pid()
    if processID then
        local o, s, t, r = execute([[lsof -n -p ]] .. processID .. [[ | grep -E '\.ttf$|\.otf$|\.ttc$']])
        if o and s and t == "exit" and r == 0 then
            local lines = tools.lines(o)
            local find = string.find
            local sub = string.sub
            local insert = table.insert
            for _, line in pairs(lines) do
                local _, position = find(line, " /")
                if position then
                    local path = sub(line, position)
                    if path then
                        insert(result, path)
                    end
                end
            end
        else
            log.ef("Failed to run `lsof` on Final Cut Pro.")
        end
    end
    return result
end

-- loadFinalCutProFonts() -> none
-- Function
-- Loads all of Final Cut Pro's Fonts into CommandPost.
--
-- Parameters:
--  * None
--
-- Returns:
--  * Table
local function loadFinalCutProFonts()
    local fontPaths = getFinalCutProFontPaths()
    local userPath = os.getenv("HOME")
    local doesFileExist = tools.doesFileExist
    local loadFont = styledtext.loadFont
    for _, file in pairs(fontPaths) do
        if not mod.processedFonts[file] and doesFileExist(file) then
            if file:sub(1, 15) ~= "/Library/Fonts/" and
            file:sub(1, userPath:len() + 15) ~= userPath .. "/Library/Fonts/" and
            file:sub(1, 22) ~= "/System/Library/Fonts/" and
            file:sub(1, 47) ~= "/Library/Application Support/Apple/Fonts/iWork/" and
            file:sub(-13) ~= "FCMetro34.ttf" then
                loadFont(file)
            end
        end
        mod.processedFonts[file] = true
    end
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
        -- Make sure Inspector is open:
        --------------------------------------------------------------------------------
        local inspector = fcp.inspector
        inspector:show()
        if not just.doUntil(function() return inspector:isShowing() end) then
            displayErrorMessage("Failed to open the Inspector.")
            return
        end

        --------------------------------------------------------------------------------
        -- Make sure the Text Inspector is open:
        --------------------------------------------------------------------------------
        local text = inspector.text
        text:show()
        if not just.doUntil(function() return text:isShowing() end) then
            displayMessage(i18n("pleaseSelectATitle"))
            return
        end

        --------------------------------------------------------------------------------
        -- Make sure we can get the currently selected font:
        --------------------------------------------------------------------------------
        local f = text:basic():font()
        if not f or not f.family then
            displayErrorMessage(string.format("Failed to get Font Dropdown: %s", f))
            return
        end

        --------------------------------------------------------------------------------
        -- Get the Font Family UI:
        --------------------------------------------------------------------------------
        local ui = f.family:UI()
        if not ui then
            displayErrorMessage(string.format("Failed to get Font Family UI: %s", ui))
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
            displayErrorMessage(string.format("Failed to get Font Family UI: %s", ui))
            return
        end

        --------------------------------------------------------------------------------
        -- Select the chosen font.
        --------------------------------------------------------------------------------
        local theFontUI = childWith(menu, "AXTitle", fontName)
        if theFontUI then
            local result = theFontUI:performAction("AXPress")
            if result then
                return
            else
                displayErrorMessage("The selected font could not be found.\n\nPlease try again.")
            end
        else
            displayErrorMessage("Could not find the font in the dropdown list.")
        end
    else
        --------------------------------------------------------------------------------
        -- Bad Action:
        --------------------------------------------------------------------------------
        displayErrorMessage("Something went wrong with the action you supplied. Try re-applying the action and try again.")
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

    --------------------------------------------------------------------------------
    -- Show the Inspector:
    --------------------------------------------------------------------------------
    local inspector = fcp.inspector
    inspector:show()
    if not just.doUntil(function() return inspector:isShowing() end) then
        displayErrorMessage("Failed to open the Inspector.")
        return
    end

    --------------------------------------------------------------------------------
    -- Make sure there's a "Text" tab:
    --------------------------------------------------------------------------------
    if not inspector:tabAvailable("Text") then
        displayMessage(i18n("pleaseSelectATitle"))
        return
    end

    --------------------------------------------------------------------------------
    -- Setup Activator:
    --------------------------------------------------------------------------------
    if not mod.activator then
        mod.activator = mod.actionmanager.getActivator("finalcutpro.font")
        mod.activator:allowHandlers("fcpx_fonts")
        mod.activator:onActivate(mod.onActivate)
    end

    --------------------------------------------------------------------------------
    -- Show the Activator:
    --------------------------------------------------------------------------------
    mod.activator:show()

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
    -- Load Final Cut Pro Fonts:
    --------------------------------------------------------------------------------
    if fcp:isRunning() then
        loadFinalCutProFonts()
    else
        return
    end

    --------------------------------------------------------------------------------
    -- Add Fonts to Table:
    --------------------------------------------------------------------------------
    local fonts = {}
    local insert = table.insert
    for _, familyName in pairs(styledtext.fontFamilies()) do
        insert(fonts, familyName)
    end

    --------------------------------------------------------------------------------
    -- Remove Duplicate, Ignored & Hidden Fonts:
    --------------------------------------------------------------------------------
    local hash = {}

        --------------------------------------------------------------------------------
        -- For whatever reason, Final Cut Pro never displays the "SF Compact Display"
        -- font family, even though TextEdit does, and it also appears in Font Book.
        -- https://github.com/CommandPost/CommandPost/issues/1407#issuecomment-411001923
        --------------------------------------------------------------------------------
        hash["SF Compact Display"] = true

    local newFonts = {}
    local sub = string.sub
    for _,fontName in ipairs(fonts) do
        if (not hash[fontName]) then
            if sub(fontName, 1, 1) ~= "." then
                newFonts[#newFonts+1] = fontName
                hash[fontName] = true
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Sort and add to table:
    --------------------------------------------------------------------------------
    table.sort(newFonts, function(a, b) return string.lower(a) < string.lower(b) end)
    local new = styledtext.new
    for _,fontName in pairs(newFonts) do
            --------------------------------------------------------------------------------
            -- Add choice to Activator:
            --------------------------------------------------------------------------------
            if choices then
                local name = new(fontName, {
                    font = { name = fontName, size = 18 },
                    color = { white = 1, alpha = 1 },
                })
                choices
                    :add(name)
                    :id(fontName)
                    :image(FONT_ICON)
                    :params({
                        fontName = fontName,
                    })
            end
    end

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

local plugin = {
    id              = "finalcutpro.console.font",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]        = "fcpxCmds",
        ["core.action.manager"]         = "actionmanager",
    }
}

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
    -- Reload the Final Cut Pro font list when Final Cut Pro restarts:
    --------------------------------------------------------------------------------
    fcp.isRunning:watch(function(running)
        if running then
            --------------------------------------------------------------------------------
            -- Give ourselves a 5 second buffer, just incase Final Cut Pro is restarting:
            --------------------------------------------------------------------------------
            doAfter(5, function()
                if fcp:isRunning() then
                    mod._handler:reset(true)
                end
            end)
        end
    end)

    --------------------------------------------------------------------------------
    -- Add the command trigger:
    --------------------------------------------------------------------------------
    deps.fcpxCmds
        :add("cpFontConsole")
        :groupedBy("commandPost")
        :whenActivated(mod.show)

    return mod
end

return plugin
