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

local mod = {}

--- plugins.finalcutpro.browser.csv.saveBrowserContentsToCSV() -> none
--- Function
--- Save Browser Contents to CSV
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.saveBrowserContentsToCSV()
    local list = fcp.libraries.list
    fcp:launch(5)
    list:show()
    if list:isShowing() then
        local result = list.contents:toCSV()
        if result then
            local path = dialog.displayChooseFolder(i18n("selectAFolderToSaveCSV") .. ":")
            if path then
                tools.writeToFile(path .. "/Browser Contents.csv", result)
            end
            return
        end
    end
    playErrorSound()
end

local plugin = {
    id = "finalcutpro.browser.csv",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"]    = "fcpxCmds",
        ["finalcutpro.menu.manager"] = "menuManager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if FCPX is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Command:
    --------------------------------------------------------------------------------
    local cmds = deps.fcpxCmds
    cmds:add("saveBrowserContentsToCSV")
        :whenActivated(mod.saveBrowserContentsToCSV)
        :titled(i18n("saveBrowserContentsToCSV"))

    --------------------------------------------------------------------------------
    -- Menubar:
    --------------------------------------------------------------------------------
    local menu = deps.menuManager.browser
    menu
        :addItems(1001, function()
            return {
                {   title = i18n("saveBrowserContentsToCSV"),
                    fn = mod.saveBrowserContentsToCSV,
                },
            }
        end)

    return mod
end

return plugin
