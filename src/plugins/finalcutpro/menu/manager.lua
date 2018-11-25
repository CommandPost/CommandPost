--- === plugins.finalcutpro.menu.manager ===
---
--- Final Cut Pro Menu Manager.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config                    = require("cp.config")
local fcp                       = require("cp.apple.finalcutpro")
local i18n                      = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.menu.manager",
    group           = "finalcutpro",
    dependencies    = {
        ["core.menu.manager"] = "menuManager",
        ["core.preferences.panels.menubar"] = "prefs",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- TODO: The menubar preferences should be automatically populated in the
    --       preference panel - this is currently a lazy manual workaround.
    --       Sorry David.
    --------------------------------------------------------------------------------

    local menuManager = deps.menuManager
    local prefs = deps.prefs

    local SECTION_DISABLED_PREFERENCES_KEY_PREFIX = "menubar.sectionDisabled."

    local disabledFn = function()
        return not fcp:isSupported() or not fcp:isFrontmost()
    end

    --------------------------------------------------------------------------------
    -- Add application heading to menubar:
    --------------------------------------------------------------------------------
    local applicationHeader = menuManager.addSection(0.1)
    applicationHeader:setDisabledFn(disabledFn)
    applicationHeader:addApplicationHeading(i18n("finalCutPro"))

    prefs:addHeading(400, i18n("finalCutPro") .. " " .. i18n("sections"))

    --------------------------------------------------------------------------------
    -- Add "Media Import" section to the menubar:
    --------------------------------------------------------------------------------
    local mediaImport = menuManager.addSection(1000)
    mediaImport:setDisabledFn(disabledFn)
    mediaImport:setDisabledPreferenceKey("mediaImport")
    mediaImport:addHeading(i18n("mediaImport"))
    mod.mediaImport = mediaImport

    local mediaImportDisabled = config.prop(SECTION_DISABLED_PREFERENCES_KEY_PREFIX .. "mediaImport", false)
    prefs:addCheckbox(401,
        {
            label = i18n("show") .. " " .. i18n("mediaImport"),
            onchange = function(_, params) mediaImportDisabled(not params.checked) end,
            checked = function() return not mediaImportDisabled() end,
        }
    )

    --------------------------------------------------------------------------------
    -- Add "Timeline" section to the menubar:
    --------------------------------------------------------------------------------
    local timeline = menuManager.addSection(2000)
    timeline:setDisabledFn(disabledFn)
    timeline:setDisabledPreferenceKey("timeline")
    timeline:addHeading(i18n("timeline"))
    mod.timeline = timeline

    local timelineDisabled = config.prop(SECTION_DISABLED_PREFERENCES_KEY_PREFIX .. "timeline", false)
    prefs:addCheckbox(402,
        {
            label = i18n("show") .. " " .. i18n("timeline"),
            onchange = function(_, params) timelineDisabled(not params.checked) end,
            checked = function() return not timelineDisabled() end,
        }
    )

    --------------------------------------------------------------------------------
    -- Add "Pasteboard" section to the menubar:
    --------------------------------------------------------------------------------
    local pasteboard = menuManager.addSection(4000)
    pasteboard:setDisabledFn(disabledFn)
    pasteboard:setDisabledPreferenceKey("pasteboard")
    pasteboard:addHeading(i18n("pasteboard"))
    mod.pasteboard = pasteboard

    local pasteboardDisabled = config.prop(SECTION_DISABLED_PREFERENCES_KEY_PREFIX .. "pasteboard", false)
    prefs:addCheckbox(403,
        {
            label = i18n("show") .. " " .. i18n("pasteboard"),
            onchange = function(_, params) pasteboardDisabled(not params.checked) end,
            checked = function() return not pasteboardDisabled() end,
        }
    )

    --------------------------------------------------------------------------------
    -- Add "Tools" section to the menubar:
    --------------------------------------------------------------------------------
    local tools = menuManager.addSection(5000)
    tools:setDisabledFn(disabledFn)
    tools:setDisabledPreferenceKey("tools")
    tools:addHeading(i18n("tools"))
    mod.tools = tools

    local toolsDisabled = config.prop(SECTION_DISABLED_PREFERENCES_KEY_PREFIX .. "tools", false)
    prefs:addCheckbox(404,
        {
            label = i18n("show") .. " " .. i18n("tools"),
            onchange = function(_, params) toolsDisabled(not params.checked) end,
            checked = function() return not toolsDisabled() end,
        }
    )

    --------------------------------------------------------------------------------
    -- Add "Help & Support" sub-section to the menubar:
    --------------------------------------------------------------------------------
    mod.helpAndSupport = menuManager.helpAndSupport:addMenu(20, function() return i18n("finalCutPro") end)

    return mod
end

return plugin
