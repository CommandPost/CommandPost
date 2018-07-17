local test				= require("cp.test")
-- local log				= require("hs.logger").new("testlocalized")
-- local inspect			= require("hs.inspect")

local config			= require("cp.config")
local localized			= require("cp.localized")

local PLUGINS_PATH = config.testsPath .. "/cp/localized/_resources"
local EFFECTS_PATH = PLUGINS_PATH .. "/Effects.localized"

return test.suite("cp.cp.localized"):with(
    test("Read Localized Strings", function()
        local result = localized.readLocalizedStrings(EFFECTS_PATH.."/.localized/French.strings", "Effects")
        ok(eq(result, "Effets"))

    end),

    test("Read Localized Name", function()
        local result = localized.readLocalizedName(PLUGINS_PATH.."/Effects.localized", "Effects", "fr")
        ok(eq(result, "Effets"))
    end),

    test("Get Localized Name", function()
        local l, o = localized.getLocalizedName(EFFECTS_PATH, "en")
        ok(eq(l, "Effects"))
        ok(eq(o, "Effects"))
        l, o = localized.getLocalizedName(EFFECTS_PATH, "ja")
        ok(eq(l, "エフェクト"))
        ok(eq(o, "Effects"))

        l, o = localized.getLocalizedName(EFFECTS_PATH.."/Local.localized", "en")
        ok(eq(l, "Local EN"))
        ok(eq(o, "Local"))
    end),

    test("Get Versioned Localized Name", function()
        local l, o = localized.getLocalizedName(EFFECTS_PATH.."/Local.localized/Versioned Effect.v2.localized", "en")
        ok(eq(l, "Versioned Effect EN"))
        ok(eq(o, "Versioned Effect.v2"))
    end),

    test("Get Quoted Name", function()
        local l, o = localized.getLocalizedName(PLUGINS_PATH.."/DoubleQuoted.localized", "en")
        ok(eq(l, 'Double "Quoted"'))
        ok(eq(o, "DoubleQuoted"))
    end)
)
