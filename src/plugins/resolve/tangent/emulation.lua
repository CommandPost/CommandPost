--- === plugins.resolve.tangent.emulation ===
---
--- Emulates a Tangent Element Panel.

local require               = require

local log                   = require "hs.logger".new "actions"

local image                 = require "hs.image"
local timer                 = require "hs.timer"

local config                = require "cp.config"
local i18n                  = require "cp.i18n"
local resolve               = require "cp.blackmagic.resolve"

local doAfter               = timer.doAfter
local imageFromPath         = image.imageFromPath

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
    --------------------------------------------------------------------------------
    -- Only load plugin if DaVinci Resolve is supported:
    --------------------------------------------------------------------------------
    if not resolve:isSupported() then return end

    local tangentManager = deps.tangentManager

    --------------------------------------------------------------------------------
    -- Request/Release Tangent Control:
    --------------------------------------------------------------------------------
    local global = deps.global
    global
        :add("requestFocus")
        :whenActivated(function()
            tangentManager:device():pluginRequestFocus()
        end)
        :titled("Request DaVinci Resolve Tangent Control")

    global
        :add("releaseFocus")
        :whenActivated(function()
            tangentManager:device():pluginReleaseFocus()
        end)
        :titled("Release DaVinci Resolve Tangent Control")

    --------------------------------------------------------------------------------
    -- Constants:
    --------------------------------------------------------------------------------
    local APP_ID            = "DaVinci Resolve"

    local CACHE_DURATION    = 2

    local ELEMENT_TK        = 0x000c0001 -- Trackerball
    local ELEMENT_MF        = 0x000d0001 -- Multifunction
    local ELEMENT_KB        = 0x000e0001 -- Knob
    local ELEMENT_BT        = 0x000f0001 -- Button

    local MENU_A            = 1
    local MENU_B            = 2

    --------------------------------------------------------------------------------
    -- Groups:
    --------------------------------------------------------------------------------
    local resolveGroup = tangentManager.controls:group("DaVinci Resolve")
    local groupIDs = {
        "Master Menu A",
        "Sizing",
        "Primary",
        "Log",
        "Curves",
        "H Clip",
        "L Clip",
        "Node",
        "Primary Adj",

        "Master Menu B",
        "HSL Q",
        "HSL Q2",
        "Window",
        "Blur",
        "Key",
        "Version",
        "Gallery",
        "Stereo 3D",
    }
    local groups = {}
    for _, label in pairs(groupIDs) do
        groups[label] = resolveGroup:group(label)
    end

    --------------------------------------------------------------------------------
    -- Modes:
    --------------------------------------------------------------------------------
    local modes = {
        ["Master Menu A"]   = 0x03000001,
        ["Sizing"]          = 0x03000002,
        ["Primary"]         = 0x03000003,
        ["Log"]             = 0x03000004,
        ["Curves"]          = 0x03000005,
        ["H Clip"]          = 0x03000006,
        ["L Clip"]          = 0x03000007,
        ["Node"]            = 0x03000008,
        ["Primary Adj"]     = 0x03000009,

        ["Master Menu B"]   = 0x03000010,
        ["HSL Q"]           = 0x03000011,
        ["HSL Q2"]          = 0x03000012,
        ["Window"]          = 0x03000013,
        ["Blur"]            = 0x03000014,
        ["Key"]             = 0x03000015,
        ["Version"]         = 0x03000016,
        ["Gallery"]         = 0x03000017,
        ["Stereo 3D"]       = 0x03000018,
    }
    for label, id in pairs(modes) do
        tangentManager:addMode(id, label)
    end

    --------------------------------------------------------------------------------
    -- Mapping:
    --------------------------------------------------------------------------------
    local map = {
        --------------------------------------------------------------------------------
        -- Element-Bt (Button):
        --------------------------------------------------------------------------------
            --------------------------------------------------------------------------------
            -- Master Menu A:
            --------------------------------------------------------------------------------
                --------------------------------------------------------------------------------
                -- Sizing:
                --------------------------------------------------------------------------------
                {
                    title   = "Sizing",
                    group   = groups["Master Menu A"],
                    mode    = "Sizing",
                    subMenu = nil,
                    button  = 0,
                    menu    = MENU_A,
                    panel   = ELEMENT_BT,
                    id      = 0x0F840000
                },
                    --------------------------------------------------------------------------------
                    -- Buttons:
                    --------------------------------------------------------------------------------
                    {
                        title   = "H Flip",
                        group   = groups["Sizing"],
                        mode    = "Sizing",
                        subMenu = 0,
                        button  = 0,
                        menu    = MENU_A,
                        panel   = ELEMENT_BT,
                        id      = 0x0F840001
                    },
                    {
                        title   = "V Flip",
                        group   = groups["Sizing"],
                        mode    = "Sizing",
                        subMenu = 0,
                        button  = 1,
                        menu    = MENU_A,
                        panel   = ELEMENT_BT,
                        id      = 0x0F840002
                    },
                    --------------------------------------------------------------------------------
                    -- Knobs:
                    --------------------------------------------------------------------------------
                    {
                        title   = "Pan",
                        group   = groups["Sizing"],
                        mode    = "Sizing",
                        subMenu = 0,
                        encoder = 0,
                        menu    = MENU_A,
                        panel   = ELEMENT_KB,
                        id      = 0x0F840005
                    },

                {
                    title   = "Master Menu A",
                    mode    = "Master Menu A",
                    group   = groups["Master Menu A"],
                    subMenu = nil,
                    button  = 12,
                    menu    = MENU_A,
                    panel   = ELEMENT_BT,
                    id      = 0x0F840003
                },
                {
                    title   = "Master Menu B",
                    mode    = "Master Menu B",
                    group   = groups["Master Menu B"],
                    subMenu = nil,
                    button  = 13,
                    menu    = MENU_B,
                    panel   = ELEMENT_BT,
                    id      = 0x0F840004
                },
                --------------------------------------------------------------------------------
                -- Primary:
                --------------------------------------------------------------------------------
                {
                    title   = "Primary",
                    mode    = "Primary",
                    group   = groups["Master Menu A"],
                    subMenu = nil,
                    button  = 1,
                    menu    = MENU_A,
                    panel   = ELEMENT_BT,
                    id      = 0x0F840006
                },
                --------------------------------------------------------------------------------
                -- Log:
                --------------------------------------------------------------------------------
                {
                    title   = "Log",
                    mode    = "Log",
                    group   = groups["Master Menu A"],
                    subMenu = nil,
                    button  = 2,
                    menu    = MENU_A,
                    panel   = ELEMENT_BT,
                    id      = 0x0F840007
                },
                --------------------------------------------------------------------------------
                -- Curves:
                --------------------------------------------------------------------------------
                {
                    title   = "Curves",
                    mode    = "Curves",
                    group   = groups["Master Menu A"],
                    subMenu = nil,
                    button  = 3,
                    menu    = MENU_A,
                    panel   = ELEMENT_BT,
                    id      = 0x0F840008
                },
                --------------------------------------------------------------------------------
                -- H Clip:
                --------------------------------------------------------------------------------
                {
                    title   = "H Clip",
                    mode    = "H Clip",
                    group   = groups["Master Menu A"],
                    subMenu = nil,
                    button  = 4,
                    menu    = MENU_A,
                    panel   = ELEMENT_BT,
                    id      = 0x0F840009
                },
                --------------------------------------------------------------------------------
                -- L Clip:
                --------------------------------------------------------------------------------
                {
                    title   = "L Clip",
                    mode    = "L Clip",
                    group   = groups["Master Menu A"],
                    subMenu = nil,
                    button  = 5,
                    menu    = MENU_A,
                    panel   = ELEMENT_BT,
                    id      = 0x0F840010
                },
                --------------------------------------------------------------------------------
                -- Node:
                --------------------------------------------------------------------------------
                {
                    title   = "Node",
                    mode    = "Node",
                    group   = groups["Master Menu A"],
                    subMenu = nil,
                    button  = 6,
                    menu    = MENU_A,
                    panel   = ELEMENT_BT,
                    id      = 0x0F840011
                },
                --------------------------------------------------------------------------------
                -- Primary Adj:
                --------------------------------------------------------------------------------
                {
                    title   = "Primary Adj",
                    mode    = "Primary Adj",
                    group   = groups["Master Menu A"],
                    subMenu = nil,
                    button  = 7,
                    menu    = MENU_A,
                    panel   = ELEMENT_BT,
                    id      = 0x0F840012
                },
            --------------------------------------------------------------------------------
            -- Master Menu B:
            --------------------------------------------------------------------------------
                --------------------------------------------------------------------------------
                -- HSL Q:
                --------------------------------------------------------------------------------
                {
                    title   = "HSL Q",
                    mode    = "HSL Q",
                    group   = groups["Master Menu B"],
                    subMenu = nil,
                    button  = 0,
                    menu    = MENU_B,
                    panel   = ELEMENT_BT,
                    id      = 0x0F840013
                },
                --------------------------------------------------------------------------------
                -- HSL Q2:
                --------------------------------------------------------------------------------
                {
                    title   = "HSL Q2",
                    mode    = "HSL Q2",
                    group   = groups["Master Menu B"],
                    subMenu = nil,
                    button  = 1,
                    menu    = MENU_B,
                    panel   = ELEMENT_BT,
                    id      = 0x0F840014
                },
                --------------------------------------------------------------------------------
                -- Window:
                --------------------------------------------------------------------------------
                {
                    title   = "Window",
                    mode    = "Window",
                    group   = groups["Master Menu B"],
                    subMenu = nil,
                    button  = 2,
                    menu    = MENU_B,
                    panel   = ELEMENT_BT,
                    id      = 0x0F840015
                },
                --------------------------------------------------------------------------------
                -- Blur:
                --------------------------------------------------------------------------------
                {
                    title   = "Blur",
                    mode    = "Blur",
                    group   = groups["Master Menu B"],
                    subMenu = nil,
                    button  = 3,
                    menu    = MENU_B,
                    panel   = ELEMENT_BT,
                    id      = 0x0F840016
                },
                --------------------------------------------------------------------------------
                -- Key:
                --------------------------------------------------------------------------------
                {
                    title   = "Key",
                    mode    = "Key",
                    group   = groups["Master Menu B"],
                    subMenu = nil,
                    button  = 4,
                    menu    = MENU_B,
                    panel   = ELEMENT_BT,
                    id      = 0x0F840017
                },
                --------------------------------------------------------------------------------
                -- Version:
                --------------------------------------------------------------------------------
                {
                    title   = "Version",
                    mode    = "Version",
                    group   = groups["Master Menu B"],
                    subMenu = nil,
                    button  = 6,
                    menu    = MENU_B,
                    panel   = ELEMENT_BT,
                    id      = 0x0F840018
                },
                --------------------------------------------------------------------------------
                -- Gallery:
                --------------------------------------------------------------------------------
                {
                    title   = "Gallery",
                    mode    = "Gallery",
                    group   = groups["Master Menu B"],
                    subMenu = nil,
                    button  = 7,
                    menu    = MENU_B,
                    panel   = ELEMENT_BT,
                    id      = 0x0F840019
                },
                --------------------------------------------------------------------------------
                -- Stereo 3D:
                --------------------------------------------------------------------------------
                {
                    title   = "Stereo 3D",
                    mode    = "Stereo 3D",
                    group   = groups["Master Menu B"],
                    subMenu = nil,
                    button  = 8,
                    menu    = MENU_B,
                    panel   = ELEMENT_BT,
                    id      = 0x0F840020
                },
    }

    local activeMode

    local function pressButton(id)
        tangentManager:device():sendShamUnmanagedButtonDown(APP_ID, ELEMENT_BT, id)
    end

    local function pressButtonA()
        pressButton(12)
    end

    local function pressButtonB()
        pressButton(13)
    end

    local function changeMode(modeName)
        local id = modes[modeName]
        tangentManager:device():sendModeValue(id)
    end

    local function checkWeAreInTheCorrectMode(v)
        if not activeMode or activeMode ~= v.mode then
            if v.menu == MENU_A then
                pressButtonA()
            else
                pressButtonB()
            end
            if v.subMenu then
                pressButton(v.subMenu)
            end
        end

        changeMode(v.mode)

        activeMode = v.mode
        doAfter(CACHE_DURATION, function() activeMode = nil end)
    end

    for _, v in pairs(map) do
        local group = v.group
        if type(v.encoder) == "number" then
            --------------------------------------------------------------------------------
            -- Knob:
            --------------------------------------------------------------------------------
            group:parameter(v.id)
                :name(v.title)
                :minValue(v.minValue or 0)
                :maxValue(v.maxValue or 10000)
                :stepSize(v.stepSize or 100)
                :onGet(function()
                    if v.getFn then
                        return v.getFn()
                    else
                        return 1
                    end
                end)
                :onChange(function(increment)
                    checkWeAreInTheCorrectMode(v)
                    tangentManager:device():sendShamUnmanagedEncoderChange(APP_ID, v.panel, v.encoder, increment)
                end)
                :onReset(function()
                    checkWeAreInTheCorrectMode(v)
                    tangentManager:device():sendShamUnmanagedButtonDown(APP_ID, v.panel, v.encoder)
                    tangentManager:device():sendShamUnmanagedButtonUp(APP_ID, v.panel, v.encoder)
                end)
        else
            --------------------------------------------------------------------------------
            -- Button:
            --------------------------------------------------------------------------------
            group:action(v.id, v.title)
                :onPress(function()
                    checkWeAreInTheCorrectMode(v)
                    pressButton(v.button)
                end)
                :onRelease(function()
                    --checkWeAreInTheCorrectMode(v)
                    --tangentManager:device():sendShamUnmanagedButtonUp(APP_ID, v.panel, v.button)
                end)
        end
    end

    return mod
end

return plugin
