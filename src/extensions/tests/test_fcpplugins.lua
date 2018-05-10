local test				= require("cp.test")
-- local log				= require("hs.logger").new("t_plugins")
-- local inspect			= require("hs.inspect")

local config			= require("cp.config")
local plugins		    = require("cp.apple.finalcutpro.plugins")
local localeID          = require("cp.i18n.localeID")

local PLUGINS_PATH = config.scriptPath .. "/tests/fcp/plugins"
local EFFECTS_PATH = PLUGINS_PATH .. "/Effects.localized"

local app = {
    getVersion = function() return "10.4" end,
    getPath = function() return "/Applications/Final Cut Pro.app" end
}

return test.suite("cp.apple.finalcutpro.plugins"):with(

    test("Get Motion Theme", function()
        local testEffect = EFFECTS_PATH .. "/Test/Test Effect/Test Effect.moef"
        ok(eq(plugins._getMotionTheme(testEffect), nil))

        local themedTestEffect = EFFECTS_PATH .. "/Test/Test Theme/Themed Test Effect/Themed Test Effect.moef"
        ok(eq(plugins._getMotionTheme(themedTestEffect), "Test Theme"))
    end),

    test("Scan Theme", function()
        local testTheme = EFFECTS_PATH .. "/Test/Test Theme"
        local scanner = plugins.new(app)

        local plugin = {
            type = "Effect",
            extension = "moef",
            check = function() return true end,
        }

        scanner:scanPluginThemeDirectory(localeID("en"), testTheme, plugin)
        local p = {en = {Effect = {
            {
                path = testTheme .. "/Themed Test Effect",
                type = "Effect",
                theme = "Test Theme",
                name = "Themed Test Effect",
                locale = localeID("en"),
            }
        }}}
        ok(eq(scanner._plugins, p))
    end),

    test("Scan Category", function()
        local testCategory = EFFECTS_PATH .. "/Test"
        local scanner = plugins.new(app)
        local en = localeID("en")

        local plugin = {
            type = "Effect",
            extension = "moef",
            check = function() return true end,
        }

        scanner:scanPluginCategoryDirectory(en, testCategory, plugin)
        local p = {en = {Effect = {
            {
                path = testCategory .. "/Test Effect",
                type = "Effect",
                theme = nil,
                name = "Test Effect",
                locale = en,
            },
            {
                path = testCategory .. "/Test Theme/Themed Test Effect",
                type = "Effect",
                theme = "Test Theme",
                name = "Themed Test Effect",
                locale = en,
            },
        }}}
        ok(eq(scanner._plugins, p))
    end),

    test("Scan Effects", function()
        local path = EFFECTS_PATH
        local scanner = plugins.new(app)
        local en = localeID("en")

        local plugin = {
            type = "Effect",
            extension = "moef",
            check = function() return true end,
        }

        scanner:scanPluginTypeDirectory("en", path, plugin)
        local p = {en = {Effect = {
            {
                path = path .. "/Test/Test Effect",
                type = "Effect",
                category = "Test",
                theme = nil,
                name = "Test Effect",
                locale = en,
            },
            {
                path = path .. "/Test/Test Theme/Themed Test Effect",
                type = "Effect",
                category = "Test",
                theme = "Test Theme",
                name = "Themed Test Effect",
                locale = en,
            },
            {
                path = path .. "/Local.localized/Local Effect.localized",
                type = "Effect",
                category = "Local EN",
                theme = nil,
                name = "Local Effect EN",
                locale = en,
            },
            {
                category = "Local EN",
                locale = en,
                name = "Versioned Effect EN",
                path = path .. "/Local.localized/Versioned Effect.v2.localized",
                type = "Effect"
            },
        }}}
        ok(eq(scanner._plugins, p))
    end)
)
