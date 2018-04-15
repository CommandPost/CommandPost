--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.timeline.generators ===
---
--- Controls Final Cut Pro's Generators.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local timer             = require("hs.timer")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config            = require("cp.config")
local dialog            = require("cp.dialog")
local fcp               = require("cp.apple.finalcutpro")
local just              = require("cp.just")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

-- plugins.finalcutpro.timeline.generators._cache <cp.prop: table>
-- Field
-- Titles cache.
mod._cache = config.prop("generatorCache", {})

--- plugins.finalcutpro.timeline.generators.apply(action) -> boolean
--- Function
--- Applies the specified action as a generator. Expects action to be a table with the following structure:
---
--- ```lua
--- { name = "XXX", category = "YYY", theme = "ZZZ" }
--- ```
---
--- ...where `"XXX"`, `"YYY"` and `"ZZZ"` are in the current FCPX language. The `category` and `theme` are optional,
--- but if they are known it's recommended to use them, or it will simply execute the first matching generator with that name.
---
--- Alternatively, you can also supply a string with just the name.
---
--- Actions will be cached each session, so that if the user applies the effect multiple times, only the first time will require
--- GUI scripting - subsequent uses will just use the Pasteboard.
---
--- Parameters:
---  * `action`     - A table with the name/category/theme for the generator to apply, or a string with just the name.
---
--- Returns:
---  * `true` if a matching generator was found and applied to the timeline.
function mod.apply(action)

    --------------------------------------------------------------------------------
    -- Get settings:
    --------------------------------------------------------------------------------
    if type(action) == "string" then
        action = { name = action }
    end

    local name, category, theme = action.name, action.category, action.theme

    if name == nil then
        dialog.displayMessage(i18n("noGeneratorShortcut"))
        return false
    end

    --------------------------------------------------------------------------------
    -- Make sure FCPX is at the front.
    --------------------------------------------------------------------------------
    fcp:launch()

    --------------------------------------------------------------------------------
    -- Build a Cache ID:
    --------------------------------------------------------------------------------
    local cacheID = name
    if theme then cacheID = cacheID .. "-" .. theme end
    if category then cacheID = cacheID .. "-" .. name end

    --------------------------------------------------------------------------------
    -- Restore from Cache:
    --------------------------------------------------------------------------------
    if mod._cache()[cacheID] then

        --------------------------------------------------------------------------------
        -- Stop Watching Pasteboard:
        --------------------------------------------------------------------------------
        local pasteboard = mod.pasteboardManager
        pasteboard.stopWatching()

        --------------------------------------------------------------------------------
        -- Save Current Pasteboard Contents for later:
        --------------------------------------------------------------------------------
        local originalPasteboard = pasteboard.readFCPXData()

        --------------------------------------------------------------------------------
        -- Add Cached Item to Pasteboard:
        --------------------------------------------------------------------------------
        local cachedItem = mod._cache()[cacheID]
        local result = pasteboard.writeFCPXData(cachedItem)
        if not result then
            dialog.displayErrorMessage("Failed to add the cached item to Pasteboard.")
            pasteboard.startWatching()
            return false
        end

        --------------------------------------------------------------------------------
        -- Make sure Timeline has focus:
        --------------------------------------------------------------------------------
        local timeline = fcp:timeline()
        timeline:show()
        if not timeline:isShowing() then
            dialog.displayErrorMessage("Unable to display the Timeline.")
            pasteboard.startWatching()
            return false
        end

        --------------------------------------------------------------------------------
        -- Trigger 'Paste' from Menubar:
        --------------------------------------------------------------------------------
        local menuBar = fcp:menuBar()
        if menuBar:isEnabled({"Edit", "Paste as Connected Clip"}) then
            menuBar:selectMenu({"Edit", "Paste as Connected Clip"})
        else
            dialog.displayErrorMessage("Unable to paste Generator.")
            pasteboard.startWatching()
            return false
        end

        --------------------------------------------------------------------------------
        -- Restore Pasteboard:
        --------------------------------------------------------------------------------
        timer.doAfter(1, function()

            --------------------------------------------------------------------------------
            -- Restore Original Pasteboard Contents:
            --------------------------------------------------------------------------------
            if originalPasteboard ~= nil then
                local cbResult = pasteboard.writeFCPXData(originalPasteboard)
                if not cbResult then
                    dialog.displayErrorMessage("Failed to restore original Pasteboard item.")
                    pasteboard.startWatching()
                    return false
                end
            end

            --------------------------------------------------------------------------------
            -- Start watching the Pasteboard again:
            --------------------------------------------------------------------------------
            pasteboard.startWatching()

        end)

        --------------------------------------------------------------------------------
        -- All done:
        --------------------------------------------------------------------------------
        return true

    end

    --------------------------------------------------------------------------------
    -- Save the main Browser layout:
    --------------------------------------------------------------------------------
    local browser = fcp:browser()
    local browserLayout = browser:saveLayout()

    --------------------------------------------------------------------------------
    -- Get Generators Browser:
    --------------------------------------------------------------------------------
    local generators = fcp:generators()
    local generatorsLayout = generators:saveLayout()

    --------------------------------------------------------------------------------
    -- Make sure the panel is open:
    --------------------------------------------------------------------------------
    generators:show()
    if not generators:isShowing() then
        dialog.displayErrorMessage("Unable to display the Generators panel.")
        return false
    end

    --------------------------------------------------------------------------------
    -- Make sure there's nothing in the search box:
    --------------------------------------------------------------------------------
    generators:search():clear()

    --------------------------------------------------------------------------------
    -- Select the Category if provided otherwise just show all:
    --------------------------------------------------------------------------------
    if category then
        generators:showGeneratorsCategory(category)
    else
        generators:showAllGenerators()
    end

    --------------------------------------------------------------------------------
    -- Make sure "Installed Generators" is selected:
    --------------------------------------------------------------------------------
    local group = generators:group():UI()
    local groupValue = group:attributeValue("AXValue")
    if groupValue ~= fcp:string("PEMediaBrowserInstalledGeneratorsMenuItem") then
        generators:showInstalledGenerators()
    end

    --------------------------------------------------------------------------------
    -- Find the requested Generator:
    --------------------------------------------------------------------------------
    local currentItemsUI = generators:currentItemsUI()
    local whichItem = nil
    for _, v in ipairs(currentItemsUI) do
        local title = name
        if theme then
            title = theme .. " - " .. name
        end
        if v:attributeValue("AXTitle") == title then
            whichItem = v
        end
    end
    if not whichItem then
        dialog.displayErrorMessage("Failed to get whichItem in plugins.finalcutpro.timeline.generators.apply.")
        return false
    end
    local grid = currentItemsUI[1]:attributeValue("AXParent")
    if not grid then
        dialog.displayErrorMessage("Failed to get grid in plugins.finalcutpro.timeline.generators.apply.")
        return false
    end

    --------------------------------------------------------------------------------
    -- Select the chosen Generator:
    --------------------------------------------------------------------------------
    grid:setAttributeValue("AXSelectedChildren", {whichItem})
    whichItem:setAttributeValue("AXFocused", true)

    --------------------------------------------------------------------------------
    -- Stop Watching Pasteboard:
    --------------------------------------------------------------------------------
    local pasteboard = mod.pasteboardManager
    pasteboard.stopWatching()

    --------------------------------------------------------------------------------
    -- Save Current Pasteboard Contents for later:
    --------------------------------------------------------------------------------
    local originalPasteboard = pasteboard.readFCPXData()

    --------------------------------------------------------------------------------
    -- Trigger 'Copy' from Menubar:
    --------------------------------------------------------------------------------
    local menuBar = fcp:menuBar()
    menuBar:selectMenu({"Edit", "Copy"})
    local newPasteboard = nil
    just.doUntil(function()

        newPasteboard = pasteboard.readFCPXData()

        if newPasteboard == nil then
            menuBar:selectMenu({"Edit", "Copy"})
            return false
        end

        if originalPasteboard == nil and newPasteboard ~= nil then
            return true
        end

        if newPasteboard ~= originalPasteboard then
            return true
        end

        --------------------------------------------------------------------------------
        -- Let's try again:
        --------------------------------------------------------------------------------
        menuBar:selectMenu({"Edit", "Copy"})
        return false

    end)

    if newPasteboard == nil then
        dialog.displayErrorMessage("Failed to copy Generator.")
        pasteboard.startWatching()
        return false
    end

    --------------------------------------------------------------------------------
    -- Cache the item for faster recall next time:
    --------------------------------------------------------------------------------
    local cache = mod._cache()
    cache[cacheID] = newPasteboard
    mod._cache(cache)

    --------------------------------------------------------------------------------
    -- Make sure Timeline has focus:
    --------------------------------------------------------------------------------
    local timeline = fcp:timeline()
    timeline:show()
    if not timeline:isShowing() then
        dialog.displayErrorMessage("Unable to display the Timeline.")
        return false
    end

    --------------------------------------------------------------------------------
    -- Trigger 'Paste' from Menubar:
    --------------------------------------------------------------------------------
    if menuBar:isEnabled({"Edit", "Paste as Connected Clip"}) then
        menuBar:selectMenu({"Edit", "Paste as Connected Clip"})
    else
        dialog.displayErrorMessage("Unable to paste Generator.")
        pasteboard.startWatching()
        return false
    end

    --------------------------------------------------------------------------------
    -- Restore Layout:
    --------------------------------------------------------------------------------
    timer.doAfter(0.1, function()
        generators:loadLayout(generatorsLayout)
        if browserLayout then browser:loadLayout(browserLayout) end
    end)

    --------------------------------------------------------------------------------
    -- Restore Pasteboard:
    --------------------------------------------------------------------------------
    timer.doAfter(1, function()

        --------------------------------------------------------------------------------
        -- Restore Original Pasteboard Contents:
        --------------------------------------------------------------------------------
        if originalPasteboard ~= nil then
            local result = pasteboard.writeFCPXData(originalPasteboard)
            if not result then
                dialog.displayErrorMessage("Failed to restore original Pasteboard item.")
                pasteboard.startWatching()
                return false
            end
        end

        --------------------------------------------------------------------------------
        -- Start watching Pasteboard again:
        --------------------------------------------------------------------------------
        pasteboard.startWatching()
    end)

    --------------------------------------------------------------------------------
    -- Success:
    --------------------------------------------------------------------------------
    return true
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.timeline.generators",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.pasteboard.manager"]               = "pasteboardManager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    mod.pasteboardManager = deps.pasteboardManager
    return mod
end

return plugin