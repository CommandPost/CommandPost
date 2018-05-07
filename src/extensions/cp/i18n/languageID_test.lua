-- test cases for `cp.is`
local test          = require("cp.test")
local languageID    = require("cp.i18n.languageID")
local localeID      = require("cp.i18n.localeID")

local pack              = table.pack
local parse, forCode, forParts, forLocale    = languageID.parse, languageID.forCode, languageID.forParts, langaugeID.forLocale

return test.suite("cp.i18n.languageID"):with {
    test("parse", function()
        -- good codes
        ok(eq(pack(parse("en")), pack("en", nil, nil)))
        ok(eq(pack(parse("en-AU")), pack("en", nil, "AU")))
        ok(eq(pack(parse("en-AU")), pack("en", nil, "AU")))
        ok(eq(pack(parse("en-Latn")), pack("en", "Latn", nil)))

        -- bad codes
        ok(eq(pack(parse("en-AU-Latn")), pack(nil, nil, nil)))
        ok(eq(pack(parse("en-AUX")), pack(nil, nil, nil)))
        ok(eq(pack(parse("en-Latin")), pack(nil, nil, nil)))
        ok(eq(pack(parse("EN-AU")), pack(nil, nil, nil)))
    end),

    test("forParts", function()
        local id

        id = forCode("en")
        ok(eq(id.code, "en"))
        ok(eq(id.language.alpha2, "en"))
        ok(eq(id.region, nil))
        ok(eq(id.script, nil))
        ok(eq(tostring(id), "en"))

        id = forCode("en", nil, "AU")
        ok(eq(id.code, "en-AU"))
        ok(eq(id.language.alpha2, "en"))
        ok(eq(id.region.alpha2, "AU"))
        ok(eq(id.script, nil))
        ok(eq(tostring(id), "en-AU"))

        id = forCode("en", "Latn")
        ok(eq(id.code, "en-Latn"))
        ok(eq(id.language.alpha2, "en"))
        ok(eq(id.region, nil))
        ok(eq(id.script.alpha4, "Latn"))
        ok(eq(tostring(id), "en-Latn"))

        id = forCode("xx")
        ok(eq(id, nil))

        id = forCode("en-XX")
        ok(eq(id, nil))

        id = forCode("en-Xxxx")
        ok(eq(id, nil))

        id = forCode("Bad Code")
        ok(eq(id, nil))

    end),

    test("forCode", function()
        local id

        id = forCode("en")
        ok(eq(id.code, "en"))
        ok(eq(id.language.alpha2, "en"))
        ok(eq(id.region, nil))
        ok(eq(id.script, nil))
        ok(eq(tostring(id), "en"))

        id = forCode("en-AU")
        ok(eq(id.code, "en-AU"))
        ok(eq(id.language.alpha2, "en"))
        ok(eq(id.region.alpha2, "AU"))
        ok(eq(id.script, nil))
        ok(eq(tostring(id), "en-AU"))

        id = forCode("en-Latn")
        ok(eq(id.code, "en-Latn"))
        ok(eq(id.language.alpha2, "en"))
        ok(eq(id.region, nil))
        ok(eq(id.script.alpha4, "Latn"))
        ok(eq(tostring(id), "en-Latn"))

        id = forCode("xx")
        ok(eq(id, nil))

        id = forCode("en-XX")
        ok(eq(id, nil))

        id = forCode("en-Xxxx")
        ok(eq(id, nil))

        id = forCode("Bad Code")
        ok(eq(id, nil))
    end)
}