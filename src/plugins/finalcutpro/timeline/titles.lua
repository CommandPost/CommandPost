--- === plugins.finalcutpro.timeline.titles ===
---
--- Controls Final Cut Pro's Titles.

local require = require

local base64            = require("hs.base64")
local timer             = require("hs.timer")

local config            = require("cp.config")
local dialog            = require("cp.dialog")
local fcp               = require("cp.apple.finalcutpro")
local i18n              = require("cp.i18n")
local json              = require("cp.json")
local just              = require("cp.just")

local doAfter           = timer.doAfter


local mod = {}

-- plugins.finalcutpro.timeline.titles._cache <cp.prop: table>
-- Field
-- Titles cache.
mod._cache = json.prop(config.cachePath, "Final Cut Pro", "Titles.cpCache", {})

--- plugins.finalcutpro.timeline.titles.apply(action) -> boolean
--- Function
--- Applies the specified action as a title. Expects action to be a table with the following structure:
---
--- ```lua
--- { name = "XXX", category = "YYY", theme = "ZZZ" }
--- ```
---
--- ...where `"XXX"`, `"YYY"` and `"ZZZ"` are in the current FCPX language. The `category` and `theme` are optional,
--- but if they are known it's recommended to use them, or it will simply execute the first matching title with that name.
---
--- Alternatively, you can also supply a string with just the name.
---
--- Actions will be cached each session, so that if the user applies the effect multiple times, only the first time will require
--- GUI scripting - subsequent uses will just use the Pasteboard.
---
--- Parameters:
---  * `action`      - A table with the name/category/theme for the title to apply, or a string with just the name.
---
--- Returns:
---  * `true` if a matching title was found and applied to the timeline.
function mod.apply(action)

    --------------------------------------------------------------------------------
    -- Get settings:
    --------------------------------------------------------------------------------
    if type(action) == "string" then
        action = { name = action }
    end

    local name, category, theme = action.name, action.category, action.theme

    if name == nil then
        dialog.displayMessage(i18n("noTitleShortcut"))
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
        local cachedItem = base64.decode(mod._cache()[cacheID])
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
        local menuBar = fcp:menu()
        if menuBar:isEnabled({"Edit", "Paste as Connected Clip"}) then
            menuBar:selectMenu({"Edit", "Paste as Connected Clip"})
        else
            dialog.displayErrorMessage("Unable to paste Title.")
            pasteboard.startWatching()
            return false
        end

        --------------------------------------------------------------------------------
        -- Restore Pasteboard:
        --------------------------------------------------------------------------------
        doAfter(1, function()

            --------------------------------------------------------------------------------
            -- Restore Original Pasteboard Contents:
            --------------------------------------------------------------------------------
            if originalPasteboard ~= nil then
                local v = pasteboard.writeFCPXData(originalPasteboard)
                if not v then
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
    -- Get Titles Browser:
    --------------------------------------------------------------------------------
    local generators = fcp:generators()
    local generatorsLayout = generators:saveLayout()

    --------------------------------------------------------------------------------
    -- Make sure the panel is open:
    --------------------------------------------------------------------------------
    generators:show()
    if not generators:isShowing() then
        dialog.displayErrorMessage("Unable to display the Titles panel.")
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
        generators:showTitlesCategory(category)
    else
        generators:showAllTitles()
    end

    --------------------------------------------------------------------------------
    -- Make sure "Installed Titles" is selected:
    --------------------------------------------------------------------------------
    local group = generators:group():UI()
    local groupValue = group:attributeValue("AXValue")
    if groupValue ~= fcp:string("PEMediaBrowserInstalledTitlesMenuItem") then
        generators:showInstalledTitles()
    end

    --------------------------------------------------------------------------------
    -- Find the requested Title:
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
    if whichItem == nil then
        dialog.displayErrorMessage("Failed to get whichItem in plugins.finalcutpro.timeline.titles.apply.")
        return false
    end
    local grid = currentItemsUI[1]:attributeValue("AXParent")
    if not grid then
        dialog.displayErrorMessage("Failed to get grid in plugins.finalcutpro.timeline.titles.apply.")
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
    local menuBar = fcp:menu()
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
        dialog.displayErrorMessage("Failed to copy Title.")
        pasteboard.startWatching()
        return false
    end

    --------------------------------------------------------------------------------
    -- Cache the item for faster recall next time:
    --------------------------------------------------------------------------------
    local cache = mod._cache()
    cache[cacheID] = base64.encode(newPasteboard)
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
        dialog.displayErrorMessage("Unable to paste Title.")
        pasteboard.startWatching()
        return false
    end

    --------------------------------------------------------------------------------
    -- Restore Layout:
    --------------------------------------------------------------------------------
    doAfter(0.1, function()
        generators:loadLayout(generatorsLayout)
        if browserLayout then browser:loadLayout(browserLayout) end
    end)

    --------------------------------------------------------------------------------
    -- Restore Pasteboard:
    --------------------------------------------------------------------------------
    doAfter(1, function()

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


local plugin = {
    id = "finalcutpro.timeline.titles",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.pasteboard.manager"]               = "pasteboardManager",
    }
}

function plugin.init(deps)
    mod.pasteboardManager = deps.pasteboardManager
    return mod
end

return plugin
