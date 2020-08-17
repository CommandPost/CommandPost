--- === plugins.finalcutpro.import.preferences ===
---
--- Import Preferences

local require       = require

local fcp           = require "cp.apple.finalcutpro"
local dialog        = require "cp.dialog"
local i18n          = require "cp.i18n"

local mod = {}

--- plugins.finalcutpro.import.preferences.createOptimizedMedia <cp.prop: boolean>
--- Variable
--- Create Optimised Media
mod.createOptimizedMedia = fcp.preferences:prop("FFImportCreateOptimizeMedia", false):mutate(
    --------------------------------------------------------------------------------
    -- Getter:
    --------------------------------------------------------------------------------
    function(original) return original() end,
    --------------------------------------------------------------------------------
    -- Setter:
    --------------------------------------------------------------------------------
    function(newValue, original)
        local currentValue = original()
        if currentValue ~= newValue then
            if fcp:isRunning() then
                --------------------------------------------------------------------------------
                -- We have to go via the Preferences window...
                -- Make sure it's active:
                --------------------------------------------------------------------------------
                fcp:launch()

                --------------------------------------------------------------------------------
                -- Toggle the checkbox:
                --------------------------------------------------------------------------------
                local panel = fcp.preferencesWindow.importPanel
                if panel:show():isShowing() then
                    panel.createOptimizedMedia:toggle()
                else
                    dialog.displayErrorMessage("Failed to toggle 'Create Optimized Media'.\n\nError occurred in createOptimizedMedia().")
                end

                --------------------------------------------------------------------------------
                -- Close the Preferences window:
                --------------------------------------------------------------------------------
                panel:hide()
            else
                original(newValue)
            end
        end
    end
)

--- plugins.finalcutpro.import.preferences.createMulticamOptimizedMedia <cp.prop: boolean>
--- Variable
--- Create Multicam Optimised Media
mod.createMulticamOptimizedMedia = fcp.preferences:prop("FFCreateOptimizedMediaForMulticamClips", true):mutate(
    --------------------------------------------------------------------------------
    -- Getter:
    --------------------------------------------------------------------------------
    function(original) return original() end,
    --------------------------------------------------------------------------------
    -- Setter:
    --------------------------------------------------------------------------------
    function(newValue, original)
        local currentValue = original()
        if newValue ~= currentValue then
            if fcp:isRunning() then
                --------------------------------------------------------------------------------
                -- We have to go via the Preferences window...
                -- Make sure it's active:
                --------------------------------------------------------------------------------
                fcp:launch()

                --------------------------------------------------------------------------------
                -- Toggle the checkbox:
                --------------------------------------------------------------------------------
                local panel = fcp.preferencesWindow.playbackPanel
                if panel:show() then
                    panel.createMulticamOptimizedMedia:toggle()
                else
                    dialog.displayErrorMessage("Failed to toggle 'Create Multicam Optimized Media'.\n\nError occurred in createMulticamOptimizedMedia().")
                end

                --------------------------------------------------------------------------------
                -- Close the Preferences window:
                --------------------------------------------------------------------------------
                panel:hide()
            else
                original(newValue)
            end
        end
    end
)

--- plugins.finalcutpro.import.preferences.createProxyMedia <cp.prop: boolean>
--- Variable
--- Create Proxy Media
mod.createProxyMedia = fcp.preferences:prop("FFImportCreateProxyMedia", false):mutate(
    --------------------------------------------------------------------------------
    -- Getter:
    --------------------------------------------------------------------------------
    function(original) return original() end,
    --------------------------------------------------------------------------------
    -- Setter:
    --------------------------------------------------------------------------------
    function(newValue, original)
        local currentValue = original()
        if currentValue ~= newValue then
            if fcp:isRunning() then
                --------------------------------------------------------------------------------
                -- Make sure it's active:
                --------------------------------------------------------------------------------
                fcp:launch()

                --------------------------------------------------------------------------------
                -- Toggle the checkbox:
                --------------------------------------------------------------------------------
                local panel = fcp.preferencesWindow.importPanel
                if panel:show():isShowing() then
                    panel:createProxyMedia():toggle()
                else
                    dialog.displayErrorMessage("Failed to toggle 'Create Proxy Media'.\n\nError occurred in createProxyMedia().")
                end

                --------------------------------------------------------------------------------
                -- Close the Preferences window:
                --------------------------------------------------------------------------------
                panel:hide()
            else
                original(newValue)
            end
        end
    end
)

--- plugins.finalcutpro.import.preferences.leaveInPlace <cp.prop: boolean>
--- Variable
--- Leave In Place.
mod.leaveInPlace = fcp.preferences:prop("FFImportCopyToMediaFolder", true):mutate(
    --------------------------------------------------------------------------------
    -- Getter:
    --------------------------------------------------------------------------------
    function(original) return not original() end,
    --------------------------------------------------------------------------------
    -- Setter:
    --------------------------------------------------------------------------------
    function(newValue, original)
        local currentValue = not original()
        if newValue ~= currentValue then
            if fcp:isRunning() then
                --------------------------------------------------------------------------------
                -- Make sure it's active:
                --------------------------------------------------------------------------------
                fcp:launch()

                --------------------------------------------------------------------------------
                -- Define FCPX:
                --------------------------------------------------------------------------------
                local prefs = fcp.preferencesWindow

                --------------------------------------------------------------------------------
                -- Toggle the checkbox:
                --------------------------------------------------------------------------------
                if not prefs.importPanel:toggleMediaLocation() then
                    dialog.displayErrorMessage("Failed to toggle 'Copy To Media Folder'.\n\nError occurred in leaveInPlace().")
                    return "Failed"
                end

                --------------------------------------------------------------------------------
                -- Close the Preferences window:
                --------------------------------------------------------------------------------
                prefs:hide()
            else
                original(newValue)
            end
        end
    end
)

local plugin = {
    id              = "finalcutpro.import.preferences",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.menu.manager"]        = "menu",
        ["finalcutpro.commands"]            = "fcpxCmds",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Menus:
    --------------------------------------------------------------------------------
    deps.menu.mediaImport
        :addItems(1000, function()
            local fcpxRunning = fcp:isRunning()
            return {
                { title = i18n("createOptimizedMedia"),         fn = function() mod.createOptimizedMedia:toggle() end,              checked = mod.createOptimizedMedia(),               disabled = not fcpxRunning },
                { title = i18n("createMulticamOptimizedMedia"), fn = function() mod.createMulticamOptimizedMedia:toggle() end,      checked = mod.createMulticamOptimizedMedia(),       disabled = not fcpxRunning },
                { title = i18n("createProxyMedia"),             fn = function() mod.createProxyMedia:toggle() end,                  checked = mod.createProxyMedia(),                   disabled = not fcpxRunning },
                { title = i18n("leaveFilesInPlaceOnImport"),    fn = function() mod.leaveInPlace:toggle() end,                      checked = mod.leaveInPlace(),                       disabled = not fcpxRunning },
            }
        end)

    --------------------------------------------------------------------------------
    -- Commands:
    --------------------------------------------------------------------------------
    local fcpxCmds = deps.fcpxCmds
    fcpxCmds
        :add("cpCreateOptimizedMediaOn")
        :groupedBy("mediaImport")
        :whenActivated(function() mod.createOptimizedMedia(true) end)

    fcpxCmds
        :add("cpCreateOptimizedMediaOff")
        :groupedBy("mediaImport")
        :whenActivated(function() mod.createOptimizedMedia(false) end)

    fcpxCmds
        :add("cpCreateMulticamOptimizedMediaOn")
        :groupedBy("mediaImport")
        :whenActivated(function() mod.createMulticamOptimizedMedia(true) end)

    fcpxCmds
        :add("cpCreateMulticamOptimizedMediaOff")
        :groupedBy("mediaImport")
        :whenActivated(function() mod.createMulticamOptimizedMedia(false) end)

    fcpxCmds
        :add("cpCreateProxyMediaOn")
        :groupedBy("mediaImport")
        :whenActivated(function() mod.createProxyMedia(true) end)

    fcpxCmds
        :add("cpCreateProxyMediaOff")
        :groupedBy("mediaImport")
        :whenActivated(function() mod.createProxyMedia(false) end)

    fcpxCmds
        :add("cpLeaveInPlaceOn")
        :groupedBy("mediaImport")
        :whenActivated(function() mod.leaveInPlace(true) end)

    fcpxCmds:add("cpLeaveInPlaceOff")
        :groupedBy("mediaImport")
        :whenActivated(function() mod.leaveInPlace(false) end)

    return mod
end

return plugin
