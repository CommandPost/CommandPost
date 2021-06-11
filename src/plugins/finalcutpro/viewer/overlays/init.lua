--- === plugins.finalcutpro.viewer.overlays ===
---
--- Final Cut Pro Viewer Overlays.

local require           = require

local log               = require "hs.logger".new "overlays"

local hs                = _G.hs

local DraggableGuide    = require "DraggableGuide"
local menus             = require "menus"

local canvas            = require "hs.canvas"
local dialog            = require "hs.dialog"
local eventtap          = require "hs.eventtap"
local fs                = require "hs.fs"
local geometry          = require "hs.geometry"
local hid               = require "hs.hid"
local image             = require "hs.image"
local menubar           = require "hs.menubar"
local mouse             = require "hs.mouse"
local timer             = require "hs.timer"

local axutils           = require "cp.ui.axutils"
local config            = require "cp.config"
local cpDialog          = require "cp.dialog"
local deferred          = require "cp.deferred"
local fcp               = require "cp.apple.finalcutpro"
local i18n              = require "cp.i18n"
local tools             = require "cp.tools"

local Do                = require "cp.rx.go.Do"

local capslock          = hid.capslock
local doAfter           = timer.doAfter
local events            = eventtap.event.types
local insert            = table.insert
local format            = string.format

local mod = {}


--- plugins.finalcutpro.viewer.overlays.update() -> none
--- Function
--- Updates the Viewer Grid.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.update()
    --------------------------------------------------------------------------------
    -- Wrap this in a timer to (maybe?) avoid notification lockups:
    --------------------------------------------------------------------------------
    doAfter(0, function()
        --------------------------------------------------------------------------------
        -- If Final Cut Pro is Front Most & Viewer is Showing:
        --------------------------------------------------------------------------------
        if fcp.isFrontmost()
            and fcp.viewer:isShowing()
            and not fcp.isModalDialogOpen()
            and not fcp.fullScreenWindow:isShowing()
            and not fcp.commandEditor:isShowing()
            and not fcp.preferencesWindow:isShowing()
        then
            --------------------------------------------------------------------------------
            -- Start the Mouse Watcher:
            --------------------------------------------------------------------------------
            if mod.enableViewerRightClick() then
                if mod._eventtap then
                    if not mod._eventtap:isEnabled() then
                        mod._eventtap:start()
                    end
                else
                    mod._eventtap = eventtap.new({events.rightMouseUp}, mod._contextualMenu)
                    mod._eventtap:start()
                end
            else
                if mod._eventtap then
                    mod._eventtap:stop()
                    mod._eventtap = nil
                end
            end

            --------------------------------------------------------------------------------
            -- Start the Caps Lock Watcher:
            --------------------------------------------------------------------------------
            if mod.capslock() then
                if mod._capslockEventTap then
                    if not mod._capslockEventTap:isEnabled() then
                        mod._capslockEventTap:start()
                    end
                else
                    mod._capslockEventTap = eventtap.new({events.flagsChanged}, function(event)
                        local keycode = event:getKeyCode()
                        if keycode == 57 then
                            mod.update()
                        end
                    end)
                    mod._capslockEventTap:start()
                end
            else
                if mod._capslockEventTap then
                    mod._capslockEventTap:stop()
                    mod._capslockEventTap = nil
                end
            end

            --------------------------------------------------------------------------------
            -- Toggle Overall Visibility:
            --------------------------------------------------------------------------------
            if mod._areAnyOverlaysEnabled() == true then
                if mod.capslock() == true then
                    --------------------------------------------------------------------------------
                    -- Caps Lock Mode:
                    --------------------------------------------------------------------------------
                    if capslock.get() == true then
                        mod.show()
                    else
                        mod.hide()
                    end
                else
                    --------------------------------------------------------------------------------
                    -- "Enable Overlays" Toggle:
                    --------------------------------------------------------------------------------
                    if mod.disabled() == true then
                        mod.hide()
                    else
                        mod.show()
                    end
                end
            else
                --------------------------------------------------------------------------------
                -- No Overlays Enabled:
                --------------------------------------------------------------------------------
                mod.hide()
            end
        else
            --------------------------------------------------------------------------------
            -- Otherwise hide the grid:
            --------------------------------------------------------------------------------
            mod.hide()

            --------------------------------------------------------------------------------
            -- Destroy the Mouse Watcher:
            --------------------------------------------------------------------------------
            if mod._eventtap then
                mod._eventtap:stop()
                mod._eventtap = nil
            end

            --------------------------------------------------------------------------------
            -- Destroy the Caps Lock Watcher:
            --------------------------------------------------------------------------------
            if mod._capslockEventTap then
                mod._capslockEventTap:stop()
                mod._capslockEventTap = nil
            end

            --------------------------------------------------------------------------------
            -- Destroy the Mouse Move Letterbox Tracker:
            --------------------------------------------------------------------------------
            if mod._mouseMoveLetterboxTracker then
                mod._mouseMoveLetterboxTracker:stop()
                mod._mouseMoveLetterboxTracker = nil
            end

            --------------------------------------------------------------------------------
            -- Destroy any Mouse Move Trackers:
            --------------------------------------------------------------------------------
            if mod._mouseMoveTracker then
                for i, _ in pairs(mod._mouseMoveTracker) do
                    mod._mouseMoveTracker[i]:stop()
                    mod._mouseMoveTracker[i] = nil
                end
            end
        end
    end)
end

-- STILLS_FOLDER -> string
-- Constant
-- Folder name for Stills Cache.
local STILLS_FOLDER = "Still Frames"

-- DEFAULT_COLOR -> string
-- Constant
-- Default Colour Setting.
local DEFAULT_COLOR = "#FFFFFF"

-- DEFAULT_ALPHA -> number
-- Constant
-- Default Alpha Setting.
local DEFAULT_ALPHA = 50

-- DEFAULT_GRID_SPACING -> number
-- Constant
-- Default Grid Spacing Setting.
local DEFAULT_GRID_SPACING = 20

-- DEFAULT_STILLS_LAYOUT -> number
-- Constant
-- Default Stills Layout Setting.
local DEFAULT_STILLS_LAYOUT = "Left Vertical"

-- DEFAULT_LETTERBOX_HEIGHT -> number
-- Constant
-- Default Letterbox Height
local DEFAULT_LETTERBOX_HEIGHT = 70

-- FCP_COLOR_BLUE -> string
-- Constant
-- Apple's preferred blue colour in Final Cut Pro.
local FCP_COLOR_BLUE = "#5760e7"

-- CROSS_HAIR_LENGTH -> number
-- Constant
-- Cross Hair Length
local CROSS_HAIR_LENGTH = 100

-- plugins.finalcutpro.viewer.overlays.NUMBER_OF_MEMORIES -> number
-- Constant
-- Number of Stills Memories Available.
mod.NUMBER_OF_MEMORIES = 5

-- plugins.finalcutpro.viewer.overlays.NUMBER_OF_DRAGGABLE_GUIDES -> number
-- Constant
-- Number of Draggable Guides Available.
mod.NUMBER_OF_DRAGGABLE_GUIDES = 5

--- plugins.finalcutpro.viewer.overlays.enableViewerRightClick <cp.prop: boolean>
--- Variable
--- Allow the user to right click on the top of the viewer to access the menu?
mod.enableViewerRightClick = config.prop("fcpx.ViewerOverlay.EnableViewerRightClick", false)

--- plugins.finalcutpro.viewer.overlays.disabled <cp.prop: boolean>
--- Variable
--- Are all the Viewer Overlay's disabled?
mod.disabled = config.prop("fcpx.ViewerOverlay.MasterDisabled", false)
:watch(mod.update)

--- plugins.finalcutpro.viewer.overlays.crossHairEnabled <cp.prop: boolean>
--- Variable
--- Is Viewer Cross Hair Enabled?
mod.crossHairEnabled = config.prop("fcpx.ViewerOverlay.CrossHair.Enabled", false)
:watch(mod.update)

--- plugins.finalcutpro.viewer.overlays.letterboxEnabled <cp.prop: boolean>
--- Variable
--- Is Viewer Letterbox Enabled?
mod.letterboxEnabled = config.prop("fcpx.ViewerOverlay.Letterbox.Enabled", false)

--- plugins.finalcutpro.viewer.overlays.letterboxHeight <cp.prop: number>
--- Variable
--- Letterbox Height
mod.letterboxHeight = config.prop("fcpx.ViewerOverlay.Letterbox.Height", DEFAULT_LETTERBOX_HEIGHT)

--- plugins.finalcutpro.viewer.overlays.basicGridEnabled <cp.prop: boolean>
--- Variable
--- Is Viewer Grid Enabled?
mod.basicGridEnabled = config.prop("fcpx.ViewerOverlay.BasicGrid.Enabled", false)

--- plugins.finalcutpro.viewer.overlays.crossHairColor <cp.prop: string>
--- Variable
--- Viewer Grid Color as HTML value
mod.crossHairColor = config.prop("fcpx.ViewerOverlay.CrossHair.Color", DEFAULT_COLOR)

--- plugins.finalcutpro.viewer.overlays.crossHairAlpha <cp.prop: number>
--- Variable
--- Viewer Grid Alpha
mod.crossHairAlpha = config.prop("fcpx.ViewerOverlay.CrossHair.Alpha", DEFAULT_ALPHA)

--- plugins.finalcutpro.viewer.overlays.gridColor <cp.prop: string>
--- Variable
--- Viewer Grid Color as HTML value
mod.gridColor = config.prop("fcpx.ViewerOverlay.Grid.Color", DEFAULT_COLOR)

--- plugins.finalcutpro.viewer.overlays.gridAlpha <cp.prop: number>
--- Variable
--- Viewer Grid Alpha
mod.gridAlpha = config.prop("fcpx.ViewerOverlay.Grid.Alpha", DEFAULT_ALPHA)

--- plugins.finalcutpro.viewer.overlays.customGridColor <cp.prop: string>
--- Variable
--- Viewer Custom Grid Color as HTML value
mod.customGridColor = config.prop("fcpx.ViewerOverlay.Grid.CustomColor", nil)

--- plugins.finalcutpro.viewer.overlays.gridSpacing <cp.prop: number>
--- Variable
--- Viewer Custom Grid Color as HTML value
mod.gridSpacing = config.prop("fcpx.ViewerOverlay.Grid.Spacing", DEFAULT_GRID_SPACING)

--- plugins.finalcutpro.viewer.overlays.activeMemory <cp.prop: number>
--- Variable
--- Viewer Custom Grid Color as HTML value
mod.activeMemory = config.prop("fcpx.ViewerOverlay.ActiveMemory", 0)

--- plugins.finalcutpro.viewer.overlays.stillsLayout <cp.prop: string>
--- Variable
--- Stills layout.
mod.stillsLayout = config.prop("fcpx.ViewerOverlay.StillsLayout", DEFAULT_STILLS_LAYOUT)

mod.draggableGuides = {
    DraggableGuide(fcp.viewer, 1),
    DraggableGuide(fcp.viewer, 2),
    DraggableGuide(fcp.viewer, 3),
    DraggableGuide(fcp.viewer, 4),
    DraggableGuide(fcp.viewer, 5),
}

--- plugins.finalcutpro.viewer.overlays.customGuideColor <cp.prop: table>
--- Variable
--- Viewer Custom Guide Color as HTML value
mod.customGuideColor = config.prop("fcpx.ViewerOverlay.Guide.CustomColor", {})

--- plugins.finalcutpro.viewer.overlays.customCrossHairColor <cp.prop: table>
--- Variable
--- Viewer Custom Cross Hair Color as HTML value
mod.customCrossHairColor = config.prop("fcpx.ViewerOverlay.CrossHair.CustomColor", {})

--- plugins.finalcutpro.viewer.overlays.capslock <cp.prop: boolean>
--- Variable
--- Toggle Viewer Overlays with Caps Lock.
mod.capslock = config.prop("fcpx.ViewerOverlay.CapsLock", false):watch(function(enabled)
    if not enabled then
        if mod._capslockEventTap then
            mod._capslockEventTap:stop()
            mod._capslockEventTap = nil
        end
    end
end)

-- addStillsFrame(overlay, frame, stillsLayout, activeMemory)
-- Function
-- Adds the active stills frame to the overlay, if it is available and enabled.
local function addStillsFrame(overlay, frame, stillsLayout, activeMemory)
    if activeMemory ~= 0 then
        local memory = mod.getMemory(activeMemory)
        if memory then
            local clipFrame = { x = 0, y = 0, h = "100%", w = "100%" }
            if stillsLayout == "Left Vertical" then
                clipFrame.w = "50%"
            elseif stillsLayout == "Right Vertical" then
                clipFrame.x = frame.w/2
                clipFrame.w = frame.w/2
            elseif stillsLayout == "Top Horizontal" then
                clipFrame.h = "50%"
            elseif stillsLayout == "Bottom Horizontal" then
                clipFrame.y = frame.h/2
                clipFrame.h = "50%"
            end

            overlay:appendElements({
                type = "rectangle",
                frame = clipFrame,
                action = "clip",
            })

            overlay:appendElements({
                type = "image",
                frame = { x = 0, y = 0, h = "100%", w = "100%"},
                action = "fill",
                image = memory,
                imageScaling = "scaleProportionally",
                imageAlignment = "topLeft",
            })

            if stillsLayout ~= "Full Frame" then
                overlay:appendElements({
                    type = "resetClip",
                })
            end
        end
    end
end

local function addCrossHair(overlay, frame)
    if mod.crossHairEnabled() then

        local length = CROSS_HAIR_LENGTH

        local crossHairColor = mod.crossHairColor()
        local crossHairAlpha = mod.crossHairAlpha() / 100

        local fillColor
        if crossHairColor == "CUSTOM" and mod.customCrossHairColor() then
            fillColor = mod.customCrossHairColor()
            fillColor.alpha = crossHairAlpha
        else
            fillColor = { hex = crossHairColor, alpha = crossHairAlpha }
        end

        --------------------------------------------------------------------------------
        -- Horizontal Bar:
        --------------------------------------------------------------------------------
        overlay:appendElements({
            type = "rectangle",
            frame = { x = (frame.w / 2) - (length/2), y = frame.h / 2, h = 1, w = length},
            fillColor = fillColor,
            action = "fill",
        })

        --------------------------------------------------------------------------------
        -- Vertical Bar:
        --------------------------------------------------------------------------------
        overlay:appendElements({
            type = "rectangle",
            frame = { x = frame.w / 2, y = (frame.h / 2) - (length/2), h = length, w = 1},
            fillColor = fillColor,
            action = "fill",
        })
    end
end

local function addBasicGrid(overlay, frame, fillColor)
    if mod.basicGridEnabled() then
        local gridSpacing   = mod.gridSpacing()
        --------------------------------------------------------------------------------
        -- Add Vertical Lines:
        --------------------------------------------------------------------------------
        for i=1, frame.w, frame.w/gridSpacing do
            overlay:appendElements({
                type = "rectangle",
                frame = { x = i, y = 0, h = frame.h, w = 1},
                fillColor = fillColor,
                action = "fill",
            })
        end

        --------------------------------------------------------------------------------
        -- Add Horizontal Lines:
        --------------------------------------------------------------------------------
        for i=1, frame.h, frame.w/gridSpacing do
            overlay:appendElements({
                type = "rectangle",
                frame = { x = 0, y = i, h = 1, w = frame.w},
                fillColor = fillColor,
                action = "fill",
            })
        end
    end
end

local function addLeterbox(overlay, frame)
    if mod.letterboxEnabled() then

        local letterboxHeight = mod.letterboxHeight()
        overlay:appendElements({
            id = "topLetterbox",
            type = "rectangle",
            frame = { x = 0, y = 0, h = letterboxHeight, w = "100%"},
            fillColor = { hex = "#000000", alpha = 1 },
            action = "fill",
            trackMouseDown = true,
            trackMouseUp = true,
            trackMouseMove = true,
        })

        overlay:appendElements({
            id = "bottomLetterbox",
            type = "rectangle",
            frame = { x = 0, y = frame.h - letterboxHeight, h = letterboxHeight, w = "100%"},
            fillColor = { hex = "#000000", alpha = 1 },
            action = "fill",
            trackMouseDown = true,
            trackMouseUp = true,
            trackMouseMove = true,
        })

    end
end

local function onLetterboxMouse(id, event, frame)
    if id == "topLetterbox" or id == "bottomLetterbox" and event == "mouseDown" then
        if not mod._mouseMoveLetterboxTracker then
            mod._mouseMoveLetterboxTracker = eventtap.new({ events.leftMouseDragged, events.leftMouseUp }, function(e)
                if e:getType() == events.leftMouseUp then
                    mod._mouseMoveLetterboxTracker:stop()
                    mod._mouseMoveLetterboxTracker = nil
                else
                    Do(function()
                        if mod._overlay then
                            local mousePosition = mouse.absolutePosition()
                            local canvasTopLeft = mod._overlay:topLeft()
                            local letterboxHeight = mousePosition.y - canvasTopLeft.y
                            local viewerFrame = geometry.new(frame)
                            if geometry.new(mousePosition):inside(viewerFrame) and letterboxHeight > 10  and letterboxHeight < (frame.h/2) then
                                mod._overlay["topLetterbox"].frame = { x = 0, y = 0, h = letterboxHeight, w = "100%"}
                                mod._overlay["bottomLetterbox"].frame = { x = 0, y = frame.h - letterboxHeight, h = letterboxHeight, w = "100%"}
                                mod.letterboxHeight(letterboxHeight)
                            end
                        end
                    end):After(0)
                end
            end, false):start()
        end
    end
end

local function addBorder(overlay)
    overlay:appendElements({
        id               = "border",
        type             = "rectangle",
        action           = "stroke",
        strokeColor      = { hex = FCP_COLOR_BLUE },
        strokeWidth      = 5,
    })
end

function mod._fillColor()
    local gridColor     = mod.gridColor()
    local gridAlpha     = mod.gridAlpha() / 100
    local fillColor
    if gridColor == "CUSTOM" and mod.customGridColor() then
        fillColor = mod.customGridColor()
        fillColor.alpha = gridAlpha
    else
        fillColor = { hex = gridColor, alpha = gridAlpha }
    end
    return fillColor
end

--- plugins.finalcutpro.viewer.overlays.show() -> none
--- Function
--- Show's the Viewer Grid.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.show()

    --------------------------------------------------------------------------------
    -- First, we must destroy any existing canvas:
    --------------------------------------------------------------------------------
    mod.hide()

    local videoImage = fcp.viewer.videoImage
    if videoImage then
        local frame = videoImage:frame()
        if frame then
            --------------------------------------------------------------------------------
            -- New Canvas:
            --------------------------------------------------------------------------------
            mod._overlay = canvas.new(frame)

            --------------------------------------------------------------------------------
            -- Still Frames:
            --------------------------------------------------------------------------------
            addStillsFrame(mod._overlay, frame, mod.stillsLayout(), mod.activeMemory())

            --------------------------------------------------------------------------------
            -- Cross Hair:
            --------------------------------------------------------------------------------
            addCrossHair(mod._overlay, frame)

            --------------------------------------------------------------------------------
            -- Basic Grid:
            --------------------------------------------------------------------------------

            local fillColor = mod._fillColor()

            addBasicGrid(mod._overlay, frame, fillColor)

            --------------------------------------------------------------------------------
            -- Letterbox:
            --------------------------------------------------------------------------------
            addLeterbox(mod._overlay, frame)

            --------------------------------------------------------------------------------
            -- Mouse Actions for Canvas:
            --------------------------------------------------------------------------------
            if mod.letterboxEnabled() then
                mod._overlay:clickActivating(false)
                mod._overlay:canvasMouseEvents(true, true, true, true)
                mod._overlay:mouseCallback(function(_, event, id)

                    --------------------------------------------------------------------------------
                    -- Letterbox:
                    --------------------------------------------------------------------------------
                    if mod.letterboxEnabled() then
                        onLetterboxMouse(id, event, frame)
                    end
                end)
            end

            --------------------------------------------------------------------------------
            -- Add Border:
            --------------------------------------------------------------------------------
            addBorder(mod._overlay)

            --------------------------------------------------------------------------------
            -- Show the Canvas:
            --------------------------------------------------------------------------------
            mod._overlay:level("status")
            -- TODO: Save the overlay to file
            -- mod._overlay:show()
        end
    else
        mod.hide()
    end
end

--- plugins.finalcutpro.viewer.overlays.hide() -> none
--- Function
--- Hides the Viewer Grid.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.hide()
    if mod._overlay then
        mod._overlay:delete()
        mod._overlay = nil
    end
end

--- plugins.finalcutpro.viewer.overlays.draggableGuidesEnabled() -> boolean
--- Function
--- Are any draggable guides enabled?
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if at least one draggable guide is enabled otherwise `false`
function mod.draggableGuidesEnabled()
    for _,guide in ipairs(mod.draggableGuides) do
        if guide:isEnabled() then
            return true
        end
    end
    return false
end

-- _areAnyOverlaysEnabled() -> boolean
-- Function
-- Are any Final Cut Pro Viewer Overlays Enabled?
--
-- Parameters:
--  * None
--
-- Returns:
--  * `true` if any Viewer Overlays are enabled otherwise `false`
function mod._areAnyOverlaysEnabled()
    return mod.basicGridEnabled() == true
    or mod.draggableGuidesEnabled() == true
    or mod.activeMemory() ~= 0
    or mod.crossHairEnabled() == true
    or mod.letterboxEnabled() == true
    or false
end

--------------------------------------------------------------------------------
-- MENUS
--------------------------------------------------------------------------------

local function generateSeparatorMenuItem()
    return { title = "-", disabled = true }
end

local colorOptions = {
    { title = i18n("black"),    color = "#000000" },
    { title = i18n("white"),    color = "#FFFFFF" },
    { title = i18n("yellow"),   color = "#F4D03F"},
    { title = i18n("red"),      color = "#FF5733"},
}

local function setCustomColor(colorProp, customColorProp)
    dialog.color.continuous(false)
    dialog.color.callback(function(color, closed)
        if closed then
            colorProp("CUSTOM")
            customColorProp(color)
            mod.update()
            fcp:launch()
        end
    end)
    dialog.color.show()
    hs.focus()
end

local function generateSpacingMenu(title, spacingProp)
    local currentSpacing = spacingProp()
    local menu = {}

    for i = 5,100,5 do
        insert(menu, {
            title = tostring(i),
            checked = currentSpacing == i,
            fn = function() spacingProp(i) end
        })
    end

    return { title = title, menu = menu }
end

local function generateDraggableGuidesMenu()
    local menu = {
        { title = i18n("enableAll"), fn = mod.enableAllDraggableGuides },
        { title = i18n("disableAll"), fn = mod.disableAllDraggableGuides },
        { title = "-", disabled = true },
    }

    local guideText, enableText, resetText = i18n("guide"), i18n("enable"), i18n("reset")
    local appearanceText, colorText, opacityText = i18n("appearance"), i18n("color"), i18n("opacity")

    for _,guide in ipairs(mod.draggableGuides) do
        local guideMenu = {}

        insert(guideMenu, { title = enableText, checked = guide:isEnabled(), fn = function() guide.isEnabled:toggle(); mod.update(); end })
        insert(guideMenu, { title = resetText, fn = function() guide:reset() end })

        insert(guideMenu, { title = appearanceText, menu = {
            menus.generateColorMenu("  "..colorText, guide.color),
            menus.generateAlphaMenu("  "..opacityText, guide.alpha),
        }})

        insert(menu, { title = format("%s %d", guideText, guide.id), menu = guideMenu })
    end

    return menu
end

local function generateCrossHairMenu()
    local menu = {}

    insert(menu, { title = i18n("enable"), checked = mod.crossHairEnabled(), fn = function() mod.crossHairEnabled:toggle() end })
    insert(menu, { i18n("appearance"), menu = {
        menus.generateColorMenu("  "..i18n("color"), mod.crossHairColor),
        menus.generateAlphaMenu("  "..i18n("opacity"), mod.crossHairAlpha),
    }})

    return menu
end

local function generateLetterboxMattesMenu()
    return {
        { title = i18n("enable"),   checked = mod.letterboxEnabled(), fn = function() mod.letterboxEnabled:toggle(); mod.update(); end },
    }
end

local function generateStillFrameViewMenu()
    local menu = {}
    local activeMemory = mod.activeMemory()
    local memoryText = i18n("memory")
    for i = 1, mod.NUMBER_OF_MEMORIES do
        insert(menu, {
            title = format("%s %d", memoryText, i),
            checked = activeMemory == i,
            fn = function() mod.viewMemory(i) end,
            disabled = not mod.getMemory(1),
        })
    end
    return menu
end

local function generateStillFrameSaveMenu()
    local menu = {}
    local memoryText = i18n("memory")
    for i = 1, mod.NUMBER_OF_MEMORIES do
        insert(menu, {
            title = format("%s %d", memoryText, i),
            fn = function() mod.saveMemory(i) end,
        })
    end
    return menu
end

local function generateStillFrameImportMenu()
    local menu = {}
    local memoryText = i18n("memory")
    for i = 1, mod.NUMBER_OF_MEMORIES do
        insert(menu, {
            title = format("%s %d", memoryText, i),
            fn = function() mod.importMemory(i) end,
        })
    end
    return menu
end

local function generateStillFrameDeleteMenu()
    local menu = {}
    local memoryText = i18n("memory")
    for i = 1, mod.NUMBER_OF_MEMORIES do
        insert(menu, {
            title = format("%s %d", memoryText, i),
            fn = function() mod.deleteMemory(1) end,
            disabled = not mod.getMemory(i),
        })
    end
    return menu
end

local function generateStillFrameAppearanceMenu()
    return {
        { title = i18n("fullFrame"),  checked = mod.stillsLayout() == "Full Frame", fn = function() mod.stillsLayout("Full Frame"); mod.update() end },
        { title = "-", disabled = true },
        { title = i18n("leftVertical"),  checked = mod.stillsLayout() == "Left Vertical", fn = function() mod.stillsLayout("Left Vertical"); mod.update() end },
        { title = i18n("rightVertical"), checked = mod.stillsLayout() == "Right Vertical", fn = function() mod.stillsLayout("Right Vertical"); mod.update() end },
        { title = "-", disabled = true },
        { title = i18n("topHorizontal"), checked = mod.stillsLayout() == "Top Horizontal", fn = function() mod.stillsLayout("Top Horizontal"); mod.update() end },
        { title = i18n("bottomHorizontal"), checked = mod.stillsLayout() == "Bottom Horizontal", fn = function() mod.stillsLayout("Bottom Horizontal"); mod.update() end },
    }
end

local function generateGridOverlayAppearanceMenu()
    local menu = {}

    -- colors
    insert(menu, menus.generateColorMenu("  ".. i18n("color"), mod.gridColor))
    insert(menu, menus.generateAlphaMenu("  "..i18n("opacity"), mod.gridAlpha))
    insert(menu, generateSpacingMenu("  "..i18n("segments"), mod.gridSpacing))

    return menu
end

-- generateMenu -> table
-- Function
-- Returns a table with the Overlay menu.
--
-- Parameters:
--  * None
--
-- Returns:
--  * A table containing the overlay menu.
local function generateMenu()
    local menu = {}

    --------------------------------------------------------------------------------
    --
    -- ENABLE OVERLAYS:
    --
    --------------------------------------------------------------------------------
    insert(menu, { title = i18n("enable") .. " " .. i18n("overlays"), checked = not mod.capslock() and not mod.disabled(), fn = function() mod.disabled:toggle() end, disabled = mod.capslock()  })
    insert(menu, { title = i18n("toggleOverlaysWithCapsLock"), checked = mod.capslock(), fn = function() mod.capslock:toggle(); mod.update() end })

    insert(menu, generateSeparatorMenuItem() )

    -- GUIDES SECTION:
    insert(menu, { title = string.upper(i18n("guides")) .. ":", disabled = true })

    --------------------------------------------------------------------------------
    --
    -- DRAGGABLE GUIDES:
    --
    --------------------------------------------------------------------------------
    insert(menu, { title = "  " .. i18n("draggableGuides"), menu = generateDraggableGuidesMenu() })

    --------------------------------------------------------------------------------
    --
    -- CROSS HAIR:
    --
    --------------------------------------------------------------------------------
    insert(menu, { title = "  " .. i18n("crossHair"), menu = generateCrossHairMenu()})

    insert(menu, generateSeparatorMenuItem())

    -- MATTES SECTION:
    insert(menu, { title = string.upper(i18n("mattes")) .. ":", disabled = true })
    insert(menu, { title = "  " .. i18n("letterbox"), menu = generateLetterboxMattesMenu()})

    insert(menu, generateSeparatorMenuItem())

    --------------------------------------------------------------------------------
    --
    -- STILL FRAMES:
    --
    --------------------------------------------------------------------------------
    insert(menu, { title = string.upper(i18n("stillFrames")) .. ":", disabled = true })

    insert(menu, { title = "  " .. i18n("view"), menu = generateStillFrameViewMenu() })
    insert(menu, { title = "  " .. i18n("save"), menu = generateStillFrameSaveMenu() })
    insert(menu, { title = "  " .. i18n("import"), menu = generateStillFrameImportMenu() })
    insert(menu, { title = "  " .. i18n("delete"), menu = generateStillFrameDeleteMenu() })
    insert(menu, { title = "  " .. i18n("appearance"), menu = generateStillFrameAppearanceMenu() })

    insert(menu, generateSeparatorMenuItem())

    --------------------------------------------------------------------------------
    --
    -- GRID OVERLAY:
    --
    --------------------------------------------------------------------------------
    insert(menu, { title = string.upper(i18n("gridOverlay")) .. ":", disabled = true })

    insert(menu, { title = "  " .. i18n("enable"), checked = mod.basicGridEnabled(), fn = function() mod.basicGridEnabled:toggle(); mod.update(); end })

    insert(menu, { title = "  " .. i18n("appearance"), menu = generateGridOverlayAppearanceMenu() })

    insert(menu, generateSeparatorMenuItem())

    insert(menu, { title = i18n("reset") .. " " .. i18n("overlays"), fn = function() mod.resetOverlays() end })

    return menu
end

-- _contextualMenu(event) -> none
-- Function
-- Builds the Final Cut Pro Overlay contextual menu.
--
-- Parameters:
--  * event - The `hs.eventtap` event
--
-- Returns:
--  * None
function mod._contextualMenu(event)
    local ui = fcp.viewer:UI()
    local topBar = ui and axutils.childFromTop(ui, 1)
    if topBar then
        local barFrame = topBar:attributeValue("AXFrame")
        local location = event:location() and geometry.point(event:location())
        if barFrame and location and location:inside(geometry.rect(barFrame)) then
            if mod._menu then
                mod._menu:delete()
                mod._menu = nil
            end
            mod._menu = menubar.new()
            mod._menu:setMenu(generateMenu())
            mod._menu:removeFromMenuBar()
            mod._menu:popupMenu(location, true)
        end
    end
end

mod._lastValue = false

--- plugins.finalcutpro.viewer.overlays.getStillsFolderPath() -> string | nil
--- Function
--- Gets the stills folder path.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The stills folder path as a string or `nil` if an error occurs.
function mod.getStillsFolderPath()
    local userConfigRootPath = config.userConfigRootPath
    if userConfigRootPath then
        if not tools.doesDirectoryExist(userConfigRootPath) then
            fs.mkdir(userConfigRootPath)
        end
        local path = userConfigRootPath .. "/" .. STILLS_FOLDER .. "/"
        if not tools.doesDirectoryExist(path) then
            fs.mkdir(path)
        end
        return tools.doesDirectoryExist(path) and path
    else
        return nil
    end
end

--- plugins.finalcutpro.viewer.overlays.deleteMemory() -> none
--- Function
--- Deletes a memory.
---
--- Parameters:
---  * id - An identifier in the form of a number.
---
--- Returns:
---  * None
function mod.deleteMemory(id)
    local path = mod.getStillsFolderPath()
    if path then
        local imagePath = path .. "/memory" .. id .. ".png"
        if tools.doesFileExist(imagePath) then
            os.remove(imagePath)
            local activeMemory = mod.activeMemory()
            if activeMemory == id then
                mod.activeMemory(0)
                mod.update()
            end
        end
    end
end

--- plugins.finalcutpro.viewer.overlays.saveMemory() -> none
--- Function
--- Saves a still frame to file.
---
--- Parameters:
---  * id - An identifier in the form of a number.
---
--- Returns:
---  * None
function mod.saveMemory(id)
    local videoImage = fcp.viewer.videoImage
    local result = false
    if videoImage then
        local path = mod.getStillsFolderPath()
        if path then
            local snapshot = videoImage:snapshot(path .. "/memory" .. id .. ".png")
            if snapshot then
                result = true
            end
        else
            log.ef("Could not create Cache Folder.")
        end
    else
        log.ef("Could not find Viewer.")
    end
    if not result then
        dialog.displayErrorMessage("Could not save still frame.")
    end
end

--- plugins.finalcutpro.viewer.overlays.importMemory() -> none
--- Function
--- Import a file to memory.
---
--- Parameters:
---  * id - An identifier in the form of a number.
---
--- Returns:
---  * None
function mod.importMemory(id)
    local disabled = mod.disabled()
    mod.disabled(true)
    local allowedImageType = {"PDF", "com.adobe.pdf", "BMP", "com.microsoft.bmp", "JPEG", "JPEG2", "jpg", "public.jpeg", "PICT", "com.apple.pict", "PNG", "public.png", "PSD", "com.adobe.photoshop-image", "TIFF", "public.tiff"}
    local path = cpDialog.displayChooseFile("Please select a file to import", allowedImageType)
    local stillsFolderPath = mod.getStillsFolderPath()
    if path and stillsFolderPath then
        local importedImage = image.imageFromPath(path)
        if importedImage then
            importedImage:saveToFile(stillsFolderPath .. "/memory" .. id .. ".png")
            local activeMemory = mod.activeMemory()
            if activeMemory == id then
                mod.activeMemory(0)
            end
        end
    end
    mod.disabled(disabled)
end

--- plugins.finalcutpro.viewer.overlays.getMemory(id) -> image | nil
--- Function
--- Gets an image from memory.
---
--- Parameters:
---  * id - The ID of the memory you want to retrieve.
---
--- Returns:
---  * The memory as a `hs.image` or `nil` if the memory could not be retrieved.
function mod.getMemory(id)
    local path = mod.getStillsFolderPath()
    if path then
        local imagePath = path .. "/memory" .. id .. ".png"
        if tools.doesFileExist(imagePath) then
            local result = image.imageFromPath(imagePath)
            if result then
                return result
            end
        end
    end
    return nil
end

--- plugins.finalcutpro.viewer.overlays.viewMemory(id) -> none
--- Function
--- View a memory.
---
--- Parameters:
---  * id - The ID of the memory you want to retrieve.
---
--- Returns:
---  * None
function mod.viewMemory(id)
    local activeMemory = mod.activeMemory()
    if activeMemory == id then
        mod.activeMemory(0)
    else
        local result = mod.getMemory(id)
        if result then
            mod.activeMemory(id)
        end
    end
    mod.update()
end

--- plugins.finalcutpro.viewer.overlays.setGridSpacing(value) -> none
--- Function
--- Sets Grid Spacing.
---
--- Parameters:
---  * value - The value you want to set.
---
--- Returns:
---  * None
function mod.setGridSpacing(value)
    mod.gridSpacing(value)
    mod.update()
end

--- plugins.finalcutpro.viewer.overlays.setGridAlpha(value) -> none
--- Function
--- Sets Grid Alpha.
---
--- Parameters:
---  * value - The value you want to set.
---
--- Returns:
---  * None
function mod.setGridAlpha(value)
    mod.gridAlpha(value)
    mod.update()
end

--- plugins.finalcutpro.viewer.overlays.setGridColor(value) -> none
--- Function
--- Sets Grid Color.
---
--- Parameters:
---  * value - The value you want to set.
---
--- Returns:
---  * None
function mod.setGridColor(value)
    mod.gridColor(value)
    mod.update()
end

--- plugins.finalcutpro.viewer.overlays.setCustomGridColor() -> none
--- Function
--- Pops up a Color Dialog box allowing the user to select a custom colour for grid lines.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.setCustomGridColor()
    setCustomColor(mod.gridColor, mod.customGridColor)
end

--- plugins.finalcutpro.viewer.overlays.setCustomCrossHairColor() -> none
--- Function
--- Pops up a Color Dialog box allowing the user to select a custom colour for cross hairs.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.setCustomCrossHairColor()
    dialog.color.continuous(false)
    dialog.color.callback(function(color, closed)
        if closed then
            mod.crossHairColor("CUSTOM")
            mod.customCrossHairColor(color)
            mod.update()
            fcp:launch()
        end
    end)
    dialog.color.show()
    hs.focus()
end

--- plugins.finalcutpro.viewer.overlays.enableAllDraggableGuides() -> none
--- Function
--- Enable all draggable guides.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.enableAllDraggableGuides()
    for _,guide in ipairs(mod.draggableGuides) do
        guide:isEnabled(true)
    end
    mod.update()
end

--- plugins.finalcutpro.viewer.overlays.disableAllDraggableGuides() -> none
--- Function
--- Disable all draggable guides.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.disableAllDraggableGuides()
    for _,guide in ipairs(mod.draggableGuides) do
        guide:isEnabled(false)
    end
    mod.update()
end

--- plugins.finalcutpro.visible.overlay.resetAllDraggableGuides() -> none
--- Function
--- Resets all draggable guides to default settings.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.resetAllDraggableGuides()
    for _,guide in ipairs(mod.draggableGuides) do
        guide:reset()
    end
end

--- plugins.finalcutpro.viewer.overlays.resetOverlays() -> none
--- Function
--- Resets all overlays to their default values.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.resetOverlays()
    mod.crossHairEnabled(false)
    mod.letterboxEnabled(false)
    mod.letterboxHeight(DEFAULT_LETTERBOX_HEIGHT)
    mod.basicGridEnabled(false)
    mod.crossHairColor(DEFAULT_COLOR)
    mod.crossHairAlpha(DEFAULT_ALPHA)
    mod.gridColor(DEFAULT_COLOR)
    mod.gridAlpha(DEFAULT_ALPHA)
    mod.customGridColor(nil)
    mod.gridSpacing(DEFAULT_GRID_SPACING)
    mod.activeMemory(0)
    mod.stillsLayout(DEFAULT_STILLS_LAYOUT)
    mod.resetAllDraggableGuides()
    mod.customCrossHairColor({})
    mod.update()
end

-- updater -> cp.deferred
-- Variable
-- A deferred timer that triggers the update function.
local updater = deferred.new(0.1):action(mod.update)

-- deferredUpdate -> none
-- Function
-- Triggers the update function.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function deferredUpdate()
    updater()
end

local plugin = {
    id              = "finalcutpro.viewer.overlays",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]        = "fcpxCmds",
        ["finalcutpro.menu.manager"]    = "menu",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Setup the system menu:
    --------------------------------------------------------------------------------
    deps.menu.viewer
        :addMenu(10001, function() return i18n("overlay") end)
        :addItems(999, function()
            return {
                { title = i18n("enableViewerContextualMenu"), fn = function() mod.enableViewerRightClick:toggle(); mod.update() end, checked = mod.enableViewerRightClick() },
                { title = "-", disabled = true },
            }
        end)
        :addItems(1000, generateMenu)

    --------------------------------------------------------------------------------
    -- Update Canvas when Final Cut Pro is shown/hidden:
    --------------------------------------------------------------------------------
    fcp.isFrontmost:watch(deferredUpdate)
    fcp.isModalDialogOpen:watch(deferredUpdate)
    fcp.fullScreenWindow.isShowing:watch(deferredUpdate)
    fcp.commandEditor.isShowing:watch(deferredUpdate)
    fcp.preferencesWindow.isShowing:watch(deferredUpdate)

    --------------------------------------------------------------------------------
    -- Update Canvas one second after going full-screen:
    --------------------------------------------------------------------------------
    fcp.primaryWindow.isFullScreen:watch(function() doAfter(1, mod.update) end)

    --------------------------------------------------------------------------------
    -- Update Canvas when Final Cut Pro's Viewer is resized or moved:
    --------------------------------------------------------------------------------
    fcp.viewer.frame:watch(function(value)
        if value then
            deferredUpdate()
        end
    end)

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    if deps.fcpxCmds then
        deps.fcpxCmds
            :add("cpViewerBasicGrid")
            :whenActivated(function() mod.basicGridEnabled:toggle(); mod.update() end)

        for i=1, mod.NUMBER_OF_DRAGGABLE_GUIDES do
            deps.fcpxCmds
                :add("cpViewerDraggableGuide" .. i)
                :whenActivated(function() mod.draggableGuides[i].isEnabled:toggle() end)
                :titled(i18n("cpViewerDraggableGuide_title") .. " " .. i)
        end

        deps.fcpxCmds
            :add("cpToggleAllViewerOverlays")
            :whenActivated(function() mod.disabled:toggle() end)

        for i=1, mod.NUMBER_OF_MEMORIES do
            deps.fcpxCmds
                :add("cpSaveStillsFrame" .. i)
                :whenActivated(function() mod.saveMemory(i) end)
                :titled(i18n("saveCurrentFrameToStillsMemory") .. " " .. i)

            deps.fcpxCmds
                :add("cpViewStillsFrame" .. i)
                :whenActivated(function() mod.viewMemory(i) end)
                :titled(i18n("viewStillsMemory") .. " " .. i)
        end
    end

    return mod
end

function plugin.postInit()
    --------------------------------------------------------------------------------
    -- Update the Canvas on initial boot:
    --------------------------------------------------------------------------------
    if mod.update then
        mod.update()
    end
end

return plugin
