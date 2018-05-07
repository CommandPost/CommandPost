-- test cases for `cp.is`
local test          = require("cp.test")
local localeID    = require("cp.i18n.localeID")

local pack              = table.pack
local parse, forCode    = localeID.parse, localeID.forCode

return test.suite("cp.i18n.languageID"):with {
    test("parse", function()
        -- good codes
        ok(eq(pack(parse("en")), pack("en", nil, nil)))
        ok(eq(pack(parse("English")), pack("English", nil, nil)))
        ok(eq(pack(parse("en_AU")), pack("en", "AU", nil)))
        ok(eq(pack(parse("en-Latn")), pack("en", nil, "Latn")))
        ok(eq(pack(parse("en-Latn_AU")), pack("en", "AU", "Latn")))

        -- bad codes
        local nada = pack(nil, nil, nil)
        ok(eq(pack(parse("en-AU")), nada))
        ok(eq(pack(parse("English_AU")), nada))
        ok(eq(pack(parse("en_AU-Latn")), nada))
        ok(eq(pack(parse("en-AUX")), nada))
        ok(eq(pack(parse("en-Latin")), nada))
        ok(eq(pack(parse("EN-AU")), nada))
    end),

    test("forCode", function()
        local id

        id = forCode("en")
        ok(eq(id.code, "en"))
        ok(eq(id.language.alpha2, "en"))
        ok(eq(id.region, nil))
        ok(eq(id.script, nil))

        id = forCode("English")
        ok(eq(id.code, "en"))
        ok(eq(id.language.alpha2, "en"))
        ok(eq(id.region, nil))
        ok(eq(id.script, nil))

        id = forCode("en_AU")
        ok(eq(id.code, "en_AU"))
        ok(eq(id.language.alpha2, "en"))
        ok(eq(id.region.alpha2, "AU"))
        ok(eq(id.script, nil))

        id = forCode("en-Latn")
        ok(eq(id.code, "en-Latn"))
        ok(eq(id.language.alpha2, "en"))
        ok(eq(id.region, nil))
        ok(eq(id.script.alpha4, "Latn"))

        id = forCode("English_AU")
        ok(eq(id, nil))

        id = forCode("xx")
        ok(eq(id, nil))

        id = forCode("en-XX")
        ok(eq(id, nil))

        id = forCode("en-Xxxx")
        ok(eq(id, nil))

        id = forCode("Bad Code")
        ok(eq(id, nil))
    end),

    test("matches", function()
        local l = localeID.forCode
        local en, en_AU, en_Latn, en_Latn_AU, de = l("en"), l("en_AU"), l("en-Latn"), l("en-Latn_AU"), l("de")

        ok(eq(en:matches(en), 3))
        ok(eq(en:matches(en_AU), 2))
        ok(eq(en:matches(en_Latn), 2))
        ok(eq(en:matches(en_Latn_AU), 1))
        ok(eq(en:matches(de), 0))
        ok(eq(en_AU:matches(en_AU), 3))
        ok(eq(en_AU:matches(en), 0))
        ok(eq(en_AU:matches(en_Latn_AU), 2))
    end),
}