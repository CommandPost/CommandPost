--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.viewer.overlays ===
---
--- Final Cut Pro Viewer Overlays.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log               = require("hs.logger").new("overlays")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils           = require("cp.ui.axutils")
local config            = require("cp.config")
local fcp               = require("cp.apple.finalcutpro")
local tools             = require("cp.tools")

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

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local STILLS_FOLDER         = "Still Frames"

local DEFAULT_MODE          = "Basic Grid"
local DEFAULT_COLOR         = "#FFFFFF"
local DEFAULT_ALPHA         = 50
local DEFAULT_GRID_SPACING  = 20
local DEFAULT_STILLS_LAYOUT = "Left Vertical"

local NUMBER_OF_MEMORIES    = 5

local FCP_COLOR_BLUE        = "#5760e7"
--local FCP_COLOR_RED         = "#d1393e"
--local FCP_COLOR_GREEN       = "#3f9253"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

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
    local ui = fcp:viewer():UI()
    local fcpFrame = ui and axutils.childWithRole(ui, "AXSplitGroup")
    if fcpFrame then
        local frame = fcpFrame:attributeValue("AXFrame")
        if frame then
            --------------------------------------------------------------------------------
            -- New Canvas:
            --------------------------------------------------------------------------------
            mod._canvas = canvas.new(frame)

            --------------------------------------------------------------------------------
            -- Get Preferences:
            --------------------------------------------------------------------------------
            local mode          = mod.gridMode()
            local gridEnabled   = mod.gridEnabled()
            local gridColor     = mod.gridColor()
            local gridAlpha     = mod.gridAlpha() / 100
            local gridSpacing   = mod.gridSpacing()
            local stillsLayout  = mod.stillsLayout()
            local guidePosition = mod.guidePosition()

            --------------------------------------------------------------------------------
            -- Grid Fill Colour:
            --------------------------------------------------------------------------------
            local fillColor
            if gridColor == "CUSTOM" and mod.customGridColor() then
                fillColor = mod.customGridColor()
                fillColor.alpha = gridAlpha
            else
                fillColor = { hex = gridColor, alpha = gridAlpha }
            end

            --------------------------------------------------------------------------------
            -- Add Still Frames:
            --------------------------------------------------------------------------------
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
            -- Add Grid:
            --------------------------------------------------------------------------------
            if gridEnabled then
                --------------------------------------------------------------------------------
                -- Basic Grid:
                --------------------------------------------------------------------------------
                if mode == "Basic Grid" then
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
                --------------------------------------------------------------------------------
                -- Draggable Guide:
                --------------------------------------------------------------------------------
                elseif mode == "Draggable Guide" then
                    local savedX, savedY
                    if guidePosition.x and guidePosition.y then
                        savedX = guidePosition.x
                        savedY = guidePosition.y
                    else
                        savedX = frame.w/2
                        savedY = frame.h/2
                    end
                    mod._canvas:appendElements({
                        id = "dragVertical",
                        action = "stroke",
                        closed = false,
                        coordinates = { { x = savedX, y = 0 }, { x = savedX, y = frame.h } },
                        strokeColor = fillColor,
                        strokeWidth = 2,
                        type = "segments",
                    })
                    mod._canvas:appendElements({
                        id = "dragHorizontal",
                        action = "stroke",
                        closed = false,
                        coordinates = { { x = 0, y = savedY }, { x = frame.w, y = savedY } },
                        strokeColor = fillColor,
                        strokeWidth = 2,
                        type = "segments",
                    })
                    mod._canvas:appendElements({
                        id = "dragCentreKill",
                        action = "fill",
                        center = { x = savedX, y = savedY },
                        radius = 8,
                        fillColor = fillColor,
                        type = "circle",
                        compositeRule = "clear",
                    })
                    mod._canvas:appendElements({
                        id = "dragCentre",
                        action = "fill",
                        center = { x = savedX, y = savedY },
                        radius = 8,
                        fillColor = fillColor,
                        type = "circle",
                        trackMouseDown = true,
                        trackMouseUp = true,
                    })
                    mod._canvas:clickActivating(false)
                    mod._canvas:canvasMouseEvents(true, true, true, true)
                    mod._canvas:mouseCallback(function(_, event, id, x, y)
                        if id == "dragCentre" and event == "mouseDown" then
                            mod._dragging = true
                        end
                        if mod._dragging and event == "mouseUp" then
                            mod._dragging = false
                            mod._canvas["dragCentre"].center = {x = x, y = y }
                            mod._canvas["dragCentreKill"].center = {x = x, y = y }
                            mod._canvas["dragVertical"].coordinates = { { x = x, y = 0 }, { x = x, y = frame.h } }
                            mod._canvas["dragHorizontal"].coordinates = { { x = 0, y = y }, { x = frame.w, y = y } }
                            mod.guidePosition({x=x, y=y})
                        end
                    end)
                end
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
        if mod.gridEnabled() or mod.activeMemory() ~= 0 then
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
            --log.df("Stopping Keyboard Monitor")
            mod._eventtap:stop()
        end
    end
end

--- plugins.finalcutpro.viewer.overlays.gridEnabled <cp.prop: boolean>
--- Variable
--- Is Viewer Grid Enabled
mod.gridEnabled = config.prop("fcpViewerGridEnabled", false)

--- plugins.finalcutpro.viewer.overlays.gridMode <cp.prop: number>
--- Variable
--- Viewer Grid Mode
mod.gridMode = config.prop("fcpViewerGridMode", DEFAULT_MODE)

--- plugins.finalcutpro.viewer.overlays.gridColor <cp.prop: string>
--- Variable
--- Viewer Grid Color as HTML value
mod.gridColor = config.prop("fcpViewerGridColor", DEFAULT_COLOR)

--- plugins.finalcutpro.viewer.overlays.gridAlpha <cp.prop: number>
--- Variable
--- Viewer Grid Alpha
mod.gridAlpha = config.prop("fcpViewerGridAlpha", DEFAULT_ALPHA)

--- plugins.finalcutpro.viewer.overlays.customGridColor <cp.prop: string>
--- Variable
--- Viewer Custom Grid Color as HTML value
mod.customGridColor = config.prop("fcpViewerCustomGridColor", nil)

--- plugins.finalcutpro.viewer.overlays.gridSpacing <cp.prop: number>
--- Variable
--- Viewer Custom Grid Color as HTML value
mod.gridSpacing = config.prop("fcpViewerGridSpacing", DEFAULT_GRID_SPACING)

--- plugins.finalcutpro.viewer.overlays.activeMemory <cp.prop: number>
--- Variable
--- Viewer Custom Grid Color as HTML value
mod.activeMemory = config.prop("fcpViewerActiveMemory", 0)

--- plugins.finalcutpro.viewer.overlays.stillsLayout <cp.prop: string>
--- Variable
--- Stills layout.
mod.stillsLayout = config.prop("fcpViewerStillsLayout", DEFAULT_STILLS_LAYOUT)

--- plugins.finalcutpro.viewer.overlays.guidePosition <cp.prop: table>
--- Variable
--- Guide Position.
mod.guidePosition = config.prop("fcpViewerGuidePosition", {})

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
    local result = false
    local ui = fcp:viewer():UI()
    if ui and ui[1] then
        local viewer = ui[1]
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
        local result = image.imageFromPath(path .. "/memory" .. id .. ".png")
        if result then
            return result
        else
            return nil
        end
    end
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
        if mod.getMemory(id) then
            mod.activeMemory(id)
        end
    end
    mod.update()
end

--- plugins.finalcutpro.viewer.overlays.setGrid(id) -> none
--- Function
--- Sets a Grid Type.
---
--- Parameters:
---  * id - The ID of the memory you want to retrieve.
---
--- Returns:
---  * None
function mod.setGrid(id)
    local gridMode = mod.gridMode()
    if gridMode == id then
        mod.gridEnabled:toggle()
    else
        if not mod.gridEnabled() then
            mod.gridEnabled(true)
        end
    end
    mod.gridMode(id)
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
    mod._eventtap = eventtap.new({eventtap.event.types.rightMouseUp}, function(event)
        local ui = fcp:viewer():UI()
        local topBar = ui and axutils.childFromTop(ui, 1)
        if topBar then
            local barFrame = topBar:attributeValue("AXFrame")
            local location = event:location() and geometry.point(event:location())
            if barFrame and location and location:inside(geometry.rect(barFrame)) then
                if mod._menu then
                    mod._menu:setMenu({
                        { title = string.upper(i18n("gridOverlay")) .. ":", disabled = true },
                        { title = "  " .. i18n("basicGrid"),        checked = mod.gridEnabled() and mod.gridMode() == "Basic Grid", fn = function() mod.setGrid("Basic Grid") end },
                        { title = "  " .. i18n("draggableGuide"),   checked = mod.gridEnabled() and mod.gridMode() == "Draggable Guide", fn = function() mod.setGrid("Draggable Guide") end },
                        --{ title = "  Rule of Thirds", checked = false },
                        { title = "-", disabled = true },
                        { title = string.upper(i18n("gridStyle")) .. ":", disabled = true },
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
                        { title = "  " .. i18n("spacing"), menu = {
                            { title = "+++++++++",      checked = mod.gridSpacing() == 5,  fn = function() mod.setGridSpacing(5) end },
                            { title = "++++++++",       checked = mod.gridSpacing() == 10, fn = function() mod.setGridSpacing(10) end },
                            { title = "+++++++",        checked = mod.gridSpacing() == 15, fn = function() mod.setGridSpacing(15) end },
                            { title = "++++++",         checked = mod.gridSpacing() == 20, fn = function() mod.setGridSpacing(20) end },
                            { title = "+++++",          checked = mod.gridSpacing() == 30, fn = function() mod.setGridSpacing(30) end },
                            { title = "++++",           checked = mod.gridSpacing() == 40, fn = function() mod.setGridSpacing(40) end },
                            { title = "+++",            checked = mod.gridSpacing() == 50, fn = function() mod.setGridSpacing(50) end },
                            { title = "++",             checked = mod.gridSpacing() == 60, fn = function() mod.setGridSpacing(60) end },
                            { title = "+",              checked = mod.gridSpacing() == 70, fn = function() mod.setGridSpacing(70) end },
                        }},
                        { title = "-", disabled = true },
                        { title = string.upper(i18n("stillFrames")) .. ":", disabled = true },
                        { title = "  " .. i18n("view"), menu = {
                            { title = i18n("memory") .. " 1", checked = mod.activeMemory() == 1, fn = function() mod.viewMemory(1) end },
                            { title = i18n("memory") .. " 2", checked = mod.activeMemory() == 2, fn = function() mod.viewMemory(2) end },
                            { title = i18n("memory") .. " 3", checked = mod.activeMemory() == 3, fn = function() mod.viewMemory(3) end },
                            { title = i18n("memory") .. " 4", checked = mod.activeMemory() == 4, fn = function() mod.viewMemory(4) end },
                            { title = i18n("memory") .. " 5", checked = mod.activeMemory() == 5, fn = function() mod.viewMemory(5) end },
                        }},
                        { title = "  " .. i18n("save"), menu = {
                            { title = i18n("memory") .. " 1", fn = function() mod.saveMemory(1) end },
                            { title = i18n("memory") .. " 2", fn = function() mod.saveMemory(2) end },
                            { title = i18n("memory") .. " 3", fn = function() mod.saveMemory(3) end },
                            { title = i18n("memory") .. " 4", fn = function() mod.saveMemory(4) end },
                            { title = i18n("memory") .. " 5", fn = function() mod.saveMemory(5) end },
                        }},
                        { title = "  " .. i18n("layout"), menu = {
                            { title = i18n("fullFrame"),  checked = mod.stillsLayout() == "Full Frame", fn = function() mod.stillsLayout("Full Frame"); mod.update() end },
                            { title = "-", disabled = true },
                            { title = i18n("leftVertical"),  checked = mod.stillsLayout() == "Left Vertical", fn = function() mod.stillsLayout("Left Vertical"); mod.update() end },
                            { title = i18n("rightVertical"), checked = mod.stillsLayout() == "Right Vertical", fn = function() mod.stillsLayout("Right Vertical"); mod.update() end },
                            { title = "-", disabled = true },
                            { title = i18n("topHorizontal"), checked = mod.stillsLayout() == "Top Horizontal", fn = function() mod.stillsLayout("Top Horizontal"); mod.update() end },
                            { title = i18n("bottomHorizontal"), checked = mod.stillsLayout() == "Bottom Horizontal", fn = function() mod.stillsLayout("Bottom Horizontal"); mod.update() end },
                        }},
                    })
                    mod._menu:popupMenu(location)
                end
            end
        end
    end)

    --------------------------------------------------------------------------------
    -- Update Canvas when Final Cut Pro is shown/hidden:
    --------------------------------------------------------------------------------
    fcp.isFrontmost:watch(mod.update)

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    if deps.fcpxCmds then
        deps.fcpxCmds
            :add("cpViewerBasicGrid")
            :whenActivated(function() mod.setGrid("Basic Grid") end)

        deps.fcpxCmds
            :add("cpViewerDraggableGuide")
            :whenActivated(function() mod.setGrid("Draggable Guide") end)

        for i=1, NUMBER_OF_MEMORIES do
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