--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                  S C A N    F I N A L    C U T    P R O                    --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.preferences.scanfinalcutpro ===
---
--- Scan Final Cut Pro.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local dialog            = require("cp.dialog")
local fcp               = require("cp.apple.finalcutpro")
local feedback          = require("cp.feedback")
local guiscan           = require("cp.apple.finalcutpro.plugins.guiscan")
local just              = require("cp.just")
local html              = require("cp.web.html")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.preferences.scanfinalcutpro.scanFinalCutPro() -> none
--- Function
--- Scan Final Cut Pro
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if successful otherwise `false`.
function mod.scanFinalCutPro()

    if not fcp:isRunning() then
        --log.d("Launching Final Cut Pro.")
        fcp:launch()

        local didFinalCutProLoad = just.doUntil(function()
            --log.d("Checking if Final Cut Pro has loaded.")
            return fcp:primaryWindow():isShowing()
        end, 10, 1)

        if not didFinalCutProLoad then
            dialog.displayMessage(i18n("loadFinalCutProFailed"))
            return false
        end
        --log.d("Final Cut Pro has loaded.")
    --else
        --log.d("Final Cut Pro is already running.")
    end

    --------------------------------------------------------------------------------
    -- Warning message:
    --------------------------------------------------------------------------------
    dialog.displayMessage(i18n("scanFinalCutProWarning"))

    local ok, result = guiscan.check()

    print(result)

    --------------------------------------------------------------------------------
    -- Competition Message:
    --------------------------------------------------------------------------------
    if ok then
        dialog.displayMessage(i18n("scanFinalCutProDone"))
    else
        feedback.showFeedback()
    end

    return true
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.preferences.scanfinalcutpro",
    group = "finalcutpro",
    dependencies = {
        ["core.preferences.panels.advanced"]            = "advanced",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    if deps.advanced then
        deps.advanced
            :addButton(61.1,
                {
                    label = i18n("scanFinalCutPro"),
                    width = 200,
                    onclick = mod.scanFinalCutPro,
                }
            )
            :addParagraph(61.2, html.span {class="tip"} (
                html.strong ( string.upper(i18n("tip")) .. ": " ) .. i18n("scanFinalCutProDescription")
            ) )
    end

    return mod
end

return plugin