--- === plugins.finalcutpro.viewer.overlays ===
---
--- Final Cut Pro Viewer Overlays.

local require           = require

local log               = require "hs.logger".new "overlays"

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

local mod = {}

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

--- plugins.finalcutpro.viewer.overlays.disabled <cp.prop: boolean>
--- Variable
--- Are all the Viewer Overlay's disabled?
mod.disabled = config.prop("fcpx.ViewerOverlay.MasterDisabled", false)

--- plugins.finalcutpro.viewer.overlays.crossHairEnabled <cp.prop: boolean>
--- Variable
--- Is Viewer Cross Hair Enabled?
mod.crossHairEnabled = config.prop("fcpx.ViewerOverlay.CrossHair.Enabled", false)

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

--- plugins.finalcutpro.viewer.overlays.draggableGuideEnabled <cp.prop: table>
--- Variable
--- Is Viewer Grid Enabled?
mod.draggableGuideEnabled = config.prop("fcpx.ViewerOverlay.DraggableGuide.Enabled", {})

--- plugins.finalcutpro.viewer.overlays.guidePosition <cp.prop: table>
--- Variable
--- Guide Position.
mod.guidePosition = config.prop("fcpx.ViewerOverlay.GuidePosition", {})

--- plugins.finalcutpro.viewer.overlays.guideColor <cp.prop: table>
--- Variable
--- Viewer Guide Color as HTML value
mod.guideColor = config.prop("fcpx.ViewerOverlay.Guide.Color", {})

--- plugins.finalcutpro.viewer.overlays.guideAlpha <cp.prop: table>
--- Variable
--- Viewer Guide Alpha
mod.guideAlpha = config.prop("fcpx.ViewerOverlay.Guide.Alpha", {})

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
    if enabled then
        mod._capslockEventTap = eventtap.new({events.flagsChanged}, function(event)
            local keycode = event:getKeyCode()
            if keycode == 57 then
                mod.update()
            end
        end):start()
    else
        if mod._capslockEventTap then
            mod._capslockEventTap:stop()
            mod._capslockEventTap = nil
        end
    end
end)

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

    local fcpFrame = fcp:viewer():contentsUI()
    if fcpFrame then
        local frame = fcpFrame:attributeValue("AXFrame")
        if frame then
            --------------------------------------------------------------------------------
            -- New Canvas:
            --------------------------------------------------------------------------------
            mod._canvas = canvas.new(frame)

            --------------------------------------------------------------------------------
            -- Still Frames:
            --------------------------------------------------------------------------------
            local stillsLayout  = mod.stillsLayout()
            local activeMemory = mod.activeMemory()
            if activeMemory ~= 0 then
                local memory = mod.getMemory(activeMemory)
                if memory then
                    if stillsLayout == "Left Vertical" then
                        mod._canvas:appendElements({
                            type = "rectangle",
                            frame = { x = 0, y = 0, h = "100%", w = "50%"},
                            action = "clip",
                        })
                    elseif stillsLayout == "Right Vertical" then
                        mod._canvas:appendElements({
                            type = "rectangle",
                            frame = { x = frame.w/2, y = 0, h = "100%", w = frame.w/2},
                            action = "clip",
                        })
                    elseif stillsLayout == "Top Horizontal" then
                        mod._canvas:appendElements({
                            type = "rectangle",
                            frame = { x = 0, y = 0, h = "50%", w = "100%"},
                            action = "clip",
                        })
                    elseif stillsLayout == "Bottom Horizontal" then
                        mod._canvas:appendElements({
                            type = "rectangle",
                            frame = { x = 0, y = frame.h/2, h = "50%", w = "100%"},
                            action = "clip",
                        })
                    end
                    mod._canvas:appendElements({
                        type = "image",
                        frame = { x = 0, y = 0, h = "100%", w = "100%"},
                        action = "fill",
                        image = memory,
                        imageScaling = "scaleProportionally",
                        imageAlignment = "topLeft",
                    })
                    if stillsLayout ~= "Full Frame" then
                        mod._canvas:appendElements({
                            type = "resetClip",
                        })
                    end
                end
            end

            --------------------------------------------------------------------------------
            -- Cross Hair:
            --------------------------------------------------------------------------------
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
                mod._canvas:appendElements({
                    type = "rectangle",
                    frame = { x = (frame.w / 2) - (length/2), y = frame.h / 2, h = 1, w = length},
                    fillColor = fillColor,
                    action = "fill",
                })

                --------------------------------------------------------------------------------
                -- Vertical Bar:
                --------------------------------------------------------------------------------
                mod._canvas:appendElements({
                    type = "rectangle",
                    frame = { x = frame.w / 2, y = (frame.h / 2) - (length/2), h = length, w = 1},
                    fillColor = fillColor,
                    action = "fill",
                })

            end

            --------------------------------------------------------------------------------
            -- Basic Grid:
            --------------------------------------------------------------------------------
            local gridColor     = mod.gridColor()
            local gridAlpha     = mod.gridAlpha() / 100
            local gridSpacing   = mod.gridSpacing()
            local fillColor
            if gridColor == "CUSTOM" and mod.customGridColor() then
                fillColor = mod.customGridColor()
                fillColor.alpha = gridAlpha
            else
                fillColor = { hex = gridColor, alpha = gridAlpha }
            end
            if mod.basicGridEnabled() then
                --------------------------------------------------------------------------------
                -- Add Vertical Lines:
                --------------------------------------------------------------------------------
                for i=1, frame.w, frame.w/gridSpacing do
                    mod._canvas:appendElements({
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
                    mod._canvas:appendElements({
                        type = "rectangle",
                        frame = { x = 0, y = i, h = 1, w = frame.w},
                        fillColor = fillColor,
                        action = "fill",
                    })
                end
            end

            --------------------------------------------------------------------------------
            -- Draggable Guides:
            --------------------------------------------------------------------------------
            local draggableGuideEnabled = false
            for i=1, mod.NUMBER_OF_DRAGGABLE_GUIDES do
                if mod.getDraggableGuideEnabled(i) then

                    draggableGuideEnabled = true

                    local guidePosition = mod.getGuidePosition(i)
                    local guideColor = mod.getGuideColor(i)
                    local guideAlpha = mod.getGuideAlpha(i) / 100
                    local customGuideColor = mod.getCustomGuideColor(i)

                    if guideColor == "CUSTOM" and customGuideColor then
                        fillColor = customGuideColor
                        fillColor.alpha = guideAlpha
                    else
                        fillColor = { hex = guideColor, alpha = guideAlpha }
                    end

                    local savedX, savedY
                    if guidePosition.x and guidePosition.y then
                        savedX = guidePosition.x
                        savedY = guidePosition.y
                    else
                        savedX = frame.w/2
                        savedY = frame.h/2
                    end
                    mod._canvas:appendElements({
                        id = "dragVertical" .. i,
                        action = "stroke",
                        closed = false,
                        coordinates = { { x = savedX, y = 0 }, { x = savedX, y = frame.h } },
                        strokeColor = fillColor,
                        strokeWidth = 2,
                        type = "segments",
                    })
                    mod._canvas:appendElements({
                        id = "dragHorizontal" .. i,
                        action = "stroke",
                        closed = false,
                        coordinates = { { x = 0, y = savedY }, { x = frame.w, y = savedY } },
                        strokeColor = fillColor,
                        strokeWidth = 2,
                        type = "segments",
                    })
                    mod._canvas:appendElements({
                        id = "dragCentreKill" .. i,
                        action = "fill",
                        center = { x = savedX, y = savedY },
                        radius = 8,
                        fillColor = fillColor,
                        type = "circle",
                        compositeRule = "clear",
                    })
                    mod._canvas:appendElements({
                        id = "dragCentre" .. i,
                        action = "fill",
                        center = { x = savedX, y = savedY },
                        radius = 8,
                        fillColor = fillColor,
                        type = "circle",
                        trackMouseDown = true,
                        trackMouseUp = true,
                        trackMouseMove = true,
                    })
                end
            end

            --------------------------------------------------------------------------------
            -- Letterbox:
            --------------------------------------------------------------------------------
            if mod.letterboxEnabled() then

                local letterboxHeight = mod.letterboxHeight()
                mod._canvas:appendElements({
                    id = "topLetterbox",
                    type = "rectangle",
                    frame = { x = 0, y = 0, h = letterboxHeight, w = "100%"},
                    fillColor = { hex = "#000000", alpha = 1 },
                    action = "fill",
                    trackMouseDown = true,
                    trackMouseUp = true,
                    trackMouseMove = true,
                })

                mod._canvas:appendElements({
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

            --------------------------------------------------------------------------------
            -- Mouse Actions for Canvas:
            --------------------------------------------------------------------------------
            if draggableGuideEnabled or mod.letterboxEnabled() then
                mod._canvas:clickActivating(false)
                mod._canvas:canvasMouseEvents(true, true, true, true)
                mod._canvas:mouseCallback(function(_, event, id)
                    --------------------------------------------------------------------------------
                    -- Draggable Guides:
                    --------------------------------------------------------------------------------
                    if draggableGuideEnabled then
                        for i=1, mod.NUMBER_OF_DRAGGABLE_GUIDES do
                            --------------------------------------------------------------------------------
                            -- Reset Guide on Double Click:
                            --------------------------------------------------------------------------------
                            if id == "dragCentre" .. i and event == "mouseUp" then
                                if mod._draggableGuideDoubleClick then

                                    local newX = frame.w/2
                                    local newY = frame.h/2

                                    mod._canvas["dragCentre" .. i].center = { x = newX, y = newY}
                                    mod._canvas["dragCentreKill" .. i].center = {x = newX, y = newY }
                                    mod._canvas["dragVertical" .. i].coordinates = { { x = newX, y = 0 }, { x = newX, y = frame.h } }
                                    mod._canvas["dragHorizontal" .. i].coordinates = { { x = 0, y = newY }, { x = frame.w, y = newY } }
                                    mod.setGuidePosition(i, {x=newX, y=newY})

                                    mod._draggableGuideDoubleClick = false
                                else
                                    mod._draggableGuideDoubleClick = true
                                    doAfter(eventtap.doubleClickInterval(), function()
                                        mod._draggableGuideDoubleClick = false
                                    end)
                                end
                            end

                            if id == "dragCentre" .. i and event == "mouseDown" then
                                if not mod._mouseMoveTracker then
                                    mod._mouseMoveTracker = {}
                                end
                                if mod._mouseMoveLetterboxTracker then
                                    mod._mouseMoveLetterboxTracker:stop()
                                    mod._mouseMoveLetterboxTracker = nil
                                end
                                if not mod._mouseMoveTracker[i] then
                                    mod._mouseMoveTracker[i] = eventtap.new({ events.leftMouseDragged, events.leftMouseUp }, function(e)
                                        if e:getType() == events.leftMouseUp then
                                            mod._mouseMoveTracker[i]:stop()
                                            mod._mouseMoveTracker[i] = nil
                                        else
                                            Do(function()
                                                if mod._canvas then
                                                    local mousePosition = mouse.getAbsolutePosition()
                                                    local canvasTopLeft = mod._canvas:topLeft()
                                                    local newX = mousePosition.x - canvasTopLeft.x
                                                    local newY = mousePosition.y - canvasTopLeft.y
                                                    local viewerFrame = geometry.new(frame)
                                                    if geometry.new(mousePosition):inside(viewerFrame) then
                                                        mod._canvas["dragCentre" .. i].center = { x = newX, y = newY}
                                                        mod._canvas["dragCentreKill" .. i].center = {x = newX, y = newY }
                                                        mod._canvas["dragVertical" .. i].coordinates = { { x = newX, y = 0 }, { x = newX, y = frame.h } }
                                                        mod._canvas["dragHorizontal" .. i].coordinates = { { x = 0, y = newY }, { x = frame.w, y = newY } }
                                                        mod.setGuidePosition(i, {x=newX, y=newY})
                                                    end
                                                end
                                            end):After(0)
                                        end
                                    end, false):start()
                                end
                            end
                        end
                    end

                    --------------------------------------------------------------------------------
                    -- Letterbox:
                    --------------------------------------------------------------------------------
                    if mod.letterboxEnabled() then
                        if id == "topLetterbox" or id == "bottomLetterbox" and event == "mouseDown" then
                            if not mod._mouseMoveLetterboxTracker then
                                mod._mouseMoveLetterboxTracker = eventtap.new({ events.leftMouseDragged, events.leftMouseUp }, function(e)
                                    if e:getType() == events.leftMouseUp then
                                        mod._mouseMoveLetterboxTracker:stop()
                                        mod._mouseMoveLetterboxTracker = nil
                                    else
                                        Do(function()
                                            if mod._canvas then
                                                local mousePosition = mouse.getAbsolutePosition()
                                                local canvasTopLeft = mod._canvas:topLeft()
                                                local letterboxHeight = mousePosition.y - canvasTopLeft.y
                                                local viewerFrame = geometry.new(frame)
                                                if geometry.new(mousePosition):inside(viewerFrame) and letterboxHeight > 10  and letterboxHeight < (frame.h/2) then
                                                    mod._canvas["topLetterbox"].frame = { x = 0, y = 0, h = letterboxHeight, w = "100%"}
                                                    mod._canvas["bottomLetterbox"].frame = { x = 0, y = frame.h - letterboxHeight, h = letterboxHeight, w = "100%"}
                                                    mod.letterboxHeight(letterboxHeight)
                                                end
                                            end
                                        end):After(0)
                                    end
                                end, false):start()
                            end
                        end
                    end
                end)
            end

            --------------------------------------------------------------------------------
            -- Add Border:
            --------------------------------------------------------------------------------
            mod._canvas:appendElements({
                id               = "border",
                type             = "rectangle",
                action           = "stroke",
                strokeColor      = { hex = FCP_COLOR_BLUE },
                strokeWidth      = 5,
            })

            --------------------------------------------------------------------------------
            -- Show the Canvas:
            --------------------------------------------------------------------------------
            mod._canvas:level("status")
            mod._canvas:show()
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
    if mod._canvas then
        mod._canvas:delete()
        mod._canvas = nil
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
    local draggableGuideEnabled = mod.draggableGuideEnabled()
    if draggableGuideEnabled then
        for id=1, mod.NUMBER_OF_DRAGGABLE_GUIDES do
            if draggableGuideEnabled[tostring(id)] == true then
                return true
            end
        end
    end
    return false
end

-- areAnyOverlaysEnabled() -> boolean
-- Function
-- Are any Final Cut Pro Viewer Overlays Enabled?
--
-- Parameters:
--  * None
--
-- Returns:
--  * `true` if any Viewer Overlays are enabled otherwise `false`
local function areAnyOverlaysEnabled()
    return mod.basicGridEnabled() == true
    or mod.draggableGuidesEnabled() == true
    or mod.activeMemory() ~= 0
    or mod.crossHairEnabled() == true
    or mod.letterboxEnabled() == true
    or false
end

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
    -- If Final Cut Pro is Front Most & Viewer is Showing:
    --------------------------------------------------------------------------------
    local viewer = fcp:viewer()

    if fcp.isFrontmost()
        and viewer:isShowing()
        and not fcp.isModalDialogOpen()
        and not fcp:fullScreenWindow():isShowing()
        and not fcp:commandEditor():isShowing()
        and not fcp:preferencesWindow():isShowing()
    then
        --------------------------------------------------------------------------------
        -- Start the Keyboard Watcher:
        --------------------------------------------------------------------------------
        if mod._eventtap then
            mod._eventtap:start()
        end

        --------------------------------------------------------------------------------
        -- Toggle Overall Visibility:
        --------------------------------------------------------------------------------
        if areAnyOverlaysEnabled() == true then
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
        -- Otherwise hide the grid and disable the Keyboard Watcher:
        --------------------------------------------------------------------------------
        mod.hide()
        if mod._eventtap then
            mod._eventtap:stop()
        end
    end
end

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
    local viewer = fcp:viewer():contentsUI()
    local result = false
    if viewer then
        local path = mod.getStillsFolderPath()
        if path then
            local snapshot = axutils.snapshot(viewer, path .. "/memory" .. id .. ".png")
            if snapshot then
                result = true
            end
        else
            log.df("Could not create Cache Folder.")
        end
    else
        log.df("Could not find Viewer.")
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
    mod.update()
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
    mod.update()
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
    dialog.color.continuous(false)
    dialog.color.callback(function(color, closed)
        if closed then
            mod.gridColor("CUSTOM")
            mod.customGridColor(color)
            mod.update()
            fcp:launch()
        end
    end)
    dialog.color.show()
    hs.focus()
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

--- plugins.finalcutpro.viewer.overlays.getGuidePosition() -> none
--- Function
--- Get Guide Position.
---
--- Parameters:
---  * id - The ID of the guide.
---
--- Returns:
---  * None
function mod.setGuidePosition(id, value)
    id = tostring(id)
    local guidePosition = mod.guidePosition()
    guidePosition[id] = value
    mod.guidePosition(guidePosition)
end

--- plugins.finalcutpro.viewer.overlays.getGuidePosition() -> none
--- Function
--- Get Guide Position.
---
--- Parameters:
---  * id - The ID of the guide.
---
--- Returns:
---  * None
function mod.getGuidePosition(id)
    id = tostring(id)
    local guidePosition = mod.guidePosition()
    return guidePosition and guidePosition[id] or {}
end

--- plugins.finalcutpro.viewer.overlays.getGuideAlpha() -> none
--- Function
--- Get Guide Alpha.
---
--- Parameters:
---  * id - The ID of the guide.
---
--- Returns:
---  * None
function mod.getGuideAlpha(id)
    id = tostring(id)
    local guideAlpha = mod.guideAlpha()
    return guideAlpha and guideAlpha[id] or DEFAULT_ALPHA
end

--- plugins.finalcutpro.viewer.overlays.getGuideColor(id) -> none
--- Function
--- Get Guide Color.
---
--- Parameters:
---  * id - The ID of the guide.
---
--- Returns:
---  * None
function mod.getGuideColor(id)
    id = tostring(id)
    local guideColor = mod.guideColor()
    return guideColor and guideColor[id] or DEFAULT_COLOR
end

--- plugins.finalcutpro.viewer.overlays.getCustomGuideColor(id) -> none
--- Function
--- Get Custom Guide Color.
---
--- Parameters:
---  * id - The ID of the guide.
---
--- Returns:
---  * None
function mod.getCustomGuideColor(id)
    id = tostring(id)
    local customGuideColor = mod.customGuideColor()
    return customGuideColor and customGuideColor[id]
end

--- plugins.finalcutpro.viewer.overlays.setGuideAlpha(value) -> none
--- Function
--- Sets Guide Alpha.
---
--- Parameters:
---  * id - The ID of the guide.
---  * value - The value you want to set.
---
--- Returns:
---  * None
function mod.setGuideAlpha(id, value)
    id = tostring(id)
    local guideAlpha = mod.guideAlpha()
    guideAlpha[id] = value
    mod.guideAlpha(guideAlpha)
    mod.update()
end

--- plugins.finalcutpro.viewer.overlays.setGuideColor(value) -> none
--- Function
--- Sets Guide Color.
---
--- Parameters:
---  * id - The ID of the guide.
---  * value - The value you want to set.
---
--- Returns:
---  * None
function mod.setGuideColor(id, value)
    id = tostring(id)
    local guideColor = mod.guideColor()
    guideColor[id] = value
    mod.guideColor(guideColor)
    mod.update()
end

--- plugins.finalcutpro.viewer.overlays.setCustomGuideColor() -> none
--- Function
--- Pops up a Color Dialog box allowing the user to select a custom colour for guide lines.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.setCustomGuideColor(id)
    id = tostring(id)
    dialog.color.continuous(false)
    dialog.color.callback(function(color, closed)
        if color and closed then
            local guideColor = mod.guideColor()
            guideColor[id] = "CUSTOM"
            mod.guideColor(guideColor)

            local customGuideColor = mod.customGuideColor()
            customGuideColor[id] = color
            mod.customGuideColor(customGuideColor)

            mod.update()
            fcp:launch()
        end
    end)
    dialog.color.show()
    hs.focus()
end

--- plugins.finalcutpro.viewer.overlays.getDraggableGuideEnabled(id) -> none
--- Function
--- Get Guide Enabled.
---
--- Parameters:
---  * id - The ID of the guide.
---
--- Returns:
---  * None
function mod.getDraggableGuideEnabled(id)
    id = tostring(id)
    local draggableGuideEnabled = mod.draggableGuideEnabled()
    return draggableGuideEnabled and draggableGuideEnabled[id] and draggableGuideEnabled[id] == true
end

--- plugins.finalcutpro.viewer.overlays.toggleDraggableGuide(id) -> none
--- Function
--- Toggle Guide Enabled.
---
--- Parameters:
---  * id - The ID of the guide.
---
--- Returns:
---  * None
function mod.toggleDraggableGuide(id)
    id = tostring(id)
    local draggableGuideEnabled = mod.draggableGuideEnabled()
    if draggableGuideEnabled[id] and draggableGuideEnabled[id] == true then
        draggableGuideEnabled[id] = false
    else
        draggableGuideEnabled[id] = true
    end
    mod.draggableGuideEnabled(draggableGuideEnabled)
    mod.update()
end

--- plugins.finalcutpro.viewer.overlays.resetDraggableGuide(id) -> none
--- Function
--- Reset a specific Draggable Guide.
---
--- Parameters:
---  * id - The ID of the guide.
---
--- Returns:
---  * None
function mod.resetDraggableGuide(id)

    id = tostring(id)

    --------------------------------------------------------------------------------
    -- Reset Color:
    --------------------------------------------------------------------------------
    local guideColor = mod.guideColor()
    guideColor[id] = nil
    mod.guideColor(guideColor)

    --------------------------------------------------------------------------------
    -- Reset Alpha:
    --------------------------------------------------------------------------------
    local guideAlpha = mod.guideAlpha()
    guideAlpha[id] = nil
    mod.guideAlpha(guideAlpha)

    --------------------------------------------------------------------------------
    -- Reset Position:
    --------------------------------------------------------------------------------
    local guidePosition = mod.guidePosition()
    guidePosition[id] = nil
    mod.guidePosition(guidePosition)

    mod.update()

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
    mod.draggableGuideEnabled({})
    mod.guidePosition({})
    mod.guideColor({})
    mod.guideAlpha({})
    mod.customGuideColor({})
    mod.customCrossHairColor({})
    mod.update()
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
    return {
        --------------------------------------------------------------------------------
        --
        -- ENABLE OVERLAYS:
        --
        --------------------------------------------------------------------------------
        { title = i18n("enable") .. " " .. i18n("overlays"), checked = not mod.capslock() and not mod.disabled(), fn = function() mod.disabled:toggle(); mod.update() end, disabled = mod.capslock()  },
        { title = i18n("toggleOverlaysWithCapsLock"), checked = mod.capslock(), fn = function() mod.capslock:toggle(); mod.update() end },
        { title = "-", disabled = true },
        --------------------------------------------------------------------------------
        --
        -- DRAGGABLE GUIDES:
        --
        --------------------------------------------------------------------------------
        { title = string.upper(i18n("guides")) .. ":", disabled = true },
        { title = "  " .. i18n("draggableGuides"), menu = {
            { title = i18n("guide") .. " 1", menu = {
                { title = i18n("enable"),   checked = mod.getDraggableGuideEnabled(1), fn = function() mod.toggleDraggableGuide(1); mod.update(); end },
                { title = i18n("reset"), fn = function() mod.resetDraggableGuide(1) end },
                { title = i18n("appearance"), menu = {
                    { title = "  " .. i18n("color"), menu = {
                        { title = i18n("black"),    checked = mod.getGuideColor(1) == "#000000", fn = function() mod.setGuideColor(1, "#000000") end },
                        { title = i18n("white"),    checked = mod.getGuideColor(1) == "#FFFFFF", fn = function() mod.setGuideColor(1, "#FFFFFF") end },
                        { title = i18n("yellow"),   checked = mod.getGuideColor(1) == "#F4D03F", fn = function() mod.setGuideColor(1, "#F4D03F") end },
                        { title = i18n("red"),      checked = mod.getGuideColor(1) == "#FF5733", fn = function() mod.setGuideColor(1, "#FF5733") end },
                        { title = "-", disabled = true },
                        { title = i18n("custom"),   checked = mod.getGuideColor(1) == "CUSTOM", fn = function() mod.setCustomGuideColor(1) end},
                    }},
                    { title = "  " .. i18n("opacity"), menu = {
                        { title = "10%",  checked = mod.getGuideAlpha(1) == 10,  fn = function() mod.setGuideAlpha(1, 10) end },
                        { title = "20%",  checked = mod.getGuideAlpha(1) == 20,  fn = function() mod.setGuideAlpha(1, 20) end },
                        { title = "30%",  checked = mod.getGuideAlpha(1) == 30,  fn = function() mod.setGuideAlpha(1, 30) end },
                        { title = "40%",  checked = mod.getGuideAlpha(1) == 40,  fn = function() mod.setGuideAlpha(1, 40) end },
                        { title = "50%",  checked = mod.getGuideAlpha(1) == 50,  fn = function() mod.setGuideAlpha(1, 50) end },
                        { title = "60%",  checked = mod.getGuideAlpha(1) == 60,  fn = function() mod.setGuideAlpha(1, 60) end },
                        { title = "70%",  checked = mod.getGuideAlpha(1) == 70,  fn = function() mod.setGuideAlpha(1, 70) end },
                        { title = "80%",  checked = mod.getGuideAlpha(1) == 80,  fn = function() mod.setGuideAlpha(1, 80) end },
                        { title = "90%",  checked = mod.getGuideAlpha(1) == 90,  fn = function() mod.setGuideAlpha(1, 90) end },
                        { title = "100%", checked = mod.getGuideAlpha(1) == 100, fn = function() mod.setGuideAlpha(1, 100) end },
                    }},
                }},
            }},
            { title = i18n("guide") .. " 2", menu = {
                { title = i18n("enable"),   checked = mod.getDraggableGuideEnabled(2), fn = function() mod.toggleDraggableGuide(2); mod.update(); end },
                { title = i18n("reset"), fn = function() mod.resetDraggableGuide(2) end },
                { title = i18n("appearance"), menu = {
                    { title = "  " .. i18n("color"), menu = {
                        { title = i18n("black"),    checked = mod.getGuideColor(2) == "#000000", fn = function() mod.setGuideColor(2, "#000000") end },
                        { title = i18n("white"),    checked = mod.getGuideColor(2) == "#FFFFFF", fn = function() mod.setGuideColor(2, "#FFFFFF") end },
                        { title = i18n("yellow"),   checked = mod.getGuideColor(2) == "#F4D03F", fn = function() mod.setGuideColor(2, "#F4D03F") end },
                        { title = i18n("red"),      checked = mod.getGuideColor(2) == "#FF5733", fn = function() mod.setGuideColor(2, "#FF5733") end },
                        { title = "-", disabled = true },
                        { title = i18n("custom"),   checked = mod.getGuideColor(2) == "CUSTOM", fn = function() mod.setCustomGuideColor(2) end},
                    }},
                    { title = "  " .. i18n("opacity"), menu = {
                        { title = "10%",  checked = mod.getGuideAlpha(2) == 10,  fn = function() mod.setGuideAlpha(2, 10) end },
                        { title = "20%",  checked = mod.getGuideAlpha(2) == 20,  fn = function() mod.setGuideAlpha(2, 20) end },
                        { title = "30%",  checked = mod.getGuideAlpha(2) == 30,  fn = function() mod.setGuideAlpha(2, 30) end },
                        { title = "40%",  checked = mod.getGuideAlpha(2) == 40,  fn = function() mod.setGuideAlpha(2, 40) end },
                        { title = "50%",  checked = mod.getGuideAlpha(2) == 50,  fn = function() mod.setGuideAlpha(2, 50) end },
                        { title = "60%",  checked = mod.getGuideAlpha(2) == 60,  fn = function() mod.setGuideAlpha(2, 60) end },
                        { title = "70%",  checked = mod.getGuideAlpha(2) == 70,  fn = function() mod.setGuideAlpha(2, 70) end },
                        { title = "80%",  checked = mod.getGuideAlpha(2) == 80,  fn = function() mod.setGuideAlpha(2, 80) end },
                        { title = "90%",  checked = mod.getGuideAlpha(2) == 90,  fn = function() mod.setGuideAlpha(2, 90) end },
                        { title = "100%", checked = mod.getGuideAlpha(2) == 100, fn = function() mod.setGuideAlpha(2, 100) end },
                    }},
                }},
            }},
            { title = i18n("guide") .. " 3", menu = {
                { title = i18n("enable"),   checked = mod.getDraggableGuideEnabled(3), fn = function() mod.toggleDraggableGuide(3); mod.update(); end },
                { title = i18n("reset"), fn = function() mod.resetDraggableGuide(3) end },
                { title = i18n("appearance"), menu = {
                    { title = "  " .. i18n("color"), menu = {
                        { title = i18n("black"),    checked = mod.getGuideColor(3) == "#000000", fn = function() mod.setGuideColor(3, "#000000") end },
                        { title = i18n("white"),    checked = mod.getGuideColor(3) == "#FFFFFF", fn = function() mod.setGuideColor(3, "#FFFFFF") end },
                        { title = i18n("yellow"),   checked = mod.getGuideColor(3) == "#F4D03F", fn = function() mod.setGuideColor(3, "#F4D03F") end },
                        { title = i18n("red"),      checked = mod.getGuideColor(3) == "#FF5733", fn = function() mod.setGuideColor(3, "#FF5733") end },
                        { title = "-", disabled = true },
                        { title = i18n("custom"),   checked = mod.getGuideColor(3) == "CUSTOM", fn = function() mod.setCustomGuideColor(3) end},
                    }},
                    { title = "  " .. i18n("opacity"), menu = {
                        { title = "10%",  checked = mod.getGuideAlpha(3) == 10,  fn = function() mod.setGuideAlpha(3, 10) end },
                        { title = "20%",  checked = mod.getGuideAlpha(3) == 20,  fn = function() mod.setGuideAlpha(3, 20) end },
                        { title = "30%",  checked = mod.getGuideAlpha(3) == 30,  fn = function() mod.setGuideAlpha(3, 30) end },
                        { title = "40%",  checked = mod.getGuideAlpha(3) == 40,  fn = function() mod.setGuideAlpha(3, 40) end },
                        { title = "50%",  checked = mod.getGuideAlpha(3) == 50,  fn = function() mod.setGuideAlpha(3, 50) end },
                        { title = "60%",  checked = mod.getGuideAlpha(3) == 60,  fn = function() mod.setGuideAlpha(3, 60) end },
                        { title = "70%",  checked = mod.getGuideAlpha(3) == 70,  fn = function() mod.setGuideAlpha(3, 70) end },
                        { title = "80%",  checked = mod.getGuideAlpha(3) == 80,  fn = function() mod.setGuideAlpha(3, 80) end },
                        { title = "90%",  checked = mod.getGuideAlpha(3) == 90,  fn = function() mod.setGuideAlpha(3, 90) end },
                        { title = "100%", checked = mod.getGuideAlpha(3) == 100, fn = function() mod.setGuideAlpha(3, 100) end },
                    }},
                }},
            }},
            { title = i18n("guide") .. " 4", menu = {
                { title = i18n("enable"),   checked = mod.getDraggableGuideEnabled(4), fn = function() mod.toggleDraggableGuide(4); mod.update(); end },
                { title = i18n("reset"), fn = function() mod.resetDraggableGuide(4) end },
                { title = i18n("appearance"), menu = {
                    { title = "  " .. i18n("color"), menu = {
                        { title = i18n("black"),    checked = mod.getGuideColor(4) == "#000000", fn = function() mod.setGuideColor(4, "#000000") end },
                        { title = i18n("white"),    checked = mod.getGuideColor(4) == "#FFFFFF", fn = function() mod.setGuideColor(4, "#FFFFFF") end },
                        { title = i18n("yellow"),   checked = mod.getGuideColor(4) == "#F4D03F", fn = function() mod.setGuideColor(4, "#F4D03F") end },
                        { title = i18n("red"),      checked = mod.getGuideColor(4) == "#FF5733", fn = function() mod.setGuideColor(4, "#FF5733") end },
                        { title = "-", disabled = true },
                        { title = i18n("custom"),   checked = mod.getGuideColor(4) == "CUSTOM", fn = function() mod.setCustomGuideColor(4) end},
                    }},
                    { title = "  " .. i18n("opacity"), menu = {
                        { title = "10%",  checked = mod.getGuideAlpha(4) == 10,  fn = function() mod.setGuideAlpha(4, 10) end },
                        { title = "20%",  checked = mod.getGuideAlpha(4) == 20,  fn = function() mod.setGuideAlpha(4, 20) end },
                        { title = "30%",  checked = mod.getGuideAlpha(4) == 30,  fn = function() mod.setGuideAlpha(4, 30) end },
                        { title = "40%",  checked = mod.getGuideAlpha(4) == 40,  fn = function() mod.setGuideAlpha(4, 40) end },
                        { title = "50%",  checked = mod.getGuideAlpha(4) == 50,  fn = function() mod.setGuideAlpha(4, 50) end },
                        { title = "60%",  checked = mod.getGuideAlpha(4) == 60,  fn = function() mod.setGuideAlpha(4, 60) end },
                        { title = "70%",  checked = mod.getGuideAlpha(4) == 70,  fn = function() mod.setGuideAlpha(4, 70) end },
                        { title = "80%",  checked = mod.getGuideAlpha(4) == 80,  fn = function() mod.setGuideAlpha(4, 80) end },
                        { title = "90%",  checked = mod.getGuideAlpha(4) == 90,  fn = function() mod.setGuideAlpha(4, 90) end },
                        { title = "100%", checked = mod.getGuideAlpha(4) == 100, fn = function() mod.setGuideAlpha(4, 100) end },
                    }},
                }},
            }},
            { title = i18n("guide") .. " 5", menu = {
                { title = i18n("enable"),   checked = mod.getDraggableGuideEnabled(5), fn = function() mod.toggleDraggableGuide(5); mod.update(); end },
                { title = i18n("reset"), fn = function() mod.resetDraggableGuide(5) end },
                { title = i18n("appearance"), menu = {
                    { title = "  " .. i18n("color"), menu = {
                        { title = i18n("black"),    checked = mod.getGuideColor(5) == "#000000", fn = function() mod.setGuideColor(5, "#000000") end },
                        { title = i18n("white"),    checked = mod.getGuideColor(5) == "#FFFFFF", fn = function() mod.setGuideColor(5, "#FFFFFF") end },
                        { title = i18n("yellow"),   checked = mod.getGuideColor(5) == "#F4D03F", fn = function() mod.setGuideColor(5, "#F4D03F") end },
                        { title = i18n("red"),      checked = mod.getGuideColor(5) == "#FF5733", fn = function() mod.setGuideColor(5, "#FF5733") end },
                        { title = "-", disabled = true },
                        { title = i18n("custom"),   checked = mod.getGuideColor(5) == "CUSTOM", fn = function() mod.setCustomGuideColor(5) end},
                    }},
                    { title = "  " .. i18n("opacity"), menu = {
                        { title = "10%",  checked = mod.getGuideAlpha(5) == 10,  fn = function() mod.setGuideAlpha(5, 10) end },
                        { title = "20%",  checked = mod.getGuideAlpha(5) == 20,  fn = function() mod.setGuideAlpha(5, 20) end },
                        { title = "30%",  checked = mod.getGuideAlpha(5) == 30,  fn = function() mod.setGuideAlpha(5, 30) end },
                        { title = "40%",  checked = mod.getGuideAlpha(5) == 40,  fn = function() mod.setGuideAlpha(5, 40) end },
                        { title = "50%",  checked = mod.getGuideAlpha(5) == 50,  fn = function() mod.setGuideAlpha(5, 50) end },
                        { title = "60%",  checked = mod.getGuideAlpha(5) == 60,  fn = function() mod.setGuideAlpha(5, 60) end },
                        { title = "70%",  checked = mod.getGuideAlpha(5) == 70,  fn = function() mod.setGuideAlpha(5, 70) end },
                        { title = "80%",  checked = mod.getGuideAlpha(5) == 80,  fn = function() mod.setGuideAlpha(5, 80) end },
                        { title = "90%",  checked = mod.getGuideAlpha(5) == 90,  fn = function() mod.setGuideAlpha(5, 90) end },
                        { title = "100%", checked = mod.getGuideAlpha(5) == 100, fn = function() mod.setGuideAlpha(5, 100) end },
                    }},
                }},
            }},
        }},
        --------------------------------------------------------------------------------
        --
        -- CROSS HAIR:
        --
        --------------------------------------------------------------------------------
        { title = "  " .. i18n("crossHair"), menu = {
            { title = i18n("enable"),   checked = mod.crossHairEnabled(), fn = function() mod.crossHairEnabled:toggle(); mod.update(); end },
            { title = i18n("appearance"), menu = {
                { title = "  " .. i18n("color"), menu = {
                    { title = i18n("black"),    checked = mod.crossHairColor() == "#000000", fn = function() mod.crossHairColor("#000000"); mod.update() end },
                    { title = i18n("white"),    checked = mod.crossHairColor() == "#FFFFFF", fn = function() mod.crossHairColor("#FFFFFF"); mod.update() end },
                    { title = i18n("yellow"),   checked = mod.crossHairColor() == "#F4D03F", fn = function() mod.crossHairColor("#F4D03F"); mod.update() end },
                    { title = i18n("red"),      checked = mod.crossHairColor() == "#FF5733", fn = function() mod.crossHairColor("#FF5733"); mod.update() end },
                    { title = "-", disabled = true },
                    { title = i18n("custom"),   checked = mod.crossHairColor() == "CUSTOM", fn = function() mod.setCustomCrossHairColor(); mod.update() end},
                }},
                { title = "  " .. i18n("opacity"), menu = {
                    { title = "10%",  checked = mod.crossHairAlpha() == 10,  fn = function() mod.crossHairAlpha(10); mod.update() end },
                    { title = "20%",  checked = mod.crossHairAlpha() == 20,  fn = function() mod.crossHairAlpha(20); mod.update() end },
                    { title = "30%",  checked = mod.crossHairAlpha() == 30,  fn = function() mod.crossHairAlpha(30); mod.update() end },
                    { title = "40%",  checked = mod.crossHairAlpha() == 40,  fn = function() mod.crossHairAlpha(40); mod.update() end },
                    { title = "50%",  checked = mod.crossHairAlpha() == 50,  fn = function() mod.crossHairAlpha(50); mod.update() end },
                    { title = "60%",  checked = mod.crossHairAlpha() == 60,  fn = function() mod.crossHairAlpha(60); mod.update() end },
                    { title = "70%",  checked = mod.crossHairAlpha() == 70,  fn = function() mod.crossHairAlpha(70); mod.update() end },
                    { title = "80%",  checked = mod.crossHairAlpha() == 80,  fn = function() mod.crossHairAlpha(80); mod.update() end },
                    { title = "90%",  checked = mod.crossHairAlpha() == 90,  fn = function() mod.crossHairAlpha(90); mod.update() end },
                    { title = "100%", checked = mod.crossHairAlpha() == 100, fn = function() mod.crossHairAlpha(100); mod.update() end },
                }},
            }},
        }},
        { title = "-", disabled = true },
        { title = string.upper(i18n("mattes")) .. ":", disabled = true },
        { title = "  " .. i18n("letterbox"), menu = {
            { title = i18n("enable"),   checked = mod.letterboxEnabled(), fn = function() mod.letterboxEnabled:toggle(); mod.update(); end },
        }},
        { title = "-", disabled = true },
        --------------------------------------------------------------------------------
        --
        -- STILL FRAMES:
        --
        --------------------------------------------------------------------------------
        { title = string.upper(i18n("stillFrames")) .. ":", disabled = true },
        { title = "  " .. i18n("view"), menu = {
            { title = i18n("memory") .. " 1", checked = mod.activeMemory() == 1, fn = function() mod.viewMemory(1) end, disabled = not mod.getMemory(1) },
            { title = i18n("memory") .. " 2", checked = mod.activeMemory() == 2, fn = function() mod.viewMemory(2) end, disabled = not mod.getMemory(2) },
            { title = i18n("memory") .. " 3", checked = mod.activeMemory() == 3, fn = function() mod.viewMemory(3) end, disabled = not mod.getMemory(3) },
            { title = i18n("memory") .. " 4", checked = mod.activeMemory() == 4, fn = function() mod.viewMemory(4) end, disabled = not mod.getMemory(4) },
            { title = i18n("memory") .. " 5", checked = mod.activeMemory() == 5, fn = function() mod.viewMemory(5) end, disabled = not mod.getMemory(5) },
        }},
        { title = "  " .. i18n("save"), menu = {
            { title = i18n("memory") .. " 1", fn = function() mod.saveMemory(1) end },
            { title = i18n("memory") .. " 2", fn = function() mod.saveMemory(2) end },
            { title = i18n("memory") .. " 3", fn = function() mod.saveMemory(3) end },
            { title = i18n("memory") .. " 4", fn = function() mod.saveMemory(4) end },
            { title = i18n("memory") .. " 5", fn = function() mod.saveMemory(5) end },
        }},
        { title = "  " .. i18n("import"), menu = {
            { title = i18n("memory") .. " 1", fn = function() mod.importMemory(1) end },
            { title = i18n("memory") .. " 2", fn = function() mod.importMemory(2) end },
            { title = i18n("memory") .. " 3", fn = function() mod.importMemory(3) end },
            { title = i18n("memory") .. " 4", fn = function() mod.importMemory(4) end },
            { title = i18n("memory") .. " 5", fn = function() mod.importMemory(5) end },
        }},
        { title = "  " .. i18n("delete"), menu = {
            { title = i18n("memory") .. " 1", fn = function() mod.deleteMemory(1) end, disabled = not mod.getMemory(1) },
            { title = i18n("memory") .. " 2", fn = function() mod.deleteMemory(2) end, disabled = not mod.getMemory(2) },
            { title = i18n("memory") .. " 3", fn = function() mod.deleteMemory(3) end, disabled = not mod.getMemory(3) },
            { title = i18n("memory") .. " 4", fn = function() mod.deleteMemory(4) end, disabled = not mod.getMemory(4) },
            { title = i18n("memory") .. " 5", fn = function() mod.deleteMemory(5) end, disabled = not mod.getMemory(5) },
        }},
        { title = "  " .. i18n("appearance"), menu = {
            { title = i18n("fullFrame"),  checked = mod.stillsLayout() == "Full Frame", fn = function() mod.stillsLayout("Full Frame"); mod.update() end },
            { title = "-", disabled = true },
            { title = i18n("leftVertical"),  checked = mod.stillsLayout() == "Left Vertical", fn = function() mod.stillsLayout("Left Vertical"); mod.update() end },
            { title = i18n("rightVertical"), checked = mod.stillsLayout() == "Right Vertical", fn = function() mod.stillsLayout("Right Vertical"); mod.update() end },
            { title = "-", disabled = true },
            { title = i18n("topHorizontal"), checked = mod.stillsLayout() == "Top Horizontal", fn = function() mod.stillsLayout("Top Horizontal"); mod.update() end },
            { title = i18n("bottomHorizontal"), checked = mod.stillsLayout() == "Bottom Horizontal", fn = function() mod.stillsLayout("Bottom Horizontal"); mod.update() end },
        }},
        { title = "-", disabled = true },
        --------------------------------------------------------------------------------
        --
        -- GRID OVERLAY:
        --
        --------------------------------------------------------------------------------
        { title = string.upper(i18n("gridOverlay")) .. ":", disabled = true },
        { title = "  " .. i18n("enable"), checked = mod.basicGridEnabled(), fn = function() mod.basicGridEnabled:toggle(); mod.update(); end },
        { title = "  " .. i18n("appearance"), menu = {
            { title = "  " .. i18n("color"), menu = {
                { title = i18n("black"),    checked = mod.gridColor() == "#000000", fn = function() mod.setGridColor("#000000") end },
                { title = i18n("white"),    checked = mod.gridColor() == "#FFFFFF", fn = function() mod.setGridColor("#FFFFFF") end },
                { title = i18n("yellow"),   checked = mod.gridColor() == "#F4D03F", fn = function() mod.setGridColor("#F4D03F") end },
                { title = i18n("red"),      checked = mod.gridColor() == "#FF5733", fn = function() mod.setGridColor("#FF5733") end },
                { title = "-", disabled = true },
                { title = i18n("custom"),   checked = mod.gridColor() == "CUSTOM" and mod.customGridColor(), fn = mod.setCustomGridColor },
            }},
            { title = "  " .. i18n("opacity"), menu = {
                { title = "10%",  checked = mod.gridAlpha() == 10,  fn = function() mod.setGridAlpha(10) end },
                { title = "20%",  checked = mod.gridAlpha() == 20,  fn = function() mod.setGridAlpha(20) end },
                { title = "30%",  checked = mod.gridAlpha() == 30,  fn = function() mod.setGridAlpha(30) end },
                { title = "40%",  checked = mod.gridAlpha() == 40,  fn = function() mod.setGridAlpha(40) end },
                { title = "50%",  checked = mod.gridAlpha() == 50,  fn = function() mod.setGridAlpha(50) end },
                { title = "60%",  checked = mod.gridAlpha() == 60,  fn = function() mod.setGridAlpha(60) end },
                { title = "70%",  checked = mod.gridAlpha() == 70,  fn = function() mod.setGridAlpha(70) end },
                { title = "80%",  checked = mod.gridAlpha() == 80,  fn = function() mod.setGridAlpha(80) end },
                { title = "90%",  checked = mod.gridAlpha() == 90,  fn = function() mod.setGridAlpha(90) end },
                { title = "100%", checked = mod.gridAlpha() == 100, fn = function() mod.setGridAlpha(100) end },
            }},
            { title = "  " .. i18n("segments"), menu = {
                { title = "5",      checked = mod.gridSpacing() == 5,  fn = function() mod.setGridSpacing(5) end },
                { title = "10",     checked = mod.gridSpacing() == 10, fn = function() mod.setGridSpacing(10) end },
                { title = "15",     checked = mod.gridSpacing() == 15, fn = function() mod.setGridSpacing(15) end },
                { title = "20",     checked = mod.gridSpacing() == 20, fn = function() mod.setGridSpacing(20) end },
                { title = "25",     checked = mod.gridSpacing() == 25, fn = function() mod.setGridSpacing(25) end },
                { title = "30",     checked = mod.gridSpacing() == 30, fn = function() mod.setGridSpacing(30) end },
                { title = "35",     checked = mod.gridSpacing() == 35, fn = function() mod.setGridSpacing(35) end },
                { title = "40",     checked = mod.gridSpacing() == 40, fn = function() mod.setGridSpacing(40) end },
                { title = "45",     checked = mod.gridSpacing() == 45, fn = function() mod.setGridSpacing(45) end },
                { title = "50",     checked = mod.gridSpacing() == 50, fn = function() mod.setGridSpacing(50) end },
                { title = "55",     checked = mod.gridSpacing() == 55, fn = function() mod.setGridSpacing(55) end },
                { title = "60",     checked = mod.gridSpacing() == 60, fn = function() mod.setGridSpacing(60) end },
                { title = "65",     checked = mod.gridSpacing() == 65, fn = function() mod.setGridSpacing(65) end },
                { title = "70",     checked = mod.gridSpacing() == 70, fn = function() mod.setGridSpacing(70) end },
                { title = "75",     checked = mod.gridSpacing() == 75, fn = function() mod.setGridSpacing(70) end },
                { title = "80",     checked = mod.gridSpacing() == 80, fn = function() mod.setGridSpacing(80) end },
                { title = "85",     checked = mod.gridSpacing() == 85, fn = function() mod.setGridSpacing(85) end },
                { title = "90",     checked = mod.gridSpacing() == 90, fn = function() mod.setGridSpacing(90) end },
                { title = "95",     checked = mod.gridSpacing() == 95, fn = function() mod.setGridSpacing(95) end },
                { title = "100",    checked = mod.gridSpacing() == 100, fn = function() mod.setGridSpacing(100) end },
            }},
        }},
        { title = "-", disabled = true },
        { title = i18n("reset") .. " " .. i18n("overlays"), fn = function() mod.resetOverlays() end },
    }
end

-- contextualMenu(event) -> none
-- Function
-- Builds the Final Cut Pro Overlay contextual menu.
--
-- Parameters:
--  * event - The `hs.eventtap` event
--
-- Returns:
--  * None
local function contextualMenu(event)
    local ui = fcp:viewer():UI()
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
    -- Setup Event Tap:
    --------------------------------------------------------------------------------
    mod._eventtap = eventtap.new({events.rightMouseUp}, contextualMenu)

    --------------------------------------------------------------------------------
    -- Setup the system menu:
    --------------------------------------------------------------------------------
    deps.menu.viewer
        :addMenu(10001, function() return i18n("overlay") end)
        :addItems(1000, generateMenu)

    --------------------------------------------------------------------------------
    -- Update Canvas when Final Cut Pro is shown/hidden:
    --------------------------------------------------------------------------------
    fcp.isFrontmost:watch(deferredUpdate)
    fcp.isModalDialogOpen:watch(deferredUpdate)
    fcp:fullScreenWindow().isShowing:watch(deferredUpdate)
    fcp:commandEditor().isShowing:watch(deferredUpdate)
    fcp:preferencesWindow().isShowing:watch(deferredUpdate)

    --------------------------------------------------------------------------------
    -- Update Canvas one second after going full-screen:
    --------------------------------------------------------------------------------
    fcp:primaryWindow().isFullScreen:watch(function() doAfter(1, mod.update) end)

    --------------------------------------------------------------------------------
    -- Update Canvas when Final Cut Pro's Viewer is resized or moved:
    --------------------------------------------------------------------------------
    fcp:viewer().frame:watch(function(value)
        if value then
            mod.update()
        end
    end)

    --------------------------------------------------------------------------------
    -- Force initial update:
    --------------------------------------------------------------------------------
    mod.capslock:update()
    mod.update()

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
                :whenActivated(function() mod.toggleDraggableGuide(i); mod.update() end)
                :titled(i18n("cpViewerDraggableGuide_title") .. " " .. i)
        end

        deps.fcpxCmds
            :add("cpToggleAllViewerOverlays")
            :whenActivated(function() mod.disabled:toggle(); mod.update() end)

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
    mod.update()
end

return plugin
