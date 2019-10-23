-- test cases for `cp.is`
local spec              = require "cp.spec"
local expect            = require "cp.spec.expect"
local describe, it      = spec.describe, spec.it

local app       = require("cp.app")

return describe "cp.app" {
    it "can check if a value is a cp.app"
    :doing(function()
        local preview = app.forBundleID("com.apple.Preview")

        expect(app.is(preview)):is(true)
        expect(app.is("foobar")):is(false)
        expect(app.is(true)):is(false)
    end),

    it "loads Preview via forBundleID"
    :doing(function()
        local preview = app.forBundleID("com.apple.Preview")

        expect(preview):isNot(nil)
        expect(preview:bundleID()):is("com.apple.Preview")
    end),

    it "launch and quit"
    :doing(function(this)
        local preview = app.forBundleID("com.apple.Preview")

        this:wait(20)
        preview:doLaunch(10):Now(
            function(success)
                expect(success):is(true)
                expect(preview:running()):is(true)
            end,
            error,
            function()
                preview:doQuit():Now(
                    function(success)
                        expect(success):is(true)
                    end,
                    error,
                    function()
                        expect(preview:running()):is(false)
                        this:done()
                    end
                )
            end
        )
    end),

    it "has a UI when running"
    :doing(function(this)
        local preview = app.forBundleID("com.apple.Preview")

        this:wait(20)
        preview:doLaunch(10):Now(
            function(success)
                expect(success):is(true)
                expect(preview:running()):is(true)
                expect(preview:UI()):isNot(nil)
            end,
            error,
            function()
                preview:doQuit():Now(
                    function(success)
                        expect(success):is(true)
                    end,
                    error,
                    function()
                        expect(preview:running()):is(false)
                        expect(preview:UI()):is(nil)
                        this:done()
                    end
                )
            end
        )
    end),

    it "path"
    :doing(function()
        local preview = app.forBundleID("com.apple.Preview")
        expect(preview:path()):is("/Applications/Preview.app")
    end)
}