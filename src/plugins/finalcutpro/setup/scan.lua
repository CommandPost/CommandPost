--- === plugins.finalcutpro.setup.scan ===
---
--- Show setup panel if Final Cut Pro needs scanning.

local require = require

local timer         = require("hs.timer")

local config        = require("cp.config")
local fcp			      = require("cp.apple.finalcutpro")
local i18n          = require("cp.i18n")

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
    if fcp:isSupported() then
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
                            --------------------------------------------------------------------------------
                            -- Show "Scanning in progress" screen:
                            --------------------------------------------------------------------------------
                            setup.injectScript([[
                                function getElementByXpath(path) {
                                  return document.evaluate(path, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue;
                                }
                                getElementByXpath("/html/body/div/div[1]/h1").style.display = "none";
                                getElementByXpath("/html/body/div/div[2]").style.display = "none";
                                getElementByXpath("/html/body/div/div[1]/p").innerHTML = "<h1>]] .. i18n("scanningInProgress") .. [[...</h1><h2>]] .. i18n("thisCanTakeSeveralMinutes") .. [[.</h2>"
                            ]])
                            timer.doAfter(0.1, function()
                                fcp:scanPlugins()
                                setup.nextPanel()
                            end)
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

function plugin.init(deps)
    return mod.init(deps)
end

return plugin
