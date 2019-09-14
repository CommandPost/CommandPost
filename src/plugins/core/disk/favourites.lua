--- === plugins.core.disk.favourites ===
---
--- Action that allows you save and open user-defined favourite folders.

local require = require

--local log                   = require "hs.logger".new "favourites"

local config                = require "cp.config"
local dialog                = require "cp.dialog"
local i18n                  = require "cp.i18n"

local displayChooseFolder   = dialog.displayChooseFolder
local displayMessage        = dialog.displayMessage

local plugin = {
    id = "core.disk.favourites",
    group = "core",
    dependencies = {
        ["core.commands.global"] = "global",
    }
}

function plugin.init(deps)
    local cmds = deps.global
    for i=1, 5 do
        --------------------------------------------------------------------------------
        -- Save Favourite Folder:
        --------------------------------------------------------------------------------
        cmds
            :add("saveFavouriteFolder" .. i)
            :whenActivated(function()
                local path = displayChooseFolder(i18n("pleasePickAFolderToUseAsAFavourite") .. ":")
                if path then
                    config.set("favouriteFolderPath." .. i, path)
                end
            end)
            :titled(i18n("saveFavouriteFolder") .. " " .. i)

        --------------------------------------------------------------------------------
        -- Open Favourite Folder:
        --------------------------------------------------------------------------------
        cmds
            :add("openFavouriteFolder" .. i)
            :whenActivated(function()
                local path = config.get("favouriteFolderPath." .. i)
                if path then
                    os.execute('open "' .. path .. '"')
                else
                    displayMessage(i18n("favouriteFolderError"))
                end
            end)
            :titled(i18n("openFavouriteFolder") .. " " .. i)
    end
end

return plugin
