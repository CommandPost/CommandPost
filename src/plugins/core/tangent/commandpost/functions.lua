--- === plugins.core.tangent.commandpost.functions ===
---
--- CommandPost Functions for Tangent.

local require = require

local i18n = require("cp.i18n")

local plugin = {
    id = "core.tangent.commandpost.functions",
    group = "core",
    dependencies = {
        ["core.tangent.commandpost"] = "cpGroup",
        ["core.console"] = "coreConsole",
        ["core.helpandsupport.developerguide"] = "developerguide",
        ["core.helpandsupport.feedback"] = "feedback",
        ["core.helpandsupport.userguide"] = "userguide",
        ["core.preferences.manager"] = "prefsMan",
        ["core.watchfolders.manager"] = "watchfolders",
    }
}

function plugin.init(deps)

    local group = deps.cpGroup:group(i18n("functions"))
    local id = 0x0AF00001

    --------------------------------------------------------------------------------
    -- Global Console:
    --------------------------------------------------------------------------------
    group:action(id, i18n("cpGlobalConsole_title"))
        :onPress(deps.coreConsole.show)
    id = id + 1

    --------------------------------------------------------------------------------
    -- Developers Guide:
    --------------------------------------------------------------------------------
    group:action(id, i18n("cpDeveloperGuide_title"))
        :onPress(deps.developerguide.show)
    id = id + 1

    --------------------------------------------------------------------------------
    -- Feedback:
    --------------------------------------------------------------------------------
    group:action(id, i18n("cpFeedback_title"))
        :onPress(deps.feedback.show)
    id = id + 1

    --------------------------------------------------------------------------------
    -- User Guide:
    --------------------------------------------------------------------------------
    group:action(id, i18n("cpUserGuide_title"))
        :onPress(deps.userguide.show)
    id = id + 1

    --------------------------------------------------------------------------------
    -- Open Debug Console:
    --------------------------------------------------------------------------------
     group:action(id, i18n("cpOpenDebugConsole_title"))
        :onPress(function() hs.openConsole() end)
    id = id + 1

    --------------------------------------------------------------------------------
    -- Preferences:
    --------------------------------------------------------------------------------
     group:action(id, i18n("cpPreferences_title"))
        :onPress(deps.prefsMan.show)
    id = id + 1

    --------------------------------------------------------------------------------
    -- Setup Watch Folders:
    --------------------------------------------------------------------------------
     group:action(id, i18n("cpSetupWatchFolders_title"))
        :onPress(deps.watchfolders.show)

end

return plugin
