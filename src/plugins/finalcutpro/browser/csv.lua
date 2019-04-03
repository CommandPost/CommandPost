--- === plugins.finalcutpro.browser.csv ===
---
--- Save Browser to CSV

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
    id = "finalcutpro.browser.csv",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"]    = "fcpxCmds",
    }
}

function plugin.init(deps)
    local cmds = deps.fcpxCmds

    local list = fcp:libraries():list()


    cmds:add("saveBrowserContentsToCSV")
        :whenActivated(function()
            list:show()
            if list:isShowing() then
                local result = list:contents():toCSV()
                if result then
                    local path = dialog.displayChooseFolder(i18n("selectAFolderToSaveCSV") .. ":")
                    if path then
                        tools.writeToFile(path .. "/Browser Contents.csv", result)
                    end
                    return
                end
            end
            playErrorSound()
        end)
        :titled(i18n("saveBrowserContentsToCSV"))
end

return plugin
