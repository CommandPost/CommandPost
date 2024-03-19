--- === plugins.finalcutpro.inspector.colourlabai ===
---
--- Colourlab Ai Effect.

local require = require

--local log                   = require "hs.logger".new "colourlabAi"

local deferred              = require "cp.deferred"
local fcp                   = require "cp.apple.finalcutpro"
--local i18n                  = require "cp.i18n"

local plugin = {
    id              = "finalcutpro.inspector.colourlabai",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]        = "fcpxCmds",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if FCPX is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    local colourlabAi = fcp.inspector.video:effects():colourlabAi()

    --------------------------------------------------------------------------------
    -- Constants:
    --------------------------------------------------------------------------------
    local SHIFT_AMOUNTS     = {0.01, 0.05, 0.1, 0.5, 1, 2, 5}
    local SUBTITLE          = "Colourlab Ai"
    local DEFER_AMOUNT      = 0.01

    --------------------------------------------------------------------------------
    -- NOTE TO FUTURE CHRIS:
    -- I'm mostly being lazy, but I haven't used i18n for the below values because
    -- Colourlab Ai always seems to display in English anyway.
    --------------------------------------------------------------------------------

    --------------------------------------------------------------------------------
    -- Buttons:
    --------------------------------------------------------------------------------
    local fcpxCmds = deps.fcpxCmds
    fcpxCmds
        :add("colourlabAiColorWheelsWindow")
        :titled("Color Wheels Window")
        :subtitled(SUBTITLE)
        :whenActivated(function() colourlabAi:show():colorWheelsWindow():button():press() end)

    fcpxCmds
        :add("colourlabAiShowHelp")
        :titled("Show Help")
        :subtitled(SUBTITLE)
        :whenActivated(function() colourlabAi:show():showHelp():button():press() end)

    --------------------------------------------------------------------------------
    -- Checkboxes:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("colourlabAiToggleUseSmartMatch")
        :titled("Toggle Use Smart Match")
        :subtitled(SUBTITLE)
        :whenActivated(function() colourlabAi:show():useSmartMatch().value:toggle() end)

    fcpxCmds
        :add("colourlabAiToggleGamutLimit")
        :titled("Toggle Gamut Limit")
        :subtitled(SUBTITLE)
        :whenActivated(function() colourlabAi:show():gamutLimit().value:toggle() end)

    --------------------------------------------------------------------------------
    -- SLIDERS: Gamut Limit
    --------------------------------------------------------------------------------
    local gamutLimitRedValue = 0
    local updateGamutLimitRed = deferred.new(DEFER_AMOUNT):action(function()
        local parameter = colourlabAi:gamutLimitRed()
        parameter:show()
        local original = parameter:value()
        parameter:value(original + gamutLimitRedValue)
        gamutLimitRedValue = 0
    end)

    local gamutLimitGreenValue = 0
    local updateGamutLimitGreen = deferred.new(DEFER_AMOUNT):action(function()
        local parameter = colourlabAi:gamutLimitGreen()
        parameter:show()
        local original = parameter:value()
        parameter:value(original + gamutLimitGreenValue)
        gamutLimitGreenValue = 0
    end)

    local gamutLimitBlueValue = 0
    local updateGamutLimitBlue = deferred.new(DEFER_AMOUNT):action(function()
        local parameter = colourlabAi:gamutLimitBlue()
        parameter:show()
        local original = parameter:value()
        parameter:value(original + gamutLimitBlueValue)
        gamutLimitBlueValue = 0
    end)

    for _, v in pairs(SHIFT_AMOUNTS) do
        --------------------------------------------------------------------------------
        -- Gamut Limit Red:
        --------------------------------------------------------------------------------
        fcpxCmds:add("colourlabAiGamutLimitRedIncrease" .. v)
            :titled("Gamut Limit Red - Increase by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                gamutLimitRedValue = gamutLimitRedValue + v
                updateGamutLimitRed()
            end)
        fcpxCmds:add("colourlabAiGamutLimitRedDecrease" .. v)
            :titled("Gamut Limit Red - Decrease by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                gamutLimitRedValue = gamutLimitRedValue - v
                updateGamutLimitRed()
            end)

        --------------------------------------------------------------------------------
        -- Gamut Limit Green:
        --------------------------------------------------------------------------------
        fcpxCmds:add("colourlabAiGamutLimitGreenIncrease" .. v)
            :titled("Gamut Limit Green - Increase by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                gamutLimitGreenValue = gamutLimitGreenValue + v
                updateGamutLimitGreen()
            end)
        fcpxCmds:add("colourlabAiGamutLimitGreenDecrease" .. v)
            :titled("Gamut Limit Green - Decrease by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                gamutLimitGreenValue = gamutLimitGreenValue - v
                updateGamutLimitGreen()
            end)

        --------------------------------------------------------------------------------
        -- Gamut Limit Blue:
        --------------------------------------------------------------------------------
        fcpxCmds:add("colourlabAiGamutLimitBlueIncrease" .. v)
            :titled("Gamut Limit Blue - Increase by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                gamutLimitBlueValue = gamutLimitBlueValue + v
                updateGamutLimitBlue()
            end)
        fcpxCmds:add("colourlabAiGamutLimitBlueDecrease" .. v)
            :titled("Gamut Limit Blue - Decrease by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                gamutLimitBlueValue = gamutLimitBlueValue - v
                updateGamutLimitBlue()
            end)
    end

    --------------------------------------------------------------------------------
    -- SLIDERS: Printer Lights
    --------------------------------------------------------------------------------
    local printerLightsLumaValue = 0
    local updatePrinterLightsLuma = deferred.new(DEFER_AMOUNT):action(function()
        local parameter = colourlabAi:printerLightsLuma()
        parameter:show()
        local original = parameter:value()
        parameter:value(original + printerLightsLumaValue)
        printerLightsLumaValue = 0
    end)

    local printerLightsRedValue = 0
    local updatePrinterLightsRed = deferred.new(DEFER_AMOUNT):action(function()
        local parameter = colourlabAi:printerLightsRed()
        parameter:show()
        local original = parameter:value()
        parameter:value(original + printerLightsRedValue)
        printerLightsRedValue = 0
    end)

    local printerLightsGreenValue = 0
    local updatePrinterLightsGreen = deferred.new(DEFER_AMOUNT):action(function()
        local parameter = colourlabAi:printerLightsGreen()
        parameter:show()
        local original = parameter:value()
        parameter:value(original + printerLightsGreenValue)
        printerLightsGreenValue = 0
    end)

    local printerLightsBlueValue = 0
    local updatePrinterLightsBlue = deferred.new(DEFER_AMOUNT):action(function()
        local parameter = colourlabAi:printerLightsBlue()
        parameter:show()
        local original = parameter:value()
        parameter:value(original + printerLightsBlueValue)
        printerLightsBlueValue = 0
    end)

    local printerLightsCyanValue = 0
    local updatePrinterLightsCyan = deferred.new(DEFER_AMOUNT):action(function()
        local parameter = colourlabAi:printerLightsCyan()
        parameter:show()
        local original = parameter:value()
        parameter:value(original + printerLightsCyanValue)
        printerLightsCyanValue = 0
    end)

    local printerLightsMagentaValue = 0
    local updatePrinterLightsMagenta = deferred.new(DEFER_AMOUNT):action(function()
        local parameter = colourlabAi:printerLightsMagenta()
        parameter:show()
        local original = parameter:value()
        parameter:value(original + printerLightsMagentaValue)
        printerLightsMagentaValue = 0
    end)

    local printerLightsYellowValue = 0
    local updatePrinterLightsYellow = deferred.new(DEFER_AMOUNT):action(function()
        local parameter = colourlabAi:printerLightsYellow()
        parameter:show()
        local original = parameter:value()
        parameter:value(original + printerLightsYellowValue)
        printerLightsYellowValue = 0
    end)


    for _, v in pairs(SHIFT_AMOUNTS) do
        --------------------------------------------------------------------------------
        -- Printer Lights Luma:
        --------------------------------------------------------------------------------
        fcpxCmds:add("colourlabAiGamutLimitRedIncrease" .. v)
            :titled("Gamut Limit Red - Increase by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                printerLightsLumaValue = printerLightsLumaValue + v
                updatePrinterLightsLuma()
            end)
        fcpxCmds:add("colourlabAiGamutLimitRedDecrease" .. v)
            :titled("Gamut Limit Red - Decrease by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                printerLightsLumaValue = printerLightsLumaValue - v
                updatePrinterLightsLuma()
            end)

        --------------------------------------------------------------------------------
        -- Printer Lights Red:
        --------------------------------------------------------------------------------
        fcpxCmds:add("colourlabAiGamutLimitRedIncrease" .. v)
            :titled("Gamut Limit Red - Increase by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                printerLightsRedValue = printerLightsRedValue + v
                updatePrinterLightsRed()
            end)
        fcpxCmds:add("colourlabAiGamutLimitRedDecrease" .. v)
            :titled("Gamut Limit Red - Decrease by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                printerLightsRedValue = printerLightsRedValue - v
                updatePrinterLightsRed()
            end)

        --------------------------------------------------------------------------------
        -- Printer Lights Green:
        --------------------------------------------------------------------------------
        fcpxCmds:add("colourlabAiGamutLimitGreenIncrease" .. v)
            :titled("Gamut Limit Green - Increase by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                printerLightsGreenValue = printerLightsGreenValue + v
                updatePrinterLightsGreen()
            end)
        fcpxCmds:add("colourlabAiGamutLimitGreenDecrease" .. v)
            :titled("Gamut Limit Green - Decrease by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                printerLightsGreenValue = printerLightsGreenValue - v
                updatePrinterLightsGreen()
            end)

        --------------------------------------------------------------------------------
        -- Printer Lights Blue:
        --------------------------------------------------------------------------------
        fcpxCmds:add("colourlabAiGamutLimitBlueIncrease" .. v)
            :titled("Gamut Limit Blue - Increase by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                printerLightsBlueValue = printerLightsBlueValue + v
                updatePrinterLightsBlue()
            end)
        fcpxCmds:add("colourlabAiGamutLimitBlueDecrease" .. v)
            :titled("Gamut Limit Blue - Decrease by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                printerLightsBlueValue = printerLightsBlueValue - v
                updatePrinterLightsBlue()
            end)

        --------------------------------------------------------------------------------
        -- Printer Lights Cyan:
        --------------------------------------------------------------------------------
        fcpxCmds:add("colourlabAiGamutLimitCyanIncrease" .. v)
            :titled("Gamut Limit Cyan - Increase by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                printerLightsCyanValue = printerLightsCyanValue + v
                updatePrinterLightsCyan()
            end)
        fcpxCmds:add("colourlabAiGamutLimitCyanDecrease" .. v)
            :titled("Gamut Limit Cyan - Decrease by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                printerLightsCyanValue = printerLightsCyanValue - v
                updatePrinterLightsCyan()
            end)

        --------------------------------------------------------------------------------
        -- Printer Lights Magenta:
        --------------------------------------------------------------------------------
        fcpxCmds:add("colourlabAiGamutLimitMagentaIncrease" .. v)
            :titled("Gamut Limit Magenta - Increase by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                printerLightsMagentaValue = printerLightsMagentaValue + v
                updatePrinterLightsMagenta()
            end)
        fcpxCmds:add("colourlabAiGamutLimitMagentaDecrease" .. v)
            :titled("Gamut Limit Magenta - Decrease by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                printerLightsMagentaValue = printerLightsMagentaValue - v
                updatePrinterLightsMagenta()
            end)

        --------------------------------------------------------------------------------
        -- Printer Lights Yellow:
        --------------------------------------------------------------------------------
        fcpxCmds:add("colourlabAiGamutLimitYellowIncrease" .. v)
            :titled("Gamut Limit Yellow - Increase by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                printerLightsYellowValue = printerLightsYellowValue + v
                updatePrinterLightsYellow()
            end)
        fcpxCmds:add("colourlabAiGamutLimitYellowDecrease" .. v)
            :titled("Gamut Limit Yellow - Decrease by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                printerLightsYellowValue = printerLightsYellowValue - v
                updatePrinterLightsYellow()
            end)
    end

    --------------------------------------------------------------------------------
    -- SLIDERS: Lift
    --------------------------------------------------------------------------------
    local liftMasterValue = 0
    local updateLiftMaster = deferred.new(DEFER_AMOUNT):action(function()
        local parameter = colourlabAi:liftMaster()
        parameter:show()
        local original = parameter:value()
        parameter:value(original + liftMasterValue)
        liftMasterValue = 0
    end)

    local liftRedValue = 0
    local updateLiftRed = deferred.new(DEFER_AMOUNT):action(function()
        local parameter = colourlabAi:liftRed()
        parameter:show()
        local original = parameter:value()
        parameter:value(original + liftRedValue)
        liftRedValue = 0
    end)

    local liftGreenValue = 0
    local updateLiftGreen = deferred.new(DEFER_AMOUNT):action(function()
        local parameter = colourlabAi:liftGreen()
        parameter:show()
        local original = parameter:value()
        parameter:value(original + liftGreenValue)
        liftGreenValue = 0
    end)

    local liftBlueValue = 0
    local updateLiftBlue = deferred.new(DEFER_AMOUNT):action(function()
        local parameter = colourlabAi:liftBlue()
        parameter:show()
        local original = parameter:value()
        parameter:value(original + liftBlueValue)
        liftBlueValue = 0
    end)

    for _, v in pairs(SHIFT_AMOUNTS) do
        --------------------------------------------------------------------------------
        -- Lift Master:
        --------------------------------------------------------------------------------
        fcpxCmds:add("colourlabAiLiftMasterIncrease" .. v)
            :titled("Lift Master - Increase by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                liftMasterValue = liftMasterValue + v
                updateLiftMaster()
            end)
        fcpxCmds:add("colourlabAiLiftMasterDecrease" .. v)
            :titled("Lift Master - Decrease by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                liftMasterValue = liftMasterValue - v
                updateLiftMaster()
            end)

        --------------------------------------------------------------------------------
        -- Lift Red:
        --------------------------------------------------------------------------------
        fcpxCmds:add("colourlabAiLiftRedIncrease" .. v)
            :titled("Lift Red - Increase by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                liftRedValue = liftRedValue + v
                updateLiftRed()
            end)
        fcpxCmds:add("colourlabAiLiftRedDecrease" .. v)
            :titled("Lift Red - Decrease by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                liftRedValue = liftRedValue - v
                updateLiftRed()
            end)

        --------------------------------------------------------------------------------
        -- Lift Green:
        --------------------------------------------------------------------------------
        fcpxCmds:add("colourlabAiLiftGreenIncrease" .. v)
            :titled("Lift Green - Increase by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                liftGreenValue = liftGreenValue + v
                updateLiftGreen()
            end)
        fcpxCmds:add("colourlabAiLiftGreenDecrease" .. v)
            :titled("Lift Green - Decrease by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                liftGreenValue = liftGreenValue - v
                updateLiftGreen()
            end)

        --------------------------------------------------------------------------------
        -- Lift Blue:
        --------------------------------------------------------------------------------
        fcpxCmds:add("colourlabAiLiftBlueIncrease" .. v)
            :titled("Lift Blue - Increase by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                liftBlueValue = liftBlueValue + v
                updateLiftBlue()
            end)
        fcpxCmds:add("colourlabAiLiftBlueDecrease" .. v)
            :titled("Lift Blue - Decrease by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                liftBlueValue = liftBlueValue - v
                updateLiftBlue()
            end)
    end

    --------------------------------------------------------------------------------
    -- SLIDERS: Gamma
    --------------------------------------------------------------------------------
    local gammaMasterValue = 0
    local updateGammaMaster = deferred.new(DEFER_AMOUNT):action(function()
        local parameter = colourlabAi:gammaMaster()
        parameter:show()
        local original = parameter:value()
        parameter:value(original + gammaMasterValue)
        gammaMasterValue = 0
    end)

    local gammaRedValue = 0
    local updateGammaRed = deferred.new(DEFER_AMOUNT):action(function()
        local parameter = colourlabAi:gammaRed()
        parameter:show()
        local original = parameter:value()
        parameter:value(original + gammaRedValue)
        gammaRedValue = 0
    end)

    local gammaGreenValue = 0
    local updateGammaGreen = deferred.new(DEFER_AMOUNT):action(function()
        local parameter = colourlabAi:gammaGreen()
        parameter:show()
        local original = parameter:value()
        parameter:value(original + gammaGreenValue)
        gammaGreenValue = 0
    end)

    local gammaBlueValue = 0
    local updateGammaBlue = deferred.new(DEFER_AMOUNT):action(function()
        local parameter = colourlabAi:gammaBlue()
        parameter:show()
        local original = parameter:value()
        parameter:value(original + gammaBlueValue)
        gammaBlueValue = 0
    end)

    for _, v in pairs(SHIFT_AMOUNTS) do
        --------------------------------------------------------------------------------
        -- Gamma Master:
        --------------------------------------------------------------------------------
        fcpxCmds:add("colourlabAiGammaMasterIncrease" .. v)
            :titled("Gamma Master - Increase by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                gammaMasterValue = gammaMasterValue + v
                updateGammaMaster()
            end)
        fcpxCmds:add("colourlabAiGammaMasterDecrease" .. v)
            :titled("Gamma Master - Decrease by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                gammaMasterValue = gammaMasterValue - v
                updateGammaMaster()
            end)

        --------------------------------------------------------------------------------
        -- Gamma Red:
        --------------------------------------------------------------------------------
        fcpxCmds:add("colourlabAiGammaRedIncrease" .. v)
            :titled("Gamma Red - Increase by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                gammaRedValue = gammaRedValue + v
                updateGammaRed()
            end)
        fcpxCmds:add("colourlabAiGammaRedDecrease" .. v)
            :titled("Gamma Red - Decrease by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                gammaRedValue = gammaRedValue - v
                updateGammaRed()
            end)

        --------------------------------------------------------------------------------
        -- Gamma Green:
        --------------------------------------------------------------------------------
        fcpxCmds:add("colourlabAiGammaGreenIncrease" .. v)
            :titled("Gamma Green - Increase by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                gammaGreenValue = gammaGreenValue + v
                updateGammaGreen()
            end)
        fcpxCmds:add("colourlabAiGammaGreenDecrease" .. v)
            :titled("Gamma Green - Decrease by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                gammaGreenValue = gammaGreenValue - v
                updateGammaGreen()
            end)

        --------------------------------------------------------------------------------
        -- Gamma Blue:
        --------------------------------------------------------------------------------
        fcpxCmds:add("colourlabAiGammaBlueIncrease" .. v)
            :titled("Gamma Blue - Increase by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                gammaBlueValue = gammaBlueValue + v
                updateGammaBlue()
            end)
        fcpxCmds:add("colourlabAiGammaBlueDecrease" .. v)
            :titled("Gamma Blue - Decrease by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                gammaBlueValue = gammaBlueValue - v
                updateGammaBlue()
            end)
    end

    --------------------------------------------------------------------------------
    -- SLIDERS: Gain
    --------------------------------------------------------------------------------
    local gainMasterValue = 0
    local updateGainMaster = deferred.new(DEFER_AMOUNT):action(function()
        local parameter = colourlabAi:GainMaster()
        parameter:show()
        local original = parameter:value()
        parameter:value(original + gainMasterValue)
        gainMasterValue = 0
    end)

    local gainRedValue = 0
    local updateGainRed = deferred.new(DEFER_AMOUNT):action(function()
        local parameter = colourlabAi:GainRed()
        parameter:show()
        local original = parameter:value()
        parameter:value(original + gainRedValue)
        gainRedValue = 0
    end)

    local gainGreenValue = 0
    local updateGainGreen = deferred.new(DEFER_AMOUNT):action(function()
        local parameter = colourlabAi:GainGreen()
        parameter:show()
        local original = parameter:value()
        parameter:value(original + gainGreenValue)
        gainGreenValue = 0
    end)

    local gainBlueValue = 0
    local updateGainBlue = deferred.new(DEFER_AMOUNT):action(function()
        local parameter = colourlabAi:GainBlue()
        parameter:show()
        local original = parameter:value()
        parameter:value(original + gainBlueValue)
        gainBlueValue = 0
    end)

    for _, v in pairs(SHIFT_AMOUNTS) do
        --------------------------------------------------------------------------------
        -- Gain Master:
        --------------------------------------------------------------------------------
        fcpxCmds:add("colourlabAiGainMasterIncrease" .. v)
            :titled("Gain Master - Increase by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                gainMasterValue = gainMasterValue + v
                updateGainMaster()
            end)
        fcpxCmds:add("colourlabAiGainMasterDecrease" .. v)
            :titled("Gain Master - Decrease by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                gainMasterValue = gainMasterValue - v
                updateGainMaster()
            end)

        --------------------------------------------------------------------------------
        -- Gain Red:
        --------------------------------------------------------------------------------
        fcpxCmds:add("colourlabAiGainRedIncrease" .. v)
            :titled("Gain Red - Increase by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                gainRedValue = gainRedValue + v
                updateGainRed()
            end)
        fcpxCmds:add("colourlabAiGainRedDecrease" .. v)
            :titled("Gain Red - Decrease by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                gainRedValue = gainRedValue - v
                updateGainRed()
            end)

        --------------------------------------------------------------------------------
        -- Gain Green:
        --------------------------------------------------------------------------------
        fcpxCmds:add("colourlabAiGainGreenIncrease" .. v)
            :titled("Gain Green - Increase by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                gainGreenValue = gainGreenValue + v
                updateGainGreen()
            end)
        fcpxCmds:add("colourlabAiGainGreenDecrease" .. v)
            :titled("Gain Green - Decrease by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                gainGreenValue = gainGreenValue - v
                updateGainGreen()
            end)

        --------------------------------------------------------------------------------
        -- Gain Blue:
        --------------------------------------------------------------------------------
        fcpxCmds:add("colourlabAiGainBlueIncrease" .. v)
            :titled("Gain Blue - Increase by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                gainBlueValue = gainBlueValue + v
                updateGainBlue()
            end)
        fcpxCmds:add("colourlabAiGainBlueDecrease" .. v)
            :titled("Gain Blue - Decrease by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                gainBlueValue = gainBlueValue - v
                updateGainBlue()
            end)
    end

    --------------------------------------------------------------------------------
    -- SLIDERS: Saturation, Contrast, Pivot, Temperature
    --------------------------------------------------------------------------------
    local saturationValue = 0
    local updateSaturation = deferred.new(DEFER_AMOUNT):action(function()
        local parameter = colourlabAi:saturation()
        parameter:show()
        local original = parameter:value()
        parameter:value(original + saturationValue)
        saturationValue = 0
    end)

    local contrastValue = 0
    local updateContrast = deferred.new(DEFER_AMOUNT):action(function()
        local parameter = colourlabAi:contrast()
        parameter:show()
        local original = parameter:value()
        parameter:value(original + contrastValue)
        contrastValue = 0
    end)

    local pivotValue = 0
    local updatePivot = deferred.new(DEFER_AMOUNT):action(function()
        local parameter = colourlabAi:pivot()
        parameter:show()
        local original = parameter:value()
        parameter:value(original + pivotValue)
        pivotValue = 0
    end)

    local temperatureValue = 0
    local updateTemperature = deferred.new(DEFER_AMOUNT):action(function()
        local parameter = colourlabAi:temperature()
        parameter:show()
        local original = parameter:value()
        parameter:value(original + temperatureValue)
        temperatureValue = 0
    end)

    for _, v in pairs(SHIFT_AMOUNTS) do
        --------------------------------------------------------------------------------
        -- Saturation:
        --------------------------------------------------------------------------------
        fcpxCmds:add("colourlabAiSaturationIncrease" .. v)
            :titled("Saturation - Increase by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                saturationValue = saturationValue + v
                updateSaturation()
            end)
        fcpxCmds:add("colourlabAiSaturationDecrease" .. v)
            :titled("Saturation - Decrease by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                saturationValue = saturationValue - v
                updateSaturation()
            end)

        --------------------------------------------------------------------------------
        -- Contrast:
        --------------------------------------------------------------------------------
        fcpxCmds:add("colourlabAiContrastIncrease" .. v)
            :titled("Contrast - Increase by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                contrastValue = contrastValue + v
                updateContrast()
            end)
        fcpxCmds:add("colourlabAiContrastDecrease" .. v)
            :titled("Contrast - Decrease by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                contrastValue = contrastValue - v
                updateContrast()
            end)

        --------------------------------------------------------------------------------
        -- Pivot:
        --------------------------------------------------------------------------------
        fcpxCmds:add("colourlabAiPivotIncrease" .. v)
            :titled("Pivot - Increase by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                pivotValue = pivotValue + v
                updatePivot()
            end)
        fcpxCmds:add("colourlabAiPivotDecrease" .. v)
            :titled("Pivot - Decrease by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                pivotValue = pivotValue - v
                updatePivot()
            end)

        --------------------------------------------------------------------------------
        -- Temperature:
        --------------------------------------------------------------------------------
        fcpxCmds:add("colourlabAiTemperatureIncrease" .. v)
            :titled("Temperature - Increase by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                temperatureValue = temperatureValue + v
                updateTemperature()
            end)
        fcpxCmds:add("colourlabAiTemperatureDecrease" .. v)
            :titled("Temperature - Decrease by " .. v)
            :subtitled(SUBTITLE)
            :whenPressed(function()
                temperatureValue = temperatureValue - v
                updateTemperature()
            end)
    end

end

return plugin
