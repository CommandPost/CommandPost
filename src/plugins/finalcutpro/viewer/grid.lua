--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.viewer.grid ===
---
--- Final Cut Pro Viewer Grid

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log               = require("hs.logger").new("grid")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils           = require("cp.ui.axutils")
local config            = require("cp.config")
local fcp               = require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local canvas            = require("hs.canvas")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.viewer.grid.show() -> none
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
    if ui and ui[1] then
        local frame = ui[1]:attributeValue("AXFrame")
        if frame then
            --------------------------------------------------------------------------------
            -- New Canvas:
            --------------------------------------------------------------------------------
            mod._canvas = canvas.new(frame)

            -- Blue: #5760e7
            -- Red: #d1393e
            -- Green: #3f9253

            --------------------------------------------------------------------------------
            -- MODE 1: Basic Grid.
            --------------------------------------------------------------------------------
            if mod.mode() == 1 then
                --------------------------------------------------------------------------------
                -- Add Vertical Lines:
                --------------------------------------------------------------------------------
                local distance = 0
                local increment = 30
                for _=1, frame.w/2 do
                    mod._canvas:appendElements({
                        type = "rectangle",
                        frame = { x = distance, y = 0, h = frame.h, w = 1},
                        fillColor = { white = 1, alpha = 1/2 },
                        action = "fill",
                    })
                    distance = distance + increment
                end

                --------------------------------------------------------------------------------
                -- Add Horizontal Lines:
                --------------------------------------------------------------------------------
                distance = 0
                for _=1, frame.h/2 do
                    mod._canvas:appendElements({
                        type = "rectangle",
                        frame = { x = 0, y = distance, h = 1, w = frame.w},
                        fillColor = { white = 1, alpha = 1/2 },
                        action = "fill",
                    })
                    distance = distance + increment
                end

                --------------------------------------------------------------------------------
                -- Add Border:
                --------------------------------------------------------------------------------
                mod._canvas:appendElements({
                    id               = "border",
                    type             = "rectangle",
                    action           = "stroke",
                    strokeColor      = { hex = "#5760e7" },
                    strokeWidth      = 5,
                })
            end

            --------------------------------------------------------------------------------
            -- Show the Canvas:
            --------------------------------------------------------------------------------
            mod._canvas:show()
        end
    end
end

--- plugins.finalcutpro.viewer.grid.hide() -> none
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
    end
end

--- plugins.finalcutpro.viewer.grid.update() -> none
--- Function
--- Updates the Viewer Grid.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.update()
    if mod.enabled() and fcp.isFrontmost() and fcp:viewer():isShowing() then
        mod.show()
    else
        mod.hide()
    end
end

--- plugins.finalcutpro.viewer.grid.enabled <cp.prop: boolean>
--- Variable
--- Is Viewer Grid Enabled
mod.enabled = config.prop("fcpViewerGridEnabled", true):watch(mod.update)

--- plugins.finalcutpro.viewer.grid.mode <cp.prop: number>
--- Variable
--- Viewer Grid Mode
mod.mode = config.prop("fcpViewerGridMode", 1)

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.viewer.grid",
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
    -- Update Canvas when Final Cut Pro is shown/hidden:
    --------------------------------------------------------------------------------
    fcp.isFrontmost:watch(mod.update)

    --------------------------------------------------------------------------------
    -- Update the Canvas on initial boot:
    --------------------------------------------------------------------------------
    mod.update()

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    if deps.fcpxCmds then
        deps.fcpxCmds
            :add("cpViewerGrid")
            :whenActivated(function() mod.enabled:toggle() end)
    end

    return mod
end

return plugin