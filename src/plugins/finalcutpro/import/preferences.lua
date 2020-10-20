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
mod.createOptimizedMedia = fcp.preferences:prop("FFImportCreateOptimizeMedia", false)

--- plugins.finalcutpro.import.preferences.createMulticamOptimizedMedia <cp.prop: boolean>
--- Variable
--- Create Multicam Optimised Media
mod.createMulticamOptimizedMedia = fcp.preferences:prop("FFCreateOptimizedMediaForMulticamClips", true)

--- plugins.finalcutpro.import.preferences.createProxyMedia <cp.prop: boolean>
--- Variable
--- Create Proxy Media
mod.createProxyMedia = fcp.preferences:prop("FFImportCreateProxyMedia", false)

--- plugins.finalcutpro.import.preferences.leaveInPlace <cp.prop: boolean>
--- Variable
--- Leave In Place.
mod.leaveInPlace = fcp.preferences:prop("FFImportCopyToMediaFolder", true)

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
    -- Only load plugin if FCPX is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Menus:
    --------------------------------------------------------------------------------
    deps.menu.mediaImport
        :addItems(1000, function()
            local fcpxRunning = fcp:isRunning()
            return {
                { title = i18n("createOptimizedMedia"),         fn = function() mod.createOptimizedMedia:toggle() end,              checked = mod.createOptimizedMedia(),               },
                { title = i18n("createMulticamOptimizedMedia"), fn = function() mod.createMulticamOptimizedMedia:toggle() end,      checked = mod.createMulticamOptimizedMedia(),       },
                { title = i18n("createProxyMedia"),             fn = function() mod.createProxyMedia:toggle() end,                  checked = mod.createProxyMedia(),                   },
                { title = i18n("leaveFilesInPlaceOnImport"),    fn = function() mod.leaveInPlace:toggle() end,                      checked = not mod.leaveInPlace(),                       },
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
        :whenActivated(function() mod.leaveInPlace(false) end)

    fcpxCmds:add("cpLeaveInPlaceOff")
        :groupedBy("mediaImport")
        :whenActivated(function() mod.leaveInPlace(true) end)

    return mod
end

return plugin
