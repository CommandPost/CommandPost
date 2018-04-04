--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.tangent.commandpost.favourites ===
---
--- Tangent Favourites.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                                       = require("hs.logger").new("tanFav")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local dialog                                    = require("cp.dialog")
local inspect                                   = require("hs.inspect")

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "core.tangent.commandpost.favourites",
    group = "core",
    dependencies = {
        ["core.tangent.commandpost"]    = "cpGroup",
        ["core.tangent.prefs"]          = "prefs",
        ["core.action.manager"]         = "actionManager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    local prefs = deps.prefs
    local cpGroup = deps.cpGroup
    local actionManager = deps.actionManager

    local max = prefs.MAX_ITEMS
    local group = cpGroup:group(i18n("favourites"))

    local id = 0x0F100000
    for i = 1, max do
        group:action(id, i18n("favourite") .. " #" .. i)
            :onPress(function()
                local favourites = prefs.favourites
                if favourites and favourites[tostring(i)] then

                    local favourite = favourites[tostring(i)]

                    local handlerID = favourite.handlerID
                    local action = favourite.action

                    if handlerID and action then
                        local handler = actionManager.getHandler(handlerID)
                        handler:execute(action)
                    else
                        log.ef("Invalid handlerID or Action: %s, %s", handlerID, inspect(action))
                    end
                else
                    dialog.displayMessage(i18n("missingTangentAction"))
                end
            end)

        id = id + 1
    end

    return group

end

return plugin