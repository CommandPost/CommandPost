--- === plugins.resolve.tangent.emulation ===
---
--- Emulates a Tangent Element Panel.

local require                           = require

local log                               = require "hs.logger".new "actions"

local image                             = require "hs.image"

local config                            = require "cp.config"
local i18n                              = require "cp.i18n"

local imageFromPath                     = image.imageFromPath

local mod = {}

local plugin = {
    id              = "resolve.tangent.emulation",
    group           = "resolve",
    dependencies    = {
        ["core.action.manager"]             = "actionManager",
        ["resolve.tangent.manager"]         = "tangentManager",
        ["core.commands.global"]            = "global",
    }
}

function plugin.init(deps)
    local tangentManager = deps.tangentManager

    local global = deps.global
    global
        :add("requestFocus")
        :whenActivated(function()
            log.df("REQUESTING FOCUS")
            tangentManager:device():pluginRequestFocus()
        end)
        :titled("Request DaVinci Resolve Tangent Control")

    global
        :add("releaseFocus")
        :whenActivated(function()
            log.df("RELEASING FOCUS")
            tangentManager:device():pluginReleaseFocus()
        end)
        :titled("Release DaVinci Resolve Tangent Control")

    --------------------------------------------------------------------------------
    -- Constants:
    --------------------------------------------------------------------------------
    local APP_ID = "DaVinci Resolve"

    local ELEMENT_TK = 0x000c0001 -- Trackerball
    local ELEMENT_MF = 0x000d0001 -- Multifunction
    local ELEMENT_KB = 0x000e0001 -- Knob
    local ELEMENT_BT = 0x000f0001 -- Button

    --------------------------------------------------------------------------------
    -- CommandPost Actions:
    --------------------------------------------------------------------------------
    local items = {
        --------------------------------------------------------------------------------
        -- Element-Tk (Trackerball):
        --------------------------------------------------------------------------------
            --------------------------------------------------------------------------------
            -- Wheel 1:
            --------------------------------------------------------------------------------
            {
                title = "Tangent Element-Tk - Wheel 1 - Horizontal",
                panel = ELEMENT_TK,
                encoder = 0,
            },
            {
                title = "Tangent Element-Tk - Wheel 1 - Vertical",
                panel = ELEMENT_TK,
                encoder = 1,
            },
            {
                title = "Tangent Element-Tk - Wheel 1 - Ring",
                panel = ELEMENT_TK,
                encoder = 2,
            },
            --------------------------------------------------------------------------------
            -- Wheel 2:
            --------------------------------------------------------------------------------
            {
                title = "Tangent Element-Tk - Wheel 2 - Horizontal",
                panel = ELEMENT_TK,
                encoder = 3,
            },
            {
                title = "Tangent Element-Tk - Wheel 2 - Vertical",
                panel = ELEMENT_TK,
                encoder = 4,
            },
            {
                title = "Tangent Element-Tk - Wheel 2 - Ring",
                panel = ELEMENT_TK,
                encoder = 5,
            },
            --------------------------------------------------------------------------------
            -- Wheel 3:
            --------------------------------------------------------------------------------
            {
                title = "Tangent Element-Tk - Wheel 3 - Horizontal",
                panel = ELEMENT_TK,
                encoder = 6,
            },
            {
                title = "Tangent Element-Tk - Wheel 3 - Vertical",
                panel = ELEMENT_TK,
                encoder = 7,
            },
            {
                title = "Tangent Element-Tk - Wheel 3 - Ring",
                panel = ELEMENT_TK,
                encoder = 8,
            },
            --------------------------------------------------------------------------------
            -- Buttons:
            --------------------------------------------------------------------------------
            {
                title = "Tangent Element-Tk - A Button",
                panel = ELEMENT_TK,
                button = 0,
            },
            {
                title = "Tangent Element-Tk - Reset Wheel 1",
                panel = ELEMENT_TK,
                button = 1,
            },
            {
                title = "Tangent Element-Tk - Reset Ring 1",
                panel = ELEMENT_TK,
                button = 2,
            },
            {
                title = "Tangent Element-Tk - Reset Wheel 2",
                panel = ELEMENT_TK,
                button = 3,
            },
            {
                title = "Tangent Element-Tk - Reset Ring 2",
                panel = ELEMENT_TK,
                button = 4,
            },
            {
                title = "Tangent Element-Tk - Reset Wheel 3",
                panel = ELEMENT_TK,
                button = 5,
            },
            {
                title = "Tangent Element-Tk - Reset Ring 3",
                panel = ELEMENT_TK,
                button = 6,
            },
            {
                title = "Tangent Element-Tk - B Button",
                panel = ELEMENT_TK,
                button = 7,
            },
        --------------------------------------------------------------------------------
        -- Element-Mf (Multifunction):
        --------------------------------------------------------------------------------
            --------------------------------------------------------------------------------
            -- Wheel 1:
            --------------------------------------------------------------------------------
            {
                title = "Tangent Element-Mf - Wheel 1 - Horizontal",
                panel = ELEMENT_MF,
                encoder = 0,
            },
            {
                title = "Tangent Element-Mf - Wheel 1 - Vertical",
                panel = ELEMENT_MF,
                encoder = 1,
            },
            {
                title = "Tangent Element-Mf - Wheel 1 - Ring",
                panel = ELEMENT_MF,
                encoder = 2,
            },
            --------------------------------------------------------------------------------
            -- Buttons:
            --------------------------------------------------------------------------------
            {
                title = "Tangent Element-Mf - Button 1",
                panel = ELEMENT_MF,
                button = 0,
            },
            {
                title = "Tangent Element-Mf - Button 2",
                panel = ELEMENT_MF,
                button = 1,
            },
            {
                title = "Tangent Element-Mf - Button 3",
                panel = ELEMENT_MF,
                button = 2,
            },
            {
                title = "Tangent Element-Mf - Button 4",
                panel = ELEMENT_MF,
                button = 3,
            },
            {
                title = "Tangent Element-Mf - Button 5",
                panel = ELEMENT_MF,
                button = 4,
            },
            {
                title = "Tangent Element-Mf - Button 6",
                panel = ELEMENT_MF,
                button = 5,
            },
            {
                title = "Tangent Element-Mf - Button 7",
                panel = ELEMENT_MF,
                button = 6,
            },
            {
                title = "Tangent Element-Mf - Button 8",
                panel = ELEMENT_MF,
                button = 7,
            },
            {
                title = "Tangent Element-Mf - Button 9",
                panel = ELEMENT_MF,
                button = 8,
            },
            {
                title = "Tangent Element-Mf - Button 10",
                panel = ELEMENT_MF,
                button = 9,
            },
            {
                title = "Tangent Element-Mf - Button 11",
                panel = ELEMENT_MF,
                button = 10,
            },
            {
                title = "Tangent Element-Mf - Button 12",
                panel = ELEMENT_MF,
                button = 11,
            },
            {
                title = "Tangent Element-Mf - Wheel Reset",
                panel = ELEMENT_MF,
                button = 19,
            },
            {
                title = "Tangent Element-Mf - Ring Reset",
                panel = ELEMENT_MF,
                button = 20,
            },
            {
                title = "Tangent Element-Mf - A Button",
                panel = ELEMENT_MF,
                button = 12,
            },
            {
                title = "Tangent Element-Mf - B Button",
                panel = ELEMENT_MF,
                button = 18,
            },
            {
                title = "Tangent Element-Mf - Play Reverse",
                panel = ELEMENT_MF,
                button = 13,
            },
            {
                title = "Tangent Element-Mf - Stop",
                panel = ELEMENT_MF,
                button = 14,
            },
            {
                title = "Tangent Element-Mf - Play Forward",
                panel = ELEMENT_MF,
                button = 15,
            },
            {
                title = "Tangent Element-Mf - Inch Reverse",
                panel = ELEMENT_MF,
                button = 16,
            },
            {
                title = "Tangent Element-Mf - Inch Forward",
                panel = ELEMENT_MF,
                button = 17,
            },
        --------------------------------------------------------------------------------
        -- Element-Kb (Knob):
        --------------------------------------------------------------------------------
            --------------------------------------------------------------------------------
            -- Wheel 1:
            --------------------------------------------------------------------------------
            {
                title = "Tangent Element-Kb - Knob 1",
                panel = ELEMENT_KB,
                encoder = 0,
            },
            {
                title = "Tangent Element-Kb - Knob 2",
                panel = ELEMENT_KB,
                encoder = 1,
            },
            {
                title = "Tangent Element-Kb - Knob 3",
                panel = ELEMENT_KB,
                encoder = 2,
            },
            {
                title = "Tangent Element-Kb - Knob 4",
                panel = ELEMENT_KB,
                encoder = 3,
            },
            {
                title = "Tangent Element-Kb - Knob 5",
                panel = ELEMENT_KB,
                encoder = 4,
            },
            {
                title = "Tangent Element-Kb - Knob 6",
                panel = ELEMENT_KB,
                encoder = 5,
            },
            {
                title = "Tangent Element-Kb - Knob 7",
                panel = ELEMENT_KB,
                encoder = 6,
            },
            {
                title = "Tangent Element-Kb - Knob 8",
                panel = ELEMENT_KB,
                encoder = 7,
            },
            {
                title = "Tangent Element-Kb - Knob 9",
                panel = ELEMENT_KB,
                encoder = 8,
            },
            {
                title = "Tangent Element-Kb - Knob 10",
                panel = ELEMENT_KB,
                encoder = 9,
            },
            {
                title = "Tangent Element-Kb - Knob 11",
                panel = ELEMENT_KB,
                encoder = 10,
            },
            {
                title = "Tangent Element-Kb - Knob 12",
                panel = ELEMENT_KB,
                encoder = 11,
            },
            --------------------------------------------------------------------------------
            -- Buttons:
            --------------------------------------------------------------------------------
            {
                title = "Tangent Element-Kb - A Button",
                panel = ELEMENT_KB,
                button = 12,
            },
            {
                title = "Tangent Element-Kb - B Button",
                panel = ELEMENT_KB,
                button = 13,
            },
            {
                title = "Tangent Element-Kb - Knob 1",
                panel = ELEMENT_KB,
                button = 0,
            },
            {
                title = "Tangent Element-Kb - Knob 2",
                panel = ELEMENT_KB,
                button = 1,
            },
            {
                title = "Tangent Element-Kb - Knob 3",
                panel = ELEMENT_KB,
                button = 2,
            },
            {
                title = "Tangent Element-Kb - Knob 4",
                panel = ELEMENT_KB,
                button = 3,
            },
            {
                title = "Tangent Element-Kb - Knob 5",
                panel = ELEMENT_KB,
                button = 4,
            },
            {
                title = "Tangent Element-Kb - Knob 6",
                panel = ELEMENT_KB,
                button = 5,
            },
            {
                title = "Tangent Element-Kb - Knob 7",
                panel = ELEMENT_KB,
                button = 6,
            },
            {
                title = "Tangent Element-Kb - Knob 8",
                panel = ELEMENT_KB,
                button = 7,
            },
            {
                title = "Tangent Element-Kb - Knob 9",
                panel = ELEMENT_KB,
                button = 8,
            },
            {
                title = "Tangent Element-Kb - Knob 10",
                panel = ELEMENT_KB,
                button = 9,
            },
            {
                title = "Tangent Element-Kb - Knob 11",
                panel = ELEMENT_KB,
                button = 10,
            },
            {
                title = "Tangent Element-Kb - Knob 12",
                panel = ELEMENT_KB,
                button = 11,
            },
        --------------------------------------------------------------------------------
        -- Element-Bt (Button)
        --------------------------------------------------------------------------------
            --------------------------------------------------------------------------------
            -- Buttons:
            --------------------------------------------------------------------------------
            {
                title = "Tangent Element-Bt - A Button",
                panel = ELEMENT_BT,
                button = 12,
            },
            {
                title = "Tangent Element-Bt - B Button",
                panel = ELEMENT_BT,
                button = 13,
            },
            {
                title = "Tangent Element-Bt - Button 1",
                panel = ELEMENT_BT,
                button = 0,
            },
            {
                title = "Tangent Element-Bt - Button 2",
                panel = ELEMENT_BT,
                button = 1,
            },
            {
                title = "Tangent Element-Bt - Button 3",
                panel = ELEMENT_BT,
                button = 2,
            },
            {
                title = "Tangent Element-Bt - Button 4",
                panel = ELEMENT_BT,
                button = 3,
            },
            {
                title = "Tangent Element-Bt - Button 5",
                panel = ELEMENT_BT,
                button = 4,
            },
            {
                title = "Tangent Element-Bt - Button 6",
                panel = ELEMENT_BT,
                button = 5,
            },
            {
                title = "Tangent Element-Bt - Button 7",
                panel = ELEMENT_BT,
                button = 6,
            },
            {
                title = "Tangent Element-Bt - Button 8",
                panel = ELEMENT_BT,
                button = 7,
            },
            {
                title = "Tangent Element-Bt - Button 9",
                panel = ELEMENT_BT,
                button = 8,
            },
            {
                title = "Tangent Element-Bt - Button 10",
                panel = ELEMENT_BT,
                button = 9,
            },
            {
                title = "Tangent Element-Bt - Button 11",
                panel = ELEMENT_BT,
                button = 10,
            },
            {
                title = "Tangent Element-Bt - Button 12",
                panel = ELEMENT_BT,
                button = 11,
            },
    }
    local tangentActionDescription = i18n("tangentActionDescription")
    local icon = imageFromPath(config.basePath .. "/plugins/core/tangent/prefs/images/tangent.icns")
    local actionManager = deps.actionManager

    local increments = {1, 2, 5, 10, 50, 100}

    mod._handler = actionManager.addHandler("resolve_tangentemulation", "resolve")
        :onChoices(function(choices)
            for _, v in pairs(items) do
                if v.button then
                    choices
                        :add(v.title .. " - Press")
                        :subText(tangentActionDescription)
                        :params({
                            panel       = v.panel,
                            button      = v.button,
                            down        = true,
                            id          = v.title
                        })
                        :image(icon)
                        :id("resolve_tangentemulation_" .. v.title .. "_press")

                    choices
                        :add(v.title .. " - Release")
                        :subText(tangentActionDescription)
                        :params({
                            panel       = v.panel,
                            button      = v.button,
                            down        = false,
                            id          = v.title
                        })
                        :image(icon)
                        :id("resolve_tangentemulation_" .. v.title .. "_release")
                else
                    for _, increment in pairs(increments) do
                        choices
                            :add(v.title .. " - Increase by " .. increment)
                            :subText(tangentActionDescription)
                            :params({
                                panel       = v.panel,
                                encoder     = v.encoder,
                                increment   = increment,
                                id          = v.title
                            })
                            :image(icon)
                            :id("resolve_tangentemulation_" .. v.title .. " - Increase by " .. increment)

                        choices
                            :add(v.title .. " - Decrease by " .. increment)
                            :subText(tangentActionDescription)
                            :params({
                                panel       = v.panel,
                                encoder     = v.encoder,
                                increment   = increment * -1,
                                id          = v.title
                            })
                            :image(icon)
                            :id("resolve_tangentemulation_" .. v.title .. " - Decrease by " .. increment)
                    end
                end
            end
        end)
        :onExecute(function(action)
            if action.button then
                if action.down then
                    tangentManager.connection():sendShamUnmanagedButtonDown(APP_ID, action.panel, action.button)
                else
                    tangentManager.connection():sendShamUnmanagedButtonUp(APP_ID, action.panel, action.button)
                end
            elseif action.encoder then
                log.df("increase by: %s", action.increment)
                tangentManager.connection():sendShamUnmanagedEncoderChange(APP_ID, action.panel, action.encoder, action.increment)
            end
        end)
        :onActionId(function(params)
            return "resolve_tangentemulation" .. params.id
        end)

    --------------------------------------------------------------------------------
    -- Tangent Mapper Actions:
    --------------------------------------------------------------------------------
    local resolveGroup = tangentManager.controls:group("DaVinci Resolve")
    local emuationGroup = resolveGroup:group("Emulation")
    local tkGroup = emuationGroup:group("Element-TK")
    local mfGroup = emuationGroup:group("Element-MF")
    local kbGroup = emuationGroup:group("Element-KB")
    local btGroup = emuationGroup:group("Element-BT")

    tangentManager:addMode(0x03000001, "Resolve: Main")

    local mappings = {
        --------------------------------------------------------------------------------
        -- Element-Tk (Trackerball):
        --------------------------------------------------------------------------------
            --------------------------------------------------------------------------------
            -- Wheel 1:
            --------------------------------------------------------------------------------
            {
                title = "Wheel 1 - Horizontal",
                encoder = 0,
                panel = ELEMENT_TK,
                reset = 1,
            },
            {
                title = "Wheel 1 - Vertical",
                encoder = 1,
                panel = ELEMENT_TK,
                reset = 1,
            },
            {
                title = "Wheel 1 - Ring",
                encoder = 2,
                panel = ELEMENT_TK,
                reset = 2,
            },
            --------------------------------------------------------------------------------
            -- Wheel 2:
            --------------------------------------------------------------------------------
            {
                title = "Wheel 2 - Horizontal",
                encoder = 3,
                panel = ELEMENT_TK,
                reset = 3,
            },
            {
                title = "Wheel 2 - Vertical",
                encoder = 4,
                panel = ELEMENT_TK,
                reset = 3,
            },
            {
                title = "Wheel 2 - Ring",
                encoder = 5,
                panel = ELEMENT_TK,
                reset = 4,
            },
            --------------------------------------------------------------------------------
            -- Wheel 3:
            --------------------------------------------------------------------------------
            {
                title = "Wheel 3 - Horizontal",
                encoder = 6,
                panel = ELEMENT_TK,
                reset = 5,
            },
            {
                title = "Wheel 3 - Vertical",
                encoder = 7,
                panel = ELEMENT_TK,
                reset = 5,
            },
            {
                title = "Wheel 3 - Ring",
                encoder = 8,
                panel = ELEMENT_TK,
                reset = 6,
            },
            --------------------------------------------------------------------------------
            -- Buttons:
            --------------------------------------------------------------------------------
            {
                title = "A Button",
                button = 0,
                panel = ELEMENT_TK,
            },
            {
                title = "Reset Wheel 1",
                button = 1,
                panel = ELEMENT_TK,
            },
            {
                title = "Reset Ring 1",
                button = 2,
                panel = ELEMENT_TK,
            },
            {
                title = "Reset Wheel 2",
                button = 3,
                panel = ELEMENT_TK,
            },
            {
                title = "Reset Ring 2",
                button = 4,
                panel = ELEMENT_TK,
            },
            {
                title = "Reset Wheel 3",
                button = 5,
                panel = ELEMENT_TK,
            },
            {
                title = "Reset Ring 3",
                button = 6,
                panel = ELEMENT_TK,
            },
            {
                title = "B Button",
                button = 7,
                panel = ELEMENT_TK,
            },
        --------------------------------------------------------------------------------
        -- Element-Mf (Multifunction):
        --------------------------------------------------------------------------------
            --------------------------------------------------------------------------------
            -- Wheel 1:
            --------------------------------------------------------------------------------
            {
                title = "Wheel 1 - Horizontal",
                encoder = 0,
                panel = ELEMENT_MF,
                reset = 1,
            },
            {
                title = "Wheel 1 - Vertical",
                encoder = 1,
                panel = ELEMENT_MF,
                reset = 1,
            },
            {
                title = "Wheel 1 - Ring",
                encoder = 2,
                panel = ELEMENT_MF,
                reset = 2,
            },
            --------------------------------------------------------------------------------
            -- Buttons:
            --------------------------------------------------------------------------------
            {
                title = "Button 01",
                button = 0,
                panel = ELEMENT_MF,
            },
            {
                title = "Button 02",
                button = 1,
                panel = ELEMENT_MF,
            },
            {
                title = "Button 03",
                button = 2,
                panel = ELEMENT_MF,
            },
            {
                title = "Button 04",
                button = 3,
                panel = ELEMENT_MF,
            },
            {
                title = "Button 05",
                button = 4,
                panel = ELEMENT_MF,
            },
            {
                title = "Button 06",
                button = 5,
                panel = ELEMENT_MF,
            },
            {
                title = "Button 07",
                button = 6,
                panel = ELEMENT_MF,
            },
            {
                title = "Button 08",
                button = 7,
                panel = ELEMENT_MF,
            },
            {
                title = "Button 09",
                button = 8,
                panel = ELEMENT_MF,
            },
            {
                title = "Button 10",
                button = 9,
                panel = ELEMENT_MF,
            },
            {
                title = "Button 11",
                button = 10,
                panel = ELEMENT_MF,
            },
            {
                title = "Button 12",
                button = 11,
                panel = ELEMENT_MF,
            },
            {
                title = "A Button",
                button = 12,
                panel = ELEMENT_MF,
            },
            {
                title = "Play Reverse Button",
                button = 13,
                panel = ELEMENT_MF,
            },
            {
                title = "Stop Button",
                button = 14,
                panel = ELEMENT_MF,
            },
            {
                title = "Play Forward Button",
                button = 15,
                panel = ELEMENT_MF,
            },
            {
                title = "Inch Reverse Button",
                button = 16,
                panel = ELEMENT_MF,
            },
            {
                title = "Inch Forward Button",
                button = 17,
                panel = ELEMENT_MF,
            },
            {
                title = "B Button",
                button = 18,
                panel = ELEMENT_MF,
            },
            {
                title = "Reset Wheel 1",
                button = 19,
                panel = ELEMENT_MF,
            },
            {
                title = "Reset Ring 1",
                button = 20,
                panel = ELEMENT_MF,
            },
        --------------------------------------------------------------------------------
        -- Element-Kb (Knob):
        --------------------------------------------------------------------------------
            --------------------------------------------------------------------------------
            -- Knobs:
            --------------------------------------------------------------------------------
            {
                title = "Knob 01",
                encoder = 0,
                panel = ELEMENT_KB,
                reset = 0,
            },
            {
                title = "Knob 02",
                encoder = 1,
                panel = ELEMENT_KB,
                reset = 1,
            },
            {
                title = "Knob 03",
                encoder = 2,
                panel = ELEMENT_KB,
                reset = 2,
            },
            {
                title = "Knob 04",
                encoder = 3,
                panel = ELEMENT_KB,
                reset = 3,
            },
            {
                title = "Knob 05",
                encoder = 4,
                panel = ELEMENT_KB,
                reset = 4,
            },
            {
                title = "Knob 06",
                encoder = 5,
                panel = ELEMENT_KB,
                reset = 5,
            },
            {
                title = "Knob 07",
                encoder = 6,
                panel = ELEMENT_KB,
                reset = 6,
            },
            {
                title = "Knob 08",
                encoder = 7,
                panel = ELEMENT_KB,
                reset = 7,
            },
            {
                title = "Knob 09",
                encoder = 8,
                panel = ELEMENT_KB,
                reset = 8,
            },
            {
                title = "Knob 10",
                encoder = 9,
                panel = ELEMENT_KB,
                reset = 9,
            },
            {
                title = "Knob 11",
                encoder = 10,
                panel = ELEMENT_KB,
                reset = 10,
            },
            {
                title = "Knob 12",
                encoder = 11,
                panel = ELEMENT_KB,
                reset = 11,
            },
            --------------------------------------------------------------------------------
            -- Buttons:
            --------------------------------------------------------------------------------
            {
                title = "A Button",
                button = 12,
                panel = ELEMENT_KB,
            },
            {
                title = "B Button",
                button = 13,
                panel = ELEMENT_KB,
            },
        --------------------------------------------------------------------------------
        -- Element-Bt (Button):
        --------------------------------------------------------------------------------
            --------------------------------------------------------------------------------
            -- Buttons:
            --------------------------------------------------------------------------------
            {
                title = "Button 01",
                button = 0,
                panel = ELEMENT_BT,
            },
            {
                title = "Button 02",
                button = 1,
                panel = ELEMENT_BT,
            },
            {
                title = "Button 03",
                button = 2,
                panel = ELEMENT_BT,
            },
            {
                title = "Button 04",
                button = 3,
                panel = ELEMENT_BT,
            },
            {
                title = "Button 05",
                button = 4,
                panel = ELEMENT_BT,
            },
            {
                title = "Button 06",
                button = 5,
                panel = ELEMENT_BT,
            },
            {
                title = "Button 07",
                button = 6,
                panel = ELEMENT_BT,
            },
            {
                title = "Button 08",
                button = 7,
                panel = ELEMENT_BT,
            },
            {
                title = "Button 09",
                button = 8,
                panel = ELEMENT_BT,
            },
            {
                title = "Button 10",
                button = 9,
                panel = ELEMENT_BT,
            },
            {
                title = "Button 11",
                button = 10,
                panel = ELEMENT_BT,
            },
            {
                title = "Button 12",
                button = 11,
                panel = ELEMENT_BT,
            },
            {
                title = "A Button",
                button = 12,
                panel = ELEMENT_BT,
            },
            {
                title = "B Button",
                button = 13,
                panel = ELEMENT_BT,
            },
    }

    local currentID = 0x0F840000
    for _, v in pairs(mappings) do
        local group
        if v.panel == ELEMENT_TK then group = tkGroup end
        if v.panel == ELEMENT_MF then group = mfGroup end
        if v.panel == ELEMENT_KB then group = kbGroup end
        if v.panel == ELEMENT_BT then group = btGroup end
        if type(v.encoder) == "number" then
            group:parameter(currentID)
                :name(v.title)
                :minValue(0)
                :maxValue(10000)
                :stepSize(100)
                :onGet(function()
                    return 1
                end)
                :onChange(function(increment)
                    tangentManager:device():sendShamUnmanagedEncoderChange(APP_ID, v.panel, v.encoder, increment)
                end)
                :onReset(function()
                    tangentManager:device():sendShamUnmanagedButtonDown(APP_ID, v.panel, v.reset)
                    tangentManager:device():sendShamUnmanagedButtonUp(APP_ID, v.panel, v.reset)
                end)
        else
            group:action(currentID, v.title)
                :onPress(function()
                    tangentManager:device():sendShamUnmanagedButtonDown(APP_ID, v.panel, v.button)
                end)
                :onRelease(function()
                    tangentManager:device():sendShamUnmanagedButtonUp(APP_ID, v.panel, v.button)
                end)
        end
        currentID = currentID + 1
    end

    return mod
end

return plugin
