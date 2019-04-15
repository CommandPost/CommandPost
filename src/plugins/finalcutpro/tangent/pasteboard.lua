--- === plugins.finalcutpro.tangent.pasteboard ===
---
--- Final Cut Pro Tangent Pasteboard Group

local require = require

local i18n        = require("cp.i18n")


local mod = {}

--- plugins.finalcutpro.tangent.pasteboard.group
--- Constant
--- The `core.tangent.manager.group` that collects Final Cut Pro New actions/parameters/etc.
mod.group = nil

--- plugins.finalcutpro.tangent.pasteboard.init() -> none
--- Function
--- Initialises the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init(fcpGroup, pbm)

    local baseID = 0x00130000

    mod.group = fcpGroup:group(i18n("pasteboardBuffer"))

    mod.save = mod.group:group(i18n("save"))
    mod.restore = mod.group:group(i18n("restore"))

    local nextID = baseID
    for id=1, pbm.NUMBER_OF_PASTEBOARD_BUFFERS do

        mod.save:action(nextID, i18n("pasteboardBuffer") .. " " .. tostring(id))
        :onPress(pbm.doSaveToBuffer(id))
        nextID = nextID + 1

        mod.restore:action(nextID, i18n("pasteboardBuffer") .. " " .. tostring(id))
        :onPress(pbm.doRestoreFromBuffer(id))
        nextID = nextID + 1

    end


end


local plugin = {
    id = "finalcutpro.tangent.pasteboard",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.tangent.group"]   = "fcpGroup",
        ["finalcutpro.pasteboard.manager"] = "pbm",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Initalise the Module:
    --------------------------------------------------------------------------------
    if deps and deps.fcpGroup and deps.pbm then
        mod.init(deps.fcpGroup, deps.pbm)
    end

    return mod
end

return plugin
