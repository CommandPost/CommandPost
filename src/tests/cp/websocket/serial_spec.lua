-- test cases for `cp.websocket.serial`
local spec              = require "cp.spec"
local expect            = require "cp.spec.expect"
local describe, it      = spec.describe, spec.it

local serial            = require "cp.websocket.serial"

return describe "cp.websocket.serial" {
    it "creates an HTTP request"
    :doing(function()
        local value = serial._createHTTPRequest("GET", "index.html", {
            ["Foo"] = "bar",
        })

        expect(value):is(
            "GET index.html HTTP/1.1\r\n"..
            "Foo: bar\r\n"..
            "\r\n"
        )
    end),

    it "parses an HTTP response"
    :doing(function()
        local value = serial._parseHTTPResponse(
            "HTTP/1.1 101 Switching Protocols\r\n"..
            "Upgrade: websocket\r\n"..
            "Connection: Upgrade\r\n"..
            "\r\n"..
            "Hello world!\r\n"
        ):get()

        expect(value.statusCode):is(101)
        expect(value.reason):is("Switching Protocols")
        expect(value.headers["Connection"]):is("Upgrade")
        expect(value.headers["Upgrade"]):is("websocket")
        expect(value.body):is("Hello world!\r\n")
    end),

    it "fails a bad status code"
    :doing(function()
        local outcome = serial._parseHTTPResponse(
            "HTTP/1.1 IOI Switching Protocols\r\n"..
            "\r\n"
        )

        expect(outcome.failure):is(true)
    end),

    it "fails a bad header value"
    :doing(function()
        local outcome = serial._parseHTTPResponse(
            "HTTP/1.1 101 Switching Protocols\r\n"..
            "Upgrade = websocket\r\n"..
            "\r\n"
        )

        expect(outcome.failure):is(true)
    end),

    it "fails when missing blank line after headers"
    :doing(function()
        local outcome = serial._parseHTTPResponse(
            "HTTP/1.1 101 Switching Protocols\r\n"..
            "Upgrade: websocket\r\n"..
            "Connection: Upgrade\r\n"
        )

        expect(outcome.failure):is(true)
    end),

    it "fails when missing carriage-returns"
    :doing(function()
        local outcome = serial._parseHTTPResponse(
            "HTTP/1.1 101 Switching Protocols\n"..
            "Upgrade: websocket\n"..
            "Connection: Upgrade\n"..
            "\n"
        )

        expect(outcome.failure):is(true)
    end),
}