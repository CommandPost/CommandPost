local test				= require("cp.test")
local log				= require("hs.logger").new("t_notifier")
-- local inspect			= require("hs.inspect")

local application       = require("hs.application")
local ax                = require("hs._asm.axuielement")
local notifier          = require("cp.ui.notifier")
local just              = require("cp.just")
local timer             = require("hs.timer")

local insert            = table.insert

return test.suite("cp.ids"):with(

    test("new", function()
        local n = notifier.new("com.foo.Bar", function() return nil end)
        -- app doesn't exist
        ok(n:app() == nil)
        ok(n:currentElement() == nil)
    end),

    test("real app", function()
        local appUI = nil

        local n = notifier.new("com.apple.Preview", function()
            if appUI then
                local menuBar = appUI:attributeValue("AXMenuBar")
                return menuBar and menuBar[2][1][1]
            end
            return nil
        end)

        local results = {}
        local lastResult = nil

        n:addWatcher("AXMenuItemSelected", function(element, notification, details)
            log.f("This should output once, after the test completes: watcher called for '%s'.", notification)
            lastResult = {n = notification, e = element, d = details}
            insert(results, lastResult)
        end)

        ok(eq(#results, 0))

        -- start Preview
        local app = application.open("com.apple.Preview")
        ok(app ~= nil)

        appUI = ax.applicationElement(app)

        -- wait for the app to finish loading.
        just.doUntil(function() return appUI:attributeValue("AXMenuBar") ~= nil end, 5)

        local item = appUI:menuBar()[2][1][1]

        ok(item ~= nil)
        ok(eq(item:title(), "About Preview")) -- note, only works in English

        -- press the menu
        item:doPress()

        -- no results yet because we haven't started the notifier.
        ok(eq(#results, 0))

        -- watch for notifications and press again
        n:start()
        item:doPress()

        -- still no results because the notification is handled asynchronously.
        ok(eq(#results, 0))

        timer.doAfter(0.01, function()
            n:stop()
            item:doPress()

            app:kill()
        end)
    end)

)