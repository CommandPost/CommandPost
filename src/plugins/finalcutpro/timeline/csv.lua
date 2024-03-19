--- === plugins.finalcutpro.timeline.csv ===
---
--- Save Timeline Index to CSV

local require           = require

local log				= require "hs.logger".new "index"

local fcp               = require "cp.apple.finalcutpro"
local i18n              = require "cp.i18n"
local tools             = require "cp.tools"
local dialog            = require "cp.dialog"

local playErrorSound    = tools.playErrorSound


local mod = {}

--- plugins.finalcutpro.timeline.csv.saveTimelineIndexToCSV() -> none
--- Function
--- Save Timeline Index to CSV
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.saveTimelineIndexToCSV()
    local timeline = fcp.timeline
    local index = timeline.index

    fcp:launch(5)
    timeline:show()
    if not timeline.toolbar.index:checked() then
        timeline.toolbar.index:press()
    end
    if index:isShowing() then
        local activeTab = index:activeTab()
        local list = activeTab and activeTab.list
        if list and not index.roles:isShowing() then
            local result = list:toCSV()
            if result then
                local path = dialog.displayChooseFolder(i18n("selectAFolderToSaveCSV") .. ":")
                if path then
                    tools.writeToFile(path .. "/Timeline Index.csv", result)
                end
                return
            end
        end
    end
    log.ef("Failed to show the Timeline Index or get its contents when saving to a CSV.")
    playErrorSound()
end

local plugin = {
    id = "finalcutpro.timeline.csv",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"]    = "fcpxCmds",
        ["finalcutpro.menu.manager"] = "menuManager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Command:
    --------------------------------------------------------------------------------
    local cmds = deps.fcpxCmds
    cmds:add("saveTimelineIndexToCSV")
        :whenActivated(mod.saveTimelineIndexToCSV)
        :titled(i18n("saveTimelineIndexToCSV"))

    --------------------------------------------------------------------------------
    -- Menubar:
    --------------------------------------------------------------------------------
    local menu = deps.menuManager.timeline
    menu
        :addItems(1001, function()
            return {
                {   title = i18n("saveTimelineIndexToCSV"),
                    fn = mod.saveTimelineIndexToCSV,
                },
            }
        end)

    return mod
end

return plugin
