--- === plugins.finalcutpro.setup.scan ===
---
--- Show setup panel if Final Cut Pro needs scanning.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local fcp			= require("cp.apple.finalcutpro")
local config		= require("cp.config")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.setup.scan.init(deps) -> self
--- Function
--- Initialises the module.
---
--- Parameters:
---  * deps - A table of dependencies.
---
--- Returns:
---  * self
function mod.init(deps)
    if fcp:isInstalled() then
        if not fcp:plugins().scanned() then
            --------------------------------------------------------------------------------
            -- Final Cut Pro hasn't been scanned yet:
            --------------------------------------------------------------------------------
            local setup = deps.setup
            local iconPath = config.application():path() .. "/Contents/Resources/AppIcon.icns"

            setup.addPanel(
                setup.panel.new("scanFinalCutPro", 20)
                    :addIcon(iconPath)
                    :addHeading(i18n("scanFinalCutPro"))
                    :addParagraph(i18n("scanFinalCutProSetupOne") .. "<br /><br />" .. i18n("scanFinalCutProSetupTwo"), false)
                    :addButton({
                        label		= i18n("startScan"),
                        onclick		= function()
                            fcp:scanPlugins()
                            setup.nextPanel()
                        end
                    })
            )

            setup.show()
        else
            --------------------------------------------------------------------------------
            -- Load already scanned plugins:
            --------------------------------------------------------------------------------
            fcp:scanPlugins()
        end
    end
    return mod
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id				= "finalcutpro.setup.scan",
    group			= "finalcutpro",
    dependencies	= {
        ["core.setup"]			        = "setup",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    return mod.init(deps)
end

return plugin