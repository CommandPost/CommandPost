-- test cases for `cp.is`
local test      = require("cp.test")
local app       = require("cp.app")

local just      = require("cp.just")

return test.suite("cp.app"):with {
    test("forBundleID", function()
        local preview = app.forBundleID("com.apple.Preview")

        ok(preview ~= nil)
        ok(eq(preview:bundleID(), "com.apple.Preview"))
    end),

    test("launch and quit", function()
        local preview = app.forBundleID("com.apple.Preview")
        preview:launch(10)
        ok(eq(preview:running(), true))

        local hsApp = preview:hsApplication()
        ok(hsApp ~= nil)
        ok(eq(preview:running(), true))

        preview:quit(5)
        ok(eq(preview:running(), false))
    end),

    test("UI", function()
        local preview = app.forBundleID("com.apple.Preview")
        ok(eq(preview:launch(10):running(), true))

        local ui = just.doUntil(function() return preview:UI() end, 10)
        ok(ui ~= nil)

        ok(eq(preview:quit(5):running(), false))
    end),

    test("path", function()
        local preview = app.forBundleID("com.apple.Preview")
        ok(eq(preview:path(), "/Applications/Preview.app"))
    end)
}