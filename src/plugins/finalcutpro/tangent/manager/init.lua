--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.tangent.manager ===
---
--- Final Cut Pro Tangent Manager.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config                                    = require("cp.config")
local fcp                                       = require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.touchbar.manager.enabled <cp.prop: boolean>
--- Field
--- Is `true` if the plugin is enabled.
mod.enabled = config.prop("enableTangent", false):watch(function(enabled)
    if enabled then
        --------------------------------------------------------------------------------
        -- Update Touch Bar Buttons when FCPX is active:
        --------------------------------------------------------------------------------
        mod._fcpWatchID = fcp:watch({
            active      = function() mod._manager.groupStatus("fcpx", true) end,
            show        = function() mod._manager.groupStatus("fcpx", true) end,
            inactive    = function() mod._manager.groupStatus("fcpx", false) end,
            hide        = function() mod._manager.groupStatus("fcpx", false) end,
        })

    else
        --------------------------------------------------------------------------------
        -- Destroy Watchers:
        --------------------------------------------------------------------------------
        if mod._fcpWatchID and mod._fcpWatchID.id then
            fcp:unwatch(mod._fcpWatchID.id)
            mod._fcpWatchID = nil
        end
    end
end)

--- plugins.finalcutpro.tangent.manager.init() -> none
--- Function
--- Initialises the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init()
    --------------------------------------------------------------------------------
    -- Add Final Cut Pro Modes:
    --------------------------------------------------------------------------------
    local modes = {
        ["0x00010002"] = {
            ["name"]        =   "FCP: Edit",
            ["groupID"]     =   "fcpx",
            ["groupSubID"]  =   "edit",
        },
        ["0x00010003"] = {
            ["name"]        =   "FCP: Board",
            ["groupID"]     =   "fcpx",
            ["groupSubID"]  =   "board",
        },
        ["0x00010004"] = {
            ["name"]        =   "FCP: Wheels",
            ["groupID"]     =   "fcpx",
            ["groupSubID"]  =   "wheels",
        },
        ["0x00010005"] = {
            ["name"]        =   "FCP: Prep",
            ["groupID"]     =   "fcpx",
            ["groupSubID"]  =   "prep",
        },
        ["0x00010006"] = {
            ["name"]        =   "FCP: Keyword",
            ["groupID"]     =   "fcpx",
            ["groupSubID"]  =   "keyword",
        },
        ["0x00010007"] = {
            ["name"]        =   "FCP: Speed",
            ["groupID"]     =   "fcpx",
            ["groupSubID"]  =   "speed",
        },
        ["0x00010008"] = {
            ["name"]        =   "FCP: Audition",
            ["groupID"]     =   "fcpx",
            ["groupSubID"]  =   "audition",
        },
        ["0x00010009"] = {
            ["name"]        =   "FCP: Multicam",
            ["groupID"]     =   "fcpx",
            ["groupSubID"]  =   "multicam",
        },
        ["0x00010010"] = {
            ["name"]        =   "FCP: Marker",
            ["groupID"]     =   "fcpx",
            ["groupSubID"]  =   "marker",
        },
        ["0x00010011"] = {
            ["name"]        =   "FCP: Sound",
            ["groupID"]     =   "fcpx",
            ["groupSubID"]  =   "sound",
        },
        ["0x00010012"] = {
            ["name"]        =   "FCP: Function",
            ["groupID"]     =   "fcpx",
            ["groupSubID"]  =   "function",
        },
        ["0x00010013"] = {
            ["name"]        =   "FCP: View",
            ["groupID"]     =   "fcpx",
            ["groupSubID"]  =   "view",
        },
    }
    mod._manager.addModes(modes)

    --------------------------------------------------------------------------------
    -- Add Final Cut Pro Parameters:
    --------------------------------------------------------------------------------
    local parameters = {
        ["fcpx_colorInspector"] = {
            --------------------------------------------------------------------------------
            -- COLOR BOARD - COLOR:
            --------------------------------------------------------------------------------
            ["0x00030001"] = {
                ["name"] = "Color Board - Color - Master - Angle",
                ["name9"] = "CB MS ANG",
                ["minValue"] = 0,
                ["maxValue"] = 359,
                ["stepSize"] = 1,
                ["getValue"] = function() return fcp:colorBoard():color():master():angle() end,
                ["shiftValue"] = function(value) return fcp:colorBoard():color():master():show():shiftAngle(value) end,
                ["resetValue"] = function() fcp:colorBoard():color():master():show():reset() end,
            },
            ["0x00030002"] = {
                ["name"] = "Color Board - Color - Master - Percentage",
                ["name9"] = "CB MS PER",
                ["minValue"] = -100,
                ["maxValue"] = 100,
                ["stepSize"] = 1,
                ["getValue"] = function() return fcp:colorBoard():color():master():percent() end,
                ["shiftValue"] = function(value) return fcp:colorBoard():color():master():show():shiftPercent(value) end,
                ["resetValue"] = function() fcp:colorBoard():color():master():show():reset() end,
            },
            ["0x00030003"] = {
                ["name"] = "Color Board - Color - Shadows - Angle",
                ["name9"] = "CB SD ANG",
                ["minValue"] = 0,
                ["maxValue"] = 359,
                ["stepSize"] = 1,
                ["getValue"] = function() return fcp:colorBoard():color():shadows():angle() end,
                ["shiftValue"] = function(value) return fcp:colorBoard():color():shadows():show():shiftAngle(value) end,
                ["resetValue"] = function() fcp:colorBoard():color():shadows():show():reset() end,
            },
            ["0x00030004"] = {
                ["name"] = "Color Board - Color - Shadows - Percentage",
                ["name9"] = "CB SD PER",
                ["minValue"] = -100,
                ["maxValue"] = 100,
                ["stepSize"] = 1,
                ["getValue"] = function() return fcp:colorBoard():color():shadows():percent() end,
                ["shiftValue"] = function(value) return fcp:colorBoard():color():shadows():show():shiftPercent(value) end,
                ["resetValue"] = function() fcp:colorBoard():color():shadows():show():reset() end,
            },
            ["0x00030005"] = {
                ["name"] = "Color Board - Color - Midtones - Angle",
                ["name9"] = "CB MT ANG",
                ["minValue"] = 0,
                ["maxValue"] = 359,
                ["stepSize"] = 1,
                ["getValue"] = function() return fcp:colorBoard():color():midtones():angle() end,
                ["shiftValue"] = function(value) return fcp:colorBoard():color():midtones():show():shiftAngle(value) end,
                ["resetValue"] = function() fcp:colorBoard():color():midtones():show():reset() end,
            },
            ["0x00030006"] = {
                ["name"] = "Color Board - Color - Midtones - Percentage",
                ["name9"] = "CB HL PER",
                ["minValue"] = -100,
                ["maxValue"] = 100,
                ["stepSize"] = 1,
                ["getValue"] = function() return fcp:colorBoard():color():midtones():percent() end,
                ["shiftValue"] = function(value) return fcp:colorBoard():color():midtones():show():shiftPercent(value) end,
                ["resetValue"] = function() fcp:colorBoard():color():midtones():show():reset() end,
            },
            ["0x00030007"] = {
                ["name"] = "Color Board - Color - Highlights - Angle",
                ["name9"] = "CB HL ANG",
                ["minValue"] = 0,
                ["maxValue"] = 359,
                ["stepSize"] = 1,
                ["getValue"] = function() return fcp:colorBoard():color():highlights():angle() end,
                ["shiftValue"] = function(value) return fcp:colorBoard():color():highlights():show():shiftAngle(value) end,
                ["resetValue"] = function() fcp:colorBoard():color():highlights():show():reset() end,
            },
            ["0x00030008"] = {
                ["name"] = "Color Board - Color - Highlights - Percentage",
                ["name9"] = "CB HL PER",
                ["minValue"] = -100,
                ["maxValue"] = 100,
                ["stepSize"] = 1,
                ["getValue"] = function() return fcp:colorBoard():color():highlights():percent() end,
                ["shiftValue"] = function(value) return fcp:colorBoard():color():highlights():show():shiftPercent(value) end,
                ["resetValue"] = function() fcp:colorBoard():color():highlights():show():reset() end,
            },

            --------------------------------------------------------------------------------
            -- COLOR BOARD - SATURATION:
            --------------------------------------------------------------------------------
            ["0x00030009"] = {
                ["name"] = "Color Board - Saturation - Master",
                ["name9"] = "CB SAT MS",
                ["minValue"] = -100,
                ["maxValue"] = 100,
                ["stepSize"] = 1,
                ["getValue"] = function() return fcp:colorBoard():saturation():master():percent() end,
                ["shiftValue"] = function(value) return fcp:colorBoard():saturation():master():show():shiftPercent(value) end,
                ["resetValue"] = function() fcp:colorBoard():saturation():master():show():reset() end,
            },
            ["0x00030010"] = {
                ["name"] = "Color Board - Saturation - Shadows",
                ["name9"] = "CB SAT SD",
                ["minValue"] = -100,
                ["maxValue"] = 100,
                ["stepSize"] = 1,
                ["getValue"] = function() return fcp:colorBoard():saturation():shadows():percent() end,
                ["shiftValue"] = function(value) return fcp:colorBoard():saturation():shadows():show():shiftPercent(value) end,
                ["resetValue"] = function() fcp:colorBoard():saturation():shadows():show():reset() end,
            },
            ["0x00030011"] = {
                ["name"] = "Color Board - Saturation - Midtones",
                ["name9"] = "CB SAT MT",
                ["minValue"] = -100,
                ["maxValue"] = 100,
                ["stepSize"] = 1,
                ["getValue"] = function() return fcp:colorBoard():saturation():midtones():percent() end,
                ["shiftValue"] = function(value) return fcp:colorBoard():saturation():midtones():show():shiftPercent(value) end,
                ["resetValue"] = function() fcp:colorBoard():saturation():midtones():show():reset() end,
            },
            ["0x00030012"] = {
                ["name"] = "Color Board - Saturation - Highlights",
                ["name9"] = "CB SAT HL",
                ["minValue"] = -100,
                ["maxValue"] = 100,
                ["stepSize"] = 1,
                ["getValue"] = function() return fcp:colorBoard():saturation():highlights():percent() end,
                ["shiftValue"] = function(value) return fcp:colorBoard():saturation():highlights():show():shiftPercent(value) end,
                ["resetValue"] = function() fcp:colorBoard():saturation():highlights():show():reset() end,
            },

            --------------------------------------------------------------------------------
            -- COLOR BOARD - EXPOSURE:
            --------------------------------------------------------------------------------
            ["0x00030013"] = {
                ["name"] = "Color Board - Exposure - Master",
                ["name9"] = "CB EXP MS",
                ["minValue"] = -100,
                ["maxValue"] = 100,
                ["stepSize"] = 1,
                ["getValue"] = function() return fcp:colorBoard():exposure():master():percent() end,
                ["shiftValue"] = function(value) return fcp:colorBoard():exposure():master():show():shiftPercent(value) end,
                ["resetValue"] = function() fcp:colorBoard():exposure():master():show():reset() end,
            },
            ["0x00030014"] = {
                ["name"] = "Color Board - Exposure - Shadows",
                ["name9"] = "CB EXP SD",
                ["minValue"] = -100,
                ["maxValue"] = 100,
                ["stepSize"] = 1,
                ["getValue"] = function() return fcp:colorBoard():exposure():shadows():percent() end,
                ["shiftValue"] = function(value) return fcp:colorBoard():exposure():shadows():show():shiftPercent(value) end,
                ["resetValue"] = function() fcp:colorBoard():exposure():shadows():show():reset() end,
            },
            ["0x00030015"] = {
                ["name"] = "Color Board - Exposure - Midtones",
                ["name9"] = "CB EXP MT",
                ["minValue"] = -100,
                ["maxValue"] = 100,
                ["stepSize"] = 1,
                ["getValue"] = function() return fcp:colorBoard():exposure():midtones():percent() end,
                ["shiftValue"] = function(value) return fcp:colorBoard():exposure():midtones():show():shiftPercent(value) end,
                ["resetValue"] = function() fcp:colorBoard():exposure():midtones():show():reset() end,
            },
            ["0x00030016"] = {
                ["name"] = "Color Board - Exposure - Highlights",
                ["name9"] = "CB EXP HL",
                ["minValue"] = -100,
                ["maxValue"] = 100,
                ["stepSize"] = 1,
                ["getValue"] = function() return fcp:colorBoard():exposure():highlights():percent() end,
                ["shiftValue"] = function(value) return fcp:colorBoard():exposure():highlights():show():shiftPercent(value) end,
                ["resetValue"] = function() fcp:colorBoard():exposure():highlights():show():reset() end,
            },

            --------------------------------------------------------------------------------
            -- COLOR WHEELS - WHEELS:
            --------------------------------------------------------------------------------
            ["0x00030017"] = {
                ["name"] = "Color Wheel - Master - Horizontal",
                ["name9"] = "MSTR HORZ",
                ["minValue"] = -1,
                ["maxValue"] = 1,
                ["stepSize"] = fcp:inspector():color():colorWheels():master():colorWell().KEY_PRESS,
                ["getValue"] = function() return fcp:inspector():color():colorWheels():master():colorOrientation() and fcp:inspector():color():colorWheels():master():colorOrientation().right end,
                ["shiftValue"] = function(value) fcp:inspector():color():colorWheels():master():show():nudgeColor(value, 0) end,
                ["resetValue"] = function() fcp:inspector():color():colorWheels():master():show():reset() end,
            },
            ["0x00030018"] = {
                ["name"] = "Color Wheel - Master - Vertical",
                ["name9"] = "MSTR VERT",
                ["minValue"] = -1,
                ["maxValue"] = 1,
                ["stepSize"] = fcp:inspector():color():colorWheels():master():colorWell().KEY_PRESS,
                ["getValue"] = function() return fcp:inspector():color():colorWheels():master():colorOrientation() and fcp:inspector():color():colorWheels():master():colorOrientation().up end,
                ["shiftValue"] = function(value) fcp:inspector():color():colorWheels():master():show():nudgeColor(0, value) end,
                ["resetValue"] = function() fcp:inspector():color():colorWheels():master():show():reset() end,
            },
            ["0x00030019"] = {
                ["name"] = "Color Wheel - Shadows - Horizontal",
                ["name9"] = "SHDW HORZ",
                ["minValue"] = -1,
                ["maxValue"] = 1,
                ["stepSize"] = fcp:inspector():color():colorWheels():shadows():colorWell().KEY_PRESS,
                ["getValue"] = function() return fcp:inspector():color():colorWheels():shadows():colorOrientation() and fcp:inspector():color():colorWheels():shadows():colorOrientation().right end,
                ["shiftValue"] = function(value) fcp:inspector():color():colorWheels():shadows():show():nudgeColor(value, 0) end,
                ["resetValue"] = function() fcp:inspector():color():colorWheels():shadows():show():reset() end,
            },
            ["0x00030020"] = {
                ["name"] = "Color Wheel - Shadows - Vertical",
                ["name9"] = "SHDW VERT",
                ["minValue"] = -1,
                ["maxValue"] = 1,
                ["stepSize"] = fcp:inspector():color():colorWheels():shadows():colorWell().KEY_PRESS,
                ["getValue"] = function() return fcp:inspector():color():colorWheels():shadows():colorOrientation() and fcp:inspector():color():colorWheels():shadows():colorOrientation().up end,
                ["shiftValue"] = function(value) fcp:inspector():color():colorWheels():shadows():show():nudgeColor(0, value) end,
                ["resetValue"] = function() fcp:inspector():color():colorWheels():shadows():show():reset() end,
            },
            ["0x00030021"] = {
                ["name"] = "Color Wheel - Midtones - Horizontal",
                ["name9"] = "MIDT HORZ",
                ["minValue"] = -1,
                ["maxValue"] = 1,
                ["stepSize"] = fcp:inspector():color():colorWheels():midtones():colorWell().KEY_PRESS,
                ["getValue"] = function() return fcp:inspector():color():colorWheels():midtones():colorOrientation() and fcp:inspector():color():colorWheels():midtones():colorOrientation().right end,
                ["shiftValue"] = function(value) fcp:inspector():color():colorWheels():midtones():show():nudgeColor(value, 0) end,
                ["resetValue"] = function() fcp:inspector():color():colorWheels():midtones():show():reset() end,
            },
            ["0x00030022"] = {
                ["name"] = "Color Wheel - Midtones - Vertical",
                ["name9"] = "MIDT VERT",
                ["minValue"] = -1,
                ["maxValue"] = 1,
                ["stepSize"] = fcp:inspector():color():colorWheels():midtones():colorWell().KEY_PRESS,
                ["getValue"] = function() return fcp:inspector():color():colorWheels():midtones():colorOrientation() and fcp:inspector():color():colorWheels():midtones():colorOrientation().up end,
                ["shiftValue"] = function(value) fcp:inspector():color():colorWheels():midtones():show():nudgeColor(0, value) end,
                ["resetValue"] = function() fcp:inspector():color():colorWheels():midtones():show():reset() end,
            },
            ["0x00030023"] = {
                ["name"] = "Color Wheel - Highlights - Horizontal",
                ["name9"] = "HIGH HORZ",
                ["minValue"] = -1,
                ["maxValue"] = 1,
                ["stepSize"] = fcp:inspector():color():colorWheels():highlights():colorWell().KEY_PRESS,
                ["getValue"] = function() return fcp:inspector():color():colorWheels():highlights():colorOrientation() and fcp:inspector():color():colorWheels():highlights():colorOrientation().right end,
                ["shiftValue"] = function(value) fcp:inspector():color():colorWheels():highlights():show():nudgeColor(value, 0) end,
                ["resetValue"] = function() fcp:inspector():color():colorWheels():highlights():show():reset() end,
            },
            ["0x00030024"] = {
                ["name"] = "Color Wheel - Highlights - Vertical",
                ["name9"] = "HIGH VERT",
                ["minValue"] = -1,
                ["maxValue"] = 1,
                ["stepSize"] = fcp:inspector():color():colorWheels():highlights():colorWell().KEY_PRESS,
                ["getValue"] = function() return fcp:inspector():color():colorWheels():highlights():colorOrientation() and fcp:inspector():color():colorWheels():highlights():colorOrientation().up end,
                ["shiftValue"] = function(value) fcp:inspector():color():colorWheels():highlights():show():nudgeColor(0, value) end,
                ["resetValue"] = function() fcp:inspector():color():colorWheels():highlights():show():reset() end,
            },

            --------------------------------------------------------------------------------
            -- COLOR WHEELS - SATURATION:
            --------------------------------------------------------------------------------
            ["0x00030025"] = {
                ["name"] = "Color Wheel - Master - Saturation",
                ["name9"] = "MSTR SAT",
                ["minValue"] = 0,
                ["maxValue"] = 2,
                ["stepSize"] = 0.01,
                ["getValue"] = function() return fcp:inspector():color():colorWheels():master():saturation():value() end,
                ["shiftValue"] = function(value) fcp:inspector():color():colorWheels():master():saturation():shiftValue(value) end,
                ["resetValue"] = function() fcp:inspector():color():colorWheels():master():saturation():value(1) end,
            },
            ["0x00030026"] = {
                ["name"] = "Color Wheel - Shadows - Saturation",
                ["name9"] = "LOW SAT",
                ["minValue"] = 0,
                ["maxValue"] = 2,
                ["stepSize"] = 0.01,
                ["getValue"] = function() return fcp:inspector():color():colorWheels():shadows():saturation():value() end,
                ["shiftValue"] = function(value) fcp:inspector():color():colorWheels():shadows():saturation():shiftValue(value) end,
                ["resetValue"] = function() fcp:inspector():color():colorWheels():shadows():saturation():value(1) end,
            },
            ["0x00030027"] = {
                ["name"] = "Color Wheel - Midtones - Saturation",
                ["name9"] = "MID SAT",
                ["minValue"] = 0,
                ["maxValue"] = 2,
                ["stepSize"] = 0.01,
                ["getValue"] = function() return fcp:inspector():color():colorWheels():midtones():saturation():value() end,
                ["shiftValue"] = function(value) fcp:inspector():color():colorWheels():midtones():saturation():shiftValue(value) end,
                ["resetValue"] = function() fcp:inspector():color():colorWheels():midtones():saturation():value(1) end,
            },
            ["0x00030028"] = {
                ["name"] = "Color Wheel - Highlights - Saturation",
                ["name9"] = "HIGH SAT",
                ["minValue"] = 0,
                ["maxValue"] = 2,
                ["stepSize"] = 0.01,
                ["getValue"] = function() return fcp:inspector():color():colorWheels():highlights():saturation():value() end,
                ["shiftValue"] = function(value) fcp:inspector():color():colorWheels():highlights():saturation():shiftValue(value) end,
                ["resetValue"] = function() fcp:inspector():color():colorWheels():highlights():saturation():value(1) end,
            },

            --------------------------------------------------------------------------------
            -- COLOR WHEELS - BRIGHTNESS:
            --------------------------------------------------------------------------------
            ["0x00030029"] = {
                ["name"] = "Color Wheel - Master - Brightness",
                ["name9"] = "MSTR BRIG",
                ["minValue"] = -1,
                ["maxValue"] = 1,
                ["stepSize"] = 0.01,
                ["getValue"] = function() return fcp:inspector():color():colorWheels():master():brightness():value() end,
                ["shiftValue"] = function(value) fcp:inspector():color():colorWheels():master():brightness():shiftValue(value) end,
                ["resetValue"] = function() fcp:inspector():color():colorWheels():master():brightness():value(0) end,
            },
            ["0x00030030"] = {
                ["name"] = "Color Wheel - Shadows - Brightness",
                ["name9"] = "LOW BRIG",
                ["minValue"] = -1,
                ["maxValue"] = 1,
                ["stepSize"] = 0.01,
                ["getValue"] = function() return fcp:inspector():color():colorWheels():shadows():brightness():value() end,
                ["shiftValue"] = function(value) fcp:inspector():color():colorWheels():shadows():brightness():shiftValue(value) end,
                ["resetValue"] = function() fcp:inspector():color():colorWheels():shadows():brightness():value(0) end,
            },
            ["0x00030031"] = {
                ["name"] = "Color Wheel - Midtones - Brightness",
                ["name9"] = "MID BRIG",
                ["minValue"] = -1,
                ["maxValue"] = 1,
                ["stepSize"] = 0.01,
                ["getValue"] = function() return fcp:inspector():color():colorWheels():midtones():brightness():value() end,
                ["shiftValue"] = function(value) fcp:inspector():color():colorWheels():midtones():brightness():shiftValue(value) end,
                ["resetValue"] = function() fcp:inspector():color():colorWheels():midtones():brightness():value(0) end,
            },
            ["0x00030032"] = {
                ["name"] = "Color Wheel - Highlights - Brightness",
                ["name9"] = "HIGH BRIG",
                ["minValue"] = -1,
                ["maxValue"] = 1,
                ["stepSize"] = 0.01,
                ["getValue"] = function() return fcp:inspector():color():colorWheels():highlights():brightness():value() end,
                ["shiftValue"] = function(value) fcp:inspector():color():colorWheels():highlights():brightness():shiftValue(value) end,
                ["resetValue"] = function() fcp:inspector():color():colorWheels():highlights():brightness():value(0) end,
            },

            --------------------------------------------------------------------------------
            -- COLOR WHEELS - TEMPERATURE, TINT, HUE, MIX:
            --------------------------------------------------------------------------------
            ["0x00030033"] = {
                ["name"] = "Color Wheel - Temperature",
                ["name9"] = "COLR TEMP",
                ["minValue"] = 2500,
                ["maxValue"] = 10000,
                ["stepSize"] = 0.1,
                ["getValue"] = function() return fcp:inspector():color():colorWheels():temperature() end,
                ["shiftValue"] = function(value) fcp:inspector():color():colorWheels():temperatureSlider():shiftValue(value) end,
                ["resetValue"] = function() fcp:inspector():color():colorWheels():temperatureSlider():setValue(0) end,
            },
            ["0x00030034"] = {
                ["name"] = "Color Wheel - Tint",
                ["name9"] = "COLR TINT",
                ["minValue"] = -50,
                ["maxValue"] = 50,
                ["stepSize"] = 0.1,
                ["getValue"] = function() return fcp:inspector():color():colorWheels():tint() end,
                ["shiftValue"] = function(value) fcp:inspector():color():colorWheels():tintSlider():shiftValue(value) end,
                ["resetValue"] = function() fcp:inspector():color():colorWheels():tintSlider():setValue(0) end,
            },
            ["0x00030035"] = {
                ["name"] = "Color Wheel - Hue",
                ["name9"] = "COLR TINT",
                ["minValue"] = 0,
                ["maxValue"] = 360,
                ["stepSize"] = 0.1,
                ["getValue"] = function() return fcp:inspector():color():colorWheels():hue() end,
                ["shiftValue"] = function(value) fcp:inspector():color():colorWheels():hueSlider():shiftValue(value) end,
                ["resetValue"] = function() fcp:inspector():color():colorWheels():hueSlider():setValue(0) end,
            },
            ["0x00030036"] = {
                ["name"] = "Color Wheel - Mix",
                ["name9"] = "COLR MIX",
                ["minValue"] = 0,
                ["maxValue"] = 1,
                ["stepSize"] = 0.01,
                ["getValue"] = function() return fcp:inspector():color():colorWheels():mix() end,
                ["shiftValue"] = function(value) fcp:inspector():color():colorWheels():mixSlider():shiftValue(value) end,
                ["resetValue"] = function() fcp:inspector():color():colorWheels():mixSlider():setValue(0) end,
            },

            --------------------------------------------------------------------------------
            -- BINDINGS:
            --------------------------------------------------------------------------------
            ["bindings"] = {
                ["name"] = "zzzzzzzzzzz", -- This is just to put the binding alphabetically last.
                ["xml"] = [[
                    <Binding name="Color Board Master Color">
                        <Member id="0x00030001"/>
                        <Member id="0x00030002"/>
                    </Binding>
                    <Binding name="Color Board Shadows Color">
                        <Member id="0x00030003"/>
                        <Member id="0x00030004"/>
                    </Binding>
                    <Binding name="Color Board Midtones Color">
                        <Member id="0x00030005"/>
                        <Member id="0x00030006"/>
                    </Binding>
                    <Binding name="Color Board Highlights Color">
                        <Member id="0x00030007"/>
                        <Member id="0x00030008"/>
                    </Binding>
                    <Binding name="Color Wheels Master">
                        <Member id="0x00030017"/>
                        <Member id="0x00030018"/>
                        <Member id="0x00030025"/>
                    </Binding>
                    <Binding name="Color Wheels Shadows">
                        <Member id="0x00030019"/>
                        <Member id="0x00030020"/>
                        <Member id="0x00030026"/>
                    </Binding>
                    <Binding name="Color Wheels Midtones">
                        <Member id="0x00030021"/>
                        <Member id="0x00030022"/>
                        <Member id="0x00030027"/>
                    </Binding>
                    <Binding name="Color Wheels Highlights">
                        <Member id="0x00030023"/>
                        <Member id="0x00030024"/>
                        <Member id="0x00030028"/>
                    </Binding>
                    ]],
                },
            },
        ["fcpx_timeline"] = {
            --------------------------------------------------------------------------------
            -- TIMELINE ZOOM:
            --------------------------------------------------------------------------------
            ["0x00040001"] = {
                ["name"] = "Timeline Zoom",
                ["name9"] = "Zoom",
                ["minValue"] = 0,
                ["maxValue"] = 10,
                ["stepSize"] = 0.2,
                ["getValue"] = function() return fcp:timeline():toolbar():appearance():zoomAmount():getValue() end,
                ["shiftValue"] = function(value) return fcp:timeline():toolbar():appearance():show():zoomAmount():shiftValue(value) end,
                ["resetValue"] = function() fcp:timeline():toolbar():appearance():show():zoomAmount():setValue(10) end,
            },
        },
    }
    mod._manager.addParameters(parameters)

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.tangent.manager",
    group = "finalcutpro",
    dependencies = {
        ["core.tangent.manager"]       = "manager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Connect to Manager:
    --------------------------------------------------------------------------------
    mod._manager = deps.manager

    --------------------------------------------------------------------------------
    -- Initalise the Module:
    --------------------------------------------------------------------------------
    mod.init()

    return mod
end

--------------------------------------------------------------------------------
-- POST INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.postInit()
    --------------------------------------------------------------------------------
    -- Update visibility:
    --------------------------------------------------------------------------------
    mod.enabled:update()
end

return plugin