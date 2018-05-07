--- === cp.i18n.region ===
---
--- Provides the set of ISO 3166-1 region codes and names.
--- The return value can be iterated as a list, or you can find a
--- specific region by either its upper-case two-character code (`alpha2`), three-character numeric code (`numeric3`),
--- or English name (`name`).
---
--- For example:
---
--- ```lua
--- local region = require("cp.i18n.region")
--- print(region[1])    -- table for "Afghanistan"
--- print(lang.FR)      -- table for "France"
--- print(lang.France)  -- same table for "France"
--- ```
---
--- This will return a table containing the following:
--- * `alpha2`      - The 2-character region code, upper-case (eg. "AU", "FR").
--- * `name`        - The name in English (eg. "Australia", "France").
---
--- Note: This data was adapted from the [datahub.io list](https://datahub.io/core/country-list)
--- released under a Public Domain license.

-- local log           = require("hs.logger").new("region")

local region = {
    {
        alpha2 = "AF",
        name = "Afghanistan"
    },
    {
        alpha2 = "AX",
        name = "Åland Islands"
    },
    {
        alpha2 = "AL",
        name = "Albania"
    },
    {
        alpha2 = "DZ",
        name = "Algeria"
    },
    {
        alpha2 = "AS",
        name = "American Samoa"
    },
    {
        alpha2 = "AD",
        name = "Andorra"
    },
    {
        alpha2 = "AO",
        name = "Angola"
    },
    {
        alpha2 = "AI",
        name = "Anguilla"
    },
    {
        alpha2 = "AQ",
        name = "Antarctica"
    },
    {
        alpha2 = "AG",
        name = "Antigua and Barbuda"
    },
    {
        alpha2 = "AR",
        name = "Argentina"
    },
    {
        alpha2 = "AM",
        name = "Armenia"
    },
    {
        alpha2 = "AW",
        name = "Aruba"
    },
    {
        alpha2 = "AU",
        name = "Australia"
    },
    {
        alpha2 = "AT",
        name = "Austria"
    },
    {
        alpha2 = "AZ",
        name = "Azerbaijan"
    },
    {
        alpha2 = "BS",
        name = "Bahamas"
    },
    {
        alpha2 = "BH",
        name = "Bahrain"
    },
    {
        alpha2 = "BD",
        name = "Bangladesh"
    },
    {
        alpha2 = "BB",
        name = "Barbados"
    },
    {
        alpha2 = "BY",
        name = "Belarus"
    },
    {
        alpha2 = "BE",
        name = "Belgium"
    },
    {
        alpha2 = "BZ",
        name = "Belize"
    },
    {
        alpha2 = "BJ",
        name = "Benin"
    },
    {
        alpha2 = "BM",
        name = "Bermuda"
    },
    {
        alpha2 = "BT",
        name = "Bhutan"
    },
    {
        alpha2 = "BO",
        name = "Bolivia, Plurinational State of"
    },
    {
        alpha2 = "BQ",
        name = "Bonaire, Sint Eustatius and Saba"
    },
    {
        alpha2 = "BA",
        name = "Bosnia and Herzegovina"
    },
    {
        alpha2 = "BW",
        name = "Botswana"
    },
    {
        alpha2 = "BV",
        name = "Bouvet Island"
    },
    {
        alpha2 = "BR",
        name = "Brazil"
    },
    {
        alpha2 = "IO",
        name = "British Indian Ocean Territory"
    },
    {
        alpha2 = "BN",
        name = "Brunei Darussalam"
    },
    {
        alpha2 = "BG",
        name = "Bulgaria"
    },
    {
        alpha2 = "BF",
        name = "Burkina Faso"
    },
    {
        alpha2 = "BI",
        name = "Burundi"
    },
    {
        alpha2 = "KH",
        name = "Cambodia"
    },
    {
        alpha2 = "CM",
        name = "Cameroon"
    },
    {
        alpha2 = "CA",
        name = "Canada"
    },
    {
        alpha2 = "CV",
        name = "Cape Verde"
    },
    {
        alpha2 = "KY",
        name = "Cayman Islands"
    },
    {
        alpha2 = "CF",
        name = "Central African Republic"
    },
    {
        alpha2 = "TD",
        name = "Chad"
    },
    {
        alpha2 = "CL",
        name = "Chile"
    },
    {
        alpha2 = "CN",
        name = "China"
    },
    {
        alpha2 = "CX",
        name = "Christmas Island"
    },
    {
        alpha2 = "CC",
        name = "Cocos (Keeling) Islands"
    },
    {
        alpha2 = "CO",
        name = "Colombia"
    },
    {
        alpha2 = "KM",
        name = "Comoros"
    },
    {
        alpha2 = "CG",
        name = "Congo"
    },
    {
        alpha2 = "CD",
        name = "Congo, the Democratic Republic of the"
    },
    {
        alpha2 = "CK",
        name = "Cook Islands"
    },
    {
        alpha2 = "CR",
        name = "Costa Rica"
    },
    {
        alpha2 = "CI",
        name = "Côte d'Ivoire"
    },
    {
        alpha2 = "HR",
        name = "Croatia"
    },
    {
        alpha2 = "CU",
        name = "Cuba"
    },
    {
        alpha2 = "CW",
        name = "Curaçao"
    },
    {
        alpha2 = "CY",
        name = "Cyprus"
    },
    {
        alpha2 = "CZ",
        name = "Czech Republic"
    },
    {
        alpha2 = "DK",
        name = "Denmark"
    },
    {
        alpha2 = "DJ",
        name = "Djibouti"
    },
    {
        alpha2 = "DM",
        name = "Dominica"
    },
    {
        alpha2 = "DO",
        name = "Dominican Republic"
    },
    {
        alpha2 = "EC",
        name = "Ecuador"
    },
    {
        alpha2 = "EG",
        name = "Egypt"
    },
    {
        alpha2 = "SV",
        name = "El Salvador"
    },
    {
        alpha2 = "GQ",
        name = "Equatorial Guinea"
    },
    {
        alpha2 = "ER",
        name = "Eritrea"
    },
    {
        alpha2 = "EE",
        name = "Estonia"
    },
    {
        alpha2 = "ET",
        name = "Ethiopia"
    },
    {
        alpha2 = "FK",
        name = "Falkland Islands (Malvinas)"
    },
    {
        alpha2 = "FO",
        name = "Faroe Islands"
    },
    {
        alpha2 = "FJ",
        name = "Fiji"
    },
    {
        alpha2 = "FI",
        name = "Finland"
    },
    {
        alpha2 = "FR",
        name = "France"
    },
    {
        alpha2 = "GF",
        name = "French Guiana"
    },
    {
        alpha2 = "PF",
        name = "French Polynesia"
    },
    {
        alpha2 = "TF",
        name = "French Southern Territories"
    },
    {
        alpha2 = "GA",
        name = "Gabon"
    },
    {
        alpha2 = "GM",
        name = "Gambia"
    },
    {
        alpha2 = "GE",
        name = "Georgia"
    },
    {
        alpha2 = "DE",
        name = "Germany"
    },
    {
        alpha2 = "GH",
        name = "Ghana"
    },
    {
        alpha2 = "GI",
        name = "Gibraltar"
    },
    {
        alpha2 = "GR",
        name = "Greece"
    },
    {
        alpha2 = "GL",
        name = "Greenland"
    },
    {
        alpha2 = "GD",
        name = "Grenada"
    },
    {
        alpha2 = "GP",
        name = "Guadeloupe"
    },
    {
        alpha2 = "GU",
        name = "Guam"
    },
    {
        alpha2 = "GT",
        name = "Guatemala"
    },
    {
        alpha2 = "GG",
        name = "Guernsey"
    },
    {
        alpha2 = "GN",
        name = "Guinea"
    },
    {
        alpha2 = "GW",
        name = "Guinea-Bissau"
    },
    {
        alpha2 = "GY",
        name = "Guyana"
    },
    {
        alpha2 = "HT",
        name = "Haiti"
    },
    {
        alpha2 = "HM",
        name = "Heard Island and McDonald Islands"
    },
    {
        alpha2 = "VA",
        name = "Holy See (Vatican City State)"
    },
    {
        alpha2 = "HN",
        name = "Honduras"
    },
    {
        alpha2 = "HK",
        name = "Hong Kong"
    },
    {
        alpha2 = "HU",
        name = "Hungary"
    },
    {
        alpha2 = "IS",
        name = "Iceland"
    },
    {
        alpha2 = "IN",
        name = "India"
    },
    {
        alpha2 = "ID",
        name = "Indonesia"
    },
    {
        alpha2 = "IR",
        name = "Iran, Islamic Republic of"
    },
    {
        alpha2 = "IQ",
        name = "Iraq"
    },
    {
        alpha2 = "IE",
        name = "Ireland"
    },
    {
        alpha2 = "IM",
        name = "Isle of Man"
    },
    {
        alpha2 = "IL",
        name = "Israel"
    },
    {
        alpha2 = "IT",
        name = "Italy"
    },
    {
        alpha2 = "JM",
        name = "Jamaica"
    },
    {
        alpha2 = "JP",
        name = "Japan"
    },
    {
        alpha2 = "JE",
        name = "Jersey"
    },
    {
        alpha2 = "JO",
        name = "Jordan"
    },
    {
        alpha2 = "KZ",
        name = "Kazakhstan"
    },
    {
        alpha2 = "KE",
        name = "Kenya"
    },
    {
        alpha2 = "KI",
        name = "Kiribati"
    },
    {
        alpha2 = "KP",
        name = "Korea, Democratic People's Republic of"
    },
    {
        alpha2 = "KR",
        name = "Korea, Republic of"
    },
    {
        alpha2 = "KW",
        name = "Kuwait"
    },
    {
        alpha2 = "KG",
        name = "Kyrgyzstan"
    },
    {
        alpha2 = "LA",
        name = "Lao People's Democratic Republic"
    },
    {
        alpha2 = "LV",
        name = "Latvia"
    },
    {
        alpha2 = "LB",
        name = "Lebanon"
    },
    {
        alpha2 = "LS",
        name = "Lesotho"
    },
    {
        alpha2 = "LR",
        name = "Liberia"
    },
    {
        alpha2 = "LY",
        name = "Libya"
    },
    {
        alpha2 = "LI",
        name = "Liechtenstein"
    },
    {
        alpha2 = "LT",
        name = "Lithuania"
    },
    {
        alpha2 = "LU",
        name = "Luxembourg"
    },
    {
        alpha2 = "MO",
        name = "Macao"
    },
    {
        alpha2 = "MK",
        name = "Macedonia, the Former Yugoslav Republic of"
    },
    {
        alpha2 = "MG",
        name = "Madagascar"
    },
    {
        alpha2 = "MW",
        name = "Malawi"
    },
    {
        alpha2 = "MY",
        name = "Malaysia"
    },
    {
        alpha2 = "MV",
        name = "Maldives"
    },
    {
        alpha2 = "ML",
        name = "Mali"
    },
    {
        alpha2 = "MT",
        name = "Malta"
    },
    {
        alpha2 = "MH",
        name = "Marshall Islands"
    },
    {
        alpha2 = "MQ",
        name = "Martinique"
    },
    {
        alpha2 = "MR",
        name = "Mauritania"
    },
    {
        alpha2 = "MU",
        name = "Mauritius"
    },
    {
        alpha2 = "YT",
        name = "Mayotte"
    },
    {
        alpha2 = "MX",
        name = "Mexico"
    },
    {
        alpha2 = "FM",
        name = "Micronesia, Federated States of"
    },
    {
        alpha2 = "MD",
        name = "Moldova, Republic of"
    },
    {
        alpha2 = "MC",
        name = "Monaco"
    },
    {
        alpha2 = "MN",
        name = "Mongolia"
    },
    {
        alpha2 = "ME",
        name = "Montenegro"
    },
    {
        alpha2 = "MS",
        name = "Montserrat"
    },
    {
        alpha2 = "MA",
        name = "Morocco"
    },
    {
        alpha2 = "MZ",
        name = "Mozambique"
    },
    {
        alpha2 = "MM",
        name = "Myanmar"
    },
    {
        alpha2 = "NA",
        name = "Namibia"
    },
    {
        alpha2 = "NR",
        name = "Nauru"
    },
    {
        alpha2 = "NP",
        name = "Nepal"
    },
    {
        alpha2 = "NL",
        name = "Netherlands"
    },
    {
        alpha2 = "NC",
        name = "New Caledonia"
    },
    {
        alpha2 = "NZ",
        name = "New Zealand"
    },
    {
        alpha2 = "NI",
        name = "Nicaragua"
    },
    {
        alpha2 = "NE",
        name = "Niger"
    },
    {
        alpha2 = "NG",
        name = "Nigeria"
    },
    {
        alpha2 = "NU",
        name = "Niue"
    },
    {
        alpha2 = "NF",
        name = "Norfolk Island"
    },
    {
        alpha2 = "MP",
        name = "Northern Mariana Islands"
    },
    {
        alpha2 = "NO",
        name = "Norway"
    },
    {
        alpha2 = "OM",
        name = "Oman"
    },
    {
        alpha2 = "PK",
        name = "Pakistan"
    },
    {
        alpha2 = "PW",
        name = "Palau"
    },
    {
        alpha2 = "PS",
        name = "Palestine, State of"
    },
    {
        alpha2 = "PA",
        name = "Panama"
    },
    {
        alpha2 = "PG",
        name = "Papua New Guinea"
    },
    {
        alpha2 = "PY",
        name = "Paraguay"
    },
    {
        alpha2 = "PE",
        name = "Peru"
    },
    {
        alpha2 = "PH",
        name = "Philippines"
    },
    {
        alpha2 = "PN",
        name = "Pitcairn"
    },
    {
        alpha2 = "PL",
        name = "Poland"
    },
    {
        alpha2 = "PT",
        name = "Portugal"
    },
    {
        alpha2 = "PR",
        name = "Puerto Rico"
    },
    {
        alpha2 = "QA",
        name = "Qatar"
    },
    {
        alpha2 = "RE",
        name = "Réunion"
    },
    {
        alpha2 = "RO",
        name = "Romania"
    },
    {
        alpha2 = "RU",
        name = "Russian Federation"
    },
    {
        alpha2 = "RW",
        name = "Rwanda"
    },
    {
        alpha2 = "BL",
        name = "Saint Barthélemy"
    },
    {
        alpha2 = "SH",
        name = "Saint Helena, Ascension and Tristan da Cunha"
    },
    {
        alpha2 = "KN",
        name = "Saint Kitts and Nevis"
    },
    {
        alpha2 = "LC",
        name = "Saint Lucia"
    },
    {
        alpha2 = "MF",
        name = "Saint Martin (French part)"
    },
    {
        alpha2 = "PM",
        name = "Saint Pierre and Miquelon"
    },
    {
        alpha2 = "VC",
        name = "Saint Vincent and the Grenadines"
    },
    {
        alpha2 = "WS",
        name = "Samoa"
    },
    {
        alpha2 = "SM",
        name = "San Marino"
    },
    {
        alpha2 = "ST",
        name = "Sao Tome and Principe"
    },
    {
        alpha2 = "SA",
        name = "Saudi Arabia"
    },
    {
        alpha2 = "SN",
        name = "Senegal"
    },
    {
        alpha2 = "RS",
        name = "Serbia"
    },
    {
        alpha2 = "SC",
        name = "Seychelles"
    },
    {
        alpha2 = "SL",
        name = "Sierra Leone"
    },
    {
        alpha2 = "SG",
        name = "Singapore"
    },
    {
        alpha2 = "SX",
        name = "Sint Maarten (Dutch part)"
    },
    {
        alpha2 = "SK",
        name = "Slovakia"
    },
    {
        alpha2 = "SI",
        name = "Slovenia"
    },
    {
        alpha2 = "SB",
        name = "Solomon Islands"
    },
    {
        alpha2 = "SO",
        name = "Somalia"
    },
    {
        alpha2 = "ZA",
        name = "South Africa"
    },
    {
        alpha2 = "GS",
        name = "South Georgia and the South Sandwich Islands"
    },
    {
        alpha2 = "SS",
        name = "South Sudan"
    },
    {
        alpha2 = "ES",
        name = "Spain"
    },
    {
        alpha2 = "LK",
        name = "Sri Lanka"
    },
    {
        alpha2 = "SD",
        name = "Sudan"
    },
    {
        alpha2 = "SR",
        name = "Suriname"
    },
    {
        alpha2 = "SJ",
        name = "Svalbard and Jan Mayen"
    },
    {
        alpha2 = "SZ",
        name = "Swaziland"
    },
    {
        alpha2 = "SE",
        name = "Sweden"
    },
    {
        alpha2 = "CH",
        name = "Switzerland"
    },
    {
        alpha2 = "SY",
        name = "Syrian Arab Republic"
    },
    {
        alpha2 = "TW",
        name = "Taiwan, Province of China"
    },
    {
        alpha2 = "TJ",
        name = "Tajikistan"
    },
    {
        alpha2 = "TZ",
        name = "Tanzania, United Republic of"
    },
    {
        alpha2 = "TH",
        name = "Thailand"
    },
    {
        alpha2 = "TL",
        name = "Timor-Leste"
    },
    {
        alpha2 = "TG",
        name = "Togo"
    },
    {
        alpha2 = "TK",
        name = "Tokelau"
    },
    {
        alpha2 = "TO",
        name = "Tonga"
    },
    {
        alpha2 = "TT",
        name = "Trinidad and Tobago"
    },
    {
        alpha2 = "TN",
        name = "Tunisia"
    },
    {
        alpha2 = "TR",
        name = "Turkey"
    },
    {
        alpha2 = "TM",
        name = "Turkmenistan"
    },
    {
        alpha2 = "TC",
        name = "Turks and Caicos Islands"
    },
    {
        alpha2 = "TV",
        name = "Tuvalu"
    },
    {
        alpha2 = "UG",
        name = "Uganda"
    },
    {
        alpha2 = "UA",
        name = "Ukraine"
    },
    {
        alpha2 = "AE",
        name = "United Arab Emirates"
    },
    {
        alpha2 = "GB",
        name = "United Kingdom"
    },
    {
        alpha2 = "US",
        name = "United States"
    },
    {
        alpha2 = "UM",
        name = "United States Minor Outlying Islands"
    },
    {
        alpha2 = "UY",
        name = "Uruguay"
    },
    {
        alpha2 = "UZ",
        name = "Uzbekistan"
    },
    {
        alpha2 = "VU",
        name = "Vanuatu"
    },
    {
        alpha2 = "VE",
        name = "Venezuela, Bolivarian Republic of"
    },
    {
        alpha2 = "VN",
        name = "Viet Nam"
    },
    {
        alpha2 = "VG",
        name = "Virgin Islands, British"
    },
    {
        alpha2 = "VI",
        name = "Virgin Islands, U.S."
    },
    {
        alpha2 = "WF",
        name = "Wallis and Futuna"
    },
    {
        alpha2 = "EH",
        name = "Western Sahara"
    },
    {
        alpha2 = "YE",
        name = "Yemen"
    },
    {
        alpha2 = "ZM",
        name = "Zambia"
    },
    {
        alpha2 = "ZW",
        name = "Zimbabwe"
    }
}

setmetatable(
    region,
    {
        __index = function(self, key)
            if type(key) == "string" then
                for _, r in ipairs(region) do
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

return region
