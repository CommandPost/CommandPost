--- === plugins.core.loupedeckplus.prefs.default ===
---
--- Default Loupedeck+ Layout.

local default = {
  fcpx1 = {
    ["102Press"] = {
      action = "ColorBoard-ToggleAllCorrection",
      actionTitle = "Toggle Color Correction Effects on/off",
      handlerID = "fcpx_shortcuts"
    },
    ["1Left"] = {
      action = {
        id = "colorWheelMasterDown"
      },
      actionTitle = "Color Wheel - Master - Nudge Down",
      handlerID = "fcpx_cmds"
    },
    ["1Press"] = {
      action = {
        id = "colorWheelMasterReset"
      },
      actionTitle = "Color Wheel - Master - Reset",
      handlerID = "fcpx_cmds"
    },
    ["1Right"] = {
      action = {
        id = "colorWheelMasterUp"
      },
      actionTitle = "Color Wheel - Master - Nudge Up",
      handlerID = "fcpx_cmds"
    },
    ["38Left"] = {
      action = {
        id = "colorWheelTemperatureDown"
      },
      actionTitle = "Color Wheel - Temperature - Nudge Down",
      handlerID = "fcpx_cmds"
    },
    ["38Press"] = {
      action = {
        id = "colorWheelTemperatureReset"
      },
      actionTitle = "Color Wheel - Temperature - Reset",
      handlerID = "fcpx_cmds"
    },
    ["38Right"] = {
      action = {
        id = "colorWheelTemperatureUp"
      },
      actionTitle = "Color Wheel - Temperature - Nudge Up",
      handlerID = "fcpx_cmds"
    },
    ["39Left"] = {
      action = {
        id = "colorWheelTintDown"
      },
      actionTitle = "Color Wheel - Tint - Nudge Down",
      handlerID = "fcpx_cmds"
    },
    ["39Press"] = {
      action = {
        id = "colorWheelTintReset"
      },
      actionTitle = "Color Wheel - Tint - Reset",
      handlerID = "fcpx_cmds"
    },
    ["39Right"] = {
      action = {
        id = "colorWheelTintUp"
      },
      actionTitle = "Color Wheel - Tint - Nudge Up",
      handlerID = "fcpx_cmds"
    },
    ["41Left"] = {
      action = {
        locale = "en",
        path = { "View", "Zoom Out" }
      },
      actionTitle = "Zoom Out",
      handlerID = "fcpx_menu"
    },
    ["41Press"] = {
      action = {
        locale = "en",
        path = { "View", "Zoom to Fit" }
      },
      actionTitle = "Zoom to Fit",
      handlerID = "fcpx_menu"
    },
    ["41Right"] = {
      action = {
        locale = "en",
        path = { "View", "Zoom In" }
      },
      actionTitle = "Zoom In",
      handlerID = "fcpx_menu"
    },
    ["48Left"] = {
      action = "JumpToPreviousFrame",
      actionTitle = "Go to Previous Frame",
      handlerID = "fcpx_shortcuts"
    },
    ["48Right"] = {
      action = "JumpToNextFrame",
      actionTitle = "Go to Next Frame",
      handlerID = "fcpx_shortcuts"
    },
    ["76Press"] = {
      action = "NextClip",
      actionTitle = "Next Clip",
      handlerID = "fcpx_shortcuts"
    },
    ["77Press"] = {
      action = "PreviousClip",
      actionTitle = "Previous Clip",
      handlerID = "fcpx_shortcuts"
    },
    ["78Press"] = {
      action = "PreviousEdit",
      actionTitle = "Go to Previous Edit",
      handlerID = "fcpx_shortcuts"
    },
    ["79Press"] = {
      action = "NextEdit",
      actionTitle = "Go to Next Edit",
      handlerID = "fcpx_shortcuts"
    },
    ["88Press"] = {
      action = "ShareDefaultDestination",
      actionTitle = "Export Using Default Share Destination…",
      handlerID = "fcpx_shortcuts"
    },
    ["95Press"] = {
      action = "UndoChanges",
      actionTitle = "Undo Changes",
      handlerID = "fcpx_shortcuts"
    },
    ["96Press"] = {
      action = "RedoChanges",
      actionTitle = "Redo Changes",
      handlerID = "fcpx_shortcuts"
    },
    ["97Press"] = {
      action = {
        locale = "en",
        path = { "View", "Playback", "Play Full Screen" }
      },
      actionTitle = "Play Full Screen",
      handlerID = "fcpx_menu"
    }
  }
}

return default