--- === plugins.core.loupedeckct.manager ===
---
--- Loupedeck CT Manager Plugin.

--[[

TODO LIST:

    [x] Fix bug when dragging and dropping icon
    [ ] Rework code so that we don't have to use lookup tables (for performance)
    [ ] Rework code so that we only send data to the screens if we need to update it
    [ ] "Choose Icon" chooser should remember last path
    [ ] Implement Reset buttons
    [ ] Add controls for Touch Wheel (left/right/up/down)
    [x] Add controls for Jog Wheel (left/right)
    [ ] Add controls for left and right screens
    [ ] Add controls for vibration
    [ ] Add actions for bank controls
    [ ] Add support for Fn keys as modifiers
    [ ] Add support for custom applications
    [ ] Add checkbox to enable/disable the hard drive support
    [ ] Add button to apply the same action of selected control to all banks
    [ ] Right click on image drop zone to show popup with a list of recent imported images

--]]

local require         = require

local log             = require "hs.logger".new "ldCT"

local application     = require "hs.application"
local appWatcher      = require "hs.application.watcher"
local ct              = require "hs.loupedeckct"
local drawing         = require "hs.drawing"
local image           = require "hs.image"
local timer           = require "hs.timer"
local utf8            = require "hs.utf8"

local config          = require "cp.config"
local json            = require "cp.json"

local doAfter         = timer.doAfter
local hexDump         = utf8.hexDump
local imageFromPath   = image.imageFromPath
local imageFromURL    = image.imageFromURL
local black           = drawing.color.hammerspoon.black

local mod = {}

mod.vibrations = config.prop("loupedeckct.vibrations", true):watch(function(enabled)
    ct.vibrations(enabled)
end)

mod.enabled = config.prop("loupedeckct.enabled", true):watch(function(enabled)
    if enabled then
        --log.df("Connecting to Loupedeck CT")
        ct.connect(true)
        mod._appWatcher:start()
    else
        --log.df("Disconnecting from Loupedeck CT")
        ct.disconnect()
        mod._appWatcher:stop()
    end
end)

--- plugins.core.loupedeckct.prefs.items <cp.prop: table>
--- Field
--- Contains all the saved Loupedeck CT data
mod.items = json.prop(config.userConfigRootPath, "Loupedeck CT", "Default.cpLoupedeckCT", {})

mod.activeBanks = config.prop("loupedeckct.activeBanks", {})

local translateButtons = {
    [0]                         = "Jog Wheel",
    [1]                         = "Knob 1",
    [2]                         = "Knob 2",
    [3]                         = "Knob 3",
    [4]                         = "Knob 4",
    [5]                         = "Knob 5",
    [6]                         = "Knob 6",
    [ct.buttonID.B1]            = "1",
    [ct.buttonID.B2]            = "2",
    [ct.buttonID.B3]            = "3",
    [ct.buttonID.B4]            = "4",
    [ct.buttonID.B5]            = "5",
    [ct.buttonID.B6]            = "6",
    [ct.buttonID.B7]            = "7",
    [ct.buttonID.B8]            = "8",
    [ct.buttonID.O]             = "O",
    [ct.buttonID.UNDO]          = "Undo",
    [ct.buttonID.KEYBOARD]      = "Keyboard",
    [ct.buttonID.RETURN]        = "Return",
    [ct.buttonID.SAVE]          = "Save",
    [ct.buttonID.LEFT_FN]       = "Fn (Left)",
    [ct.buttonID.RIGHT_FN]      = "Fn (Right)",
    [ct.buttonID.A]             = "A",
    [ct.buttonID.B]             = "B",
    [ct.buttonID.C]             = "C",
    [ct.buttonID.D]             = "D",
    [ct.buttonID.E]             = "E",
}

local buttonsWithLEDs = {
    ["1"]                       = ct.buttonID.B1,
    ["2"]                       = ct.buttonID.B2,
    ["3"]                       = ct.buttonID.B3,
    ["4"]                       = ct.buttonID.B4,
    ["5"]                       = ct.buttonID.B5,
    ["6"]                       = ct.buttonID.B6,
    ["7"]                       = ct.buttonID.B7,
    ["8"]                       = ct.buttonID.B8,
    ["O"]                       = ct.buttonID.O,
    ["Undo"]                    = ct.buttonID.UNDO,
    ["Keyboard"]                = ct.buttonID.KEYBOARD,
    ["Return"]                  = ct.buttonID.RETURN,
    ["Save"]                    = ct.buttonID.SAVE,
    ["Fn (Left)"]               = ct.buttonID.LEFT_FN,
    ["Fn (Right)"]              = ct.buttonID.RIGHT_FN,
    ["A"]                       = ct.buttonID.A,
    ["B"]                       = ct.buttonID.B,
    ["C"]                       = ct.buttonID.C,
    ["D"]                       = ct.buttonID.D,
    ["E"]                       = ct.buttonID.E,
}

function mod.refresh()
    local items = mod.items()

    local frontmostApplication = application.frontmostApplication()
    local bundleID = frontmostApplication:bundleID()

    local activeBanks = mod.activeBanks()
    local bank = activeBanks[bundleID] or "1"

    --------------------------------------------------------------------------------
    -- SET LED BUTTON COLOURS:
    --------------------------------------------------------------------------------
    for id, realID in pairs(buttonsWithLEDs) do
        if items[bundleID] and items[bundleID][bank] and items[bundleID][bank][id] and items[bundleID][bank][id]["LED"] then
            ct.buttonColor(realID, {hex="#" .. items[bundleID][bank][id]["LED"]})
        else
            ct.buttonColor(realID, {hex="#000000"})
        end
    end

    --------------------------------------------------------------------------------
    -- SET TOUCH SCREEN BUTTON IMAGES:
    --------------------------------------------------------------------------------
    ct.updateScreenColor(ct.screens.middle, black)
    if items[bundleID] and items[bundleID][bank] and items[bundleID][bank] then
        for label, v in pairs(items[bundleID][bank]) do
            if label and label:sub(1, 7) == "Button " then
                local buttonID = tonumber(label:sub(8))
                local encodedIcon = v["encodedIcon"]
                local success = false
                if encodedIcon then
                    local decodedImage = imageFromURL(encodedIcon)
                    if decodedImage then
                        ct.updateScreenButtonImage(buttonID, decodedImage)
                        success = true
                    end
                end
                if not success then
                    ct.updateScreenButtonColor(buttonID, black)
                end
            end
        end
    end

    --------------------------------------------------------------------------------
    -- TEMPORARY PLACEHOLDER:
    --------------------------------------------------------------------------------
    ct.updateScreenImage(ct.screens.wheel, imageFromPath(config.assetsPath .. "/wheel.png"))
    ct.updateScreenColor(ct.screens.left, drawing.color.hammerspoon.red)
    ct.updateScreenColor(ct.screens.right, drawing.color.hammerspoon.red)

end

local function callback(data)
    --log.df("ct data: %s", hs.inspect(data))

    --------------------------------------------------------------------------------
    -- REFRESH ON INITIAL LOAD:
    --------------------------------------------------------------------------------
    if data.action == "websocket_open" then
        mod.refresh()
        return
    end

    local frontmostApplication = application.frontmostApplication()
    local bundleID = frontmostApplication:bundleID()

    local items = mod.items()

    local activeBanks = mod.activeBanks()
    local bank = activeBanks[bundleID] or "1"

    if items[bundleID] and items[bundleID][bank] then
        if data.id == ct.event.BUTTON_PRESS and data.direction == "down" then
            --------------------------------------------------------------------------------
            -- BUTTON PRESS:
            --------------------------------------------------------------------------------
            local button = translateButtons[data.buttonID]
            if items[bundleID][bank][button] and items[bundleID][bank][button]["Press"] then
                local handlerID = items[bundleID][bank][button]["Press"]["handlerID"]
                local action = items[bundleID][bank][button]["Press"]["action"]
                if handlerID and action then
                    local handler = mod._actionmanager.getHandler(handlerID)
                    handler:execute(action)
                end
            end
        elseif data.id == ct.event.ENCODER_MOVE then
            if data.direction == "left" then
                --------------------------------------------------------------------------------
                -- TURN KNOB LEFT:
                --------------------------------------------------------------------------------
                local button = translateButtons[data.buttonID]
                if items[bundleID][bank][button] and items[bundleID][bank][button]["Left"] then
                    local handlerID = items[bundleID][bank][button]["Left"]["handlerID"]
                    local action = items[bundleID][bank][button]["Left"]["action"]
                    if handlerID and action then
                        local handler = mod._actionmanager.getHandler(handlerID)
                        handler:execute(action)
                    end
                end
            elseif data.direction == "right" then
                --------------------------------------------------------------------------------
                -- TURN KNOB RIGHT:
                --------------------------------------------------------------------------------
                local button = translateButtons[data.buttonID]
                if items[bundleID][bank][button] and items[bundleID][bank][button]["Right"] then
                    local handlerID = items[bundleID][bank][button]["Right"]["handlerID"]
                    local action = items[bundleID][bank][button]["Right"]["action"]
                    if handlerID and action then
                        local handler = mod._actionmanager.getHandler(handlerID)
                        handler:execute(action)
                    end
                end
            end
        elseif data.id == ct.event.WHEEL_PRESSED then
            log.df("Wheel not yet implimented: %s", hs.inspect(data))
        elseif data.id == ct.event.SCREEN_PRESSED then
            --------------------------------------------------------------------------------
            -- TOUCH SCREEN BUTTON PRESS:
            --------------------------------------------------------------------------------
            local button = data.buttonID
            if button and items[bundleID][bank]["Button " .. button] and items[bundleID][bank]["Button " .. button]["Press"] then
                local handlerID = items[bundleID][bank]["Button " .. button]["Press"]["handlerID"]
                local action = items[bundleID][bank]["Button " .. button]["Press"]["action"]
                if handlerID and action then
                    local handler = mod._actionmanager.getHandler(handlerID)
                    handler:execute(action)
                end
            end
        end

    end
end

local plugin = {
    id          = "core.loupedeckct.manager",
    group       = "core",
    required    = true,
    dependencies    = {
        ["core.action.manager"]             = "actionmanager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Link to dependancies:
    --------------------------------------------------------------------------------
    mod._actionmanager = deps.actionmanager

    --------------------------------------------------------------------------------
    -- Setup the Loupedeck CT callback:
    --------------------------------------------------------------------------------
    ct.callback(callback)

    --------------------------------------------------------------------------------
    -- Setup watch to refresh the Loupedeck CT when apps change focus:
    --------------------------------------------------------------------------------
    mod._appWatcher = appWatcher.new(function()
        mod.refresh()
    end)

    --------------------------------------------------------------------------------
    -- Connect to the Loupedeck CT:
    --------------------------------------------------------------------------------
    mod.enabled:update()

    return mod
end

return plugin
