--- === cp.i18n.language ===
---
--- Provides the set of ISO 693-1/2/3 language codes and names.
--- The return value can be iterated as a list, or you can find a
--- specific language by either its two-character code (`alpha2`), English-based three-character code (`alpha3B`),
--- local name, or English name.
---
--- For example:
---
--- ```lua
--- local lang = require("cp.i18n.language")
--- print(lang[1]) -- table for "Abkhaz" language
--- print(lang.fr) -- table for "French"
--- print(lang.fre) -- same table for "French"
--- print(lang["Français"]) -- same table for "French"
--- print(lang.French) -- same table for "French"
--- ```
---
--- This will return a table containing the following:
--- * `alpha2`       - The 2-character language code (eg. "en", "fr").
--- * `alpha3`       - The 3-character language code (eg. "eng", "fra").
--- * `alpha3B`      - The 3-character English-derived language code (eg. "eng", "fre").
--- * `alpha3T`      - The 3-character local-language-derived code (eg. "eng", "fra").
--- * `localName`   - The name in the local language (eg. "English", "Français").
--- * `name`        - The name in English (eg. "English", "French").
---
--- Note: This data was adapted from [arnubol's code](https://github.com/anurbol/languages-iso-639-1-2-3-json)
--- under an [MIT license](https://raw.githubusercontent.com/anurbol/languages-iso-639-1-2-3-json/master/LICENSE).

-- local log           = require("hs.logger").new("language")

local language = {
    {
        alpha2 = "ab",
        alpha3 = "abk",
        alpha3B = "abk",
        alpha3T = "abk",
        alpha3X = "abk",
        localName = "Аҧсуа",
        name = "Abkhaz"
    },
    {
        alpha2 = "aa",
        alpha3 = "aar",
        alpha3B = "aar",
        alpha3T = "aar",
        alpha3X = "aar",
        localName = "Afaraf",
        name = "Afar"
    },
    {
        alpha2 = "af",
        alpha3 = "afr",
        alpha3B = "afr",
        alpha3T = "afr",
        alpha3X = "afr",
        localName = "Afrikaans",
        name = "Afrikaans"
    },
    {
        alpha2 = "ak",
        alpha3 = "aka",
        alpha3B = "aka",
        alpha3T = "aka",
        alpha3X = "aka",
        localName = "Akan",
        name = "Akan"
    },
    {
        alpha2 = "sq",
        alpha3 = "sqi",
        alpha3B = "alb",
        alpha3T = "sqi",
        alpha3X = "sqi",
        localName = "Shqip",
        name = "Albanian"
    },
    {
        alpha2 = "am",
        alpha3 = "amh",
        alpha3B = "amh",
        alpha3T = "amh",
        alpha3X = "amh",
        localName = "አማርኛ",
        name = "Amharic"
    },
    {
        alpha2 = "ar",
        alpha3 = "ara",
        alpha3B = "ara",
        alpha3T = "ara",
        alpha3X = "ara",
        localName = "العربية",
        name = "Arabic"
    },
    {
        alpha2 = "an",
        alpha3 = "arg",
        alpha3B = "arg",
        alpha3T = "arg",
        alpha3X = "arg",
        localName = "Aragonés",
        name = "Aragonese"
    },
    {
        alpha2 = "hy",
        alpha3 = "hye",
        alpha3B = "arm",
        alpha3T = "hye",
        alpha3X = "hye",
        localName = "Հայերեն",
        name = "Armenian"
    },
    {
        alpha2 = "as",
        alpha3 = "asm",
        alpha3B = "asm",
        alpha3T = "asm",
        alpha3X = "asm",
        localName = "অসমীয়া",
        name = "Assamese"
    },
    {
        alpha2 = "av",
        alpha3 = "ava",
        alpha3B = "ava",
        alpha3T = "ava",
        alpha3X = "ava",
        localName = "Авар",
        name = "Avaric"
    },
    {
        alpha2 = "ae",
        alpha3 = "ave",
        alpha3B = "ave",
        alpha3T = "ave",
        alpha3X = "ave",
        localName = "avesta",
        name = "Avestan"
    },
    {
        alpha2 = "ay",
        alpha3 = "aym",
        alpha3B = "aym",
        alpha3T = "aym",
        alpha3X = "aym",
        localName = "Aymar",
        name = "Aymara"
    },
    {
        alpha2 = "az",
        alpha3 = "aze",
        alpha3B = "aze",
        alpha3T = "aze",
        alpha3X = "aze",
        localName = "Azərbaycanca",
        name = "Azerbaijani"
    },
    {
        alpha2 = "bm",
        alpha3 = "bam",
        alpha3B = "bam",
        alpha3T = "bam",
        alpha3X = "bam",
        localName = "Bamanankan",
        name = "Bambara"
    },
    {
        alpha2 = "ba",
        alpha3 = "bak",
        alpha3B = "bak",
        alpha3T = "bak",
        alpha3X = "bak",
        localName = "Башҡортса",
        name = "Bashkir"
    },
    {
        alpha2 = "eu",
        alpha3 = "eus",
        alpha3B = "baq",
        alpha3T = "eus",
        alpha3X = "eus",
        localName = "Euskara",
        name = "Basque"
    },
    {
        alpha2 = "be",
        alpha3 = "bel",
        alpha3B = "bel",
        alpha3T = "bel",
        alpha3X = "bel",
        localName = "Беларуская",
        name = "Belarusian"
    },
    {
        alpha2 = "bn",
        alpha3 = "ben",
        alpha3B = "ben",
        alpha3T = "ben",
        alpha3X = "ben",
        localName = "বাংলা",
        name = "Bengali"
    },
    {
        alpha2 = "bh",
        alpha3 = "bih",
        alpha3B = "bih",
        alpha3T = "bih",
        alpha3X = "bih",
        localName = "भोजपुरी",
        name = "Bihari"
    },
    {
        alpha2 = "bi",
        alpha3 = "bis",
        alpha3B = "bis",
        alpha3T = "bis",
        alpha3X = "bis",
        localName = "Bislama",
        name = "Bislama"
    },
    {
        alpha2 = "bs",
        alpha3 = "bos",
        alpha3B = "bos",
        alpha3T = "bos",
        alpha3X = "bos",
        localName = "Bosanski",
        name = "Bosnian"
    },
    {
        alpha2 = "br",
        alpha3 = "bre",
        alpha3B = "bre",
        alpha3T = "bre",
        alpha3X = "bre",
        localName = "Brezhoneg",
        name = "Breton"
    },
    {
        alpha2 = "bg",
        alpha3 = "bul",
        alpha3B = "bul",
        alpha3T = "bul",
        alpha3X = "bul",
        localName = "Български",
        name = "Bulgarian"
    },
    {
        alpha2 = "my",
        alpha3 = "mya",
        alpha3B = "bur",
        alpha3T = "mya",
        alpha3X = "mya",
        localName = "မြန်မာဘာသာ",
        name = "Burmese"
    },
    {
        alpha2 = "ca",
        alpha3 = "cat",
        alpha3B = "cat",
        alpha3T = "cat",
        alpha3X = "cat",
        localName = "Català",
        name = "Catalan"
    },
    {
        alpha2 = "ch",
        alpha3 = "cha",
        alpha3B = "cha",
        alpha3T = "cha",
        alpha3X = "cha",
        localName = "Chamoru",
        name = "Chamorro"
    },
    {
        alpha2 = "ce",
        alpha3 = "che",
        alpha3B = "che",
        alpha3T = "che",
        alpha3X = "che",
        localName = "Нохчийн",
        name = "Chechen"
    },
    {
        alpha2 = "ny",
        alpha3 = "nya",
        alpha3B = "nya",
        alpha3T = "nya",
        alpha3X = "nya",
        localName = "Chichewa",
        name = "Chichewa"
    },
    {
        alpha2 = "zh",
        alpha3 = "zho",
        alpha3B = "chi",
        alpha3T = "zho",
        alpha3X = "zho",
        localName = "中文",
        name = "Chinese"
    },
    {
        alpha2 = "cv",
        alpha3 = "chv",
        alpha3B = "chv",
        alpha3T = "chv",
        alpha3X = "chv",
        localName = "Чӑвашла",
        name = "Chuvash"
    },
    {
        alpha2 = "kw",
        alpha3 = "cor",
        alpha3B = "cor",
        alpha3T = "cor",
        alpha3X = "cor",
        localName = "Kernewek",
        name = "Cornish"
    },
    {
        alpha2 = "co",
        alpha3 = "cos",
        alpha3B = "cos",
        alpha3T = "cos",
        alpha3X = "cos",
        localName = "Corsu",
        name = "Corsican"
    },
    {
        alpha2 = "cr",
        alpha3 = "cre",
        alpha3B = "cre",
        alpha3T = "cre",
        alpha3X = "cre",
        localName = "ᓀᐦᐃᔭᐍᐏᐣ",
        name = "Cree"
    },
    {
        alpha2 = "hr",
        alpha3 = "hrv",
        alpha3B = "hrv",
        alpha3T = "hrv",
        alpha3X = "hrv",
        localName = "Hrvatski",
        name = "Croatian"
    },
    {
        alpha2 = "cs",
        alpha3 = "ces",
        alpha3B = "cze",
        alpha3T = "ces",
        alpha3X = "ces",
        localName = "Čeština",
        name = "Czech"
    },
    {
        alpha2 = "da",
        alpha3 = "dan",
        alpha3B = "dan",
        alpha3T = "dan",
        alpha3X = "dan",
        localName = "Dansk",
        name = "Danish"
    },
    {
        alpha2 = "dv",
        alpha3 = "div",
        alpha3B = "div",
        alpha3T = "div",
        alpha3X = "div",
        localName = "Divehi",
        name = "Divehi"
    },
    {
        alpha2 = "nl",
        alpha3 = "nld",
        alpha3B = "dut",
        alpha3T = "nld",
        alpha3X = "nld",
        localName = "Nederlands",
        name = "Dutch"
    },
    {
        alpha2 = "dz",
        alpha3 = "dzo",
        alpha3B = "dzo",
        alpha3T = "dzo",
        alpha3X = "dzo",
        localName = "རྫོང་ཁ",
        name = "Dzongkha"
    },
    {
        alpha2 = "en",
        alpha3 = "eng",
        alpha3B = "eng",
        alpha3T = "eng",
        alpha3X = "eng",
        localName = "English",
        name = "English"
    },
    {
        alpha2 = "eo",
        alpha3 = "epo",
        alpha3B = "epo",
        alpha3T = "epo",
        alpha3X = "epo",
        localName = "Esperanto",
        name = "Esperanto"
    },
    {
        alpha2 = "et",
        alpha3 = "est",
        alpha3B = "est",
        alpha3T = "est",
        alpha3X = "est",
        localName = "Eesti",
        name = "Estonian"
    },
    {
        alpha2 = "ee",
        alpha3 = "ewe",
        alpha3B = "ewe",
        alpha3T = "ewe",
        alpha3X = "ewe",
        localName = "Eʋegbe",
        name = "Ewe"
    },
    {
        alpha2 = "fo",
        alpha3 = "fao",
        alpha3B = "fao",
        alpha3T = "fao",
        alpha3X = "fao",
        localName = "Føroyskt",
        name = "Faroese"
    },
    {
        alpha2 = "fj",
        alpha3 = "fij",
        alpha3B = "fij",
        alpha3T = "fij",
        alpha3X = "fij",
        localName = "Na Vosa Vaka-Viti",
        name = "Fijian"
    },
    {
        alpha2 = "fi",
        alpha3 = "fin",
        alpha3B = "fin",
        alpha3T = "fin",
        alpha3X = "fin",
        localName = "Suomi",
        name = "Finnish"
    },
    {
        alpha2 = "fr",
        alpha3 = "fra",
        alpha3B = "fre",
        alpha3T = "fra",
        alpha3X = "fra",
        localName = "Français",
        name = "French"
    },
    {
        alpha2 = "ff",
        alpha3 = "ful",
        alpha3B = "ful",
        alpha3T = "ful",
        alpha3X = "ful",
        localName = "Fulfulde",
        name = "Fula"
    },
    {
        alpha2 = "gl",
        alpha3 = "glg",
        alpha3B = "glg",
        alpha3T = "glg",
        alpha3X = "glg",
        localName = "Galego",
        name = "Galician"
    },
    {
        alpha2 = "ka",
        alpha3 = "kat",
        alpha3B = "geo",
        alpha3T = "kat",
        alpha3X = "kat",
        localName = "ქართული",
        name = "Georgian"
    },
    {
        alpha2 = "de",
        alpha3 = "deu",
        alpha3B = "ger",
        alpha3T = "deu",
        alpha3X = "deu",
        localName = "Deutsch",
        name = "German"
    },
    {
        alpha2 = "el",
        alpha3 = "ell",
        alpha3B = "gre",
        alpha3T = "ell",
        alpha3X = "ell",
        localName = "Ελληνικά",
        name = "Greek"
    },
    {
        alpha2 = "gn",
        alpha3 = "grn",
        alpha3B = "grn",
        alpha3T = "grn",
        alpha3X = "grn",
        localName = "Avañe'ẽ",
        name = "Guaraní"
    },
    {
        alpha2 = "gu",
        alpha3 = "guj",
        alpha3B = "guj",
        alpha3T = "guj",
        alpha3X = "guj",
        localName = "ગુજરાતી",
        name = "Gujarati"
    },
    {
        alpha2 = "ht",
        alpha3 = "hat",
        alpha3B = "hat",
        alpha3T = "hat",
        alpha3X = "hat",
        localName = "Kreyòl Ayisyen",
        name = "Haitian"
    },
    {
        alpha2 = "ha",
        alpha3 = "hau",
        alpha3B = "hau",
        alpha3T = "hau",
        alpha3X = "hau",
        localName = "هَوُسَ",
        name = "Hausa"
    },
    {
        alpha2 = "he",
        alpha3 = "heb",
        alpha3B = "heb",
        alpha3T = "heb",
        alpha3X = "heb",
        localName = "עברית",
        name = "Hebrew"
    },
    {
        alpha2 = "hz",
        alpha3 = "her",
        alpha3B = "her",
        alpha3T = "her",
        alpha3X = "her",
        localName = "Otjiherero",
        name = "Herero"
    },
    {
        alpha2 = "hi",
        alpha3 = "hin",
        alpha3B = "hin",
        alpha3T = "hin",
        alpha3X = "hin",
        localName = "हिन्दी",
        name = "Hindi"
    },
    {
        alpha2 = "ho",
        alpha3 = "hmo",
        alpha3B = "hmo",
        alpha3T = "hmo",
        alpha3X = "hmo",
        localName = "Hiri Motu",
        name = "Hiri Motu"
    },
    {
        alpha2 = "hu",
        alpha3 = "hun",
        alpha3B = "hun",
        alpha3T = "hun",
        alpha3X = "hun",
        localName = "Magyar",
        name = "Hungarian"
    },
    {
        alpha2 = "ia",
        alpha3 = "ina",
        alpha3B = "ina",
        alpha3T = "ina",
        alpha3X = "ina",
        localName = "Interlingua",
        name = "Interlingua"
    },
    {
        alpha2 = "id",
        alpha3 = "ind",
        alpha3B = "ind",
        alpha3T = "ind",
        alpha3X = "ind",
        localName = "Bahasa Indonesia",
        name = "Indonesian"
    },
    {
        alpha2 = "ie",
        alpha3 = "ile",
        alpha3B = "ile",
        alpha3T = "ile",
        alpha3X = "ile",
        localName = "Interlingue",
        name = "Interlingue"
    },
    {
        alpha2 = "ga",
        alpha3 = "gle",
        alpha3B = "gle",
        alpha3T = "gle",
        alpha3X = "gle",
        localName = "Gaeilge",
        name = "Irish"
    },
    {
        alpha2 = "ig",
        alpha3 = "ibo",
        alpha3B = "ibo",
        alpha3T = "ibo",
        alpha3X = "ibo",
        localName = "Igbo",
        name = "Igbo"
    },
    {
        alpha2 = "ik",
        alpha3 = "ipk",
        alpha3B = "ipk",
        alpha3T = "ipk",
        alpha3X = "ipk",
        localName = "Iñupiak",
        name = "Inupiaq"
    },
    {
        alpha2 = "io",
        alpha3 = "ido",
        alpha3B = "ido",
        alpha3T = "ido",
        alpha3X = "ido",
        localName = "Ido",
        name = "Ido"
    },
    {
        alpha2 = "is",
        alpha3 = "isl",
        alpha3B = "ice",
        alpha3T = "isl",
        alpha3X = "isl",
        localName = "Íslenska",
        name = "Icelandic"
    },
    {
        alpha2 = "it",
        alpha3 = "ita",
        alpha3B = "ita",
        alpha3T = "ita",
        alpha3X = "ita",
        localName = "Italiano",
        name = "Italian"
    },
    {
        alpha2 = "iu",
        alpha3 = "iku",
        alpha3B = "iku",
        alpha3T = "iku",
        alpha3X = "iku",
        localName = "ᐃᓄᒃᑎᑐᑦ",
        name = "Inuktitut"
    },
    {
        alpha2 = "ja",
        alpha3 = "jpn",
        alpha3B = "jpn",
        alpha3T = "jpn",
        alpha3X = "jpn",
        localName = "日本語",
        name = "Japanese"
    },
    {
        alpha2 = "jv",
        alpha3 = "jav",
        alpha3B = "jav",
        alpha3T = "jav",
        alpha3X = "jav",
        localName = "Basa Jawa",
        name = "Javanese"
    },
    {
        alpha2 = "kl",
        alpha3 = "kal",
        alpha3B = "kal",
        alpha3T = "kal",
        alpha3X = "kal",
        localName = "Kalaallisut",
        name = "Kalaallisut"
    },
    {
        alpha2 = "kn",
        alpha3 = "kan",
        alpha3B = "kan",
        alpha3T = "kan",
        alpha3X = "kan",
        localName = "ಕನ್ನಡ",
        name = "Kannada"
    },
    {
        alpha2 = "kr",
        alpha3 = "kau",
        alpha3B = "kau",
        alpha3T = "kau",
        alpha3X = "kau",
        localName = "Kanuri",
        name = "Kanuri"
    },
    {
        alpha2 = "ks",
        alpha3 = "kas",
        alpha3B = "kas",
        alpha3T = "kas",
        alpha3X = "kas",
        localName = "كشميري",
        name = "Kashmiri"
    },
    {
        alpha2 = "kk",
        alpha3 = "kaz",
        alpha3B = "kaz",
        alpha3T = "kaz",
        alpha3X = "kaz",
        localName = "Қазақша",
        name = "Kazakh"
    },
    {
        alpha2 = "km",
        alpha3 = "khm",
        alpha3B = "khm",
        alpha3T = "khm",
        alpha3X = "khm",
        localName = "ភាសាខ្មែរ",
        name = "Khmer"
    },
    {
        alpha2 = "ki",
        alpha3 = "kik",
        alpha3B = "kik",
        alpha3T = "kik",
        alpha3X = "kik",
        localName = "Gĩkũyũ",
        name = "Kikuyu"
    },
    {
        alpha2 = "rw",
        alpha3 = "kin",
        alpha3B = "kin",
        alpha3T = "kin",
        alpha3X = "kin",
        localName = "Kinyarwanda",
        name = "Kinyarwanda"
    },
    {
        alpha2 = "ky",
        alpha3 = "kir",
        alpha3B = "kir",
        alpha3T = "kir",
        alpha3X = "kir",
        localName = "Кыргызча",
        name = "Kyrgyz"
    },
    {
        alpha2 = "kv",
        alpha3 = "kom",
        alpha3B = "kom",
        alpha3T = "kom",
        alpha3X = "kom",
        localName = "Коми",
        name = "Komi"
    },
    {
        alpha2 = "kg",
        alpha3 = "kon",
        alpha3B = "kon",
        alpha3T = "kon",
        alpha3X = "kon",
        localName = "Kongo",
        name = "Kongo"
    },
    {
        alpha2 = "ko",
        alpha3 = "kor",
        alpha3B = "kor",
        alpha3T = "kor",
        alpha3X = "kor",
        localName = "한국어",
        name = "Korean"
    },
    {
        alpha2 = "ku",
        alpha3 = "kur",
        alpha3B = "kur",
        alpha3T = "kur",
        alpha3X = "kur",
        localName = "Kurdî",
        name = "Kurdish"
    },
    {
        alpha2 = "kj",
        alpha3 = "kua",
        alpha3B = "kua",
        alpha3T = "kua",
        alpha3X = "kua",
        localName = "Kuanyama",
        name = "Kwanyama"
    },
    {
        alpha2 = "la",
        alpha3 = "lat",
        alpha3B = "lat",
        alpha3T = "lat",
        alpha3X = "lat",
        localName = "Latina",
        name = "Latin"
    },
    {
        alpha2 = "lb",
        alpha3 = "ltz",
        alpha3B = "ltz",
        alpha3T = "ltz",
        alpha3X = "ltz",
        localName = "Lëtzebuergesch",
        name = "Luxembourgish"
    },
    {
        alpha2 = "lg",
        alpha3 = "lug",
        alpha3B = "lug",
        alpha3T = "lug",
        alpha3X = "lug",
        localName = "Luganda",
        name = "Ganda"
    },
    {
        alpha2 = "li",
        alpha3 = "lim",
        alpha3B = "lim",
        alpha3T = "lim",
        alpha3X = "lim",
        localName = "Limburgs",
        name = "Limburgish"
    },
    {
        alpha2 = "ln",
        alpha3 = "lin",
        alpha3B = "lin",
        alpha3T = "lin",
        alpha3X = "lin",
        localName = "Lingála",
        name = "Lingala"
    },
    {
        alpha2 = "lo",
        alpha3 = "lao",
        alpha3B = "lao",
        alpha3T = "lao",
        alpha3X = "lao",
        localName = "ພາສາລາວ",
        name = "Lao"
    },
    {
        alpha2 = "lt",
        alpha3 = "lit",
        alpha3B = "lit",
        alpha3T = "lit",
        alpha3X = "lit",
        localName = "Lietuvių",
        name = "Lithuanian"
    },
    {
        alpha2 = "lu",
        alpha3 = "lub",
        alpha3B = "lub",
        alpha3T = "lub",
        alpha3X = "lub",
        localName = "Tshiluba",
        name = "Luba-Katanga"
    },
    {
        alpha2 = "lv",
        alpha3 = "lav",
        alpha3B = "lav",
        alpha3T = "lav",
        alpha3X = "lav",
        localName = "Latviešu",
        name = "Latvian"
    },
    {
        alpha2 = "gv",
        alpha3 = "glv",
        alpha3B = "glv",
        alpha3T = "glv",
        alpha3X = "glv",
        localName = "Gaelg",
        name = "Manx"
    },
    {
        alpha2 = "mk",
        alpha3 = "mkd",
        alpha3B = "mac",
        alpha3T = "mkd",
        alpha3X = "mkd",
        localName = "Македонски",
        name = "Macedonian"
    },
    {
        alpha2 = "mg",
        alpha3 = "mlg",
        alpha3B = "mlg",
        alpha3T = "mlg",
        alpha3X = "mlg",
        localName = "Malagasy",
        name = "Malagasy"
    },
    {
        alpha2 = "ms",
        alpha3 = "msa",
        alpha3B = "may",
        alpha3T = "msa",
        alpha3X = "msa",
        localName = "Bahasa Melayu",
        name = "Malay"
    },
    {
        alpha2 = "ml",
        alpha3 = "mal",
        alpha3B = "mal",
        alpha3T = "mal",
        alpha3X = "mal",
        localName = "മലയാളം",
        name = "Malayalam"
    },
    {
        alpha2 = "mt",
        alpha3 = "mlt",
        alpha3B = "mlt",
        alpha3T = "mlt",
        alpha3X = "mlt",
        localName = "Malti",
        name = "Maltese"
    },
    {
        alpha2 = "mi",
        alpha3 = "mri",
        alpha3B = "mao",
        alpha3T = "mri",
        alpha3X = "mri",
        localName = "Māori",
        name = "Māori"
    },
    {
        alpha2 = "mr",
        alpha3 = "mar",
        alpha3B = "mar",
        alpha3T = "mar",
        alpha3X = "mar",
        localName = "मराठी",
        name = "Marathi"
    },
    {
        alpha2 = "mh",
        alpha3 = "mah",
        alpha3B = "mah",
        alpha3T = "mah",
        alpha3X = "mah",
        localName = "Kajin M̧ajeļ",
        name = "Marshallese"
    },
    {
        alpha2 = "mn",
        alpha3 = "mon",
        alpha3B = "mon",
        alpha3T = "mon",
        alpha3X = "mon",
        localName = "Монгол",
        name = "Mongolian"
    },
    {
        alpha2 = "na",
        alpha3 = "nau",
        alpha3B = "nau",
        alpha3T = "nau",
        alpha3X = "nau",
        localName = "Dorerin Naoero",
        name = "Nauru"
    },
    {
        alpha2 = "nv",
        alpha3 = "nav",
        alpha3B = "nav",
        alpha3T = "nav",
        alpha3X = "nav",
        localName = "Diné Bizaad",
        name = "Navajo"
    },
    {
        alpha2 = "nd",
        alpha3 = "nde",
        alpha3B = "nde",
        alpha3T = "nde",
        alpha3X = "nde",
        localName = "isiNdebele",
        name = "Northern Ndebele"
    },
    {
        alpha2 = "ne",
        alpha3 = "nep",
        alpha3B = "nep",
        alpha3T = "nep",
        alpha3X = "nep",
        localName = "नेपाली",
        name = "Nepali"
    },
    {
        alpha2 = "ng",
        alpha3 = "ndo",
        alpha3B = "ndo",
        alpha3T = "ndo",
        alpha3X = "ndo",
        localName = "Owambo",
        name = "Ndonga"
    },
    {
        alpha2 = "nb",
        alpha3 = "nob",
        alpha3B = "nob",
        alpha3T = "nob",
        alpha3X = "nob",
        localName = "Norsk (Bokmål)",
        name = "Norwegian Bokmål"
    },
    {
        alpha2 = "nn",
        alpha3 = "nno",
        alpha3B = "nno",
        alpha3T = "nno",
        alpha3X = "nno",
        localName = "Norsk (Nynorsk)",
        name = "Norwegian Nynorsk"
    },
    {
        alpha2 = "no",
        alpha3 = "nor",
        alpha3B = "nor",
        alpha3T = "nor",
        alpha3X = "nor",
        localName = "Norsk",
        name = "Norwegian"
    },
    {
        alpha2 = "ii",
        alpha3 = "iii",
        alpha3B = "iii",
        alpha3T = "iii",
        alpha3X = "iii",
        localName = "ꆈꌠ꒿ Nuosuhxop",
        name = "Nuosu"
    },
    {
        alpha2 = "nr",
        alpha3 = "nbl",
        alpha3B = "nbl",
        alpha3T = "nbl",
        alpha3X = "nbl",
        localName = "isiNdebele",
        name = "Southern Ndebele"
    },
    {
        alpha2 = "oc",
        alpha3 = "oci",
        alpha3B = "oci",
        alpha3T = "oci",
        alpha3X = "oci",
        localName = "Occitan",
        name = "Occitan"
    },
    {
        alpha2 = "oj",
        alpha3 = "oji",
        alpha3B = "oji",
        alpha3T = "oji",
        alpha3X = "oji",
        localName = "ᐊᓂᔑᓈᐯᒧᐎᓐ",
        name = "Ojibwe"
    },
    {
        alpha2 = "cu",
        alpha3 = "chu",
        alpha3B = "chu",
        alpha3T = "chu",
        alpha3X = "chu",
        localName = "Словѣ́ньскъ",
        name = "Old Church Slavonic"
    },
    {
        alpha2 = "om",
        alpha3 = "orm",
        alpha3B = "orm",
        alpha3T = "orm",
        alpha3X = "orm",
        localName = "Afaan Oromoo",
        name = "Oromo"
    },
    {
        alpha2 = "or",
        alpha3 = "ori",
        alpha3B = "ori",
        alpha3T = "ori",
        alpha3X = "ori",
        localName = "ଓଡି଼ଆ",
        name = "Oriya"
    },
    {
        alpha2 = "os",
        alpha3 = "oss",
        alpha3B = "oss",
        alpha3T = "oss",
        alpha3X = "oss",
        localName = "Ирон æвзаг",
        name = "Ossetian"
    },
    {
        alpha2 = "pa",
        alpha3 = "pan",
        alpha3B = "pan",
        alpha3T = "pan",
        alpha3X = "pan",
        localName = "ਪੰਜਾਬੀ",
        name = "Panjabi"
    },
    {
        alpha2 = "pi",
        alpha3 = "pli",
        alpha3B = "pli",
        alpha3T = "pli",
        alpha3X = "pli",
        localName = "पाऴि",
        name = "Pāli"
    },
    {
        alpha2 = "fa",
        alpha3 = "fas",
        alpha3B = "per",
        alpha3T = "fas",
        alpha3X = "fas",
        localName = "فارسی",
        name = "Persian"
    },
    {
        alpha2 = "pl",
        alpha3 = "pol",
        alpha3B = "pol",
        alpha3T = "pol",
        alpha3X = "pol",
        localName = "Polski",
        name = "Polish"
    },
    {
        alpha2 = "ps",
        alpha3 = "pus",
        alpha3B = "pus",
        alpha3T = "pus",
        alpha3X = "pus",
        localName = "پښتو",
        name = "Pashto"
    },
    {
        alpha2 = "pt",
        alpha3 = "por",
        alpha3B = "por",
        alpha3T = "por",
        alpha3X = "por",
        localName = "Português",
        name = "Portuguese"
    },
    {
        alpha2 = "qu",
        alpha3 = "que",
        alpha3B = "que",
        alpha3T = "que",
        alpha3X = "que",
        localName = "Runa Simi",
        name = "Quechua"
    },
    {
        alpha2 = "rm",
        alpha3 = "roh",
        alpha3B = "roh",
        alpha3T = "roh",
        alpha3X = "roh",
        localName = "Rumantsch",
        name = "Romansh"
    },
    {
        alpha2 = "rn",
        alpha3 = "run",
        alpha3B = "run",
        alpha3T = "run",
        alpha3X = "run",
        localName = "Kirundi",
        name = "Kirundi"
    },
    {
        alpha2 = "ro",
        alpha3 = "ron",
        alpha3B = "rum",
        alpha3T = "ron",
        alpha3X = "ron",
        localName = "Română",
        name = "Romanian"
    },
    {
        alpha2 = "ru",
        alpha3 = "rus",
        alpha3B = "rus",
        alpha3T = "rus",
        alpha3X = "rus",
        localName = "Русский",
        name = "Russian"
    },
    {
        alpha2 = "sa",
        alpha3 = "san",
        alpha3B = "san",
        alpha3T = "san",
        alpha3X = "san",
        localName = "संस्कृतम्",
        name = "Sanskrit"
    },
    {
        alpha2 = "sc",
        alpha3 = "srd",
        alpha3B = "srd",
        alpha3T = "srd",
        alpha3X = "srd",
        localName = "Sardu",
        name = "Sardinian"
    },
    {
        alpha2 = "sd",
        alpha3 = "snd",
        alpha3B = "snd",
        alpha3T = "snd",
        alpha3X = "snd",
        localName = "سنڌي‎",
        name = "Sindhi"
    },
    {
        alpha2 = "se",
        alpha3 = "sme",
        alpha3B = "sme",
        alpha3T = "sme",
        alpha3X = "sme",
        localName = "Sámegiella",
        name = "Northern Sami"
    },
    {
        alpha2 = "sm",
        alpha3 = "smo",
        alpha3B = "smo",
        alpha3T = "smo",
        alpha3X = "smo",
        localName = "Gagana Sāmoa",
        name = "Samoan"
    },
    {
        alpha2 = "sg",
        alpha3 = "sag",
        alpha3B = "sag",
        alpha3T = "sag",
        alpha3X = "sag",
        localName = "Sängö",
        name = "Sango"
    },
    {
        alpha2 = "sr",
        alpha3 = "srp",
        alpha3B = "srp",
        alpha3T = "srp",
        alpha3X = "srp",
        localName = "Српски",
        name = "Serbian"
    },
    {
        alpha2 = "gd",
        alpha3 = "gla",
        alpha3B = "gla",
        alpha3T = "gla",
        alpha3X = "gla",
        localName = "Gàidhlig",
        name = "Gaelic"
    },
    {
        alpha2 = "sn",
        alpha3 = "sna",
        alpha3B = "sna",
        alpha3T = "sna",
        alpha3X = "sna",
        localName = "ChiShona",
        name = "Shona"
    },
    {
        alpha2 = "si",
        alpha3 = "sin",
        alpha3B = "sin",
        alpha3T = "sin",
        alpha3X = "sin",
        localName = "සිංහල",
        name = "Sinhala"
    },
    {
        alpha2 = "sk",
        alpha3 = "slk",
        alpha3B = "slo",
        alpha3T = "slk",
        alpha3X = "slk",
        localName = "Slovenčina",
        name = "Slovak"
    },
    {
        alpha2 = "sl",
        alpha3 = "slv",
        alpha3B = "slv",
        alpha3T = "slv",
        alpha3X = "slv",
        localName = "Slovenščina",
        name = "Slovene"
    },
    {
        alpha2 = "so",
        alpha3 = "som",
        alpha3B = "som",
        alpha3T = "som",
        alpha3X = "som",
        localName = "Soomaaliga",
        name = "Somali"
    },
    {
        alpha2 = "st",
        alpha3 = "sot",
        alpha3B = "sot",
        alpha3T = "sot",
        alpha3X = "sot",
        localName = "Sesotho",
        name = "Southern Sotho"
    },
    {
        alpha2 = "es",
        alpha3 = "spa",
        alpha3B = "spa",
        alpha3T = "spa",
        alpha3X = "spa",
        localName = "Español",
        name = "Spanish"
    },
    {
        alpha2 = "su",
        alpha3 = "sun",
        alpha3B = "sun",
        alpha3T = "sun",
        alpha3X = "sun",
        localName = "Basa Sunda",
        name = "Sundanese"
    },
    {
        alpha2 = "sw",
        alpha3 = "swa",
        alpha3B = "swa",
        alpha3T = "swa",
        alpha3X = "swa",
        localName = "Kiswahili",
        name = "Swahili"
    },
    {
        alpha2 = "ss",
        alpha3 = "ssw",
        alpha3B = "ssw",
        alpha3T = "ssw",
        alpha3X = "ssw",
        localName = "SiSwati",
        name = "Swati"
    },
    {
        alpha2 = "sv",
        alpha3 = "swe",
        alpha3B = "swe",
        alpha3T = "swe",
        alpha3X = "swe",
        localName = "Svenska",
        name = "Swedish"
    },
    {
        alpha2 = "ta",
        alpha3 = "tam",
        alpha3B = "tam",
        alpha3T = "tam",
        alpha3X = "tam",
        localName = "தமிழ்",
        name = "Tamil"
    },
    {
        alpha2 = "te",
        alpha3 = "tel",
        alpha3B = "tel",
        alpha3T = "tel",
        alpha3X = "tel",
        localName = "తెలుగు",
        name = "Telugu"
    },
    {
        alpha2 = "tg",
        alpha3 = "tgk",
        alpha3B = "tgk",
        alpha3T = "tgk",
        alpha3X = "tgk",
        localName = "Тоҷикӣ",
        name = "Tajik"
    },
    {
        alpha2 = "th",
        alpha3 = "tha",
        alpha3B = "tha",
        alpha3T = "tha",
        alpha3X = "tha",
        localName = "ภาษาไทย",
        name = "Thai"
    },
    {
        alpha2 = "ti",
        alpha3 = "tir",
        alpha3B = "tir",
        alpha3T = "tir",
        alpha3X = "tir",
        localName = "ትግርኛ",
        name = "Tigrinya"
    },
    {
        alpha2 = "bo",
        alpha3 = "bod",
        alpha3B = "tib",
        alpha3T = "bod",
        alpha3X = "bod",
        localName = "བོད་ཡིག",
        name = "Tibetan Standard"
    },
    {
        alpha2 = "tk",
        alpha3 = "tuk",
        alpha3B = "tuk",
        alpha3T = "tuk",
        alpha3X = "tuk",
        localName = "Türkmençe",
        name = "Turkmen"
    },
    {
        alpha2 = "tl",
        alpha3 = "tgl",
        alpha3B = "tgl",
        alpha3T = "tgl",
        alpha3X = "tgl",
        localName = "Tagalog",
        name = "Tagalog"
    },
    {
        alpha2 = "tn",
        alpha3 = "tsn",
        alpha3B = "tsn",
        alpha3T = "tsn",
        alpha3X = "tsn",
        localName = "Setswana",
        name = "Tswana"
    },
    {
        alpha2 = "to",
        alpha3 = "ton",
        alpha3B = "ton",
        alpha3T = "ton",
        alpha3X = "ton",
        localName = "faka Tonga",
        name = "Tonga"
    },
    {
        alpha2 = "tr",
        alpha3 = "tur",
        alpha3B = "tur",
        alpha3T = "tur",
        alpha3X = "tur",
        localName = "Türkçe",
        name = "Turkish"
    },
    {
        alpha2 = "ts",
        alpha3 = "tso",
        alpha3B = "tso",
        alpha3T = "tso",
        alpha3X = "tso",
        localName = "Xitsonga",
        name = "Tsonga"
    },
    {
        alpha2 = "tt",
        alpha3 = "tat",
        alpha3B = "tat",
        alpha3T = "tat",
        alpha3X = "tat",
        localName = "Татарча",
        name = "Tatar"
    },
    {
        alpha2 = "tw",
        alpha3 = "twi",
        alpha3B = "twi",
        alpha3T = "twi",
        alpha3X = "twi",
        localName = "Twi",
        name = "Twi"
    },
    {
        alpha2 = "ty",
        alpha3 = "tah",
        alpha3B = "tah",
        alpha3T = "tah",
        alpha3X = "tah",
        localName = "Reo Mā’ohi",
        name = "Tahitian"
    },
    {
        alpha2 = "ug",
        alpha3 = "uig",
        alpha3B = "uig",
        alpha3T = "uig",
        alpha3X = "uig",
        localName = "ئۇيغۇرچه",
        name = "Uyghur"
    },
    {
        alpha2 = "uk",
        alpha3 = "ukr",
        alpha3B = "ukr",
        alpha3T = "ukr",
        alpha3X = "ukr",
        localName = "Українська",
        name = "Ukrainian"
    },
    {
        alpha2 = "ur",
        alpha3 = "urd",
        alpha3B = "urd",
        alpha3T = "urd",
        alpha3X = "urd",
        localName = "اردو",
        name = "Urdu"
    },
    {
        alpha2 = "uz",
        alpha3 = "uzb",
        alpha3B = "uzb",
        alpha3T = "uzb",
        alpha3X = "uzb",
        localName = "O‘zbek",
        name = "Uzbek"
    },
    {
        alpha2 = "ve",
        alpha3 = "ven",
        alpha3B = "ven",
        alpha3T = "ven",
        alpha3X = "ven",
        localName = "Tshivenḓa",
        name = "Venda"
    },
    {
        alpha2 = "vi",
        alpha3 = "vie",
        alpha3B = "vie",
        alpha3T = "vie",
        alpha3X = "vie",
        localName = "Tiếng Việt",
        name = "Vietnamese"
    },
    {
        alpha2 = "vo",
        alpha3 = "vol",
        alpha3B = "vol",
        alpha3T = "vol",
        alpha3X = "vol",
        localName = "Volapük",
        name = "Volapük"
    },
    {
        alpha2 = "wa",
        alpha3 = "wln",
        alpha3B = "wln",
        alpha3T = "wln",
        alpha3X = "wln",
        localName = "Walon",
        name = "Walloon"
    },
    {
        alpha2 = "cy",
        alpha3 = "cym",
        alpha3B = "wel",
        alpha3T = "cym",
        alpha3X = "cym",
        localName = "Cymraeg",
        name = "Welsh"
    },
    {
        alpha2 = "wo",
        alpha3 = "wol",
        alpha3B = "wol",
        alpha3T = "wol",
        alpha3X = "wol",
        localName = "Wolof",
        name = "Wolof"
    },
    {
        alpha2 = "fy",
        alpha3 = "fry",
        alpha3B = "fry",
        alpha3T = "fry",
        alpha3X = "fry",
        localName = "Frysk",
        name = "Western Frisian"
    },
    {
        alpha2 = "xh",
        alpha3 = "xho",
        alpha3B = "xho",
        alpha3T = "xho",
        alpha3X = "xho",
        localName = "isiXhosa",
        name = "Xhosa"
    },
    {
        alpha2 = "yi",
        alpha3 = "yid",
        alpha3B = "yid",
        alpha3T = "yid",
        alpha3X = "yid",
        localName = "ייִדיש",
        name = "Yiddish"
    },
    {
        alpha2 = "yo",
        alpha3 = "yor",
        alpha3B = "yor",
        alpha3T = "yor",
        alpha3X = "yor",
        localName = "Yorùbá",
        name = "Yoruba"
    },
    {
        alpha2 = "za",
        alpha3 = "zha",
        alpha3B = "zha",
        alpha3T = "zha",
        alpha3X = "zha",
        localName = "Cuengh",
        name = "Zhuang"
    },
    {
        alpha2 = "zu",
        alpha3 = "zul",
        alpha3B = "zul",
        alpha3T = "zul",
        alpha3X = "zul",
        localName = "isiZulu",
        name = "Zulu"
    }
}

local SEARCH_KEYS = {"alpha2", "alpha3B", "localName", "name"}

setmetatable(
    language,
    {
        __index = function(self, key)
            if type(key) == "string" then
                for _, lang in ipairs(language) do
                    for _, prop in ipairs(SEARCH_KEYS) do
                        if lang[prop] == key then
                            rawset(self, key, lang)
                            return lang
                        end
                    end
                end
            end
            return nil
        end
    }
)

return language
