--- === plugins.core.tourbox.manager ===
---
--- TourBox Manager Plugin.

local require                   = require

local log                       = require "hs.logger".new "tourBox"

local application               = require "hs.application"
local appWatcher                = require "hs.application.watcher"
local bytes                     = require "hs.bytes"
local eventtap                  = require "hs.eventtap"
local image                     = require "hs.image"
local serial                    = require "hs.serial"
local timer                     = require "hs.timer"

local config                    = require "cp.config"
local dialog                    = require "cp.dialog"
local i18n                      = require "cp.i18n"
local json                      = require "cp.json"

local applicationsForBundleID   = application.applicationsForBundleID
local displayNotification       = dialog.displayNotification
local doAfter                   = timer.doAfter
local doEvery                   = timer.doEvery
local hexToBytes                = bytes.hexToBytes
local imageFromPath             = image.imageFromPath
local keyRepeatInterval         = eventtap.keyRepeatInterval
local launchOrFocusByBundleID   = application.launchOrFocusByBundleID

local mod = {}

-- BAUD_RATE
-- Constant
-- Baud Rate for serial connection.
local BAUD_RATE = 115200

-- TOURBOX_CONSOLE_BUNDLE_ID -> string
-- Constant
-- The TourBox Console Bundle ID.
local TOURBOX_CONSOLE_BUNDLE_ID = "com.tourbox.ui.launch"

-- DEVICES -> table
-- Constant
-- TourBox Hardware information.
local DEVICES = {
    original = {
        name = "TourBox",
        idVendor  = 4292,   -- 0x10C4
        idProduct = 60000,  -- 0xEA60
        initHex = {
            --------------------------------------------------------------------------------
            -- Unlock:
            --------------------------------------------------------------------------------
            "5500072cd8001afe",

            --------------------------------------------------------------------------------
            -- Config frames:
            --------------------------------------------------------------------------------
            "a5001f2cd80001ffffffffffffffff0001ffffffffffffff0100ff01000000fe",
        },
    },
    elite = {
        name = "TourBox Elite",
        idVendor  = 49745, -- 0xC251
        idProduct = 8197,  -- 0x2005
        initHex = {
            --------------------------------------------------------------------------------
            -- Unlock:
            --------------------------------------------------------------------------------
            "5500078894001afe",

            --------------------------------------------------------------------------------
            -- Packet 1:
            --------------------------------------------------------------------------------
            "1b00b0c99f2503e7ffff000000000900000300130002035e000000b5005d040805080608070808080809080b080c080d080e080f0826082708280829083b083c083d083e083f0840084108420843084408450846084708480849084a084b084c084d084e084f0850085108520853085408a808a908aa08ab08fe",

            --------------------------------------------------------------------------------
            -- Packet 2:
            --------------------------------------------------------------------------------
            "1b00b0c99f2503e7ffff0000000009000103001300020300000000",
        },
    }
}

-- ELITE_HAPTIC_TEMPLATE_HEX -> string
-- Constant
-- TourBox Elite Haptic Feedback Template Hex.
local ELITE_HAPTIC_TEMPLATE_HEX =
    "b5005d04" ..
    "00050006000700080009000b000c000d" ..
    "000e000f0026002700280029003b003c003d003e" ..
    "003f004000410042004300440045004600470048" ..
    "0049004a004b004c004d004e004f005000510052" ..
    "0053005400a800a900aa00ab00fe"

-- ELITE_HAPTIC_OFFSETS -> table
-- Constant
-- TourBox Elite Haptic Feedback Offsets.
local ELITE_HAPTIC_OFFSETS = {
    --------------------------------------------------------------------------------
    -- Knob:
    --------------------------------------------------------------------------------
    4,6,8,10,12,34,36,38,40,42,44,46,48,50,52,

    --------------------------------------------------------------------------------
    -- Scroll:
    --------------------------------------------------------------------------------
    14,16,18,20,22,26,28,30,32,54,56,58,60,62,64,

    --------------------------------------------------------------------------------
    -- Dial:
    --------------------------------------------------------------------------------
    24,66,68,70,72,74,76,78,80,82,84,86,88,90,92,
}

-- fileExtension -> string
-- Variable
-- File Extension for TourBox
local fileExtension = ".cpTourBox"

-- defaultFilename -> string
-- Variable
-- Default Filename for TourBox Settings
local defaultFilename = "Default" .. fileExtension

-- plugins.core.tourbox.manager._connecting -> boolean
-- Variable
-- Are we connecting?
mod._connecting = false

-- plugins.core.tourbox.manager._retryTimer -> boolean
-- Variable
-- Retry timer
mod._retryTimer = nil

-- plugins.core.tourbox.manager._retryDelay -> boolean
-- Variable
-- Retry delay
mod._retryDelay = 0.25

-- plugins.core.tourbox.manager._lastPortName -> boolean
-- Variable
-- Last port name
mod._lastPortName = nil

-- hexToByteArray(hex) -> string
-- Function
-- Converts Hex to Byte Array
--
-- Parameters:
--  * hex - Hex string
--
-- Returns:
--  * Byte array
local function hexToByteArray(hex)
    hex = hex:gsub("%s+", ""):lower()
    local out = {}
    for i = 1, #hex, 2 do
        out[#out+1] = tonumber(hex:sub(i,i+1), 16) or 0
    end
    return out
end

-- byteArrayToHex(t) -> string
-- Function
-- Converts a Byte Array to a Hex String
--
-- Parameters:
--  * t - The byte array
--
-- Returns:
--  * A string
local function byteArrayToHex(t)
    local s = {}
    for i = 1, #t do
        s[#s+1] = string.format("%02x", t[i] & 0xFF)
    end
    return table.concat(s)
end

-- buildEliteHapticsHex(strength, speed) -> string
-- Function
-- Build TourBox Elite Haptics Hex.
--
-- Parameters:
--  * strength - 0x00, 0x04, 0x08
--  * speed - 0x00, 0x01, 0x02
--
-- Returns:
--  * Hex String
local function buildEliteHapticsHex(strength, speed)
    local msg = hexToByteArray(ELITE_HAPTIC_TEMPLATE_HEX)
    local v = (strength or 0x00) | (speed or 0x00)

    for _, off in ipairs(ELITE_HAPTIC_OFFSETS) do
        local i = off + 1 -- convert 0-based -> Lua index
        if i >= 1 and i <= #msg then
            msg[i] = v
        end
    end

    return byteArrayToHex(msg)
end

-- makeEliteAckFromReportHex(reportHex) -> string
-- Function
-- Build the 27-byte ACK from the incoming 28-byte report.
--
-- Parameters:
--  * reportHex - Hex string
--
-- Returns:
--  * Byte array in table.
local function makeEliteAckFromReportHex(reportHex)
    local b = hexToByteArray(reportHex)
    if #b ~= 28 then return nil end
    if b[1] ~= 0x1b or b[2] ~= 0x00 then return nil end

    --------------------------------------------------------------------------------
    -- ACK is first 27 bytes, with a few fields normalized like the capture shows:
    --------------------------------------------------------------------------------
    local ack = {}
    for i = 1, 27 do
        ack[i] = b[i]
    end

    --------------------------------------------------------------------------------
    -- Observed: byte[8] (1-based) e7 -> d7 (subtract 0x10):
    --------------------------------------------------------------------------------
    ack[8] = (ack[8] - 0x10) & 0xFF

    --------------------------------------------------------------------------------
    -- Observed: byte[17] (1-based) 01 -> 00:
    --------------------------------------------------------------------------------
    ack[17] = 0x00

    --------------------------------------------------------------------------------
    -- Observed: byte[24] (1-based) 01 -> 00:
    --------------------------------------------------------------------------------
    ack[24] = 0x00

    --------------------------------------------------------------------------------
    -- Ensure last byte exists (27 bytes total):
    --------------------------------------------------------------------------------
    return byteArrayToHex(ack)
end

-- scheduleReconnect(portName) -> none
-- Function
-- Schedule reconnection to TourBox device
--
-- Parameters:
--  * portName - The port name
--
-- Returns:
--  * None
local function scheduleReconnect(portName)
    if mod._retryTimer then return end
    mod._retryTimer = doAfter(mod._retryDelay, function()
        mod._retryTimer = nil
        mod._retryDelay = math.min(mod._retryDelay * 1.5, 2.0) -- backoff up to 2s
        mod.connectToTourBox(portName or mod._lastPortName)
    end)
end

-- matchingDevice(portDetails) -> none
-- Function
-- Matches a device to port details.
--
-- Parameters:
--  * portDetails - Port details
--
-- Returns:
--  * The TourBox device
local function matchingDevice(portDetails)
    if not portDetails then return nil end
    for _, dev in pairs(DEVICES) do
        if portDetails.idVendor == dev.idVendor and portDetails.idProduct == dev.idProduct then
            return dev
        end
    end
    return nil
end

-- lockup -> table
-- Variable
-- A lookup table that translates TourBox messages to control and action type strings.
local lookup = {
	["01"] 		= {controlType = "side", actionType = "pressAction", supportsDoubleClick = true},
	["81"] 		= {controlType = "side", actionType = "releaseAction", supportsDoubleClick = true},
	["21"]      = {controlType = "side", actionType = "doubleClickPressAction"},
	["a1"]      = {controlType = "side", actionType = "doubleClickReleaseAction"},

	["02"] 		= {controlType = "top", actionType = "pressAction", supportsDoubleClick = true},
	["82"] 		= {controlType = "top", actionType = "releaseAction", supportsDoubleClick = true},
	["1f"] 		= {controlType = "top", actionType = "doubleClickPressAction"},
	["9f"] 		= {controlType = "top", actionType = "doubleClickReleaseAction"},
	["20"] 		= {controlType = "top", actionType = "pressSideAction"},
	["a0"] 		= {controlType = "top", actionType = "releaseSideAction"},

	["00"] 		= {controlType = "tall", actionType = "pressAction", supportsDoubleClick = true},
	["80"] 		= {controlType = "tall", actionType = "releaseAction", supportsDoubleClick = true},
	["18"] 		= {controlType = "tall", actionType = "doubleClickPressAction"},
	["98"] 		= {controlType = "tall", actionType = "doubleClickReleaseAction"},
	["1b"] 		= {controlType = "tall", actionType = "pressSideAction"},
	["9b"] 		= {controlType = "tall", actionType = "releaseSideAction"},
	["1a"]      = {controlType = "tall", actionType = "pressShortAction"},
	["9a"]      = {controlType = "tall", actionType = "releaseShortAction"},

	["03"] 		= {controlType = "short", actionType = "pressAction", supportsDoubleClick = true},
	["83"] 		= {controlType = "short", actionType = "releaseAction", supportsDoubleClick = true},
	["1c"] 		= {controlType = "short", actionType = "doubleClickPressAction"},
	["9c"] 		= {controlType = "short", actionType = "doubleClickReleaseAction"},
	["1e"] 		= {controlType = "short", actionType = "pressSideAction"},
	["9e"] 		= {controlType = "short", actionType = "releaseSideAction"},

	["0a"] 		= {controlType = "scroll", actionType = "pressAction", supportsDoubleClick = true},
	["8a"] 		= {controlType = "scroll", actionType = "releaseAction", supportsDoubleClick = true},
	["49c9"] 	= {controlType = "scroll", actionType = "leftAction"},
	["0989"] 	= {controlType = "scroll", actionType = "rightAction"},
	["4ece"]    = {controlType = "scroll", actionType = "leftSideAction"},
	["0e8e"]    = {controlType = "scroll", actionType = "rightSideAction"},
	["4dcd"]    = {controlType = "scroll", actionType = "leftTopAction"},
	["0d8d"]    = {controlType = "scroll", actionType = "rightTopAction"},
	["4bcb"]    = {controlType = "scroll", actionType = "leftTallAction"},
	["0b8b"]    = {controlType = "scroll", actionType = "rightTallAction"},
	["4ccc"]    = {controlType = "scroll", actionType = "leftShortAction"},
	["0c8c"]    = {controlType = "scroll", actionType = "rightShortAction"},
	["66e6"]    = {controlType = "scroll", actionType = "leftUpAction"},
	["26a6"]    = {controlType = "scroll", actionType = "rightUpAction"},
	["68e8"]    = {controlType = "scroll", actionType = "leftLeftAction"},
	["28a8"]    = {controlType = "scroll", actionType = "rightLeftAction"},
	["67e7"]    = {controlType = "scroll", actionType = "leftDownAction"},
	["27a7"]    = {controlType = "scroll", actionType = "rightDownAction"},
	["69e9"]    = {controlType = "scroll", actionType = "leftRightAction"},
	["29a9"]    = {controlType = "scroll", actionType = "rightRightAction"},

	["37"]      = {controlType = "knob", actionType = "pressAction"},
	["b7"]      = {controlType = "knob", actionType = "releaseAction"},
	["0484"] 	= {controlType = "knob", actionType = "leftAction"},
	["44c4"] 	= {controlType = "knob", actionType = "rightAction"},
	["48c8"] 	= {controlType = "knob", actionType = "leftSideAction"},
	["0888"] 	= {controlType = "knob", actionType = "rightSideAction"},
	["47c7"] 	= {controlType = "knob", actionType = "leftTopAction"},
	["0787"] 	= {controlType = "knob", actionType = "rightTopAction"},
	["45c5"] 	= {controlType = "knob", actionType = "leftTallAction"},
	["0585"] 	= {controlType = "knob", actionType = "rightTallAction"},
	["46c6"] 	= {controlType = "knob", actionType = "leftShortAction"},
	["0686"] 	= {controlType = "knob", actionType = "rightShortAction"},

	["22"] 		= {controlType = "c1", actionType = "pressAction"},
	["a2"] 		= {controlType = "c1", actionType = "releaseAction"},
	["24"] 		= {controlType = "c1", actionType = "pressTallAction"},
	["a4"] 		= {controlType = "c1", actionType = "releaseTallAction"},

	["23"] 		= {controlType = "c2", actionType = "pressAction"},
	["a3"] 		= {controlType = "c2", actionType = "releaseAction"},

	["4fcf"] 	= {controlType = "dial", actionType = "leftAction"},
	["0f8f"] 	= {controlType = "dial", actionType = "rightAction"},
	["38"]      = {controlType = "dial", actionType = "pressAction"},
	["b8"]      = {controlType = "dial", actionType = "releaseAction"},

	["2a"] 		= {controlType = "tour", actionType = "pressAction"},
	["aa"] 		= {controlType = "tour", actionType = "releaseAction"},

	["10"] 		= {controlType = "up", actionType = "pressAction"},
	["90"] 		= {controlType = "up", actionType = "releaseAction"},
	["14"] 		= {controlType = "up", actionType = "pressSideAction"},
	["94"] 		= {controlType = "up", actionType = "releaseSideAction"},
	["2b"] 		= {controlType = "up", actionType = "pressTopAction"},
	["ab"] 		= {controlType = "up", actionType = "releaseTopAction"},

	["11"] 		= {controlType = "down", actionType = "pressAction"},
	["91"] 		= {controlType = "down", actionType = "releaseAction"},
	["15"] 		= {controlType = "down", actionType = "pressSideAction"},
	["95"] 		= {controlType = "down", actionType = "releaseSideAction"},
	["2c"] 		= {controlType = "down", actionType = "pressTopAction"},
	["ac"] 		= {controlType = "down", actionType = "releaseTopAction"},

	["12"] 		= {controlType = "left", actionType = "pressAction"},
	["92"] 		= {controlType = "left", actionType = "releaseAction"},
	["16"] 		= {controlType = "left", actionType = "pressSideAction"},
	["96"] 		= {controlType = "left", actionType = "releaseSideAction"},
	["2d"] 		= {controlType = "left", actionType = "pressTopAction"},
	["ad"] 		= {controlType = "left", actionType = "releaseTopAction"},

	["13"] 		= {controlType = "right", actionType = "pressAction"},
	["93"] 		= {controlType = "right", actionType = "releaseAction"},
	["17"] 		= {controlType = "right", actionType = "pressSideAction"},
	["97"] 		= {controlType = "right", actionType = "releaseSideAction"},
	["2e"] 		= {controlType = "right", actionType = "pressTopAction"},
	["ae"] 		= {controlType = "right", actionType = "releaseTopAction"},

    --------------------------------------------------------------------------------
    -- TourBox Elite (single-byte event codes = last byte of 28-byte frame):
    --------------------------------------------------------------------------------
    ["49"] = {controlType = "scroll", actionType = "rightAction"}, -- clockwise/up
    ["09"] = {controlType = "scroll", actionType = "leftAction"},  -- counter/down

    ["44"] = {controlType = "knob",   actionType = "rightAction"}, -- clockwise/up
    ["04"] = {controlType = "knob",   actionType = "leftAction"},  -- counter/down

    ["4f"] = {controlType = "dial",   actionType = "rightAction"}, -- clockwise/up
    ["0f"] = {controlType = "dial",   actionType = "leftAction"},  -- counter/down
}

-- cachedBundleID -> string
-- Variable
-- The last bundle ID processed.
local cachedBundleID = ""

-- executeAction(thisAction) -> boolean
-- Function
-- Executes an action.
--
-- Parameters:
--  * thisAction - The action to execute
--
-- Returns:
--  * `true` if successful otherwise `false`
local function executeAction(thisAction)
    if thisAction then
        local handlerID = thisAction.handlerID
        local action = thisAction.action
        if handlerID and action then
            local handler = mod._actionmanager.getHandler(handlerID)
            if handler then
                doAfter(0, function()
                    handler:execute(action)
                end)
                return true
            end
        end
    end
    return false
end

-- doubleClickInProgress -> table
-- Variable
-- A table containing a list of all the active double click's in progress
local doubleClickInProgress = {}

-- repeatTimers -> table
-- Variable
-- A table containing all the repeat timers
local repeatTimers = {}

-- delayTimers -> table
-- Variable
-- A table containing all the delay timers
local delayTimers = {}

-- ignoreNextReleaseAction -> table
-- Variable
-- A table containing all the release actions to ignore.
local ignoreNextReleaseAction = {}

-- processMessage(message) -> none
-- Function
-- Processes a TourBox message
--
-- Parameters:
--  * message - A table containing the message from the TourBox.
--
-- Returns:
--  * None
local function processMessage(m)

    --log.df("processMessage: %s", hs.inspect(m))

    local items = mod.items()
    local bundleID = cachedBundleID

    --------------------------------------------------------------------------------
    -- Revert to "All Applications" if no settings for frontmost app exist:
    --------------------------------------------------------------------------------
    if not items[bundleID] then
        bundleID = "All Applications"
    end

    --------------------------------------------------------------------------------
    -- Ignore if ignored:
    --------------------------------------------------------------------------------
    if items[bundleID] and items[bundleID].ignore then
        bundleID = "All Applications"
    end

    --------------------------------------------------------------------------------
    -- If not Automatically Switching Applications:
    --------------------------------------------------------------------------------
    if not mod.automaticallySwitchApplications() then
        bundleID = mod.lastBundleID()
    end

    --------------------------------------------------------------------------------
    -- Get data from settings:
    --------------------------------------------------------------------------------
    local activeBanks = mod.activeBanks()
    local bankID = activeBanks[bundleID] or "1"

    local item = items[bundleID]
    local bank = item and item[bankID]
    local control = bank and bank[m.controlType]
    local action = control and control[m.actionType]

    local controlType = m.controlType
    local actionType = m.actionType
    local supportsDoubleClick = m.supportsDoubleClick

    --------------------------------------------------------------------------------
    -- Release any held down buttons:
    --------------------------------------------------------------------------------
    if actionType:find("elease") then -- This isn't a typo.
        local releaseFn = function()
            local id = controlType .. actionType:gsub("release", "press"):gsub("Release", "Press")
            if repeatTimers[id] then
                repeatTimers[id]:stop()
                repeatTimers[id] = nil
            end
        end
        if supportsDoubleClick then
            --------------------------------------------------------------------------------
            -- This control supports double clicks, so we need to add a delay to check
            -- if it's a single click or a double click:
            --------------------------------------------------------------------------------
            doAfter(0.2, releaseFn)
        else
            --------------------------------------------------------------------------------
            -- This control doesn't support double clicks so trigger it straight away:
            --------------------------------------------------------------------------------
            releaseFn()
        end
    end

    --------------------------------------------------------------------------------
    -- Ignore the release action when Arrow Keys pressed with Side/Top Modifiers:
    --------------------------------------------------------------------------------
    if controlType == "up" or controlType == "down" or controlType == "left" or controlType == "right" then
        if actionType == "releaseAction" and ignoreNextReleaseAction[controlType] then
            ignoreNextReleaseAction[controlType] = false
            return
        end
        if actionType == "releaseTopAction" or actionType == "releaseSideAction" then
            ignoreNextReleaseAction[controlType] = true
        end
    end

    --------------------------------------------------------------------------------
    -- Ignore the release action when Tall button pressed with Short Modifier:
    --------------------------------------------------------------------------------
    if controlType == "tall" then
        if actionType == "releaseAction" and ignoreNextReleaseAction[controlType] then
            ignoreNextReleaseAction[controlType] = false
            return
        end
        if actionType == "releaseShortAction" then
            ignoreNextReleaseAction[controlType] = true
        end

    end

    --log.df("%s - %s", controlType, actionType)

    --------------------------------------------------------------------------------
    -- Trigger actions:
    --------------------------------------------------------------------------------
    if action then
        --------------------------------------------------------------------------------
        -- Function that triggers the
        --------------------------------------------------------------------------------
        local triggerAction = function()
            executeAction(action)
            if action.action and control[actionType .. "Repeat"] then
                local repeatID = controlType .. actionType
                repeatTimers[repeatID] = doEvery(keyRepeatInterval(), function()
                    executeAction(action)
                end)
            end
        end

        --------------------------------------------------------------------------------
        -- A double click should remove any single presses and releases from the queue:
        --------------------------------------------------------------------------------
        if actionType == "doubleClickPressAction" then
            if delayTimers[controlType .. "pressAction"] then
                delayTimers[controlType .. "pressAction"]:stop()
                delayTimers[controlType .. "pressAction"] = nil
            end
            if delayTimers[controlType .. "releaseAction"] then
                delayTimers[controlType .. "releaseAction"]:stop()
                delayTimers[controlType .. "releaseAction"] = nil
            end
        end

        if supportsDoubleClick then
            --------------------------------------------------------------------------------
            -- This control supports double clicks, so we need to add a delay to check
            -- if it's a single click or a double click:
            --------------------------------------------------------------------------------
            local id = controlType .. actionType
            doubleClickInProgress[id] = true
            delayTimers[id] = doAfter(0.2, function()
                if doubleClickInProgress[id] then
                    doubleClickInProgress[id] = false
                    triggerAction()
                end
                delayTimers[id] = nil
            end)
        else
            --------------------------------------------------------------------------------
            -- This control doesn't support double clicks so trigger it straight away:
            --------------------------------------------------------------------------------
            triggerAction()
        end
    end
end

mod._ignoreInputUntil = 0

-- processHexReport(hex) -> none
-- Function
-- Processes the Hex Report from a TourBox device.
--
-- Parameters:
--  * hex - The hex string
--
-- Returns:
--  * None
local function processHexReport(hex)
    if not hex or hex == "" then return end

    if mod._ignoreInputUntil and timer.secondsSinceEpoch() < mod._ignoreInputUntil then
        return
    end


    hex = hex:gsub("%s+", ""):lower()

    --------------------------------------------------------------------------------
    -- Scan byte stream and fire lookup matches:
    --------------------------------------------------------------------------------
    local function scanByteStream(h)
        local matched = false
        for i = 1, #h - 1, 2 do
            local b1 = h:sub(i, i+1)
            local entry = lookup[b1]
            if entry then
                matched = true
                processMessage(entry)
            end
        end
        if not matched then
            log.df("TourBox unmapped report: %s", h)
        end
    end

    --------------------------------------------------------------------------------
    -- TourBox Elite:
    -- Sometimes events arrive as full 28-byte frames (starting 1b00),
    -- but in your case wheel ticks arrive as single bytes ("0f", "4f", etc).
    --------------------------------------------------------------------------------
    if mod._device and mod._device.name == "TourBox Elite" then
        local frameLen = 56

        --------------------------------------------------------------------------------
        -- If it looks like a framed packet (or multiple), parse frames;
        -- otherwise treat as byte stream:
        --------------------------------------------------------------------------------
        if #hex >= 4 and hex:sub(1,4) == "1b00" and #hex >= frameLen then
            local i = 1
            local matchedAny = false

            while i <= (#hex - 3) do
                if hex:sub(i, i+3) == "1b00" and (i + frameLen - 1) <= #hex then
                    local frame = hex:sub(i, i + frameLen - 1)
                    local eventByte = frame:sub(#frame-1, #frame)
                    local entry = lookup[eventByte]
                    if entry then
                        matchedAny = true
                        processMessage(entry)
                    else
                        log.df("TourBox Elite unmapped event byte: %s (frame=%s)", eventByte, frame)
                    end
                    i = i + frameLen
                else
                    i = i + 2
                end
            end

            if not matchedAny then
                log.df("TourBox Elite RX (no event matched): %s", hex)
            end
            return
        else
            --------------------------------------------------------------------------------
            -- Single-byte (or short stream) mode:
            --------------------------------------------------------------------------------
            scanByteStream(hex)
            return
        end
    end

    --------------------------------------------------------------------------------
    -- Original TourBox behaviour (byte scan + x,(x|0x80) tick coalescing):
    --------------------------------------------------------------------------------
    local matched = false
    local i = 1

    while i <= (#hex - 1) do
        local b1 = hex:sub(i, i+1)
        local v1 = tonumber(b1, 16)

        local b2, v2 = nil, nil
        if i+3 <= #hex then
            b2 = hex:sub(i+2, i+3)
            v2 = tonumber(b2, 16)
        end

        if v1 and v2 and v2 == (v1 + 0x80) then
            local entry = lookup[b1]
            if entry then
                matched = true
                processMessage(entry)
            end
            i = i + 4
        else
            local entry = lookup[b1]
            if entry then
                matched = true
                processMessage(entry)
            end
            i = i + 2
        end
    end

    if not matched then
        log.df("TourBox unmapped report: %s", hex)
    end
end



-- tourBoxCallback(obj, messageType, data, messageHexString) -> none
-- Function
-- TourBox Serial Callback
--
-- Parameters:
--  * obj - The hs.serial object
--  * messageType - A string containing the message type
--  * message - The encoded message
--  * messageHexString - The message as a hex string
--
-- Returns:
--  * None
local function tourBoxCallback(obj, messageType, message, messageHexString)
    if messageType == "opened" then
        --------------------------------------------------------------------------------
        -- Ignore input briefly while we get TourBox setup:
        --------------------------------------------------------------------------------
        mod._ignoreInputUntil = timer.secondsSinceEpoch() + 0.5

        local dev = mod._device
        if dev and dev.initHex then
            doAfter(0.1, function()
                for i, hex in ipairs(dev.initHex) do
                    --------------------------------------------------------------------------------
                    -- Small stagger can help on some serial devices:
                    --------------------------------------------------------------------------------
                    doAfter(0.01 * (i-1), function()
                        mod.tourBox:sendData(hexToBytes(hex))
                    end)
                end

                --------------------------------------------------------------------------------
                -- Enable Haptics:
                --------------------------------------------------------------------------------
                mod.updateHaptics()
            end)
        else
            --------------------------------------------------------------------------------
            -- Keep the old behavior if device unknown as a fallback:
            --------------------------------------------------------------------------------
            mod.tourBox:sendData(hexToBytes("5500072cd8001afe"))
            mod.tourBox:sendData(hexToBytes("a5001f2cd80001ffffffffffffffff0001ffffffffffffff0100ff01000000fe"))
        end
        return
    elseif messageType == "error" then
        log.ef("TourBox serial error: %s", tostring(message))

        --------------------------------------------------------------------------------
        -- Close & schedule a reconnect with backoff:
        --------------------------------------------------------------------------------
        if mod.tourBox then
            pcall(function() mod.tourBox:close() end)
            mod.tourBox = nil
        end
        scheduleReconnect(mod._lastPortName)
    else
        if messageHexString then
            messageHexString = messageHexString:gsub("%s+", ""):lower()
            --log.df("RX: %s", messageHexString)

            --------------------------------------------------------------------------------
            -- TourBox Elite ACK: if we receive a 28-byte report, respond with 27-byte ACK:
            --------------------------------------------------------------------------------
            if mod._device and mod._device.name == "TourBox Elite" then
                local ackHex = makeEliteAckFromReportHex(messageHexString)
                if ackHex then
                    mod.tourBox:sendData(hexToBytes(ackHex))
                    --log.df("TX(ack): %s", ackHex)
                end
            end

            processHexReport(messageHexString)
        else
            log.wf("TourBox messageHexString was nil (type=%s)", tostring(messageType))
        end
    end
end

--- plugins.core.tourbox.manager.setHaptics(enabled[, strength[, speed]]) -> none
--- Function
--- Enables/disables haptics on the TourBox Elite by sending the haptics config map.
---
--- Parameters:
---  * enabled  - boolean
---  * strength - 0(off), 1(weak), 2(strong)   (default: 2)
---  * speed    - 0(fast), 1(medium), 2(slow)  (default: 1)
---
--- Returns:
---  * None
function mod.setHaptics(enabled, strength, speed)
    --------------------------------------------------------------------------------
    -- Only meaningful for Elite + connected:
    --------------------------------------------------------------------------------
    if not (mod._device and mod._device.name == "TourBox Elite") then return end
    if not (mod.tourBox and mod.tourBox.isOpen and mod.tourBox:isOpen()) then return end

    strength = tonumber(strength) or 2
    speed    = tonumber(speed) or 1

    local theStrength = 0x00
    if enabled then
        if strength == 1 then
            theStrength = 0x04
        elseif strength == 2 then
            theStrength = 0x08
        end
    end

    local theSpeed = 0x00
    if enabled then
        if speed == 1 then
            theSpeed = 0x01
        elseif speed == 2 then
            theSpeed = 0x02
        end
    end

    local h = buildEliteHapticsHex(theStrength, theSpeed)
    if h then
        mod.tourBox:sendData(hexToBytes(h))
        --log.df("TX(haptics): enabled=%s strength=%d speed=%d hex=%s", tostring(enabled), strength, speed, h)
    end
end

--- plugins.core.tourbox.manager.updateHaptics() -> none
--- Function
--- Updates TourBox Elite Haptics
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.updateHaptics()
    local enableHaptics = mod.enableHaptics()
    local hapticsStrength = mod.hapticsStrength()
    local hapticsSpeed = mod.hapticsSpeed()
    mod.setHaptics(enableHaptics, hapticsStrength, hapticsSpeed)
end

--- plugins.core.tourbox.manager.connectToTourBox([portName]) -> none
--- Function
--- Attempts to establish the TourBox serial connection.
---
--- Parameters:
---  * portName - The optional port name of the device.
---
--- Returns:
---  * None
function mod.connectToTourBox(portName)

    if mod._connecting then return end
    mod._connecting = true

    local availablePortDetails = serial.availablePortDetails()
    --local availablePortNames = serial.availablePortNames()

    --log.df("TourBox connect attempt. portName=%s. %d serial ports found.", tostring(portName), #availablePortNames)

    --[[
    for _, n in pairs(availablePortNames) do
        local d = availablePortDetails[n]
        if d then
            log.df("Serial port: %s vid=%s pid=%s manufacturer=%s product=%s",
                tostring(n),
                tostring(d.idVendor),
                tostring(d.idProduct),
                tostring(d.manufacturer),
                tostring(d.productName))
        else
            log.df("Serial port: %s (no details)", tostring(n))
        end
    end
    --]]

    if not portName then
        local availablePortNames = serial.availablePortNames()
        for _, currentPortName in pairs(availablePortNames) do
            local portDetails = availablePortDetails[currentPortName]
            local dev = matchingDevice(portDetails)
            if dev then
                portName = currentPortName
                mod._device = dev
                break
            end
        end
    else
        --------------------------------------------------------------------------------
        -- If caller passed portName, still detect device from details:
        --------------------------------------------------------------------------------
        mod._device = matchingDevice(availablePortDetails[portName])
        if not mod._device then
            log.wf("No matching TourBox serial device found for portName=%s", tostring(portName))
        end
    end

    mod._lastPortName = portName

    if not portName then
        mod._connecting = false
        return
    end

    --------------------------------------------------------------------------------
    -- If we already have an object and it's open, don't reopen:
    --------------------------------------------------------------------------------
    if mod.tourBox and mod.tourBox.isOpen and mod.tourBox:isOpen() then
        mod._retryDelay = 0.25
        mod._connecting = false
        return
    end

    --------------------------------------------------------------------------------
    -- Always close/discard stale object before creating/opening again:
    --------------------------------------------------------------------------------
    if mod.tourBox then
        pcall(function() mod.tourBox:close() end)
        mod.tourBox = nil
    end

    local tourBox = serial.newFromName(portName)
    if not tourBox then
        mod._connecting = false
        scheduleReconnect(portName)
        return
    end

    mod.resetTimers()
    tourBox:baudRate(BAUD_RATE):parity("none"):callback(tourBoxCallback)

    local ok = pcall(function() tourBox:open() end)
    if ok then
        mod.tourBox = tourBox
        mod._retryDelay = 0.25
        mod._connecting = false
    else
        mod._connecting = false
        scheduleReconnect(portName)
    end

end

-- deviceCallback(callbackType, devices) -> none
-- Function
-- The hs.serial device callback.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function deviceCallback(callbackType, devices)
    if callbackType == "connected" then
        local availablePortDetails = serial.availablePortDetails()
        for _, portName in pairs(devices) do
            local portDetails = availablePortDetails[portName]
            local dev = matchingDevice(portDetails)
            if dev then
                mod._device = dev
                mod.connectToTourBox(portName)
            end
        end
    end
end

--- plugins.core.tourbox.manager.resetTimers() -> none
--- Function
--- Resets all the various timers and memories.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.resetTimers()
    doubleClickInProgress = {}

    for _, v in pairs(repeatTimers) do
        v:stop()
    end
    repeatTimers = {}

    for _, v in pairs(delayTimers) do
        v:stop()
    end
    delayTimers = {}

    ignoreNextReleaseAction = {}
end

--- plugins.core.tourbox.manager.enabled <cp.prop: boolean>
--- Field
--- Is TourBox support enabled?
mod.enabled = config.prop("tourbox.enabled", false):watch(function(enabled)
    if enabled then
        mod._appWatcher = appWatcher.new(function(_, event)
            if event == appWatcher.activated then
                local frontmostApplication = application.frontmostApplication()
                cachedBundleID = frontmostApplication:bundleID()
                mod.resetTimers()
            end
        end):start()
        mod.deviceWatcher = serial.deviceCallback(deviceCallback)
        mod.connectToTourBox()

        --------------------------------------------------------------------------------
        -- Check again in 5 seconds, just case TourBox Console took a while to close:
        --------------------------------------------------------------------------------
        doAfter(5, mod.connectToTourBox)
    else
        mod.deviceWatcher = nil
        if mod._appWatcher then
            mod._appWatcher:stop()
            mod._appWatcher = nil
        end
        if mod.tourBox then
            mod.tourBox:close()
            mod.tourBox = nil
        end

        mod.resetTimers()

        collectgarbage()
        collectgarbage()
    end
end)

-- defaultLayoutPath -> string
-- Variable
-- Default Layout Path
local defaultLayoutPath = config.basePath .. "/plugins/core/tourbox/default/Default.cpTourBox"

--- plugins.core.tourbox.manager.defaultLayout -> table
--- Variable
--- Default TourBox Layout
mod.defaultLayout = json.read(defaultLayoutPath)

--- plugins.core.tourbox.manager.automaticallySwitchApplications <cp.prop: boolean>
--- Field
--- Enable or disable the automatic switching of applications.
mod.automaticallySwitchApplications = config.prop("tourbox.automaticallySwitchApplications", false)

--- plugins.core.tourbox.manager.displayMessageWhenChangingBanks <cp.prop: boolean>
--- Field
--- Display message when changing banks?
mod.displayMessageWhenChangingBanks = config.prop("tourbox.displayMessageWhenChangingBanks", true)

--- plugins.core.tourbox.manager.enableHaptics <cp.prop: boolean>
--- Field
--- Enable Haptics on TourBox Elite
mod.enableHaptics = config.prop("tourbox.enableHaptics", true):watch(mod.updateHaptics)

--- plugins.core.tourbox.manager.hapticsStrength <cp.prop: number>
--- Field
--- Haptics Strength
mod.hapticsStrength = config.prop("tourbox.hapticsStrength", 2):watch(mod.updateHaptics)

--- plugins.core.tourbox.manager.hapticsSpeed <cp.prop: number>
--- Field
--- Haptics Speed
mod.hapticsSpeed = config.prop("tourbox.hapticsSpeed", 1):watch(mod.updateHaptics)

--- plugins.core.tourbox.manager.automaticallySwitchApplications <cp.prop: boolean>
--- Field
--- Enable or disable the automatic switching of applications.
mod.lastBundleID = config.prop("tourbox.lastBundleID", "All Applications")

--- plugins.core.tourbox.manager.items <cp.prop: table>
--- Field
--- Contains all the saved TourBox layouts.
mod.items = json.prop(config.userConfigRootPath, "TourBox", defaultFilename, mod.defaultLayout)

--- plugins.core.tourbox.manager.activeBanks <cp.prop: table>
--- Field
--- Table of active banks for each application.
mod.activeBanks = config.prop("tourbox.activeBanks", {})

--- plugins.core.tourbox.manager.reset()
--- Function
--- Resets the config back to the default layout.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.reset()
    mod.items(mod.defaultLayout)
end

local plugin = {
    id          = "core.tourbox.manager",
    group       = "core",
    required    = true,
    dependencies    = {
        ["core.action.manager"]             = "actionmanager",
        ["core.application.manager"]        = "appmanager",
        ["core.controlsurfaces.manager"]    = "csman",
        ["core.commands.global"]            = "global",
    }
}

function plugin.init(deps, env)
    --------------------------------------------------------------------------------
    -- Link to dependancies:
    --------------------------------------------------------------------------------
    mod._actionmanager = deps.actionmanager

    --------------------------------------------------------------------------------
    -- TourBox Icon:
    --------------------------------------------------------------------------------
    local tourBoxIcon = imageFromPath(env:pathToAbsolute("/../prefs/images/TourBox.icns"))

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    local global = deps.global
    global
        :add("enableTourBox")
        :whenActivated(function()
            mod.enabled(true)
        end)
        :groupedBy("commandPost")
        :image(tourBoxIcon)
        :titled(i18n("enableTourBoxSupport"))

    global
        :add("disableTourBox")
        :whenActivated(function()
            mod.enabled(false)
        end)
        :groupedBy("commandPost")
        :image(tourBoxIcon)
        :titled(i18n("disableTourBoxSupport"))

    global
        :add("toggleTourBox")
        :whenActivated(function()
            mod.enabled:toggle()
        end)
        :groupedBy("commandPost")
        :image(tourBoxIcon)
        :titled(i18n("toggleTourBoxSupport"))

    global
        :add("disableTourBoxAndLaunchTourBoxConsole")
        :whenActivated(function()
            mod.enabled(false)
            launchOrFocusByBundleID(TOURBOX_CONSOLE_BUNDLE_ID)
        end)
        :groupedBy("commandPost")
        :image(tourBoxIcon)
        :titled(i18n("disableTourBoxAndLaunchTourBoxConsole"))

    global
        :add("enableTourBoxSupportQuitTourBoxConsole")
        :whenActivated(function()
            local apps = applicationsForBundleID(TOURBOX_CONSOLE_BUNDLE_ID)
            if apps then
                for _, app in pairs(apps) do
                    app:kill9()
                end
            end
            mod.enabled(true)
        end)
        :groupedBy("commandPost")
        :image(tourBoxIcon)
        :titled(i18n("enableTourBoxSupportQuitTourBoxConsole"))

    --------------------------------------------------------------------------------
    -- Setup Bank Actions:
    --------------------------------------------------------------------------------
    local actionmanager = deps.actionmanager
    local numberOfBanks = deps.csman.NUMBER_OF_BANKS
    actionmanager.addHandler("global_tourbox_banks")
        :onChoices(function(choices)
            for i=1, numberOfBanks do
                choices
                    :add(i18n("tourBox") .. " " .. i18n("bank") .. " " .. tostring(i))
                    :subText(i18n("tourBoxBankDescription"))
                    :params({ id = i })
                    :id(i)
                    :image(tourBoxIcon)
            end

            choices
                :add(i18n("next") .. " " .. i18n("tourBox") .. " " .. i18n("bank"))
                :subText(i18n("tourBoxBankDescription"))
                :params({ id = "next" })
                :id("next")
                :image(tourBoxIcon)

            choices:add(i18n("previous") .. " " .. i18n("tourBox") .. " " .. i18n("bank"))
                :subText(i18n("tourBoxBankDescription"))
                :params({ id = "previous" })
                :id("previous")
                :image(tourBoxIcon)

            return choices
        end)
        :onExecute(function(result)
            if result and result.id then

                local frontmostApplication = application.frontmostApplication()
                local bundleID = frontmostApplication:bundleID()

                local items = mod.items()

                --------------------------------------------------------------------------------
                -- Revert to "All Applications" if no settings for frontmost app exist:
                --------------------------------------------------------------------------------
                if not items[bundleID] then
                    bundleID = "All Applications"
                end

                --------------------------------------------------------------------------------
                -- Ignore if ignored:
                --------------------------------------------------------------------------------
                if items[bundleID].ignore and items[bundleID].ignore == true then
                    bundleID = "All Applications"
                end

                --------------------------------------------------------------------------------
                -- If not Automatically Switching Applications:
                --------------------------------------------------------------------------------
                if not mod.automaticallySwitchApplications() then
                    bundleID = mod.lastBundleID()
                end

                local activeBanks = mod.activeBanks()
                local currentBank = activeBanks[bundleID] and tonumber(activeBanks[bundleID]) or 1

                if type(result.id) == "number" then
                    activeBanks[bundleID] = tostring(result.id)
                else
                    if result.id == "next" then
                        if currentBank == numberOfBanks then
                            activeBanks[bundleID] = "1"
                        else
                            activeBanks[bundleID] = tostring(currentBank + 1)
                        end
                    elseif result.id == "previous" then
                        if currentBank == 1 then
                            activeBanks[bundleID] = tostring(numberOfBanks)
                        else
                            activeBanks[bundleID] = tostring(currentBank - 1)
                        end
                    end
                end

                mod.activeBanks(activeBanks)

                --------------------------------------------------------------------------------
                -- Reset any timers:
                --------------------------------------------------------------------------------
                mod.resetTimers()

                --------------------------------------------------------------------------------
                -- Display a notification if enabled:
                --------------------------------------------------------------------------------
                if mod.displayMessageWhenChangingBanks() then
                    local newBank = activeBanks[bundleID]
                    items = mod.items() -- Reload items
                    local label = items[bundleID] and items[bundleID][newBank] and items[bundleID][newBank]["bankLabel"]
                    if label then
                        displayNotification(label)
                    else
                        displayNotification(i18n("tourBox") .. " " .. i18n("bank") .. ": " .. newBank)
                    end
                end
            end
        end)
        :onActionId(function(action) return "tourBoxBank" .. action.id end)

    --------------------------------------------------------------------------------
    -- Shutdown Callback (make screen black):
    --------------------------------------------------------------------------------
    config.shutdownCallback:new("tourBox", function()
        log.df("Shutting down TourBox...")
        if mod.tourBox then
            mod.tourBox:close()
            mod.tourBox = nil
        end
    end)

    return mod
end

function plugin.postInit()
    --------------------------------------------------------------------------------
    -- Connect to the TourBox:
    --------------------------------------------------------------------------------
    mod.enabled:update()
end

return plugin