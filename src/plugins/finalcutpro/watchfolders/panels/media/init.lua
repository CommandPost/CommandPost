--- === plugins.finalcutpro.watchfolders.panels.media ===
---
--- Final Cut Pro Media Watch Folder Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log				= require("hs.logger").new("fcpwatch")
-- local inspect           = require("hs.inspect")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local host				= require("hs.host")
local image				= require("hs.image")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config			= require("cp.config")
local dialog			= require("cp.dialog")
local fcp				  = require("cp.apple.finalcutpro")
local tools				= require("cp.tools")
local html				= require("cp.web.html")
local ui				  = require("cp.web.ui")
local i18n        = require("cp.i18n")

--------------------------------------------------------------------------------
-- Local Extensions:
--------------------------------------------------------------------------------
local MediaFolder = require("MediaFolder")

--------------------------------------------------------------------------------
-- Local Lua Functions:
--------------------------------------------------------------------------------
local insert      = table.insert

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

-- The storage for the media folders.
local savedMediaFolders = config.prop("fcp.watchFolders.mediaFolders", {})

--- plugins.finalcutpro.watchfolders.panels.media.mediaFolders
--- Variable
--- The table of MediaFolders currently configured.

local mediaFolders = nil

function mod.addMediaFolder(path, videoTag, audioTag, imageTag)
    insert(mediaFolders, MediaFolder.new(mod, path, videoTag, audioTag, imageTag):init())
    mod.saveMediaFolders()
end

function mod.mediaFolders()
    return mediaFolders
end

--- plugins.finalcutpro.watchfolders.panels.media.saveMediaFolders()
--- Function
--- Saves the current state of the media folders, including notifications, etc.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Nothing
function mod.saveMediaFolders()
    local details = {}
    for _,folder in ipairs(mediaFolders) do
        insert(details, folder:freeze())
    end
    savedMediaFolders(details)
end

--- plugins.finalcutpro.watchfolders.panels.media.loadMediaFolders()
--- Function
--- Loads the MediaFolder list from storage. Any existing MediaFolder instances
--- will be destroyed before loading.
function mod.loadMediaFolders()
    if mediaFolders then
        for _,folder in ipairs(mediaFolders) do
            folder:destroy()
        end
    end

    local details = savedMediaFolders()
    -- delete any existing ones.
    mediaFolders = {}
    for _,frozen in ipairs(details) do
        insert(mediaFolders, MediaFolder.thaw(mod, frozen):init())
    end
end

--- plugins.finalcutpro.watchfolders.panels.media.SECONDS_UNTIL_DELETE -> number
--- Constant
--- Seconds until a file is deleted.
mod.SECONDS_UNTIL_DELETE = 30

-- uuid -> string
-- Variable
-- A unique ID.
local uuid = host.uuid

--- plugins.finalcutpro.watchfolders.panels.media.watchFolderTableID -> string
--- Variable
--- Watch Folder Table ID
mod.watchFolderTableID = "fcpMediaWatchFoldersTable"

--- plugins.finalcutpro.watchfolders.panels.media.automaticallyImport <cp.prop: boolean>
--- Variable
--- Boolean that sets whether or not new generated voice file are automatically added to the timeline or not.
mod.automaticallyImport = config.prop("fcp.watchFolders.automaticallyImport", false)

--- plugins.finalcutpro.watchfolders.panels.media.insertIntoTimeline <cp.prop: boolean>
--- Variable
--- Boolean that sets whether or not the files are automatically added to the timeline or not.
mod.insertIntoTimeline = config.prop("fcp.watchFolders.insertIntoTimeline", true)

--- plugins.finalcutpro.watchfolders.panels.media.deleteAfterImport <cp.prop: boolean>
--- Variable
--- Boolean that sets whether or not you want to delete file after they've been imported.
mod.deleteAfterImport = config.prop("fcp.watchFolders.deleteAfterImport", false)

--- plugins.finalcutpro.watchfolders.panels.media.controllerCallback(id, params) -> none
--- Function
--- Callback Controller
---
--- Parameters:
---  * id - ID as string
---  * params - table of Parameters
---
--- Returns:
---  * None
function mod.controllerCallback(_, params)
    local action = params and params.action
    if action == "remove" then
        --------------------------------------------------------------------------------
        -- Remove a Watch Folder:
        --------------------------------------------------------------------------------
        for i,f in ipairs(mediaFolders) do
            if f.path == params.path then
                f:destroy()
                table.remove(mediaFolders, i)
                break
            end
        end

        --------------------------------------------------------------------------------
        -- Refresh Table:
        --------------------------------------------------------------------------------
        mod.refreshTable()
    elseif action == "refresh" then
        --------------------------------------------------------------------------------
        -- Refresh Table:
        --------------------------------------------------------------------------------
        mod.refreshTable()
    end
end

--- plugins.finalcutpro.watchfolders.panels.media.generateTable() -> string
--- Function
--- Generate HTML Table
---
--- Parameters:
---  * None
---
--- Returns:
---  * Returns a HTML table as a string
function mod.generateTable()

    local watchFoldersHTML = ""
    local iNone = i18n("none")

    for _, folder in ipairs(mediaFolders) do
        local uniqueUUID = string.gsub(uuid(), "-", "")
        watchFoldersHTML = watchFoldersHTML .. [[
                <tr>
                    <td class="mediaRowPath">]] .. folder.path .. [[</td>
                    <td class="mediaRowVideoTag">]] .. (folder.tags.video or iNone) .. [[</td>
                    <td class="mediaRowAudioTag">]] .. (folder.tags.audio or iNone) .. [[</td>
                    <td class="mediaRowImageTag">]] .. (folder.tags.image or iNone) .. [[</td>
                    <td class="mediaRowRemove"><a onclick="remove]] .. uniqueUUID .. [[()" href="#">Remove</a></td>
                </tr>
        ]]
        mod.manager.injectScript([[
            function remove]] .. uniqueUUID .. [[() {
                try {
                    var p = {};
                    p["action"] = "remove";
                    p["path"] = "]] .. folder.path .. [[";
                    var result = { id: "]] .. uniqueUUID .. [[", params: p };
                    webkit.messageHandlers.watchfolders.postMessage(result);
                } catch(err) {
                    alert('An error has occurred. Does the controller exist yet?');
                }
            }
        ]])
        mod.manager.addHandler(uniqueUUID, mod.controllerCallback)
    end

    if watchFoldersHTML == "" then
            watchFoldersHTML = [[
                <tr>
                    <td class="mediaRowPath">]] .. i18n("empty") .. [[</td>
                    <td class="mediaRowVideoTag"></td>
                    <td class="mediaRowAudioTag"></td>
                    <td class="mediaRowImageTag"></td>
                    <td class="mediaRowRemove"></td>
                </tr>
        ]]
    end

    local result = [[
        <table class="mediaWatchFolders">
            <thead>
                <tr>
                    <th class="mediaRowPath">]] .. i18n("folder") .. [[</th>
                    <th class="mediaRowVideoTag">]] .. i18n("video") .. " " .. i18n("tag") .. [[</th>
                    <th class="mediaRowAudioTag">]] .. i18n("audio") .. " " .. i18n("tag") .. [[</th>
                    <th class="mediaRowImageTag">]] .. i18n("stills") .. " " .. i18n("tag") .. [[</th>
                    <th class="mediaRowRemove"></th>
                </tr>
            </thead>
            <tbody>
                ]] .. watchFoldersHTML .. [[
            </tbody>
        </table>
    ]]

    return result
end

--- plugins.finalcutpro.watchfolders.panels.media.refreshTable() -> string
--- Function
--- Refreshes the Final Cut Pro Watch Folder Panel via JavaScript Injection
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.refreshTable()
    local id = mod.watchFolderTableID
    local result = [[
        try {
            var ]] .. id .. [[ = document.getElementById("]] .. id .. [[");
            if (typeof(]] .. id .. [[) != 'undefined' && ]] .. id .. [[ != null)
            {
                document.getElementById("]] .. id .. [[").innerHTML = `]] .. mod.generateTable() .. [[`;
            }
        }
        catch(err) {
            alert("Refresh Table Error");
        }
        ]]
    mod.manager.injectScript(result)
end

--- plugins.finalcutpro.watchfolders.panels.media.styleSheet() -> string
--- Function
--- Generates Style Sheet
---
--- Parameters:
---  * None
---
--- Returns:
---  * Returns Style Sheet as a string
function mod.styleSheet()
    return ui.style [[
        .mediaAddWatchFolder {
            margin-top: 10px;
        }

        .mediaRowPath {
            width:40%;
        }

        .mediaRowVideoTag {
            width:18.33%;
        }

        .mediaRowAudioTag {
            width:18.33%;
        }

        .mediaRowImageTag {
            width:18.33%;
        }

        .mediaRowRemove {
            width:5%;
            text-align:right;
        }

        .mediaWatchFolders {
            float: left;
            margin-left: 20px;
            table-layout: fixed;
            width: 95%;
            white-space: nowrap;
            border: 1px solid #cccccc;
            padding: 8px;
            text-align: left;
            background-color: #161616 !important;
        }

        .mediaWatchFolders td {
            white-space: nowrap;
            overflow: hidden;
            text-overflow: ellipsis;
        }

        .mediaWatchFolders thead, .mediaWatchFolders tbody tr {
            display:table;
            table-layout:fixed;
            width: 100%;
        }

        .mediaWatchFolders tbody {
            display:block;
            height: 80px;
            font-weight: normal;
            font-size: 10px;

            overflow-x: hidden;
            overflow-y: auto;
        }

        .mediaWatchFolders tbody tr {
            display:table;
            width:100%;
            table-layout:fixed;
        }

        .mediaWatchFolders thead {
            font-weight: bold;
            font-size: 12px;
        }

        .mediaWatchFolders tbody {
            font-weight: normal;
            font-size: 10px;
        }

        .mediaWatchFolders tbody tr:hover {
            background-color: #006dd4;
            color: white;
        }

        .mediaDeleteNote {
            font-size: 10px;
            margin-left: 20px;
        }
    ]]
end

--- plugins.finalcutpro.watchfolders.panels.media.addWatchFolder() -> none
--- Function
--- Opens the "Add Watch Folder" Dialog.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.addWatchFolder()
    local path = dialog.displayChooseFolder(i18n("selectFolderToWatch"))
    if path then

        --------------------------------------------------------------------------------
        -- Make sure the folder isn't already being watched:
        --------------------------------------------------------------------------------
        for _,folder in ipairs(mediaFolders) do
            if folder.path == path then
                dialog.displayMessage(i18n("alreadyWatched"))
                return
            end
        end

        --------------------------------------------------------------------------------
        -- Finder Tags:
        --------------------------------------------------------------------------------
        local videoTag = dialog.displayTextBoxMessage(i18n("watchFolderAddFinderTag", {type=i18n("video")}), "", "", function() return true end)
        if videoTag == false then
            return
        else
            videoTag = tools.trim(videoTag)
        end

        local audioTag = dialog.displayTextBoxMessage(i18n("watchFolderAddFinderTag", {type=i18n("audio")}), "", "", function() return true end)
        if audioTag == false then
            return
        else
            audioTag = tools.trim(audioTag)
        end

        local imageTag = dialog.displayTextBoxMessage(i18n("watchFolderAddFinderTag", {type=i18n("stills")}), "", "", function() return true end)
        if imageTag == false then
            return
        else
            imageTag = tools.trim(imageTag)
        end

        mod.addMediaFolder(path, videoTag, audioTag, imageTag)

        --------------------------------------------------------------------------------
        -- Refresh HTML Table:
        --------------------------------------------------------------------------------
        mod.refreshTable()
    end
end

--- plugins.finalcutpro.watchfolders.panels.media.init(deps, env) -> table
--- Function
--- Initialises the module.
---
--- Parameters:
---  * deps - The dependencies environment
---  * env - The plugin environment
---
--- Returns:
---  * Table of the module.
function mod.init(deps)

    --------------------------------------------------------------------------------
    -- Ignore Panel if Final Cut Pro isn't installed.
    --------------------------------------------------------------------------------
    if not fcp:isInstalled() then
        return nil
    end

    --------------------------------------------------------------------------------
    -- Define Plugins:
    --------------------------------------------------------------------------------
    mod.pasteboardManager = deps.pasteboardManager
    mod.manager = deps.manager

    --------------------------------------------------------------------------------
    -- Setup Watchers:
    --------------------------------------------------------------------------------
    mod.loadMediaFolders()

    --------------------------------------------------------------------------------
    -- Setup Panel:
    --------------------------------------------------------------------------------
    mod.panel = deps.manager.addPanel({
            priority 		= 2010,
            id				= "media",
            label			= i18n("media"),
            image			= image.imageFromPath(fcp:getPath() .. "/Contents/Resources/Final Cut.icns"),
            tooltip			= i18n("watchFolderFCPMediaTooltip"),
            height			= 500,
            loadFn			= mod.refreshTable,
        })

    --------------------------------------------------------------------------------
    -- Setup Panel Contents:
    --------------------------------------------------------------------------------
    mod.panel
        :addContent(1, mod.styleSheet())
        :addHeading(10, i18n("description"))
        :addParagraph(11, i18n("watchFolderFCPMediaHelp"), false)
        :addParagraph(12, "")
        :addHeading(13, i18n("watchFolders"), 3)
        :addContent(14, html.div { id=mod.watchFolderTableID } ( mod.generateTable(), false ))
        :addButton(15,
            {
                label		= i18n("addWatchFolder"),
                onclick		= mod.addWatchFolder,
                class		= "mediaAddWatchFolder",
            })
        :addParagraph(16, "")
        :addHeading(17, i18n("options"), 3)
        :addCheckbox(18,
            {
                label		= i18n("importToTimeline"),
                checked		= mod.insertIntoTimeline,
                onchange	= function(_, params) mod.insertIntoTimeline(params.checked) end,
            }
        )
        :addCheckbox(19,
            {
                label		= i18n("automaticallyImport"),
                checked		= mod.automaticallyImport,
                onchange	= function(_, params) mod.automaticallyImport(params.checked) end,
            }
        )
        :addCheckbox(20,
            {
                label		= i18n("deleteAfterImport", {
                    numberOfSeconds = mod.SECONDS_UNTIL_DELETE,
                    seconds = i18n("second", {count = mod.SECONDS_UNTIL_DELETE})
                }),
                checked		= mod.deleteAfterImport,
                onchange	= function(_, params) mod.deleteAfterImport(params.checked) end,
            }
        )
        :addParagraph(21, i18n("deleteNote"), false, "mediaDeleteNote")

    return mod

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.watchfolders.panels.media",
    group = "finalcutpro",
    dependencies = {
        ["core.watchfolders.manager"]		= "manager",
        ["finalcutpro.pasteboard.manager"]	= "pasteboardManager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)
    return mod.init(deps, env)
end

return plugin
