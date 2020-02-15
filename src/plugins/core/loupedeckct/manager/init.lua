--- === plugins.core.loupedeckct.manager ===
---
--- Loupedeck CT Manager Plugin.

--[[

DONE:

    [x] Fix bug when dragging and dropping icon
    [x] Rework code so that we don't have to use lookup tables (for performance)
    [x] Rework code so that we only send data to the screens if we need to update it
    [x] Add controls for Jog Wheel (left/right)
    [x] Add controls for left and right screens
    [x] Implement Reset buttons
    [x] "Choose Icon" chooser should remember last path
    [x] Add controls for Touch Wheel (left/right/up/down)
    [x] Add support for Fn keys as modifiers
    [x] Add actions for bank controls

TO-DO:

    [ ] Add controls for vibration
    [ ] Add Touch Wheel action for two finger tap (or just double tap?)

    [ ] Improve Left/Right/Up/Down Touch Screen Action Performance/Usability

    [ ] Add support for custom applications

    [ ] Add button to apply the same action of selected control to all banks
    [ ] Right click on image drop zone to show popup with a list of recent imported images

    [ ] Add checkbox to enable/disable the hard drive support
    [ ] Add checkbox to enable/disable Bluetooth support
--]]

local require               = require

--local log                   = require "hs.logger".new "ldCT"

local application           = require "hs.application"
local appWatcher            = require "hs.application.watcher"
local ct                    = require "hs.loupedeckct"
local drawing               = require "hs.drawing"
local image                 = require "hs.image"
local timer                 = require "hs.timer"

local config                = require "cp.config"
local deferred              = require "cp.deferred"
local dialog                = require "cp.dialog"
local i18n                  = require "cp.i18n"
local json                  = require "cp.json"

local black                 = drawing.color.hammerspoon.black
local displayNotification   = dialog.displayNotification
local doAfter               = timer.doAfter
local imageFromURL          = image.imageFromURL

local mod = {}

-- leftFnPressed -> boolean
-- Variable
-- Is the left Function button pressed?
local leftFnPressed = false

-- rightFnPressed -> boolean
-- Variable
-- Is the right Function button pressed?
local rightFnPressed = false

-- cachedLEDButtonValues -> table
-- Variable
-- Table of cached LED button values.
local cachedLEDButtonValues = {}

-- cachedTouchScreenButtonValues -> table
-- Variable
-- Table of cached Touch Screen button values.
local cachedTouchScreenButtonValues = {}

-- cachedWheelScreen -> string
-- Variable
-- The last wheel screen data sent.
local cachedWheelScreen = ""

-- cachedLeftSideScreen -> string
-- Variable
-- The last screen data sent.
local cachedLeftSideScreen = ""

-- cachedRightSideScreen -> string
-- Variable
-- The last screen data sent.
local cachedRightSideScreen = ""

-- cachedTouchScreenButtonValues -> string
-- Variable
-- The last bundle ID processed.
local cachedBundleID = ""

--- plugins.core.loupedeckct.manager.numberOfBanks -> number
--- Field
--- Number of banks
mod.numberOfBanks = 9

--- plugins.core.loupedeckct.manager.enabled <cp.prop: boolean>
--- Field
--- Is Loupedeck CT support enabled?
mod.enabled = config.prop("loupedeckct.enabled", true):watch(function(enabled)
    if enabled then
        ct.connect(true)
        mod._appWatcher:start()
    else
        ct.disconnect()
        mod._appWatcher:stop()
    end
end)

--- plugins.core.loupedeckct.manager.items <cp.prop: table>
--- Field
--- Contains all the saved Loupedeck CT layouts.
mod.items = json.prop(config.userConfigRootPath, "Loupedeck CT", "Default.cpLoupedeckCT", {})

--- plugins.core.loupedeckct.manager.activeBanks <cp.prop: table>
--- Field
--- Table of active banks for each application.
mod.activeBanks = config.prop("loupedeckct.activeBanks", {})

--- plugins.core.loupedeckct.manager.refresh()
--- Function
--- Refreshes the Loupedeck CT screens and LED buttons.
---
--- Parameters:
---  * dueToAppChange - A optional boolean to specify whether the refresh is due to
---                     an application focus change.
---
--- Returns:
---  * None
function mod.refresh(dueToAppChange)
    local success
    local frontmostApplication = application.frontmostApplication()
    local bundleID = frontmostApplication:bundleID()

    --------------------------------------------------------------------------------
    -- If we're refreshing due to an change in application focus, make sure things
    -- have actually changed:
    --------------------------------------------------------------------------------
    if dueToAppChange and bundleID == cachedBundleID then
        cachedBundleID = bundleID
        return
    else
        cachedBundleID = bundleID
    end

    local items = mod.items()

    local activeBanks = mod.activeBanks()
    local bank = activeBanks[bundleID] or "1"

    --------------------------------------------------------------------------------
    -- TREAT LEFT & RIGHT FUNCTION KEYS AS MODIFIERS:
    --------------------------------------------------------------------------------
    if leftFnPressed then
        bank = bank .. "_LeftFn"
    elseif rightFnPressed then
        bank = bank .. "_RightFn"
    end

    --------------------------------------------------------------------------------
    -- SET LED BUTTON COLOURS:
    --------------------------------------------------------------------------------
    for i=7, 26 do
        local id = tostring(i)
        if items[bundleID] and items[bundleID][bank] and items[bundleID][bank]["ledButton"] and items[bundleID][bank]["ledButton"][id] and items[bundleID][bank]["ledButton"][id]["led"] then
            local value = items[bundleID][bank]["ledButton"][id]["led"]
            if cachedLEDButtonValues[id] ~= value then
                --------------------------------------------------------------------------------
                -- Only update if the colour has changed to save bandwidth:
                --------------------------------------------------------------------------------
                ct.buttonColor(i, {hex="#" .. value})
            end
            cachedLEDButtonValues[id] = value
        else
            if cachedLEDButtonValues[id] ~= "black" then
                --------------------------------------------------------------------------------
                -- Only update if the colour has changed to save bandwidth:
                --------------------------------------------------------------------------------
                ct.buttonColor(i, black)
            end
            cachedLEDButtonValues[id] = "black"
        end
    end

    --------------------------------------------------------------------------------
    -- SET TOUCH SCREEN BUTTON IMAGES:
    --------------------------------------------------------------------------------
    for i=1, 12 do
        local id = tostring(i)
        success = false
        if items[bundleID] and items[bundleID][bank] and items[bundleID][bank]["touchButton"] and items[bundleID][bank]["touchButton"][id] and items[bundleID][bank]["touchButton"][id]["encodedIcon"] then
            local encodedIcon = items[bundleID][bank]["touchButton"][id]["encodedIcon"]
            if encodedIcon then
                local decodedImage = imageFromURL(encodedIcon)
                if decodedImage then
                    --------------------------------------------------------------------------------
                    -- Only update if the screen has changed to save bandwidth:
                    --------------------------------------------------------------------------------
                    if cachedTouchScreenButtonValues[id] ~= decodedImage then
                        ct.updateScreenButtonImage(i, decodedImage)
                    end
                    success = true
                    cachedTouchScreenButtonValues[id] = decodedImage
                end
            end
        end
        if not success then
            --------------------------------------------------------------------------------
            -- Only update if the screen has changed to save bandwidth:
            --------------------------------------------------------------------------------
            if cachedTouchScreenButtonValues[id] ~= "black" then
                ct.updateScreenButtonColor(i, black)
            end
            cachedTouchScreenButtonValues[id] = "black"
        end
    end

    --------------------------------------------------------------------------------
    -- SET WHEEL SCREEN:
    --------------------------------------------------------------------------------
    success = false
    if items[bundleID] and items[bundleID][bank] and items[bundleID][bank]["wheelScreen"] and items[bundleID][bank]["wheelScreen"]["1"] and items[bundleID][bank]["wheelScreen"]["1"]["encodedIcon"] then
        local encodedIcon = items[bundleID][bank]["wheelScreen"]["1"]["encodedIcon"]
        if encodedIcon then
            local decodedImage = imageFromURL(encodedIcon)
            if decodedImage then
                --------------------------------------------------------------------------------
                -- Only update if the screen has changed to save bandwidth:
                --------------------------------------------------------------------------------
                if cachedWheelScreen ~= decodedImage then
                    ct.updateScreenImage(ct.screens.wheel, decodedImage)
                end
                success = true
                cachedWheelScreen = decodedImage
            end
        end
    end
    if not success then
        --------------------------------------------------------------------------------
        -- Only update if the screen has changed to save bandwidth:
        --------------------------------------------------------------------------------
        if cachedWheelScreen ~= "black" then
            ct.updateScreenColor(ct.screens.wheel, black)
        end
        cachedWheelScreen = "black"
    end

    --------------------------------------------------------------------------------
    -- SET LEFT SIDE SCREEN:
    --------------------------------------------------------------------------------
    success = false
    if items[bundleID] and items[bundleID][bank] and items[bundleID][bank]["sideScreen"] and items[bundleID][bank]["sideScreen"]["1"] and items[bundleID][bank]["sideScreen"]["1"]["encodedIcon"] then
        local encodedIcon = items[bundleID][bank]["sideScreen"]["1"]["encodedIcon"]
        if encodedIcon then
            local decodedImage = imageFromURL(encodedIcon)
            if decodedImage then
                --------------------------------------------------------------------------------
                -- Only update if the screen has changed to save bandwidth:
                --------------------------------------------------------------------------------
                if cachedLeftSideScreen ~= decodedImage then
                    ct.updateScreenImage(ct.screens.left, decodedImage)
                end
                success = true
                cachedLeftSideScreen = decodedImage
            end
        end
    end
    if not success then
        --------------------------------------------------------------------------------
        -- Only update if the screen has changed to save bandwidth:
        --------------------------------------------------------------------------------
        if cachedLeftSideScreen ~= "black" then
            ct.updateScreenColor(ct.screens.left, black)
        end
        cachedLeftSideScreen = "black"
    end

    --------------------------------------------------------------------------------
    -- SET RIGHT SIDE SCREEN:
    --------------------------------------------------------------------------------
    success = false
    if items[bundleID] and items[bundleID][bank] and items[bundleID][bank]["sideScreen"] and items[bundleID][bank]["sideScreen"]["2"] and items[bundleID][bank]["sideScreen"]["2"]["encodedIcon"] then
        local encodedIcon = items[bundleID][bank]["sideScreen"]["2"]["encodedIcon"]
        if encodedIcon then
            local decodedImage = imageFromURL(encodedIcon)
            if decodedImage then
                --------------------------------------------------------------------------------
                -- Only update if the screen has changed to save bandwidth:
                --------------------------------------------------------------------------------
                if cachedRightSideScreen ~= decodedImage then
                    ct.updateScreenImage(ct.screens.right, decodedImage)
                end
                success = true
                cachedRightSideScreen = decodedImage
            end
        end
    end
    if not success then
        --------------------------------------------------------------------------------
        -- Only update if the screen has changed to save bandwidth:
        --------------------------------------------------------------------------------
        if cachedRightSideScreen ~= "black" then
            ct.updateScreenColor(ct.screens.right, black)
        end
        cachedRightSideScreen = "black"
    end
end

--------------------------------------------------------------------------------
-- WHEEL:
--------------------------------------------------------------------------------
local cacheWheelYAxis = 0
local lastCacheWheelYAxis = 0

local cacheWheelXAxis = 0
local lastCacheWheelXAxis = 0

local wheelTouchUpAction = function() end
local wheelTouchDownAction = function() end

local wheelTouchLeftAction = function() end
local wheelTouchRightAction = function() end

local touchWheel = deferred.new(0.001):action(function()
    if lastCacheWheelYAxis > cacheWheelYAxis then
        wheelTouchUpAction()
    else
        wheelTouchDownAction()
    end

    if lastCacheWheelXAxis > cacheWheelXAxis then
        wheelTouchLeftAction()
    else
        wheelTouchRightAction()
    end

    lastCacheWheelYAxis = cacheWheelYAxis
    lastCacheWheelXAxis = cacheWheelXAxis
end)

--------------------------------------------------------------------------------
-- LEFT TOUCH SCREEN:
--------------------------------------------------------------------------------
local cacheLeftScreenYAxis = 0
local lastCacheLeftScreenYAxis = 0

local leftTouchScreenUpAction = function() end
local leftTouchScreenDownAction = function() end

local leftTouchScreen = deferred.new(0.001):action(function()
    if lastCacheLeftScreenYAxis == 0 then
        lastCacheLeftScreenYAxis = cacheLeftScreenYAxis
        return
    end

    if lastCacheLeftScreenYAxis > cacheLeftScreenYAxis then
        leftTouchScreenUpAction()
    else
        leftTouchScreenDownAction()
    end
    lastCacheLeftScreenYAxis = cacheLeftScreenYAxis
end)

--------------------------------------------------------------------------------
-- RIGHT TOUCH SCREEN:
--------------------------------------------------------------------------------
local cacheRightScreenYAxis = 0
local lastCacheRightScreenYAxis = 0

local rightTouchScreenUpAction = function() end
local rightTouchScreenDownAction = function() end

local rightTouchScreen = deferred.new(0.001):action(function()
    if lastCacheRightScreenYAxis == 0 then
        lastCacheRightScreenYAxis = cacheRightScreenYAxis
        return
    end

    if lastCacheRightScreenYAxis > cacheRightScreenYAxis then
        rightTouchScreenUpAction()
    else
        rightTouchScreenDownAction()
    end
    lastCacheRightScreenYAxis = cacheRightScreenYAxis
end)

-- callback(data) -> none
-- Function
-- The Loupedeck CT callback.
--
-- Parameters:
--  * data - The callback data.
--
-- Returns:
--  * None
local function callback(data)
    --log.df("ct data: %s", hs.inspect(data))

    --------------------------------------------------------------------------------
    -- REFRESH ON INITIAL LOAD AFTER A SLIGHT DELAY:
    --------------------------------------------------------------------------------
    if data.action == "websocket_open" then
        doAfter(0.5, mod.refresh)
        return
    end

    local frontmostApplication = application.frontmostApplication()
    local bundleID = frontmostApplication:bundleID()

    local items = mod.items()

    local activeBanks = mod.activeBanks()
    local bank = activeBanks[bundleID] or "1"

    local buttonID = tostring(data.buttonID)

    --------------------------------------------------------------------------------
    -- TREAT LEFT & RIGHT FUNCTION KEYS AS MODIFIERS:
    --------------------------------------------------------------------------------
    if data.id == ct.event.BUTTON_PRESS then
        if data.direction == "up" then
            if data.buttonID == ct.buttonID.LEFT_FN then
                leftFnPressed = false
                mod.refresh()
            elseif data.buttonID == ct.buttonID.RIGHT_FN then
                rightFnPressed = false
                mod.refresh()
            end
        elseif data.direction == "down" then
            if data.buttonID == ct.buttonID.LEFT_FN then
                leftFnPressed = true
                mod.refresh()
            elseif data.buttonID == ct.buttonID.RIGHT_FN then
                rightFnPressed = true
                mod.refresh()
            end
        end
    end

    --------------------------------------------------------------------------------
    -- HANDLE FUNCTION KEYS AS MODIFIERS:
    --------------------------------------------------------------------------------
    if leftFnPressed then
        bank = bank .. "_LeftFn"
    elseif rightFnPressed then
        bank = bank .. "_RightFn"
    end

    if items[bundleID] and items[bundleID][bank] then
        if data.id == ct.event.BUTTON_PRESS and data.direction == "down" then
            --------------------------------------------------------------------------------
            -- LED BUTTON PRESS:
            --------------------------------------------------------------------------------
            if items[bundleID][bank]["ledButton"] and items[bundleID][bank]["ledButton"][buttonID] and items[bundleID][bank]["ledButton"][buttonID]["pressAction"] then
                local item = items[bundleID][bank]["ledButton"][buttonID]["pressAction"]
                local handlerID = item["handlerID"]
                local action = item["action"]
                if handlerID and action then
                    local handler = mod._actionmanager.getHandler(handlerID)
                    handler:execute(action)
                    return
                end
            end

            --------------------------------------------------------------------------------
            -- KNOB BUTTON PRESS:
            --------------------------------------------------------------------------------
            if items[bundleID][bank]["knob"] and items[bundleID][bank]["knob"][buttonID] and items[bundleID][bank]["knob"][buttonID]["pressAction"] then
                local item = items[bundleID][bank]["knob"][buttonID]["pressAction"]
                local handlerID = item["handlerID"]
                local action = item["action"]
                if handlerID and action then
                    local handler = mod._actionmanager.getHandler(handlerID)
                    handler:execute(action)
                    return
                end
            end
        elseif data.id == ct.event.ENCODER_MOVE then
            if data.direction == "left" then
                --------------------------------------------------------------------------------
                -- TURN KNOB LEFT:
                --------------------------------------------------------------------------------
                if items[bundleID][bank]["knob"] and items[bundleID][bank]["knob"][buttonID] and items[bundleID][bank]["knob"][buttonID]["leftAction"] then
                    local item = items[bundleID][bank]["knob"][buttonID]["leftAction"]
                    local handlerID = item["handlerID"]
                    local action = item["action"]
                    if handlerID and action then
                        local handler = mod._actionmanager.getHandler(handlerID)
                        handler:execute(action)
                        return
                    end
                end

                --------------------------------------------------------------------------------
                -- TURN JOG WHEEL LEFT:
                --------------------------------------------------------------------------------
                if items[bundleID][bank]["jogWheel"] and items[bundleID][bank]["jogWheel"]["1"] and items[bundleID][bank]["jogWheel"]["1"]["leftAction"] then
                    local item = items[bundleID][bank]["jogWheel"]["1"]["leftAction"]
                    local handlerID = item["handlerID"]
                    local action = item["action"]
                    if handlerID and action then
                        local handler = mod._actionmanager.getHandler(handlerID)
                        handler:execute(action)
                        return
                    end
                end
            elseif data.direction == "right" then
                --------------------------------------------------------------------------------
                -- TURN KNOB RIGHT:
                --------------------------------------------------------------------------------
                if items[bundleID][bank]["knob"] and items[bundleID][bank]["knob"][buttonID] and items[bundleID][bank]["knob"][buttonID]["rightAction"] then
                    local item = items[bundleID][bank]["knob"][buttonID]["rightAction"]
                    local handlerID = item["handlerID"]
                    local action = item["action"]
                    if handlerID and action then
                        local handler = mod._actionmanager.getHandler(handlerID)
                        handler:execute(action)
                        return
                    end
                end

                --------------------------------------------------------------------------------
                -- TURN JOG WHEEL RIGHT:
                --------------------------------------------------------------------------------
                if items[bundleID][bank]["jogWheel"] and items[bundleID][bank]["jogWheel"]["1"] and items[bundleID][bank]["jogWheel"]["1"]["rightAction"] then
                    local item = items[bundleID][bank]["jogWheel"]["1"]["rightAction"]
                    local handlerID = item["handlerID"]
                    local action = item["action"]
                    if handlerID and action then
                        local handler = mod._actionmanager.getHandler(handlerID)
                        handler:execute(action)
                        return
                    end
                end
            end
        elseif data.id == ct.event.SCREEN_PRESSED then
            --------------------------------------------------------------------------------
            -- TOUCH SCREEN BUTTON PRESS:
            --------------------------------------------------------------------------------
            if items[bundleID][bank]["touchButton"] and items[bundleID][bank]["touchButton"][buttonID] and items[bundleID][bank]["touchButton"][buttonID]["pressAction"] then
                local item = items[bundleID][bank]["touchButton"][buttonID]["pressAction"]
                local handlerID = item["handlerID"]
                local action = item["action"]
                if handlerID and action then
                    local handler = mod._actionmanager.getHandler(handlerID)
                    handler:execute(action)
                    return
                end
            end


            if data.x < 50 then
                --------------------------------------------------------------------------------
                -- LEFT TOUCH SCREEN TOUCH UP:
                --------------------------------------------------------------------------------
                if items[bundleID][bank]["sideScreen"] and items[bundleID][bank]["sideScreen"]["1"] and items[bundleID][bank]["sideScreen"]["1"]["upAction"] then
                    leftTouchScreenUpAction = function()
                        local item = items[bundleID][bank]["sideScreen"]["1"]["upAction"]
                        local handlerID = item["handlerID"]
                        local action = item["action"]
                        if handlerID and action then
                            local handler = mod._actionmanager.getHandler(handlerID)
                            handler:execute(action)
                        end
                    end
                    cacheLeftScreenYAxis = data.y
                    leftTouchScreen()
                end

                --------------------------------------------------------------------------------
                -- LEFT TOUCH SCREEN TOUCH DOWN:
                --------------------------------------------------------------------------------
                if items[bundleID][bank]["sideScreen"] and items[bundleID][bank]["sideScreen"]["1"] and items[bundleID][bank]["sideScreen"]["1"]["downAction"] then
                    leftTouchScreenDownAction = function()
                        local item = items[bundleID][bank]["sideScreen"]["1"]["downAction"]
                        local handlerID = item["handlerID"]
                        local action = item["action"]
                        if handlerID and action then
                            local handler = mod._actionmanager.getHandler(handlerID)
                            handler:execute(action)
                        end
                    end
                    cacheLeftScreenYAxis = data.y
                    leftTouchScreen()
                end
            end

            if data.x > 400 then
                --------------------------------------------------------------------------------
                -- RIGHT TOUCH SCREEN TOUCH UP:
                --------------------------------------------------------------------------------
                if items[bundleID][bank]["sideScreen"] and items[bundleID][bank]["sideScreen"]["2"] and items[bundleID][bank]["sideScreen"]["2"]["upAction"] then
                    rightTouchScreenUpAction = function()
                        local item = items[bundleID][bank]["sideScreen"]["2"]["upAction"]
                        local handlerID = item["handlerID"]
                        local action = item["action"]
                        if handlerID and action then
                            local handler = mod._actionmanager.getHandler(handlerID)
                            handler:execute(action)
                        end
                    end
                    cacheRightScreenYAxis = data.y
                    rightTouchScreen()
                end

                --------------------------------------------------------------------------------
                -- RIGHT TOUCH SCREEN TOUCH DOWN:
                --------------------------------------------------------------------------------
                if items[bundleID][bank]["sideScreen"] and items[bundleID][bank]["sideScreen"]["2"] and items[bundleID][bank]["sideScreen"]["2"]["downAction"] then
                    rightTouchScreenDownAction = function()
                        local item = items[bundleID][bank]["sideScreen"]["2"]["downAction"]
                        local handlerID = item["handlerID"]
                        local action = item["action"]
                        if handlerID and action then
                            local handler = mod._actionmanager.getHandler(handlerID)
                            handler:execute(action)
                        end
                    end
                    cacheRightScreenYAxis = data.y
                    rightTouchScreen()
                end
            end
        elseif data.id == ct.event.SCREEN_RELEASED then
            cacheLeftScreenYAxis = 0
            cacheRightScreenYAxis = 0
        elseif data.id == ct.event.WHEEL_PRESSED then
            --------------------------------------------------------------------------------
            -- WHEEL TOUCH UP:
            --------------------------------------------------------------------------------
            if items[bundleID][bank]["wheelScreen"] and items[bundleID][bank]["wheelScreen"]["1"] and items[bundleID][bank]["wheelScreen"]["1"]["upAction"] then
                wheelTouchUpAction = function()
                    local item = items[bundleID][bank]["wheelScreen"]["1"]["upAction"]
                    local handlerID = item["handlerID"]
                    local action = item["action"]
                    if handlerID and action then
                        local handler = mod._actionmanager.getHandler(handlerID)
                        handler:execute(action)
                    end
                end
                cacheWheelYAxis = data.y
                touchWheel()
            end

            --------------------------------------------------------------------------------
            -- WHEEL TOUCH DOWN:
            --------------------------------------------------------------------------------
            if items[bundleID][bank]["wheelScreen"] and items[bundleID][bank]["wheelScreen"]["1"] and items[bundleID][bank]["wheelScreen"]["1"]["downAction"] then
                wheelTouchDownAction = function()
                    local item = items[bundleID][bank]["wheelScreen"]["1"]["downAction"]
                    local handlerID = item["handlerID"]
                    local action = item["action"]
                    if handlerID and action then
                        local handler = mod._actionmanager.getHandler(handlerID)
                        handler:execute(action)
                    end
                end
                cacheWheelYAxis = data.y
                touchWheel()
            end


            --------------------------------------------------------------------------------
            -- WHEEL TOUCH LEFT:
            --------------------------------------------------------------------------------
            if items[bundleID][bank]["wheelScreen"] and items[bundleID][bank]["wheelScreen"]["1"] and items[bundleID][bank]["wheelScreen"]["1"]["leftAction"] then
                wheelTouchLeftAction = function()
                    local item = items[bundleID][bank]["wheelScreen"]["1"]["leftAction"]
                    local handlerID = item["handlerID"]
                    local action = item["action"]
                    if handlerID and action then
                        local handler = mod._actionmanager.getHandler(handlerID)
                        handler:execute(action)
                    end
                end
                cacheWheelXAxis = data.x
                touchWheel()
            end

            --------------------------------------------------------------------------------
            -- WHEEL TOUCH RIGHT:
            --------------------------------------------------------------------------------
            if items[bundleID][bank]["wheelScreen"] and items[bundleID][bank]["wheelScreen"]["1"] and items[bundleID][bank]["wheelScreen"]["1"]["rightAction"] then
                wheelTouchRightAction = function()
                    local item = items[bundleID][bank]["wheelScreen"]["1"]["rightAction"]
                    local handlerID = item["handlerID"]
                    local action = item["action"]
                    if handlerID and action then
                        local handler = mod._actionmanager.getHandler(handlerID)
                        handler:execute(action)
                    end
                end
                cacheWheelXAxis = data.x
                touchWheel()
            end
        elseif data.id == ct.event.WHEEL_RELEASED then
            cacheWheelYAxis = 0
            cacheWheelXAxis = 0
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
        mod.refresh(true)
    end)

    --------------------------------------------------------------------------------
    -- Connect to the Loupedeck CT:
    --------------------------------------------------------------------------------
    mod.enabled:update()

    --------------------------------------------------------------------------------
    -- Setup Bank Actions:
    --------------------------------------------------------------------------------
    local actionmanager = deps.actionmanager
    actionmanager.addHandler("global_loupedeckct_banks")
        :onChoices(function(choices)
            for i=1, mod.numberOfBanks do
                choices:add(i18n("loupedeckCT") .. " " .. i18n("bank") .. " " .. tostring(i))
                    :subText(i18n("loupedeckCTBankDescription"))
                    :params({ id = i })
                    :id(i)
            end

            choices:add(i18n("next") .. " " .. i18n("loupedeckCT") .. " " .. i18n("bank"))
                :subText(i18n("loupedeckCTBankDescription"))
                :params({ id = "next" })
                :id("next")

            choices:add(i18n("previous") .. " " .. i18n("loupedeckCT") .. " " .. i18n("bank"))
                :subText(i18n("loupedeckCTBankDescription"))
                :params({ id = "previous" })
                :id("previous")

            return choices
        end)
        :onExecute(function(result)
            if result and result.id then

                local frontmostApplication = application.frontmostApplication()
                local bundleID = frontmostApplication:bundleID()
                local activeBanks = mod.activeBanks()
                local currentBank = activeBanks[bundleID] and tonumber(activeBanks[bundleID]) or 1

                if type(result.id) == "number" then
                    activeBanks[bundleID] = tostring(result.id)
                else
                    if result.id == "next" then
                        if currentBank == mod.numberOfBanks then
                            activeBanks[bundleID] = "1"
                        else
                            activeBanks[bundleID] = tostring(currentBank + 1)
                        end
                    elseif result.id == "previous" then
                        if currentBank == 1 then
                            activeBanks[bundleID] = tostring(mod.numberOfBanks)
                        else
                            activeBanks[bundleID] = tostring(currentBank - 1)
                        end
                    end
                end

                local newBank = activeBanks[bundleID]

                mod.activeBanks(activeBanks)

                mod.refresh()

                local items = mod.items()
                local label = items[bundleID] and items[bundleID][newBank] and items[bundleID][newBank]["bankLabel"] or newBank

                displayNotification(i18n("loupedeckCT") .. " " .. i18n("bank") .. ": " .. label)
            end
        end)
        :onActionId(function(action) return "loupedeckCTBank" .. action.id end)

    return mod
end

return plugin
