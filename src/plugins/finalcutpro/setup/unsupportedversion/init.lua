--- === plugins.finalcutpro.setup.unsupportedversion ===
---
--- Unsupported version setup panel.

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

--- plugins.finalcutpro.setup.unsupportedversion.notifiedVersion <cp.prop: string>
--- Variable
--- Notified Version
mod.notifiedVersion = config.prop("finalcutproUnsupportedVersionNotified", nil)

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id				= "finalcutpro.setup.unsupportedversion",
    group			= "finalcutpro",
    dependencies	= {
        ["core.setup"]			= "setup",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- The last version we notified about:
    --------------------------------------------------------------------------------
    local notified = mod.notifiedVersion
    local notNotified = notified:ISNOT(fcp.versionString)
    --------------------------------------------------------------------------------
    -- Require setup if FCP is unsupported and we have not notified about
    -- this version:
    --------------------------------------------------------------------------------
    fcp.isUnsupported:AND(notNotified):watch(function(unsupported)
        if unsupported then
            local setup = deps.setup
            local minVersion = fcp.EARLIEST_SUPPORTED_VERSION

            local iconPath = config.application():path() .. "/Contents/Resources/AppIcon.icns"

            setup.addPanel(
                setup.panel.new("fcpunsupported", 20)
                    :addIcon(iconPath)
                    :addHeading(i18n("finalcutproUnsupportedVersionTitle"))
                    :addParagraph(i18n("finalcutproUnsupportedVersionText", {
                        thisVersion = fcp:versionString(), minVersion = minVersion
                    }), false)
                    :addButton({
                        label		= i18n("continue"),
                        onclick		= function()
                            notified(fcp:versionString())
                            setup.nextPanel()
                        end
                    })
            )

            setup.show()
        end
    end, true)
    return mod
end

return plugin