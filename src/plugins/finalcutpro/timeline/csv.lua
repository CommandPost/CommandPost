--- === plugins.finalcutpro.timeline.csv ===
---
--- Save Timeline Index to CSV

local require           = require

--local log				= require "hs.logger".new "index"

local fcp               = require "cp.apple.finalcutpro"
local i18n              = require "cp.i18n"
local tools             = require "cp.tools"
local dialog            = require "cp.dialog"

local playErrorSound    = tools.playErrorSound

local plugin = {
    id = "finalcutpro.timeline.csv",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"]    = "fcpxCmds",
        ["finalcutpro.menu.manager"] = "menuManager",
    }
}

function plugin.init(deps)
    local cmds = deps.fcpxCmds

    local timeline = fcp.timeline
    local index = timeline:index()

    local saveTimelineIndexToCSV = function()
        fcp:launch(5)
        timeline:show()
        if not timeline.toolbar:index():checked() then
            timeline.toolbar:index():press()
        end
        if index:isShowing() then
            local activeTab = index:activeTab()
            local list = activeTab and activeTab:list()
            if list and not index:roles():isShowing() then
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
        playErrorSound()
    end

    --------------------------------------------------------------------------------
    -- Command:
    --------------------------------------------------------------------------------
    cmds:add("saveTimelineIndexToCSV")
        :whenActivated(saveTimelineIndexToCSV)
        :titled(i18n("saveTimelineIndexToCSV"))

    --------------------------------------------------------------------------------
    -- Menubar:
    --------------------------------------------------------------------------------
    local menu = deps.menuManager.timeline
    menu
        :addItems(1001, function()
            return {
                {   title = i18n("saveTimelineIndexToCSV"),
                    fn = saveTimelineIndexToCSV,
                },
            }
        end)


end

return plugin
