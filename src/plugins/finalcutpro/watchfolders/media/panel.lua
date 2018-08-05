local require = require
local host              = require("hs.host")
local image             = require("hs.image")

local fcp               = require("cp.apple.finalcutpro")
local dialog            = require("cp.dialog")
local tools             = require("cp.tools")
local html				= require("cp.web.html")
local ui                = require("cp.web.ui")
local i18n              = require("cp.i18n")

-- uuid -> string
-- Variable
-- A unique ID.
local uuid = host.uuid

local mod = {}

--- plugins.finalcutpro.watchfolders.media.watchFolderTableID -> string
--- Variable
--- Watch Folder Table ID
mod.watchFolderTableID = "fcpMediaWatchFoldersTable"

function mod.init(mediaFolderManager, panelManager)
    mod.manager = mediaFolderManager
    mod.panelManager = panelManager

    --------------------------------------------------------------------------------
    -- Setup Panel:
    --------------------------------------------------------------------------------
    mod.panel = panelManager.addPanel({
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
                checked		= mod.manager.insertIntoTimeline,
                onchange	= function(_, params) mod.manager.insertIntoTimeline(params.checked) end,
            }
        )
        :addCheckbox(19,
            {
                label		= i18n("automaticallyImport"),
                checked		= mod.manager.automaticallyImport,
                onchange	= function(_, params) mod.manager.automaticallyImport(params.checked) end,
            }
        )
        :addCheckbox(20,
            {
                label		= i18n("deleteAfterImport", {
                    numberOfSeconds = mediaFolderManager.SECONDS_UNTIL_DELETE,
                    seconds = i18n("second", {count = mediaFolderManager.SECONDS_UNTIL_DELETE})
                }),
                checked		= mod.manager.deleteAfterImport,
                onchange	= function(_, params) mod.manager.deleteAfterImport(params.checked) end,
            }
        )
        :addParagraph(21, i18n("deleteNote"), false, "mediaDeleteNote")

    return mod
end

--- plugins.finalcutpro.watchfolders.media.controllerCallback(id, params) -> none
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
        mod.manager.removeWatchFolder(params.path)

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

--- plugins.finalcutpro.watchfolders.media.generateTable() -> string
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

    for _, folder in ipairs(mod.manager.mediaFolders()) do
        local uniqueUUID = string.gsub(uuid(), "-", "")

        local videoTag = folder.tags.video
        local audioTag = folder.tags.audio
        local imageTag = folder.tags.image

        if videoTag == "" then videoTag = iNone end
        if audioTag == "" then audioTag = iNone end
        if imageTag == "" then imageTag = iNone end

        watchFoldersHTML = watchFoldersHTML .. [[
                <tr>
                    <td class="mediaRowPath">]] .. folder.path .. [[</td>
                    <td class="mediaRowVideoTag">]] .. videoTag .. [[</td>
                    <td class="mediaRowAudioTag">]] .. audioTag .. [[</td>
                    <td class="mediaRowImageTag">]] .. imageTag .. [[</td>
                    <td class="mediaRowRemove"><a onclick="remove]] .. uniqueUUID .. [[()" href="#">Remove</a></td>
                </tr>
        ]]
        mod.panelManager.injectScript([[
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
        mod.panelManager.addHandler(uniqueUUID, mod.controllerCallback)
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

--- plugins.finalcutpro.watchfolders.media.refreshTable() -> string
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
    mod.panelManager.injectScript(result)
end

--- plugins.finalcutpro.watchfolders.media.styleSheet() -> string
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

--- plugins.finalcutpro.watchfolders.media.addWatchFolder() -> none
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
        if mod.manager:hasMediaFolder(path) then
            dialog.displayMessage(i18n("alreadyWatched"))
            return
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

return mod
