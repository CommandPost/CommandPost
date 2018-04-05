--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                     M I D I    M A N A G E R    P L U G I N                --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.midi.manager ===
---
--- MIDI Manager Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                                       = require("hs.logger").new("midiManager")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local fnutils                                   = require("hs.fnutils")
local inspect                                   = require("hs.inspect")
local midi                                      = require("hs.midi")
local timer                                     = require("hs.timer")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config                                    = require("cp.config")
local tools                                     = require("cp.tools")

--------------------------------------------------------------------------------
--
-- THE MODULE - CONTROLS:
--
--------------------------------------------------------------------------------

--- === plugins.core.midi.manager.controls ===
---
--- MIDI Manager Controls.

local mod = {}

local controls = {}
controls._items = {}

mod.controls = controls

--- plugins.core.midi.manager.controls:new(id, params) -> table
--- Method
--- Creates a new MIDI control.
---
--- Parameters:
--- * `id`      - The unique ID for this widget.
---
--- Returns:
---  * table that has been created
function controls:new(id, params)

    if controls._items[id] ~= nil then
        error("Duplicate Control ID: " .. id)
    end
    local o = {
        _id = id,
        _params = params,
    }
    setmetatable(o, self)
    self.__index = self

    controls._items[id] = o
    return o

end

--- plugins.core.midi.manager.controls:get(id) -> table
--- Method
--- Gets a MIDI control.
---
--- Parameters:
--- * `id`      - The unique ID for the widget you want to return.
---
--- Returns:
---  * table containing the widget
function controls:get(id)
    return self._items[id]
end

--- plugins.core.midi.manager.controls:getAll() -> table
--- Method
--- Returns all of the created controls.
---
--- Parameters:
--- * None
---
--- Returns:
---  * table containing all of the created callbacks
function controls:getAll()
    return self._items
end

--- plugins.core.midi.manager.controls:id() -> string
--- Method
--- Returns the ID of the control.
---
--- Parameters:
--- * None
---
--- Returns:
---  * The ID of the widget as a `string`
function controls:id()
    return self._id
end

--- plugins.core.midi.manager.controls:params() -> function
--- Method
--- Returns the paramaters of the control.
---
--- Parameters:
--- * None
---
--- Returns:
---  * The paramaters of the widget
function controls:params()
    return self._params
end

--- plugins.core.midi.manager.controls.allGroups() -> table
--- Function
--- Returns a table containing all of the control groups.
---
--- Parameters:
--- * None
---
--- Returns:
---  * Table
function controls.allGroups()
    local result = {}
    local allControls = controls:getAll()
    for _, widget in pairs(allControls) do
        local params = widget:params()
        if params and params.group then
            if not tools.tableContains(result, params.group) then
                table.insert(result, params.group)
            end
        end
    end
    return result
end

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------

--- DEFAULT_MIDI_CONTROLS -> table
--- Constant
--- The default MIDI controls, so that the user has a starting point.
local DEFAULT_MIDI_CONTROLS = {
  fcpx1 = {
    ["1"] = {
      action = {
        id = "next"
      },
      actionTitle = "Next MIDI Bank",
      handlerID = "global_midibanks",
    },
    ["2"] = {
      action = {
        id = "previous",
      },
      actionTitle = "Previous MIDI Bank",
      handlerID = "global_midibanks",
    },
    ["3"] = {
      action = {
        id = "colorAnglePuckOne"
      },
      actionTitle = "MIDI: Color Board Color Puck 1 (Angle)",
      handlerID = "fcpx_midicontrols"
    },
    ["4"] = {
      action = {
        id = "colorPercentagePuckOne"
      },
      actionTitle = "MIDI: Color Board Color Puck 1 (Percentage)",
      handlerID = "fcpx_midicontrols"
    },
    ["5"] = {
      action = {
        id = "colorAnglePuckTwo"
      },
      actionTitle = "MIDI: Color Board Color Puck 2 (Angle)",
      handlerID = "fcpx_midicontrols"
    },
    ["6"] = {
      action = {
        id = "colorPercentagePuckTwo"
      },
      actionTitle = "MIDI: Color Board Color Puck 2 (Percentage)",
      handlerID = "fcpx_midicontrols"
    },
    ["7"] = {
      action = {
        id = "colorAnglePuckThree"
      },
      actionTitle = "MIDI: Color Board Color Puck 3 (Angle)",
      handlerID = "fcpx_midicontrols"
    },
    ["8"] = {
      action = {
        id = "colorPercentagePuckThree"
      },
      actionTitle = "MIDI: Color Board Color Puck 3 (Percentage)",
      handlerID = "fcpx_midicontrols"
    },
    ["9"] = {
      action = {
        id = "colorAnglePuckFour"
      },
      actionTitle = "MIDI: Color Board Color Puck 4 (Angle)",
      handlerID = "fcpx_midicontrols"
    },
    ["10"] = {
      action = {
        id = "colorPercentagePuckFour"
      },
      actionTitle = "MIDI: Color Board Color Puck 4 (Percentage)",
      handlerID = "fcpx_midicontrols"
    },
    ["11"] = {
      action = {
        id = "exposurePercentagePuckOne"
      },
      actionTitle = "MIDI: Color Board Exposure Puck 1 (Percentage)",
      handlerID = "fcpx_midicontrols"
    },
    ["12"] = {
      action = {
        id = "exposurePercentagePuckTwo"
      },
      actionTitle = "MIDI: Color Board Exposure Puck 2 (Percentage)",
      handlerID = "fcpx_midicontrols"
    },
    ["13"] = {
      action = {
        id = "exposurePercentagePuckThree"
      },
      actionTitle = "MIDI: Color Board Exposure Puck 3 (Percentage)",
      handlerID = "fcpx_midicontrols"
    },
    ["14"] = {
      action = {
        id = "exposurePercentagePuckFour"
      },
      actionTitle = "MIDI: Color Board Exposure Puck 4 (Percentage)",
      handlerID = "fcpx_midicontrols"
    },
    ["15"] = {
      action = {
        id = "saturationPercentagePuckOne"
      },
      actionTitle = "MIDI: Color Board Saturation Puck 1 (Percentage)",
      handlerID = "fcpx_midicontrols"
    },
    ["16"] = {
      action = {
        id = "saturationPercentagePuckTwo"
      },
      actionTitle = "MIDI: Color Board Saturation Puck 2 (Percentage)",
      handlerID = "fcpx_midicontrols"
    },
    ["17"] = {
      action = {
        id = "saturationPercentagePuckThree"
      },
      actionTitle = "MIDI: Color Board Saturation Puck 3 (Percentage)",
      handlerID = "fcpx_midicontrols"
    },
    ["18"] = {
      action = {
        id = "saturationPercentagePuckFour"
      },
      actionTitle = "MIDI: Color Board Saturation Puck 4 (Percentage)",
      handlerID = "fcpx_midicontrols"
    },
    ["19"] = {
      action = {
        id = "puckOne"
      },
      actionTitle = "MIDI: Color Board Puck 1",
      handlerID = "fcpx_midicontrols"
    },
    ["20"] = {
      action = {
        id = "puckTwo"
      },
      actionTitle = "MIDI: Color Board Puck 2",
      handlerID = "fcpx_midicontrols"
    },
    ["21"] = {
      action = {
        id = "puckThree"
      },
      actionTitle = "MIDI: Color Board Puck 3",
      handlerID = "fcpx_midicontrols"
    },
    ["22"] = {
      action = {
        id = "puckFour"
      },
      actionTitle = "MIDI: Color Board Puck 4",
      handlerID = "fcpx_midicontrols"
    },
  },
  fcpx2 = {
    ["1"] = {
      action = {
        id = "next"
      },
      actionTitle = "Next MIDI Bank",
      handlerID = "global_midibanks",
    },
    ["2"] = {
      action = {
        id = "previous",
      },
      actionTitle = "Previous MIDI Bank",
      handlerID = "global_midibanks",
    },
    ["3"] = {
      action = {
        id = "masterHorizontal"
      },
      actionTitle = "MIDI: Color Wheel Master (Horizontal)",
      handlerID = "fcpx_midicontrols"
    },
    ["4"] = {
      action = {
        id = "masterVertical"
      },
      actionTitle = "MIDI: Color Wheel Master (Vertical)",
      handlerID = "fcpx_midicontrols"
    },
    ["5"] = {
      action = {
        id = "highlightsHorizontal"
      },
      actionTitle = "MIDI: Color Wheel Highlights (Horizontal)",
      handlerID = "fcpx_midicontrols"
    },
    ["6"] = {
      action = {
        id = "highlightsVertical"
      },
      actionTitle = "MIDI: Color Wheel Highlights (Vertical)",
      handlerID = "fcpx_midicontrols"
    },
    ["7"] = {
      action = {
        id = "midtonesHorizontal"
      },
      actionTitle = "MIDI: Color Wheel Midtones (Horizontal)",
      handlerID = "fcpx_midicontrols"
    },
    ["8"] = {
      action = {
        id = "midtonesVertical"
      },
      actionTitle = "MIDI: Color Wheel Midtones (Vertical)",
      handlerID = "fcpx_midicontrols"
    },
    ["9"] = {
      action = {
        id = "shadowsHorizontal"
      },
      actionTitle = "MIDI: Color Wheel Shadows (Horizontal)",
      handlerID = "fcpx_midicontrols"
    },
    ["10"] = {
      action = {
        id = "shadowsVertical"
      },
      actionTitle = "MIDI: Color Wheel Shadows (Vertical)",
      handlerID = "fcpx_midicontrols"
    },
  },
  fcpx3 = {
    ["1"] = {
      action = {
        id = "next"
      },
      actionTitle = "Next MIDI Bank",
      handlerID = "global_midibanks",
    },
    ["2"] = {
      action = {
        id = "previous",
      },
      actionTitle = "Previous MIDI Bank",
      handlerID = "global_midibanks",
    },
    ["3"] = {
      action = {
        id = "zoomSlider",
      },
      actionTitle = "MIDI: Timeline Zoom",
      handlerID = "fcpx_midicontrols",
    },
  },
  fcpx4 = {
    ["1"] = {
      action = {
        id = "next",
      },
      actionTitle = "Next MIDI Bank",
      handlerID = "global_midibanks",
    },
    ["2"] = {
      action = {
        id = "previous",
      },
      actionTitle = "Previous MIDI Bank",
      handlerID = "global_midibanks",
    },
  },
  fcpx5 = {
    ["1"] = {
      action = {
        id = "next",
      },
      actionTitle = "Next MIDI Bank",
      handlerID = "global_midibanks",
    },
    ["2"] = {
      action = {
        id = "previous",
      },
      actionTitle = "Previous MIDI Bank",
      handlerID = "global_midibanks",
    }
  },
  global1 = {
    ["1"] = {
      action = {
        id = "next",
      },
      actionTitle = "Next MIDI Bank",
      handlerID = "global_midibanks",
    },
    ["2"] = {
      action = {
        id = "previous",
      },
      actionTitle = "Previous MIDI Bank",
      handlerID = "global_midibanks",
    }
  },
  global2 = {
    ["1"] = {
      action = {
        id = "next",
      },
      actionTitle = "Next MIDI Bank",
      handlerID = "global_midibanks",
    },
    ["2"] = {
      action = {
        id = "previous",
      },
      actionTitle = "Previous MIDI Bank",
      handlerID = "global_midibanks",
    }
  },
  global3 = {
    ["1"] = {
      action = {
        id = "next",
      },
      actionTitle = "Next MIDI Bank",
      handlerID = "global_midibanks",
    },
    ["2"] = {
      action = {
        id = "previous",
      },
      actionTitle = "Previous MIDI Bank",
      handlerID = "global_midibanks",
    }
  },
  global4 = {
    ["1"] = {
      action = {
        id = "next",
      },
      actionTitle = "Next MIDI Bank",
      handlerID = "global_midibanks",
    },
    ["2"] = {
      action = {
        id = "previous",
      },
      actionTitle = "Previous MIDI Bank",
      handlerID = "global_midibanks",
    }
  },
  global5 = {
    ["1"] = {
      action = {
        id = "next",
      },
      actionTitle = "Next MIDI Bank",
      handlerID = "global_midibanks",
    },
    ["2"] = {
      action = {
        id = "previous",
      },
      actionTitle = "Previous MIDI Bank",
      handlerID = "global_midibanks",
    }
  },
}

--
-- MIDI Device Names:
--
mod._deviceNames = {}
mod._virtualDevices = {}

-- plugins.core.midi.manager._groupStatus -> table
-- Variable
-- Group Statuses.
mod._groupStatus = {}

-- plugins.core.midi.manager._currentSubGroup -> table
-- Variable
-- Current Touch Bar Sub Group Statuses.
mod._currentSubGroup = config.prop("midiCurrentSubGroup", {})

--- plugins.core.midi.manager.numberOfSubGroups -> number
--- Variable
--- The number of Sub Groups per Touch Bar Group.
mod.numberOfSubGroups = 5

--
-- Used to prevent callback delays (sorry David, I know this is the worst possible way to do things):
--
mod._alreadyProcessingCallback  = false
mod._lastControllerNumber       = nil
mod._lastControllerValue        = nil
mod._lastControllerChannel      = nil
mod._lastTimestamp              = nil
mod._lastPitchChange            = nil

-- mod._listenMMCFunctions -> table
-- Variable
-- MMC Listener Functions.
mod._listenMMCFunctions = {}

-- mod._listenMTCFunctions -> table
-- Variable
-- MTC Listener Functions.
mod._listenMTCFunctions = {}

-- mod._generalCallbacks -> table
-- Variable
-- General Callback Functions.
mod._generalCallbacks = {}

--- plugins.core.midi.manager.maxItems -> number
--- Variable
--- The maximum number of MIDI items per group.
mod.maxItems = 150

--- plugins.core.midi.manager.buttons <cp.prop: table>
--- Field
--- Contains all the saved MIDI items
mod._items = config.prop("midiControls", DEFAULT_MIDI_CONTROLS)

--- plugins.core.midi.manager.defaultGroup -> string
--- Variable
--- The default group.
mod.defaultGroup = "global"

--- plugins.core.midi.manager.clear() -> none
--- Function
--- Clears the MIDI items.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.clear()
    mod._items({})
    mod.update()
end

--- plugins.core.midi.manager.updateAction(button, group, actionTitle, handlerID, action) -> none
--- Function
--- Updates a MIDI action.
---
--- Parameters:
---  * button - Button ID as string
---  * group - Group ID as string
---  * actionTitle - Action Title as string
---  * handlerID - Handler ID as string
---  * action - Action in a table
---
--- Returns:
---  * None
function mod.updateAction(button, group, actionTitle, handlerID, action)

    local buttons = mod._items()

    button = tostring(button)
    if not buttons[group] then
        buttons[group] = {}
    end
    if not buttons[group][button] then
        buttons[group][button] = {}
    end
    buttons[group][button]["actionTitle"] = actionTitle
    buttons[group][button]["handlerID"] = handlerID
    buttons[group][button]["action"] = action

    mod._items(buttons)
    mod.update()

end

--- plugins.core.midi.manager.setItem(item, button, group, value) -> none
--- Function
--- Stores a MIDI item in Preferences.
---
--- Parameters:
---  * item - The item you want to set.
---  * button - Button ID as string
---  * group - Group ID as string
---  * value - The value of the item you want to set.
---
--- Returns:
---  * None
function mod.setItem(item, button, group, value)
    local buttons = mod._items()

    button = tostring(button)

    if not buttons[group] then
        buttons[group] = {}
    end
    if not buttons[group][button] then
        buttons[group][button] = {}
    end
    buttons[group][button][item] = value

    mod._items(buttons)
    mod.update()
end

--- plugins.core.midi.manager.getItem(item, button, group) -> table
--- Function
--- Gets a MIDI item from Preferences.
---
--- Parameters:
---  * item - The item you want to get.
---  * button - Button ID as string
---  * group - Group ID as string
---
--- Returns:
---  * A table otherwise `nil`
function mod.getItem(item, button, group)
    local items = mod._items()
    if items[group] and items[group][button] and items[group][button][item] then
        return items[group][button][item]
    else
        return nil
    end
end

--- plugins.core.midi.manager.getItems() -> tables
--- Function
--- Gets all the MIDI items in a table.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table
function mod.getItems()
    return mod._items()
end

--- plugins.core.midi.manager.activeGroup() -> string
--- Function
--- Returns the active group.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Returns the active group or `manager.defaultGroup` as a string.
function mod.activeGroup()

    local groupStatus = mod._groupStatus
    for group, status in pairs(groupStatus) do
        if status then
            return group
        end
    end
    return mod.defaultGroup

end

--- plugins.core.midi.manager.activeSubGroup() -> string
--- Function
--- Returns the active sub-group.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Returns the active sub group as string
function mod.activeSubGroup()
    local currentSubGroup = mod._currentSubGroup()
    local result = 1
    local activeGroup = mod.activeGroup()
    if currentSubGroup[activeGroup] then
        result = currentSubGroup[activeGroup]
    end
    return tostring(result)
end

--- plugins.core.midi.manager.gotoSubGroup() -> none
--- Function
--- Loads a specific sub-group.
---
--- Parameters:
---  * id - The ID of the sub-group.
---
--- Returns:
---  * None
function mod.gotoSubGroup(id)
    local activeGroup = mod.activeGroup()
    local currentSubGroup = mod._currentSubGroup()
    currentSubGroup[activeGroup] = id
    mod._currentSubGroup(currentSubGroup)
end

--- plugins.core.midi.manager.nextSubGroup() -> none
--- Function
--- Goes to the next sub-group for the active group.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.nextSubGroup()
    local activeGroup = mod.activeGroup()
    local currentSubGroup = mod._currentSubGroup()
    local currentSubGroupValue = currentSubGroup[activeGroup] or 1
    if currentSubGroupValue < mod.numberOfSubGroups then
        currentSubGroup[activeGroup] = currentSubGroupValue + 1
    else
        currentSubGroup[activeGroup] = 1
    end
    mod._currentSubGroup(currentSubGroup)
end

--- plugins.core.midi.manager.previousSubGroup() -> none
--- Function
--- Goes to the previous sub-group for the active group.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.previousSubGroup()
    local activeGroup = mod.activeGroup()
    local currentSubGroup = mod._currentSubGroup()
    local currentSubGroupValue = currentSubGroup[activeGroup] or 1
    if currentSubGroupValue == 1 then
        currentSubGroup[activeGroup] = mod.numberOfSubGroups
    else
        currentSubGroup[activeGroup] = currentSubGroupValue - 1
    end
    mod._currentSubGroup(currentSubGroup)
end

--- plugins.core.midi.manager.groupStatus(groupID, status) -> none
--- Function
--- Updates a group's visibility status.
---
--- Parameters:
---  * groupID - the group you want to update as a string.
---  * status - the status of the group as a boolean.
---
--- Returns:
---  * None
function mod.groupStatus(groupID, status)
    mod._groupStatus[groupID] = status
    mod.update()
end

--- plugins.core.midi.manager.registerListenMMCFunction(id, fn) -> none
--- Function
--- Registers a MMC Listening Function
---
--- Parameters:
---  * id - The group ID as a string.
---  * fn - The function you want to trigger.
---
--- Returns:
---  * None
function mod.registerListenMMCFunction(id, fn)
    if id and type(id) == "string" and fn and type(fn) == "function" then
        mod._listenMMCFunctions[id] = fn
    else
        log.ef("Could not register MMC listening function. id: %s, fn: %s", id, fn)
    end
end

--- plugins.core.midi.manager.registerListenMTCFunction(id, fn) -> none
--- Function
--- Registers a MTC Listening Function
---
--- Parameters:
---  * id - The group ID as a string.
---  * fn - The function you want to trigger.
---
--- Returns:
---  * None
function mod.registerListenMTCFunction(id, fn)
    if id and type(id) == "string" and fn and type(fn) == "function" then
        mod._listenMTCFunctions[id] = fn
    else
        log.ef("Could not register MTC listening function. id: %s, fn: %s", id, fn)
    end
end

--- plugins.core.midi.manager.registerCallback(id, fn) -> none
--- Function
--- Registers a MIDI Callback.
---
--- Parameters:
---  * id - The ID as a string.
---  * fn - The function you want to trigger.
---
--- Returns:
---  * None
function mod.registerCallback(id, fn)
    if id and type(id) == "string" and fn and type(fn) == "function" then
        mod._generalCallbacks[id] = fn
    else
        log.ef("Could not register callback function. id: %s, fn: %s", id, fn)
    end
end

-- convertSingleHexStringToDecimalString(hex) -> string
-- Function
-- Converts a single hex string (i.e. "3") to a binary string (i.e. "0011")
--
-- Parameters:
--  * hex - A single string character
--
-- Returns:
--  * A four character string
local function convertSingleHexStringToDecimalString(hex)
    local lookup = {
        ["0"]   = "0000",
        ["1"]   = "0001",
        ["2"]   = "0010",
        ["3"]   = "0011",
        ["4"]   = "0100",
        ["5"]   = "0101",
        ["6"]   = "0110",
        ["7"]   = "0111",
        ["8"]   = "1000",
        ["9"]   = "1001",
        ["A"]   = "1010",
        ["B"]   = "1011",
        ["C"]   = "1100",
        ["D"]   = "1101",
        ["E"]   = "1110",
        ["F"]   = "1111",
    }
    return lookup[hex]
end

--- plugins.core.midi.manager.sendMMC(deviceName, virtual, commandType, parameters) -> boolean
--- Function
--- Sends MMC Data to a MIDI Device.
---
--- Parameters:
---  * deviceName - The MIDI Device name.
---  * virtual - Is this MIDI Device virtual as boolean?
---  * channelNumber - "00" to "7F", where "7F" is all devices.
---  * commandType - Command Type as string (see possible options in Notes below)
---  * parameters - Optional parameters in a table.
---
--- Returns:
---  * `true` if successfully sent otherwise `false`.
---
--- Notes:
---  * The possible MMC commands are:
---    * STOP
---    * PLAY
---    * DEFERRED_PLAY
---    * FAST_FORWARD
---    * REWIND
---    * RECORD_STROBE
---    * RECORD_EXIT
---    * RECORD_PAUSE
---    * PAUSE
---    * EJECT
---    * CHASE
---    * MMC_RESET
---    * WRITE
---    * GOTO
---      * timecode - Timecode as string, in the following format: "hh:mm:ss:fr" (i.e. "12:03:03:13").
---      * frameRate - Frame Rate as string, possible options include: "24", "25", "30 DF" or "30 NDF".
---      * subFrame - Subframe as string.
---    * ERROR
---    * SHUTTLE
--- * Example Usage:
---   ```lua
---     _plugins("core.midi.manager").sendMMC("CommandPost", false, "7F", "GOTO", {timecode="01:02:03:04", frameRate="25", subFrame="00"})
---   ```
function mod.sendMMC(deviceName, virtual, channelNumber, commandType, parameters)

    if deviceName and virtual then
        deviceName = "virtual_" .. deviceName
    end
    local device
    if mod._midiDevices and mod._midiDevices[deviceName] then
        device = mod._midiDevices[deviceName]
    else
        log.ef("MIDI Device not found: %s (virtual: %s)", deviceName, virtual)
        return false
    end

    local parameterString = ""
    if commandType and mod.MMC_COMMAND_TYPE[commandType] then
        if commandType == "GOTO" then
            if parameters and type(parameters) == "table" and parameters.timecode and parameters.frameRate and parameters.subFrame then

                local timecode = parameters.timecode
                local frameRate = parameters.frameRate
                local subFrame = parameters.subFrame

                --------------------------------------------------------------------------------
                -- Only handle valid timecode values:
                --------------------------------------------------------------------------------
                if not string.find(timecode, "%d%d:%d%d:%d%d:%d%d") then
                    log.ef("Invalid GOTO MMC Timecode: %s", timecode)
                    return
                end

                --------------------------------------------------------------------------------
                -- Remove timecode formatting:
                --------------------------------------------------------------------------------
                local value = string.gsub(timecode, ":", "")

                local decimalHours = tonumber(string.sub(value, 1, 2))
                local decimalMinutes = tonumber(string.sub(value, 3, 4))
                local decimalSeconds = tonumber(string.sub(value, 5, 6))
                local decimalFrames = tonumber(string.sub(value, 7, 8))

                --------------------------------------------------------------------------------
                -- hr:
                -- 7 65 43210
                -- 0 yy zzzzz
                --      yy: 00 = 24fps
                --          01 = 25fps
                --          10 = 30fps (drop frame)
                --          11 = 30fps (non drop frame)
                --      zzzzz: hours (00 -> 23)
                --------------------------------------------------------------------------------

                local frameRateAsDecimalCode = tonumber(mod.MMC_TIMECODE_TYPE[frameRate])

                local hexHours = string.format("%02x", (frameRateAsDecimalCode << 5) + decimalHours)
                local hexMinutes = string.format("%02x", decimalMinutes)
                local hexSeconds = string.format("%02x", decimalSeconds)
                local hexFrames = string.format("%02x", decimalFrames)

                parameterString = "06 01 " .. hexHours .. " " .. hexMinutes .. " " .. hexSeconds .. " " .. hexFrames .. " " .. subFrame

            else
                log.ef("Bad GOTO MMC Parameters: %s", parameters and inspect(parameters))
            end
        end
    else
        log.ef("Invalid MMC Command: %s", commandType)
        return false
    end

    if channelNumber and commandType and parameterString then
        local message = "F0 7F " .. channelNumber .. " 06 " .. mod.MMC_COMMAND_TYPE[commandType] .. parameterString .. " F7"
        device:sendSysex(message)
    end

end

--- plugins.core.midi.manager.processMMC(sysexData) -> string, ...
--- Function
--- Process MMC Data
---
--- Parameters:
---  * sysexData - Sysex Data as Hex String
---
--- Returns:
---  * A string with the MMC command, and any additional parameters as per below notes.
---
--- Notes:
---  * The possible MMC commands are:
---    * STOP
---    * PLAY
---    * DEFERRED_PLAY
---    * FAST_FORWARD
---    * REWIND
---    * RECORD_STROBE
---    * RECORD_EXIT
---    * RECORD_PAUSE
---    * PAUSE
---    * EJECT
---    * CHASE
---    * MMC_RESET
---    * WRITE
---    * GOTO
---      * timecode - Timecode as string, in the following format: "hh:mm:ss:fr" (i.e. "12:03:03:13").
---      * frameRate - Frame Rate as string, possible options include: "24", "25", "30 DF" or "30 NDF".
---      * subframe - Subframe as string.
---    * ERROR
---    * SHUTTLE
function mod.processMMC(sysexData)
    ---------------------------------------------------------------------------------------------
    -- An MMC message is either an MMC command (Sub-ID#1=06) or an MMC response
    -- (Sub-ID#1=07). As a SysEx message it is formatted (all numbers hexadecimal):
    --
    --      F0 7F <Device-ID> <06|07> [<Sub-ID#2> [<parameters>]] F7
    --      Device-ID: MMC device's ID#; value 00-7F (7F = all devices); AKA "channel number"
    ---------------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------------
    -- Split sysexData into individual components:
    ---------------------------------------------------------------------------------------------
    local data = {}
    for c in sysexData:gmatch"." do
        table.insert(data, c)
    end

    if data then
        if data[1] == "0" and data[2] == "6" then
            --------------------------------------------------------------------------------
            -- We have a command:
            --------------------------------------------------------------------------------
            if data[3] == "0" and data[4] == "1" then
                --------------------------------------------------------------------------------
                -- 01 Stop
                --------------------------------------------------------------------------------
                return "STOP"
            elseif data[3] == "0" and data[4] == "2" then
                --------------------------------------------------------------------------------
                -- 02 Play
                --------------------------------------------------------------------------------
                return "PLAY"
            elseif data[3] == "0" and data[4] == "3" then
                --------------------------------------------------------------------------------
                -- 03 Deferred Play (play after no longer busy)
                --------------------------------------------------------------------------------
                return "DEFERRED_PLAY"
            elseif data[3] == "0" and data[4] == "4" then
                --------------------------------------------------------------------------------
                -- 04 Fast Forward
                --------------------------------------------------------------------------------
                return "FAST_FORWARD"
            elseif data[3] == "0" and data[4] == "5" then
                --------------------------------------------------------------------------------
                -- 05 Rewind
                --------------------------------------------------------------------------------
                return "REWIND"
            elseif data[3] == "0" and data[4] == "6" then
                --------------------------------------------------------------------------------
                -- 06 Record Strobe (AKA [[Punch in/out|Punch In]])
                --------------------------------------------------------------------------------
                return "RECORD_STROBE"
            elseif data[3] == "0" and data[4] == "7" then
                --------------------------------------------------------------------------------
                -- 07 Record Exit (AKA [[Punch out (music)|Punch out]])
                --------------------------------------------------------------------------------
                return "RECORD_EXIT"
            elseif data[3] == "0" and data[4] == "8" then
                --------------------------------------------------------------------------------
                -- 08 Record Pause
                --------------------------------------------------------------------------------
                return "RECORD_PAUSE"
            elseif data[3] == "0" and data[4] == "9" then
                --------------------------------------------------------------------------------
                -- 09 Pause (pause playback)
                --------------------------------------------------------------------------------
                return "PAUSE"
            elseif data[3] == "0" and data[4] == "A" then
                --------------------------------------------------------------------------------
                -- 0A Eject (disengage media container from MMC device)
                --------------------------------------------------------------------------------
                return "EJECT"
            elseif data[3] == "0" and data[4] == "B" then
                --------------------------------------------------------------------------------
                -- 0B Chase
                --------------------------------------------------------------------------------
                return "CHASE"
            elseif data[3] == "0" and data[4] == "D" then
                --------------------------------------------------------------------------------
                -- 0D MMC Reset (to default/startup state)
                --------------------------------------------------------------------------------
                return "MMC_RESET"
            elseif data[3] == "4" and data[4] == "0" then
                --------------------------------------------------------------------------------
                -- 40 Write (AKA Record Ready, AKA Arm Tracks)
                --    parameters: <length1> 4F <length2> <track-bitmap-bytes>
                --------------------------------------------------------------------------------
                return "WRITE"
            elseif data[3] == "4" and data[4] == "4" then
                --------------------------------------------------------------------------------
                -- 44 Goto (AKA Locate)
                --    parameters: <length>=06 01 <hours> <minutes> <seconds> <frames> <subframes>
                --------------------------------------------------------------------------------

                --------------------------------------------------------------------------------
                -- F0 7F <Device-ID> 06 44 <length>=06 01 <hr> <mn> <sc> <fr> <ff> F7
                --
                -- Sub-ID#2 =44: LOCATE command
                -- length: 06 Data byte count (always six bytes)
                -- subcommand: 01 TARGET
                -- hr: hours and type (as with MTC Fullframe); values 0-17 (= 0-23 decimal)
                -- mn: minutes; values 0-3B (= 0-59 decimal)
                -- sc: seconds; values 0-3B (= 0-59 decimal)
                -- fr: frames; values 0-1D (= 0-29 decimal)
                -- ff: sub-frames / fractional frames (leave at zero if un-sure); values 0-63 (= 0-99 decimal)
                --
                --
                -- The data byte for the Hours hi nybble and frame-rate, the bits are interpreted as follows:
                -- 0nnn xyyd
                --
                -- x is unused and set to 0.
                -- d is the high bit of the Hours count.
                -- yy defines the frame-rate as follows:
                -- 00 = 24 fps (Film)
                -- 01 = 25 fps (EBU)
                -- 10 = 30 fps (SMPTE drop-frame)
                -- 11 = 30 fps (SMPTE non-drop frame)
                --------------------------------------------------------------------------------
                if data[5] == "0" and data[6] == "6" and data[7] == "0" and data[8] == "1" then

                    local hourHex = data[9] .. data[10]
                    local minHex = data[11] .. data[12]
                    local secHex = data[13] .. data[14]
                    local frameHex = data[15] .. data[16]
                    local subframeHex = data[17] .. data[18]

                    local hour, frameRate
                    if hourHex then
                        local hourDec = tostring(tonumber(hourHex,16))
                        local hourBin = convertSingleHexStringToDecimalString(hourDec:sub(1, 1)) .. convertSingleHexStringToDecimalString(hourDec:sub(2, 2))
                        frameRate = hourBin:sub(6,7)
                        hour = hourDec & 0x1f
                    end

                    local min = minHex and tonumber(minHex,16) or 0
                    local sec = secHex and tonumber(secHex,16) or 0
                    local frame = frameHex and tonumber(frameHex,16) or 0
                    local subframe = subframeHex and tonumber(subframeHex,16) or 0

                    local frameRateString = mod.MMC_TIMECODE_TYPE[frameRate] or "UNKNOWN"

                    local timecode = string.format("%02d", hour) .. ":" .. string.format("%02d", min) .. ":" .. string.format("%02d", sec) .. ":" .. string.format("%02d", frame)

                    return "GOTO", timecode, frameRateString, string.format("%02d", subframe)
                else
                    return "ERROR", "Bad Goto Data"
                end
            elseif data[3] == "4" and data[4] == "7" then
                --------------------------------------------------------------------------------
                -- 47 Shuttle
                --    parameters: <length>=03 <sh> <sm> <sl> (MIDI Standard Speed codes)
                --------------------------------------------------------------------------------
                return "SHUTTLE"
            end
        --elseif data[1] == "0" and data[2] == "7" then
            --------------------------------------------------------------------------------
            -- We have a response:
            --------------------------------------------------------------------------------
        end
    end
    return nil
end

--- plugins.core.midi.manager.MMC_COMMAND_TYPE -> table
--- Constant
--- MMC Command Types
mod.MMC_COMMAND_TYPE = {
    ["STOP"]                = "01",
    ["PLAY"]                = "02",
    ["DEFERRED_PLAY"]       = "03",
    ["FAST_FORWARD"]        = "04",
    ["REWIND"]              = "05",
    ["RECORD_STROBE"]       = "06",
    ["RECORD_EXIT"]         = "07",
    ["RECORD_PAUSE"]        = "08",
    ["PAUSE"]               = "09",
    ["EJECT"]               = "0A",
    ["CHASE"]               = "0B",
    ["MMC_RESET"]           = "0D",
    ["WRITE"]               = "40",
    ["GOTO"]                = "44",
    ["SHUTTLE"]             = "47",
}

--- plugins.core.midi.manager.MMC_TIMECODE_TYPE -> table
--- Constant
--- MMC Timecode Type
mod.MMC_TIMECODE_TYPE = {
    ["00"] = "24",              -- 24 fps (Film)
    ["01"] = "25",              -- 25 fps (EBU)
    ["10"] = "30 DF",           -- 30 fps (SMPTE drop-frame)
    ["11"] = "30 NDF",          -- 30 fps (SMPTE non-drop frame)

    --------------------------------------------------------------------------------
    -- REVERSE:
    --------------------------------------------------------------------------------
    ["24"] = "00",              -- 24 fps (Film)
    ["25"] = "01",              -- 25 fps (EBU)
    ["30 DF"] = "10",           -- 30 fps (SMPTE drop-frame)
    ["30 NDF"] = "11",          -- 30 fps (SMPTE non-drop frame)
}

--- plugins.core.midi.manager.MTC_MESSAGE_TYPE -> table
--- Constant
--- MTC Message Types
mod.MTC_MESSAGE_TYPE = {
    [0] = "FRAME_LS",
    [1] = "FRAME_MS",
    [2] = "SECONDS_LS",
    [3] = "SECONDS_MS",
    [4] = "MINUTES_LS",
    [5] = "MINUTES_MS",
    [6] = "HOURS_LS",
    [7] = "HOURS_MS",
}

--- plugins.core.midi.manager.MTC_TIMECODE_TYPE -> table
--- Constant
--- MTC Timecode Type
mod.MTC_TIMECODE_TYPE = {
    [0] = "24",
    [1] = "25",
    [2] = "30 DF",
    [3] = "30 NDF",
}

--- plugins.core.midi.manager.MTC_COMMAND_TYPE -> table
--- Constant
--- MTC Command Type
mod.MTC_COMMAND_TYPE = {
    ["f1"] = "QUARTER_FRAME",
}

-- plugins.core.midi.manager._mtcBuffer -> table
-- Variable
-- MTC Buffer.
mod._mtcBuffer = {}

--- plugins.core.midi.manager.processMTC(mtcData) -> string, ...
--- Function
--- Process MTC Data
---
--- Parameters:
---  * mtcData - MTC Data as Hex String
---
--- Returns:
---  * A string with the MTC command, and any additional parameters.
function mod.processMTC(mtcData)

    ---------------------------------------------------------------------------------------------
    -- Split sysexData into individual components:
    ---------------------------------------------------------------------------------------------
    local data = {}
    for c in mtcData:gmatch"." do
        table.insert(data, c)
    end

    if data then
        if data[1] == "f" and data[2] == "1" then
            ---------------------------------------------------------------------------------------------
            -- Quarter Frame Messages (2 bytes)
            ---------------------------------------------------------------------------------------------
            local message = convertSingleHexStringToDecimalString(data[3]) .. convertSingleHexStringToDecimalString(data[4])
            if message then

                ---------------------------------------------------------------------------------------------
                -- Split nibble into individual components:
                ---------------------------------------------------------------------------------------------
                local nibble = {}
                for c in message:gmatch"." do
                    table.insert(nibble, c)
                end

                if nibble[1] == "0" then
                    local messageTypeBinary = nibble[2] .. nibble[3] .. nibble[4]
                    local messageTypeDecimal = tonumber(messageTypeBinary, 2)
                    local messageTypeString = mod.MTC_MESSAGE_TYPE[messageTypeDecimal]

                    mod._mtcBuffer[messageTypeString] = nibble[5] .. nibble[6] .. nibble[7] .. nibble[8]

                    if mod._mtcBuffer["FRAME_LS"] and mod._mtcBuffer["FRAME_MS"] and mod._mtcBuffer["SECONDS_LS"] and mod._mtcBuffer["SECONDS_MS"] and mod._mtcBuffer["MINUTES_LS"] and mod._mtcBuffer["MINUTES_MS"] and mod._mtcBuffer["HOURS_LS"] and mod._mtcBuffer["HOURS_MS"] then

                        local frameCount = string.sub(mod._mtcBuffer["FRAME_MS"] .. mod._mtcBuffer["FRAME_LS"], 4)
                        local secondsCount = string.sub(mod._mtcBuffer["SECONDS_MS"] .. mod._mtcBuffer["SECONDS_LS"], 3)
                        local minutesCount = string.sub(mod._mtcBuffer["MINUTES_MS"] .. mod._mtcBuffer["MINUTES_LS"], 3)
                        local hoursCount = string.sub(mod._mtcBuffer["HOURS_MS"] .. mod._mtcBuffer["HOURS_LS"], 4)
                        local framerateCount = string.sub(mod._mtcBuffer["HOURS_MS"] .. mod._mtcBuffer["HOURS_LS"], 2, 3)

                        local frame = string.format("%02d", tonumber(frameCount, 2))
                        local sec = string.format("%02d", tonumber(secondsCount, 2))
                        local min = string.format("%02d", tonumber(minutesCount, 2))
                        local hour = string.format("%02d", tonumber(hoursCount, 2))

                        local framerate = mod.MTC_TIMECODE_TYPE[tonumber(framerateCount, 2)]

                        local timecode = hour .. ":" .. min .. ":" .. sec .. ":" .. frame

                        if timecode ~= mod._lastMTC then
                            mod._lastMTC = timecode
                            return "QUARTER_FRAME", timecode, framerate
                        else
                            mod._lastMTC = timecode
                        end

                        ---------------------------------------------------------------------------------------------
                        -- Clear the buffer:
                        ---------------------------------------------------------------------------------------------
                        mod._mtcBuffer = nil
                        mod._mtcBuffer = {}
                    end
                end
            end
        end
    end
    return nil
end

--- plugins.core.midi.manager.midiCallback(object, deviceName, commandType, description, metadata) -> none
--- Function
--- MIDI Callback
---
--- Parameters:
---  * object - The `hs.midi` userdata object
---  * deviceName - Device name as string
---  * commandType - Command Type as string
---  * description - Description as string
---  * metadata - A table containing metadata for the MIDI command
---
--- Returns:
---  * None
function mod.midiCallback(object, deviceName, commandType, description, metadata)

    --------------------------------------------------------------------------------
    -- Get Active Group:
    --------------------------------------------------------------------------------
    local activeGroup = mod.activeGroup() .. mod.activeSubGroup()

    --------------------------------------------------------------------------------
    -- Get Items:
    --------------------------------------------------------------------------------
    local items = mod._items()

    --------------------------------------------------------------------------------
    -- Prefix Virtual Devices:
    --------------------------------------------------------------------------------
    if metadata.isVirtual == true then
        deviceName = "virtual_" .. deviceName
    end

    --------------------------------------------------------------------------------
    -- Listen for MMC Callbacks:
    ---------------------------- ----------------------------------------------------
    local listenMMCDevice = mod.listenMMCDevice()
    if mod.listenMMC() and listenMMCDevice and listenMMCDevice == deviceName and commandType == "systemExclusive" then
        for _, v in pairs(mod._listenMMCFunctions) do
            timer.doAfter(0.0000000000000000000001, function()
                local mmcType, timecode, framerate, subframe = mod.processMMC(metadata.sysexData)
                if mmcType then
                    v(mmcType, timecode, framerate, subframe)
                end
            end)
        end
    end

    --------------------------------------------------------------------------------
    -- Listen for MTC Callbacks:
    --------------------------------------------------------------------------------
    local listenMTCDevice = mod.listenMTCDevice()
    if mod.listenMTC() and listenMTCDevice and listenMTCDevice == deviceName and commandType == "systemTimecodeQuarterFrame" then
        for _, v in pairs(mod._listenMTCFunctions) do
            timer.doAfter(0.0000000000000000000001, function()
                local mtcType, timecode, framerate = mod.processMTC(metadata.data)
                if mtcType then
                    v(mtcType, timecode, framerate)
                end
            end)
        end
    end

    --------------------------------------------------------------------------------
    -- Listen for General Callbacks:
    --------------------------------------------------------------------------------
    for _, v in pairs(mod._generalCallbacks) do
        timer.doAfter(0.0000000000000000000001, function()
            v(object, deviceName, commandType, description, metadata)
        end)
    end

    --------------------------------------------------------------------------------
    -- Support 14bit Control Change Messages:
    --------------------------------------------------------------------------------
    local controllerValue = metadata.controllerValue
    if metadata.fourteenBitCommand then
        controllerValue = metadata.fourteenBitValue
    end

    if items[activeGroup] then
        for _, item in pairs(items[activeGroup]) do
            if deviceName == item.device and item.channel == metadata.channel and item.commandType == commandType then
                --------------------------------------------------------------------------------
                -- Note On:
                --------------------------------------------------------------------------------
                if commandType == "noteOn" and metadata.velocity ~= 0 then
                    if tostring(item.number) == tostring(metadata.note) then
                        if item.handlerID and item.action then
                            local handler = mod._actionmanager.getHandler(item.handlerID)
                            handler:execute(item.action)
                        end
                        return
                    end
                --------------------------------------------------------------------------------
                -- Control Change:
                --------------------------------------------------------------------------------
                elseif commandType == "controlChange" then
                    if tostring(item.number) == tostring(metadata.controllerNumber) then
                        if item.handlerID and string.sub(item.handlerID, -13) and string.sub(item.handlerID, -13) == "_midicontrols" then
                            --------------------------------------------------------------------------------
                            -- MIDI Controls:
                            --------------------------------------------------------------------------------
                            local id = item.action.id
                            local control = controls:get(id)
                            local params = control:params()
                            if mod._alreadyProcessingCallback then
                                if mod._lastControllerNumber == metadata.controllerNumber and mod._lastControllerChannel == metadata.channel then
                                    if mod._lastControllerValue == controllerValue then
                                        return
                                    else
                                        timer.doAfter(0.0001, function()
                                            if metadata.timestamp == mod._lastTimestamp then
                                                params.fn(metadata, deviceName)
                                                mod._alreadyProcessingCallback = false
                                            end
                                        end)
                                    end
                                end
                                mod._lastTimestamp = metadata and metadata.timestamp
                            else
                                mod._alreadyProcessingCallback = true
                                timer.doAfter(0.000000000000000000001, function()
                                    params.fn(metadata, deviceName)
                                    mod._alreadyProcessingCallback = false
                                end)
                                mod._lastControllerNumber = metadata and metadata.controllerNumber
                                mod._lastControllerValue = metadata and controllerValue
                                mod._lastControllerChannel = metadata and metadata.channel
                            end
                        elseif tostring(item.value) == tostring(controllerValue) then
                            if item.handlerID and item.action then
                                local handler = mod._actionmanager.getHandler(item.handlerID)
                                handler:execute(item.action)
                            end
                            return
                        end
                    end
                --------------------------------------------------------------------------------
                -- Pitch Wheel Change:
                --------------------------------------------------------------------------------
                elseif commandType == "pitchWheelChange" then
                    if item.handlerID and string.sub(item.handlerID, -13) and string.sub(item.handlerID, -13) == "_midicontrols" then
                        --------------------------------------------------------------------------------
                        -- MIDI Controls for Pitch Wheel:
                        --------------------------------------------------------------------------------
                        local id = item.action.id
                        local control = controls:get(id)
                        local params = control:params()
                        if mod._alreadyProcessingCallback then
                            if mod._lastControllerChannel == metadata.channel then
                                if mod._lastPitchChange == metadata.pitchChange then
                                    return
                                else
                                    timer.doAfter(0.0001, function()
                                        if metadata.timestamp == mod._lastTimestamp then
                                            params.fn(metadata, deviceName)
                                            mod._alreadyProcessingCallback = false
                                        end
                                    end)
                                end
                            end
                            mod._lastTimestamp = metadata and metadata.timestamp
                        else
                            mod._alreadyProcessingCallback = true
                            timer.doAfter(0.000000000000000000001, function()
                                params.fn(metadata, deviceName)
                                mod._alreadyProcessingCallback = false
                            end)
                            mod._lastPitchChange = metadata and metadata.pitchChange
                            mod._lastControllerChannel = metadata and metadata.channel
                        end
                    elseif item.handlerID and item.action then
                        --------------------------------------------------------------------------------
                        -- Just trigger the handler if Pitch Wheel value changes at all:
                        --------------------------------------------------------------------------------
                        local handler = mod._actionmanager.getHandler(item.handlerID)
                        handler:execute(item.action)
                        return
                    end
                end
            end
        end
    end

end

--- plugins.core.midi.manager.devices() -> table
--- Function
--- Gets a table of Physical MIDI Device Names.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of Physical MIDI Device Names.
function mod.devices()
    return mod._deviceNames
end

--- plugins.core.midi.manager.virtualDevices() -> table
--- Function
--- Gets a table of Virtual MIDI Source Names.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of Virtual MIDI Source Names.
function mod.virtualDevices()
    return mod._virtualDevices
end

-- plugins.core.midi.manager._forcefullyWatchMIDIDevices -> table
-- Variable
-- Table of forced MIDI Devices.
mod._forcefullyWatchMIDIDevices = {}

--- plugins.core.midi.manager.forcefullyWatchMIDIDevices(devices) -> none
--- Function
--- Forces CommandPost to watch a table of MIDI devices.
---
--- Parameters:
---  * devices - A table containing all the device names you want to always watch.
---
--- Returns:
---  * A table of Virtual MIDI Source Names.
function mod.forcefullyWatchMIDIDevices(devices)
    if devices and type(devices) == "table" then
        for _, device in pairs(devices) do
            table.insert(mod._forcefullyWatchMIDIDevices, device)
        end
    end
end

--- plugins.core.midi.manager.getDevice(deviceName, virtual) -> hs.midi object | nil
--- Function
--- Gets a MIDI Device.
---
--- Parameters:
---  * deviceName - The device name.
---  * virtual - A boolean that defines whether or not the device is virtual.
---
--- Returns:
---  * A `hs.midi` object or nil if no MIDI device by that name exists.
function mod.getDevice(deviceName, virtual)
    if virtual then
        deviceName = "virtual_" .. deviceName
    end
    return mod._midiDevices and mod._midiDevices[deviceName]
end

--- plugins.core.midi.manager.start() -> boolean
--- Function
--- Starts the MIDI Plugin
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.start()
    if not mod._midiDevices then
        --log.df("Starting MIDI Watchers")
        mod._midiDevices = {}
    end

    --------------------------------------------------------------------------------
    -- Setup MIDI Device Callback:
    --------------------------------------------------------------------------------
    midi.deviceCallback(function(devices, virtualDevices)
        mod._deviceNames = devices
        mod._virtualDevices = virtualDevices
        --log.df("MIDI Devices Updated (%s physical, %s virtual)", #devices, #virtualDevices)
    end)

    --------------------------------------------------------------------------------
    -- For performance, we only use watchers for USED devices:
    --------------------------------------------------------------------------------
    local items = mod._items()
    local usedDevices = {}
    for _, v in pairs(items) do
        for _, vv in pairs(v) do
            table.insert(usedDevices, vv.device)
        end
    end

    --------------------------------------------------------------------------------
    -- Take into account Sync features too:
    --------------------------------------------------------------------------------
    local transmitMMCDevice = mod.transmitMMCDevice()
    if mod.transmitMMC() and transmitMMCDevice and type(transmitMMCDevice) == "string" and transmitMMCDevice ~= "" then
        table.insert(usedDevices, transmitMMCDevice)
    end

    local listenMMCDevice = mod.listenMMCDevice()
    if mod.listenMMC() and listenMMCDevice and type(listenMMCDevice) == "string" and listenMMCDevice ~= "" then
        table.insert(usedDevices, listenMMCDevice)
    end

    local transmitMTCDevice = mod.transmitMTCDevice()
    if mod.transmitMTC() and transmitMTCDevice and type(transmitMTCDevice) == "string" and transmitMTCDevice ~= "" then
        table.insert(usedDevices, transmitMTCDevice)
    end

    local listenMTCDevice = mod.listenMTCDevice()
    if mod.listenMTC() and listenMTCDevice and type(listenMTCDevice) == "string" and listenMTCDevice ~= "" then
        table.insert(usedDevices, listenMTCDevice)
    end

    --------------------------------------------------------------------------------
    -- Take into account forced MIDI Devices:
    --------------------------------------------------------------------------------
    for _, device in pairs(mod._forcefullyWatchMIDIDevices) do
        table.insert(mod._forcefullyWatchMIDIDevices, device)
    end

    --------------------------------------------------------------------------------
    -- Create a table of both Physical & Virtual MIDI Devices:
    --------------------------------------------------------------------------------
    local devices = {}
    for _, v in pairs(mod.devices()) do
        table.insert(devices, v)
    end
    for _, v in pairs(mod.virtualDevices()) do
        table.insert(devices, "virtual_" .. v)
    end

    --------------------------------------------------------------------------------
    -- Create MIDI Watchers for MIDI Devices that have actions assigned to them:
    --------------------------------------------------------------------------------
    for _, deviceName in ipairs(devices) do
        if not mod._midiDevices[deviceName] then
            if fnutils.contains(usedDevices, deviceName) then
                if string.sub(deviceName, 1, 8) == "virtual_" then
                    --log.df("Creating new Virtual MIDI Source Watcher: %s", deviceName)
                    mod._midiDevices[deviceName] = midi.newVirtualSource(string.sub(deviceName, 9))
                    if mod._midiDevices[deviceName] then
                        mod._midiDevices[deviceName]:callback(mod.midiCallback)
                    end
                else
                    --log.df("Creating new Physical MIDI Watcher: %s", deviceName)
                    mod._midiDevices[deviceName] = midi.new(deviceName)
                    if mod._midiDevices[deviceName] then
                        mod._midiDevices[deviceName]:callback(mod.midiCallback)
                    end
                end
            end
        end
    end
end

--- plugins.core.midi.manager.start() -> boolean
--- Function
--- Stops the MIDI Plugin
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.stop()
    --------------------------------------------------------------------------------
    -- Destroy MIDI Watchers:
    --------------------------------------------------------------------------------
    --log.df("Stopping MIDI Watchers")
    if mod._midiDevices and type(mod._midiDevices) == "table" then
        for _, id in pairs(mod._midiDevices) do
            mod._midiDevices[id] = nil
        end
        mod._midiDevices = nil
    end

    --------------------------------------------------------------------------------
    -- Destroy MIDI Device Callback:
    --------------------------------------------------------------------------------
    midi.deviceCallback(nil)

    --------------------------------------------------------------------------------
    -- Garbage Collection:
    --------------------------------------------------------------------------------
    collectgarbage()
end

--- plugins.core.midi.manager.update() -> none
--- Function
--- Updates the MIDI Watchers.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.update()
    --log.df("Updating MIDI Watchers")
    if mod.enabled() or mod.listenMTC() or mod.listenMMC() or mod.transmitMMC() or mod.transmitMTC() then

        --------------------------------------------------------------------------------
        -- Start MIDI:
        --------------------------------------------------------------------------------
        mod.start()

        --------------------------------------------------------------------------------
        -- Update the prop, so that any other plugins watching this prop also update:
        --------------------------------------------------------------------------------
        mod.transmitMTC:update()
        mod.transmitMMC:update()
    else
        mod.stop()
    end
end

--- plugins.core.midi.manager.enabled <cp.prop: boolean>
--- Field
--- Enable or disable MIDI Support.
mod.enabled = config.prop("enableMIDI", false):watch(function()
    mod.update()
end)

--- plugins.core.midi.manager.init(deps, env) -> none
--- Function
--- Initialises the MIDI Plugin
---
--- Parameters:
---  * deps - Dependencies Table
---  * env - Environment Table
---
--- Returns:
---  * None
function mod.init(deps)
    mod._actionmanager = deps.actionmanager
    return mod
end

--------------------------------------------------------------------------------
--
-- MIDI SYNC:
--
--------------------------------------------------------------------------------

--- plugins.core.midi.manager.transmitMMC <cp.prop: boolean>
--- Field
--- Enable or disable Transmit MMC Support.
mod.transmitMMC = config.prop("transmitMMC", false)

--- plugins.core.midi.manager.listenMMC <cp.prop: boolean>
--- Field
--- Enable or disable Listen MMC Support.
mod.listenMMC = config.prop("listenMMC", false)

--- plugins.core.midi.manager.transmitMTC <cp.prop: boolean>
--- Field
--- Enable or disable Transmit MTC Support.
mod.transmitMTC = config.prop("transmitMTC", false)

--- plugins.core.midi.manager.listenMTC <cp.prop: boolean>
--- Field
--- Enable or disable Listen MTC Support.
mod.listenMTC = config.prop("listenMTC", false)

--- plugins.core.midi.manager.transmitMMCDevice <cp.prop: string>
--- Field
--- MIDI Device
mod.transmitMMCDevice = config.prop("transmitMMCDevice", "")

--- plugins.core.midi.manager.listenMMCDevice <cp.prop: string>
--- Field
--- MIDI Device
mod.listenMMCDevice = config.prop("listenMMCDevice", "")

--- plugins.core.midi.manager.transmitMTCDevice <cp.prop: string>
--- Field
--- MIDI Device
mod.transmitMTCDevice = config.prop("transmitMTCDevice", "")

--- plugins.core.midi.manager.listenMTCDevice <cp.prop: string>
--- Field
--- MIDI Device
mod.listenMTCDevice = config.prop("listenMTCDevice", "")

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id          = "core.midi.manager",
    group       = "core",
    required    = true,
    dependencies    = {
        ["core.action.manager"]             = "actionmanager",
        ["core.commands.global"]            = "global",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)
    --------------------------------------------------------------------------------
    -- Get list of MIDI devices:
    --------------------------------------------------------------------------------
    mod._deviceNames = midi.devices() or {}

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    local global = deps.global
    global:add("cpMIDI")
        :whenActivated(mod.toggle)
        :groupedBy("commandPost")

    return mod.init(deps, env)
end

--------------------------------------------------------------------------------
-- POST INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.postInit(deps)

    --------------------------------------------------------------------------------
    -- Setup Actions:
    --------------------------------------------------------------------------------
    mod._handlers = {}
    local controlGroups = controls.allGroups()
    for _, groupID in pairs(controlGroups) do
        mod._handlers[groupID] = deps.actionmanager.addHandler(groupID .. "_" .. "midicontrols", groupID)
            :onChoices(function(choices)
                --------------------------------------------------------------------------------
                -- Choices:
                --------------------------------------------------------------------------------
                local allControls = controls:getAll()
                for _, control in pairs(allControls) do

                    local id = control:id()
                    local params = control:params()

                    local action = {
                        id      = id,
                    }

                    if params.group == groupID then
                        choices:add(params.text)
                            :subText(params.subText)
                            :params(action)
                            :id(id)
                    end

                end
                return choices
            end)
            :onExecute(function() end)
    end

    --------------------------------------------------------------------------------
    -- Start Plugin:
    --------------------------------------------------------------------------------
    mod.update()

end

return plugin