--- === plugins.finalcutpro.tangent.os.pasteboard ===
---
--- Pasteboard Tools for Tangent.

local require = require

local i18n = require("cp.i18n")


local plugin = {
    id = "finalcutpro.tangent.os.pasteboard",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.tangent.os"] = "osGroup",
        ["finder.pasteboard"] = "mod",
    }
}

function plugin.init(deps)

    local mod = deps.mod
    local group = deps.osGroup:group(i18n("pasteboard"))
    local id = 0x0AE00001

    group:action(id, i18n("cpMakePasteboardTextUppercase" .. "_title"))
        :onPress(function() mod.processText("uppercase", false) end)
    id = id + 1

    group:action(id, i18n("cpMakePasteboardTextLowercase" .. "_title"))
        :onPress(function() mod.processText("lowercase", false) end)
    id = id + 1

    group:action(id, i18n("cpMakePasteboardTextCamelcase" .. "_title"))
        :onPress(function() mod.processText("camelcase", false) end)
    id = id + 1

    group:action(id, i18n("cpMakeSelectedTextUppercase" .. "_title"))
        :onPress(function() mod.processText("uppercase", true) end)
    id = id + 1

    group:action(id, i18n("cpMakeSelectedTextLowercase" .. "_title"))
        :onPress(function() mod.processText("lowercase", true) end)
    id = id + 1

    group:action(id, i18n("cpMakeSelectedTextCamelcase" .. "_title"))
        :onPress(function() mod.processText("camelcase", true) end)

end

return plugin
