-- test cases for `cp.is`
local test          = require("cp.test")
local languageID    = require("cp.i18n.languageID")
local localeID      = require("cp.i18n.localeID")

local pack              = table.pack
local parse, forCode, forParts, forLocaleID    = languageID.parse, languageID.forCode, languageID.forParts, languageID.forLocaleID

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

        id = forParts("en")
        ok(eq(id.code, "en"))
        ok(eq(id.language.alpha2, "en"))
        ok(eq(id.region, nil))
        ok(eq(id.script, nil))

        id = forParts("en", nil, "AU")
        ok(eq(id.code, "en-AU"))
        ok(eq(id.language.alpha2, "en"))
        ok(eq(id.region.alpha2, "AU"))
        ok(eq(id.script, nil))

        id = forParts("en", "Latn")
        ok(eq(id.code, "en-Latn"))
        ok(eq(id.language.alpha2, "en"))
        ok(eq(id.region, nil))
        ok(eq(id.script.alpha4, "Latn"))

        id = forParts("xx")
        ok(eq(id, nil))

        id = forParts("en", nil, "XX")
        ok(eq(id, nil))

        id = forParts("en", "Xxxx")
        ok(eq(id, nil))

        id = forParts("Bad Code")
        ok(eq(id, nil))

    end),

    test("forCode", function()
        local id

        id = forCode("en")
        ok(eq(id.code, "en"))
        ok(eq(id.language.alpha2, "en"))
        ok(eq(id.region, nil))
        ok(eq(id.script, nil))

        id = forCode("en-AU")
        ok(eq(id.code, "en-AU"))
        ok(eq(id.language.alpha2, "en"))
        ok(eq(id.region.alpha2, "AU"))
        ok(eq(id.script, nil))

        id = forCode("en-Latn")
        ok(eq(id.code, "en-Latn"))
        ok(eq(id.language.alpha2, "en"))
        ok(eq(id.region, nil))
        ok(eq(id.script.alpha4, "Latn"))

        id = forCode("xx")
        ok(eq(id, nil))

        id = forCode("en-XX")
        ok(eq(id, nil))

        id = forCode("en-Xxxx")
        ok(eq(id, nil))

        id = forCode("Bad Code")
        ok(eq(id, nil))
    end),

    test("forLocale", function()
        local id

        local l = localeID.forCode
        id = forLocaleID(l("en"))
        ok(eq(id.code, "en"))
        ok(eq(id.language.alpha2, "en"))
        ok(eq(id.region, nil))
        ok(eq(id.script, nil))

        id = forLocaleID(l("en_AU"))
        ok(eq(id.code, "en-AU"))
        ok(eq(id.language.alpha2, "en"))
        ok(eq(id.region.alpha2, "AU"))
        ok(eq(id.script, nil))

        id = forLocaleID(l("en-Latn"))
        ok(eq(id.code, "en-Latn"))
        ok(eq(id.language.alpha2, "en"))
        ok(eq(id.region, nil))
        ok(eq(id.script.alpha4, "Latn"))

        id = forLocaleID(l("en-Latn_AU"))
        ok(eq(id.code, "en-AU"))
        ok(eq(id.language.alpha2, "en"))
        ok(eq(id.region.alpha2, "AU"))

        id = forLocaleID(l("en-Latn_AU"), true)
        ok(eq(id.code, "en-Latn"))
        ok(eq(id.language.alpha2, "en"))
        ok(eq(id.region, nil))
        ok(eq(id.script.alpha4, "Latn"))
    end),

    test("cast", function()
        local id

        id = languageID("en-AU")
        ok(eq(id.code, "en-AU"))

        local id2 = languageID(id)
        ok(eq(id, id2))

        local id3 = languageID(localeID("en_AU"))
        ok(eq(id3.code, "en-AU"))
        ok(eq(id3, id))

    end),
}