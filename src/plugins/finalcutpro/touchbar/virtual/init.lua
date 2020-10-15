--- === plugins.finalcutpro.touchbar.virtual ===
---
--- Virtual Touch Bar Plugin.

local require = require

local config                                    = require("cp.config")
local dialog                                    = require("cp.dialog")
local fcp                                       = require("cp.apple.finalcutpro")
local i18n                                      = require("cp.i18n")


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

-- plugins.finalcutpro.touchbar.virtual._checkVisibility(active) -> none
-- Function
-- Checks the visibility of the Virtual Touch Bar
--
-- Parameters:
--  * active - A boolean
--
-- Returns:
--  * None
function mod._checkVisibility(active)
    if mod.visibility() == mod.VISIBILITY_ALWAYS then
        mod._virtual.show()
    else
        if active then
            mod._virtual.show()
        else
            mod._virtual.hide()
        end
    end
end

-- updateStatus(enabled) -> none
-- Function
-- Update a Touch Bar Group Status
--
-- Parameters:
--  * enabled - `true` if enabled, otherwise `false`
--
-- Returns:
--  * None
local function updateStatus(enabled)
    mod._tbManager.groupStatus("fcpx", enabled)
end

--- plugins.finalcutpro.touchbar.virtual.enabled <cp.prop: boolean>
--- Field
--- Is `true` if the plugin is enabled.
mod.enabled = config.prop("displayVirtualTouchBar", false):watch(function(enabled)
    --------------------------------------------------------------------------------
    -- Check for compatibility:
    --------------------------------------------------------------------------------
    if enabled and not mod._virtual.supported() then
        dialog.displayMessage(i18n("touchBarError"))
        mod.enabled(false)
    end
    if enabled then

        --------------------------------------------------------------------------------
        -- Add Callbacks to Control Location:
        --------------------------------------------------------------------------------
        mod.updateLocationCallback = mod._virtual.updateLocationCallback:new("fcp", function()

            local displayVirtualTouchBarLocation = mod._virtual.location()

            --------------------------------------------------------------------------------
            -- Show Touch Bar at Top Centre of Timeline:
            --------------------------------------------------------------------------------
            local timeline = fcp.timeline
            if timeline and displayVirtualTouchBarLocation == mod.LOCATION_TIMELINE and timeline:isShowing() then
                --------------------------------------------------------------------------------
                -- Position Touch Bar to Top Centre of Final Cut Pro Timeline:
                --------------------------------------------------------------------------------
                local viewFrame = timeline.contents:viewFrame()
                if viewFrame then
                    if mod._virtual._touchBar then
                        local topLeft = {x = viewFrame.x + viewFrame.w/2 - mod._virtual._touchBar:getFrame().w/2, y = viewFrame.y + 20}
                        mod._virtual._touchBar:topLeft(topLeft)
                    end
                end
            elseif displayVirtualTouchBarLocation == mod._virtual.LOCATION_MOUSE then

                --------------------------------------------------------------------------------
                -- Position Touch Bar to Mouse Pointer Location:
                --------------------------------------------------------------------------------
                if mod._virtual._touchBar then
                    mod._virtual._touchBar:atMousePosition()
                end

            end
        end)

        --------------------------------------------------------------------------------
        -- Update Touch Bar Buttons when FCPX is active:
        --------------------------------------------------------------------------------
        fcp.app.frontmost:watch(updateStatus)
        fcp.app.showing:watch(updateStatus)

        --------------------------------------------------------------------------------
        -- Disable/Enable the Touchbar when the Command Editor/etc is open:
        --------------------------------------------------------------------------------
        mod.isActive = fcp.isFrontmost:AND(fcp.isModalDialogOpen:NOT())
        :bind(mod, "isActive")
        :watch(mod._checkVisibility)

        --------------------------------------------------------------------------------
        -- Update the Virtual Touch Bar position if either of the main windows move:
        --------------------------------------------------------------------------------
        fcp.primaryWindow.frame:watch(mod._virtual.updateLocation)
        fcp.secondaryWindow.frame:watch(mod._virtual.updateLocation)

        --------------------------------------------------------------------------------
        -- Start the Virtual Touch Bar:
        --------------------------------------------------------------------------------
        mod._virtual.start()

        --------------------------------------------------------------------------------
        -- Update the visibility:
        --------------------------------------------------------------------------------
        if mod.visibility() == mod.VISIBILITY_ALWAYS then
            mod._virtual.show()
        else
            if fcp.isFrontmost() then
                mod._virtual.show()
            else
                mod._virtual.hide()
            end
        end

    else
        --------------------------------------------------------------------------------
        -- Destroy Watchers:
        --------------------------------------------------------------------------------
        fcp.app.frontmost:unwatch(updateStatus)
        fcp.app.showing:unwatch(updateStatus)

        if mod.isActive then
            mod.isActive:unwatch(mod._checkVisibility)
            mod.isActive = nil
        end
        if mod._fcpPrimaryWindowWatcher then
            mod._fcpPrimaryWindowWatcher:unwatch(mod._virtual.updateLocation)
            mod._fcpPrimaryWindowWatcher = nil
        end
        if mod._fcpSecondaryWindowWatcher then
            fcp.secondaryWindow.frame:unwatch(mod._virtual.updateLocation)
            mod._fcpSecondaryWindowWatcher = nil
        end
        if mod.updateLocationCallback then
            mod.updateLocationCallback:delete()
            mod.updateLocationCallback = nil
        end

        --------------------------------------------------------------------------------
        -- Stop the Virtual Touch Bar:
        --------------------------------------------------------------------------------
        mod._virtual.stop()
    end
end)

local plugin = {
    id = "finalcutpro.touchbar.virtual",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"]        = "fcpxCmds",
        ["core.touchbar.virtual"]       = "manager",
        ["core.touchbar.manager"]       = "tbManager",
        ["core.commands.global"]        = "global",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Connect to Manager:
    --------------------------------------------------------------------------------
    mod._virtual = deps.manager
    mod._tbManager = deps.tbManager

    --------------------------------------------------------------------------------
    -- Add Commands if Supported:
    --------------------------------------------------------------------------------
    if mod._virtual.supported() then
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

function plugin.postInit()
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Update visibility:
    --------------------------------------------------------------------------------
    mod.enabled:update()
end

return plugin
