--- === plugins.textedit.application.manager ===
---
--- Registers TextEdit with the Core Application Manager.

local require               = require

local plugin = {
    id              = "textedit.application.manager",
    group           = "textedit",
    dependencies    = {
        ["core.application.manager"] = "manager",
    }
}

function plugin.init(deps)
    deps.manager.registerApplication({
        bundleID = "com.apple.TextEdit",
        displayName = "TextEdit",
    })
end

return plugin