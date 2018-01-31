--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--               V I R T U A L   T O U C H B A R     P L U G I N              --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.touchbar.virtual ===
---
--- Virtual Touch Bar Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                                       = require("hs.logger").new("virtualTouchBar")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config                                    = require("cp.config")
local dialog                                    = require("cp.dialog")
local fcp                                       = require("cp.apple.finalcutpro")
local prop                                      = require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.touchbar.virtual.VISIBILITY_ALWAYS -> string
--- Constant
--- Virtual Touch Bar is always displayed.
mod.VISIBILITY_ALWAYS = "Always"

--- plugins.finalcutpro.touchbar.virtual.VISIBILITY_FCP -> string
--- Constant
--- Virtual Touch Bar is displayed at top centre of the Final Cut Pro Timeline.
mod.VISIBILITY_FCP = "Final Cut Pro"

--- plugins.finalcutpro.touchbar.virtual.LOCATION_TIMELINE -> string
--- Constant
--- Virtual Touch Bar is displayed at top centre of the Final Cut Pro Timeline.
mod.LOCATION_TIMELINE = "TimelineTopCentre"

--- plugins.finalcutpro.touchbar.virtual.visibility <cp.prop: string>
--- Field
--- When should the Virtual Touch Bar be visible?
mod.visibility = config.prop("virtualTouchBarVisibility", mod.VISIBILITY_FCP)

function mod._checkVisibility(active)
    if mod.visibility() == mod.VISIBILITY_ALWAYS then
        mod._manager.virtual.show()
    else
        if active then
            mod._manager.virtual.show()
        else
            mod._manager.virtual.hide()
        end
    end
end

--- plugins.finalcutpro.touchbar.virtual.enabled <cp.prop: boolean>
--- Field
--- Is `true` if the plugin is enabled.
mod.enabled = config.prop("displayVirtualTouchBar", false):watch(function(enabled)
    --------------------------------------------------------------------------------
    -- Check for compatibility:
    --------------------------------------------------------------------------------
    if enabled and not mod._manager.supported() then
        dialog.displayMessage(i18n("touchBarError"))
        mod.enabled(false)
    end
    if enabled then

        --------------------------------------------------------------------------------
        -- Add Callbacks to Control Location:
        --------------------------------------------------------------------------------
        mod.updateLocationCallback = mod._manager.virtual.updateLocationCallback:new("fcp", function()

            local displayVirtualTouchBarLocation = mod._manager.virtual.location()

            --------------------------------------------------------------------------------
            -- Show Touch Bar at Top Centre of Timeline:
            --------------------------------------------------------------------------------
            local timeline = fcp:timeline()
            if timeline and displayVirtualTouchBarLocation == mod.LOCATION_TIMELINE and timeline:isShowing() then
                --------------------------------------------------------------------------------
                -- Position Touch Bar to Top Centre of Final Cut Pro Timeline:
                --------------------------------------------------------------------------------
                local viewFrame = timeline:contents():viewFrame()
                if viewFrame then
                    local topLeft = {x = viewFrame.x + viewFrame.w/2 - mod._manager.touchBar():getFrame().w/2, y = viewFrame.y + 20}
                    mod._manager.touchBar():topLeft(topLeft)
                end
            elseif displayVirtualTouchBarLocation == mod._manager.virtual.LOCATION_MOUSE then

                --------------------------------------------------------------------------------
                -- Position Touch Bar to Mouse Pointer Location:
                --------------------------------------------------------------------------------
                mod._manager.touchBar():atMousePosition()

            end
        end)

        --------------------------------------------------------------------------------
        -- Update Touch Bar Buttons when FCPX is active:
        --------------------------------------------------------------------------------
        mod._fcpWatchID = fcp:watch({
            active      = function() mod._manager.groupStatus("fcpx", true) end,
            show        = function() mod._manager.groupStatus("fcpx", true) end,
            inactive    = function() mod._manager.groupStatus("fcpx", false) end,
            hide        = function() mod._manager.groupStatus("fcpx", false) end,
        })

        --------------------------------------------------------------------------------
        -- Disable/Enable the Touchbar when the Command Editor/etc is open:
        --------------------------------------------------------------------------------
        fcp.isFrontmost:AND(fcp.isModalDialogOpen:NOT()):watch(mod._checkVisibility)

        --------------------------------------------------------------------------------
        -- Update the Virtual Touch Bar position if either of the main windows move:
        --------------------------------------------------------------------------------
        fcp:primaryWindow().frame:watch(mod._manager.virtual.updateLocation)
        fcp:secondaryWindow().frame:watch(mod._manager.virtual.updateLocation)

        --------------------------------------------------------------------------------
        -- Start the Virtual Touch Bar:
        --------------------------------------------------------------------------------
        mod._manager.virtual.start()

        --------------------------------------------------------------------------------
        -- Update the visibility:
        --------------------------------------------------------------------------------
        if mod.visibility() == mod.VISIBILITY_ALWAYS then
            mod._manager.virtual.show()
        else
            if fcp.isFrontmost() then
                mod._manager.virtual.show()
            else
                mod._manager.virtual.hide()
            end
        end

    else
        --------------------------------------------------------------------------------
        -- Destroy Watchers:
        --------------------------------------------------------------------------------
        if mod._fcpWatchID and mod._fcpWatchID.id then
            fcp:unwatch(mod._fcpWatchID.id)
            mod._fcpWatchID = nil
        end
        fcp.isFrontmost:AND(fcp.isModalDialogOpen:NOT()):unwatch(mod._checkVisibility)
        fcp:primaryWindow().frame:unwatch(mod._manager.virtual.updateLocation)
        fcp:secondaryWindow().frame:unwatch(mod._manager.virtual.updateLocation)
        if mod.updateLocationCallback then
            mod.updateLocationCallback:delete()
            mod.updateLocationCallback = nil
        end

        --------------------------------------------------------------------------------
        -- Stop the Virtual Touch Bar:
        --------------------------------------------------------------------------------
        mod._manager.virtual.stop()
    end
end)

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.touchbar.virtual",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"]        = "fcpxCmds",
        ["core.touchbar.manager"]       = "manager",
        ["core.commands.global"]        = "global",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Connect to Manager:
    --------------------------------------------------------------------------------
    mod._manager = deps.manager

    --------------------------------------------------------------------------------
    -- Add Commands if Supported:
    --------------------------------------------------------------------------------
    if mod._manager.supported() then
        --------------------------------------------------------------------------------
        -- Final Cut Pro Command:
        --------------------------------------------------------------------------------
        deps.fcpxCmds
            :add("cpToggleTouchBar")
            :activatedBy():ctrl():option():cmd("z")
            :whenActivated(function() mod.enabled:toggle() end)
            :groupedBy("commandPost")

        --------------------------------------------------------------------------------
        -- Global Command:
        --------------------------------------------------------------------------------
        deps.global
            :add("cpGlobalToggleTouchBar")
            :whenActivated(function() mod.enabled:toggle() end)
            :groupedBy("commandPost")
    end
    return mod
end

--------------------------------------------------------------------------------
-- POST INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.postInit()
    --------------------------------------------------------------------------------
    -- Update visibility:
    --------------------------------------------------------------------------------
    mod.enabled:update()
end

return plugin