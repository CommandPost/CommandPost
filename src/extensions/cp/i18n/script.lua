--- === cp.i18n.script ===
---
--- Provides the set of ISO 15924 language scripts.
--- The return value can be iterated as a list, or you can find a
--- specific language by either its four-character code (`alpha4`), three-character numeric code (`numeric3`),
--- local name, or English name.
---
--- For example:
---
--- ```lua
--- local script = require("cp.i18n.script")
--- print(script[1])        -- table for "Adlam" script
--- print(script.Hani)      -- table for "Han" script (matches `alpha4`)
--- print(script["500"])    -- same table for "Han" (matches `numeric3`)
--- print(script["Han (Hanzi, Kanji, Hanja)"]) -- same table for "Han" (matches `name`)
--- print(script.Han)       -- same table for "Han" (matches `pva`).
--- ```
---
--- This will return a table containing the following:
--- * `alpha4`      - The 4-character script code (eg. "Hani", "Arab").
--- * `date`        - The `YYYY-MM-DD` date the script was added.
--- * `name`        - The name in English (eg. "Arabic", "Afaka").
--- * `numeric3`    - The 3-character language code (eg. "500", "050").
--- * `pva`         - The Property Value Alias. Not available on all scripts.
---
--- Note: This data was adapted from [wooorm's code](https://github.com/wooorm/iso-15924)
--- under an [MIT license](https://raw.githubusercontent.com/wooorm/iso-15924/master/LICENSE).

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log           = require("hs.logger").new("script")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local script = {
    {
        alpha4 = "Adlm",
        date = "2016-12-05",
        name = "Adlam",
        numeric3 = "166",
        pva = "Adlam"
    },
    {
        alpha4 = "Afak",
        date = "2010-12-21",
        name = "Afaka",
        numeric3 = "439"
    },
    {
        alpha4 = "Aghb",
        date = "2014-11-15",
        name = "Caucasian Albanian",
        numeric3 = "239",
        pva = "Caucasian_Albanian"
    },
    {
        alpha4 = "Ahom",
        date = "2015-07-07",
        name = "Ahom, Tai Ahom",
        numeric3 = "338",
        pva = "Ahom"
    },
    {
        alpha4 = "Arab",
        date = "2004-05-01",
        name = "Arabic",
        numeric3 = "160",
        pva = "Arabic"
    },
    {
        alpha4 = "Aran",
        date = "2014-11-15",
        name = "Arabic (Nastaliq variant)",
        numeric3 = "161"
    },
    {
        alpha4 = "Armi",
        date = "2009-06-01",
        name = "Imperial Aramaic",
        numeric3 = "124",
        pva = "Imperial_Aramaic"
    },
    {
        alpha4 = "Armn",
        date = "2004-05-01",
        name = "Armenian",
        numeric3 = "230",
        pva = "Armenian"
    },
    {
        alpha4 = "Avst",
        date = "2009-06-01",
        name = "Avestan",
        numeric3 = "134",
        pva = "Avestan"
    },
    {
        alpha4 = "Bali",
        date = "2006-10-10",
        name = "Balinese",
        numeric3 = "360",
        pva = "Balinese"
    },
    {
        alpha4 = "Bamu",
        date = "2009-06-01",
        name = "Bamum",
        numeric3 = "435",
        pva = "Bamum"
    },
    {
        alpha4 = "Bass",
        date = "2014-11-15",
        name = "Bassa Vah",
        numeric3 = "259",
        pva = "Bassa_Vah"
    },
    {
        alpha4 = "Batk",
        date = "2010-07-23",
        name = "Batak",
        numeric3 = "365",
        pva = "Batak"
    },
    {
        alpha4 = "Beng",
        date = "2016-12-05",
        name = "Bengali (Bangla)",
        numeric3 = "325",
        pva = "Bengali"
    },
    {
        alpha4 = "Bhks",
        date = "2016-12-05",
        name = "Bhaiksuki",
        numeric3 = "334",
        pva = "Bhaiksuki"
    },
    {
        alpha4 = "Blis",
        date = "2004-05-01",
        name = "Blissymbols",
        numeric3 = "550"
    },
    {
        alpha4 = "Bopo",
        date = "2004-05-01",
        name = "Bopomofo",
        numeric3 = "285",
        pva = "Bopomofo"
    },
    {
        alpha4 = "Brah",
        date = "2010-07-23",
        name = "Brahmi",
        numeric3 = "300",
        pva = "Brahmi"
    },
    {
        alpha4 = "Brai",
        date = "2004-05-01",
        name = "Braille",
        numeric3 = "570",
        pva = "Braille"
    },
    {
        alpha4 = "Bugi",
        date = "2006-06-21",
        name = "Buginese",
        numeric3 = "367",
        pva = "Buginese"
    },
    {
        alpha4 = "Buhd",
        date = "2004-05-01",
        name = "Buhid",
        numeric3 = "372",
        pva = "Buhid"
    },
    {
        alpha4 = "Cakm",
        date = "2012-02-06",
        name = "Chakma",
        numeric3 = "349",
        pva = "Chakma"
    },
    {
        alpha4 = "Cans",
        date = "2004-05-29",
        name = "Unified Canadian Aboriginal Syllabics",
        numeric3 = "440",
        pva = "Canadian_Aboriginal"
    },
    {
        alpha4 = "Cari",
        date = "2007-07-02",
        name = "Carian",
        numeric3 = "201",
        pva = "Carian"
    },
    {
        alpha4 = "Cham",
        date = "2009-11-11",
        name = "Cham",
        numeric3 = "358",
        pva = "Cham"
    },
    {
        alpha4 = "Cher",
        date = "2004-05-01",
        name = "Cherokee",
        numeric3 = "445",
        pva = "Cherokee"
    },
    {
        alpha4 = "Cirt",
        date = "2004-05-01",
        name = "Cirth",
        numeric3 = "291"
    },
    {
        alpha4 = "Copt",
        date = "2006-06-21",
        name = "Coptic",
        numeric3 = "204",
        pva = "Coptic"
    },
    {
        alpha4 = "Cpmn",
        date = "2017-07-26",
        name = "Cypro-Minoan",
        numeric3 = "402"
    },
    {
        alpha4 = "Cprt",
        date = "2017-07-26",
        name = "Cypriot syllabary",
        numeric3 = "403",
        pva = "Cypriot"
    },
    {
        alpha4 = "Cyrl",
        date = "2004-05-01",
        name = "Cyrillic",
        numeric3 = "220",
        pva = "Cyrillic"
    },
    {
        alpha4 = "Cyrs",
        date = "2004-05-01",
        name = "Cyrillic (Old Church Slavonic variant)",
        numeric3 = "221"
    },
    {
        alpha4 = "Deva",
        date = "2004-05-01",
        name = "Devanagari (Nagari)",
        numeric3 = "315",
        pva = "Devanagari"
    },
    {
        alpha4 = "Dogr",
        date = "2016-12-05",
        name = "Dogra",
        numeric3 = "328"
    },
    {
        alpha4 = "Dsrt",
        date = "2004-05-01",
        name = "Deseret (Mormon)",
        numeric3 = "250",
        pva = "Deseret"
    },
    {
        alpha4 = "Dupl",
        date = "2014-11-15",
        name = "Duployan shorthand, Duployan stenography",
        numeric3 = "755",
        pva = "Duployan"
    },
    {
        alpha4 = "Egyd",
        date = "2004-05-01",
        name = "Egyptian demotic",
        numeric3 = "070"
    },
    {
        alpha4 = "Egyh",
        date = "2004-05-01",
        name = "Egyptian hieratic",
        numeric3 = "060"
    },
    {
        alpha4 = "Egyp",
        date = "2009-06-01",
        name = "Egyptian hieroglyphs",
        numeric3 = "050",
        pva = "Egyptian_Hieroglyphs"
    },
    {
        alpha4 = "Elba",
        date = "2014-11-15",
        name = "Elbasan",
        numeric3 = "226",
        pva = "Elbasan"
    },
    {
        alpha4 = "Ethi",
        date = "2004-10-25",
        name = "Ethiopic (Geʻez)",
        numeric3 = "430",
        pva = "Ethiopic"
    },
    {
        alpha4 = "Geok",
        date = "2012-10-16",
        name = "Khutsuri (Asomtavruli and Nuskhuri)",
        numeric3 = "241",
        pva = "Georgian"
    },
    {
        alpha4 = "Geor",
        date = "2016-12-05",
        name = "Georgian (Mkhedruli and Mtavruli)",
        numeric3 = "240",
        pva = "Georgian"
    },
    {
        alpha4 = "Glag",
        date = "2006-06-21",
        name = "Glagolitic",
        numeric3 = "225",
        pva = "Glagolitic"
    },
    {
        alpha4 = "Gong",
        date = "2016-12-05",
        name = "Gunjala Gondi",
        numeric3 = "312"
    },
    {
        alpha4 = "Gonm",
        date = "2017-07-26",
        name = "Masaram Gondi",
        numeric3 = "313",
        pva = "Masaram Gondi"
    },
    {
        alpha4 = "Goth",
        date = "2004-05-01",
        name = "Gothic",
        numeric3 = "206",
        pva = "Gothic"
    },
    {
        alpha4 = "Gran",
        date = "2014-11-15",
        name = "Grantha",
        numeric3 = "343",
        pva = "Grantha"
    },
    {
        alpha4 = "Grek",
        date = "2004-05-01",
        name = "Greek",
        numeric3 = "200",
        pva = "Greek"
    },
    {
        alpha4 = "Gujr",
        date = "2004-05-01",
        name = "Gujarati",
        numeric3 = "320",
        pva = "Gujarati"
    },
    {
        alpha4 = "Guru",
        date = "2004-05-01",
        name = "Gurmukhi",
        numeric3 = "310",
        pva = "Gurmukhi"
    },
    {
        alpha4 = "Hanb",
        date = "2016-01-19",
        name = "Han with Bopomofo (alias for Han + Bopomofo)",
        numeric3 = "503"
    },
    {
        alpha4 = "Hang",
        date = "2004-05-29",
        name = "Hangul (Hangŭl, Hangeul)",
        numeric3 = "286",
        pva = "Hangul"
    },
    {
        alpha4 = "Hani",
        date = "2009-02-23",
        name = "Han (Hanzi, Kanji, Hanja)",
        numeric3 = "500",
        pva = "Han"
    },
    {
        alpha4 = "Hano",
        date = "2004-05-29",
        name = "Hanunoo (Hanunóo)",
        numeric3 = "371",
        pva = "Hanunoo"
    },
    {
        alpha4 = "Hans",
        date = "2004-05-29",
        name = "Han (Simplified variant)",
        numeric3 = "501"
    },
    {
        alpha4 = "Hant",
        date = "2004-05-29",
        name = "Han (Traditional variant)",
        numeric3 = "502"
    },
    {
        alpha4 = "Hatr",
        date = "2015-07-07",
        name = "Hatran",
        numeric3 = "127",
        pva = "Hatran"
    },
    {
        alpha4 = "Hebr",
        date = "2004-05-01",
        name = "Hebrew",
        numeric3 = "125",
        pva = "Hebrew"
    },
    {
        alpha4 = "Hira",
        date = "2004-05-01",
        name = "Hiragana",
        numeric3 = "410",
        pva = "Hiragana"
    },
    {
        alpha4 = "Hluw",
        date = "2015-07-07",
        name = "Anatolian Hieroglyphs (Luwian Hieroglyphs, Hittite Hieroglyphs)",
        numeric3 = "080",
        pva = "Anatolian_Hieroglyphs"
    },
    {
        alpha4 = "Hmng",
        date = "2014-11-15",
        name = "Pahawh Hmong",
        numeric3 = "450",
        pva = "Pahawh_Hmong"
    },
    {
        alpha4 = "Hmnp",
        date = "2017-07-26",
        name = "Nyiakeng Puachue Hmong",
        numeric3 = "451"
    },
    {
        alpha4 = "Hrkt",
        date = "2011-06-21",
        name = "Japanese syllabaries (alias for Hiragana + Katakana)",
        numeric3 = "412",
        pva = "Katakana_Or_Hiragana"
    },
    {
        alpha4 = "Hung",
        date = "2015-07-07",
        name = "Old Hungarian (Hungarian Runic)",
        numeric3 = "176",
        pva = "Old_Hungarian"
    },
    {
        alpha4 = "Inds",
        date = "2004-05-01",
        name = "Indus (Harappan)",
        numeric3 = "610"
    },
    {
        alpha4 = "Ital",
        date = "2004-05-29",
        name = "Old Italic (Etruscan, Oscan, etc.)",
        numeric3 = "210",
        pva = "Old_Italic"
    },
    {
        alpha4 = "Jamo",
        date = "2016-01-19",
        name = "Jamo (alias for Jamo subset of Hangul)",
        numeric3 = "284"
    },
    {
        alpha4 = "Java",
        date = "2009-06-01",
        name = "Javanese",
        numeric3 = "361",
        pva = "Javanese"
    },
    {
        alpha4 = "Jpan",
        date = "2006-06-21",
        name = "Japanese (alias for Han + Hiragana + Katakana)",
        numeric3 = "413"
    },
    {
        alpha4 = "Jurc",
        date = "2010-12-21",
        name = "Jurchen",
        numeric3 = "510"
    },
    {
        alpha4 = "Kali",
        date = "2007-07-02",
        name = "Kayah Li",
        numeric3 = "357",
        pva = "Kayah_Li"
    },
    {
        alpha4 = "Kana",
        date = "2004-05-01",
        name = "Katakana",
        numeric3 = "411",
        pva = "Katakana"
    },
    {
        alpha4 = "Khar",
        date = "2006-06-21",
        name = "Kharoshthi",
        numeric3 = "305",
        pva = "Kharoshthi"
    },
    {
        alpha4 = "Khmr",
        date = "2004-05-29",
        name = "Khmer",
        numeric3 = "355",
        pva = "Khmer"
    },
    {
        alpha4 = "Khoj",
        date = "2014-11-15",
        name = "Khojki",
        numeric3 = "322",
        pva = "Khojki"
    },
    {
        alpha4 = "Kitl",
        date = "2015-07-15",
        name = "Khitan large script",
        numeric3 = "505"
    },
    {
        alpha4 = "Kits",
        date = "2015-07-15",
        name = "Khitan small script",
        numeric3 = "288"
    },
    {
        alpha4 = "Knda",
        date = "2004-05-29",
        name = "Kannada",
        numeric3 = "345",
        pva = "Kannada"
    },
    {
        alpha4 = "Kore",
        date = "2007-06-13",
        name = "Korean (alias for Hangul + Han)",
        numeric3 = "287"
    },
    {
        alpha4 = "Kpel",
        date = "2010-03-26",
        name = "Kpelle",
        numeric3 = "436"
    },
    {
        alpha4 = "Kthi",
        date = "2009-06-01",
        name = "Kaithi",
        numeric3 = "317",
        pva = "Kaithi"
    },
    {
        alpha4 = "Lana",
        date = "2009-06-01",
        name = "Tai Tham (Lanna)",
        numeric3 = "351",
        pva = "Tai_Tham"
    },
    {
        alpha4 = "Laoo",
        date = "2004-05-01",
        name = "Lao",
        numeric3 = "356",
        pva = "Lao"
    },
    {
        alpha4 = "Latf",
        date = "2004-05-01",
        name = "Latin (Fraktur variant)",
        numeric3 = "217"
    },
    {
        alpha4 = "Latg",
        date = "2004-05-01",
        name = "Latin (Gaelic variant)",
        numeric3 = "216"
    },
    {
        alpha4 = "Latn",
        date = "2004-05-01",
        name = "Latin",
        numeric3 = "215",
        pva = "Latin"
    },
    {
        alpha4 = "Leke",
        date = "2015-07-07",
        name = "Leke",
        numeric3 = "364"
    },
    {
        alpha4 = "Lepc",
        date = "2007-07-02",
        name = "Lepcha (Róng)",
        numeric3 = "335",
        pva = "Lepcha"
    },
    {
        alpha4 = "Limb",
        date = "2004-05-29",
        name = "Limbu",
        numeric3 = "336",
        pva = "Limbu"
    },
    {
        alpha4 = "Lina",
        date = "2014-11-15",
        name = "Linear A",
        numeric3 = "400",
        pva = "Linear_A"
    },
    {
        alpha4 = "Linb",
        date = "2004-05-29",
        name = "Linear B",
        numeric3 = "401",
        pva = "Linear_B"
    },
    {
        alpha4 = "Lisu",
        date = "2009-06-01",
        name = "Lisu (Fraser)",
        numeric3 = "399",
        pva = "Lisu"
    },
    {
        alpha4 = "Loma",
        date = "2010-03-26",
        name = "Loma",
        numeric3 = "437"
    },
    {
        alpha4 = "Lyci",
        date = "2007-07-02",
        name = "Lycian",
        numeric3 = "202",
        pva = "Lycian"
    },
    {
        alpha4 = "Lydi",
        date = "2007-07-02",
        name = "Lydian",
        numeric3 = "116",
        pva = "Lydian"
    },
    {
        alpha4 = "Mahj",
        date = "2014-11-15",
        name = "Mahajani",
        numeric3 = "314",
        pva = "Mahajani"
    },
    {
        alpha4 = "Maka",
        date = "2016-12-05",
        name = "Makasar",
        numeric3 = "366"
    },
    {
        alpha4 = "Mand",
        date = "2010-07-23",
        name = "Mandaic, Mandaean",
        numeric3 = "140",
        pva = "Mandaic"
    },
    {
        alpha4 = "Mani",
        date = "2014-11-15",
        name = "Manichaean",
        numeric3 = "139",
        pva = "Manichaean"
    },
    {
        alpha4 = "Marc",
        date = "2016-12-05",
        name = "Marchen",
        numeric3 = "332",
        pva = "Marchen"
    },
    {
        alpha4 = "Maya",
        date = "2004-05-01",
        name = "Mayan hieroglyphs",
        numeric3 = "090"
    },
    {
        alpha4 = "Medf",
        date = "2016-12-05",
        name = "Medefaidrin (Oberi Okaime, Oberi Ɔkaimɛ)",
        numeric3 = "265"
    },
    {
        alpha4 = "Mend",
        date = "2014-11-15",
        name = "Mende Kikakui",
        numeric3 = "438",
        pva = "Mende_Kikakui"
    },
    {
        alpha4 = "Merc",
        date = "2012-02-06",
        name = "Meroitic Cursive",
        numeric3 = "101",
        pva = "Meroitic_Cursive"
    },
    {
        alpha4 = "Mero",
        date = "2012-02-06",
        name = "Meroitic Hieroglyphs",
        numeric3 = "100",
        pva = "Meroitic_Hieroglyphs"
    },
    {
        alpha4 = "Mlym",
        date = "2004-05-01",
        name = "Malayalam",
        numeric3 = "347",
        pva = "Malayalam"
    },
    {
        alpha4 = "Modi",
        date = "2014-11-15",
        name = "Modi, Moḍī",
        numeric3 = "324",
        pva = "Modi"
    },
    {
        alpha4 = "Mong",
        date = "2004-05-01",
        name = "Mongolian",
        numeric3 = "145",
        pva = "Mongolian"
    },
    {
        alpha4 = "Moon",
        date = "2006-12-11",
        name = "Moon (Moon code, Moon script, Moon type)",
        numeric3 = "218"
    },
    {
        alpha4 = "Mroo",
        date = "2016-12-05",
        name = "Mro, Mru",
        numeric3 = "264",
        pva = "Mro"
    },
    {
        alpha4 = "Mtei",
        date = "2009-06-01",
        name = "Meitei Mayek (Meithei, Meetei)",
        numeric3 = "337",
        pva = "Meetei_Mayek"
    },
    {
        alpha4 = "Mult",
        date = "2015-07-07",
        name = "Multani",
        numeric3 = "323",
        pva = "Multani"
    },
    {
        alpha4 = "Mymr",
        date = "2004-05-01",
        name = "Myanmar (Burmese)",
        numeric3 = "350",
        pva = "Myanmar"
    },
    {
        alpha4 = "Narb",
        date = "2014-11-15",
        name = "Old North Arabian (Ancient North Arabian)",
        numeric3 = "106",
        pva = "Old_North_Arabian"
    },
    {
        alpha4 = "Nbat",
        date = "2014-11-15",
        name = "Nabataean",
        numeric3 = "159",
        pva = "Nabataean"
    },
    {
        alpha4 = "Newa",
        date = "2016-12-05",
        name = "Newa, Newar, Newari, Nepāla lipi",
        numeric3 = "333",
        pva = "Newa"
    },
    {
        alpha4 = "Nkdb",
        date = "2017-07-26",
        name = "Naxi Dongba (na²¹ɕi³³ to³³ba²¹, Nakhi Tomba)",
        numeric3 = "085"
    },
    {
        alpha4 = "Nkgb",
        date = "2017-07-26",
        name = "Naxi Geba (na²¹ɕi³³ gʌ²¹ba²¹, 'Na-'Khi ²Ggŏ-¹baw, Nakhi Geba)",
        numeric3 = "420"
    },
    {
        alpha4 = "Nkoo",
        date = "2006-10-10",
        name = "N’Ko",
        numeric3 = "165",
        pva = "Nko"
    },
    {
        alpha4 = "Nshu",
        date = "2017-07-26",
        name = "Nüshu",
        numeric3 = "499",
        pva = "Nushu"
    },
    {
        alpha4 = "Ogam",
        date = "2004-05-01",
        name = "Ogham",
        numeric3 = "212",
        pva = "Ogham"
    },
    {
        alpha4 = "Olck",
        date = "2007-07-02",
        name = "Ol Chiki (Ol Cemet’, Ol, Santali)",
        numeric3 = "261",
        pva = "Ol_Chiki"
    },
    {
        alpha4 = "Orkh",
        date = "2009-06-01",
        name = "Old Turkic, Orkhon Runic",
        numeric3 = "175",
        pva = "Old_Turkic"
    },
    {
        alpha4 = "Orya",
        date = "2016-12-05",
        name = "Oriya (Odia)",
        numeric3 = "327",
        pva = "Oriya"
    },
    {
        alpha4 = "Osge",
        date = "2016-12-05",
        name = "Osage",
        numeric3 = "219",
        pva = "Osage"
    },
    {
        alpha4 = "Osma",
        date = "2004-05-01",
        name = "Osmanya",
        numeric3 = "260",
        pva = "Osmanya"
    },
    {
        alpha4 = "Palm",
        date = "2014-11-15",
        name = "Palmyrene",
        numeric3 = "126",
        pva = "Palmyrene"
    },
    {
        alpha4 = "Pauc",
        date = "2014-11-15",
        name = "Pau Cin Hau",
        numeric3 = "263",
        pva = "Pau_Cin_Hau"
    },
    {
        alpha4 = "Perm",
        date = "2014-11-15",
        name = "Old Permic",
        numeric3 = "227",
        pva = "Old_Permic"
    },
    {
        alpha4 = "Phag",
        date = "2006-10-10",
        name = "Phags-pa",
        numeric3 = "331",
        pva = "Phags_Pa"
    },
    {
        alpha4 = "Phli",
        date = "2009-06-01",
        name = "Inscriptional Pahlavi",
        numeric3 = "131",
        pva = "Inscriptional_Pahlavi"
    },
    {
        alpha4 = "Phlp",
        date = "2014-11-15",
        name = "Psalter Pahlavi",
        numeric3 = "132",
        pva = "Psalter_Pahlavi"
    },
    {
        alpha4 = "Phlv",
        date = "2007-07-15",
        name = "Book Pahlavi",
        numeric3 = "133"
    },
    {
        alpha4 = "Phnx",
        date = "2006-10-10",
        name = "Phoenician",
        numeric3 = "115",
        pva = "Phoenician"
    },
    {
        alpha4 = "Plrd",
        date = "2012-02-06",
        name = "Miao (Pollard)",
        numeric3 = "282",
        pva = "Miao"
    },
    {
        alpha4 = "Piqd",
        date = "2015-12-16",
        name = "Klingon (KLI pIqaD)",
        numeric3 = "293"
    },
    {
        alpha4 = "Prti",
        date = "2009-06-01",
        name = "Inscriptional Parthian",
        numeric3 = "130",
        pva = "Inscriptional_Parthian"
    },
    {
        alpha4 = "Qaaa",
        date = "2004-05-29",
        name = "Reserved for private use (start)",
        numeric3 = "900"
    },
    {
        alpha4 = "Qabx",
        date = "2004-05-29",
        name = "Reserved for private use (end)",
        numeric3 = "949"
    },
    {
        alpha4 = "Rjng",
        date = "2009-02-23",
        name = "Rejang (Redjang, Kaganga)",
        numeric3 = "363",
        pva = "Rejang"
    },
    {
        alpha4 = "Rohg",
        date = "2017-11-21",
        name = "Hanifi Rohingya",
        numeric3 = "167"
    },
    {
        alpha4 = "Roro",
        date = "2004-05-01",
        name = "Rongorongo",
        numeric3 = "620"
    },
    {
        alpha4 = "Runr",
        date = "2004-05-01",
        name = "Runic",
        numeric3 = "211",
        pva = "Runic"
    },
    {
        alpha4 = "Samr",
        date = "2009-06-01",
        name = "Samaritan",
        numeric3 = "123",
        pva = "Samaritan"
    },
    {
        alpha4 = "Sara",
        date = "2004-05-29",
        name = "Sarati",
        numeric3 = "292"
    },
    {
        alpha4 = "Sarb",
        date = "2009-06-01",
        name = "Old South Arabian",
        numeric3 = "105",
        pva = "Old_South_Arabian"
    },
    {
        alpha4 = "Saur",
        date = "2007-07-02",
        name = "Saurashtra",
        numeric3 = "344",
        pva = "Saurashtra"
    },
    {
        alpha4 = "Sgnw",
        date = "2015-07-07",
        name = "SignWriting",
        numeric3 = "095",
        pva = "SignWriting"
    },
    {
        alpha4 = "Shaw",
        date = "2004-05-01",
        name = "Shavian (Shaw)",
        numeric3 = "281",
        pva = "Shavian"
    },
    {
        alpha4 = "Shrd",
        date = "2012-02-06",
        name = "Sharada, Śāradā",
        numeric3 = "319",
        pva = "Sharada"
    },
    {
        alpha4 = "Shui",
        date = "2017-07-26",
        name = "Shuishu",
        numeric3 = "530"
    },
    {
        alpha4 = "Sidd",
        date = "2014-11-15",
        name = "Siddham, Siddhaṃ, Siddhamātṛkā",
        numeric3 = "302",
        pva = "Siddham"
    },
    {
        alpha4 = "Sind",
        date = "2014-11-15",
        name = "Khudawadi, Sindhi",
        numeric3 = "318",
        pva = "Khudawadi"
    },
    {
        alpha4 = "Sinh",
        date = "2004-05-01",
        name = "Sinhala",
        numeric3 = "348",
        pva = "Sinhala"
    },
    {
        alpha4 = "Sogd",
        date = "2017-11-21",
        name = "Sogdian",
        numeric3 = "141"
    },
    {
        alpha4 = "Sogo",
        date = "2017-11-21",
        name = "Old Sogdian",
        numeric3 = "142"
    },
    {
        alpha4 = "Sora",
        date = "2012-02-06",
        name = "Sora Sompeng",
        numeric3 = "398",
        pva = "Sora_Sompeng"
    },
    {
        alpha4 = "Soyo",
        date = "2017-07-26",
        name = "Soyombo",
        numeric3 = "329",
        pva = "Soyombo"
    },
    {
        alpha4 = "Sund",
        date = "2007-07-02",
        name = "Sundanese",
        numeric3 = "362",
        pva = "Sundanese"
    },
    {
        alpha4 = "Sylo",
        date = "2006-06-21",
        name = "Syloti Nagri",
        numeric3 = "316",
        pva = "Syloti_Nagri"
    },
    {
        alpha4 = "Syrc",
        date = "2004-05-01",
        name = "Syriac",
        numeric3 = "135",
        pva = "Syriac"
    },
    {
        alpha4 = "Syre",
        date = "2004-05-01",
        name = "Syriac (Estrangelo variant)",
        numeric3 = "138"
    },
    {
        alpha4 = "Syrj",
        date = "2004-05-01",
        name = "Syriac (Western variant)",
        numeric3 = "137"
    },
    {
        alpha4 = "Syrn",
        date = "2004-05-01",
        name = "Syriac (Eastern variant)",
        numeric3 = "136"
    },
    {
        alpha4 = "Tagb",
        date = "2004-05-01",
        name = "Tagbanwa",
        numeric3 = "373",
        pva = "Tagbanwa"
    },
    {
        alpha4 = "Takr",
        date = "2012-02-06",
        name = "Takri, Ṭākrī, Ṭāṅkrī",
        numeric3 = "321",
        pva = "Takri"
    },
    {
        alpha4 = "Tale",
        date = "2004-10-25",
        name = "Tai Le",
        numeric3 = "353",
        pva = "Tai_Le"
    },
    {
        alpha4 = "Talu",
        date = "2006-06-21",
        name = "New Tai Lue",
        numeric3 = "354",
        pva = "New_Tai_Lue"
    },
    {
        alpha4 = "Taml",
        date = "2004-05-01",
        name = "Tamil",
        numeric3 = "346",
        pva = "Tamil"
    },
    {
        alpha4 = "Tang",
        date = "2016-12-05",
        name = "Tangut",
        numeric3 = "520",
        pva = "Tangut"
    },
    {
        alpha4 = "Tavt",
        date = "2009-06-01",
        name = "Tai Viet",
        numeric3 = "359",
        pva = "Tai_Viet"
    },
    {
        alpha4 = "Telu",
        date = "2004-05-01",
        name = "Telugu",
        numeric3 = "340",
        pva = "Telugu"
    },
    {
        alpha4 = "Teng",
        date = "2004-05-01",
        name = "Tengwar",
        numeric3 = "290"
    },
    {
        alpha4 = "Tfng",
        date = "2006-06-21",
        name = "Tifinagh (Berber)",
        numeric3 = "120",
        pva = "Tifinagh"
    },
    {
        alpha4 = "Tglg",
        date = "2009-02-23",
        name = "Tagalog (Baybayin, Alibata)",
        numeric3 = "370",
        pva = "Tagalog"
    },
    {
        alpha4 = "Thaa",
        date = "2004-05-01",
        name = "Thaana",
        numeric3 = "170",
        pva = "Thaana"
    },
    {
        alpha4 = "Thai",
        date = "2004-05-01",
        name = "Thai",
        numeric3 = "352",
        pva = "Thai"
    },
    {
        alpha4 = "Tibt",
        date = "2004-05-01",
        name = "Tibetan",
        numeric3 = "330",
        pva = "Tibetan"
    },
    {
        alpha4 = "Tirh",
        date = "2014-11-15",
        name = "Tirhuta",
        numeric3 = "326",
        pva = "Tirhuta"
    },
    {
        alpha4 = "Ugar",
        date = "2004-05-01",
        name = "Ugaritic",
        numeric3 = "040",
        pva = "Ugaritic"
    },
    {
        alpha4 = "Vaii",
        date = "2007-07-02",
        name = "Vai",
        numeric3 = "470",
        pva = "Vai"
    },
    {
        alpha4 = "Visp",
        date = "2004-05-01",
        name = "Visible Speech",
        numeric3 = "280"
    },
    {
        alpha4 = "Wara",
        date = "2014-11-15",
        name = "Warang Citi (Varang Kshiti)",
        numeric3 = "262",
        pva = "Warang_Citi"
    },
    {
        alpha4 = "Wcho",
        date = "2017-07-26",
        name = "Wancho",
        numeric3 = "283"
    },
    {
        alpha4 = "Wole",
        date = "2010-12-21",
        name = "Woleai",
        numeric3 = "480"
    },
    {
        alpha4 = "Xpeo",
        date = "2006-06-21",
        name = "Old Persian",
        numeric3 = "030",
        pva = "Old_Persian"
    },
    {
        alpha4 = "Xsux",
        date = "2006-10-10",
        name = "Cuneiform, Sumero-Akkadian",
        numeric3 = "020",
        pva = "Cuneiform"
    },
    {
        alpha4 = "Yiii",
        date = "2004-05-01",
        name = "Yi",
        numeric3 = "460",
        pva = "Yi"
    },
    {
        alpha4 = "Zanb",
        date = "2017-07-26",
        name = "Zanabazar Square (Zanabazarin Dörböljin Useg, Xewtee Dörböljin Bicig, Horizontal Square Script)",
        numeric3 = "339",
        pva = "Zanabazar_Square"
    },
    {
        alpha4 = "Zinh",
        date = "2009-02-23",
        name = "Code for inherited script",
        numeric3 = "994",
        pva = "Inherited"
    },
    {
        alpha4 = "Zmth",
        date = "2007-11-26",
        name = "Mathematical notation",
        numeric3 = "995"
    },
    {
        alpha4 = "Zsye",
        date = "2015-12-16",
        name = "Symbols (Emoji variant)",
        numeric3 = "993"
    },
    {
        alpha4 = "Zsym",
        date = "2007-11-26",
        name = "Symbols",
        numeric3 = "996"
    },
    {
        alpha4 = "Zxxx",
        date = "2011-06-21",
        name = "Code for unwritten documents",
        numeric3 = "997"
    },
    {
        alpha4 = "Zyyy",
        date = "2004-05-29",
        name = "Code for undetermined script",
        numeric3 = "998",
        pva = "Common"
    },
    {
        alpha4 = "Zzzz",
        date = "2006-10-10",
        name = "Code for uncoded script",
        numeric3 = "999",
        pva = "Unknown"
    }
}

setmetatable(
    script,
    {
        __index = function(self, key)
            if type(key) == "string" then
                for _, r in ipairs(script) do
                    for _, value in pairs(r) do
                        if value == key then
                            rawset(self, key, r)
                            return r
                        end
                    end
                end
            end
            return nil
        end
    }
)

return script