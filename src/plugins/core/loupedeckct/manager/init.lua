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
local image                 = require "hs.image"
local timer                 = require "hs.timer"

local config                = require "cp.config"
local dialog                = require "cp.dialog"
local i18n                  = require "cp.i18n"
local json                  = require "cp.json"

local displayNotification   = dialog.displayNotification
local doAfter               = timer.doAfter
local imageFromURL          = image.imageFromURL

local mod = {}

-- default panel color (black)
local defaultColor = "000000"

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
    local bankID = activeBanks[bundleID] or "1"

    local item = items[bundleID]
    local bank = item and item[bankID]

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
    local ledButton = bank.ledButton
    for i=7, 26 do
        local id = tostring(i)
        local ledColor = ledButton[id] and bank.ledButton[id].led or defaultColor
        if cachedLEDButtonValues[id] ~= ledColor then
            --------------------------------------------------------------------------------
            -- Only update if the colour has changed to save bandwidth:
            --------------------------------------------------------------------------------
            ct.buttonColor(i, {hex="#" .. ledColor})
        end
        cachedLEDButtonValues[id] = ledColor
    end

    --------------------------------------------------------------------------------
    -- SET TOUCH SCREEN BUTTON IMAGES:
    --------------------------------------------------------------------------------
    local touchButton = bank.touchButton
    for i=1, 12 do
        local id = tostring(i)
        success = false
        local thisButton = touchButton and touchButton[id]
        local encodedIcon = thisButton and thisButton.encodedIcon

        --------------------------------------------------------------------------------
        -- Only update if the screen has changed to save bandwidth:
        --------------------------------------------------------------------------------
        if encodedIcon and cachedTouchScreenButtonValues[id] ~= encodedIcon then
            cachedTouchScreenButtonValues[id] = encodedIcon
            local decodedImage = imageFromURL(encodedIcon)
            if decodedImage then
                ct.updateScreenButtonImage(i, decodedImage)
                success = true
            end
        end
        if not success and cachedTouchScreenButtonValues[id] ~= defaultColor then
            --------------------------------------------------------------------------------
            -- Only update if the screen has changed to save bandwidth:
            --------------------------------------------------------------------------------
            ct.updateScreenButtonColor(i, {hex="#"..defaultColor})
            cachedTouchScreenButtonValues[id] = defaultColor
        end
    end

    --------------------------------------------------------------------------------
    -- SET WHEEL SCREEN:
    --------------------------------------------------------------------------------
    success = false
    local thisWheel = bank.wheelScreen and bank.wheelScreen["1"]
    local encodedIcon = thisWheel and thisWheel.encodedIcon
    --------------------------------------------------------------------------------
    -- Only update if the screen has changed to save bandwidth:
    --------------------------------------------------------------------------------
    if encodedIcon and cachedWheelScreen ~= encodedIcon then
        cachedWheelScreen = encodedIcon
        local decodedImage = imageFromURL(encodedIcon)
        if decodedImage then
            ct.updateScreenImage(ct.screens.wheel, decodedImage)
        end
        success = true
    end

    --------------------------------------------------------------------------------
    -- Only update if the screen has changed to save bandwidth:
    --------------------------------------------------------------------------------
    if not success and cachedWheelScreen ~= defaultColor then
        ct.updateScreenColor(ct.screens.wheel, {hex="#"..defaultColor})
        cachedWheelScreen = defaultColor
    end

    --------------------------------------------------------------------------------
    -- SET LEFT SIDE SCREEN:
    --------------------------------------------------------------------------------
    success = false
    local thisSideScreen = bank.sideScreen and bank.sideScreen["1"]
    encodedIcon = thisSideScreen and thisSideScreen.encodedIcon
    if encodedIcon and cachedLeftSideScreen ~= encodedIcon then
        cachedLeftSideScreen = encodedIcon
        local decodedImage = imageFromURL(encodedIcon)
        if decodedImage then
            --------------------------------------------------------------------------------
            -- Only update if the screen has changed to save bandwidth:
            --------------------------------------------------------------------------------
            ct.updateScreenImage(ct.screens.left, decodedImage)
            success = true
        end
    end
    --------------------------------------------------------------------------------
    -- Only update if the screen has changed to save bandwidth:
    --------------------------------------------------------------------------------
    if not success and cachedLeftSideScreen ~= defaultColor then
        ct.updateScreenColor(ct.screens.left, {hex="#"..defaultColor})
        cachedLeftSideScreen = defaultColor
    end

    --------------------------------------------------------------------------------
    -- SET RIGHT SIDE SCREEN:
    --------------------------------------------------------------------------------
    success = false
    thisSideScreen = bank.sideScreen and bank.sideScreen["2"]
    encodedIcon = thisSideScreen and thisSideScreen.encodedIcon
    if encodedIcon and cachedRightSideScreen ~= encodedIcon then
        cachedRightSideScreen = encodedIcon
        local decodedImage = imageFromURL(encodedIcon)
        if decodedImage then
            --------------------------------------------------------------------------------
            -- Only update if the screen has changed to save bandwidth:
            --------------------------------------------------------------------------------
            ct.updateScreenImage(ct.screens.right, decodedImage)
            success = true
        end
    end
    --------------------------------------------------------------------------------
    -- Only update if the screen has changed to save bandwidth:
    --------------------------------------------------------------------------------
    if not success and cachedRightSideScreen ~= defaultColor then
        ct.updateScreenColor(ct.screens.right, {hex="#"..defaultColor})
        cachedRightSideScreen = defaultColor
    end
end

--------------------------------------------------------------------------------
-- WHEEL:
--------------------------------------------------------------------------------
local cacheWheelYAxis = nil
local cacheWheelXAxis = nil

--------------------------------------------------------------------------------
-- RIGHT TOUCH SCREEN:
--------------------------------------------------------------------------------
local cacheRightScreenYAxis = nil
local cacheLeftScreenYAxis = nil

local function executeAction(thisAction)
    if thisAction then
        local handlerID = thisAction.handlerID
        local action = thisAction.action
        if handlerID and action then
            local handler = mod._actionmanager.getHandler(handlerID)
            handler:execute(action)
            return true
        end

    end
    return false
end

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
    local bankID = activeBanks[bundleID] or "1"

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
        bankID = bankID .. "_LeftFn"
    elseif rightFnPressed then
        bankID = bankID .. "_RightFn"
    end

    local item = items[bundleID]
    local bank = item and item[bankID]

    if bank then
        if data.id == ct.event.BUTTON_PRESS and data.direction == "down" then
            --------------------------------------------------------------------------------
            -- LED BUTTON PRESS:
            --------------------------------------------------------------------------------
            local thisButton = bank.ledButton and bank.ledButton[buttonID]
            if thisButton and executeAction(thisButton.pressAction) then
                return
            end

            --------------------------------------------------------------------------------
            -- KNOB BUTTON PRESS:
            --------------------------------------------------------------------------------
            local thisKnob = bank.knob and bank.knob[buttonID]
            if thisKnob and executeAction(thisKnob.pressAction) then
                return
            end
        elseif data.id == ct.event.ENCODER_MOVE then
            local thisKnob = bank.knob and bank.knob[buttonID]
            if thisKnob and executeAction(thisKnob[data.direction.."Action"]) then
                return
            end

            local thisJogWheel = bank.jogWheel and bank.jogWheel["1"]
            if thisJogWheel and executeAction(thisJogWheel[data.direction.."Action"]) then
                return
            end
        elseif data.id == ct.event.SCREEN_PRESSED then
            --------------------------------------------------------------------------------
            -- TOUCH SCREEN BUTTON PRESS:
            --------------------------------------------------------------------------------
            local thisTouchButton = bank.touchButton and bank.touchButton[buttonID]
            if thisTouchButton and executeAction(thisTouchButton.pressAction) then
                return
            end


            if data.x < 50 then
                --------------------------------------------------------------------------------
                -- LEFT TOUCH SCREEN TOUCH SLIDE UP/DOWN:
                --------------------------------------------------------------------------------
                local thisSideScreen = bank.sideScreen and bank.sideScreen["1"]
                if thisSideScreen then
                    if cacheLeftScreenYAxis ~= nil then
                        -- already dragging. Which way?
                        local yDiff = data.y - cacheLeftScreenYAxis
                        if yDiff < 0 then
                            executeAction(thisSideScreen.upAction)
                        elseif yDiff > 0 then
                            executeAction(thisSideScreen.downAction)
                        end
                    end
                    cacheLeftScreenYAxis = data.y
                end
            end

            if data.x > 400 then
                --------------------------------------------------------------------------------
                -- RIGHT TOUCH SCREEN TOUCH UP:
                --------------------------------------------------------------------------------
                local thisSideScreen = bank.sideScreen and bank.sideScreen["2"]
                if thisSideScreen then
                    if cacheRightScreenYAxis ~= nil then
                        -- already dragging. Which way?
                        local yDiff = data.y - cacheRightScreenYAxis
                        if yDiff < 0 then
                            executeAction(thisSideScreen.upAction)
                        elseif yDiff > 0 then
                            executeAction(thisSideScreen.downAction)
                        end
                    end
                    cacheRightScreenYAxis = data.y
                end
            end
        elseif data.id == ct.event.SCREEN_RELEASED then
            cacheLeftScreenYAxis = nil
            cacheRightScreenYAxis = nil
        elseif data.id == ct.event.WHEEL_PRESSED then
            local wheelScreen = bank.wheelScreen and bank.wheelScreen["1"]

            if wheelScreen then
                if cacheWheelXAxis ~= nil and cacheWheelYAxis ~= nil then
                    -- we're already dragging. Which way?
                    local xDiff, yDiff = data.x - cacheWheelXAxis, data.y - cacheWheelYAxis
                    if math.abs(xDiff) > math.abs(yDiff) then
                        -- dragging horizontally
                        if xDiff < 0 then
                            executeAction(wheelScreen.leftAction)
                        else
                            executeAction(wheelScreen.rightAction)
                        end
                    elseif yDiff ~= 0 then
                        -- dragging vertically
                        if yDiff < 0 then
                            executeAction(wheelScreen.upAction)
                        else
                            executeAction(wheelScreen.downAction)
                        end
                    end
                end
                cacheWheelXAxis = data.x
                cacheWheelYAxis = data.y
            end
        elseif data.id == ct.event.WHEEL_RELEASED then
            cacheWheelYAxis = nil
            cacheWheelXAxis = nil
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
