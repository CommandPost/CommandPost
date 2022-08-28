--- === plugins.finalcutpro.timeline.generators ===
---
--- Controls Final Cut Pro's Generators.

local require = require

local log               = require "hs.logger".new "generators"

local base64            = require "hs.base64"
local timer             = require "hs.timer"

local config            = require "cp.config"
local dialog            = require "cp.dialog"
local fcp               = require "cp.apple.finalcutpro"
local i18n              = require "cp.i18n"
local json              = require "cp.json"
local just              = require "cp.just"

local doAfter           = timer.doAfter
local doUntil           = just.doUntil

local go                = require "cp.rx.go"
local Do, If            = go.Do, go.If

local mod = {}

-- plugins.finalcutpro.timeline.generators._cache <cp.prop: table>
-- Field
-- Titles cache.
mod._cache = json.prop(config.cachePath, "Final Cut Pro", "Generators.cpCache", {})

local function getCacheID(action)
    local cacheID = action.name
    if action.theme then cacheID = cacheID .. "-" .. action.theme end
    if action.category then cacheID = cacheID .. "-" .. action.category end
    return cacheID
end

local function hasCacheItem(cacheID)
    return mod._cache()[cacheID] ~= nil
end

local function getCacheItem(cacheID)
    local value = mod._cache()[cacheID]
    if value then
        return base64.decode(value)
    end
end

local function setCacheItem(cacheID, value)
    local cache = mod._cache()
    cache[cacheID] = base64.encode(value)
    mod._cache(cache)
end

local function getItemName(action)
    local name = action.name
    if action.theme then name = action.theme .. " - " .. name end
    return name
end

local function findItem(generators, action)
    local fullName = getItemName(action)
    for _, v in ipairs(generators.contents) do
        local title = v:title()
        if title == fullName then
            return v
        end
    end
end

local function preservePasteboard()
    local pasteboard = mod.pasteboardManager
    pasteboard.stopWatching()
    local originalData = pasteboard.readFCPXData()

    -- always restore the pasteboard after the current action is complete
    doAfter(0, function()
        if originalData ~= nil and not pasteboard.writeFCPXData(originalData) then
            log.w("Failed to restore original Pasteboard item after applying Generator.")
        end
        pasteboard.startWatching()
    end)

    return originalData
end

local function copyCachedItem(cacheID)
    local cachedItem = getCacheItem(cacheID)

    if not cachedItem then
        log.ef("Failed to find cached Generator: %s", cacheID)
        return false
    end

    --------------------------------------------------------------------------------
    -- Stop Watching Pasteboard:
    --------------------------------------------------------------------------------
    preservePasteboard()

    --------------------------------------------------------------------------------
    -- Add Cached Item to Pasteboard:
    --------------------------------------------------------------------------------
    local pasteboard = mod.pasteboardManager
    local result = pasteboard.writeFCPXData(cachedItem)
    if not result then
        dialog.displayErrorMessage("Failed to add the cached item to Pasteboard.")
        return false
    end
end

local function pasteAsConnectedClip()
    --------------------------------------------------------------------------------
    -- Make sure Timeline has focus:
    --------------------------------------------------------------------------------
    local timeline = fcp.timeline
    timeline:show()
    if not doUntil(function() return timeline:isShowing() end, 0.5) then
        dialog.displayErrorMessage("Unable to display the Timeline.")
        return false
    end

    --------------------------------------------------------------------------------
    -- Trigger 'Paste' from Menubar:
    --------------------------------------------------------------------------------
    local menuBar = fcp.menu
    if menuBar:isEnabled({"Edit", "Paste as Connected Clip"}) then
        menuBar:selectMenu({"Edit", "Paste as Connected Clip"})
    else
        dialog.displayErrorMessage("Unable to paste Generator.")
        return false
    end
end

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

    if action.name == nil then
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
    local cacheID = getCacheID(action)

    --------------------------------------------------------------------------------
    -- Restore from Cache, unless there's a range selected in the timeline:
    --------------------------------------------------------------------------------
    local rangeSelected = fcp.timeline:isRangeSelected()
    if not rangeSelected and hasCacheItem(cacheID) then
        -----------------------------------------------------------
        -- Restore from Cache:
        -----------------------------------------------------------
        log.df("copying cached item: %s", cacheID)
        copyCachedItem(cacheID)

        --------------------------------------------------------------------------------
        -- Paste the cached item as a connected clip:
        --------------------------------------------------------------------------------
        log.df("pasting cached item as connected clip")
        pasteAsConnectedClip()

        --------------------------------------------------------------------------------
        -- All done:
        --------------------------------------------------------------------------------
        return true
    end

    --------------------------------------------------------------------------------
    -- Save the main Browser layout:
    --------------------------------------------------------------------------------
    local browser = fcp.browser
    local browserLayout = browser:saveLayout()

    --------------------------------------------------------------------------------
    -- Get Generators Browser:
    --------------------------------------------------------------------------------
    local generators = fcp.generators

    --------------------------------------------------------------------------------
    -- Make sure the panel is open:
    --------------------------------------------------------------------------------
    generators:show()
    if not generators:isShowing() then
        dialog.displayErrorMessage("Unable to display the Generators panel.")
        return false
    end

    local generatorsLayout = generators:saveLayout()

    --------------------------------------------------------------------------------
    -- Make sure there's nothing in the search box:
    --------------------------------------------------------------------------------
    generators.search:clear()

    --------------------------------------------------------------------------------
    -- Make sure "Installed Generators" is selected:
    --------------------------------------------------------------------------------
    generators:showInstalledGenerators()

    --------------------------------------------------------------------------------
    -- Select the Category if provided:
    --------------------------------------------------------------------------------
    if action.category then
        generators:showGeneratorsCategory(action.category)
    end

    --------------------------------------------------------------------------------
    -- Find the requested Generator:
    --------------------------------------------------------------------------------
    local whichItem = findItem(generators, action)
    if not whichItem then
        dialog.displayErrorMessage(string.format("Failed to get find generator \"%s\" in plugins.finalcutpro.timeline.generators.apply.", action.name))
        return false
    end

    --------------------------------------------------------------------------------
    -- If there's a range selected, do the old fashion way (ninja clicking):
    --------------------------------------------------------------------------------
    if rangeSelected then
        --------------------------------------------------------------------------------
        -- Apply item:
        --------------------------------------------------------------------------------
        Do(whichItem:doApply())
        :Then(generators:doLayout(generatorsLayout))
        :Then(If(browserLayout):Then(browser:doLayout(browserLayout)))
        :Now()

        return true
    end

    --------------------------------------------------------------------------------
    -- Make sure the correct window has focus:
    --------------------------------------------------------------------------------
    if not whichItem:focusOnWindow() then
        dialog.displayErrorMessage("Failed to select the window that contains the Generator Browser.")
        return false
    end

    --------------------------------------------------------------------------------
    -- Select the chosen Generator:
    --------------------------------------------------------------------------------
    generators.contents:selectChild(whichItem)
    whichItem:isFocused(true)

    preservePasteboard()

    --------------------------------------------------------------------------------
    -- Trigger 'Copy' from Menubar:
    --------------------------------------------------------------------------------
    local pasteboard = mod.pasteboardManager
    pasteboard.writeFCPXData("")
    if not doUntil(function() return pasteboard.readFCPXData() == "" end) then
        dialog.displayErrorMessage("Failed to clear the Pasteboard.")
        return false
    end
    local menuBar = fcp.menu
    local newData = doUntil(function()
        menuBar:selectMenu({"Edit", "Copy"})
        local data = pasteboard.readFCPXData()
        if data == "" then
            return nil
        else
            return data
        end
    end)

    if newData == nil then
        dialog.displayErrorMessage("Failed to copy Generator.")
        pasteboard.startWatching()
        return false
    end

    --------------------------------------------------------------------------------
    -- Cache the item for faster recall next time:
    --------------------------------------------------------------------------------
    log.df("Caching Generator: %s", cacheID)
    setCacheItem(cacheID, newData)

    --------------------------------------------------------------------------------
    -- Paste the copied item as a connected clip:
    --------------------------------------------------------------------------------
    pasteAsConnectedClip()

    --------------------------------------------------------------------------------
    -- Restore Layout:
    --------------------------------------------------------------------------------
    doAfter(0.1, function()
        generators:loadLayout(generatorsLayout)
        if browserLayout then browser:loadLayout(browserLayout) end
    end)

    --------------------------------------------------------------------------------
    -- Success:
    --------------------------------------------------------------------------------
    return true
end

local plugin = {
    id = "finalcutpro.timeline.generators",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.pasteboard.manager"]               = "pasteboardManager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    mod.pasteboardManager = deps.pasteboardManager
    return mod
end

return plugin
