--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                       M I D I    C O N T R O L S                           --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.midi.controls.banks ===
---
--- MIDI Control Bank Actions.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
--local log                           = require("hs.logger").new("banks")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local dialog                        = require("cp.dialog")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.core.midi.controls.banks.init() -> nil
--- Function
--- Initialise the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init()
    mod._handler = mod._actionmanager.addHandler("global_midibanks")
        :onChoices(function(choices)
            for i=1, mod._manager.numberOfSubGroups do
                choices:add(i18n("midiBank") .. " " .. tostring(i))
                    :subText(i18n("midiBankDescription"))
                    :params({ id = i })
                    :id(i)
            end

            choices:add(i18n("next") .. " " .. i18n("midiBank"))
                :subText(i18n("midiBankDescription"))
                :params({ id = "next" })
                :id("next")

            choices:add(i18n("previous") .. " " .. i18n("midiBank"))
                :subText(i18n("midiBankDescription"))
                :params({ id = "previous" })
                :id("previous")

            return choices
        end)
        :onExecute(function(result)
            if result and result.id then
                if type(result.id) == "number" then
                    mod._manager.gotoSubGroup(result.id)
                else
                    if result.id == "next" then
                        mod._manager.nextSubGroup()
                    elseif result.id == "previous" then
                        mod._manager.previousSubGroup()
                    end
                end
                local activeSubGroup = mod._manager.activeSubGroup()
                if activeSubGroup then
                    dialog.displayNotification(i18n("midiBank") .. " " .. activeSubGroup)
                end
            end
        end)
    return mod
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "core.midi.controls.banks",
    group           = "core",
    dependencies    = {
        ["core.midi.manager"]   = "manager",
        ["core.action.manager"]	= "actionmanager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    mod._manager = deps.manager
    mod._actionmanager = deps.actionmanager
    return mod.init()
end

return plugin