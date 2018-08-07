--- === plugins.finalcutpro.viewer.overlays ===
---
--- Final Cut Pro Viewer Overlays.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log               = require("hs.logger").new("overlays")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local canvas            = require("hs.canvas")
local dialog            = require("hs.dialog")
local eventtap          = require("hs.eventtap")
local fs                = require("hs.fs")
local geometry          = require("hs.geometry")
local image             = require("hs.image")
local menubar           = require("hs.menubar")
local mouse             = require("hs.mouse")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils           = require("cp.ui.axutils")
local config            = require("cp.config")
local cpDialog          = require("cp.dialog")
local fcp               = require("cp.apple.finalcutpro")
local i18n              = require("cp.i18n")
local tools             = require("cp.tools")

--------------------------------------------------------------------------------
-- Local Lua Functions:
--------------------------------------------------------------------------------
local events            = eventtap.event.types

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

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

-- FCP_COLOR_BLUE -> string
-- Constant
-- Apple's preferred blue colour in Final Cut Pro.
local FCP_COLOR_BLUE = "#5760e7"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

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

--- plugins.finalcutpro.viewer.overlays.basicGridEnabled <cp.prop: boolean>
--- Variable
--- Is Viewer Grid Enabled?
mod.basicGridEnabled = config.prop("fcpx.ViewerOverlay.BasicGrid.Enabled", false)

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
                    mod._canvas:clickActivating(false)
                    mod._canvas:canvasMouseEvents(true, true, true, true)
                end
            end
            if draggableGuideEnabled then
                mod._canvas:mouseCallback(function(_, event, id)
                    for i=1, mod.NUMBER_OF_DRAGGABLE_GUIDES do
                        if id == "dragCentre" .. i and event == "mouseDown" then
                            if not mod._mouseMoveTracker then
                                mod._mouseMoveTracker = {}
                            end
                            mod._mouseMoveTracker[i] = eventtap.new({ events.leftMouseDragged, events.leftMouseUp }, function(e)
                                if e:getType() == events.leftMouseUp then
                                    mod._mouseMoveTracker[i]:stop()
                                    mod._mouseMoveTracker[i] = nil
                                else
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
                            end, false):start()
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
    if fcp.isFrontmost() and fcp:viewer():isShowing() then
        --------------------------------------------------------------------------------
        -- Start the Keyboard Watcher:
        --------------------------------------------------------------------------------
        if mod._eventtap then
            --log.df("Starting Keyboard Monitor")
            mod._eventtap:start()
        end
        --------------------------------------------------------------------------------
        -- Show the grid if enabled:
        --------------------------------------------------------------------------------
        local draggableGuideEnabled = false
        for i=1, mod.NUMBER_OF_DRAGGABLE_GUIDES do
            if mod.getDraggableGuideEnabled(i) then
                draggableGuideEnabled = true
            end
        end
        if not mod.disabled() and (mod.basicGridEnabled() or draggableGuideEnabled or mod.activeMemory() ~= 0) then
            mod.show()
        else
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
        if closed then
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
                mod._menu:setMenu({
                    --------------------------------------------------------------------------------
                    --
                    -- ENABLE OVERLAYS:
                    --
                    --------------------------------------------------------------------------------
                    { title = i18n("enable") .. " " .. i18n("overlays"), checked = not mod.disabled(), fn = function() mod.disabled:toggle(); mod.update() end },
                    { title = "-", disabled = true },
                    --------------------------------------------------------------------------------
                    --
                    -- DRAGGABLE GUIDES:
                    --
                    --------------------------------------------------------------------------------
                    { title = string.upper(i18n("guides")) .. ":", disabled = true },
                    { title = "  " .. i18n("draggableGuides"), menu = {
                        { title = "Guide 1", menu = {
                            { title = i18n("enable"),   checked = mod.getDraggableGuideEnabled(1), fn = function() mod.toggleDraggableGuide(1); mod.update(); end },
                            { title = i18n("appearance"), menu = {
                                { title = "  " .. i18n("color"), menu = {
                                    { title = i18n("black"),    checked = mod.getGuideColor(1) == "#000000", fn = function() mod.setGuideColor(1, "#000000") end },
                                    { title = i18n("white"),    checked = mod.getGuideColor(1) == "#FFFFFF", fn = function() mod.setGuideColor(1, "#FFFFFF") end },
                                    { title = i18n("yellow"),   checked = mod.getGuideColor(1) == "#F4D03F", fn = function() mod.setGuideColor(1, "#F4D03F") end },
                                    { title = i18n("red"),      checked = mod.getGuideColor(1) == "#FF5733", fn = function() mod.setGuideColor(1, "#FF5733") end },
                                    { title = "-", disabled = true },
                                    { title = i18n("custom"),   checked = mod.getGuideColor(1) == "CUSTOM" and mod.getCustomGuideColor(1), fn = function() mod.setCustomGuideColor(1) end},
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
                        { title = "Guide 2", menu = {
                            { title = i18n("enable"),   checked = mod.getDraggableGuideEnabled(2), fn = function() mod.toggleDraggableGuide(2); mod.update(); end },
                            { title = i18n("appearance"), menu = {
                                { title = "  " .. i18n("color"), menu = {
                                    { title = i18n("black"),    checked = mod.getGuideColor(2) == "#000000", fn = function() mod.setGuideColor(2, "#000000") end },
                                    { title = i18n("white"),    checked = mod.getGuideColor(2) == "#FFFFFF", fn = function() mod.setGuideColor(2, "#FFFFFF") end },
                                    { title = i18n("yellow"),   checked = mod.getGuideColor(2) == "#F4D03F", fn = function() mod.setGuideColor(2, "#F4D03F") end },
                                    { title = i18n("red"),      checked = mod.getGuideColor(2) == "#FF5733", fn = function() mod.setGuideColor(2, "#FF5733") end },
                                    { title = "-", disabled = true },
                                    { title = i18n("custom"),   checked = mod.getGuideColor(2) == "CUSTOM" and mod.getCustomGuideColor(2), fn = function() mod.setCustomGuideColor(1) end},
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
                        { title = "Guide 3", menu = {
                            { title = i18n("enable"),   checked = mod.getDraggableGuideEnabled(3), fn = function() mod.toggleDraggableGuide(3); mod.update(); end },
                            { title = i18n("appearance"), menu = {
                                { title = "  " .. i18n("color"), menu = {
                                    { title = i18n("black"),    checked = mod.getGuideColor(3) == "#000000", fn = function() mod.setGuideColor(3, "#000000") end },
                                    { title = i18n("white"),    checked = mod.getGuideColor(3) == "#FFFFFF", fn = function() mod.setGuideColor(3, "#FFFFFF") end },
                                    { title = i18n("yellow"),   checked = mod.getGuideColor(3) == "#F4D03F", fn = function() mod.setGuideColor(3, "#F4D03F") end },
                                    { title = i18n("red"),      checked = mod.getGuideColor(3) == "#FF5733", fn = function() mod.setGuideColor(3, "#FF5733") end },
                                    { title = "-", disabled = true },
                                    { title = i18n("custom"),   checked = mod.getGuideColor(3) == "CUSTOM" and mod.getCustomGuideColor(3), fn = function() mod.setCustomGuideColor(1) end},
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
                        { title = "Guide 4", menu = {
                            { title = i18n("enable"),   checked = mod.getDraggableGuideEnabled(4), fn = function() mod.toggleDraggableGuide(4); mod.update(); end },
                            { title = i18n("appearance"), menu = {
                                { title = "  " .. i18n("color"), menu = {
                                    { title = i18n("black"),    checked = mod.getGuideColor(4) == "#000000", fn = function() mod.setGuideColor(4, "#000000") end },
                                    { title = i18n("white"),    checked = mod.getGuideColor(4) == "#FFFFFF", fn = function() mod.setGuideColor(4, "#FFFFFF") end },
                                    { title = i18n("yellow"),   checked = mod.getGuideColor(4) == "#F4D03F", fn = function() mod.setGuideColor(4, "#F4D03F") end },
                                    { title = i18n("red"),      checked = mod.getGuideColor(4) == "#FF5733", fn = function() mod.setGuideColor(4, "#FF5733") end },
                                    { title = "-", disabled = true },
                                    { title = i18n("custom"),   checked = mod.getGuideColor(4) == "CUSTOM" and mod.getCustomGuideColor(4), fn = function() mod.setCustomGuideColor(1) end},
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
                        { title = "Guide 5", menu = {
                            { title = i18n("enable"),   checked = mod.getDraggableGuideEnabled(5), fn = function() mod.toggleDraggableGuide(5); mod.update(); end },
                            { title = i18n("appearance"), menu = {
                                { title = "  " .. i18n("color"), menu = {
                                    { title = i18n("black"),    checked = mod.getGuideColor(5) == "#000000", fn = function() mod.setGuideColor(5, "#000000") end },
                                    { title = i18n("white"),    checked = mod.getGuideColor(5) == "#FFFFFF", fn = function() mod.setGuideColor(5, "#FFFFFF") end },
                                    { title = i18n("yellow"),   checked = mod.getGuideColor(5) == "#F4D03F", fn = function() mod.setGuideColor(5, "#F4D03F") end },
                                    { title = i18n("red"),      checked = mod.getGuideColor(5) == "#FF5733", fn = function() mod.setGuideColor(5, "#FF5733") end },
                                    { title = "-", disabled = true },
                                    { title = i18n("custom"),   checked = mod.getGuideColor(5) == "CUSTOM" and mod.getCustomGuideColor(5), fn = function() mod.setCustomGuideColor(1) end},
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
                            { title = "100",     checked = mod.gridSpacing() == 100, fn = function() mod.setGridSpacing(100) end },
                        }},
                    }},
                })
                mod._menu:popupMenu(location, true)
            end
        end
    end
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.viewer.overlays",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]        = "fcpxCmds",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Setup contextual menu:
    --------------------------------------------------------------------------------
    mod._menu = menubar.new(false)
    mod._eventtap = eventtap.new({eventtap.event.types.rightMouseUp}, contextualMenu)

    --------------------------------------------------------------------------------
    -- Update Canvas when Final Cut Pro is shown/hidden:
    --------------------------------------------------------------------------------
    fcp.isFrontmost:watch(mod.update)

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

--------------------------------------------------------------------------------
-- POST INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.postInit()

    --------------------------------------------------------------------------------
    -- Update the Canvas on initial boot:
    --------------------------------------------------------------------------------
    mod.update()

end

return plugin
