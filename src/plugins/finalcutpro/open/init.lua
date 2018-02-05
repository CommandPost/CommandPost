--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                    O P E N   F I N A L   C U T   P R O                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.open ===
---
--- Opens Final Cut Pro via Global Shortcut & Menubar.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local fcp           = require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- PRIORITY -> number
-- Constant
-- The menubar position priority.
local PRIORITY = 3

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.open.app() -> none
--- Function
--- Opens Final Cut Pro
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.app()
    fcp:launch()
end

--- plugins.finalcutpro.open.commandEditor() -> none
--- Function
--- Opens the Final Cut Pro Command Editor
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.commandEditor()
    fcp:launch()
    fcp:commandEditor():show()
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.open",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.menu.top"] = "top",
        ["core.commands.global"] = "global",
        ["finalcutpro.commands"] = "fcpxCmds",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Menubar:
    --------------------------------------------------------------------------------
    deps.top
        :addItem(PRIORITY + 1, function()
            if fcp:isInstalled() then
                return {
                    title = i18n("launch") .. " " .. i18n("finalCutPro"),
                    fn = mod.app,
                }
            end
        end)
        :addItem(PRIORITY, function()
            if fcp:isInstalled()  then
                return {
                    title = i18n("openCommandEditor"),
                    fn = mod.commandEditor,
                }
            end
        end)

    --------------------------------------------------------------------------------
    -- Global Commands:
    --------------------------------------------------------------------------------
    local global = deps.global
    global:add("cpLaunchFinalCutPro")
        :activatedBy():ctrl():alt():cmd("l")
        :whenPressed(mod.app)
        :groupedBy("finalCutPro")

    --------------------------------------------------------------------------------
    -- Final Cut Pro Commands:
    --------------------------------------------------------------------------------
    local fcpxCmds = deps.fcpxCmds
    fcpxCmds:add("cpOpenCommandEditor")
        :titled(i18n("openCommandEditor"))
        :whenActivated(mod.commandEditor)

    return mod
end

return plugin