--- === plugins.finder.pasteboard ===
---
--- Handy text tools.

local require           = require

local log               = require "hs.logger".new "textTools"

local eventtap          = require "hs.eventtap"
local pasteboard        = require "hs.pasteboard"

local tools             = require "cp.tools"

local upper             = tools.upper
local lower             = tools.lower
local camelCase         = tools.camelCase

local keyStroke         = tools.keyStroke
local keyStrokes        = eventtap.keyStrokes
local playErrorSound    = tools.playErrorSound

local mod = {}

-- processText(value, copyAndPaste) -> none
-- Function
-- Processes Text
--
-- Parameters:
--  * value - The type of text manipulation you want to do. Current values are: `uppercase`, `lowercase` or `camelcase`.
--  * copyAndPaste - A boolean that defines whether or not we should trigger copy and paste.
--
-- Returns:
--  * None
local function processText(value, copyAndPaste)
    if copyAndPaste then
        keyStroke({"command"}, "c")
    end
    local contents = pasteboard.getContents()
    if contents and type(contents) == "string" then
        local result = ""
        if value == "uppercase" then
            result = upper(contents)
        elseif value == "lowercase" then
            result = lower(contents)
        elseif value == "camelcase" then
            result = camelCase(contents)
        end
        if pasteboard.setContents(result) then
            if copyAndPaste then
                keyStroke({"command"}, "v")
            end
        else
            log.ef("Failed to write this to the Pasteboard: %s (%s)", result, type(result))
        end
    else
        log.ef("Pasteboard Contents is invalid: %s", contents)
        playErrorSound()
    end
end

local plugin = {
    id              = "finder.pasteboard",
    group           = "finder",
    dependencies    = {
        ["core.commands.global"]                    = "global",
    }
}

function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Commands:
    --------------------------------------------------------------------------------
    local global = deps.global

    --------------------------------------------------------------------------------
    -- Add Commands:
    --------------------------------------------------------------------------------
    global:add("cpMakePasteboardTextUppercase")
        :whenActivated(function() processText("uppercase", false) end)

    global:add("cpMakePasteboardTextLowercase")
        :whenActivated(function() processText("lowercase", false) end)

    global:add("cpMakePasteboardTextCamelcase")
        :whenActivated(function() processText("camelcase", false) end)

    global:add("cpMakeSelectedTextUppercase")
        :whenActivated(function() processText("uppercase", true) end)

    global:add("cpMakeSelectedTextLowercase")
        :whenActivated(function() processText("lowercase", true) end)

    global:add("cpMakeSelectedTextCamelcase")
        :whenActivated(function() processText("camelcase", true) end)

    global:add("cpTypeClipboardContents")
        :whenActivated(function()
            local pasteboardContents = pasteboard.getContents()
            if pasteboardContents then
                keyStrokes(pasteboardContents)
            else
                playErrorSound()
            end
        end)

    return mod
end

return plugin
