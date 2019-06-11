--- === plugins.core.midi.manager.default ===
---
--- Default MIDI Controls.

local default = {
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
      actionTitle = "Color Board Color Puck 1 (Angle)",
      handlerID = "fcpx_midicontrols"
    },
    ["4"] = {
      action = {
        id = "colorPercentagePuckOne"
      },
      actionTitle = "Color Board Color Puck 1 (Percentage)",
      handlerID = "fcpx_midicontrols"
    },
    ["5"] = {
      action = {
        id = "colorAnglePuckTwo"
      },
      actionTitle = "Color Board Color Puck 2 (Angle)",
      handlerID = "fcpx_midicontrols"
    },
    ["6"] = {
      action = {
        id = "colorPercentagePuckTwo"
      },
      actionTitle = "Color Board Color Puck 2 (Percentage)",
      handlerID = "fcpx_midicontrols"
    },
    ["7"] = {
      action = {
        id = "colorAnglePuckThree"
      },
      actionTitle = "Color Board Color Puck 3 (Angle)",
      handlerID = "fcpx_midicontrols"
    },
    ["8"] = {
      action = {
        id = "colorPercentagePuckThree"
      },
      actionTitle = "Color Board Color Puck 3 (Percentage)",
      handlerID = "fcpx_midicontrols"
    },
    ["9"] = {
      action = {
        id = "colorAnglePuckFour"
      },
      actionTitle = "Color Board Color Puck 4 (Angle)",
      handlerID = "fcpx_midicontrols"
    },
    ["10"] = {
      action = {
        id = "colorPercentagePuckFour"
      },
      actionTitle = "Color Board Color Puck 4 (Percentage)",
      handlerID = "fcpx_midicontrols"
    },
    ["11"] = {
      action = {
        id = "exposurePercentagePuckOne"
      },
      actionTitle = "Color Board Exposure Puck 1 (Percentage)",
      handlerID = "fcpx_midicontrols"
    },
    ["12"] = {
      action = {
        id = "exposurePercentagePuckTwo"
      },
      actionTitle = "Color Board Exposure Puck 2 (Percentage)",
      handlerID = "fcpx_midicontrols"
    },
    ["13"] = {
      action = {
        id = "exposurePercentagePuckThree"
      },
      actionTitle = "Color Board Exposure Puck 3 (Percentage)",
      handlerID = "fcpx_midicontrols"
    },
    ["14"] = {
      action = {
        id = "exposurePercentagePuckFour"
      },
      actionTitle = "Color Board Exposure Puck 4 (Percentage)",
      handlerID = "fcpx_midicontrols"
    },
    ["15"] = {
      action = {
        id = "saturationPercentagePuckOne"
      },
      actionTitle = "Color Board Saturation Puck 1 (Percentage)",
      handlerID = "fcpx_midicontrols"
    },
    ["16"] = {
      action = {
        id = "saturationPercentagePuckTwo"
      },
      actionTitle = "Color Board Saturation Puck 2 (Percentage)",
      handlerID = "fcpx_midicontrols"
    },
    ["17"] = {
      action = {
        id = "saturationPercentagePuckThree"
      },
      actionTitle = "Color Board Saturation Puck 3 (Percentage)",
      handlerID = "fcpx_midicontrols"
    },
    ["18"] = {
      action = {
        id = "saturationPercentagePuckFour"
      },
      actionTitle = "Color Board Saturation Puck 4 (Percentage)",
      handlerID = "fcpx_midicontrols"
    },
    ["19"] = {
      action = {
        id = "puckOne"
      },
      actionTitle = "Color Board Puck 1",
      handlerID = "fcpx_midicontrols"
    },
    ["20"] = {
      action = {
        id = "puckTwo"
      },
      actionTitle = "Color Board Puck 2",
      handlerID = "fcpx_midicontrols"
    },
    ["21"] = {
      action = {
        id = "puckThree"
      },
      actionTitle = "Color Board Puck 3",
      handlerID = "fcpx_midicontrols"
    },
    ["22"] = {
      action = {
        id = "puckFour"
      },
      actionTitle = "Color Board Puck 4",
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
      actionTitle = "Color Wheel Master (Horizontal)",
      handlerID = "fcpx_midicontrols"
    },
    ["4"] = {
      action = {
        id = "masterVertical"
      },
      actionTitle = "Color Wheel Master (Vertical)",
      handlerID = "fcpx_midicontrols"
    },
    ["5"] = {
      action = {
        id = "highlightsHorizontal"
      },
      actionTitle = "Color Wheel Highlights (Horizontal)",
      handlerID = "fcpx_midicontrols"
    },
    ["6"] = {
      action = {
        id = "highlightsVertical"
      },
      actionTitle = "Color Wheel Highlights (Vertical)",
      handlerID = "fcpx_midicontrols"
    },
    ["7"] = {
      action = {
        id = "midtonesHorizontal"
      },
      actionTitle = "Color Wheel Midtones (Horizontal)",
      handlerID = "fcpx_midicontrols"
    },
    ["8"] = {
      action = {
        id = "midtonesVertical"
      },
      actionTitle = "Color Wheel Midtones (Vertical)",
      handlerID = "fcpx_midicontrols"
    },
    ["9"] = {
      action = {
        id = "shadowsHorizontal"
      },
      actionTitle = "Color Wheel Shadows (Horizontal)",
      handlerID = "fcpx_midicontrols"
    },
    ["10"] = {
      action = {
        id = "shadowsVertical"
      },
      actionTitle = "Color Wheel Shadows (Vertical)",
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
      actionTitle = "Timeline Zoom",
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

return default