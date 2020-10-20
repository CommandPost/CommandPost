--- === plugins.core.console.scripts ===
---
--- Adds all installed AppleScripts to the Search Console.

local require               = require

local hs                    = _G.hs

local log				    = require "hs.logger".new "applications"

local image                 = require "hs.image"
local fs                    = require "hs.fs"

local config                = require "cp.config"
local spotlight             = require "hs.spotlight"

local displayName           = fs.displayName
local execute               = hs.execute
local imageFromPath         = image.imageFromPath

local mod = {}

mod.appCache = {}

local function modifyNameMap(info, add)
    for _, item in ipairs(info) do
        local displayname = item.kMDItemDisplayName or displayName(item.kMDItemPath)

        --------------------------------------------------------------------------------
        -- Add to the cache:
        --------------------------------------------------------------------------------
        if add then
            --------------------------------------------------------------------------------
            -- AppleScript Icon:
            --------------------------------------------------------------------------------
            local icon = imageFromPath(config.bundledPluginsPath .. "/core/console/images/SEScriptDocument.icns")

            --------------------------------------------------------------------------------
            -- Add application to cache:
            --------------------------------------------------------------------------------
            mod.appCache[displayname] = {
                path = item.kMDItemPath,
                icon = icon
            }
        --------------------------------------------------------------------------------
        -- Remove from the cache:
        --------------------------------------------------------------------------------
        else
            mod.appCache[displayname] = nil
        end
    end

    mod._handler:reset()
end

local function updateNameMap(_, msg, info)
    if info then
        --------------------------------------------------------------------------------
        -- All three can occur in either message, so check them all:
        --------------------------------------------------------------------------------
        if info.kMDQueryUpdateAddedItems   then modifyNameMap(info.kMDQueryUpdateAddedItems,   true)  end
        if info.kMDQueryUpdateChangedItems then modifyNameMap(info.kMDQueryUpdateChangedItems, true)  end
        if info.kMDQueryUpdateRemovedItems then modifyNameMap(info.kMDQueryUpdateRemovedItems, false) end
   else
        --------------------------------------------------------------------------------
        -- This shouldn't happen for didUpdate or inProgress:
        --------------------------------------------------------------------------------
        log.df("userInfo from SpotLight was empty for " .. msg)
   end
end

function mod.startSpotlightSearch()
    local searchPaths = {
       "/Applications",
       "/System/Applications",
       "~/Applications",
       "/Developer/Applications",
       "/Applications/Xcode.app/Contents/Applications",
       "/System/Library/PreferencePanes",
       "/Library/PreferencePanes",
       "~/Library/PreferencePanes",
       "/System/Library/CoreServices/Applications",
       "/System/Library/CoreServices/",
       "/usr/local/Cellar",
       "/Library/Scripts",
       "~/Library/Scripts"
    }

    mod.spotlight = spotlight.new():queryString([[ (kMDItemContentType = "com.apple.applescript.text")  || (kMDItemContentType = "com.apple.applescript.script") ]])
       :callbackMessages("didUpdate", "inProgress")
       :setCallback(updateNameMap)
       :searchScopes(searchPaths)
       :start()
end

local plugin = {
    id = "core.console.scripts",
    group = "core",
    dependencies = {
        ["core.action.manager"] = "actionmanager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Start Spotlight Search:
    --------------------------------------------------------------------------------
    mod.startSpotlightSearch()

    --------------------------------------------------------------------------------
    -- Setup Handler:
    --------------------------------------------------------------------------------
    mod._handler = deps.actionmanager.addHandler("global_scripts", "global")
        :onChoices(function(choices)
            for name, app in pairs(mod.appCache) do
                choices:add(name)
                    :subText(app["path"])
                    :params({
                        ["path"] = app["path"],
                    })
                    :image(app["icon"])
                    :id("global_applications_" .. name)
            end
        end)
        :onExecute(function(action)
            execute(string.format("/usr/bin/osascript '%s'", action["path"]))
        end)
        :onActionId(function() return "global_scripts" end)

    return mod
end

return plugin
