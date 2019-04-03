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

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.timeline.csv",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"]    = "fcpxCmds",
    }
}

function plugin.init(deps)
    local cmds = deps.fcpxCmds

    local timeline = fcp:timeline()
    local index = timeline:index()

    cmds:add("saveTimelineIndexToCSV")
        :whenActivated(function()
            if not timeline:toolbar():index():checked() then
                timeline:toolbar():index():press()
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
        end)
        :titled(i18n("saveTimelineIndexToCSV"))
end

return plugin
